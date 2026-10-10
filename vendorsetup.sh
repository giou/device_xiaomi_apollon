#
# OrangeFox vendorsetup.sh for apollon (Mi 10T / 10T Pro / Redmi K30S Ultra)
#
# Minimal, mondrian-style: FDEVICE guard so these exports only apply to
# apollon builds (the fox_16.0 manifest also ships mondrian/sm84xx trees
# whose vendorsetup.sh files are all sourced at lunch time).
#
# Shell-only vars (per OrangeFox docs these MUST be set here, not in .mk):
# FOX_USE_BASH_SHELL, FOX_ASH_IS_BASH, FOX_USE_TAR_BINARY,
# FOX_USE_SED_BINARY, FOX_USE_XZ_UTILS, FOX_USE_NANO_EDITOR, FOX_USE_ZIP_BINARY.
# Everything else lives in fox_apollon.mk / BoardConfig.mk.
#

FDEVICE="apollon"

fox_get_target_device() {
local chkdev=$(echo "$BASH_SOURCE" | grep -w \"$FDEVICE\")
   if [ -n "$chkdev" ]; then
      FOX_BUILD_DEVICE="$FDEVICE"
   else
      chkdev=$(set | grep BASH_ARGV | grep -w \"$FDEVICE\")
      [ -n "$chkdev" ] && FOX_BUILD_DEVICE="$FDEVICE"
   fi
}

if [ -z "$1" -a -z "$FOX_BUILD_DEVICE" ]; then
   fox_get_target_device
fi

if [ "$1" = "$FDEVICE" -o "$FOX_BUILD_DEVICE" = "$FDEVICE" ]; then
	export FOX_USE_BASH_SHELL=1
	export FOX_ASH_IS_BASH=1
	export FOX_USE_TAR_BINARY=1
	export FOX_USE_SED_BINARY=1
	export FOX_USE_XZ_UTILS=1
	export FOX_USE_NANO_EDITOR=1
	export FOX_USE_ZIP_BINARY=1
	export OF_USE_GREEN_LED=0

	# log the build vars for debugging
	if [ -n "$FOX_BUILD_LOG_FILE" -a -f "$FOX_BUILD_LOG_FILE" ]; then
	   export | grep "FOX" >> $FOX_BUILD_LOG_FILE
	   export | grep "OF_" >> $FOX_BUILD_LOG_FILE
	   export | grep "TARGET_" >> $FOX_BUILD_LOG_FILE
	   export | grep "TW_" >> $FOX_BUILD_LOG_FILE
	fi
else
	if [ -z "$FOX_BUILD_DEVICE" -a -z "$BASH_SOURCE" ]; then
		echo "I: This script requires bash. Not processing the $FDEVICE $(basename $0)"
	fi
fi
#
