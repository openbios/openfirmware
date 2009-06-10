purpose: High-level glue and codec selection
\ Intel HD Audio top-level
hex

" audio" device-name
" sound" device-type

: vendor-id  ( -- id )  0 to node  h# f0000 cmd?  ;

: setup-defers  ( -- )
   vendor-id case
      h# 14f1.5066  of  cx2058x-init  endof
   endcase
;

' setup-defers to detect-codec

