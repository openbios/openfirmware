purpose: Configuration variables needed by early startup code
\ See license at end of file

d#  20 value /fixed-nv
h# 7ec value fixed-nv-base	\ Override as needed for the platform

true value fixed-nv-ok?

: fixed-nv@  ( offset -- byte )
   fixed-nv-base +  nv-c@
;
: fixed-nv!  ( byte offset -- )
   fixed-nv-base +  nv-c!
;

: fixed-nv-checksum  ( -- checksum )
   0  /fixed-nv  0  ?do  i fixed-nv@ xor  loop  ( checksum )
;

: set-fixed-nv-checksum  ( -- )
   fixed-nv-checksum  0 fixed-nv@ xor  h# 5a xor  0 fixed-nv!
;

6 actions
action: fixed-nv-ok?  if  l@ fixed-nv@ 0<>  else  la1+ @  then  ;
action: l@ fixed-nv! set-fixed-nv-checksum  ;
action: l@  ;
action: drop flag>$  ;
action: drop $>flag  ;
action: la1+ @ 0<>  ;

: fixed-nv-flag  ( "name" default-value offset -- )
   create-option use-actions  l, ,  
;

6 actions
action:
   fixed-nv-ok?  if
      l@  4 bounds  do  i fixed-nv@  loop  swap 2swap swap bljoin
   else
      la1+ @
   then
;
action:
   l@ >r  lbsplit  r> 4 bounds  do  i fixed-nv!  loop
   set-fixed-nv-checksum
;
action: l@  ;
action: drop  push-hex <# u#s [char] x hold  [char] 0 hold u#>  pop-base  ;
action: drop $>number  ;
action: la1+ @  ;

: fixed-nv-int  ( "name" default-value offset -- )
   create-option use-actions  l, ,  
;

false     1 fixed-nv-flag diag-switch?
false     2 fixed-nv-flag real-mode?
-1        3 fixed-nv-int  real-base
-1        7 fixed-nv-int  real-size
-1    d# 11 fixed-nv-int  virt-base
-1    d# 15 fixed-nv-int  virt-size
false d# 19 fixed-nv-flag hrp-memmap?

' diag-switch? is (diagnostic-mode?)

: init-fixed-nv  ( -- )
   fixed-nv-checksum h# 5a = ?dup  if  to fixed-nv-ok? exit  then
   ['] diag-switch? do-set-default
   ['] real-mode?   do-set-default
   ['] real-base    do-set-default
   ['] real-size    do-set-default
   ['] virt-base    do-set-default
   ['] virt-size    do-set-default
   ['] hrp-memmap?  do-set-default
   fixed-nv-checksum h# 5a =  to fixed-nv-ok?
;

\ LICENSE_BEGIN
\ Copyright (c) 1997 FirmWorks
\
\ Permission is hereby granted, free of charge, to any person obtaining
\ a copy of this software and associated documentation files (the
\ "Software"), to deal in the Software without restriction, including
\ without limitation the rights to use, copy, modify, merge, publish,
\ distribute, sublicense, and/or sell copies of the Software, and to
\ permit persons to whom the Software is furnished to do so, subject to
\ the following conditions:
\
\ The above copyright notice and this permission notice shall be
\ included in all copies or substantial portions of the Software.
\
\ THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
\ EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
\ MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
\ NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
\ LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
\ OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
\ WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
\
\ LICENSE_END

