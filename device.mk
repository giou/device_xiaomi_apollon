#
# Copyright (C) 2020 The TwrpBuilder Open-Source Project
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

# Configure base.mk
$(call inherit-product, $(SRC_TARGET_DIR)/product/base.mk)

# Configure core_64_bit_only.mk
$(call inherit-product, $(SRC_TARGET_DIR)/product/core_64_bit_only.mk)

# Configure twrp
$(call inherit-product, vendor/twrp/config/common.mk)

# NOTE (fox_16.0): no HIDL boot/health HAL packages - they do not exist in
# the 16.0 manifest, and apollon is A-only (dedicated /recovery, no slots).

# Vibrator HAL (AIDL) built from source - vendor/qcom/opensource/vibrator
# via twrp.dependencies. Replaces the dead 2023 prebuilt HIDL binary.
PRODUCT_PACKAGES += \
    vendor.qti.hardware.vibrator.service

# Recovery-only build with prebuilt kernel: skip OTA kernel VINTF check
PRODUCT_OTA_ENFORCE_VINTF_KERNEL_REQUIREMENTS := false

# SHIPPING API - 29 for FBEv1 (ice), 30 for FBEv2
PRODUCT_SHIPPING_API_LEVEL := 29

# VNDK API
PRODUCT_TARGET_VNDK_VERSION := 31

# Soong namespaces
PRODUCT_SOONG_NAMESPACES += \
    $(DEVICE_PATH)

PRODUCT_USE_DYNAMIC_PARTITIONS := true

# apollon is A-only (no slots). The 16.0 build system switches
# AB_OTA_UPDATER on for dynamic-partition devices, which wrongly shows
# dead Slot A/B buttons in the reboot menu. Force it off; verified via the
# "AB_OTA_UPDATER :=" line in the build/recovery log.
AB_OTA_UPDATER := false

# otacert (LineageOS-official target: no MIUI keys)
PRODUCT_EXTRA_RECOVERY_KEYS += \
    $(DEVICE_PATH)/security/magisk

PRODUCT_PROPERTY_OVERRIDES += ro.twrp.device.name=apollon

TWRP_REQUIRED_MODULES += apollon_firmware_prebuilt \
    erofsfuse.recovery
