# OrangeFox device tree for Xiaomi apollon (Mi 10T / Mi 10T Pro / Redmi K30S Ultra)

Recovery device tree targeting **official LineageOS 24 (Android 17)** with
working data decryption (FBEv1 + metadata wrappedkey). Still works on
LineageOS 23.2 (same FBEv1 policy; the OS-version pin satisfies both).

See **[FIXES.md](FIXES.md)** for the full delta vs stock OrangeFox (what changed
and why), and **[docs/](docs/)** for per-issue detail dossiers.

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
| Kernel | 4.19.325, built from source (`giou/android_kernel_xiaomi_sm8250@lineage-24.0-apollon`, LOS config set, `clang-r547379` + `LLVM=1`, LTO+CFI); `dtb`/`recovery_dtbo` stay LOS blobs from the same commit |

Branch **`fox_16.0`** (default) — native Android 16 build
(`fox_16.0` manifest, SDK 36).

## Build

Sync the `fox_16.0` manifest with the OrangeFox sync script, then clone this
tree to `device/xiaomi/apollon`:

```
./orangefox_sync.sh --branch 16.0 --path ~/OrangeFox_16.0
cd ~/OrangeFox_16.0
git clone --depth=1 --single-branch --branch fox_16.0 \
  https://github.com/giou/device_xiaomi_apollon.git device/xiaomi/apollon
```

Extra sources (`vendor/qcom/opensource/vibrator` for the AIDL vibrator HAL)
are declared in [twrp.dependencies](twrp.dependencies) and cloned by this
repo's own `OrangeFox - Build` workflow (`Clone TWRP dependencies` step) —
or clone them manually to the listed `target_path`.

Build:

```
source build/envsetup.sh
lunch twrp_apollon-bp2a-eng
mka adbd recoveryimage
```

Out: `out/target/product/apollon/OrangeFox-R12.0-fox16.0-Unofficial-apollon.img`
(`R12.0` is the OrangeFox release version, not Android; `fox16.0` is the
manifest branch. Published releases are titled `... (R12.0_<n>)` from
`FOX_MAINTAINER_PATCH_VERSION` in `fox_apollon.mk` — check the recovery
banner matches the file.)

## Notes for maintainers

- FBEv1 (`fileencryption=ice`, `TW_USE_FSCRYPT_POLICY := 1`) matches
  LineageOS. FBEv2 trees are for MIUI/HyperOS and will *not* decrypt LOS.
- Security patch is pinned to 2099-12-31 (SKKK convention): QTI unwrapping
  is version-sensitive, so an honest SPL breaks decrypt on every monthly
  OTA. Far-future stamp survives bumps; refresh kernel/blobs per nightly.
- OS version is pinned to 99 for the same reason: LOS re-binds key blobs
  to the OS version on boot, so a recovery reporting older (16 vs 17)
  fails metadata unwrap. 99 satisfies both LOS 23 and 24.
- `vendorsetup.sh` is mondrian-style with an `FDEVICE` guard — the `fox_16.0`
  manifest sources every device tree's `vendorsetup.sh` at lunch.
- "Flash current OrangeFox" persists the *running* version (partition
  kernel + live ramdisk); moving versions needs the full zip, which
  carries a matched kernel+ramdisk pair.
- `TARGET_RECOVERY_PIXEL_FORMAT` must stay **unquoted**: the 16.0 soong
  config emitter writes it raw into `product_config.json`.
- `ds28e16: Failed to reset ds28e16!` dmesg spam is the Maxim 1-Wire
  battery authenticator not answering — expected with a replacement
  (non-original) battery pack, which lacks the chip. Harmless: fuel
  gauge, charging, and decrypt are independent of it. Do not "fix".
- The vibrator HAL is source-built; `BOARD_RECOVERY_IMAGE_PREPARE` stages it
  into the ramdisk and fails loudly if it wasn't built.

## Credits

- Base tree: [MurtazaKolachi/device_xiaomi_ofox_apollo](https://github.com/MurtazaKolachi/device_xiaomi_ofox_apollo)
  (`ofox` branch) and [sekaiacg/android_device_xiaomi_umi_TWRP](https://github.com/sekaiacg/android_device_xiaomi_umi_TWRP)
  (SKKK FBEv1 reference)
- LOS device/kernel/vendor: LineageOS + TheMuppets (`apollon`, `sm8250-common`)
- Vibrator HAL: `LineageOS/android_vendor_qcom_opensource_vibrator`
- OrangeFox Recovery Project
