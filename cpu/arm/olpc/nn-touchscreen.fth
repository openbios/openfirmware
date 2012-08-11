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

d# 250 constant /pbuf
0 value pbuf
0 value plen

: in?  ( -- got-data? )
   no-data?  if  false exit  then

   pbuf 2  twsi-read                            ( )
   pbuf 1+ c@                                   ( len )
   dup 2+ to plen                               ( len )

   pbuf 2+ swap  twsi-read                      ( )
   true
;

: out  ( byte ... bytes# -- )  twsi-out  ;

defer process
' noop to process

: anticipate  ( id msecs -- )
   get-msecs +                          ( id limit )
   begin
      in?  if
         process
         over pbuf 2+ c@                ( id limit received-id )
         =  if  2drop exit  then
      then                              ( id limit )
      dup get-msecs -  0<               ( id limit timeout? )
   until                                ( id limit )
   2drop                                ( )
;

: read-boot-complete  ( -- )  h# 07 d# 20 anticipate  ;

: initialise  ( -- )  h# 01 h# 01 h# ee  3 out  h# 01 d# 20 anticipate  ;

: set-resolution  ( -- )
   set-geometry
   screen-h wbsplit swap  screen-w wbsplit swap  h# 02 h# 05 h# ee  7 out
   h# 02 d# 20 anticipate
;

: start  ( -- )  h# 04 h# 01 h# ee  3 out  ;

: deactivate  ( -- )  h# 00 h# 01 h# ee  3 out  h# 00 d# 20 anticipate  ;

: configure  ( -- )
   initialise
   set-resolution
   start
;

: open  ( -- okay? )
   /pbuf alloc-mem to pbuf
   my-unit set-twsi-target
   set-gpios
   no-data?  if
      reset
      no-data?  if  pbuf /pbuf free-mem  false exit  then
      read-boot-complete
   then
   ['] configure  catch  if  pbuf /pbuf free-mem  false exit  then
   true
;

: close
   deactivate
   pbuf /pbuf free-mem
;

: stream-poll?  ( -- false | x y buttons true )
   in?  if
      pbuf 2+ c@ h# 04 = if
         pbuf 4 + w@  pbuf 6 + w@       ( x y )
         pbuf 8 + c@  3 and  0=         ( x y down? )
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

   ." dumping events from touchscreen controller, press a key to stop" cr

   \ FIXME: graphically show data on screen until key
   begin
      in?  if
         ." rx: "  pbuf plen  bounds  do
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
