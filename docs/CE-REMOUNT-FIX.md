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

## The TEE cleanup is what makes this hard
`TWPartition::UnMount` does **not** clear `Is_Decrypted`, and `Mount` reuses
`Decrypted_Block_Device`, so the remount itself never re-decrypts - no decrypt
attempt appears in the log after the remount.

But rebuilding the keyring means *unwrapping* keys, and on this device every one
of them is Keymaster-wrapped (R12.0_5 logcat, first decrypt):

```
06:51:49.505 fscrypt_initialize_systemwide_keys -> Key exists, using: /data/unencrypted/key
06:51:49.505   Retrieving key from keymaster
06:51:49.537 fscrypt::load_all_de_keys::retrieveKey -> Retrieving key from keymaster
06:52:24.558 Trying user CE key /data/misc/vold/user_keys/ce/0/current -> Retrieving key from keymaster
```

The post-decrypt TEE cleanup stops gatekeeper/keymaster, so keystore2 is dead for
the rest of the session and a second unwrap cannot happen (same session, at the
remount):

```
06:53:08.056 Retrieving key from keymaster
06:53:08.058 keystore2: beginInternal transaction failed ... 'DEAD_OBJECT'
06:53:08.058 decryptWithKeystoreKey failed
```

So: capture the *unwrapped* material while keystore is still alive (during
decryption, where each key is already in hand) and re-install that on remount.
Nothing is unwrapped twice, and the TEE services stay stopped - which is what the
stall work wants anyway.

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
   - Cache the **unwrapped** material at the moment each key is installed while
     keystore is alive: the device key in `fscrypt_initialize_systemwide_keys()`,
     each DE key in `load_all_de_keys()`, each CE key in
     `fscrypt_unlock_ce_storage()`.
   - `fscrypt_reinstall_cached_device_key()` /
     `fscrypt_reinstall_cached_user_keys()` install that material with
     `install_storage_key()` and nothing else: **no keystore**, no
     `retrieveOrGenerateKey()` (which would generate *and write* a replacement key
     if it could not read one), no writes at all. An empty cache fails loudly
     rather than guessing.
   - `fscrypt_forget_cached_keys()` wipes the material; `Decrypt_Forget_CE()`
     calls it on Format Data, where `/data` is re-keyed.
   - Export `Decrypt_Reapply_All_CE()` / `Decrypt_Forget_CE()` (`Decrypt.h`);
     `Decrypt_Reapply_All_CE()` prints one breadcrumb per step, so the recovery
     log alone says which part failed.
   - The builder **overrides** `system/vold` with this fork (replace-by-clone) and
     logs the commit it cloned (`Override HEAD now:` + `git log --oneline -3`).
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

## Security
Process-local only (vold code is linked into the recovery). The material is never
written to disk and never logged - only "device key re-installed"-style
breadcrumbs are. The **PIN is never cached**: what is held is already-unwrapped
key material of the kind the kernel keeps in the keyring anyway, in a root/ADB-
trusted context. It is wiped on Format Data, and this path can never take a
generate/write branch because it only calls `install_storage_key()`.

## Verification
1. Decrypt → `ls /data/media/0` readable, and `/proc/keys` has the fscrypt entries.
2. Mount page: untick `/data`, tick `/data` → the recovery log shows
   `Reapply: rebuilding the fscrypt keyring after /data remount` →
   `Reapply: device key re-installed` → `Reapply: DE/CE keys re-installed` →
   `Reapply: keyring rebuilt`, and `ls /data/media/0` is readable **without a
   reboot**.
3. Mount page: tick `/data` again while it is already mounted → **no** re-apply
   (the `Is_Mounted()` gate keeps the log quiet).
4. Format Data → material cleared (decrypt again afterwards).
5. If a step still fails, the breadcrumb names it and `adb logcat` has the
   detail (vold's `LOG()` lines, e.g. `Failed to install fscrypt key to /data:
   <errno>`) - that is how the R12.0_5 failure was pinned down.
