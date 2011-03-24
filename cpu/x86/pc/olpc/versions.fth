\ Version numbers of items included in the OLPC firmware image

\ The overall firmware revision
macro: FW_MAJOR E
macro: FW_MINOR 45s

\ The EC microcode
macro: EC_VERSION e35

\ Alternate command for getting EC microcode, for testing new versions.
\ Temporarily uncomment the line and modify the path as necessary
\ macro: GET_EC cp pq2e18c.img ec.img

macro: KEYS mpkeys
\ macro: KEYS testkeys

\ The wireless LAN module firmware
macro: WLAN_RPM ${WLAN_VERSION}.olpc1
macro: WLAN_VERSION 5.110.22.p23

\ The bios_verify image
macro: CRYPTO_VERSION 0.4

\ The multicast NAND updater code version
\ Use a specific git commit ID for a formal release or "test" for development.
\ With a specific ID, mcastnand.bth will download a tarball without .git stuff.
\ With "test", mcastnand.bth will clone the git head if build/multicast-nand/
\ is not already present, then you can modify the git subtree as needed.
macro: MCNAND_VERSION af0cadd1cbfb17ddfa7dcf299c4c3662ad7120a4
\ macro: MCNAND_VERSION test
\ macro: MCNAND_VERSION HEAD
