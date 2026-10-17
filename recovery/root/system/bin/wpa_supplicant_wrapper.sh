#!/system/bin/sh
# The recovery has no syslogd: init running wpa_supplicant directly with -s
# makes it exit 0 instantly. Run it through this wrapper (no -s) instead.
exec /system/bin/wpa_supplicant "$@"
