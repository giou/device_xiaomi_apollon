# apollon test backlog (current only — move to done, don't accumulate)

## v18 build `38210824357` (vanilla + kernel refresh + vibrator 24.0)

- [x] LOS 24 PIN decrypt
- [x] Vibration (24.0 HAL + old effect prebuilt held up fine)
- [x] Built-in Magisk 31 addon install (tested on v17; mechanism identical on v18)
- [x] MTP single-entry
- [ ] OTG on old iteration code (MSR-first disk; single-partition regression; unformatted-drive error)
- [ ] LOS zip flash with patching skipped
- [x] OTA row gone, settings stable
- [ ] Boot-time delta vs v17 (MIUI-props skip measurement)
- [x] Navbar lock (no hide option in settings)

## Fixes build `38217828738` (OTG redesign + purges + battery test)

- [ ] OTG redesign: plug → auto-tick ≤10s untouched
- [ ] OTG redesign: manual checkbox iterates to `sdg2`
- [ ] OTG redesign: per-candidate log lines visible on failure
- [ ] OTG redesign: MTP survives a failed attempt; unplug/replug re-triggers
- [ ] Vibration again (source-built effect lib)
- [ ] Battery % vs actual charge (health-HAL path)
- [ ] Sideload without treble-compat check (next LOS nightly)
- [ ] Quick backup: empty default → set once in Settings → persists across reboot
- [ ] Super backup (dd) + ROM flash without lptools
- [ ] Decrypt with auto-detect only (`Using keymaster version '4.x'` in log)
- [ ] Reflash-button press (repack lossless with effect-lib registration)
- [x] Offline charging — struck: the flag never lived in recovery's path
  (offline charging runs from the ROM's boot image), so there is nothing
  to verify. Drop stands.
- [ ] English-only UI, default icon layout, touch sanity
- [ ] Green-led setting hidden again

## Retired

- Updater-OTA ON-test — vanilla removes its UI by design.

## Proven, don't retest

- v17 decrypt (4/4 incl. repeats), MTP working, kernel enumerates `sdg1+sdg2`.
