\ Version numbers of items included in the OLPC firmware image

\ The overall firmware revision
macro: FW_MAJOR C
macro: FW_MINOR 09

\ The EC microcode
macro: EC_VERSION c09

\ Alternate command for getting EC microcode, for testing new versions.
\ Temporarily uncomment the line and modify the path as necessary
\ macro: GET_EC cp ~/ec-c05t.bin ec.img

\ The wireless LAN module firmware
macro: WLAN_RPM ${WLAN_VERSION}-1.olpc1
macro: WLAN_VERSION 5.220.10.p5
