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
# Invoked from start_qseecomd.sh, the vendor.qseecomd service wrapper.
i=0
# Verdict goes to /dev/kmsg (readable from dmesg when the script is run by hand)
# and to /tmp/wait_sg_rpmb.log. The file matters because init's `exec` sends the
# command's stdout/stderr to /dev/null, so a failing kmsg redirect is silent -
# measured on 2026-10-15: the gate ran every boot (proven by qseecomd's start
# point) yet never appeared in dmesg. /tmp survives the session, and the log
# collector pulls the file out.
say() {
    echo "wait_sg_rpmb: $1" > /dev/kmsg
    echo "wait_sg_rpmb: $1" >> /tmp/wait_sg_rpmb.log
}
say "waiting for sg0 sg1 sg2"
while [ $i -lt 100 ]; do
    if [ -e /dev/sg0 ] && [ -e /dev/sg1 ] && [ -e /dev/sg2 ]; then
        say "ready after $i tries"
        exit 0
    fi
    sleep 0.2
    i=$((i + 1))
done
say "TIMEOUT, proceeding anyway"
exit 1
