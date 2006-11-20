\ Extract the keyboard type info from the manufacturing data
\ and export it via CMOS RAM.

h# 50 constant pn-cmos-offset
: set-pn  ( -- )
   atest?  if  [char] A  else  [char] B  then
   pn-cmos-offset cmos!
   [char] 1 pn-cmos-offset 1+ cmos!
;

h# 52 constant kb-cmos-offset

: set-kb-name  ( name$ -- )
   [char] K kb-cmos-offset cmos!
   [char] B kb-cmos-offset 1+ cmos!
   kb-cmos-offset 2+  -rot  bounds ?do   ( cmos-offset )
      i c@ over cmos!  1+                ( cmos-offset' )
   loop                                  ( cmos-offset )
   0 swap cmos!
;

: set-keyboard-code  ( -- )
   0 kb-cmos-offset c!      \ Initially declare failure
   " P#" find-tag  if           ( data$ )
      8 <  if  drop exit  then  ( data-adr )
      6 +                       ( country-adr )
      dup  " U0" comp  0=  if  drop " us_INTL" set-kb-name exit  then
      dup  " T0" comp  0=  if  drop " pt_BR"   set-kb-name exit  then
      dup  " P0" comp  0=  if  drop " es"      set-kb-name exit  then
      dup  " -0" comp  0=  if  drop " th"      set-kb-name exit  then
      dup  " Q0" comp  0=  if  drop " ara"     set-kb-name exit  then
      dup  " AB" comp  0=  if  drop " ng"      set-kb-name exit  then
      drop
   then
;

warning @ warning off
: stand-init
   stand-init
   set-pn
   set-keyboard-code
;
warning !
