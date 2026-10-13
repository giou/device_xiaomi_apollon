# Decrypt stall (PIN hang) — findings

**Status: unresolved — kernel-side. Root cause localized; fix deferred pending a
kernel stack capture.**

## Symptom

After entering the correct PIN, recovery wedges forever: the log ends at
`using secdis to decrypt spblob`, the screen dims (5→0), no error, no timeout.
A hardware force-reboot clears it and the next decrypt works.

Intermittent, **not deterministic**: roughly 1 in 5–10 decrypts. Not tied to
flashing, and not tied to cold vs warm reboot (proven by testing below).

## Root cause (localized)

Call chain on the stuck decrypt:

1. `system/vold/Decrypt.cpp`, `Decrypt_User_Synth_Pass`, **secdis (non-Weaver)
   branch**, runs **inside the recovery process** (there is no separate `vold`).
   After the print it does: Get_Secdis → PersonalizedHashBinary →
   `AServiceManager_isDeclared(AIDL gatekeeper)` → `IGatekeeper::getService()`
   (HIDL) → `gk_device->verify()` (HIDL sync).
2. The AIDL `isDeclared` lookup returns **false** (expected — dmesg shows the
   `avc: denied { find } IGatekeeper/default` + servicemanager VINTF message), so
   it falls back to HIDL.
3. `IGatekeeper::getService()` **succeeded**: all managers are idle
   (hwservicemanager, servicemanager `do_epoll_wait`; keystore2 all-idle), so
   step 4 is ruled out.
4. **`gk_device->verify()`** is a synchronous binder call to the gatekeeper HAL.
   The recovery decrypt thread blocks in `binder_ioctl_write_read`
   (`binder_ioctl_write_read → binder_ioctl → ioctl`).
5. The gatekeeper HAL is **wedged inside QSEECom**: it is in a hot loop on
   `ioctl(fd = /dev/qseecom, req 0xc0209703)` — decoded as
   `QSEECOM_IOCTL_SEND_CMD_REQ` (`_IOWR(magic=0x97, nr=3, size=32)`,
   `sizeof(struct qseecom_send_cmd_req)` = 32). State **R**, `utime=0`, `stime`
   climbing ≈ 100 % CPU (i.e. in-kernel). Its maps show
   `/vendor/lib64/libQSEEComAPI.so`.
6. The process is **unkillable**: `setprop ctl.restart gatekeeper-1-0` sends
   SIGKILL but the process never exits (`libprocessgroup: Unable to remove
   cgroup .../pid_…: Device or resource busy`) and the decrypt thread stays
   blocked → stuck in the **kernel** (inside the qseecom ioctl).

**One-liner:** the gatekeeper TA path (HAL → `/dev/qseecom` → QTEE)
intermittently livelocks; recovery's `verify()` binder call then waits forever.
`qseecomd` is idle, so it is not the daemon. **Only a reboot clears it** —
userspace cannot (proven).

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
- **Kernel** — byte-identical LOS 24 kernel in all boots; no kernel error in
  dmesg at the stall.

## Kernel recon

Kernel: `LineageOS/android_kernel_xiaomi_sm8250` @
`6b34d24765327d746074c8e53b5ad0d24a51acc7` (`lineage-24.0`), driver
`drivers/misc/qseecom.c`.

- The `-EBUSY` secure-world retry loop (`__qseecom_scm_call2_locked`) is
  **bounded**: `QSEECOM_SCM_EBUSY_MAX_RETRY 67` × `QSEECOM_SCM_EBUSY_WAIT_MS 30`
  ≈ 2 s, and it logs `secure world has been busy for 1 second!`. Not in dmesg →
  **ruled out**.
- The send path logs nothing at the stall (dmesg clean) → the spin sits
  **below** the driver's logging: either the SCM/SMC layer (`qcom_scm`) or a
  **userspace retry** in `libQSEEComAPI`. Distinguishing these is the last gap.
- **debugfs is disabled** in this kernel (`mount -t debugfs` → "No such
  device") → binder debugfs and `tzdbg` are permanently unavailable.

## Diagnostics for the next occurrence (the missing piece)

**SysRq is the key** (works without debugfs). On the next hang, BEFORE rebooting:

```sh
# adb shell, or the equivalent on the host
echo l > /proc/sysrq-trigger        # backtrace of every active CPU
echo t > /proc/sysrq-trigger        # all task stacks
dmesg | tail -n 250
```

`echo l` shows exactly which kernel function the gatekeeper thread is spinning
in (`qcom_scm` vs qseecom ioctl vs a userspace loop). Also useful:

```sh
cat /proc/<gatekeeper-pid>/stat; sleep 3; cat /proc/<gatekeeper-pid>/stat   # CPU burn?
cat /proc/<gatekeeper-pid>/syscall; sleep 2; cat /proc/<gatekeeper-pid>/syscall
ls -l /proc/<gatekeeper-pid>/fd
```

Optionally check whether ftrace/tracefs exists (it is separate from debugfs):

```sh
mkdir -p /sys/kernel/tracing; mount -t tracefs nodev /sys/kernel/tracing; ls /sys/kernel/tracing | head
```

## Decisions

- The post-decrypt TEE-service stop (see `FIXES.md`) is **official parity, not a
  fix** for this — it happens *during* `verify()`, earlier. It also means any
  Password-based re-decrypt would need the services restarted.
- **Do not implement a workaround** (bounded fail-loud / reboot watchdog) until
  the bug recurs and is captured with SysRq.
- If kernel-side: compile `android_kernel_xiaomi_sm8250` with a defensive patch
  (timeout / killable qseecom wait). This departs from the "extract the LOS
  kernel byte-identical" decision; kernel compilation is a candidate new default
  and should copy the official LOS build method.

## History

- **2026-10-13 22:21 (R12.0_4) — recurrence, same signature.** Log ends at
  `using secdis to decrypt spblob`, brightness 5→0, UI thread alive
  (blanktimer toggling), still hung ≥4.5 min when dmesg was captured. The dmesg
  contains no SysRq output (`echo l`/`echo t` were never run), so the
  kernel-function gap below is still open. A PIN-panel screenshot taken right
  before decrypting is incidental (pre-decrypt `/sdcard` is not mounted, so the
  PNG lands in the ramdisk — `dev="rootfs"` in the avc record).
- A 60 s capped auto-reboot watchdog was written then reverted (diagnose-first).
  Do not re-apply without capture evidence + explicit order.
- Early (pre-capture) hypotheses — cold-boot race, "service registers late" — are
  **dead** (see Ruled out).
- Official miatoll reference tree: dedicated `init.recovery.qcom_decrypt.rc` +
  `.fbe.rc`, imports `prepdecrypt`, sets `LD_LIBRARY_PATH` on the HAL services,
  and stops `qseecomd`/`gatekeeper`/`keymaster` on `twrp.all.users.decrypted`.
