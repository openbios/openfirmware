" "  " d420a000" " /"  begin-package
   " camera" device-name
   0 0 reg  \ A reg property makes "test-all" consider this device

0 [if]
   : alloc-capture-buffer  ( len -- vadr padr )
      \ XXX need map-in if we should use virtual mode
      dup " dma-alloc" $call-parent        ( len vadr )
      tuck swap                            ( vadr vadr len )
      false  " dma-map-in" $call-parent    ( vadr padr )
   ;
   : free-capture-buffer  ( vadr padr len -- )
      3dup " dma-map-out" $call-parent  ( vadr padr len )
      nip  " dma-free" $call-parent
   ;
[else]
   : alloc-capture-buffer  ( len -- vadr padr )
      drop load-base dup
   ;
   : free-capture-buffer  ( vadr padr len -- )
      3drop
   ;
[then]

   fload ${BP}/cpu/arm/olpc/1.75/smbus.fth
   fload ${BP}/dev/olpc/mmp2camera/platform.fth
   fload ${BP}/dev/olpc/mmp2camera/ov.fth
   fload ${BP}/dev/olpc/mmp2camera/ccic.fth
end-package


