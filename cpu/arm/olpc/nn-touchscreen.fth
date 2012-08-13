\ See license at end of file
purpose: Driver and diagnostic for Neonode zForce MultiSensing I2C Touchscreen

0 0  " 4,a0"  " /twsi" begin-package
my-space encode-int  my-address encode-int encode+  " reg" property

\ XXX these are really platform-related, not touchscreen-related
: targets?  ( -- flag )  final-test?  ;
: .tsmsg  ( -- )  0 d# 27 at-xy  ." Touchscreen test.  Type a key to exit" cr  ;

fload ${BP}/cpu/arm/olpc/touchscreen-common.fth

[ifndef] 2u.x
: 2u.x  base @ >r hex  0 <# # # #> type  r> base !  ;
[then]

: set-gpios
   touch-rst-gpio# dup gpio-set gpio-dir-out
   touch-tck-gpio# dup gpio-clr gpio-dir-out
;
: reset  ( -- )  touch-rst-gpio# dup gpio-clr gpio-set  d# 250 ms  ;
: no-data?  ( -- no-data? )  touch-scr-gpio# gpio-pin@  ;

d# 250 constant /pbuf
0 value pbuf
0 value plen
0 value configure?

: in?  ( -- got-data? )
   no-data?  if  false exit  then

   pbuf 2  twsi-read                            ( )
   pbuf 1+ c@                                   ( len )
   dup 2+ to plen                               ( len )

   pbuf 2+ swap  twsi-read                      ( )

   pbuf 2+ c@ h# 07 =  pbuf 3 + c@ 0=  and  if  ( )
      true to configure?
   then
   true
;

: anticipate  ( id msecs -- )
   get-msecs +                          ( id limit )
   begin
      in?  if
         over pbuf 2+ c@                ( id limit received-id )
         =  if  2drop exit  then
      then                              ( id limit )
      dup get-msecs -  0<               ( id limit timeout? )
   until                                ( id limit )
   2drop                                ( )
;

: read-boot-complete  ( -- )  h# 07 d# 20 anticipate  ;

: initialise  ( -- )  h# 01 h# 01 h# ee  3 twsi-out  h# 01 d# 20 anticipate  ;

: set-resolution  ( -- )
   set-geometry
   screen-h wbsplit swap  screen-w wbsplit swap  h# 02 h# 05 h# ee  7 twsi-out
   h# 02 d# 20 anticipate
;

: start  ( -- )  h# 04 h# 01 h# ee  3 twsi-out  ;

: deactivate  ( -- )
   h# 00 h# 01 h# ee  3 twsi-out  h# 00 d# 20 anticipate
   true to configure?
;

: configure  ( -- )
   configure?  if
      initialise
      set-resolution
      start
      false to configure?
   then
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
         exit
      then
   then
   configure
   false
;


0 value faults
: fault  faults 1+ to faults  ;

: .bits  ( addr low high -- addr )
   ." ( "  swap  do                                     ( addr )
      i over bittest  if
         i .d  fault
      then
   loop  ." )" cr                                       ( addr )
;

: 4sp  ."     "  ;

: 8sp  ."         "  ;

: test-os-axis  ( axis -- )
   h# 21 h# 02 h# ee  4 twsi-out
   h# 21 d# 30 anticipate
   pbuf 2+ c@ h# 21 <> abort" bad response"

   pbuf 3 + c@  if h# 0a else h# 0e then  >r            ( r:nleds )
   pbuf 5 +                                             ( r:nleds array )

   \ bit array layout: | open_pd   | short_pd  | short_led  | open_led   |
   \ subarray widths:  | npds bits | npds bits | nleds bits | nleds bits |
   \ npds = nleds+1

   \ FIXME: express failed devices in terms of IR PCB component names.
   \                         0               npds
   8sp  ." open_pd="         0               r@ 1+           .bits
   \                         npds            npds*2
   8sp  ." short_pd="        r@ 1+           r@ 1+ 2*        .bits
   \                         npds*2          npds*2+nleds
   8sp  ." short_led="       r@ 1+ 2*        dup r@ +        .bits
   \                         npds*2+nleds    npds*2+nleds*2
   8sp  ." open_led="        r@ 1+ 2* r@ +   dup r@ +        .bits
   r> drop drop                                         ( )
   cr
;

: test-os
   ." Open and Short" cr
   4sp ." X Axis" cr  0 test-os-axis
   4sp ." Y Axis" cr  1 test-os-axis
;

: test-fss-axis  ( axis -- )
   d# 64 swap h# 0f h# 03 h# ee  5 twsi-out
   h# 0f d# 20 anticipate
   pbuf 2+ c@ h# 0f <> abort" bad response"
   8sp
   push-decimal
   pbuf 4 + c@ 0  do   ( )
      pbuf 5 + i + c@
      dup 0=  if  fault  then
      4 .r space
      i d# 10 mod d# 9 =  if  cr 8sp  then
   loop  cr
   pop-base
   \ FIXME: using a light guide, characterise a low signal level,
   \ detect, and fail self test
   \ FIXME: express failed signals in terms of IR PCB component names.
;

: test-fss
   ." Fixed Signal Strength" cr
   4sp ." X Axis" cr  0 test-fss-axis
   4sp ." Y Axis" cr  1 test-fss-axis
;

: test-ls-axis  ( axis -- )
   h# 0d h# 02 h# ee  4 twsi-out
   h# 0d d# 200 anticipate
   pbuf 2+ c@ h# 0d <> abort" bad response"

   8sp
   pbuf 4 + c@  >r					( r:nsigs )
   pbuf 5 +                                             ( r:nsigs array )
   0 r@ 1+ .bits					( r:nsigs array )
   r> drop drop                                         ( )
   cr
   \ FIXME: express low signals in terms of IR PCB component names.
;

: test-ls
   ." Low Signals" cr
   4sp ." X Axis" cr  0 test-ls-axis
   4sp ." Y Axis" cr  1 test-ls-axis
;

: selftest  ( -- error? )

   \ skip test during SMT, as the IR PCB is required for controller to
   \ respond, issue being worked with Neonode 2012-08.
   smt-test?  if  false  exit  then

   open  0=  if
      ." No touchscreen present" cr  false exit
   then

   diagnostic-mode?  if
      0 to faults
      test-os
      test-fss
      test-ls
      faults  if  true  exit  then
   then

   ." dumping events from touchscreen controller, press a key to stop" cr

   \ FIXME: graphically show data on screen until key
   begin
      in?  if
         ." rx: "  pbuf plen  bounds  do
            i c@  2u.x  space
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
