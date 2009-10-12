\ Version numbers of items included in the OLPC firmware image

\ The overall firmware revision
macro: FW_MAJOR A
macro: FW_MINOR 13

\ The EC microcode
macro: EC_VERSION 1_9_11

\ Alternate command for getting EC microcode, for testing new versions.
\ Temporarily uncomment the line and modify the path as necessary
\ macro: GET_EC cp ~rsmith/olpc/ec/ec-code15/image/ecimage.bin ec.img
\ macro: GET_EC wget -q http://dev.laptop.org/pub/ec/ec_test.img -O ec.img

macro: KEYS mpkeys
\ macro: KEYS testkeys

\ The wireless LAN module firmware
macro: WLAN_VERSION 9.70.7.p0

\ Alternate command for getting WLAN firmware, for testing new versions.
\ Temporarily uncomment the line and modify the path as necessary
\ macro: GET_WLAN cp "/c/Documents and Settings/Mitch Bradley/My Documents/OLPC/DiskImages/sd8686-9.70.7.p0.bin" sd8686.bin; cp "/c/Documents and Settings/Mitch Bradley/My Documents/OLPC/DiskImages/sd8686_helper.bin" sd8686_helper.bin

\ The bios_verify image
macro: CRYPTO_VERSION 0.4

\ The multicast NAND updater code version
\ Use a specific git commit ID for a formal release or "test" for development.
\ With a specific ID, mcastnand.bth will download a tarball without .git stuff.
\ With "test", mcastnand.bth will clone the git head if build/multicast-nand/
\ is not already present, then you can modify the git subtree as needed.
macro: MCNAND_VERSION b9a9d22b6037c3891f9cf8eabeaf7cd9efbd5241
\ macro: MCNAND_VERSION test
\ macro: MCNAND_VERSION HEAD
