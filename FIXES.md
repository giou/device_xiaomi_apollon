# Fixes & additions vs stock OrangeFox

Scope: **Xiaomi apollon** (Mi 10T / Mi 10T Pro / Redmi K30S Ultra), OrangeFox
`fox_16.0` device tree, LineageOS 24 base (SDK 37, FBEv1).

This tree is not a from-scratch port — it is the stock OrangeFox 16.0 codebase
with a small set of targeted changes needed to make apollon work correctly on
LineageOS 24. This file lists every deliberate delta, why it exists, and where
it lives. Per-issue detail dossiers are under [`docs/`](docs/).

Repos involved:
- **device tree** — `giou/device_xiaomi_apollon` (`fox_16.0`) — this repo.
- **recovery fork** — `giou/Recovery` (`fox_16.0-apollon`) — fork of
  `bootable/recovery`.
- **vold fork** — `giou/android_system_vold` (branch `fox_16.0-apollon`; `fox_16.0` kept
  pristine as an upstream mirror) — fork of `system/vold`.
- **vibrator HAL fork** — `giou/android_vendor_qcom_opensource_vibrator`.
- **kernel fork** — `giou/android_kernel_xiaomi_sm8250`
  (`lineage-24.0-apollon`; `lineage-24.0` kept pristine).
- **builder** — `giou/OrangeFox-Action-Builder`.

---

## Decrypt / FBE

- **LineageOS 24 (SDK 37) FBEv1 decryption.** apollon's LOS 24 uses FBEv1
  (`ice`, wrapped keys). The tree is pinned to match: `PRODUCT_SHIPPING_API_LEVEL
  := 29`, `TW_USE_FSCRYPT_POLICY := 1`, `PRODUCT_USE_DYNAMIC_PARTITIONS := true`.
  *(tree: `device.mk`, `BoardConfig.mk`)*
- **TEE services stopped after decryption (official parity).** Once all users
  are decrypted, `vendor.qseecomd` / `gatekeeper-1-0` / `keymaster-4-0` are
  stopped so TEE clients are not left running across reboots.
  *(tree: `recovery/root/init.recovery.qcom.rc`, on `twrp.all.users.decrypted`)*
- **CE / file-name keys re-applied on `/data` remount.** fscrypt keys live in a
  keyring owned by the `/data` superblock, so unmounting `/data` destroys the
  **device key** and every **DE/CE key** with it (a remount then showed
  ciphertext filenames until reboot, and `/data/misc/vold` itself went
  unreadable). On a real remount the recovery now rebuilds the keyring the way
  boot does — device key → DE keys → cached CE secret — none of which needs the
  PIN. The secret cache is cleared on data wipe.
  *(vold fork + recovery fork hook; see [`docs/CE-REMOUNT-FIX.md`](docs/CE-REMOUNT-FIX.md))*

## USB / OTG

- **Mount point renamed `/usb-otg` → `/usb_otg`** to match the official miatoll
  tree; this unhides the theme's USB-Storage shortcut (gated on `/usb_otg`).
  Backups land under `/usb_otg/Fox`. *(tree: `twrp.flags`; fork: mount strings)*
- **OTG automount by plug-event edge.** On a drive appearance, recovery mounts
  it automatically with bounded spin-up retries, iterating candidates
  `sdg1…sdg16` (so MSR/EFI stub first partitions don't break the mount), logging
  each candidate, and **restoring MTP if the attempt fails**. Manual mount uses
  the same code path. *(recovery fork: `partitionmanager.cpp`)*
- **Custom USB init** (`init.recovery.usb.rc` + `TW_EXCLUDE_DEFAULT_USB_INIT`)
  is required for the OTG/ADB switching to behave. *(tree: `BoardConfig.mk`)*

## MTP

- **Dates now show in Windows Explorer.** MTP/PTP defines the Date properties as
  DateTime *strings*; they were being sent as `UINT64` with an empty string, so
  Windows (which reads them via `GetObjectPropList`) showed a blank column while
  Linux/libmtp (ObjectInfo path) showed dates. Now emitted as formatted strings.
  *(recovery fork `bc6516b2`: `mtp/ffs/node.cpp`)*
- **Single MTP storage entry.** The internal storage is exposed once, not
  duplicated. *(recovery fork: `mtp/ffs/mtp_MtpServer.cpp`)*

## Backups

- **Encrypted backups enabled.** `TW_EXCLUDE_ENCRYPTED_BACKUPS := false` is
  **required** to include the feature — the recovery `Android.mk` test is
  inverted (unset ⇒ `-DTW_EXCLUDE_ENCRYPTED_BACKUPS` and **no `libopenaes`**).
  *(tree: `BoardConfig.mk`)*
- **`/storage` (Internal Storage) backup source** exposed in the Backup page.
  *(tree: `twrp.flags`/fstab)*
- **Uniform failure-text spacing.** Each `%text_fail%` underline is 3px and its
  error label used to sit on the *same* row, so the text started on the line; the
  rename-backup page alone put it a row lower (30px). Every error text is now
  anchored `y="below:idfail_N+27"` (27px under the underline's bottom edge = the
  rename-backup spacing), so all nine are identical. *(recovery fork:
  `gui/theme/portrait_hdpi/pages/*` + `pages/templates/templates.xml`)*
- **Theme-wide form-field alignment.** `%col1_x_caption%` (216) is the *listbox
  icon-column width* (`<iconsize w="%col1_x_caption%">`), but it was also reused
  as the x for plain form fields, so every password/name field sat 168 px right
  of the body text and ran 120 px off the 1080 screen
  (`216 + %input_w% 984 = 1200`) — visible as the misaligned "Verify Password"
  field directly after the correctly aligned "Set Password" one, and on the
  restore prompt, rename/chmod, time offset, PIN setup and debug pages. Every
  field group (caption, input, underline, failure text) now uses `%col1_x%` (48;
  `48 + 984 = 1032` fits), including the shared `templates.xml` password
  templates. Text after an `icon_info` icon now uses a new `%col1_x_icon_text%`
  (136 = 48 + 64 px icon + 24 px) instead of `%col1_x_indent%` (216, too far) or
  `%col1_x%` (which overlapped the icon on `universal.xml`). *(recovery fork:
  `gui/theme/portrait_hdpi/pages/*` + `resources/vars.xml`)*

## Build / packaging

- **Logical-partition tools restored (official parity).** `OF_ENABLE_LPTOOLS := 1`
  + `OF_ENABLE_ALL_PARTITION_TOOLS := 1` ship `lpdump`/`lpdumpd`/`lptools`/
  `lpmake`/`lpunpack`/`lpadd`/`lpflash`/`bootctl`, matching the official miatoll
  tree. Sources come from the OF manifest (`twrp-default.xml` → phhusson
  `vendor_lptools`). *(tree: `fox_apollon.mk`)*
- **LOS-only ("vanilla") direction**: no MIUI-specific props are looked up; MIUI
  OTA handling and AromaFM (32-bit, crashes on A16) are dropped. *(tree/
  builder)*
- **Magisk 31 bundled** as the addon (upstream ships an older one).
  *(tree: `fox_apollon.mk` + builder fetch)*
- **dtb / recovery_dtbo are extracted (not built) from the LOS 24 boot image**,
  keeping them byte-identical to LineageOS; the kernel itself is built from our
  fork — see [Kernel](#kernel). *(builder)*
- **Three upstream workarounds live in the recovery fork**, not in the build:
  openaes `isaac` used K&R prototypes/definitions with the parameters commented
  out (`void randinit(/*_ randctx *r, word flag _*/);`), which `clang-r547379`
  rejects with "too many arguments to function call"; `twrpRepacker.cpp` only
  switched its target to `/recovery` when the device was slotted, so a slotless
  A-only device like apollon repacked into **BOOT** (confirmed: `sde50` written
  twice, MI-logo bootloop); and the manual "Flash current OrangeFox" item in
  `advanced.xml` required `tw_has_boot_slots=1`, which only holds with
  `AB_OTA_UPDATER`, hiding the button entirely on A-only devices. Nothing is
  rewritten at build time any more: both override steps just clone our forks
  and print the commit they used, so the build log is the audit trail.
  *(fork: `giou/Recovery@fox_16.0-apollon` `41e0acf5`)*

## Hardware HALs

- **Vibrator**: source-built AIDL HAL repointed to `lineage-24.0` plus a
  source-built `libqtivibratoreffect` (prebuilt deleted). *(vibrator HAL fork +
  tree)*
- **No green notification LED** on apollon → the inert LED setting is hidden
  (`OF_USE_GREEN_LED := 0`). *(tree: `fox_apollon.mk`)*

## Kernel

- **The kernel is compiled from our fork, not extracted.** The builder clones
  `giou/android_kernel_xiaomi_sm8250@lineage-24.0-apollon` and builds `Image`
  with LOS's own config set for this device (from
  `android_device_xiaomi_sm8250-common@lineage-24.0` +
  `android_device_xiaomi_apollon@lineage-24.0`):
  `vendor/kona-perf_defconfig` + `vendor/debugfs.config` +
  `vendor/xiaomi/sm8250-common.config` + `vendor/xiaomi/apollo.config`, which
  enable `CONFIG_LTO_CLANG` (+ `CONFIG_THINLTO`) + `CONFIG_CFI_CLANG` — i.e.
  LTO + KCFI exactly as LOS ships it. Toolchain: the clang this tree already
  carries (`clang-r547379`), used with `LLVM=1` on **both** the config phase and
  the build so lld and llvm-ar come from the same prebuilt. The built `Image` is
  installed over `prebuilt/apollon/kernel`; the committed prebuilt remains as a
  one-commit rollback.
  - Two traps, both hit while bringing this up. (1) `apollo.config` is not
    optional: it carries `CONFIG_MACH_XIAOMI_APOLLO`, which selects
    `CONFIG_MACH_XIAOMI_SM8250` and is what supplies the touchscreen driver —
    without it the kernel has no touch in recovery, and it surfaces only by luck
    (upstream code guarded on that symbol leaves variables unused, which
    `CONFIG_CC_WERROR=y` turns into a build failure). (2) `LLVM=1` must be
    passed to `defconfig`/`olddefconfig` too: `LTO_CLANG` and `CFI_CLANG` depend
    on `CC_IS_CLANG && LD_IS_LLD`, so a config phase run with the host gcc
    silently resolves the choice to `CONFIG_LTO_NONE` — no LTO, no CFI.
  - LOS's own kernel images are produced by their kernel CI with a *built* LLVM
    (`llvm-r596125-release`, clang 22.0.2) **plus PGO/BOLT/MLGO profile data** —
    not reproducible from public prebuilts. We match their config/flags, not
    their exact binary; if the tree's clang ever misbehaves, pin its newer
    sibling next.
  - `dtb` and `recovery_dtbo` deliberately stay the LOS blobs: our fork is the
    same kernel commit they were generated from and our only change is in the
    Image, so they stay consistent (and the proven boot data is untouched).
  - The build step asserts instead of trusting the merge: the clone must contain
    the patch (`scm_interrupted_give_up`), the merged config must have
    `MACH_XIAOMI_APOLLO`, `MACH_XIAOMI_SM8250`,
    `TOUCHSCREEN_NT36xxx_HOSTDL_SPI`, `LTO_CLANG` and `CFI_CLANG` set, and the
    built image must contain the patch's log string (`returned INTERRUPTED`).
- **`SCM_INTERRUPTED` retry bound — REMOVED 2026-10-14.** `drivers/soc/qcom/scm.c`
  carried a 2 s / 1e6-retry bound (`f56cbb55`) while the occurrence-4 SMC-spin
  was thought to be the bug. Occurrence 5 proved the
  recurring stall is a userspace RPMB livelock whose SMCs all complete, which
  no SMC-level bound can catch — and the user ordered the patch out. Both
  commits are gone from the branch (reset to pristine 2026-10-14; the attempt
  is archived as tag `archive/scm-interrupted-bound-attempt`).
  The source-build pipeline is unchanged (same config/toolchain/asserts minus
  the patch-string check). See [`docs/DECRYPT-STALL.md`](docs/DECRYPT-STALL.md).

## Known issues carried (not fixed)

- **Intermittent decrypt stall (TEE wedge).** ~1 in 5–10 decrypts wedge inside
  the gatekeeper → `/dev/qseecom` → QTEE path; only a reboot clears it. Root
  cause localized, kernel-side, unresolved — see
  [`docs/DECRYPT-STALL.md`](docs/DECRYPT-STALL.md).
- **`ds28e16` kernel log spam.** The (replacement) battery lacks the Maxim
  1-Wire authenticator, so the driver retries. Harmless. *(documented in
  `README.md`)*
