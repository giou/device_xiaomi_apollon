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
OF_USE_GREEN_LED := 0
OF_NO_TREBLE_COMPATIBILITY_CHECK := 1
OF_MAINTAINER := giou
FOX_MAINTAINER_PATCH_VERSION := 1

# Fox Addons payload (installer zip only; the .img carries none of this):
# drop AromaFM (32-bit binary from 2012, segfaults on A16) and bundle
# Magisk 31 instead of upstream's 30.7. "?=" keeps this overridable from
# the environment - the builder passes an absolute path; local builds
# fall back to the tree-relative copy fetched alongside the tree.
FOX_DELETE_AROMAFM := 1
FOX_USE_SPECIFIC_MAGISK_ZIP ?= $(DEVICE_PATH)/magisk/Magisk-v31.0.zip

OF_ENABLE_LPTOOLS := 1
OF_QUICK_BACKUP_LIST := /boot;/data;

# apollon runs LOS only: no MIUI props exist to find, so skip the
# MIUI-specific checks outright (upstream claims ~0.5s off boot;
# actual delta TBD from boot timestamps, harmless either way)
OF_NO_ADDITIONAL_MIUI_PROPS_CHECK := 1

# apollon has no hardware navigation buttons: forbid hiding the
# on-screen navbar (OF_ALLOW_DISABLE_NAVBAR defaults to 1, which would
# strand users with no way back)
OF_ALLOW_DISABLE_NAVBAR := 0

# Keymaster 4.0 is proven in the decrypt logs ("Using keymaster version
# '4.x'"); pin it as the default so a failed auto-detect can't silently
# change it. A ROM using another version still overrides this.
OF_DEFAULT_KEYMASTER_VERSION := 4.0

# avb 2.0
OF_PATCH_AVB20 := 1

# try to prevent potential data format errors
OF_UNBIND_SDCARD_F2FS := 1

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
