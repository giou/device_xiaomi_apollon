# Decrypt stall (PIN hang) — root cause

**Status: root cause CONFIRMED and FIXED in our kernel fork
(`giou/android_kernel_xiaomi_sm8250@lineage-24.0-apollon`, `f56cbb55`). Next:
switch the build to compile the kernel from source and verify on device.**

## Symptom

After entering the correct PIN, recovery wedges forever: the log ends at
`using secdis to decrypt spblob`, no error, no timeout — it stops *before* the
`GateKeeper status ok` line that always follows in a good run. A hardware
force-reboot clears it and the next decrypt works.

(The `Set_Brightness … 5 → 0` lines that appear afterwards are just the
recovery's screen-blank timer firing on the frozen page — **not** a symptom and
not a trigger.)

Intermittent, **not deterministic**: roughly 1 in 5–10 decrypts. Not tied to
flashing, and not tied to cold vs warm reboot (proven by testing below).

## Root cause (confirmed 2026-10-13, R12.0_4)

Captured with SysRq on the 4th occurrence (recovery pid 608). Three views line
up:

**1. `sysrq: Show backtrace of all active CPUs` — CPU5** (the wedged one):

```
__scm_call2.llvm... +0xe0/0x448          <- drivers/soc/qcom/scm.c
__qseecom_scm_call2_locked+0x90/0xf4     <- drivers/misc/qseecom.c
qseecom_scm_call+0x950/0xa50
__qseecom_process_reentrancy+0x3b0/0x780
__qseecom_send_cmd+0x2cc/0x460
qseecom_ioctl+0x3ffc/0x6da0              <- QSEECOM_IOCTL_SEND_CMD_REQ
do_vfs_ioctl / __arm64_sys_ioctl / el0_svc
```

**2. CPU2 at the same instant** — a *second* qseecom caller spinning on the
driver lock the wedged one holds:

```
mutex_spin_on_owner -> __mutex_lock -> qseecom_ioctl+0x1064/0x6da0
```

**3. Process view** — `android.hardware.gatekeeper@1.0-service-qti` (pid 633):
state **R**, `utime` 46718 → 46972 (≈85 % of a core) with `stime` 0 → it is
burning CPU in a **no-sleep** loop. `qseecomd`'s threads are all parked in
`qseecom_ioctl+0x2b40` (the normal listener wait). Recovery tid 814 is parked in
`binder_ioctl_write_read` — waiting on the gatekeeper reply, as always.

**The loop itself** — the raw SMC wrapper, `drivers/soc/qcom/scm.c`:

```c
/* __scm_call_armv8_64(), lines 108-134 */
do {
        asm volatile("smc #0" ...);      /* into the secure monitor */
} while (r0 == SCM_INTERRUPTED);         /* SCM_INTERRUPTED == 1, line 28 */
```

**No bound, no delay, no cancellation, no logging.** While QTEE answers an SMC
with `SCM_INTERRUPTED` (1), this spins forever inside the kernel, holding the
request context. That single fact explains every observed behaviour:

- **silent** — unlike the EBUSY retries, this path logs nothing, so dmesg was
  clean and the kernel looked innocent;
- **100 % CPU** — no `msleep`/`cond_resched()` in the loop;
- **unkillable** — no signal check, so `SIGKILL` from
  `setprop ctl.restart gatekeeper-1-0` can never take effect;
- **only a reboot clears it** — userspace cannot cancel a kernel SMC loop.

**Why QTEE keeps answering INTERRUPTED** (mechanism): QTEE wants a qseecomd
listener to complete something before it can finish the request, while the
wedged caller holds the driver lock — so the listener (all of qseecomd's threads
are in the listener wait, and one more caller spins on the mutex on CPU2) cannot
run. Mutual wait → livelock. Intermittent because it depends on a race in that
handshake.

## Correction: the SCM layer was wrongly ruled out

The previous version of this doc ruled the kernel SCM layer out because the
`-EBUSY` secure-world retries are bounded — that reasoning was right about the
wrong loop. Both EBUSY loops are genuinely bounded *and loud*:

- `drivers/misc/qseecom.c:470` `__qseecom_scm_call2_locked` — 67 × 30 ms, logs
  `secure world has been busy for 1 second!`
- `drivers/soc/qcom/scm.c:351` `__scm_call2` — 67 × 30 ms, logs
  `scm: secure world has been busy for 1 second!`

The loop we are stuck in is the **INTERRUPTED** retry *inside*
`__scm_call_armv8_64`, one level below `__scm_call2` — unbounded and silent.
"Nothing in dmesg" was evidence *for* the kernel, not against it.

## Fix — implemented in the kernel fork

Fork: **`giou/android_kernel_xiaomi_sm8250`**, branch **`lineage-24.0-apollon`**
(`f56cbb55`), branched from the pristine `lineage-24.0` @ `6b34d247` (the anchor
we were shipping as a prebuilt). Same convention as the recovery/vold forks.

`drivers/soc/qcom/scm.c`, +47 lines, purely additive:

- `scm_interrupted_give_up()` + `struct scm_interrupted_watch`: give up after
  **2 s** (jiffies) or **1,000,000** retries, whichever comes first. The retry
  count is the backstop for interrupts-off contexts where jiffies cannot advance.
  **No sleeping** — these wrappers are also reached from atomic context
  (`scm_call2_atomic` ← `arch/arm64/mm/fault.c` TLB conflict).
- Applied to all three armv8 wrappers (`__scm_call_armv8_64`, arm64
  `__scm_call_armv8_32`, arm32 `__scm_call_armv8_32`). On give-up: one `pr_err`
  and `return SCM_V2_TIMED_OUT`.
- New `SCM_V2_TIMED_OUT` (-13) → `scm_remap_error()` maps it to `-ETIMEDOUT`, so
  the ioctl fails with a real errno. `__scm_call2`/`scm_call2_atomic` then log
  `scm_call failed: func id …`, the HAL's `verify()` returns an error, and the
  recovery reports a decrypt failure instead of hanging. It also becomes
  killable, because the kernel loop now returns.
- `scm_get_version()`'s loop is deliberately untouched (it returns a version, not
  an errno).

**Effect:** a wedged QTEE now costs ~2 s of one core and a clear error, instead
of a silent, unkillable, reboot-only wedge. (The TZ-side state still needs a
reboot to clear; we just stop being blind to it.)

**Build change this implies** (in progress): compile the kernel from source
instead of extracting the prebuilt. LOS's own config, from
`android_device_xiaomi_sm8250-common@lineage-24.0`:

```
TARGET_KERNEL_SOURCE := kernel/xiaomi/sm8250
TARGET_KERNEL_CONFIG := vendor/kona-perf_defconfig \
                        vendor/debugfs.config \
                        vendor/xiaomi/sm8250-common.config
BOARD_KERNEL_IMAGE_NAME := Image
BOARD_INCLUDE_DTB_IN_BOOTIMG := true
BOARD_KERNEL_SEPARATED_DTBO := true
BOARD_INCLUDE_RECOVERY_DTBO := true
```

Today the tree ships `prebuilt/apollon/{kernel,dtb,recovery_dtbo}` +
`TARGET_PREBUILT_KERNEL`.

## Occurrence 5 (2026-10-14, R12.0_5) — RPMB userspace spin; the kernel bound did NOT fire

First stall on the source-built kernel (`gf56cbb55005d`, patch present).
Recovery log ends at the same line as always (`using secdis to decrypt spblob`,
synthetic-password/Weaver verify after PIN entry). But this time the wedge is
**not** the kernel SMC loop:

- `returned INTERRUPTED`: 0 in dmesg, 0 in logcat. `TIMED_OUT`/`ETIMEDOUT`: 0.
  The bound provably never fired — no SMC INTERRUPTED-spin was involved.
- logcat shows `vendor.qseecomd` (pid 594, thread 608) emitting
  `E rpmb: rpmb read operation on invalid RPMB device!!` at ~2,500/s,
  sustained ≥15 s (12:50:48.791 → pull at 12:51:03.272, 37,759 lines). The flood
  starts within the same second as the PIN submission; the thread was idle
  before (previous line 12:49:43).
- The successful session the same morning (`logcat-20261014-0803`) contains
  zero `rpmb` lines in 28,434 lines: the invalid-device state is the anomaly,
  not normal noise.
- dmesg (t=0–97 s) is clean apart from the known early-boot `scm_call failed:
  func id 0x42001907` (t=0.006 s, pre-existing, cannot be our 2 s bound) and the
  `ds28e16` battery spam. TWRP's decrypt lines never reach logd, so logcat
  carries no decrypt flow — only the HAL/daemon side.

Reading: the Weaver verify hammers RPMB reads that fail instantly ("invalid
device") and retries with no delay, no backoff, no give-up — a userspace
livelock in/around qseecomd (prebuilt, no source). The kernel bound cannot
cover this mode: nothing spins inside `__scm_call_armv8_64`. Intermittency
(~1 in 5–10) + absence on good boots points at a boot-time readiness race
(RPMB path invalid on some boots when the first Weaver request lands).

Consequences:

- The recovery-side bounded fail-loud (abort the decrypt after N s with a
  clear message) is promoted from fallback to **primary fix candidate for this
  mode**. The kernel bound stays for the occurrence-4 (SMC-spin) mode.
- Whether occurrence 4's SMC spin was the same RPMB storm observed one level
  down (each retry SMC-ing into a QTEE that answers INTERRUPTED) is unknown —
  two signatures, possibly one root cause.
- Next-stall capture: `adb shell top -n 1 -b | head -20` (confirm CPU burn +
  process) and `ls /dev | grep -i rpmb` vs a good boot (missing node →
  init-ordering fix in the tree). Testable hypothesis: waiting ~60–90 s after
  the PIN screen appears before entering the PIN.

### Confirmed live + fix (2026-10-14 ~13:04, session still stuck, no reboot)

- `/dev/sg0`–`sg8` ALL present while stuck — the missing-node variant is dead.
- `/proc/594/fd` (qseecomd): **no sg fd held** — RPMB never acquired this boot.
  Other fds: ion/dmabuf/binder/many `/dev/qseecom` sessions, `/dev/block/sda2`.
- `sysfs`: sg0/sg1/sg2 are type `0x1E` (UFS well-known LUs, LUNs
  0xC150/0xC144/0xC130); sg3–sg8 are type 0 disks. Good boots variously open
  sg0 (2026-10-13 logs, t≈2.04 s) or sg1 (2026-10-14 0803, t≈2.02 s + at
  decrypt) — i.e. acquisition runs once at qseecomd startup and whatever it
  finds (or doesn't) is latched for the session.
- Gatekeeper HAL (pid 635): single thread, `R`, wchan 0 — spinning in
  **userspace**, not in an SMC loop. Kernel dmesg has zero UFS/SCSI/sense
  errors. So: HAL verify-retry → TA → RPMB request → qseecomd instant-fail →
  repeat, every SMC completing — uncatchable by any kernel-side bound, by
  construction.
- Refined mechanism: one-time sg acquisition at qseecomd startup races ueventd
  coldboot; losing boots latch "invalid RPMB device" permanently. No
  `rpmb_init`/`parti_cfg` lines in any logcat (lib doesn't log init at default
  level); `/system/etc/rpmb_sec_parti.cfg` ships nowhere in the tree, and
  `/system` was mounted before the PIN attempt this session, so the cfg path
  is not the variable.
- **Fix (prevention, per user — fail-loud explicitly rejected):**
  `init.recovery.qcom.rc` moves `start vendor.qseecomd` from `on init` to
  `on boot`. No hardcodes, no hang risk (`on boot` always fires), nothing
  consumes TEE before it. Rides the next build after R12.0_6.
- Validation: subsequent decrypts (rate was ~1 in 5–10; a dozen clean ones
  builds confidence). A recurrence with the new trigger + `ls /dev/sg*` and
  fd data would falsify the startup-race and reopen it.

## Capture recipe (SysRq — reusable for any kernel-side stall)

debugfs is disabled in this kernel, so SysRq is the tool. **Before rebooting**:

```sh
echo 1 > /proc/sys/kernel/sysrq        # ensure enabled (0 disables it)
cat /proc/sys/kernel/sysrq             # confirm: 1
echo l > /proc/sysrq-trigger           # backtrace of every active CPU
echo t > /proc/sysrq-trigger           # all task stacks
sleep 3; dmesg > /tmp/sysrq.txt        # then pull /tmp/sysrq.txt

# targeted, cheap and very telling:
ps -A | grep -E 'gatekeeper|qseecomd|keystore|recovery'
cat /proc/<pid>/task/*/wchan           # kernel symbol it waits in
cat /proc/<pid>/stat; sleep 3; cat /proc/<pid>/stat   # utime/stime delta
cat /proc/<pid>/task/*/stack           # full kernel stack
```

(ftrace/tracefs is separate from debugfs and may still be mountable:
`mount -t tracefs nodev /sys/kernel/tracing`.)

## Ruled out (with evidence)

- **Wrong PIN** — fails fast, never hangs.
- **AIDL gatekeeper path** — fast-fails identically in good boots.
- **`getService()` / service registration** — managers idle at hang time;
  gatekeeper registered ~2 s into boot (`ro.boottime` 2.02 s vs recovery 1.99 s).
- **Cold-boot correlation** — one hang was a warm reboot; later A/B tests gave
  clean decrypts on cold boot, warm `Reboot→Recovery`, reboot-to-system, and
  power-off/power-on.
- **Flash determinism** — re-flashing the zip decrypted first try.
- **OTG / battery-authenticator log spam / service crashes** — unrelated.
- **Taking a screenshot before decrypting** — no relation; the log stops at the
  same line every time. (Pre-decrypt screenshots are written into the ramdisk:
  `/sdcard` isn't mounted yet, so the PNG's `dev="rootfs"`.)

## Decisions

- The post-decrypt TEE-service stop (see `FIXES.md`) is **official parity, not a
  fix** for this — it happens *during* `verify()`, earlier. It also means any
  Password-based re-decrypt would need the services restarted.
- No workaround shipped while the bug was uncaptured. It is now captured; the
  kernel patch above covers the SMC-spin mode (occurrence 4), the recovery-side
  fail-loud is the primary candidate for the RPMB-spin mode (occurrence 5) —
  user's call.

## History

- **2026-10-13 22:21 (R12.0_4) — 4th occurrence, captured.** SysRq `l`/`t` +
  process probes pinned the spin to the unbounded `SCM_INTERRUPTED` loop in
  `__scm_call_armv8_64` (`drivers/soc/qcom/scm.c`). A PIN-panel screenshot taken
  right before decrypting is incidental. Same signature as Hang 3.
- Earlier occurrences were lost to reboots before capture; a 60 s auto-reboot
  watchdog was written then reverted (diagnose-first). Do not re-apply it.
- Early (pre-capture) hypotheses — cold-boot race, "service registers late" — are
  **dead** (see Ruled out).
- Official miatoll reference tree: dedicated `init.recovery.qcom_decrypt.rc` +
  `.fbe.rc`, imports `prepdecrypt`, sets `LD_LIBRARY_PATH` on the HAL services,
  and stops `qseecomd`/`gatekeeper`/`keymaster` on `twrp.all.users.decrypted`.
