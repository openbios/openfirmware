\ See license at end of file
purpose: Driver and diagnostic for Neonode zForce MultiSensing I2C Touchscreen

0 0  " 4,a0"  " /twsi" begin-package
my-space encode-int  my-address encode-int encode+  " reg" property

\ XXX these are really platform-related, not touchscreen-related
: targets?  ( -- flag )  final-test?  ;
: .tsmsg  ( -- )  0 d# 27 at-xy  ." Touchscreen test.  Type a key to exit" cr  ;

fload ${BP}/cpu/arm/olpc/touchscreen-common.fth

: set-gpios
   touch-rst-gpio# dup gpio-set gpio-dir-out
   touch-tck-gpio# dup gpio-clr gpio-dir-out
;
: reset  ( -- )  touch-rst-gpio# dup gpio-clr gpio-set  d# 250 ms  ;
: no-data?  ( -- no-data? )  touch-scr-gpio# gpio-pin@  ;

d# 250 constant /packet
/packet buffer: packet
0 value packet-size

: in?  ( -- got-data? )
   no-data?  if  false exit  then

   packet 2  " twsi-read" $call-parent          ( )
   packet 1+ c@                                 ( size )
   dup 2+ to packet-size                        ( size )

   packet 2+ swap  " twsi-read" $call-parent    ( )
   true
;

: out  ( byte ... bytes# -- )  " twsi-out" $call-parent  ;

defer process
' noop to process

: expect  ( id msecs -- )
   get-msecs +                          ( id limit )
   begin
      in?  if
         process
         over packet 2+ c@              ( id limit received-id )
         =  if  2drop exit  then
      then                              ( id limit )
      dup get-msecs -  0<               ( id limit timeout? )
   until                                ( id limit )
   2drop                                ( )
;

: read-boot-complete  ( -- )  h# 07 d# 10 expect  ;

: initialise  ( -- )  h# ee h# 01 h# 01  3 out  h# 01 d# 10 expect  ;

: set-resolution  ( -- )
   set-geometry
   h# ee h# 05 h# 02  screen-w wbsplit  screen-h wbsplit  7 out
   h# 02 d# 10 expect
;

: start  ( -- )  h# ee h# 01 h# 04  3 out  ;

: deactivate  ( -- )  h# ee h# 01 h# 00  3 out  h# 00 d# 10 expect  ;

: configure  ( -- )
   read-boot-complete
   initialise
   set-resolution
   start
;

: open  ( -- okay? )
   my-unit " set-address" $call-parent
   set-gpios
   no-data?  if  reset  then
   no-data?  if  false exit  then
   ['] configure  catch  if  false exit  then
   true
;

: close
   deactivate
;

: stream-poll?  ( -- false | x y buttons true )
   in?  if
      packet 2+ c@ h# 04 = if
         packet 4 + w@  packet 6 + w@   ( x y )
         packet 8 + c@  3 and  0=       ( x y down? )
         true                           ( x y buttons true )
      else
         false
      then
   else
      false
   then
;

: selftest
   open  0=  if
      ." No touchscreen present" cr  false exit
   then

   \ FIXME: graphically show data on screen until key
   begin
      in?  if
         ." rx: " packet packet-size  bounds  do
            i c@  0 <# # # #> type space
         loop  cr
      then
      key?
   until
   key drop

   close false
;

end-package

\ LICENSE_BEGIN
\ Copyright (c) 2012 FirmWorks
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
