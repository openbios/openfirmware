\ See license at end of file
purpose: Interface to ACPI Embedded Controller internal variables

: ec-obf?  ( -- flag )  h# 66 pc@ 1 and  0<>  ;
: ec-ibf?  ( -- flag )  h# 66 pc@ 2 and  0<>  ;
: wait-ibf0
   h# 800  0  do  ec-ibf?  0=  if  unloop exit  then  d# 10 us  loop
   true abort" EC timeout"
;
: wait-obf  ( -- )
   h# 800  0  do  ec-obf?  if  unloop exit  then  d# 10 us  loop
   true abort" EC timeout"
;
: ec-cmd  ( cmd -- )  wait-ibf0 h# 66 pc!  ;
: ec-data!  ( data -- )  wait-ibf0 h# 62 pc!  ;
: ec-data@  ( data -- )  wait-obf h# 62 pc@  ;
: ec-cmd-data  ( data cmd -- )  ec-cmd  ec-data!  ;
: ec-sci@  ( -- b )  h# 84 ec-cmd  ec-data@  ;

: ec-b@  ( adr -- b )  h# 80 ec-cmd-data ec-data@  ;
: ec-b!  ( b adr -- )  h# 81 ec-cmd-data ec-data!  ;

: ec-w@  ( adr -- b )  dup ec-b@  swap 1+ ec-b@  bwjoin  ;
: ec-w!  ( b adr -- )  >r wbsplit  r@ 1+ ec-b!  r> ec-b!  ;

\ LICENSE_BEGIN
\ Copyright (c) 2011 FirmWorks
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
