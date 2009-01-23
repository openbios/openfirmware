purpose: Bounce USB power to reset devices

\ This is used by the biosload build for OLPC to reset USB
\ devices.  Insyde BIOS / GeodeROM leaves some USB sticks in
\ funny state in which reads fail.  Power cycling fixes them.

: power-cycle-usb  ( -- )
   " /pci/usb@f,4" open-dev >r     \ OHCI controller

   \ Configure the OHCI controller for global power switching
   " hc-rh-desa@" r@ $call-method  ( desA )
   h# 300 invert and               ( desA' )
   " hc-rh-desa!" r@ $call-method  ( desA )

   \ Turn off the power from the OHCI point of view, leaving the
   \ EHCI in control (the power switches are the logical OR
   \ of the OHCI and EHCI controls)
   1 " hc-rh-stat!" r@ $call-method
   r> close-dev
   d# 100 ms

   " /pci/usb@f,5" open-dev   ( ih )     \ EHCI controller
   4 0  do  0 i " portsc!" 4 pick $call-method  loop  ( ih )
   d# 100 ms
   4 0  do  i " power-port" 3 pick $call-method  loop  ( ih )
   close-dev
;
