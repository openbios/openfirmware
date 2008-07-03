purpose: Interrupt mapping support functions
\ See license at end of file

headerless
: pin,dev>isa-irq  ( pin# dev# -- true | irq-irq# false )
   " slot-map" $call-self                  ( pin# dev# adr )
   begin  dup c@  ff <>  while             ( pin# dev# adr )
      2dup c@ =  if                        ( pin# dev# adr )
         nip 1+ + c@ false exit
      then                                 ( pin# dev# adr )
      5 +                                  ( pin# dev# adr' )
   repeat                                  ( pin# dev# adr' )
   3drop true
;

0 value interrupt-parent

headers
1  " #interrupt-cells" integer-property
0 0 encode-bytes  0000.f800 +i  0+i  0+i  7 +i  " interrupt-map-mask" property

headerless
: +map  ( adr len dev# int-pin# int-level -- adr' len' )
   >r >r                           ( $ dev# R: level pin )
   h# 800 *  +i                    ( $' R: level pin )
   0+i 0+i  r> +i                  ( $' R: level )
   interrupt-parent +i             ( $' R: level )
   r> +i  1 +i                     ( $' )
;

headers
external

: make-isapic-interrupt-map  ( -- )
   " /isa/interrupt-controller" find-package  0=  if  exit  then  to interrupt-parent

   0 0 encode-bytes

   " slot-map" $call-self                    ( adr )
   begin  dup c@  h# ff <>  while            ( adr )
      \ Each table entry contains dev#,pin1,pin2,pin3,pin4
      \ We loop over the pin numbers and create map entries for each
      \ valid pin entry.
      5 1  do                                ( adr ) 
         dup i + c@  h# ff <>  if            ( adr )
            i swap >r                        ( pin# R: adr )
            r@ c@  swap  dup r@ + c@  +map   ( R: adr )
            r>                               ( adr )
         then                                ( adr )
      loop                                   ( adr )
      5 +                                    ( adr' )
   repeat                                    ( adr )
   drop

   " interrupt-map" property
;

: assign-int-line  ( phys.hi.func int-pin -- false | int-line true )
   dup 0=  if  2drop false  exit  then               ( phys.hi.func int-pin# )
   1-  swap d# 11 rshift  h# 1f and                  ( int-pin0 dev# )

   \ Bail out for non-existent device IDs
   pin,dev>pic-irq  if  false exit  then             ( opic-int# )

   true
;

\ LICENSE_BEGIN
\ Copyright (c) 2008 FirmWorks
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
