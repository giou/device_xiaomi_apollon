#!/system/bin/sh
# fox WLAN bring-up for the QCA6390 (apollon).
# Called by init on `sys.fox.wlan.up=1`; safe to run manually for debugging.
# Chain (mirrors a working Android boot):
#   mounts -> qrtr-ns -> fs_ready -> (WLFW announcement) -> cnss-daemon
#   -> wait wlan0 -> supplicant
LOG=/tmp/wlan-bringup.log
exec >>"$LOG" 2>&1
echo "=== wlan bring-up $(date) ==="

# 1. /vendor (erofs) and the modem firmware partition (vfat). Retry: the dm
#    device can lag at early boot, and the FW files must be visible before
#    fs_ready releases the cnss boot.
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

# 4. Wait for the firmware to announce WLFW (same point Android starts the
#    daemon), then run cnss-daemon: it performs the WLFW service request and
#    calibration that produce the "FW ready" indication. Without it the driver
#    stalls at "Timeout waiting for FW ready indication".
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

# 5. Wait for the host driver to create wlan0.
i=0
while [ "$i" -lt 90 ]; do
  ifconfig wlan0 >/dev/null 2>&1 && { echo "wlan0 up after ${i}s"; break; }
  sleep 1; i=$((i+1))
done
ifconfig wlan0 2>&1 | head -2

# 6. Supplicant.
setprop ctl.start wpa_supplicant
sleep 2
echo "supplicant: $(getprop init.svc.wpa_supplicant)"
echo "=== done ==="
