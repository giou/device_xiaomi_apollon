# apollon test backlog (current only — move to done, don't accumulate)

## v18 build `38210824357` (vanilla + kernel refresh + vibrator 24.0)

- [x] LOS 24 PIN decrypt
- [x] Vibration (24.0 HAL + old effect prebuilt held up fine)
- [x] Built-in Magisk 31 addon install (tested on v17; mechanism identical on v18)
- [x] MTP single-entry
- [x] OTG MSR-first disk: `sdg1` unmountable → `sdg2` (NTFS) mounted, backups at `/usb_otg/Fox` (log 20261013-1425)
- [x] OTG single-partition disk: auto-mounted with only the data partition present (2026-10-13, MSR removed)
- [x] OTG unformatted/unmountable drive: clean `no mountable partition on this drive`, no hang (log 20261013-1436)
- [x] LOS zip flash with patching skipped (verified 2026-10-14 on R12.0_5 — see R12.0_5 section; ROM boot confirmation still pending)
- [x] OTA row gone, settings stable
- [x] Navbar lock (no hide option in settings)

## Fixes build `38217828738` (OTG redesign + purges + battery test)

- [x] OTG redesign: plug → auto-tick ≤10s untouched (log 20261013-1425: `apollon OTG: plug event, attempting mount`)
- [x] OTG redesign: manual checkbox iterates to `sdg2` (proven twice on fixes build — re-verify quiet)
- [x] OTG redesign: per-candidate log lines visible on failure (`/dev/block/sdg1 not mountable, trying next`)
- [x] OTG redesign: MTP restored after a *failed* attempt (`[MTP] Starting MTP` immediately after `no mountable partition`); unplug/replug re-triggers too
- [x] `/usb_otg` rename: theme USB-Storage shortcut visible; OTG backups under `/usb_otg/Fox`
  (no `/usb-otg/Fox` migration needed — the old `/usb-otg` mount dir was replaced by `/usb_otg`)
- [x] Vibration again (source-built effect lib)
- [x] Battery % vs actual charge (health-HAL path)
- [x] Sideload without treble-compat check (verified 2026-10-14 on R12.0_5 — code 11, proceeded; see R12.0_5 section)
- [x] Quick backup: empty default → set once in Settings → persists across reboot
- [x] Super backup (dd): 8704 MB `super.emmc.win` + SHA2 digest, 540 s (log 20261013-1501)
- [x] ROM flash (LOS zip) (verified 2026-10-14 on R12.0_5, status=0, OF survived). **ROM boot confirmed working on device 2026-10-14.**
- [x] Decrypt with auto-detect only (`Using keymaster version '4.x'` in log)
- [x] Reflash-button press (repack lossless with effect-lib registration)
- [x] Offline charging — struck: the flag never lived in recovery's path
  (offline charging runs from the ROM's boot image), so there is nothing
  to verify. Drop stands.
- [x] Default English layout + touch sanity (+ one extra-language spot-check). **Verified on device 2026-10-14 (R12.0_7).**
- [x] Green-led setting hidden (Settings LED section absent — confirmed on device)
- [x] MTP dates in Windows: **fixed** (fork `giou/Recovery` `bc6516b2`) — `mtp/ffs/node.cpp` sent `DATE_MODIFIED`/`DATE_ADDED` as `MTP_TYPE_UINT64`; the prop-list path Windows uses needs DateTime *strings*, while the ObjectInfo path (Linux/libmtp) already formatted them. Now emits `formatDateTime()` + `MTP_TYPE_STR`. **Verified on device: dates now show in Windows Explorer.**

## Build `38403589621` (R12.0_3 — LP tools + MTP fix + TEE cleanup)

- [x] MTP date column in Windows (fork `bc6516b2`) — verified
- [x] LP tools usable in the terminal (`lptools` installed — confirmed)
- [x] TEE cleanup: stop confirmed (`init.svc.gatekeeper-1-0` = `stopped` after decrypt); no in-session re-decrypt path exists (a `/data` remount rebuilds the keyring without re-decrypting), so no regression observed. A future Password-based re-decrypt would need the services restarted; none exists today.
- [x] Version banner reads `R12.0_3` (confirmed)
- [x] `/storage` Internal-Storage backup source entry usable, backups to it work (confirmed)

## Build `38435351717` (R12.0_4) — device-tested 2026-10-13 21:46

- [x] Encrypted-backup **lock icon** (verified on R12.0_5 — see R12.0_5 section). (Backup menu → set a backup password). Fix: `TW_EXCLUDE_ENCRYPTED_BACKUPS := false` reinstated (the recovery `Android.mk` test is **inverted**: unset ⇒ `-DTW_EXCLUDE_ENCRYPTED_BACKUPS` + no `libopenaes`). `libopenaes`/`isaac` confirmed present in the published image.
- [x] Encrypted-backup **restore prompt** (verified on R12.0_5 — see R12.0_5 section): the `(i)` icon no longer overlaps the text. Superseded the one-page `993eb7ff` (reverted) — now done theme-wide in R12.0_5 (`c2165eef`, info text at `%col1_x_icon_text%`); verify on device.
- [x] Version banner reads `R12.0_4` (confirmed in the published image)
- [x] `Decrypt.cpp` compiles (host + arm), `libvold` builds, CE symbols linked into the recovery (confirmed in build log + image)
- [x] Carried over: LOS flash + sideload verified on R12.0_5 (see below); layout/touch is the v18 item above (single copy, no duplicates)

### `/data` remount → ❌ still broken on R12.0_4 (diagnosed, re-fixed, not yet built)

The CE re-apply **ran** on remount but was a **no-op**: `Attempting to unlock user
storage` → `failed to fscrypt_prepare_user_storage`, and names stayed ciphertext.
`fscrypt_unlock_ce_storage()` early-returns while its in-process map still lists
the user (nothing clears it on unmount), so the key was never re-added. Deeper:
the whole keyring is per-superblock, so the remount also destroys the **device
key** — leaving `/data/misc/vold` (home of every DE/CE key blob) unreadable — and
the **DE keys**. Re-installing CE alone can never work.

Re-fixed (pending build): vold rebuilds the keyring the way boot does (device key
→ on-disk DE keys → cached CE secret; no PIN needed, and the new DE reloader can
never rewrite key material), and the recovery hook only arms on a real mount
transition.

## Retired

- Updater-OTA ON-test — vanilla removes its UI by design.

## Proven, don't retest

- v17 decrypt (4/4 incl. repeats), MTP working, kernel enumerates `sdg1+sdg2`.

## Build R12.0_8 (pending) — sg-poll gate for qseecomd start (stall prevention, v2)

- [x] Boot time not regressed: the R12.0_8 device session (2026-10-15) booted
  normally, recovery came up in the usual few seconds, and qseecomd acquired
  `/dev/sg1` early — no boot delay. How many tries the poll took is still
  uncaptured — see `docs/DECRYPT-STALL.md` §Validation (read it early, and from
  `dmesg` only).
- [x] Artifact: `wait_sg_rpmb.sh` in ramdisk `system/bin` (with kmsg lines), `on boot` runs exec-then-start in the shipped init rc (verified in image).
- [ ] Stall-rate validation over subsequent decrypts: run the `docs/DECRYPT-STALL.md` §Validation steps each boot (gate verdict, RPMB count, sg fd); the bar is ~30 clean runs. A recurrence with `ls /dev/sg*` + qseecomd fd data reopens the case. Count so far: **4** clean boots with a PIN decrypt and zero RPMB lines (2026-10-15: the first R12.0_8 device test, the 05:19 boot — the one whose two encrypted backups crashed, the boot used for the compression-only backup test, and the gate-check boot). Not enough yet: with the old rate of 1 in 5, four clean runs are ~41% likely by chance alone.
- [x] The gate **runs** (proven 2026-10-15 on device): `start vendor.qseecomd` exists only in that block and qseecomd's first `sg` access lands at t=2.07 s; the following `on boot` block starts the vibrator service, up at t=2.04 s. But **its verdict is still unobservable** (measured 2026-10-15 on 38690605691): neither `/dev/kmsg` nor `/tmp/wait_sg_rpmb.log` ever contains its lines, while the identical script run by hand from an adb shell writes the file fine, and `/tmp` is confirmed real and reachable from init's namespace (`ls -l /proc/1/root/tmp` shows TWRP's live files, no gate file). The `exec` line does execute — `vendor.qseecomd` appears in exactly one file in the whole ramdisk (this tree's rc) and is `disabled`, yet it runs — so the exec'd child simply cannot write either sink (both are root-only-ish: `/tmp` 0775 root:shell, `/dev/kmsg` 0600 root) and init sends the child's stderr to `/dev/null`. Fixed for the next build: qseecomd starts through `start_qseecomd.sh` (gate, then `exec` qseecomd in the same pid), so the gate runs as the `vendor.qseecomd` service (`user root`) and both sinks are writable. Use the vibrator avc timestamp as the per-boot proxy: ~2.04 s means N=0; every 0.2 s later means the gate polled that many times, and ~22 s means it hit its bound. See §Validation.
- [ ] Have not yet observed the gate **wait** (N > 0) on any boot, so the prevention itself is still unobserved: every boot so far had the nodes ready. Watch the proxy above; a boot where it slips is the direct proof.
- [x] Release title carries `(R12.0_8)` (confirmed: `OrangeFox Recovery for apollon // 20261015 (R12.0_8)`). Assets renamed in place to `OrangeFox-R12.0_8-Unofficial-apollon.*` (hash-verified copies, old names deleted); future runs rename at build time via the workflow step.
- [x] CI shakedown run `38652501708` (tree `13183d5`, version kept at `R12.0_8`): green, all 16 steps. Rename proved (`OrangeFox-R12.0-Unofficial-apollon.*` → `OrangeFox-R12.0_8-Unofficial-apollon.*`, old names gone), Magisk zip `sha256 …d4e8` OK, pinned actions resolved, corrected notes matched the published release except the built-commit line. Release and run-ID tag deleted 2026-10-15 — the device-tested artifact (tag `38604355666`) stays and is `latest`.

## Build R12.0_7 (retry; first attempt cancelled at kernel step) — qseecomd late-start + pristine kernel + remount v3

- [x] qseecomd start timing (CLOSED as designed, INEFFECTIVE as fix): dmesg
  proves the sg scan at t=2.054 s vs 2.018 s on `on init` — `on boot` fires
  ~2 s in this recovery, so the trigger move bought 36 ms. Superseded by the
  sg poll in R12.0_8. (Logcat can't show starts at all — pre-logd.)
- [x] Pristine kernel regression check: banner `R12.0_7` (image), boots,
  decrypts repeatedly on device 2026-10-14 (PIN + both remount sessions);
  no `returned INTERRUPTED` string in the image (patch gone by design).
- [x] Stall-rate validation (SUPERSEDED — moved to the R12.0_8 section in this
  file): the `on boot` trigger move bought only 36 ms, so the gate replaced it
  before the count restarted. A recurrence with `ls /dev/sg*` + qseecomd fd
  data reopens the case.
- [x] Release title carries `(R12.0_7)` (confirmed: `OrangeFox Recovery for apollon // 20261014 (R12.0_7)`).
- [x] Remount with vold v3 (`2728d08`): untick→tick shows `rebuilding…` →
  `device key re-installed` → `DE/CE keys re-installed` → `keyring rebuilt`,
  `/data/media/0` readable without reboot. **Verified on device 2026-10-14
  (R12.0_7) — twice in one session, zero FAILED lines.**

## Build R12.0_6 (pending) — remount fix (cached key material) + extra languages

_Note: cloned before the qseecomd late-start (`4965794`) and the kernel branch reset — those ride R12.0_7. A stall on R12.0_6 is still the old race; capture `ls /dev/sg*` if so._

- [x] `/data` untick→tick (VERIFIED on R12.0_7-retry with vold v3 — R12.0_6
  itself carries the flawed v2 and can never pass this; see R12.0_7 section).
  - R12.0_6 result: hook fired, all three steps FAILED — logcat `exportKey`
    service error `-1000` → v2 cached the *raw* key but every reinstall
    re-exports via dead keystore. Fixed in vold `2728d08` (cache installed
    bytes, `installKey` directly); retest moved to the R12.0_7 retry below
    (carries vold `2728d08`).
- [x] Settings > Regional > Language lists the four extras (Spanish, Hungarian,
  Simplified and Traditional Chinese) and CJK text renders.  **Verified on
  device 2026-10-14 (R12.0_6).**
- [x] Release title carries `(R12.0_6)` (confirmed: `OrangeFox Recovery for apollon // 20261014 (R12.0_6)`).

## Build R12.0_5 (`38482616737`, published 2026-10-14 01:48) — theme layout + corrected CE re-apply + kernel from source

- [x] `/data` unmount→remount (SUPERSEDED — retest on R12.0_6, item above): names readable without a reboot; log shows
  `Reapply: rebuilding the fscrypt keyring after /data remount` → `device key
  re-installed` → `DE/CE keys re-installed` → `keyring rebuilt`.
  - R12.0_5 fired the hook but could not rebuild: the device/DE/CE keys are all
    Keymaster-wrapped and the post-decrypt TEE cleanup stops keystore
    (`keystore2 ... DEAD_OBJECT` → `decryptWithKeystoreKey failed`). vold
    `aaa3135` now re-installs material cached during decryption instead (no
    keystore, no generation, no writes) - needs the next build.

- [x] **No spurious re-apply while `/data` stays mounted** (`Is_Mounted()` gate).
  Proven from logs already in hand: R12.0_4's `install.log` shows the *ungated*
  hook firing on the recovery's own `Mount_By_Path("/data")` right after decrypt
  (`Attempting to unlock user storage` again at line ~1170, with no unmount
  anywhere in that window), while R12.0_5's `post-install.log` runs the same flow
  and is silent - the only difference between the two builds there is the gate.
  No extra run needed; only a genuine untick→tick transition may fire it.
- [x] Theme form fields: Verify Password, restore password prompt, Rename
  backup, file rename/chmod, Time offset — caption/input/underline all at x=48,
  underline ending at 1032 (no clipping). (`c2165eef`, `7134e101`.)
  **Verified on device 2026-10-14 (R12.0_5).**
- [x] Info-icon gap: PIN decrypt screen ("Data Partition is encrypted") and the
  restore prompt — text snug after the icon (136) instead of 216.
  **Verified on device 2026-10-14 (R12.0_5).**
- [x] Failure-text spacing uniform: wrong password on Set Password / the PIN
  decrypt screen → the red text sits ~27px below the red underline, matching
  Rename backup. (`5faba288`.)  **Verified on device 2026-10-14 (R12.0_5).**
- [x] Version banner reads `R12.0_5` (confirmed in the published image).
- [x] Verified in the published artifact (R12.0_5's image): banner `R12.0_5`;
  `col1_x_icon_text` = 136 and nine `below:idfail_*` anchors in the theme; CE
  re-apply strings (`rebuilding fscrypt keyring`, `CE keys restored`,
  `fscrypt_reload_de_keys`) and `libopenaes` in the ramdisk.  The strings change
  in the next build: the re-apply now prints `rebuilding the fscrypt keyring
  after /data remount` → `device key (re-)installed` → `DE/CE keys …` →
  `keyring rebuilt`.
- [x] Encrypted-backup lock icon present, and the restore prompt's `(i)` sits
  like it does elsewhere.  **Verified on device 2026-10-14 (R12.0_5).**
- [x] **Extra languages missing from the menu** (SUPERSEDED — retest on R12.0_6, item above; found on device 2026-10-14).
  The build ships only the 28 `gui/theme/common/languages/*.xml`; the four
  `gui/theme/extra-languages/languages/*.xml` - Spanish, Hungarian, Simplified and
  Traditional Chinese - plus the font overrides they need are copied into `/twres`
  only when the tree sets `TW_EXTRA_LANGUAGES := true`
  (`gui/libfoxui_defaults.go`: `if getMakeVars(ctx, "TW_EXTRA_LANGUAGES") == "true"`,
  shipping `extra-languages/{fonts,languages}`).  Confirmed absent from R12.0_5's
  ramdisk (`twres/languages` = exactly the 28 common files).  Flag now set in
  `BoardConfig.mk`; verify on the next build that Settings > Regional > Language
  lists them and the CJK text renders.
- [x] LOS zip flash + sideload, treble path.  Sideloaded
  `lineage-24.0-20261011-nightly-apollon-signed.zip` on R12.0_5 (2026-10-14):
  assert passed (`AssertDevice=[apollon,apollo,apollopro]`), OF logged
  `detected Treble ROM installer. [code=11]` and **proceeded** (no refusal - so
  `OF_NO_TREBLE_COMPATIBILITY_CHECK` is not needed), LP resized
  system/vendor/product/odm/system_ext, system was patched block-by-block, and
  the addon repacked/flashed the boot image for Magisk.  `operation_end -
  status=0`.  No recovery image was written, so OF survived the ROM flash.
  ROM boot confirmation still pending.
- [x] Moved the three build-time workarounds into the recovery fork
  (`giou/Recovery@fox_16.0-apollon` `41e0acf5`): openaes K&R → ANSI prototypes,
  repacker targets `/recovery` on slotless devices, manual reflash item
  un-gated. The override step clones the fork as-is; the log records the fork commit used
  (`Override HEAD now:` + `git log --oneline -3`). Same resulting bytes as R12.0_5,
  so no device re-test is needed beyond the checklist above.

## Decrypt stall — ROOT CAUSE CONFIRMED (userspace RPMB race, 2026-10-14; kernel exonerated, patch removed)

Full dossier: [`docs/DECRYPT-STALL.md`](docs/DECRYPT-STALL.md).

- [x] Captured (4th occurrence, R12.0_4) with SysRq `l`/`t` + process probes.
  Exact frame: `__scm_call_armv8_64` (`drivers/soc/qcom/scm.c`, lines 108-134) —
  `do { smc #0 } while (r0 == SCM_INTERRUPTED);` — **unbounded, no delay, no
  logging**. Reached via `__scm_call2` ← `__qseecom_scm_call2_locked` ←
  `qseecom_scm_call` ← `__qseecom_process_reentrancy` ← `__qseecom_send_cmd` ←
  `qseecom_ioctl(QSEECOM_IOCTL_SEND_CMD_REQ)`. Gatekeeper HAL (pid 633): state R,
  ~85 % of a core, `stime` 0 (no-sleep loop); a second caller spins on the driver
  mutex (CPU2 → `mutex_spin_on_owner`) → livelock. Explains silent / 100 % CPU /
  unkillable / reboot-only.
- [x] Correction: the bounded `-EBUSY` loops (67x30 ms, both of which log) were
  ruled out on sound grounds — but the spin is the INTERRUPTED retry one level
  below them. "dmesg clean" was evidence *for* the kernel, not against.
- [x] Official-parity TEE cleanup (`init.recovery.qcom.rc`) — parity only, not a
  fix for this (the wedge is earlier, inside `verify()`).
- [x] **Kernel fork + fix (was done, REMOVED 2026-10-14):** `giou/android_kernel_xiaomi_sm8250@lineage-24.0-apollon`
  (`f56cbb55`, from pristine `lineage-24.0` @ `6b34d247`) bounds the
  SCM_INTERRUPTED retry (2 s / 1,000,000 retries, no sleeping) → new
  `SCM_V2_TIMED_OUT` → `-ETIMEDOUT`, logged once. Wedge becomes a loud error
  after ~2 s instead of an unkillable hang.
- [x] **Kernel built from source** — done. Builder run `38482616737` cloned
  `giou/android_kernel_xiaomi_sm8250@lineage-24.0-apollon`, built `Image` with
  LOS's full apollon config set (`kona-perf_defconfig` + `debugfs.config` +
  `sm8250-common.config` + `apollo.config`) using the tree's clang r547379 with
  `LLVM=1`, and installed it over `prebuilt/apollon/kernel`. First attempt
  exposed two silent-loss bugs (missing device fragment → no Xiaomi board/touch;
  config phase without `LLVM=1` → `CONFIG_LTO_NONE`), both fixed and now
  asserted. Shipped kernel verifies as ours:
  `Linux version 4.19.325-cip136-st20-perf-gf56cbb55005d`, `CONFIG_LTO_CLANG=y`
  + `THINLTO=y` + `CFI_CLANG=y`, `returned INTERRUPTED` present. dtb/dtbo stay
  the LOS blobs (same kernel commit). (Patch `f56cbb55` removed from the branch 2026-10-14 — fork identical to pristine; new builds lack the `returned INTERRUPTED` string but keep the source-build pipeline.)
- [x] **Source-built kernel boots and decrypts on device (R12.0_5 — verified 2026-10-14** across sessions, incl. metadata decrypt in the stall session):
  banner/boot works, `/data` decrypts, behaviour unchanged (the patch era is over — reverted).
- [x] SMC-spin backstop — dropped with the revert (user order): an
  occurrence-4-style wedge would hang silently again. Accepted: the recurring
  bug is the RPMB mode, covered by the init fix below.
- [x] Recovery-side bounded fail-loud — REJECTED, not pursued: user rejected mitigation-without-prevention (prevention via late-start instead).
- [x] Proper (preventive) fix for the RPMB-spin mode, confirmed live 13:04:
  qseecomd's librpmb acquires `/dev/sg*` once at startup and never recovers;
  `start vendor.qseecomd` moved from `on init` to `on boot` in
  `init.recovery.qcom.rc` so acquisition runs after ueventd coldboot drains.
  Rides the next build after R12.0_6; validate over subsequent decrypts
  (recurrence + `ls /dev/sg*`/fd data would falsify).
- [x] Low priority, noted from the same logs: a screenshot taken **before**
  `/data` is decrypted is reported as saved to `/sdcard/Fox/screenshots/…` but is
  actually written into the ramdisk (`dev="rootfs"` in the avc record) — it will
  not survive a reboot. **Verified as-documented 2026-10-14 (R12.0_7): pulled
  pre-reboot via `adb pull`, PNG opens fine.** Cosmetic; unrelated to the stall.

## Open bug: encrypted backups abort with heap corruption (R12.0_8) — BLOCKING

**RESULT 2026-10-15 (verified on device, build 38690605691):** the trigger is the
multi-threaded encryption stage. With `core_count = 1`, encryption ON and
compression OFF, `/data` completed: `[BACKUP COMPLETED IN 894 SECONDS]`, the log
shows `Core Count      : 1`, and there are **0** `Scudo ERROR` / `Fatal signal` /
`signal: 6` / `createTarFork` lines. The sampler shows exactly **one openaes at a
time** (51 of 63 samples, 0 before the phase started) where the failing runs had
8, with RSS 120 -> 152 MB, fds 56 -> 57 and threads 7 -> 8 (no leak). Output: 7
archives (`data.f2fs.win000..win005`, `win100`) each with a `.sha2`, plus
`data.info`; 0 `invalid RPMB` lines. Only two `E:` lines, both MTP/USB noise.

So it is the concurrency in phase 2 (one `openaes` fork per thread writing
through its own pipe), not openaes alone, not the pipe/no-buffer write path
(compression-only with encryption OFF passes), and not the threaded plain path.
`Creating unencrypted backup...` in the log is the expected first stage - phase 1
writes plain archives and phase 2 encrypts them in place - so that line is not a
sign that encryption was off.

The single-thread setting is a **working workaround, not a root cause**, and
restore of that backup is **not yet verified**.

**ROUND TRIP VERIFIED 2026-10-16 (build 38839683143, 8 threads):** encrypted
`/data` backup completed in 1611 s, then **restore completed in 736 s** with the
archives extracting cleanly (`Extracting uncompressed tar`, no errors). 0 policy
lookup failures across 24,980 `found fscrypt policy` lines; only 2 `E:` lines,
both MTP/USB noise; 0 `invalid RPMB`. Backup + restore of FBEv1 `/data` with
encryption now works end to end at full thread count. (This session's `dmesg`
capture starts at t=1120s - the t=2s gate lines were evicted on the 40+ minute
session, as documented; the gate itself was proven on the previous boot.)

**STALL GATE VERIFIED 2026-10-16 (same build, same boot):** the gate-as-service
fix works. `dmesg` finally shows the verdict directly at t=1.998s
(`waiting for sg0 sg1 sg2` / `ready after 0 tries`), and
`/tmp/wait_sg_rpmb.log` holds the same two lines (collector pulled it). The
wrapper (`start_qseecomd.sh`, pid-preserving `exec`) is confirmed in the shipped
ramdisk, and the TEE cleanup stopped qseecomd cleanly after decrypt (22.15s).
0 `invalid RPMB` lines; decrypt-to-cleanup took ~80ms, no hesitation signature.

Stall count: **9** clean boots (9th, 2026-10-16 evening: gate `ready after 0 tries` at t=1.98s, first-try decrypt, 0 RPMB lines) with a PIN decrypt and zero RPMB lines (incl. the
round-trip session), gate N=0 on every boot where the verdict was readable. Still below the ~30 bar, and the
gate has never been observed waiting (N>0), so the prevention itself remains
unobserved - but from this build on, any boot where it engages will say so in
`dmesg`, no proxy needed.

**FIX VERIFIED 2026-10-16 (on device, build 38839683143, 8 threads):** encrypted
`/data`, compression OFF, `Core Count : 8` completed in 316 s with **0** Scudo /
signal / `createTarFork` / `fscrypt policy size mismatch` lines. Phase 2 ran all
8 openaes forks (sampler saw openaes=8) and produced 14 archives
(`win000..win005`, `win100..win800`) with sha2 digests; only 2 `E:` lines, both
MTP/USB noise; 0 `invalid RPMB` lines. The threaded encryption path that aborted
twice before now passes - the v1/v2 struct mismatch was the corruption.


### Forensic route: malloc debug, no build needed

The crash is in the threaded encryption stage, so the diagnostic build (which
cannot crash) is not the tool. Malloc debug probes it without any build:

- The library libc loads lives in the runtime APEX of the installed ROM:
  `/apex/com.android.runtime/lib64/libc_malloc_debug.so` (642 KB on the LOS 24
  build tested 2026-10-15). It is **not** in the recovery ramdisk, so it must be
  pushed there; the ramdisk is a tmpfs, so it disappears at reboot and nothing
  persists.
- libc reads the env var `LIBC_DEBUG_MALLOC_OPTIONS` first, else the property
  `libc.debug.malloc.options`; then `dlopen("libc_malloc_debug.so")`. A missing or
  mismatched library **fails open** with one logcat line
  (`Unable to open shared library …` / `… routine not found …`), leaving scudo in
  place - so the probe cannot break the recovery.
- The property must be set before the target process starts, so the `recovery`
  service has to be restarted for the backup to run under it (the env var cannot
  reach an init-started service).
- The report goes to **logcat** (`malloc_debug` tag), which is where the log
  collector already looks, so this replaces the crash_dump64/tombstoned route
  entirely.

Options used: `verbose backtrace guard free_track verify_pointers abort_on_error`.
`guard` puts 0xaa/0xbb guards around every allocation and checks them at free;
`backtrace` attaches the allocation site; `free_track` records the free
backtrace. Given scudo's message ("memory corruption **or a double free**"), the
free_track/verify_pointers pair is the one most likely to name the caller.

Needs the **threaded** build, i.e. R12.0_8 as published (the currently flashed
diagnostic build cannot crash).

**Verified on device 2026-10-15:** the APEX library (657368 bytes, pulled from
`/apex/com.android.runtime/lib64/libc_malloc_debug.so` on the LOS 24 build) is
ABI-compatible with the recovery ramdisk's libc. Pushed to
`/system/lib64/libc_malloc_debug.so` and run with `LIBC_DEBUG_MALLOC_OPTIONS=verbose`,
logcat shows `I malloc_debug: ls: malloc debug enabled` - so this route works and
the blob is viable, not just theoretically.

Quoting note for these probes: `adb shell` strips **inner** quotes, so a value
with spaces must be escaped for the device shell:
`.db.exe shell 'setprop libc.debug.malloc.options verbose\ backtrace\ guard'`
and greps must avoid quoted patterns (`grep -i malloc`, not `grep -i "malloc debug"`).
 Heisenbug risk: a debug allocator changes timing,
so a non-reproduction means lightening the options, not that the bug is gone.



- [ ] Any **tar + encryption** backup dies in the backup child:
  `scudo: Scudo ERROR: corrupted chunk header … memory corruption or a double free` →
  `Fatal signal 6 (SIGABRT)` (in the forked backup child) →
  `createTarFork() process ended with signal: 6` → `Backup Failed. Cleaning Backup Folder.`
  No write error, no USB event, and the target is irrelevant.
- [x] Reproduced twice, both `/data` only, both ~5 min in: to the OTG drive (2026-10-15
  05:19, compression OFF) and to Internal Storage (06:21, compression ON — confirmed).
- [x] Narrowed: **dd + encryption is fine** — `/boot` and `/super` are dd images
  (`boot.emmc.win`), not tar, so their clean runs never tested this path. Plain
  (unencrypted) `/data` tar works (13 archives, 1405 s), compression-only works. Only the
  encrypted *tar* path fails.
- [x] Shape of the failing path: phase 1 writes the plain archives single-threaded
  (`Thread id 0 tarList done, 5 archives`), then phase 2 starts `core_count` = 8 threads,
  one archive each (`win100…win800`), each forking its own `openaes` and writing a tar
  stream through a pipe (`write_tar_no_buffer`, `tarWrite.c`). Crash is always inside
  phase 2. `/super` is one file, `/data` is ~200k.
- [x] (SUPERSEDED 2026-10-16 — the v1/v2 struct fix is verified end to end; see
  "FIX VERIFIED" above.) In flight: `/data` **compression ON, encryption OFF**
  ... separates the write path from the threading.
- [x] (SUPERSEDED — same fix.) Next build: `core_count = 1` for encrypted backups.
- [x] (SUPERSEDED — same fix; malloc_debug found the cause, no tombstone tooling needed.)
  If it survives a single thread, the next lever is a backtrace: push `crash_dump64` plus
  its libs from the ROM into the ramdisk and let the abort dump a tombstone.
- [x] (DONE — fixed sampler used one adb call per value, nothing piped or quoted
  device-side; the malloc_debug runs already used it.) Sampler note.

## Open bug: production kernel prints the DEBUG-kernel notice

```
** trace_printk() being used. Allocating extra memory.  **
** This means that this is a DEBUG kernel and it is     **
** unsafe for production use.                           **
```

- Cause: `CONFIG_FTRACE`/`CONFIG_TRACING` are on. `CONFIG_DEBUG_KERNEL` is default-y in the
  kernel's own Kconfig and FTRACE depends on it; our merged fragments add **no** tracing
  symbol, so a stock LineageOS build of this kernel prints the same notice. It appears the
  first time an upstream `trace_printk()` call site runs — there are 13 in the tree — and the
  trace core then allocates the extra buffers the notice warns about.
- [x] Production fix **DONE 2026-10-16**: `arch/arm64/configs/vendor/xiaomi/apollon-recovery.config`
  (`# CONFIG_FTRACE is not set`) in the kernel fork (`fb8307fbc`), merged by the
  workflow and asserted (`grep -q "^# CONFIG_FTRACE is not set"` fails the build
  if FTRACE returns — dt `4a013f3`/wlan dt `45912c1`). Rides the next build.
- Recovery needs no tracing: the stall work used `dmesg` and SysRq only.

## Fixed in the fork, pending your next build (device test)

- [ ] **Decrypt flake**: the gatekeeper HAL occasionally answers a verify with a
  transient error (`GateKeeper response error` right after `using secdis to
  decrypt spblob` → `Failed to decrypt user 0`) and an immediate manual retry
  succeeds - four sessions 10-15/10-16, predating any restore damage.
  `Decrypt_Device` now retries the FBE decrypt exactly once after 300 ms (a
  genuinely wrong password fails both times: at most one extra attempt spent).
  `Recovery-fork d24f01fb` (mainline) / `eec02792` (wlan)
- [ ] **CLI backup name ignored**: `Run_Backup` resolved `tw_backup_name` after
  `Update_System_Details()`, whose prop-read fallback silently overwrites it with
  the current date - so `fox backup --name foo` always landed in a date-named
  folder (proven on device 2026-10-16: `Backup Name is: '2026-10-16--15-03-22_…'`
  for a request that carried `name=fixtest`). Resolution moved before that call.
  `d24f01fb`/`eec02792`

- [ ] **Passwords**: the backup, verify and restore fields silently dropped every character
  outside `[A-Za-z0-9_]` (your `++++++++1234` / `1234` match proved it) and converted a space
  to `_`. They now accept all printable ASCII. `Recovery-fork b5b6af9e`
- [ ] **Names**: the Nandroid name, auto-name, rename-backup and the file-manager
  mkdir/rename/copy fields dropped ~30 symbols silently, and `<restrict disable="1"/>` on the
  name fields meant "reject the character `1`" — a `1` could not be typed in a backup name.
  They now accept all printable except `'` and `/`. `Recovery-fork 29f5221c`
- [ ] **Shell safety**: password and filenames in the size probes are now escaped for
  `/bin/sh`; the theme's delete-backup and rename-backup commands were double-quoted and are
  now single-quoted (a `$` or backtick in a backup name was expanded there, and a backtick
  ran as root). `29f5221c`
- [ ] **`openaes` CLI**: a password of exactly `--in`/`--out` aborted the helper, and `--ecb`
  silently switched the cipher to ECB. Both fixed. `b5b6af9e`
- [ ] Known remaining limit: `'` cannot be typed in a *name* field. The theme language has no
  escape function and ~20 built-in actions single-quote the value. To lift it, either add an
  escaping action (~20-30 lines in `gui/action.cpp`) or move those file operations into C++.

## Theme / character-restriction notes (resolved 2026-10-15)

`TW_THEME := portrait_hdpi` (BoardConfig.mk:236), and the ramdisk's
`/twres/pages/backup.xml` is **byte-identical to the pre-fix**
`gui/theme/portrait_hdpi/pages/backup.xml` - so the theme the escaping fix edits is
the default one that ships, not an unused older one. Do not revert it on the
assumption that it is unused.

What the shipped XML actually restricts:

| Node (shipped backup.xml) | Restriction | Typing behaviour |
|---|---|---|
| line 127-128, `tw_backup_name` on the New Backup page (rendered as text) | `<restrict disable="1"/>` | blacklist of the char `1`; the value is normally set by code |
| line 297-298, `tw_backup_name` on the Backup Name screen - **the editable one** | `allow="a-zA-Z0-9-_.{}[]"` | digits yes, `+` and ~25 symbols silently dropped |
| line 388-389, third name node | `<restrict minlen="0" maxlen="64" disable="1"/>` | as above |
| lines 457-458 / 523-524, `tw_backup_password{,2}` | `allow="a-zA-Z0-9_"`, space becomes `_` | symbols dropped |

On-device confirmation: on R12.0_8 the editable name field refuses `+` - which is
exactly the whitelist at line 297 and exactly the bug the fix widens. So the A/B is:
`+` in that field (rejected on the shipped build, accepted once the fixed build is
flashed), and `!@#$%^&*` plus a space in the password field.

Still unproven and not to be repeated as fact: that `<restrict disable="1"/>` stops
you typing a `1`. That node renders the name as text on the New Backup page; the
field a user actually edits is the whitelisted one at line 297. `gui/input.cpp`
(`GUIInput::NotifyCharInput`) treats `allow` as a whitelist and `disable` as a
blacklist and only ever rejects, so the claim is not contradicted by the source -
but it has never been observed on a field that is typed into, and should not be
quoted again until it is.

## Backup-name character set (resolved 2026-10-16)

Backup names must survive Linux, Windows, FAT32/exFAT, MTP, tar and the shell,
so both layers enforce the same portable set: printable ASCII except
`' / " * + , : ; < = > ? [ \ ] |`, no trailing space or dot, and none of the
reserved Windows device names (CON, PRN, AUX, NUL, COM1-9, LPT1-9, with or
without an extension). Passwords keep all 95 printable characters - they never
become filenames and pass through Shell_Quote() + openaes.

## Restore bug: top-level directories are never stored (fix later, 2026-10-16)

Every `/data` restore on this tree recreates all top-level directories without
fscrypt policy, SELinux context or explicit owner, and the first system boot
after restore dies on each of them in turn with
`--reason=set_policy_failed:<path>` (seen: vendor, anr, tombstones, property,
local, app, dalvik-cache, resource-cache, drm, ...).

Root cause, proven from the lb8 backup log: `Generate_TarList` pushes children
but never the root it is called on, and nothing else adds the tops - zero bare
top-dir lines (`addFile` or `found fscrypt policy`) for all 12 top dirs versus
651 policy lines for `/data/vendor` children alone. The restore side already
handles tagged dir entries (`FSCRYPT_TAG` in block.c); it is just never fed
them. Upstream shares the code, so this is not our regression - but our
backups hit it on every restore.

Repair in progress on device: move aside each failing dir (`.ofbak`, never
delete), let init recreate it with policy+label, then copy contents back and
`restorecon` (copy creates files under the correct policy; restorecon fixes
labels - never blanket `restorecon -R /data`, which would mislabel per-app
data). Durable fix: the backup walk must store top-level dir entries.

## Phone repair after the restore (2026-10-16, all on device via remote adb)

The restore itself was correct (policies stored clean), but two restore-side gaps
broke the first boots, plus one self-inflicted label bug:

1. Top-level dirs recreated without policies -> `set_policy_failed` per dir
   (vendor, anr, tombstones, property, local, app, dalvik-cache,
   resource-cache, drm, nfc, backup, ...). Repaired by move-aside, init
   recreate, copy-back. Durable fix still owed: store top-level dir entries.
2. `restorecon -R` over repaired dirs flattened live-specific labels to
   file_contexts generics. Two casualties: Magisk module dirs
   (`adb_data_file` instead of `system_file` -> zygote abort loop, fixed by
   matching `.ofbak` labels incl. `dex2oat_exec` binaries) and the vendor wifi
   subtree (993 paths, 37 types incl. `vendor_wifi_vendor_wpa_socket`).
   Lesson: never blanket-restorecon a tree; Magisk manages its own labels.
   `/data/adb` is excluded from any future restorecon.
3. Stale runtime sockets (`cnss_user_server`, `wpa_ctrl_*`, `unsolzygote*`)
   with wrong labels blocked daemon startup (`Wifi HAL start failed` via a
   driver-state EINVAL chain). Removed in recovery; daemons recreated them.
4. `/data/user_de` restored with the fallback label blocked zygote `mounton`
   (no app could start). Relabeled to `system_userdir_file` from recovery root
   (system shell cannot relabel - `Operation not permitted`).

Verified after repair: clean boot, 0 fatals, 0 HAL failures, wifi enabled,
PM UIDs match data-dir owners (twitter 10229, termux 10207).

## Launcher + widget restore, encrypted-backup test prep (2026-10-16, later)

- Home screen: `launcher.db` from the OTG backup (667648 B, win100) placed in
  recovery with owner 10134, mode 660, `privapp_data_file` label -> icon grid
  restored on boot. `.ofbak` dirs (21, ~8.5G) deleted after verification
  (app byte-identical; adb diffs were pure Magisk/LSPosed runtime churn).
- Widgets are two files, not one: the db rows (favorites itemType 4,
  appWidgetIds 5/7/8) AND the AppWidgetService bindings
  (`/data/system/users/0/appwidgets.xml`, binary XML). Booting with only the db
  made the launcher prune the widget rows (667648 -> 643072 B, 0 widget rows)
  and the service rewrite its file (20522 B). Fix: restore BOTH together in
  recovery (xml: owner 1000:1000, 600, `system_data_file`; db: as above).
  Done and verified on device: `dumpsys appwidget` shows launcher3 host 1024
  with `widgets.size=3`; home screen back with all icons, folders and the
  crypto widgets (Monero/BTC panels render; a third dark card may still be
  warming up).
- LOS adb from the new Linux PC: DONE 2026-10-16 - the PC's host key is
  pre-authorized in `/data/misc/adb/adb_keys` (adbd re-persists the file itself
  as `system:shell` + `adb_keys_file`; leave that ownership to adbd). The
  one-time on-screen Allow was needed only before this.
- Tooling: `pyoaes.py` (decrypt openaes backup streams: 4096 B frames,
  header+IV per frame, AES-CBC, ascending 1..k pad, key = raw password bytes;
  byte-exact against the phone's openaes). For TWRP tars pass
  `ignore_zeros=True` (PAX `TWRP.security.fscrypt` headers + zero blocks make
  plain `tarfile` stop early). Windows PC superseded by the Linux PC
  (<tailnet-ip>) after the hardware move; adb + Samba-free reads of the NTFS
  HDD work there.
- Fox engine: `backup`/`restore` now take `password` (`encrypt`), so encrypted
  backups are creatable/restorable headless (`1dc8f297`).
- Test plan for the walk fix (build 38891076450): flash, decrypt, encrypted
  data backup to internal storage, restore it, expect bare-top
  `found fscrypt policy '/data/<top>'` lines and no `set_policy_failed`.
- TEST PASSED (build 38891076450 = walk fix + fox password args):
  - encrypted data backup via fox CLI (password) to internal storage: 22
    archives (win000-005 plain app/dalvik, win100-800 + splits OAES-encrypted),
    21.7 GB, .sha2 digests generated.
  - encrypted restore via fox CLI with the password arg: `RESTORE COMPLETED IN
    399 SECONDS`, result code 0.
  - restore log: bare-top `found fscrypt policy '/data/<top>'` for ALL 33 top
    dirs (adb, adbroot, anr, app, ..., system, tombstones, vendor);
    `set_policy_failed` = 0 (was 12+ pre-fix).
  - post-restore boot: dmesg set_policy_failed = 0, logcat FATAL = 0, home
    screen + all 3 widgets + folders intact. One post-restore quirk: the
    LineageOS setup wizard took the HOME slot (stale preferred activity); fixed
    with `cmd package set-home-activity com.android.launcher3/.uioverrides.QuickstepLauncher`,
    reboot-verified.
  - the test backup is KEPT on device (first backup that is safe to restore):
    /sdcard/Fox/BACKUPS/Mi_10T_Pro/2026-10-16--15-03-22_CP2A260605016/
  - evidence bundle: /tmp/opencode/phone-logs/restore-test/ (restore.ndjson,
    recovery-after-restore.log, dmesg, logcat).
  - lessons: attach the foxout reader BEFORE sending the request (a request that
    starts a long op can outlive the adb shell that sent it); the adb link
    blipped once under heavy IO but the engine-side operation ran to completion.
- Flashing on the Linux PC: fastboot is dead against this bootloader from Linux
  (gadget crashes mid-download, both platform-tools 33 and 37 - full detail in
  scripts/remote-access.md). Proven path: push the release zip and
  `twrp install /sdcard/of.zip` from recovery, then sha256 the partition -
  verified bit-exact on the last release (partition = 128 MiB exactly).
- Decrypt flake (found in /sdcard/Fox/logs archives): occasionally the first
  PIN decrypt dies with `GateKeeper response error` -> `Failed to decrypt user 0`;
  an immediate retry succeeds. Seen 10-15 19:42 and 20:18, 10-16 08:40 and 09:01 -
  it predates the disaster. All scripts must retry `twrp decrypt` up to 3 times.
- 10-15 storage backups to the OTG drive aborted mid-file on big media
  (`E:Error writing tar file!` in three sessions) - those attempts are incomplete;
  likely disk-full or OTG write flake. The 10-16 07:58 backup is the good one.
- On-phone recovery-log archive lives at /sdcard/Fox/logs (per-boot
  recovery_*.log.zip); pulled copy: /tmp/opencode/phone-logs/foxlogs.

## WLAN / wireless-ADB build line (2026-10-16) — SEPARATE build, run 38958101995

- Recovery fork branch `fox_16.0-apollon-wlan` = apollon fork + merge of OrangeFox
  `fox_16.0_wifidev` (auto-merge, zero conflicts; all apollon fixes intact):
  WiFi-in-recovery (wlan GUI + `fox wlan` CLI), `fox_adbd` (network ADB with
  `start`/`pair`/`stop`/`list`/`forget`, secure or no-auth), web dashboard,
  secrets store. Mainline branches stay untouched.
- DT branch `fox_16.0-wlan`: `OF_ENABLE_WLAN := 1` (fox_apollon.mk), clones
  wpa_supplicant_8 (`android16-s2-release`) + ttyd via twrp.dependencies, mounts
  the modem partition at `/vendor/firmware_mnt` in recovery (qca6390 firmware
  lives there), and builds recovery from the wlan branch.
- Device facts for the test: firmware `/vendor/firmware_mnt/image/qca6390/`;
  WCNSS configs in `/vendor/etc/wifi/`; `qcom,cnss-qca6390` present in the
  recovery DTB; WiFi `<home-SSID>` (same LAN as the PC).
- Test plan: flash zip -> recovery -> `fox wlan enable` + connect -> `fox adbd
  start` (+ `pair`) -> `adb pair` / `adb connect` from the PC -> unplug USB, plug
  the HDD on OTG -> wireless control while OTG is occupied, then the OTG-target
  encrypted backup retest (the one HDD-dependent item).
