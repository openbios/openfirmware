purpose: Repair manufacturing data

/ec buffer: ec-buf

: reverse$  ( adr len -- )
   over + 1-                ( start end )
   begin  2dup u>  while    ( start end )
      over c@  over c@      ( start end sb eb )
      3 pick c!             ( start end sb )
      over c!               ( start end )
      swap 1+ swap 1-       ( start' end' )
   repeat                   ( start end )
   2drop                    ( )
;

: ?fix-mfg-data  ( -- )
   \ Exit if the mfg data is missing
   " P#" find-tag  0=  if  exit  then     ( data$ )
   \ Exit if the mfg data is already ordered correctly
   drop " 1CL1" comp  0=  if  exit  then  ( )
   
   spi-start spi-identify

   flash-base ec-buf /ec move

   ec-buf /ec +                   ( adr )
   begin  another-tag?  while     ( adr' data$ name-adr )
      drop  reverse$              ( adr )
   repeat                         ( adr )
   drop                           ( )

   ec-buf /ec 0 write-flash-range
   \ power-off
;
