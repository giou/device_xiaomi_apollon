# OrangeFox device tree for Xiaomi apollon (Mi 10T / Mi 10T Pro / Redmi K30S Ultra)

This tree targets official LineageOS 24 (Android 17). It decrypts data with FBEv1 and metadata wrappedkey. It also works on LineageOS 23.2, which uses the same FBEv1 policy.

See [docs/DECRYPT-STALL.md](docs/DECRYPT-STALL.md) for the open decrypt-stall dossier.

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
- Internal storage as backup source
- Correct MTP dates in Windows
- One MTP storage entry
- Automatic USB-OTG mount
- `/usb_otg` mount point
- Custom USB setup
- More languages (Spanish, Hungarian, Simplified/Traditional Chinese)
- Aligned theme text and icons
- Vibrator driver built from source
- No LED setting
- Locked navigation bar
- AVB 2.0 patching
- No MIUI code or updates
- Pinned security patch and OS version
- Recovery build fixes (compiler, repacker, reflash menu)

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

Branch **`fox_16.0`** is the default. It builds Android 16 native code with the `fox_16.0` manifest (SDK 36).

## Credits

- Base tree: [MurtazaKolachi/device_xiaomi_ofox_apollo](https://github.com/MurtazaKolachi/device_xiaomi_ofox_apollo)
  (`ofox` branch) and [sekaiacg/android_device_xiaomi_umi_TWRP](https://github.com/sekaiacg/android_device_xiaomi_umi_TWRP)
  (SKKK FBEv1 reference)
- LOS device/kernel/vendor: LineageOS + TheMuppets (`apollon`, `sm8250-common`)
- Vibrator HAL: `LineageOS/android_vendor_qcom_opensource_vibrator`
- OrangeFox Recovery Project
