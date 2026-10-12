#
# Copyright (C) 2019 The TwrpBuilder Open-Source Project
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

ALLOW_MISSING_DEPENDENCIES := true

# Architecture
TARGET_ARCH := arm64
TARGET_ARCH_VARIANT := armv8-a
TARGET_CPU_ABI := arm64-v8a
TARGET_CPU_ABI2 :=
TARGET_CPU_VARIANT := kryo
TARGET_CPU_VARIANT_RUNTIME := kryo585

TARGET_2ND_ARCH := arm
TARGET_2ND_ARCH_VARIANT := armv8-a
TARGET_2ND_CPU_ABI := armeabi-v7a
TARGET_2ND_CPU_ABI2 := armeabi
TARGET_2ND_CPU_VARIANT := kryo
TARGET_2ND_CPU_VARIANT_RUNTIME := $(TARGET_CPU_VARIANT_RUNTIME)

ENABLE_CPUSETS := true
ENABLE_SCHEDBOOST := true

# Bootloader
PRODUCT_PLATFORM := kona
TARGET_BOOTLOADER_BOARD_NAME := apollon
TARGET_NO_BOOTLOADER := true
TARGET_USES_UEFI := true

# Platform
TARGET_BOARD_PLATFORM := xiaomi_sm8250
TARGET_BOARD_PLATFORM_GPU := qcom-adreno650
QCOM_BOARD_PLATFORMS += xiaomi_sm8250

# Kernel
BOARD_KERNEL_CMDLINE := console=ttyMSM0,115200n8 androidboot.hardware=qcom androidboot.console=ttyMSM0 androidboot.memcg=1 lpm_levels.sleep_disabled=1 video=vfb:640x400,bpp=32,memsize=3072000 msm_rtb.filter=0x237 service_locator.enable=1 androidboot.usbcontroller=a600000.dwc3 swiotlb=2048 loop.max_part=7 cgroup.memory=nokmem,nosocket reboot=panic_warm buildvariant=user
BOARD_KERNEL_CMDLINE += androidboot.selinux=permissive
BOARD_BOOT_HEADER_VERSION := 2
BOARD_KERNEL_HEADER_VERSION := $(BOARD_BOOT_HEADER_VERSION)
BOARD_KERNEL_IMAGE_NAME := Image
BOARD_KERNEL_PAGESIZE := 4096
BOARD_KERNEL_BASE          := 0x00000000
BOARD_KERNEL_TAGS_OFFSET   := 0x00000100
BOARD_KERNEL_OFFSET        := 0x00008000
BOARD_KERNEL_SECOND_OFFSET := 0x00f00000
BOARD_RAMDISK_OFFSET       := 0x01000000
TARGET_KERNEL_ARCH := arm64
TARGET_PREBUILT_KERNEL := $(DEVICE_PATH)/prebuilt/apollon/kernel

BOARD_MKBOOTIMG_ARGS += --header_version $(BOARD_KERNEL_HEADER_VERSION)
BOARD_MKBOOTIMG_ARGS += --pagesize $(BOARD_KERNEL_PAGESIZE)
BOARD_MKBOOTIMG_ARGS += --base $(BOARD_KERNEL_BASE)
BOARD_MKBOOTIMG_ARGS += --ramdisk_offset $(BOARD_RAMDISK_OFFSET)
BOARD_MKBOOTIMG_ARGS += --tags_offset $(BOARD_KERNEL_TAGS_OFFSET)
BOARD_MKBOOTIMG_ARGS += --kernel_offset $(BOARD_KERNEL_OFFSET)
BOARD_MKBOOTIMG_ARGS += --second_offset $(BOARD_KERNEL_SECOND_OFFSET)

# Kenel dtb
# BOARD_INCLUDE_DTB_IN_BOOTIMG := true
INSTALLED_DTBIMAGE_TARGET := $(DEVICE_PATH)/prebuilt/apollon/dtb
BOARD_DTB_OFFSET := 0x01f00000
BOARD_MKBOOTIMG_ARGS += --dtb $(INSTALLED_DTBIMAGE_TARGET)
BOARD_MKBOOTIMG_ARGS += --dtb_offset $(BOARD_DTB_OFFSET)

# Kenel recovery dtbo
BOARD_INCLUDE_RECOVERY_DTBO := true
BOARD_PREBUILT_RECOVERY_DTBOIMAGE := $(DEVICE_PATH)/prebuilt/apollon/recovery_dtbo

# QCOM
#TARGET_USE_SDCLANG := true

# Assert
TARGET_OTA_ASSERT_DEVICE := apollon,apollo,apollopro

# Avb
BOARD_AVB_ENABLE := true
BOARD_AVB_ROLLBACK_INDEX := $(PLATFORM_SECURITY_PATCH_TIMESTAMP)
BOARD_AVB_RECOVERY_ALGORITHM := SHA256_RSA4096
BOARD_AVB_RECOVERY_KEY_PATH := external/avb/test/data/testkey_rsa4096.pem
BOARD_AVB_RECOVERY_ROLLBACK_INDEX := $(PLATFORM_SECURITY_PATCH_TIMESTAMP)
BOARD_AVB_RECOVERY_ROLLBACK_INDEX_LOCATION := 1

# Partitions
BOARD_RECOVERYIMAGE_PARTITION_SIZE := 134217728

# Dynamic Partition
BOARD_SUPER_PARTITION_SIZE := 9126805504
BOARD_SUPER_PARTITION_GROUPS := qti_dynamic_partitions
BOARD_QTI_DYNAMIC_PARTITIONS_SIZE := 9122611200
BOARD_QTI_DYNAMIC_PARTITIONS_PARTITION_LIST := product vendor system system_ext odm

# System as root
BOARD_ROOT_EXTRA_FOLDERS := bluetooth dsp firmware persist
BOARD_SUPPRESS_SECURE_ERASE := true

# File systems
TARGET_USERIMAGES_USE_EXT4 := true
TARGET_USERIMAGES_USE_F2FS := true

# Workaround for error copying vendor files to recovery ramdisk
BOARD_VENDORIMAGE_FILE_SYSTEM_TYPE := ext4
TARGET_COPY_OUT_VENDOR := vendor

#Init
TARGET_INIT_VENDOR_LIB := //$(DEVICE_PATH):libinit_apollo
TARGET_RECOVERY_DEVICE_MODULES := libinit_apollo

# Vibrator HAL into the recovery ramdisk (source-built via
# vendor/qcom/opensource/vibrator). libexpat: the impl parses
# HapticsPolicy.xml at runtime (same as reference 16.0 trees).
# libqtivibratoreffect (non-offload) is source-built too, not taken from
# the old recovery/root prebuilt: 24.0's OL.impl links it (effect_lib
# default) and the prebuilt's era is unverified. Deleted prebuilts that
# nothing loads (proven: no NEEDED refs in any shipped binary, and the
# LOS 24 ROM itself ships neither): vibrator.default.so (legacy HIDL),
# libsoc_helper.so (dep dropped in 24.0), excluded-input-devices.xml
# (framework-only; inputflinger doesn't run in recovery), and the 2MB
# system/bin/busybox (zero refs anywhere; Magisk uses its own bundled
# busybox; vendor actively deletes /sbin/busybox unless requested).
TARGET_RECOVERY_DEVICE_MODULES += \
    vendor.qti.hardware.vibrator.service \
    vendor.qti.hardware.vibrator.impl \
    vendor.qti.hardware.vibratorOL.impl \
    vendor.qti.hardware.vibratorSel.impl \
    libqtivibratoreffect \
    libqtivibratoreffectoffload \
    libexpat
RECOVERY_LIBRARY_SOURCE_FILES += \
    $(TARGET_OUT_SHARED_LIBRARIES)/libexpat.so
BOARD_RECOVERY_IMAGE_PREPARE += \
    mkdir -p $(TARGET_RECOVERY_ROOT_OUT)/vendor/bin/hw $(TARGET_RECOVERY_ROOT_OUT)/vendor/lib64/hw; \
    if [ -f $(TARGET_OUT_VENDOR_EXECUTABLES)/hw/vendor.qti.hardware.vibrator.service ]; then \
        cp -f $(TARGET_OUT_VENDOR_EXECUTABLES)/hw/vendor.qti.hardware.vibrator.service $(TARGET_RECOVERY_ROOT_OUT)/vendor/bin/hw/; \
        cp -f $(TARGET_OUT_VENDOR_SHARED_LIBRARIES)/*vibrator*.so $(TARGET_RECOVERY_ROOT_OUT)/vendor/lib64/; \
    else \
        echo "ERROR: vibrator HAL not built - was vendor/qcom/opensource/vibrator synced via twrp.dependencies?"; \
        exit 1; \
    fi;
# The "Flash current OrangeFox" repacker rebuilds the ramdisk from the live
# root fs using ramdisk-files.txt - which is generated BEFORE this hook runs.
# Any NEW path staged here is therefore silently dropped from repacked images
# (proven on v8: the staged HAL below was lost -> no vibrator service, every
# touch stalled 5s waiting for IVibrator). Overwrites of already-listed paths
# (avatar, libqtivibratoreffect.so) are safe. Register each staged file below
# (grep-guarded, idempotent). NOTE: never "cd" in this hook - every PREPARE
# block runs in ONE shell, so a cd here breaks the relative paths of all
# later blocks (this killed v10: the avatar check below it went missing).
# Keep every path absolute except the registered names themselves.
BOARD_RECOVERY_IMAGE_PREPARE += \
    RFL=$(TARGET_RECOVERY_ROOT_OUT)/ramdisk-files.txt; \
    if [ -f "$$RFL" ]; then \
        for f in vendor/bin/hw/vendor.qti.hardware.vibrator.service vendor/lib64/android.hardware.vibrator-V2-ndk.so vendor/lib64/libqtivibratoreffect.so vendor/lib64/libqtivibratoreffectoffload.so vendor/lib64/vendor.qti.hardware.vibrator.impl.so vendor/lib64/vendor.qti.hardware.vibratorOL.impl.so vendor/lib64/vendor.qti.hardware.vibratorSel.impl.so; do \
            [ -e "$(TARGET_RECOVERY_ROOT_OUT)/$$f" ] || continue; \
            grep -qxF "$$f" "$$RFL" || echo "$$f" >> "$$RFL"; \
        done; \
    else \
        echo "WARNING: ramdisk-files.txt not found - repacked images will lack the staged vibrator HAL"; \
    fi;
# Maintainer avatar for the About page (overrides theme default
# twres/images/Default/About/maintainer.png, shown next to OF_MAINTAINER)
BOARD_RECOVERY_IMAGE_PREPARE += \
    if [ -f $(DEVICE_PATH)/avatar/maintainer.png ]; then \
        cp -f $(DEVICE_PATH)/avatar/maintainer.png $(TARGET_RECOVERY_ROOT_OUT)/twres/images/Default/About/maintainer.png; \
    else \
        echo "ERROR: $(DEVICE_PATH)/avatar/maintainer.png missing"; \
        exit 1; \
    fi;

# Recovery
BOARD_HAS_LARGE_FILESYSTEM := true
# NOTE: no surrounding quotes - soong_extra_config.mk emits this raw into
# product_config.json (quoted value breaks JSON parsing on fox_16.0)
TARGET_RECOVERY_PIXEL_FORMAT := RGBX_8888

# Crypto
BOARD_USES_QCOM_FBE_DECRYPTION := true
BOARD_USES_METADATA_PARTITION := true
ifdef DECRYPT_PLATFORM_VERSION
PLATFORM_VERSION := $(DECRYPT_PLATFORM_VERSION)
else
# NOTE: OS version pinned to 99 (same SKKK-class hack as the SPL pin
# below), NOT the manifest's 16. QTI Keymaster binds unwrapping to BOTH
# tags: a recovery reporting an older OS version than the installed ROM
# (16 vs LOS 24's 17 - keys are re-bound on first boot after an OTA)
# fails metadata unwrap exactly like the old SPL mismatch did. Proven
# 2026-10-12: v12 (16) cannot unwrap LOS 24 metadata; the SPL pin's
# success already proves the TA reads recovery props, so this pin rides
# the same channel. Cosmetic side effect: recovery reports release "99".
PLATFORM_VERSION := 99
endif
PLATFORM_VERSION_LAST_STABLE := $(PLATFORM_VERSION)
# NOTE: patch pinned to 2099-12-31 (TWRP/SKKK convention), NOT the ROM's SPL.
# QTI Keymaster unwrapping is version-sensitive: a recovery stamping an older
# SPL than the installed ROM (e.g. 2026-09-01 vs 2026-10-01) fails metadata
# unwrap and breaks decrypt after every monthly OTA. A far-future stamp
# always satisfies version checks, so decrypt survives SPL bumps; only
# kernel/blob drift can still break it (refresh those per nightly).
# Harmless here: bootloader is unlocked, AVB rollback unenforced.
PLATFORM_SECURITY_PATCH := 2099-12-31
VENDOR_SECURITY_PATCH := $(PLATFORM_SECURITY_PATCH)
TW_INCLUDE_CRYPTO := true
TW_INCLUDE_CRYPTO_FBE := true
TW_INCLUDE_FBE_METADATA_DECRYPT := true
TW_USE_FSCRYPT_POLICY := 1
TW_INCLUDE_CRYPTO_FBE_XATTR := true

# Network
BUILD_BROKEN_USES_NETWORK := true

# Tool
TW_INCLUDE_REPACKTOOLS := true
TW_INCLUDE_RESETPROP := true
TW_INCLUDE_LIBRESETPROP := true
TW_INCLUDE_LPDUMP := true
TW_INCLUDE_LPTOOLS := true
TW_HAS_MTP := true
TW_USE_MODEL_HARDWARE_ID_FOR_DEVICE_ID := true
			     
# TWRP specific build flags
TW_THEME := portrait_hdpi
TW_DEVICE_VERSION := apollon-LOS23-16.0-v2
RECOVERY_SDCARD_ON_DATA := true
TARGET_RECOVERY_QCOM_RTC_FIX := true
# TEST (user-ordered): legacy battery services OFF - status-bar % will come
# from the health HAL (GetBatteryInfo()) instead of sysfs. Revert (uncomment
# below) if the percentage misreports. Reference 16.0 trees set this, but
# health-hal-2-1 runs in our recovery so the HAL path may work on apollon.
# TW_USE_LEGACY_BATTERY_SERVICES := true
TW_EXCLUDE_DEFAULT_USB_INIT := true
TW_INCLUDE_NTFS_3G := true
TW_NO_EXFAT_FUSE := true
TW_USE_TOOLBOX := true
TW_BRIGHTNESS_PATH := "/sys/class/backlight/panel0-backlight/brightness"
TW_MAX_BRIGHTNESS := 2047
TW_DEFAULT_BRIGHTNESS := 1433
TWRP_INCLUDE_LOGCAT := true
TARGET_USES_LOGD := true
TW_NO_SCREEN_BLANK := true
TW_SUPPORT_INPUT_AIDL_HAPTICS := true
TW_BACKUP_EXCLUSIONS := /data/fonts,/data/adb/ap,/data/adb/ksu

# Enable early preparation of /data/media for emulated storage
TW_PREPARE_DATA_MEDIA_EARLY := true
