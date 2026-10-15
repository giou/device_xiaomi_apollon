# Decrypt stall (PIN hang): root cause

**Status: the cause is a userspace RPMB race, not the kernel. The fix is a
storage gate before the TEE start. The gate waits for validation over many
decrypts. An older kernel patch is removed.**

## Symptom

After you enter the correct PIN, recovery stops forever. The log ends at
`using secdis to decrypt spblob`. No error appears. No timeout occurs. The
stop is *before* the `GateKeeper status ok` line of a good run. Only a
hardware force-reboot clears it. The next decrypt works.

(The `Set_Brightness … 5 → 0` lines after the stop are the screen-blank timer
on the frozen page. They are not a symptom. They are not a trigger.)

The stop is intermittent, not fixed: about 1 in 5–10 decrypts. It does not
depend on flashing. It does not depend on cold or warm reboot.

## Occurrence 4 (2026-10-13, R12.0_4): SMC spin, captured

SysRq captured the 4th occurrence (recovery pid 608). Three views match:

**1. `sysrq: Show backtrace of all active CPUs`, CPU5 (the stuck one):**

```
__scm_call2.llvm... +0xe0/0x448          <- drivers/soc/qcom/scm.c
__qseecom_scm_call2_locked+0x90/0xf4     <- drivers/misc/qseecom.c
qseecom_scm_call+0x950/0xa50
__qseecom_process_reentrancy+0x3b0/0x780
__qseecom_send_cmd+0x2cc/0x460
qseecom_ioctl+0x3ffc/0x6da0              <- QSEECOM_IOCTL_SEND_CMD_REQ
do_vfs_ioctl / __arm64_sys_ioctl / el0_svc
```

**2. CPU2 at the same instant:** a second qseecom caller spins on the
driver lock of the stuck caller:

```
mutex_spin_on_owner -> __mutex_lock -> qseecom_ioctl+0x1064/0x6da0
```

**3. Process view:** `android.hardware.gatekeeper@1.0-service-qti` (pid 633)
has state **R**. Its `utime` moved 46718 → 46972 (about 85 % of one core).
Its `stime` is 0. It burns CPU in a loop with no sleep. All `qseecomd`
threads wait in `qseecom_ioctl+0x2b40` (the normal listener wait). Recovery
tid 814 waits in `binder_ioctl_write_read` for the gatekeeper reply.

**The loop:** the raw SMC wrapper in `drivers/soc/qcom/scm.c`:

```c
/* __scm_call_armv8_64(), lines 108-134 */
do {
        asm volatile("smc #0" ...);      /* into the secure monitor */
} while (r0 == SCM_INTERRUPTED);         /* SCM_INTERRUPTED == 1, line 28 */
```

**No bound, no delay, no cancellation, no logging.** While the secure world
answers an SMC with `SCM_INTERRUPTED` (1), this loop spins forever in the
kernel. That one fact explains every behavior seen:

- The wedge is silent: this path logs nothing, unlike the EBUSY retries.
  dmesg was clean, and the kernel looked innocent.
- It burns 100 % CPU: the loop has no `msleep`/`cond_resched()`.
- It is unkillable: the loop has no signal check. `SIGKILL` from
  `setprop ctl.restart gatekeeper-1-0` cannot take effect.
- Only a reboot clears it: userspace cannot stop a kernel SMC loop.

**Why the secure world keeps answering INTERRUPTED** (reading at the time):
the secure world waits for a qseecomd listener before it finishes the
request. The stuck caller holds the driver lock. All qseecomd threads wait
in the listener wait, and one more caller spins on the mutex on CPU2. Each
side waits for the other side. The result is a livelock. It is intermittent
because it depends on a race in that handshake. (Occurrence 5 later showed a
userspace RPMB storm. The spin here can be the same storm seen one level
down. That link is unknown.)

## Correction: the SCM layer was ruled out by mistake

An earlier version of this file ruled out the kernel SCM layer. The reason
was that the `-EBUSY` secure-world retries have bounds. That reason was
right about the wrong loop. Both EBUSY loops have bounds and log loudly:

- `drivers/misc/qseecom.c:470` `__qseecom_scm_call2_locked` — 67 × 30 ms. It logs `secure world has been busy for 1 second!`
- `drivers/soc/qcom/scm.c:351` `__scm_call2` — 67 × 30 ms. It logs `scm: secure world has been busy for 1 second!`

The stuck loop is the **INTERRUPTED** retry *inside*
`__scm_call_armv8_64`, one level below `__scm_call2`. It has no bound and
logs nothing. Clean dmesg was evidence *for* the kernel, not against it.

## Removed fix: kernel bound (history)

The fork `giou/android_kernel_xiaomi_sm8250`, branch `lineage-24.0-apollon`,
once carried a bound in `drivers/soc/qcom/scm.c` (`f56cbb55`, 47 lines,
additive only). It gave up after **2 s** or **1,000,000** retries. The count
is the backstop for contexts where time stands still. It never sleeps,
because atomic contexts reach these wrappers. On give-up it logged once and
returned `SCM_V2_TIMED_OUT` (-13), which maps to `-ETIMEDOUT`. The decrypt
then failed loudly after about 2 s instead of hanging.

Occurrence 5 proved the recurring stall never enters this loop. The patch
left the branch again. The attempt lives on as tag
`archive/scm-interrupted-bound-attempt`.

The kernel still builds from source with the LOS config set for this
device: `vendor/kona-perf_defconfig` plus `vendor/debugfs.config` plus
`vendor/xiaomi/sm8250-common.config` plus `vendor/xiaomi/apollo.config`.
The toolchain is the tree clang (`clang-r547379`) with `LLVM=1` on the
config phase and on the build. Two traps from the bring-up stay on record.
First, `apollo.config` is not optional: it selects `CONFIG_MACH_XIAOMI_SM8250`
and supplies the touchscreen driver, and a build without it fails on unused
variables through `CONFIG_CC_WERROR=y`. Second, `LLVM=1` belongs on the
config phase too: without it the choice resolves silently to
`CONFIG_LTO_NONE`, with no LTO and no CFI. The LOS kernel CI uses a newer
built LLVM plus profile data, which public prebuilts cannot reproduce. The
`dtb` and `recovery_dtbo` stay LOS blobs. The committed prebuilt stays as a
rollback.

## Occurrence 5 (2026-10-14, R12.0_5): RPMB userspace spin

First stall on the source-built kernel (`gf56cbb55005d`, patch present).
The recovery log ends at the same line as always (`using secdis to decrypt
spblob`, Weaver verify after PIN entry). But this wedge is **not** the
kernel SMC loop:

- `returned INTERRUPTED`: 0 in dmesg, 0 in logcat. `TIMED_OUT`/`ETIMEDOUT`:
  0. The bound never fired. No SMC INTERRUPTED-spin was involved.
- logcat shows `vendor.qseecomd` (pid 594, thread 608) emitting
  `E rpmb: rpmb read operation on invalid RPMB device!!` at about 2,500/s.
  The flood lasts 15 s or more (12:50:48.791 to pull at 12:51:03.272, 37,759
  lines). It starts within the same second as the PIN entry. The thread was
  idle before (previous line 12:49:43).
- The good session the same morning (`logcat-20261014-0803`) has zero
  `rpmb` lines in 28,434 lines. The invalid-device state is the anomaly. It
  is not normal noise.
- dmesg (t=0–97 s) is clean apart from the known early-boot `scm_call
  failed: func id 0x42001907` (t=0.006 s, pre-existing) and the `ds28e16`
  battery spam. The recovery decrypt lines never reach logd. logcat carries
  no decrypt flow, only the HAL and daemon side.

Reading: the Weaver verify hammers RPMB reads that fail at once ("invalid
device"). It retries with no delay, no backoff, no give-up. The result is a
userspace livelock in and around qseecomd (prebuilt, no source). The kernel
bound cannot cover this mode. Nothing spins inside `__scm_call_armv8_64`.
Intermittency (about 1 in 5–10) with clean good boots points at a boot-time
readiness race. On some boots the RPMB path is invalid at the first Weaver
request lands.

### Confirmed live (2026-10-14 ~13:04, session stuck, no reboot yet)

- `/dev/sg0`–`sg8` are ALL present while stuck. The missing-node variant is
  dead.
- `/proc/594/fd` (qseecomd) holds **no sg fd**. RPMB never got acquired in
  this boot. Other fds: ion, dmabuf, binder, many `/dev/qseecom` sessions,
  `/dev/block/sda2`.
- `sysfs` shows sg0/sg1/sg2 as type `0x1E` (UFS well-known LUs, LUNs
  0xC150/0xC144/0xC130). sg3–sg8 are type 0 disks. Good boots open sg0
  (2026-10-13 logs, t≈2.04 s) or sg1 (2026-10-14 0803, t≈2.02 s and at
  decrypt). Acquisition runs once at qseecomd startup. What it finds (or
  misses) stays latched for the session.
- Gatekeeper HAL (pid 635) is one thread, `R`, wchan 0. It spins in
  **userspace**, not in an SMC loop. Kernel dmesg has zero UFS, SCSI, and
  sense errors. The chain is: HAL verify-retry, then TA, then RPMB request,
  then qseecomd instant failure, then repeat. Every SMC completes. No
  kernel-side bound can catch this, by construction.
- Refined mechanism: one-time sg acquisition at qseecomd startup races
  ueventd coldboot. Losing boots latch "invalid RPMB device" permanently. No
  `rpmb_init` or `parti_cfg` lines exist in any logcat. The file
  `/system/etc/rpmb_sec_parti.cfg` ships nowhere in the tree. `/system` was
  mounted before the PIN attempt this session. The config path is not the
  variable.
- **Fix:** gate `start vendor.qseecomd` on readiness with a bounded poll
  (`system/bin/wait_sg_rpmb.sh`: sg0+sg1+sg2 present, 100 × 0.2 s = 20 s
  maximum, falls through to the start on timeout). Fail-loud retry stays
  rejected: prevention only, by user decision.
- **Dead end on record:** merely moving the start from `on init` to `on
  boot` (shipped in R12.0_7) changed nothing. dmesg proves the sg scan at
  t=2.054 s against 2.018 s before, because this recovery completes its
  whole trigger cascade in about 2 s. The import chain is verified
  (`hw/init.rc` imports `init.recovery.${ro.hardware}.rc`, our file, its
  only definer of `vendor.qseecomd`). The edit was live but useless. The
  poll is the actual gate.
- Validation: run the steps in [Validation](#validation-is-the-fix-working).
  The rate was about 1 in 5–10, so the bar is about 30 clean decrypts, not
  one. A recurrence with the new gate plus `ls /dev/sg*` and fd data reopens
  the case and kills the startup-race reading.

## Validation (is the fix working?)

A single clean boot proves nothing: the stall is a race, about 1 in 5–10
boots. Prove the fix in three steps.

### 1. The gate ran

Run this after the recovery boots, and read it early:

```sh
adb shell dmesg | grep wait_sg_rpmb
```

### Seeing the gate without the breadcrumb

The gate writes its verdict twice: to `/dev/kmsg` and to
`/tmp/wait_sg_rpmb.log`. The file is the one to read. The kmsg lines are mute
when init runs the script - init's `exec` sends the command's stdout/stderr to
`/dev/null`, so a failing redirect is silent (measured 2026-10-15: the gate ran
on every boot, proven by qseecomd's start point, yet never appeared in dmesg).
Run by hand from an adb shell the kmsg lines do appear, and `ready after 0
tries` is normal.

    adb shell cat /tmp/wait_sg_rpmb.log

`/tmp` lasts until the device restarts recovery; the log collector copies the
file into its pulled folder on every run.

The block's other effect is visible in `dmesg` too, which is useful when the
file is gone:

The gate's *effect* is still visible in `dmesg`, because the `on boot` block
that follows it starts the vibrator service:

    on boot
        exec /system/bin/sh /system/bin/wait_sg_rpmb.sh
        start vendor.qseecomd
    on boot
        start health-hal-2-1
        start vendor.qti.vibrator        <- first avc line lands ~t=2.04 s
        setprop sys.usb.config adb

So take the timestamp of the first `vibrator.IVibrator` avc line in `dmesg`:

- ~2.04 s: N = 0, the nodes were ready, the gate cost nothing (measured
  2026-10-15: vibrator 2.0408 s, qseecomd's first `sg` access 2.0725 s).
- 0.2 s per try later: the gate waited N tries - a boot where the old code
  would have let qseecomd scan too early. This is the evidence that the gate
  stopped the race on that boot.
- ~22 s: the gate hit its 20 s bound (`TIMEOUT`).

No code change needed; grep the boot's `dmesg` for that line.

Two limits. The script writes to `/dev/kmsg` only, so the OrangeFox console log
(`/tmp/recovery.log`) never carries these lines - the console has no kernel
lines at all. And the kernel ring buffer drops the oldest lines as new ones
arrive: the 2026-10-15 capture had already lost everything before t=9.4 s, so a
dump taken tens of minutes into a session may no longer show the gate. Absent
lines are therefore not proof that the gate did not run.

A boot where the gate ran shows two lines:

```
wait_sg_rpmb: waiting for sg0 sg1 sg2
wait_sg_rpmb: ready after N tries
```

- `N = 0`: the sg nodes already existed. The poll cost about 0 ms. Normal.
- `N` above 0: coldboot was still running, so the gate waited. On such a
  boot the old code would have started qseecomd early and latched "invalid
  RPMB device". This is direct proof that the gate stopped the race on that
  boot.
- `wait_sg_rpmb: TIMEOUT, proceeding anyway`: the gate hit its 20 s bound and
  qseecomd started with no gate. The protection did **not** apply. Capture the
  logs and treat that boot as a near-miss.

The rc runs the script with `exec` before `start vendor.qseecomd`, and `exec`
blocks. So the start cannot happen before the script exits.

### 2. RPMB was acquired

Two signals, both taken from the occurrence-5 capture:

```sh
adb shell logcat -d | grep -c "invalid RPMB device"
adb shell 'ls -l /proc/$(pidof qseecomd)/fd 2>/dev/null | grep -o "/dev/sg[0-9]*" | sort -u'
```

Expect 0 RPMB lines, and one sg fd (`sg0` or `sg1` on a good boot). A held
sg fd is positive proof that qseecomd acquired RPMB. Ignore the `EventTagMap`
warning and the permissive `avc: denied` lines.

### 3. Enough clean decrypts

Count every reboot and decrypt. Record one line for each, with the date, `N`,
the RPMB count and the result. Use this table:

- rate 1 in 5: about 15 clean runs give 96% confidence.
- rate 1 in 10: about 25–30 clean runs give 93–96% confidence.

Stop after 30 clean runs. Keep the OTG drive unplugged: it adds `sdg1` and
`sdg2`, which are different devices, and it only confuses the sg check.

### If it stalls again

Capture this set before the reboot. It decides the case:

```sh
adb shell ls -l /dev/sg*
adb shell 'ls -l /proc/$(pidof qseecomd)/fd 2>/dev/null | grep sg'
adb shell dmesg | grep wait_sg_rpmb
adb shell logcat -d | grep -c "invalid RPMB device"
```

- Stall after `ready after N`: the gate passed, so the startup-race reading is
  wrong. Reopen the case.
- Stall after `TIMEOUT`: the gate's bound failed, not the reading.
- Do not collect PIDs with `ps | grep`: it matches its own ancestors. Use
  `pidof`.

## Capture recipe (SysRq for a kernel-side stall)

debugfs is off in this kernel. SysRq is the tool. Do these steps before you
reboot:

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

ftrace and tracefs are separate from debugfs. The mount below can still
work: `mount -t tracefs nodev /sys/kernel/tracing`.

## Ruled out (with evidence)

- **Wrong PIN** — fails fast, never hangs.
- **AIDL gatekeeper path** — fails fast identically in good boots.
- **`getService()` and service registration** — managers sit idle at hang
  time. Gatekeeper registered about 2 s into boot.
- **Cold-boot link** — one hang was a warm reboot. Later tests gave clean
  decrypts on cold boot, warm `Reboot→Recovery`, reboot-to-system, and
  power-off with power-on.
- **Flash link** — re-flashing the zip decrypted at the first try.
- **OTG, battery-authenticator spam, and service crashes** — unrelated.
- **Screenshot before decrypt** — no link. The log stops at the same line
  every time. (Pre-decrypt screenshots land in the ramdisk: `/sdcard` is not
  mounted yet, so the PNG has `dev="rootfs"`.)

## Decisions

- The post-decrypt TEE-service stop is **official parity, not a fix** for
  this. It happens *during* `verify()`, earlier. Any Password-based
  re-decrypt needs the services restarted.
- Occurrence 4 met the kernel bound. The bound is removed (wrong layer).
- Occurrence 5 meets the sg-poll gate. Fail-loud retry stays rejected
  (prevention only, by user decision).

## History

- **2026-10-13 22:21 (R12.0_4) — 4th occurrence, captured.** SysRq `l`/`t`
  with process probes pinned the spin to the unbounded `SCM_INTERRUPTED`
  loop in `__scm_call_armv8_64` (`drivers/soc/qcom/scm.c`). A PIN-panel
  screenshot before decrypting is incidental. Same signature as Hang 3.
- **2026-10-14 — 5th occurrence, captured live.** qseecomd RPMB flood at
  about 2,500/s with sg nodes present and no sg fd held. Root cause moved
  from the kernel SMC loop to the userspace acquisition race.
- Earlier occurrences died with reboots before capture. A 60 s auto-reboot
  watchdog was written, then reverted (diagnose first). Do not re-apply it.
- Early hypotheses — cold-boot race, "service registers late" — are
  **dead** (see Ruled out).
- Official miatoll reference tree: dedicated `init.recovery.qcom_decrypt.rc`
  with `.fbe.rc`, imports `prepdecrypt`, sets `LD_LIBRARY_PATH` on the HAL
  services, and stops `qseecomd`/`gatekeeper`/`keymaster` on
  `twrp.all.users.decrypted`.
