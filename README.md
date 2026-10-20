# OrangeFox device tree for Xiaomi apollon (Mi 10T / Mi 10T Pro / Redmi K30S Ultra)

This tree targets official LineageOS 24 (Android 17). It decrypts data with FBEv1 and metadata wrappedkey. It also works on LineageOS 23.2, which uses the same FBEv1 policy.

## Features and custom changes

- Data decryption for LineageOS 24
- TEE cleanup after decrypt
- Readable file names after `/data` remount
- TEE start after storage is ready
- Kernel built from source
- Boot blobs from LineageOS
- Logical partition tools
- Magisk 31, no AromaFM
- Encrypted backups
- Correct MTP dates in Windows
- Automatic USB-OTG mount
- More languages (Spanish, Hungarian, Simplified/Traditional Chinese)
- Aligned theme text and icons
- Vibrator driver built from source
- Recovery WLAN + wireless ADB (hands-off autostart, pre-decrypt auto-join; see the wireless flavor below)
- Network Storage (NAS): SFTP mounts + encrypted backups to a remote share
- Pinned security patch and OS version

| Spec | |
| :--- | :--- |
| SoC | Qualcomm SM8250 Snapdragon 865 |
| CPU | Octa-core Kryo 585 (1x2.84 + 3x2.42 + 4x1.80 GHz) |
| GPU | Adreno 650 |
| RAM | 6 / 8 GB |
| Storage | 128 / 256 GB (FBEv1, `/metadata` wrappedkey) |
| Display | 6.67" 1080x2400 IPS, 144 Hz |
| Battery | 5000 mAh |
| OTA assert | `apollon,apollo,apollopro` |
| Kernel | 4.19.325, built from source (`giou/android_kernel_xiaomi_sm8250@lineage-24.0-apollon`, LOS config set, `clang-r547379` + `LLVM=1`, LTO+CFI). `dtb`/`recovery_dtbo` stay LOS blobs from the same commit |

## Branches

- **`fox_16.0`** — mainline (default). Builds Android 16 native code with the `fox_16.0` manifest (SDK 36).
- **`fox_16.0-wlan`** — mainline plus the wireless recovery work described below.

## Wireless flavor (`fox_16.0-wlan`)

Adds recovery WLAN, network ADB and Network Storage on top of the mainline
tree and upstream OrangeFox. The recovery-side code lives in the
[`giou/Recovery`](https://github.com/giou/Recovery) fork, branch
`fox_16.0-apollon-wlan`; the CI is the workflow in this repo.

**WLAN**
- Ramdisk bring-up: a `wlan_bringup` init service (seclabel trigger) runs
  through `/system/bin/sh`, waits for firmware and switches the driver on.
- Saved-network connect with an async engine and a cold-boot allowance.
- Hands-off autostart: `of_wlan_auto_enable`, `of_wlan_auto_connect`,
  `of_adbd_auto` and `of_wlan_last_ssid` persist across FBE decrypt, so a
  cold boot joins the saved network and starts network ADB.

**Network ADB**
- Paired-ADB TLS server on a fixed port; the "Network ADB automatically"
  toggle lives in WiFi settings.

**Network Storage (NAS)**
- `rclone` + `fusermount3` in the ramdisk; the build fails if a wlan
  ramdisk lacks them.
- Passwordless SFTP via `tw_nas_key`; `fox nas mount|unmount|status`.
- Encrypted (optionally compressed) `/data` + Internal Storage backups to
  the remote share, digests included; write-back cache mode for speed.

**CI (this repo)**
- Dual-variant workflow (mainline + wlan, `-wlan` asset tags), persistent
  ccache, auto-generated release notes, NAS dependency/assert and the adbd
  port patch.

## Credits

- Base tree: [MurtazaKolachi/device_xiaomi_ofox_apollo](https://github.com/MurtazaKolachi/device_xiaomi_ofox_apollo)
  (`ofox` branch) and [sekaiacg/android_device_xiaomi_umi_TWRP](https://github.com/sekaiacg/android_device_xiaomi_umi_TWRP)
  (SKKK FBEv1 reference)
- LOS device/kernel/vendor: LineageOS + TheMuppets (`apollon`, `sm8250-common`)
- Vibrator HAL: `LineageOS/android_vendor_qcom_opensource_vibrator`
- OrangeFox Recovery Project
