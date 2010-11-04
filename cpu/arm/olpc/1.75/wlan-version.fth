\ The wireless LAN module firmware
macro: WLAN_VERSION 9.0.7.p2

\ Alternate command for getting WLAN firmware, for testing new versions.
\ Temporarily uncomment the line and modify the path as necessary
\ macro: GET_WLAN cp "/c/Documents and Settings/Mitch Bradley/My Documents/OLPC/DiskImages/sd8686-9.70.7.p0.bin" sd8686.bin; cp "/c/Documents and Settings/Mitch Bradley/My Documents/OLPC/DiskImages/sd8686_helper.bin" sd8686_helper.bin
\ macro: GET_WLAN wget http://dev.laptop.org/pub/firmware/libertas/thinfirm/lbtf_sdio-9.0.7.p2.bin -O sd8686.bin
