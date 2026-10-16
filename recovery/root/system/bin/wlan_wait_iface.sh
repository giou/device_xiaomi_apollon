#!/system/bin/sh
# Wait for a network interface to exist (bounded), used by the fox WLAN
# bring-up so wpa_supplicant is not started before the QCA6390 host driver
# has probed and created wlan0.
for i in $(seq 1 60); do
    ifconfig "$1" >/dev/null 2>&1 && exit 0
    sleep 1
done
exit 1
