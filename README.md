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
- OTA updater entry hidden (it only serves official builds)
- Maintainer avatar in the About page
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

## Branches

- **`fox_16.0`** — mainline (default). Builds Android 16 native code with the `fox_16.0` manifest (SDK 36).
- **`fox_16.0-wlan`** — mainline plus the wireless recovery work described below.

## Wireless flavor (`fox_16.0-wlan`)

Additions and fixes on this branch, on top of the mainline tree and upstream
OrangeFox. The recovery-side changes live in the
[`giou/Recovery`](https://github.com/giou/Recovery) fork, branch
`fox_16.0-apollon-wlan`; the CI is the workflow in this repo.

**WLAN**
- Bring-up as a tested ramdisk script: a `wlan_bringup` init service with a
  seclabel trigger, executed through `/system/bin/sh`, with a
  firmware-ready wait and the driver-on write (`9d4774c`, `6d6f2e7`,
  `ff8f368`, `1db0daf`).
- Async WLAN engine with saved-network connect, and a 120 s allowance for
  the cold bring-up before `enable` reports failure (`61400763`).
- Hands-off autostart: `of_wlan_auto_enable`, `of_wlan_auto_connect`,
  `of_adbd_auto` and `of_wlan_last_ssid` are persisted (settings file + the
  `/persist` mirror) and re-applied after FBE decrypt, so a cold boot joins
  the saved network and starts network ADB with no prep
  (`1bdd1c64`, `26d53dbc`, `2dfc5f1b`, `004e5409`).

**Network ADB**
- The paired-ADB TLS server is pinned to a fixed port: a CI patch teaches
  the AOSP daemon to honor `service.adb.tls_server.port`, the fork sets it,
  and WiFi settings expose a "Network ADB automatically" toggle
  (`91e7fcb`, `10d54db`, `abd6de74`).

**Network Storage (NAS)**
- OrangeFox Network Storage enabled end-to-end: `rclone` + `fusermount3`
  are cloned via `twrp.dependencies`, and the build fails if a wlan ramdisk
  lacks them (`98b4da9`, `9848b67`).
- Passwordless SFTP via `tw_nas_key` (`18fad9d3`); headless
  `fox nas mount|unmount|status` (`0d55348c`); dead-mount recovery and an
  upload-wait driven by rclone's live queues (`db2e0d94`, `86d74718`).
- Verified end-to-end on apollon: encrypted (and optionally compressed)
  `/data` + Internal Storage backups over SFTP to a Windows share, digests
  included, with the write-back cache mode for speed.

**Recovery-engine fixes that came out of this work**
- Fox RPC: no engine wedge on the action-slot race (`ab9398ba`); encrypted
  backup/restore accept password arguments (`1dc8f297`).
- Digest driver digests every split chunk of encrypted backups
  (`89fcc475`); empty-tar chunks are accepted on restore (`18576f84`).
- Backup names stay portable and survive `Update_System_Details`
  (`2c681d84`, `87d38bed`, `eec02792`); gatekeeper decrypt retry and
  `/cache` OAES backups (`eec02792`, `62b8f3f`); the CA store ships for
  in-recovery TLS clients (`d2e4c734`).

**CI (this repo)**
- Dual-variant workflow (mainline + wlan, `-wlan` asset tags), persistent
  ccache, auto-generated release notes, plus the NAS dependency/assert and
  adbd patch steps above. An optional self-hosted WSL runner (`runner`
  input, on-demand) shortens the wall-clock for local builds.

**Recent hardening (v17–v20, 2026-10-18/19)**
- The WiFi sockets shield is narrowed to `/data/vendor/wifi/sockets` only —
  the earlier whole-directory tmpfs hid `wlfw_cal_01.bin` and broke
  calibration (`ddfc9f7`).
- The connect paths read the interface IP from the kernel (`SIOCGIFADDR`;
  the dhcp client never reports the lease into supplicant STATUS), `fox wlan
  info` prints ssid + IP, and the IP is published as `sys.fox.wlan.ip`.
- The connection test uses native TCP + DNS (there is no busybox/ping in the
  ramdisk, and ICMP datagrams are blocked) and `/etc/resolv.conf` is written
  from the DHCP-provided servers.
- NAS: the mount flow self-mounts `/persist` (the key must be readable), the
  NAS page refresh runs off the worker thread (no more "threaded action"
  rejections during a backup), sftp hides the SMB-only fields, and the SFTP
  key file is editable in the UI.
- Restore digest checks are on by default (opt-out with
  `"digest_check":false`).

## Credits

- Base tree: [MurtazaKolachi/device_xiaomi_ofox_apollo](https://github.com/MurtazaKolachi/device_xiaomi_ofox_apollo)
  (`ofox` branch) and [sekaiacg/android_device_xiaomi_umi_TWRP](https://github.com/sekaiacg/android_device_xiaomi_umi_TWRP)
  (SKKK FBEv1 reference)
- LOS device/kernel/vendor: LineageOS + TheMuppets (`apollon`, `sm8250-common`)
- Vibrator HAL: `LineageOS/android_vendor_qcom_opensource_vibrator`
- OrangeFox Recovery Project
