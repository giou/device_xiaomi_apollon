# apollon test backlog (current only — move to done, don't accumulate)

## v18 build `38210824357` (vanilla + kernel refresh + vibrator 24.0)

- [x] LOS 24 PIN decrypt
- [x] Vibration (24.0 HAL + old effect prebuilt held up fine)
- [x] Built-in Magisk 31 addon install (tested on v17; mechanism identical on v18)
- [x] MTP single-entry
- [ ] OTG on old iteration code (MSR-first disk; single-partition regression; unformatted-drive error)
- [ ] LOS zip flash with patching skipped
- [x] OTA row gone, settings stable
- [ ] Boot-time A/B: `fastboot reboot recovery` + `time adb wait-for-device`,
  3 runs each on v17 vs v18 (logs can't time it — no per-line timestamps)
- [x] Navbar lock (no hide option in settings)

## Fixes build `38217828738` (OTG redesign + purges + battery test)

- [ ] OTG redesign: plug → auto-tick ≤10s untouched (needs build `38354849855`: entry-log proves branch fires)
- [ ] OTG redesign: manual checkbox iterates to `sdg2` (proven twice on fixes build — re-verify quiet)
- [ ] OTG redesign: per-candidate log lines visible on failure
- [ ] OTG redesign: MTP survives a failed attempt; unplug/replug re-triggers
- [x] Vibration again (source-built effect lib)
- [x] Battery % vs actual charge (health-HAL path)
- [ ] Sideload without treble-compat check (next LOS nightly)
- [x] Quick backup: empty default → set once in Settings → persists across reboot
- [ ] Super backup (dd) + ROM flash without lptools
- [x] Decrypt with auto-detect only (`Using keymaster version '4.x'` in log)
- [x] Reflash-button press (repack lossless with effect-lib registration)
- [x] Offline charging — struck: the flag never lived in recovery's path
  (offline charging runs from the ROM's boot image), so there is nothing
  to verify. Drop stands.
- [ ] English-only UI, default icon layout, touch sanity
- [ ] Green-led setting hidden again

## Retired

- Updater-OTA ON-test — vanilla removes its UI by design.

## Proven, don't retest

- v17 decrypt (4/4 incl. repeats), MTP working, kernel enumerates `sdg1+sdg2`.

## Decrypt stall — root cause localized (2026-10-13)

Full dossier: `/home/ubuntu/apollon-recovery/decrypt-stall/FINDINGS.md`.

- [x] Captured Hang 3 (build ...907): decrypt thread (recovery pid 618, tid 828)
  blocked in binder on gatekeeper `verify()`; gatekeeper HAL (643) wedged in
  `ioctl(/dev/qseecom, QSEECOM_IOCTL_SEND_CMD_REQ)`; process unkillable; only a
  reboot clears it. `getService()`/managers/cold-boot/flash all ruled out.
- [x] Official-parity TEE cleanup applied: `init.recovery.qcom.rc` stops
  `vendor.qseecomd`/`gatekeeper-1-0`/`keymaster-4-0` on
  `twrp.all.users.decrypted=true` (matches miatoll).
- [ ] Next hang (pre-reboot): **SysRq capture** — `echo l` / `echo t` to
  `/proc/sysrq-trigger` + `dmesg | tail -250` — to pin the exact kernel
  function (qcom_scm vs qseecom ioctl vs libQSEEComAPI userspace loop).
  debugfs is disabled → tzdbg/binder dumps unavailable.
- [ ] Wait for user go-ahead before implementing any fix (incl. bounded
  fail-loud / reboot watchdog): hold until the bug recurs and is captured.
- [ ] If kernel-side: compile `android_kernel_xiaomi_sm8250` with a defensive
  patch (candidate new default; copy the official LOS build method). Departs
  from the byte-identical kernel-extraction decision.
