dev screen
\ XXX Capture video to video memory only.  I don't know why I can't capture to
\ XXX system memory.  I'm using an arbitrary offset into the video memory.

h# 200.0000 constant capture-base

: alloc-capture-buffer  ( len -- vadr padr )
   >r                                          ( r: len )
   capture-base 0  h# 0200.0010 my-space or    ( pci-phys.. r: len )
   r> " map-in" $call-parent                   ( vadr )

   dup >physical                               ( vadr padr )
;

: free-capture-buffer  ( vadr padr len -- )  nip unmap  ;

: dma-alloc  ( len -- adr )  " dma-alloc" $call-parent  ;
: dma-free  ( adr len -- )  " dma-free" $call-parent  ;

new-device
   " camera" device-name
   fload ${BP}/dev/olpc/viacamera/smbus.fth
   fload ${BP}/dev/olpc/viacamera/camera.fth
finish-device

device-end

