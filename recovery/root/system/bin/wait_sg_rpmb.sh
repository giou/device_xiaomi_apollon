#!/system/bin/sh
# Wait (bounded) for the UFS RPMB sg nodes before qseecomd's one-shot scan.
#
# librpmb acquires /dev/sg* exactly once at qseecomd startup and never
# recovers: a scan that finds nothing latches "invalid RPMB device" for the
# whole session, and the first Weaver verify then livelocks. Recovery boot is
# too compressed for trigger tricks (`on boot` fires ~2 s, 36 ms after the old
# `on init` start), so poll for readiness instead: sg0+sg1+sg2 are the UFS
# well-known LUs (RPMB is one of them) on this SoC/driver, created in the same
# coldboot burst. Bound 100 x 0.2 s = 20 s, then give up and let the start
# proceed anyway (today's behavior - never worse, never hangs boot).
# Invoked from init.recovery.qcom.rc as: exec /system/bin/sh <this script>.
i=0
echo "wait_sg_rpmb: waiting for sg0 sg1 sg2" > /dev/kmsg
while [ $i -lt 100 ]; do
    if [ -e /dev/sg0 ] && [ -e /dev/sg1 ] && [ -e /dev/sg2 ]; then
        echo "wait_sg_rpmb: ready after $i tries" > /dev/kmsg
        exit 0
    fi
    sleep 0.2
    i=$((i + 1))
done
echo "wait_sg_rpmb: TIMEOUT, proceeding anyway" > /dev/kmsg
exit 1
