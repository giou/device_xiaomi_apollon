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
- [ ] Encrypted-backup **restore prompt**: the `(i)` icon no longer overlaps the text. Superseded the one-page `993eb7ff` (reverted) — now done theme-wide in R12.0_5 (`c2165eef`, info text at `%col1_x_icon_text%`); verify on device.
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

## Build R12.0_5 (pending) — theme layout + corrected CE re-apply

- [ ] `/data` unmount→remount: names readable without a reboot; log shows
  `Reapply: rebuilding fscrypt keyring for 1 user(s)` … `Reapply: CE keys
  restored`. (vold `74d592b` + recovery `e710f732`; R12.0_4's attempt was a
  no-op. Verify per [`docs/CE-REMOUNT-FIX.md`](docs/CE-REMOUNT-FIX.md).)
- [ ] Re-tick `/data` while it is already mounted → **no** re-apply, log quiet
  (`Is_Mounted()` gate).
- [ ] Theme form fields: Verify Password, restore password prompt, Rename
  backup, file rename/chmod, Time offset — caption/input/underline all at x=48,
  underline ending at 1032 (no clipping). (`c2165eef`, `7134e101`.)
- [ ] Info-icon gap: PIN decrypt screen ("Data Partition is encrypted") and the
  restore prompt — text snug after the icon (136) instead of 216.
- [ ] Failure-text spacing uniform: wrong password on Set Password / the PIN
  decrypt screen → the red text sits ~30px below the red underline, matching
  Rename backup. (`5faba288`.)
- [ ] Version banner reads `R12.0_5`.
- [ ] Carried over, still untested: encrypted-backup lock icon, LOS zip flash,
  sideload without the treble check, English-only UI / touch sanity.

## Decrypt stall — ROOT CAUSE CONFIRMED (kernel, 2026-10-13)

Full dossier: [`docs/DECRYPT-STALL.md`](docs/DECRYPT-STALL.md).

- [x] Captured (4th occurrence, R12.0_4) with SysRq `l`/`t` + process probes.
  Exact frame: `__scm_call_armv8_64` (`drivers/soc/qcom/scm.c`, lines 108-134) —
  `do { smc #0 } while (r0 == SCM_INTERRUPTED);` — **unbounded, no delay, no
  logging**. Reached via `__scm_call2` ← `__qseecom_scm_call2_locked` ←
  `qseecom_scm_call` ← `__qseecom_process_reentrancy` ← `__qseecom_send_cmd` ←
  `qseecom_ioctl(QSEECOM_IOCTL_SEND_CMD_REQ)`. Gatekeeper HAL (pid 633): state R,
  ~85 % of a core, `stime` 0 (no-sleep loop); a second caller spins on the driver
  mutex (CPU2 → `mutex_spin_on_owner`) → livelock. Explains silent / 100 % CPU /
  unkillable / reboot-only.
- [x] Correction: the bounded `-EBUSY` loops (67x30 ms, both of which log) were
  ruled out on sound grounds — but the spin is the INTERRUPTED retry one level
  below them. "dmesg clean" was evidence *for* the kernel, not against.
- [x] Official-parity TEE cleanup (`init.recovery.qcom.rc`) — parity only, not a
  fix for this (the wedge is earlier, inside `verify()`).
- [x] **Kernel fork + fix done:** `giou/android_kernel_xiaomi_sm8250@lineage-24.0-apollon`
  (`f56cbb55`, from pristine `lineage-24.0` @ `6b34d247`) bounds the
  SCM_INTERRUPTED retry (2 s / 1,000,000 retries, no sleeping) → new
  `SCM_V2_TIMED_OUT` → `-ETIMEDOUT`, logged once. Wedge becomes a loud error
  after ~2 s instead of an unkillable hang.
- [x] **Kernel built from source** (wired): the builder clones
  `giou/android_kernel_xiaomi_sm8250@lineage-24.0-apollon`, builds `Image` with
  LOS's defconfig set + the tree's clang r547379 (LTO+KCFI), asserts the patch
  is in the image, and installs it over `prebuilt/apollon/kernel`. dtb/dtbo stay
  the LOS blobs (same kernel commit).
- [ ] **Verify the first source-built kernel boots and decrypts** (R12.0_5):
  confirm the banner/boot works, `/data` decrypts, and the LD'd behaviour is
  unchanged apart from our patch. Watch for LTO link memory on the runner.
- [ ] Verify on device: a stall (if it recurs) must now fail after ~2 s with
  `scm_call failed` in dmesg instead of wedging.
- [ ] Fallback if the source build proves unworkable: recovery-side bounded
  fail-loud (abort the decrypt after N s with a clear message).
- [ ] Low priority, noted from the same logs: a screenshot taken **before**
  `/data` is decrypted is reported as saved to `/sdcard/Fox/screenshots/…` but is
  actually written into the ramdisk (`dev="rootfs"` in the avc record) — it will
  not survive a reboot. Cosmetic; unrelated to the stall.
