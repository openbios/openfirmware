\ Version numbers of items included in the OLPC firmware image

\ The overall firmware revision
macro: FW_MAJOR F
macro: FW_MINOR 02

\ The EC microcode
macro: EC_VERSION 1_1_2

\ Alternate command for getting EC microcode, for testing new versions.
\ Temporarily uncomment the line and modify the path as necessary
\ macro: GET_EC cp pq2e18c.img ec.img

macro: KEYS mpkeys
\ macro: KEYS testkeys

\ The wireless LAN module firmware
macro: WLAN_RPM ${WLAN_VERSION}.olpc1
macro: WLAN_VERSION 5.110.22.p23

\ The bios_verify image
macro: CRYPTO_VERSION 0.2

\ The multicast NAND updater code version
\ Use a specific git commit ID for a formal release or "test" for development.
\ With a specific ID, mcastnand.bth will download a tarball without .git stuff.
\ With "test", mcastnand.bth will clone the git head if build/multicast-nand/
\ is not already present, then you can modify the git subtree as needed.
macro: MCNAND_VERSION 0c73b4a084a27f0687b152dd0395c67fdf54b10f
\ macro: MCNAND_VERSION test
\ macro: MCNAND_VERSION HEAD
