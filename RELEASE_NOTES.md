<!-- Release-notes TEMPLATE. Placeholders (%%LIKE_THIS%%) are substituted at
     build time by the workflow's "Compose release notes" step; browse a
     published release for the resolved text. -->
## OrangeFox Recovery R12.0_%%BUILD_VER%% (Unofficial)

Flash check: the recovery UI and log line 1 must show `R12.0_%%BUILD_VER%%`.
Assets: plain names = mainline build; `-wlan` = wireless-adb / WLAN recovery.
Sources (fox_%%MANIFEST_BRANCH%%): [device tree @ `%%COMMIT_ID_SHORT%%`](%%DEVICE_TREE_URL%%/tree/%%DEVICE_TREE_BRANCH%%) + [fork @ `%%FORK_HEAD_SHORT%%`](https://github.com/giou/Recovery/commit/%%FORK_HEAD%%).

Full feature list: [README](https://github.com/giou/device_xiaomi_apollon#readme)

### Known issues
(none)

<!-- The line below is replaced at build time with the per-release commit
     list: invisible in this template, visible in published releases. -->
<!--AUTO-CHANGES-->
