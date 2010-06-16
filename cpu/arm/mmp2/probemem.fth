purpose: Memory probing
copyright: Copyright 1994 FirmWorks  All Rights Reserved

" /memory" find-device

headerless

h# ffff.ffff value low
h#         0 value high

: log&release  ( adr len -- )
   over    low  umin to low   ( adr len )
   2dup +  high umax to high  ( adr len )
   release
;

headers
: probe  ( -- )
   0 sdram-size log&release

   0 0 encode-bytes                                   ( adr 0 )
   physavail  ['] make-phys-memlist  find-node        ( adr len  prev 0 )
   2drop  " reg" property

   \ Claim the memory used by OFW
\   high h# 10.0000 -  h# 10.0000    0 claim  drop
;

device-end
