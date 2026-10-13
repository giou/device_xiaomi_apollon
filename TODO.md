# apollon test backlog (current only — move to done, don't accumulate)

## v18 build `38210824357` (vanilla + kernel refresh + vibrator 24.0)

- [x] LOS 24 PIN decrypt
- [x] Vibration (24.0 HAL + old effect prebuilt held up fine)
- [x] Built-in Magisk 31 addon install (tested on v17; mechanism identical on v18)
- [x] MTP single-entry
- [ ] OTG on old iteration code (MSR-first disk; single-partition regression; unformatted-drive error)
- [ ] LOS zip flash with patching skipped
- [x] OTA row gone, settings stable
- [ ] Boot-time A/B: `fastboot reboot recovery` + `time adb wait-for-device`,
  3 runs each on v17 vs v18 (logs can't time it — no per-line timestamps)
- [x] Navbar lock (no hide option in settings)

## Fixes build `38217828738` (OTG redesign + purges + battery test)

- [ ] OTG redesign: plug → auto-tick ≤10s untouched (BLOCKED: no OTG adapter on hand)
- [ ] OTG redesign: manual checkbox iterates to `sdg2` (BLOCKED: same)
- [ ] OTG redesign: per-candidate log lines visible on failure (BLOCKED: same)
- [ ] OTG redesign: MTP survives a failed attempt; unplug/replug re-triggers (BLOCKED: same)
- [x] Vibration again (source-built effect lib)
- [x] Battery % vs actual charge (health-HAL path)
- [ ] Sideload without treble-compat check (next LOS nightly)
- [x] Quick backup: empty default → set once in Settings → persists across reboot
- [ ] Super backup (dd) + ROM flash without lptools
- [x] Decrypt with auto-detect only (`Using keymaster version '4.x'` in log)
- [x] Reflash-button press (repack lossless with effect-lib registration)
- [x] Offline charging — struck: the flag never lived in recovery's path
  (offline charging runs from the ROM's boot image), so there is nothing
  to verify. Drop stands.
- [ ] English-only UI, default icon layout, touch sanity
- [ ] Green-led setting hidden again

## Retired

- Updater-OTA ON-test — vanilla removes its UI by design.

## Proven, don't retest

- v17 decrypt (4/4 incl. repeats), MTP working, kernel enumerates `sdg1+sdg2`.

## Next (decrypt stall diagnosis — watchdog reverted, diagnose-first)

- Stall is inside vold `Decrypt.cpp` secdis branch: HIDL gatekeeper
  `getService()` → `verify()` (both blocking, no timeout). File reads,
  AIDL fast-fail, and service crashes all exonerated by log/dmesg diff.
- [ ] Next hang (cable plugged): `getprop init.svc.gatekeeper-1-0`,
  `ps -A | grep -E "gatekeeper|keymaster"`,
  `cat /sys/kernel/debug/tzdbg/log | tail -n 30` — service present vs
  TA-side isolates it definitively.
- [ ] Note boot type (cold overnight vs warm reboot) on every decrypt;
  both hangs were morning boots.
