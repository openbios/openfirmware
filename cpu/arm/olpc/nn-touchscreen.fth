\ See license at end of file
purpose: Driver and diagnostic for Neonode zForce MultiSensing I2C Touchscreen

0 0  " 4,50"  " /twsi" begin-package
my-space encode-int  my-address encode-int encode+  " reg" property

\ XXX these are really platform-related, not touchscreen-related
: targets?  ( -- flag )  final-test?  ;
: .tsmsg  ( -- )  0 d# 27 at-xy  ." Touchscreen test.  Type a key to exit" cr  ;

[ifndef] set-geometry
fload ${BP}/cpu/arm/olpc/touchscreen-common.fth
[then]

[ifndef] 2u.x
: 2u.x  base @ >r hex  0 <# # # #> type  r> base !  ;
[then]

: set-gpios
   touch-rst-gpio# dup gpio-set gpio-dir-out
   touch-tck-gpio# dup gpio-clr gpio-dir-out
;
: reset  ( -- )  touch-rst-gpio# dup gpio-clr gpio-set  d# 250 ms  ;
: no-data?  ( -- no-data? )  touch-int-gpio# gpio-pin@  ;

d# 250 constant /pbuf
0 value pbuf
0 value plen
0 value configure?

: pbuf-alloc  /pbuf alloc-mem to pbuf  ;
: pbuf-free  pbuf /pbuf free-mem  ;

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

: read-boot-complete  ( -- )  h# 07 d# 0 anticipate  ;

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
   pbuf-alloc
   my-unit set-twsi-target
   set-gpios
   no-data?  if
      reset
      no-data?  if
	 ." no response to reset" cr
	 pbuf-free  false  exit
      then
   then
   ['] read-boot-complete  catch  if
      ." no response on bus" cr
      pbuf-free  false  exit
   then
   ['] configure  catch  if
      ." failed to configure" cr
      pbuf-free  false  exit
   then
   true
;

: close
   deactivate
   pbuf-free
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


: (.version)  ( addr -- )
   dup c@  over 1+ c@  bwjoin           ( addr version )
   (.) type
;

: .version  ( addr -- )
   pbuf 2+ c@ h# 1e <> abort" bad response"
   ." Neonode zForce Touch Driver firmware version "
   pbuf 3 +  3 0  do                    ( addr )
      (.version) 2+
      [char] . emit
   loop                                 ( addr )
   (.version)                       ( )
;

: test-version  ( -- )
   h# 1e h# 01 h# ee  3 twsi-out
   h# 1e d# 30 anticipate

   .version
   cr
;


0 value faults
: fault  faults 1+ to faults  ;

: 4sp  ."     "  ;

: 8sp  ."         "  ;

[ifdef] nn-components
\ optional decoding of component identifiers

\ bit descriptions
\ shorts have been verified
\ a trailing ? means this combination is untested
string-array x-os

    ," PD13 open?"	\ 01 00 00 00 00 00 00 00
    ," PD14 open?"	\ 02 00 00 00 00 00 00 00
    ," PD15 open?"	\ 04 00 00 00 00 00 00 00
    ," PD16 open?"	\ 08 00 00 00 00 00 00 00
    ," PD17 open?"	\ 10 00 00 00 00 00 00 00
    ," PD18 open?"	\ 20 00 00 00 00 00 00 00
    ," PD19 open?"	\ 40 00 00 00 00 00 00 00
    ," PD20 open?"	\ 80 00 00 00 00 00 00 00

    ," PD21 open?"	\ 00 01 00 00 00 00 00 00
    ," PD22 open?"	\ 00 02 00 00 00 00 00 00
    ," PD23 open?"	\ 00 04 00 00 00 00 00 00
    ," PD24 open?"	\ 00 08 00 00 00 00 00 00
    ," PD25 open?"	\ 00 10 00 00 00 00 00 00
    ," PD26 open?"	\ 00 20 00 00 00 00 00 00
    ," PD27 open?"	\ 00 40 00 00 00 00 00 00
    ," PD28 open?"	\ 00 80 00 00 00 00 00 00

    ," PD13 short"	\ 00 00 01 00 00 00 00 00
    ," PD14 short"	\ 00 00 02 00 00 00 00 00
    ," PD15 short"	\ 00 00 04 00 00 00 00 00
    ," PD16 short"	\ 00 00 08 00 00 00 00 00
    ," PD17 short"	\ 00 00 10 00 00 00 00 00
    ," PD18 short"	\ 00 00 20 00 00 00 00 00
    ," PD19 short"	\ 00 00 40 00 00 00 00 00
    ," PD20 short"	\ 00 00 80 00 00 00 00 00

    ," PD21 short"	\ 00 00 00 01 00 00 00 00
    ," PD22 short"	\ 00 00 00 02 00 00 00 00
    ," PD23 short"	\ 00 00 00 04 00 00 00 00
    ," PD24 short"	\ 00 00 00 08 00 00 00 00
    ," PD25 short"	\ 00 00 00 10 00 00 00 00
    ," PD26 short"	\ 00 00 00 20 00 00 00 00
    ," PD27 short"	\ 00 00 00 40 00 00 00 00
    ," PD28 short"	\ 00 00 00 80 00 00 00 00

    ," IR12 short"	\ 00 00 00 00 01 00 00 00
    ," IR13 short"	\ 00 00 00 00 02 00 00 00
    ," IR14 short"	\ 00 00 00 00 04 00 00 00
    ," IR15 short"	\ 00 00 00 00 08 00 00 00
    ," IR16 short"	\ 00 00 00 00 10 00 00 00
    ," IR17 short"	\ 00 00 00 00 20 00 00 00
    ," IR18 short"	\ 00 00 00 00 40 00 00 00
    ," IR19 short"	\ 00 00 00 00 80 00 00 00

    ," IR20 short"	\ 00 00 00 00 00 01 00 00
    ," IR21 short"	\ 00 00 00 00 00 02 00 00
    ," IR22 short"	\ 00 00 00 00 00 04 00 00
    ," IR23 short"	\ 00 00 00 00 00 08 00 00
    ," IR24 short"	\ 00 00 00 00 00 10 00 00
    ," IR25 short"	\ 00 00 00 00 00 20 00 00
    ," IR26 short"	\ 00 00 00 00 00 40 00 00
    ," reserved?"	\ 00 00 00 00 00 80 00 00

    ," IR12 open?"	\ 00 00 00 00 00 00 01 00
    ," IR13 open?"	\ 00 00 00 00 00 00 02 00
    ," IR14 open?"	\ 00 00 00 00 00 00 04 00
    ," IR15 open?"	\ 00 00 00 00 00 00 08 00
    ," IR16 open?"	\ 00 00 00 00 00 00 10 00
    ," IR17 open?"	\ 00 00 00 00 00 00 20 00
    ," IR18 open?"	\ 00 00 00 00 00 00 40 00
    ," IR19 open?"	\ 00 00 00 00 00 00 80 00

    ," IR20 open?"	\ 00 00 00 00 00 00 00 01
    ," IR21 open?"	\ 00 00 00 00 00 00 00 02
    ," IR22 open?"	\ 00 00 00 00 00 00 00 04
    ," IR23 open?"	\ 00 00 00 00 00 00 00 08
    ," IR24 open?"	\ 00 00 00 00 00 00 00 10
    ," IR25 open?"	\ 00 00 00 00 00 00 00 20
    ," IR26 open?"	\ 00 00 00 00 00 00 00 40
    ," reserved?"	\ 00 00 00 00 00 00 00 80

end-string-array

string-array y-os

    ," PD4 open?"	\ 01 00 00 00 00 00
    ," PD3 open?"	\ 02 00 00 00 00 00
    ," PD2 open?"	\ 04 00 00 00 00 00
    ," PD1 open?"	\ 08 00 00 00 00 00
    ," PD12 open?"	\ 10 00 00 00 00 00
    ," PD11 open?"	\ 20 00 00 00 00 00
    ," PD10 open?"	\ 40 00 00 00 00 00
    ," PD9 open?"	\ 80 00 00 00 00 00

    ," PD8 open?"	\ 00 01 00 00 00 00
    ," PD7 open?"	\ 00 02 00 00 00 00
    ," PD6 open?"	\ 00 04 00 00 00 00
    ," PD5 open?"	\ 00 08 00 00 00 00
    ," PD12 short"	\ 00 10 00 00 00 00
    ," PD11 short"	\ 00 20 00 00 00 00
    ," PD10 short"	\ 00 40 00 00 00 00
    ," PD9 short"	\ 00 80 00 00 00 00

    ," PD8 short"	\ 00 00 01 00 00 00
    ," PD7 short"	\ 00 00 02 00 00 00
    ," PD6 short"	\ 00 00 04 00 00 00
    ," PD5 short"	\ 00 00 08 00 00 00
    ," PD4 short"	\ 00 00 10 00 00 00
    ," PD3 short"	\ 00 00 20 00 00 00
    ," PD2 short"	\ 00 00 40 00 00 00
    ," PD1 short"	\ 00 00 80 00 00 00

    ," IR11 short"	\ 00 00 00 01 00 00
    ," IR10 short"	\ 00 00 00 02 00 00
    ," IR9 short"	\ 00 00 00 04 00 00
    ," IR8 short"	\ 00 00 00 08 00 00
    ," IR7 short"	\ 00 00 00 10 00 00
    ," IR6 short"	\ 00 00 00 20 00 00
    ," IR5 short"	\ 00 00 00 40 00 00
    ," IR4 short"	\ 00 00 00 80 00 00

    ," IR3 short"	\ 00 00 00 00 01 00
    ," IR2 short"	\ 00 00 00 00 02 00
    ," IR1 short"	\ 00 00 00 00 04 00
    ," reserved?"	\ 00 00 00 00 08 00
    ," reserved?"	\ 00 00 00 00 10 00
    ," IR11 open?"	\ 00 00 00 00 20 00
    ," IR10 open?"	\ 00 00 00 00 40 00
    ," IR9 open?"	\ 00 00 00 00 80 00

    ," IR8 open?"	\ 00 00 00 00 00 01
    ," IR7 open?"	\ 00 00 00 00 00 02
    ," IR6 open?"	\ 00 00 00 00 00 04
    ," IR5 open?"	\ 00 00 00 00 00 08
    ," IR4 open?"	\ 00 00 00 00 00 10
    ," IR3 open?"	\ 00 00 00 00 00 20
    ," IR2 open?"	\ 00 00 00 00 00 40
    ," IR1 open?"	\ 00 00 00 00 00 80

end-string-array

defer our-os
' noop is our-os
[then]

d# 64 constant /x-os
d# 48 constant /y-os

: test-os-axis  ( axis -- )
   h# 21 h# 02 h# ee  4 twsi-out
   h# 21 d# 30 anticipate
   pbuf 2+ c@ h# 21 <> abort" bad response"

   pbuf d#  5 +                         ( addr )

   pbuf 3 + c@  if
      pbuf 4 + c@  h# 16  <> abort" bad signals y"
      [ifdef] nn-components
	 ['] y-os to our-os
      [then]
      /y-os                             ( addr bits# )
   else
      pbuf 4 + c@  h# 1e  <> abort" bad signals x"
      [ifdef] nn-components
	 ['] x-os to our-os
      [then]
      /x-os                             ( addr bits# )
   then

   0 do					( addr )
      dup c@				( addr byte )
      i 8 mod				( addr byte bit# )
      rshift 1 and  if			( addr )
	 8sp
	 [ifdef] nn-components
	    i our-os count type
	 [then]
	 ."  ( bit " i .d ." )" cr
	 fault
      then				( addr )
      i 8 mod  7 =  if  1+  then	( addr' )
   loop drop				( )
   cr
;

: test-os
   ." Open and Short" cr
   4sp ." X Axis" cr  0 test-os-axis
   4sp ." Y Axis" cr  1 test-os-axis
;

[ifdef] nn-components
d# 11 constant x-ir-0 \ first X axis IR component identifier
d# 12 constant x-pd-0 \ first X axis PD component identifier
d# -1 constant x-up   \ direction of numbering

d# 12 constant y-ir-0
d# 13 constant y-pd-0
d#  1 constant y-up
[then]

d# 1 value fss-min

: test-fss-axis  ( axis -- )
   d# 64 swap h# 0f h# 03 h# ee  5 twsi-out
   h# 0f d# 20 anticipate
   pbuf 2+ c@ h# 0f <> abort" bad response"
   8sp
   push-decimal
   pbuf 4 + c@ 0  do   ( )
      pbuf 5 + i + c@
      dup fss-min <  if  fault  then
      4 .r space
      i d# 10 mod d# 9 =  if  cr 8sp  then
   loop  cr
   pop-base
[ifdef] nn-components
   \ FIXME: express failed signals in terms of IR PCB component names.
   \ Y axis, IR11 PD12, IR11 PD11, IR10 PD11 ... IR1 PD1
   \ X axis, IR12 PD13, IR12 PD14, IR13 PD14 ... IR26 PD28
[then]
   \ FIXME: using a light guide, characterise a low signal level,
   \ detect, and fail self test
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
   pbuf 5 +                     ( addr )
   pbuf 4 + c@                  ( addr #bits )
   ." ( "  0 do                 ( addr )
      dup c@                    ( addr byte )
      i 8 mod                   ( addr byte bit# )
      rshift 1 and  if          ( addr )
	 i .d
	 fault
      then
      i 8 mod                   ( addr rem )
      7 =  if  1+  then         ( addr' )
   loop drop                    ( )
   ." )" cr
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
      test-version
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
