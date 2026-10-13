# apollon test backlog (current only — move to done, don't accumulate)

## v18 build `38210824357` (vanilla + kernel refresh + vibrator 24.0)

- [x] LOS 24 PIN decrypt
- [x] Vibration (24.0 HAL + old effect prebuilt held up fine)
- [x] Built-in Magisk 31 addon install (tested on v17; mechanism identical on v18)
- [x] MTP single-entry
- [x] OTG MSR-first disk: `sdg1` unmountable → `sdg2` (NTFS) mounted, backups at `/usb_otg/Fox` (log 20261013-1425)
- [x] OTG single-partition disk: auto-mounted with only the data partition present (2026-10-13, MSR removed)
- [x] OTG unformatted/unmountable drive: clean `no mountable partition on this drive`, no hang (log 20261013-1436)
- [ ] LOS zip flash with patching skipped
- [x] OTA row gone, settings stable
- [x] Navbar lock (no hide option in settings)

## Fixes build `38217828738` (OTG redesign + purges + battery test)

- [x] OTG redesign: plug → auto-tick ≤10s untouched (log 20261013-1425: `apollon OTG: plug event, attempting mount`)
- [x] OTG redesign: manual checkbox iterates to `sdg2` (proven twice on fixes build — re-verify quiet)
- [x] OTG redesign: per-candidate log lines visible on failure (`/dev/block/sdg1 not mountable, trying next`)
- [x] OTG redesign: MTP restored after a *failed* attempt (`[MTP] Starting MTP` immediately after `no mountable partition`); unplug/replug re-triggers too
- [x] `/usb_otg` rename: theme USB-Storage shortcut visible; OTG backups under `/usb_otg/Fox`
  (no `/usb-otg/Fox` migration needed — the old `/usb-otg` mount dir was replaced by `/usb_otg`)
- [x] Vibration again (source-built effect lib)
- [x] Battery % vs actual charge (health-HAL path)
- [ ] Sideload without treble-compat check (next LOS nightly)
- [x] Quick backup: empty default → set once in Settings → persists across reboot
- [x] Super backup (dd): 8704 MB `super.emmc.win` + SHA2 digest, 540 s (log 20261013-1501)
- [ ] ROM flash (LOS zip) — now with LP tools restored (official parity), so test the normal path
- [x] Decrypt with auto-detect only (`Using keymaster version '4.x'` in log)
- [x] Reflash-button press (repack lossless with effect-lib registration)
- [x] Offline charging — struck: the flag never lived in recovery's path
  (offline charging runs from the ROM's boot image), so there is nothing
  to verify. Drop stands.
- [ ] English-only UI, default icon layout, touch sanity
- [x] Green-led setting hidden (Settings LED section absent — confirmed on device)
- [x] MTP dates in Windows: **fixed** (fork `giou/Recovery` `bc6516b2`) — `mtp/ffs/node.cpp` sent `DATE_MODIFIED`/`DATE_ADDED` as `MTP_TYPE_UINT64`; the prop-list path Windows uses needs DateTime *strings*, while the ObjectInfo path (Linux/libmtp) already formatted them. Now emits `formatDateTime()` + `MTP_TYPE_STR`. **Verified on device: dates now show in Windows Explorer.**

## Build `38403589621` (R12.0_3 — LP tools + MTP fix + TEE cleanup)

- [x] MTP date column in Windows (fork `bc6516b2`) — verified
- [x] LP tools usable in the terminal (`lptools` installed — confirmed)
- [x] TEE cleanup: stop confirmed (`init.svc.gatekeeper-1-0` = `stopped` after decrypt); no in-session re-decrypt path exists (a `/data` remount reuses the decrypted device — see `notes/CE-REMOUNT-FIX.md`), so no regression observed. A future Password-based re-decrypt would need the services restarted; none exists today.
- [x] Version banner reads `R12.0_3` (confirmed)
- [x] `/storage` Internal-Storage backup source entry usable, backups to it work (confirmed)

## Build `38435351717` (R12.0_4) — device-tested 2026-10-13 21:46

- [ ] Encrypted-backup **lock icon** (Backup menu → set a backup password). Fix: `TW_EXCLUDE_ENCRYPTED_BACKUPS := false` reinstated (the recovery `Android.mk` test is **inverted**: unset ⇒ `-DTW_EXCLUDE_ENCRYPTED_BACKUPS` + no `libopenaes`). `libopenaes`/`isaac` confirmed present in the published image.
- [ ] Encrypted-backup **restore prompt**: the `(i)` icon no longer overlaps the text ("You…"). Fix: fork `993eb7ff` (`%col1_x%` → `%col1_x_indent%`, matching the other info blocks).
- [x] Version banner reads `R12.0_4` (confirmed in the published image)
- [x] `Decrypt.cpp` compiles (host + arm), `libvold` builds, CE symbols linked into the recovery (confirmed in build log + image)
- [ ] Carried over, still untested: LOS zip flash, sideload without treble-compat check, English-only UI / touch sanity

### `/data` remount → ❌ still broken on R12.0_4 (diagnosed, re-fixed, not yet built)

The CE re-apply **ran** on remount but was a **no-op**: `Attempting to unlock user
storage` → `failed to fscrypt_prepare_user_storage`, and names stayed ciphertext.
`fscrypt_unlock_ce_storage()` early-returns while its in-process map still lists
the user (nothing clears it on unmount), so the key was never re-added. Deeper:
the whole keyring is per-superblock, so the remount also destroys the **device
key** — leaving `/data/misc/vold` (home of every DE/CE key blob) unreadable — and
the **DE keys**. Re-installing CE alone can never work.

Re-fixed (pending build): vold rebuilds the keyring the way boot does (device key
→ on-disk DE keys → cached CE secret; no PIN needed, and the new DE reloader can
never rewrite key material), and the recovery hook only arms on a real mount
transition. Full write-up + verification: [`docs/CE-REMOUNT-FIX.md`](docs/CE-REMOUNT-FIX.md).

## Retired

- Updater-OTA ON-test — vanilla removes its UI by design.

## Proven, don't retest

- v17 decrypt (4/4 incl. repeats), MTP working, kernel enumerates `sdg1+sdg2`.

## Decrypt stall — root cause localized (2026-10-13)

Full dossier: [`docs/DECRYPT-STALL.md`](docs/DECRYPT-STALL.md).

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
