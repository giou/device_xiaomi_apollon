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
- **Backup-encryption prompt layout.** On the *encrypted-backup restore* page the
  `(i)` icon overlapped the prompt text, and the "Password" field sat in the
  caption column (`%col1_x_caption%`, 216) where its width (`%input_w%`, 984) ran
  off the 1080 screen. The prompt text now sits just past the icon
  (`%col1_x_small_indent%`, 150) and the caption/input/underline/failure-text
  group is left-aligned with the page body (`%col1_x%`, 48) — 48+984 = 1032, so
  it fits with the usual 48 px margin. *(recovery fork:
  `gui/theme/portrait_hdpi/pages/restore.xml`)*

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
- **Kernel / dtb / dtbo are extracted (not built) from the LOS 24 boot image**,
  keeping them byte-identical to LineageOS. *(builder)*

## Hardware HALs

- **Vibrator**: source-built AIDL HAL repointed to `lineage-24.0` plus a
  source-built `libqtivibratoreffect` (prebuilt deleted). *(vibrator HAL fork +
  tree)*
- **No green notification LED** on apollon → the inert LED setting is hidden
  (`OF_USE_GREEN_LED := 0`). *(tree: `fox_apollon.mk`)*

## Known issues carried (not fixed)

- **Intermittent decrypt stall (TEE wedge).** ~1 in 5–10 decrypts wedge inside
  the gatekeeper → `/dev/qseecom` → QTEE path; only a reboot clears it. Root
  cause localized, kernel-side, unresolved — see
  [`docs/DECRYPT-STALL.md`](docs/DECRYPT-STALL.md).
- **`ds28e16` kernel log spam.** The (replacement) battery lacks the Maxim
  1-Wire authenticator, so the driver retries. Harmless. *(documented in
  `README.md`)*
