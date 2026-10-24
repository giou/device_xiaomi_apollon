#
#	This file is part of the OrangeFox Recovery Project
# 	Copyright (C) 2021-2023 The OrangeFox Recovery Project
#
#	OrangeFox is free software: you can redistribute it and/or modify
#	it under the terms of the GNU General Public License as published by
#	the Free Software Foundation, either version 3 of the License, or
#	any later version.
#
#	OrangeFox is distributed in the hope that it will be useful,
#	but WITHOUT ANY WARRANTY; without even the implied warranty of
#	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#	GNU General Public License for more details.
#
# 	This software is released under GPL version 3 or any later version.
#	See <http://www.gnu.org/licenses/>.
#
# 	Please maintain this if you use this script or any part of it
#

# OrangeFox-specific settings - cleaned for fox_16.0 / LOS official
# (removed: FOX_VERSION [obsolete], OF_DONT_PATCH_ENCRYPTED_DEVICE /
#  OF_KEEP_DM_VERITY [always-on], OF_SUPPORT_ALL_BLOCK_OTA_UPDATES /
#  OF_FIX_OTA_UPDATE_MANUAL_FLASH_ERROR / OF_DISABLE_MIUI_OTA_BY_DEFAULT /
#  OF_NO_MIUI_PATCH_WARNING [legacy], OF_IGNORE_LOGICAL_MOUNT_ERRORS [obsolete])
# (minimal-delta pass: OF_NO_TREBLE_COMPATIBILITY_CHECK,
#  OF_QUICK_BACKUP_LIST, OF_UNBIND_SDCARD_F2FS, OF_DEFAULT_KEYMASTER_VERSION
#  all dropped - defaults or untriggered insurance; re-add on evidence)
# apollon has no notification LED (/sys/class/leds/green doesn't exist -
# confirmed in dmesg); hide the inert setting
OF_USE_GREEN_LED := 0
OF_MAINTAINER := giou

# WiFi in recovery + fox_adbd (network ADB, incl. pairing) + web dashboard.
# Needs the wpa_supplicant_8/ttyd sources (see twrp.dependencies) and the modem
# partition mounted at /vendor/firmware_mnt in recovery (see recovery.fstab).
OF_ENABLE_WLAN := 1
FOX_REMOTE_DASHBOARD := 1
FOX_MAINTAINER_PATCH_VERSION := 4

# Logical-partition toolkit — official/miatoll parity.
#   OF_ENABLE_LPTOOLS=1            -> external/lptools (lptools binary)
#   OF_ENABLE_ALL_PARTITION_TOOLS=1 -> also lpmake/lpadd/lpflash/lpunpack
#                                      + lpdump/lpdumpd/bootctl
# Supersedes the earlier TW_EXCLUDE_LPDUMP/TW_EXCLUDE_LPTOOLS purge (see
# BoardConfig.mk). Requires external/lptools sources, which the OrangeFox
# manifest ships (twrp-default.xml -> phhusson/vendor_lptools) and repo sync
# clones — same as the official miatoll tree (flags only, no builder step).
OF_ENABLE_LPTOOLS := 1
OF_ENABLE_ALL_PARTITION_TOOLS := 1

# Fox Addons payload (installer zip only; the .img carries none of this):
# drop AromaFM (32-bit binary from 2012, segfaults on A16) and bundle
# Magisk 31 instead of upstream's 30.7. "?=" keeps this overridable from
# the environment - the builder passes an absolute path; local builds
# fall back to the tree-relative copy fetched alongside the tree.
FOX_DELETE_AROMAFM := 1
FOX_USE_SPECIFIC_MAGISK_ZIP ?= $(DEVICE_PATH)/magisk/Magisk-v31.0.zip

# (minimal-delta: lptools/lpdump dropped - zero runtime invocations in
# recovery source or vendor scripts; super backup uses dd, flashing uses
# the updater. Re-add if a flow ever needs logical-partition tools.)

# apollon runs LOS only: no MIUI props exist to find, so skip the
# MIUI-specific checks outright (upstream claims ~0.5s off boot;
# actual delta TBD from boot timestamps, harmless either way)
OF_NO_ADDITIONAL_MIUI_PROPS_CHECK := 1

# apollon has no hardware navigation buttons: forbid hiding the
# on-screen navbar (OF_ALLOW_DISABLE_NAVBAR defaults to 1, which would
# strand users with no way back)
OF_ALLOW_DISABLE_NAVBAR := 0

# EXPERIMENTAL TEST VARIANT (not for release): strip MIUI-specific
# features and the OTA menu, skip install-time patching. Proves whether
# the LOS-only path is identical without them. Doubles as the vote on
# the pending ON-test: this variant cannot run it (no UI, defaults off).
FOX_VANILLA_BUILD := 1
OF_DISABLE_MIUI_SPECIFIC_FEATURES := 1

# avb 2.0
OF_PATCH_AVB20 := 1

# maximum permissible splash image size (in kilobytes); do *NOT* increase!
OF_SPLASH_MAX_SIZE := 130

# screen settings
OF_SCREEN_H := 2400
OF_STATUS_H := 100
OF_STATUS_INDENT_LEFT := 150
OF_STATUS_INDENT_RIGHT := 48
OF_HIDE_NOTCH := 1
OF_CLOCK_POS := 1
#
