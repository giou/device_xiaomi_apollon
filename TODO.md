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

## Build R12.0_6 (pending) — remount fix (cached key material) + extra languages

- [ ] `/data` untick→tick with the vold cache in place: log shows
  `Reapply: rebuilding the fscrypt keyring after /data remount` → `device key
  re-installed` → `DE/CE keys re-installed` → `keyring rebuilt`, and
  `/data/media/0` is readable **without a reboot**.  (vold `aaa3135`; if a step
  fails, its breadcrumb names it and `adb logcat` has the errno.)
- [ ] Settings > Regional > Language lists the four extras (Spanish, Hungarian,
  Simplified and Traditional Chinese) and CJK text renders.  (`TW_EXTRA_LANGUAGES`
  in the tree, `cfabd87`.)
- [ ] Release title carries `(R12.0_6)` - the naming change in builder `bce00ff`.

## Build R12.0_5 (`38482616737`, published 2026-10-14 01:48) — theme layout + corrected CE re-apply + kernel from source

- [ ] `/data` unmount→remount: names readable without a reboot; log shows
  `Reapply: rebuilding the fscrypt keyring after /data remount` → `device key
  re-installed` → `DE/CE keys re-installed` → `keyring rebuilt`.
  - R12.0_5 fired the hook but could not rebuild: the device/DE/CE keys are all
    Keymaster-wrapped and the post-decrypt TEE cleanup stops keystore
    (`keystore2 ... DEAD_OBJECT` → `decryptWithKeystoreKey failed`). vold
    `aaa3135` now re-installs material cached during decryption instead (no
    keystore, no generation, no writes) - needs the next build.
  - Verify per [`docs/CE-REMOUNT-FIX.md`](docs/CE-REMOUNT-FIX.md).
- [x] **No spurious re-apply while `/data` stays mounted** (`Is_Mounted()` gate).
  Proven from logs already in hand: R12.0_4's `install.log` shows the *ungated*
  hook firing on the recovery's own `Mount_By_Path("/data")` right after decrypt
  (`Attempting to unlock user storage` again at line ~1170, with no unmount
  anywhere in that window), while R12.0_5's `post-install.log` runs the same flow
  and is silent - the only difference between the two builds there is the gate.
  No extra run needed; only a genuine untick→tick transition may fire it.
- [x] Theme form fields: Verify Password, restore password prompt, Rename
  backup, file rename/chmod, Time offset — caption/input/underline all at x=48,
  underline ending at 1032 (no clipping). (`c2165eef`, `7134e101`.)
  **Verified on device 2026-10-14 (R12.0_5).**
- [x] Info-icon gap: PIN decrypt screen ("Data Partition is encrypted") and the
  restore prompt — text snug after the icon (136) instead of 216.
  **Verified on device 2026-10-14 (R12.0_5).**
- [x] Failure-text spacing uniform: wrong password on Set Password / the PIN
  decrypt screen → the red text sits ~27px below the red underline, matching
  Rename backup. (`5faba288`.)  **Verified on device 2026-10-14 (R12.0_5).**
- [x] Version banner reads `R12.0_5` (confirmed in the published image).
- [x] Verified in the published artifact (R12.0_5's image): banner `R12.0_5`;
  `col1_x_icon_text` = 136 and nine `below:idfail_*` anchors in the theme; CE
  re-apply strings (`rebuilding fscrypt keyring`, `CE keys restored`,
  `fscrypt_reload_de_keys`) and `libopenaes` in the ramdisk.  The strings change
  in the next build: the re-apply now prints `rebuilding the fscrypt keyring
  after /data remount` → `device key (re-)installed` → `DE/CE keys …` →
  `keyring rebuilt`.
- [x] Encrypted-backup lock icon present, and the restore prompt's `(i)` sits
  like it does elsewhere.  **Verified on device 2026-10-14 (R12.0_5).**
- [ ] **Extra languages missing from the menu** (found on device 2026-10-14).
  The build ships only the 28 `gui/theme/common/languages/*.xml`; the four
  `gui/theme/extra-languages/languages/*.xml` - Spanish, Hungarian, Simplified and
  Traditional Chinese - plus the font overrides they need are copied into `/twres`
  only when the tree sets `TW_EXTRA_LANGUAGES := true`
  (`gui/libfoxui_defaults.go`: `if getMakeVars(ctx, "TW_EXTRA_LANGUAGES") == "true"`,
  shipping `extra-languages/{fonts,languages}`).  Confirmed absent from R12.0_5's
  ramdisk (`twres/languages` = exactly the 28 common files).  Flag now set in
  `BoardConfig.mk`; verify on the next build that Settings > Regional > Language
  lists them and the CJK text renders.
- [x] LOS zip flash + sideload, treble path.  Sideloaded
  `lineage-24.0-20261011-nightly-apollon-signed.zip` on R12.0_5 (2026-10-14):
  assert passed (`AssertDevice=[apollon,apollo,apollopro]`), OF logged
  `detected Treble ROM installer. [code=11]` and **proceeded** (no refusal - so
  `OF_NO_TREBLE_COMPATIBILITY_CHECK` is not needed), LP resized
  system/vendor/product/odm/system_ext, system was patched block-by-block, and
  the addon repacked/flashed the boot image for Magisk.  `operation_end -
  status=0`.  No recovery image was written, so OF survived the ROM flash.
  ROM boot confirmation still pending.
- [x] Moved the three build-time workarounds into the recovery fork
  (`giou/Recovery@fox_16.0-apollon` `41e0acf5`): openaes K&R → ANSI prototypes,
  repacker targets `/recovery` on slotless devices, manual reflash item
  un-gated. The override step clones the fork as-is — no build-time rewriting
  and no content-marker asserts; the log records the fork commit used
  (`Override HEAD now:` + `git log --oneline -3`). Same resulting bytes as R12.0_5,
  so no device re-test is needed beyond the checklist above.

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
- [x] **Kernel built from source** — done. Builder run `38482616737` cloned
  `giou/android_kernel_xiaomi_sm8250@lineage-24.0-apollon`, built `Image` with
  LOS's full apollon config set (`kona-perf_defconfig` + `debugfs.config` +
  `sm8250-common.config` + `apollo.config`) using the tree's clang r547379 with
  `LLVM=1`, and installed it over `prebuilt/apollon/kernel`. First attempt
  exposed two silent-loss bugs (missing device fragment → no Xiaomi board/touch;
  config phase without `LLVM=1` → `CONFIG_LTO_NONE`), both fixed and now
  asserted; details in `FIXES.md`. Shipped kernel verifies as ours:
  `Linux version 4.19.325-cip136-st20-perf-gf56cbb55005d`, `CONFIG_LTO_CLANG=y`
  + `THINLTO=y` + `CFI_CLANG=y`, `returned INTERRUPTED` present. dtb/dtbo stay
  the LOS blobs (same kernel commit). (Patch `f56cbb55` reverted 2026-10-14 in `ee83446` — fork now identical to pristine; new builds lack the `returned INTERRUPTED` string but keep the source-build pipeline.)
- [ ] **Verify the source-built kernel boots and decrypts on device** (R12.0_5):
  banner/boot works, `/data` decrypts, behaviour unchanged (the patch era is over — reverted).
- [x] SMC-spin backstop — dropped with the revert (user order): an
  occurrence-4-style wedge would hang silently again. Accepted: the recurring
  bug is the RPMB mode, covered by the init fix below.
- [ ] Recovery-side bounded fail-loud (abort the decrypt after N s with a clear
  message) — NOT pursued: user rejected mitigation-without-prevention.
- [x] Proper (preventive) fix for the RPMB-spin mode, confirmed live 13:04:
  qseecomd's librpmb acquires `/dev/sg*` once at startup and never recovers;
  `start vendor.qseecomd` moved from `on init` to `on boot` in
  `init.recovery.qcom.rc` so acquisition runs after ueventd coldboot drains.
  Rides the next build after R12.0_6; validate over subsequent decrypts
  (recurrence + `ls /dev/sg*`/fd data would falsify).
- [ ] Low priority, noted from the same logs: a screenshot taken **before**
  `/data` is decrypted is reported as saved to `/sdcard/Fox/screenshots/…` but is
  actually written into the ramdisk (`dev="rootfs"` in the avc record) — it will
  not survive a reboot. Cosmetic; unrelated to the stall.
