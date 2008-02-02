\ Version numbers of items included in the OLPC firmware image

\ The overall firmware revision
macro: FW_MAJOR D
macro: FW_MINOR 12a

\ The EC microcode
macro: EC_VERSION d11

\ Alternate command for getting EC microcode, for testing new versions.
\ Temporarily uncomment the line and modify the path as necessary
\ macro: GET_EC cp PQ2D08a.bin ec.img

macro: KEYS mpkeys
\ macro: KEYS testkeys

\ The wireless LAN module firmware
macro: WLAN_RPM ${WLAN_VERSION}-1.olpc1
macro: WLAN_VERSION 5.110.22.p1

\ The bios_verify image
macro: CRYPTO_VERSION 0.3
