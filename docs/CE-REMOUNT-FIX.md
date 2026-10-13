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

## R12.0_4 result — the first attempt was a no-op

Build `38435351717` (R12.0_4) shipped the fix below; the bug persisted, and the
device log (2026-10-13 21:46) shows exactly why:

- The hook **did** fire on remount (`Attempting to unlock user storage` →
  `Attempting to prepare user storage`), so the call path was live.
- But `fscrypt_unlock_ce_storage()` **early-returns** while its in-process map
  (`s_ce_policies`) still lists the user — and it always does, because nothing
  clears it on unmount. The key was therefore never re-added, and the following
  `fscrypt_prepare_user_storage()` failed (`failed to fscrypt_prepare_user_storage`)
  because the key it needs is gone.

The flawed assumption was that only the CE key was dropped. It is not: the whole
keyring lives in the `/data` superblock, so unmounting `/data` also destroys the
**device key** — and with it the readability of `/data/misc/vold`, where every
DE/CE key blob lives — plus the **DE keys**. Re-installing only CE can never
work: the CE blob cannot even be read while `/data/misc/vold` is unreadable.

## Fix — rebuild the whole keyring, then re-apply CE

A remount must redo what boot does: device key → DE keys → CE keys. None of that
needs the user's PIN — the device key blob sits in the **plaintext**
`/data/unencrypted`, and the DE/CE blobs are wrapped with `kEmptyAuthentication`.

1. **vold** — forked as `giou/android_system_vold` (branch **`fox_16.0-apollon`**,
   based on OrangeFox `fox_16.0` @ `953de96`; the fork's `fox_16.0` branch is kept
   pristine as an upstream mirror); direct source edits:
   - Cache the secret inside `Decrypt_CE_storage(user_id, secret)` — captured
     there, so **no decrypt-logic change** and it works for every path
     (`Decrypt_User_Synth_Pass`, default-password, legacy).
   - Export `Decrypt_Reapply_All_CE()` / `Decrypt_Forget_CE()` (`Decrypt.h`).
     `Decrypt_Reapply_All_CE()` now does:
     `fscrypt_initialize_systemwide_keys()` (device + per-boot key) →
     `fscrypt_reload_de_keys()` (new: `load_all_de_keys()` minus
     `fscrypt_init_user0()`'s create/overwrite paths, so it can never rewrite key
     material) → per cached user, `fscrypt_lock_ce_storage()` (drops the stale
     "unlocked" bookkeeping so the unlock really re-adds the key) →
     `Decrypt_CE_storage()`.
   - The builder **overrides** `system/vold` with this fork (replace-by-clone,
     asserted on `apollon_ce_secrets` / `Decrypt_Reapply_All_CE`).
     `Check-Upstream-Drift.yml` compares `OrangeFox/system/vold@fox_16.0` against
     the fork base (`VOLDS_BASE`) so upstream vold fixes aren't missed.
2. **recovery fork** (`giou/Recovery`):
   - `TWPartitionManager::Mount_By_Path`: only on a genuine mount transition
     (`!Is_Mounted()` before `Mount()`) of `/data` while decrypted →
     `android::keystore::Decrypt_Reapply_All_CE()`. The gate matters: a no-op
     `Mount_By_Path("/data")` on an already-mounted partition returns early
     (`TWPartition::Mount` short-circuits on `Is_Mounted()`) and must not evict
     and re-add a perfectly good key.
   - `TWPartition::Wipe_Encryption`: `Decrypt_Forget_CE()` (secret goes stale
     once `/data` is re-keyed).

## Security (as reviewed)
Process-local only (vold code is linked into the recovery); never logged; the
**PIN is never cached** — only the derived disk secret. Cleared on data wipe.
Comparable to the fscrypt master-key material the kernel already retains, and
recovery is already a root/ADB-trusted context. Keep it single-purpose.

## Verification
1. Decrypt → `ls /data/media/0` readable and `/proc/keys` shows `fscrypt-dm-5`.
2. Mount page: untick `/data`, tick `/data` → the recovery log shows
   `Reapply: rebuilding fscrypt keyring for 1 user(s)` … `Reapply: CE keys
   restored`; `/proc/keys` shows `fscrypt-dm-5` again and `ls /data/media/0` is
   readable **without a reboot**.
3. Mount page: tick `/data` again while it is already mounted → **no** re-apply
   (the `Is_Mounted()` gate keeps the log quiet).
4. Format Data → cache cleared (no stale secret; decrypt again afterwards).
