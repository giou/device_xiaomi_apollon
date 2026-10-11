# OrangeFox device tree for Xiaomi apollon (Mi 10T / Mi 10T Pro / Redmi K30S Ultra)

Recovery device tree targeting **official LineageOS 23 (Android 16)** with
working data decryption (FBEv1 + metadata wrappedkey).

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
| Kernel | 4.19.325 (LineageOS `android_kernel_xiaomi_sm8250:lineage-23.2` boot image) |

Branch **`fox_16.0`** (default, only branch) — native Android 16 build
(`fox_16.0` manifest, SDK 36).

## Status (fox_16.0)

Not yet device-tested (needs v7 build `38107413049`, in progress):

- "Flash current OrangeFox" button (repacker target fixed, untested)

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
are declared in [twrp.dependencies](twrp.dependencies) and cloned by the
[OrangeFox-Action-Builder](https://github.com/giou/OrangeFox-Action-Builder)
`Clone TWRP dependencies` step — or clone them manually to the listed
`target_path`.

Build:

```
source build/envsetup.sh
lunch twrp_apollon-bp2a-eng
mka adbd recoveryimage
```

Out: `out/target/product/apollon/OrangeFox-R12.0-fox16.0-Unofficial-apollon.img`
(`R12.0` is the OrangeFox release version, not Android; `fox16.0` is the
manifest branch.)

## Notes for maintainers

- FBEv1 (`fileencryption=ice`, `TW_USE_FSCRYPT_POLICY := 1`) matches
  LineageOS. FBEv2 trees are for MIUI/HyperOS and will *not* decrypt LOS.
- Security patch is pinned to 2099-12-31 (SKKK convention): QTI unwrapping
  is version-sensitive, so an honest SPL breaks decrypt on every monthly
  OTA. Far-future stamp survives bumps; refresh kernel/blobs per nightly.
- `vendorsetup.sh` is mondrian-style with an `FDEVICE` guard — the `fox_16.0`
  manifest sources every device tree's `vendorsetup.sh` at lunch.
- `TARGET_RECOVERY_PIXEL_FORMAT` must stay **unquoted**: the 16.0 soong
  config emitter writes it raw into `product_config.json`.
- The vibrator HAL is source-built; `BOARD_RECOVERY_IMAGE_PREPARE` stages it
  into the ramdisk and fails loudly if it wasn't built.

## Credits

- Base tree: [MurtazaKolachi/device_xiaomi_ofox_apollo](https://github.com/MurtazaKolachi/device_xiaomi_ofox_apollo)
  (`ofox` branch) and [sekaiacg/android_device_xiaomi_umi_TWRP](https://github.com/sekaiacg/android_device_xiaomi_umi_TWRP)
  (SKKK FBEv1 reference)
- LOS device/kernel/vendor: LineageOS + TheMuppets (`apollon`, `sm8250-common`)
- Vibrator HAL: `LineageOS/android_vendor_qcom_opensource_vibrator`
- OrangeFox Recovery Project
