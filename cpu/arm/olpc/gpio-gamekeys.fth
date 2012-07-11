: gpio-game-key@  ( -- n )
   0                                        ( n )
   rotate-gpio# gpio-pin@ 0=  if  button-rotate  or  then
   d# 16 gpio-pin@ 0=  if  button-o       or  then
   d# 17 gpio-pin@ 0=  if  button-check   or  then
   d# 18 gpio-pin@ 0=  if  button-x       or  then
   d# 19 gpio-pin@ 0=  if  button-square  or  then
   d# 20 gpio-pin@ 0=  if  rocker-up      or  then
   d# 21 gpio-pin@ 0=  if  rocker-right   or  then
   d# 22 gpio-pin@ 0=  if  rocker-down    or  then
   d# 23 gpio-pin@ 0=  if  rocker-left    or  then
;
' gpio-game-key@ to game-key@

: gpio-rotate-button?  ( -- flag )  rotate-gpio# gpio-pin@ 0=  ;
' gpio-rotate-button? to rotate-button?
