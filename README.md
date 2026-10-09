#  Recovery Tree for Xiaomi Mi 10T/Mi 10T Pro (apollo)

## Device specifications

| Feature                 | Specification                                                              |
| :---------------------- | :--------------------------------                                          |
| CPU                     | Octa-core (1x2.84 GHz Kryo 585 & 3x2.42 GHz Kryo 585 & 4x1.80 GHz Kryo 585)|
| Chipset                 | Qualcomm SM8250 Snapdragon 865 (7 nm)                                      |
| GPU                     | Adreno 650                                                                 |
| Memory                  | 6 GB / 8 GB                                                                |
| Shipped Software        | Android 10, MIUI 12                                                        |
| Storage                 | 128 GB / 256 GB                                                            |
| Battery                 | 5000 mAh                                                                   |
| Dimensions              | 165.1 x 76.4 x 9.3 mm (6.5 x 3.01 x 0.37 in)                               |
| Display                 | 6.67 inches, 107.4 cm2 (~85.2% screen-to-body ratio)                       |
| Rear Camera             | 64 MP, f/1.9, 26mm (wide), 1/1.73", 0.8µm, PDAF                            |
|                         | 13 MP, f/2.4, 123 (ultrawide), 1.12µm                                     |
|                         | 5 MP, f/2.4, (macro), AF                                                   |
| Front Camera            | 20 MP, f/2.2, 27mm (wide), 1/3.4", 0.8µm                                   |
| Release Date            | October 2020                                                               |

## Device Picture

![Xiaomi Mi 10T/Mi 10T Pro](https://www.bug.hr/img/xiaomi-mi-10t-serija-telefona-za-kreativce_oFqltN.png "Xiaomi Mi 10T/Mi 10T Pro/Redmi K30S Ultra")

## Features

**Works**

- Booting.
- **Decryption** (Android 16)
- ADB
- MTP
- OTG
- Super partition functions
- Vibration

## Compile

First checkout minimal twrp with omnirom tree:

```
repo init -u git://github.com/minimal-manifest-twrp/platform_manifest_twrp_aosp.git -b twrp-11
repo sync
```

Then clone the recovery tree of your choice:

```
git clone https://github.com/murtazakolachi/device_xiaomi_apollo_recovery -b twrp device/xiaomi/apollo
```

Use ccache
```
#Enable ccache
export USE_CCACHE=1
export CCACHE_EXEC=$(which ccache)
```

Finally execute these:

```
export ALLOW_MISSING_DEPENDENCIES=true
. build/envsetup.sh
lunch twrp_apollo-eng
mka recoveryimage
```

To test it:

```
fastboot boot out/target/product/apollo/recovery.img
```

## Thanks
- [FsCrypt fix by mauronofrio](https://github.com/mauronofrio/android_bootable_recovery)
- [Decryption by bigbiff](https://github.com/bigbiff/android_bootable_recovery)
- [Oneplus 8 TWRP by mauronofrio](https://github.com/mauronofrio/android_device_oneplus_instantnoodle_TWRP)
