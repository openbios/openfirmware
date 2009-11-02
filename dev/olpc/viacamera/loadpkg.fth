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

new-device
   " camera" device-name
   fload ${BP}/dev/olpc/viacamera/smbus.fth
   fload ${BP}/dev/olpc/viacamera/camera.fth
finish-device

device-end

