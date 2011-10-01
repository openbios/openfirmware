dev screen
\ XXX Capture video to video memory only.  I don't know why I can't capture to
\ XXX system memory.

: alloc-capture-buffer  ( len -- vadr padr )
   drop                                        ( )
   graphmem                                    ( vadr )
   dup >physical                               ( vadr padr )
;

: free-capture-buffer  ( vadr padr len -- )  3drop  ;

: dma-alloc  ( len -- adr )  " dma-alloc" $call-parent  ;
: dma-free  ( adr len -- )  " dma-free" $call-parent  ;

\ encode-unit, decode-unit, #size-cells and #address-cells establish the
\ characteristics of a  subordinate address space so the camera sub-node
\ can have a reg property.
: encode-unit  ( n -- adr len )  push-hex (u.) pop-base  ;
: decode-unit  ( adr len -- n )
   push-hex  $number  if  0  then  pop-base
;
1 " #size-cells" integer-property
1 " #address-cells" integer-property

new-device
   " camera" device-name
   0 0 reg  \ A reg property makes "test-all" consider this device
   [ifndef] seq!  : seq!  3c4 pc! 3c5 pc!  ;  [then]
   [ifndef] seq@  : seq@  3c4 pc! 3c5 pc@  ;  [then]
   fload ${BP}/dev/olpc/viacamera/smbus.fth       \ Bit-banging SMBUS driver
   fload ${BP}/dev/olpc/viacamera/platform.fth
   fload ${BP}/dev/olpc/ov7670.fth
   fload ${BP}/cpu/x86/ycrcbtorgb.fth             \ Color space conversion
   fload ${BP}/dev/olpc/viacamera/camera.fth
   fload ${BP}/dev/olpc/cameratest.fth
finish-device

device-end
