# apollon OrangeFox — finish list

Target: full-featured OrangeFox for apollon (Mi 10T / 10T Pro / Redmi K30S
Ultra) on official LineageOS. Items below are deferred, not dropped.

## Must fix before calling it finished

- [ ] **logd crash loop (no logcat).** A16 `system/logging/logd/main.cpp:216-218`
      does `SetProperty("ro.logd.kernel", "true")`, fatal on failure. First
      start likely dies on missing `/etc/task_profiles.json` scheduling setup
      (`failed to set background scheduling policy`, see dmesg), then every
      restart aborts on the already-set read-only prop (`SIGABRT`,
      `PROP_ERROR_READ_ONLY_PROPERTY`). Fix needs a source patch to the
      upstream manifest project `system/logging` — the builder can currently
      only *add* repos (twrp.dependencies), not override platform ones, so
      this also needs builder support for manifest overrides/replace rules.
      Impact today: none on recovery function (decrypt/mount/flash/backup
      don't use logd); only `logcat` unavailable. Fix when a bug appears
      that is only visible via logcat.

## Pending verification (device tests)

- [x] Vibrator HAL stays up on v4+ build (`IVibrator/default` registers, no
      `status 1` loop in dmesg) and touch is instant with haptics on.
      (Verified: 0 service exits, UI snappy.)
- [x] PIN decrypt and MTP (device-tested).
- [ ] Password/pattern decrypt on a *locked* LOS 23 install (PIN done; the
      other two credential types share the gatekeeper path, low risk).
- [ ] Backup/restore of `/data` (FBE) end-to-end.
- [ ] `adb sideload` + USB-OTG sanity.
- [ ] LineageOS OTA update from the Updater (ROM Survival + Magisk/addon
      survival; verify the update applies and boots, recovery not
      overwritten).

## Upstream workarounds to drop when fixed upstream

- [ ] Builder openaes K&R sed (`bootable/Recovery@fox_16.0`
      `openaes/src/isaac/rand.{h,c}`). Harmless if upstream fixes it (patterns
      still match), remove for cleanliness once confirmed.
- [ ] `orangefox_sync.sh` missing `patch-vendor-twrp-fox_12.1.diff` (12.1 path
      only, cosmetic).

## Deliberate deviations (not bugs)

- FBEv1 (`ice`, policy 1) to match LOS; FBEv2 trees are for MIUI/HyperOS.
- No MIUI otacert key (LOS-official target); Magisk key kept.
- `exfat_miui.ko` dropped (wrong vermagic on 4.19.325; built-in exfat used).
- `BOARD_PLAT_*` / libc++ deprecation warnings in build log are upstream
  code, untouched.
