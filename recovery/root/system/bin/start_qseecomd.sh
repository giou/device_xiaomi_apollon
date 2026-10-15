#!/system/bin/sh
# Start qseecomd only after the UFS RPMB sg nodes exist, then become qseecomd in
# this same pid (so `stop vendor.qseecomd`, pidof and the TEE cleanup keep
# working on one process).
#
# This runs as the vendor.qseecomd service (declared `user root`) rather than via
# init's `exec` builtin. Measured 2026-10-15 on 38690605691: with `exec`, the
# gate ran but wrote neither /dev/kmsg nor /tmp/wait_sg_rpmb.log - the exec'd
# child cannot write those (0775 root:shell / 0600 root) and init sends its
# stdout/stderr to /dev/null, so the failure was silent. As a service it runs as
# root, the verdict is visible, and the gate cannot be skipped.
#
# Bound: wait_sg_rpmb.sh polls 100 x 0.2 s, then exits either way (fail-open).
/system/bin/wait_sg_rpmb.sh
exec /vendor/bin/qseecomd
