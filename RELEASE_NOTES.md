## OrangeFox Recovery Build - Unofficial
Banner: `R12.0_%%BUILD_VER%%`. The recovery UI (or the first line of its log) must show this version.
Variants: plain-name assets are the mainline build; `-wlan` assets carry the wireless-adb / WLAN recovery features.
Build: fox_%%MANIFEST_BRANCH%%
Device: [Device Tree/Branch](%%DEVICE_TREE_URL%%/tree/%%DEVICE_TREE_BRANCH%%)
Built from commit [%%COMMIT_ID%%](%%DEVICE_TREE_URL%%/commit/%%COMMIT_ID%%) + fork [%%FORK_HEAD%%](https://github.com/giou/Recovery/commit/%%FORK_HEAD%%).

### What this fork changes (vs stock OrangeFox)
- Decrypt: LOS 24 FBEv1, TEE cleanup after decrypt, readable file names after `/data` remount
- Stall prevention: TEE start waits for storage readiness (bounded poll)
- USB/OTG: automatic mount on plug-in, MTP restored on failure
- MTP: correct dates in Windows
- Backups: encrypted backups enabled
- Build: logical partition tools, Magisk 31, source-built kernel (LOS config), boot blobs from LOS
- Wireless (`-wlan` variants): WLAN in recovery, network ADB with pairing, remote web access (dashboard + terminal)
- Full list: [README](%%DEVICE_TREE_URL%%/blob/%%DEVICE_TREE_BRANCH%%/README.md)

### Known issues
(none)

%%AUTO_CHANGES%%
