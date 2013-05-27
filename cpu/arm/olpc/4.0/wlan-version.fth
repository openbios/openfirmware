\ The wireless LAN module firmware

\ Thin firmware version
macro: WLAN_SUBDIR thinfirm/
macro: WLAN_PREFIX lbtf_sdio-
macro: WLAN_VERSION 9.0.7.p2

\ dd7193bc is 14.66.09.p96 .  The OFW driver doesn't work with it yet
\ macro: WLAN_8787_VERSION dd7193bc187a5182a6236cb6337699d2229c54b0

\ 7a28e074 is 14.66.09.p80
\ macro: WLAN_8787_VERSION 7a28e074

\ 2013-05-27 hashes in marvell repository have changed
\ macro: WLAN_8787_VERSION bac3567cdb38d5cfcf3045718618026d60478d05
\     commit comment says this is v14.66.9.p96
\     did hang on use
\ macro: WLAN_8787_VERSION 4bd88f614cd9107148cfc758180832f1d0ba53bc
\     passes tests
\     has a different md5sum to what we were using
\ use what we were using
macro: WLAN_8787_VERSION 14.66.09.p80

\ Non-thin version
\ macro: WLAN_SUBDIR
\ macro: WLAN_PREFIX sd8686-
\ macro: WLAN_VERSION 9.70.20.p0

\ Alternate command for getting WLAN firmware, for testing new versions.
\ Temporarily uncomment the line and modify the path as necessary
\ macro: GET_WLAN cp "/c/Documents and Settings/Mitch Bradley/My Documents/OLPC/DiskImages/sd8686-9.70.7.p0.bin" sd8686.bin; cp "/c/Documents and Settings/Mitch Bradley/My Documents/OLPC/DiskImages/sd8686_helper.bin" sd8686_helper.bin
\ macro: GET_WLAN wget http://dev.laptop.org/pub/firmware/libertas/thinfirm/lbtf_sdio-9.0.7.p2.bin -O sd8686.bin
