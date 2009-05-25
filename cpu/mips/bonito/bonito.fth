purpose: Forth words for Bonito 
copyright: Copyright 2000-2001 FirmWorks  All Rights Reserved

defer pcicache-wbinv	' 2drop to pcicache-wbinv
defer pcicache-inv      ' 2drop to pcicache-inv

: bonito-iobc-cmd!  ( cmd line -- )
   ( cmd ) ( line ) 3 << or dup pcicachectrl !
   dup h# 20 or pcicachectrl !
   begin  pcicachectrl @ h# 20 and  0=  until
   pcicachectrl !
;

: bonito-iobc-range  ( pa size cmd -- )
   over 0=  if  3drop exit  then
   rot h# 1fff.ffff and rot over + rot
   4 0 do                           ( pa top cmd )
      2 i bonito-iobc-cmd!          ( pa top cmd )  \ Read tag
      pcicachetag @ dup h# 0100.0000 and  if
         h# 00ff.ffff and 5 <<      ( pa top cmd tag )
         2 pick over >              ( pa top cmd tag flag )
         swap h# 20 + 4 pick > and  ( pa top cmd flag )
         if  dup i bonito-iobc-cmd!  then  ( pa size cmd )  \ Write-back & invalidate
      else
         drop                       ( pa size cmd )
      then
   loop  3drop
;

: bonito-iobc-wbinv-all ( -- )
   4 0 do
      2 i bonito-iobc-cmd!
      pcicachetag @ h# 0100.0000 and  if
         1 i bonito-iobc-cmd!
      then
   loop
   3 0 bonito-iobc-cmd!             \ Flush write queue
;

: bonito-iobc-wbinv  ( pa size -- )
   1 bonito-iobc-range              \ Write-back & invalidate range
   3 0 bonito-iobc-cmd!             \ Flush write queue
;
' bonito-iobc-wbinv to pcicache-wbinv
   
: bonito-iobc-inv-all ( -- )
   4 0 do
      2 i bonito-iobc-cmd!
      pcicachetag @ h# 0100.0000 and  if
         0 i bonito-iobc-cmd!
      then
   loop
;
: bonito-iobc-inv  ( pa size -- )
   0 bonito-iobc-range              \ Invalidate range
;
' bonito-iobc-inv to pcicache-inv

: bonito-iobc-dump  ( -- )
   4 0 do
      2 i bonito-iobc-cmd!
      pcicachetag @
      i u. dup u. h# ff.ffff and 5 << u. cr
   loop
;

: init-bonito  ( -- )
   h# 0000.0800 h# 0c bonito-cfg-pa + w!
   h# 0000.0000 h# 10 bonito-cfg-pa + l!
   h# 2000.0000 h# 14 bonito-cfg-pa + l!
   h# 1000.0000 h# 18 bonito-cfg-pa + l!

   h# 0004.6144 pcimap    l!
   h# 0000.2c0f intedge   l!
   h# 6400.0000 intsteer  l!
   h# 6600.0000 intpol    l!
   h# 0004.21cf intenset  l!
   h# 1a41.fd1f intenclr  l!
;

stand-init: Initialize Bonito
   init-bonito
   bonito-iobc-inv-all
;
