# apollon OrangeFox — finish list

Target: full-featured OrangeFox for apollon (Mi 10T / 10T Pro / Redmi K30S
Ultra) on official LineageOS. Items below are deferred, not dropped.

## Must fix before calling it finished

- [x] **"Flash current OrangeFox" wrote to `/boot` (bricked system).**
      Upstream `twrpRepacker` defaulted `dest_partition` to `/boot`, only
      switching to `/recovery` for slotted devices. Fixed in builder
      (`e593eeb`): target `/recovery` whenever the partition exists.
      Unbuilt — needs a device test (fastboot boot → button → verify
      recovery partition updated, system still boots). Do NOT press the
      button on older builds.
- [ ] **logd crash loop (no logcat).** Chain: A16 `system/logging/logd`
      `DropPrivs()` aborts when `set_sched_policy(SP_BACKGROUND)` fails (no
      `/etc/task_profiles.json` in recovery), then every restart aborts
      re-setting the already-set `ro.logd.kernel` (`main.cpp:216-218`,
      `SIGABRT`). Attempted fix (unbuilt): minimal `task_profiles.json`
      stub with empty `SCHED_SP_BACKGROUND` actions in ramdisk `/etc`.
      If logd still dies, the fallback is a source patch to `system/logging`
      (tolerate both failures) — needs manifest-override support in the
      builder (it can only *add* repos today) plus a fork to carry it.
      Impact: none on recovery function; only `logcat` unavailable.

## Pending verification (device tests)

- [x] Vibrator HAL stays up on v4+ build (`IVibrator/default` registers, no
      `status 1` loop in dmesg) and touch is instant with haptics on.
      (Verified: 0 service exits, UI snappy, vibration felt on touch.)
- [x] PIN decrypt and MTP (device-tested).
- [ ] Password/pattern decrypt on a *locked* LOS 23 install (PIN done; the
      other two credential types share the gatekeeper path, low risk).
- [ ] Backup/restore of `/data` (FBE) end-to-end.
- [ ] `adb sideload` + USB-OTG sanity.
- [x] LineageOS OTA update from the Updater (Oct 10 build: applied cleanly,
      auto-rebooted to system; Magisk 31.0 survived with Ramdisk Yes).

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
