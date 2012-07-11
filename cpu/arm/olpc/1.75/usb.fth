purpose: Platform-specific USB elaborations
\ See license at end of file

dev /usb@d4208000
   \ Port 1 on the hub is connected to unused pins on the WLAN connector,
   \ so testing it is confusing
   \ Port 2 is right upper
   \ Port 3 is left
   \ Port 4 is right lower
   " 3,4,2" " usb-hub-test-list" string-property
device-end

: (reset-usb-hub)  ( -- )
   usb-hub-reset-gpio# gpio-clr  d# 10 ms  usb-hub-reset-gpio# gpio-set
;
' (reset-usb-hub) to reset-usb-hub

devalias u    /usb/disk
