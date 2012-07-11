: (game-key@)  ( -- n )
   0                                        ( n )
   d# 16 gpio-pin@ 0=  if  h#  80 or  then  \ O
   d# 17 gpio-pin@ 0=  if  h#  02 or  then  \ Check
   d# 18 gpio-pin@ 0=  if  h# 100 or  then  \ X
   d# 19 gpio-pin@ 0=  if  h#  01 or  then  \ Square
   rotate-gpio# gpio-pin@ 0=  if  h#  40 or  then  \ Rotate
;
' (game-key@) to game-key@
