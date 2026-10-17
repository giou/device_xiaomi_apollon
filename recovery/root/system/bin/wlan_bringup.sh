#!/system/bin/sh
LOG=/tmp/wlan-bringup.log
exec >>"$LOG" 2>&1
echo "=== wlan bring-up $(date) ==="

# 1. /vendor (erofs) + modem firmware (vfat). Retry: the dm device can lag at
#    early boot, and the firmware must be visible before fs_ready.
i=0
while ! mount | grep -q " /vendor "; do
  mkdir -p /vendor
  mount -t erofs -o ro /dev/block/mapper/vendor /vendor && break
  i=$((i+1)); [ "$i" -ge 10 ] && { echo "vendor mount FAILED"; exit 1; }
  sleep 1
done
echo "vendor mounted"
i=0
while ! mount | grep -q " /vendor/firmware_mnt "; do
  mkdir -p /vendor/firmware_mnt
  mount -t vfat -o ro,shortname=lower /dev/block/by-name/modem /vendor/firmware_mnt && break
  i=$((i+1)); [ "$i" -ge 10 ] && { echo "firmware mount FAILED"; exit 1; }
  sleep 1
done
echo "firmware mounted"

# 2. QRTR name server: the firmware's WLFW QMI service registers here.
mkdir -p /tmp/recovery/sockets && chmod 777 /tmp/recovery/sockets
if ! pidof qrtr-ns >/dev/null 2>&1; then
  nohup /vendor/bin/qrtr-ns >/dev/null 2>&1 &
  echo "qrtr-ns started"
fi

# 3. Release the cnss boot (regulators, PCIe, MHI, firmware load).
echo 1 > /sys/kernel/cnss/fs_ready

# 4. Wait for the WLFW announcement, then run cnss-daemon: it performs the
#    WLFW service request that produces the "FW ready" indication.
i=0
while [ "$i" -lt 30 ]; do
  dmesg 2>/dev/null | grep -q "WLFW server arriving" && break
  sleep 1; i=$((i+1))
done
echo "WLFW announced after ${i}s (or timeout)"
export LD_LIBRARY_PATH=/vendor/lib64:/vendor/lib
if ! pidof cnss-daemon >/dev/null 2>&1; then
  nohup /vendor/bin/cnss-daemon >/dev/null 2>&1 &
  echo "cnss-daemon started"
fi

# 5. Wait for FW ready, then kick the host driver: the qcwlanstate char device
#    write calls hdd_driver_load() -> wlan0 appears.
i=0
while [ "$i" -lt 40 ]; do
  dmesg 2>/dev/null | grep -q "Received QMI WLFW FW ready indication" && break
  sleep 1; i=$((i+1))
done
echo "FW ready after ${i}s"
if [ -e /dev/wlan ]; then
  printf 'ON\n' > /dev/wlan
  echo "wrote ON to /dev/wlan"
else
  echo "no /dev/wlan node"
fi

# 6. Wait for wlan0, then start the supplicant service.
i=0
while [ "$i" -lt 90 ]; do
  ifconfig wlan0 >/dev/null 2>&1 && { echo "wlan0 up after ${i}s"; break; }
  sleep 1; i=$((i+1))
done
ifconfig wlan0 2>&1 | head -2
setprop ctl.start wpa_supplicant
sleep 2
echo "supplicant: $(getprop init.svc.wpa_supplicant)"
echo "=== done ==="
