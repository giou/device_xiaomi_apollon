# `/data` CE / file-name keys lost on unmount+remount — fix

## Symptom
Unticking then ticking `/data` on the Mount page: the partition mounts, but
`/data/media/0` (and other CE paths) show **ciphertext filenames** until a
reboot.

## Evidence
`mount | grep ' /data '`, `cat /proc/keys | grep -i fscrypt`, `ls /data/media/0`:

- **Good (after decrypt):** `/dev/block/dm-5 on /data`; `/proc/keys` shows
  `keyring fscrypt-dm-5: 4` plus four `._fscrypt` keys; names readable.
- **Bad (after remount):** **same** device `dm-5`, but `/proc/keys` has **no
  fscrypt entries at all**; names ciphertext.

=> fscrypt uses a **per-superblock keyring** (`fscrypt-dm-5`); the kernel
destroys it with the mount, and stock TWRP never re-adds the CE key. The device
choice is fine (not a raw-device fallback) — it is purely the dropped keys.

## Not the TEE cleanup
`TWPartition::UnMount` does **not** clear `Is_Decrypted`; `Mount` reuses
`Decrypted_Block_Device`; the log shows **no** decrypt attempt after the
remount. So the post-decrypt `stop` of qseecomd/gatekeeper/keymaster is not
involved. (It does mean any *Password*-based re-decrypt would need those
services back — hence the secret-based approach below.)

## Fix — secret-based CE re-apply
Two parts:

1. **vold** — forked as `giou/android_system_vold` (branch **`apollon`**,
   based on OrangeFox `fox_16.0` @ `953de96`, commit `f07596e`; the fork's
   `fox_16.0` branch is kept pristine as an upstream mirror); a direct source
   edit:
   - Cache the secret inside `Decrypt_CE_storage(user_id, secret)` — captured
     there, so **no decrypt-logic change** and it works for every path
     (`Decrypt_User_Synth_Pass`, default-password, legacy).
   - Export `Decrypt_Reapply_CE(user_id)`, `Decrypt_Reapply_All_CE()`,
     `Decrypt_Forget_CE()` (declared in `Decrypt.h`).
   - The builder **overrides** `system/vold` with this fork (replace-by-clone,
     asserted on `apollon_ce_secrets` / `Decrypt_Reapply_All_CE`).
     `Check-Upstream-Drift.yml` compares `OrangeFox/system/vold@fox_16.0` against
     the fork base (`VOLDS_BASE`) so upstream vold fixes aren't missed.
2. **recovery fork** (`giou/Recovery`, commit `3217046d`):
   - `TWPartitionManager::Mount_By_Path`: after a successful mount of `/data`
     while still decrypted → `android::keystore::Decrypt_Reapply_All_CE()`.
   - `TWPartition::Wipe_Encryption`: `Decrypt_Forget_CE()` (secret goes stale
     once `/data` is re-keyed).

## Security (as reviewed)
Process-local only (vold code is linked into the recovery); never logged; the
**PIN is never cached** — only the derived disk secret. Cleared on data wipe.
Comparable to the fscrypt master-key material the kernel already retains, and
recovery is already a root/ADB-trusted context. Keep it single-purpose.

## Verification
1. Decrypt → `ls /data/media/0` readable and `/proc/keys` shows `fscrypt-dm-5`.
2. Mount page: untick `/data`, tick `/data` → `/proc/keys` shows `fscrypt-dm-5`
   again and `ls /data/media/0` is readable **without a reboot**.
3. Format Data → cache cleared (no stale secret; decrypt again afterwards).
