\ Version numbers of items included in the OLPC firmware image

\ The overall firmware revision
macro: FW_MAJOR E
macro: FW_MINOR 21

\ The EC microcode
macro: EC_VERSION e21

\ Alternate command for getting EC microcode, for testing new versions.
\ Temporarily uncomment the line and modify the path as necessary
\ macro: GET_EC cp pq2e18c.img ec.img

macro: KEYS mpkeys
\ macro: KEYS testkeys

\ The wireless LAN module firmware
macro: WLAN_RPM ${WLAN_VERSION}.olpc1
macro: WLAN_VERSION 5.110.22.p20

\ The bios_verify image
macro: CRYPTO_VERSION 0.2
