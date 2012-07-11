purpose: Platform-specific USB elaborations
\ See license at end of file

dev /usb@d4208000
   \ The Marvell EHCI can handle low and full speed devices directly,
   \ without needing a UHCI or OHCI companion controller
   ' make-port-node to handle-ls-device
   ' make-port-node to handle-fs-device
device-end

fload ${BP}/cpu/arm/mmp2/ulpiphy.fth

0 0  " f0003000"  " /" begin-package  \ USB Host Controller 1 - ULPI
   h# 200 constant /regs
   my-address my-space /regs reg
   : my-map-in  ( len -- adr )
      my-space swap  " map-in" $call-parent  h# 100 +  ( adr )
   ;
   : my-map-out  ( adr len -- )  swap h# 100 - swap " map-out" $call-parent  ;
   false constant has-dbgp-regs?
   false constant needs-dummy-qh?
   : grab-controller  ( config-adr -- error? )  drop false  ;
   fload ${BP}/dev/usb2/hcd/ehci/loadpkg.fth
\  false to delay?  \ No need for a polling delay on this platform

   \ The Marvell EHCI can handle low and full speed devices directly,
   \ without needing a UHCI or OHCI companion controller
   ' make-port-node to handle-ls-device
   ' make-port-node to handle-fs-device

   : sleep  ( -- )  true to first-open?  ;
   : wake  ( -- )  ;
end-package

\ usb-power-on is unnecessary on initial boot, as CForth turns on the
\ USB power during its GPIO setup.
: (usb-power-on)  ( -- )
   d# 126 gpio-clr  \ OTG 5V on
   d# 127 gpio-clr  \ ULPI 5V on
;
' (usb-power-on) to usb-power-on

: (reset-usb-hub)  ( -- )
   d# 146 gpio-clr  d# 10 ms  d# 146 gpio-set  \ Resets ULPI hub
   ulpi-clock-on
   ulpi-clock-select
   ulpi-on
;
' (reset-usb-hub) to reset-usb-hub

devalias otg  /usb@d4208000       \ USB OTG (micro) connector
devalias usba /usb@f0003000       \ USB-A connector
devalias o    /usb@d4208000/disk  \ Disk on USB OTG (micro) connector
devalias u    /usb@f0003000/disk  \ Disk on USB-A connector
