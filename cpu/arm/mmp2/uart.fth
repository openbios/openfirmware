   " uart" name
   my-space  h# 20  reg

   : write  ( adr len -- actual )
      0 max  tuck                    ( actual adr actual )
      bounds  ?do  i c@ uemit  loop  ( actual )
   ;
   : read   ( adr len -- actual )
      0=  if  drop 0  exit  then
      ukey?  if           ( adr )
         ukey swap c!  1  ( actual )
      else                ( adr )
         drop  -2         ( -2 )
      then
   ;
   : open  ( -- okay? )  true  ;
   : close  ( -- )   ;
   : install-abort  ;
   : remove-abort  ;
