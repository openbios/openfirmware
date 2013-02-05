\ See license at end of file
purpose: Driver and diagnostic for Neonode zForce MultiSensing I2C Touchscreen

dev /i2c@d4033000
new-device

h# 50 1 reg

" zforce" +compatible
touch-rst-gpio# 1  " reset-gpios" gpio-property
touch-tck-gpio# 1  " test-gpios"  gpio-property
touch-hd-gpio#  1  " hd-gpios"    gpio-property
touch-int-gpio# 1  " dr-gpios"    gpio-property

: read-bytes  ( adr len -- )  " read-bytes"  $call-parent  ;
: bytes-out  ( byte .. #bytes -- )  " bytes-out"  $call-parent  ;

create nn-os            \ open short test
create nn-fll           \ forced LED levels test
create nn-watch         \ graphical signal tests

create nn-fss           \ optional fixed signal strength test
\ create nn-ls            \ optional low signals test
create nn-fss-all       \ fixed signal strength test, all power levels

create nn-components    \ isolate test results to failed component identifier

d# 15 value xleds
d# 11 value yleds

0. 2value version#
: get-version  ( -- version.d )  version#  ;

: (.)'  ( version-segment.w -- )
   push-decimal  (.)  type  [char] . emit  pop-base
;

: .version  ( version.d -- )  lwsplit (.)' (.)'  lwsplit (.)' (.)'  ;

: show-version  ( -- )
   ." Neonode zForce Touch Driver firmware version "  version# .version  cr
;

\ XXX these are really platform-related, not touchscreen-related
: targets?  ( -- flag )  final-test?  ;
: (.tsmsg)  ( -- )  0 d# 27 at-xy  ." Touchscreen test.  Type a key to exit" cr  ;
defer .tsmsg
' (.tsmsg) to .tsmsg

[ifndef] set-geometry
fload ${BP}/cpu/arm/olpc/touchscreen-common.fth
[then]

[ifndef] 2u.x
: 2u.x  base @ >r hex  0 <# # # #> type  r> base !  ;
[then]

defer x>x'  ' noop to x>x'
: (x>x')  ( x -- x' )  screen-w swap -  ;  \ reverse x coordinate
: set-reverse-x  ['] (x>x') to x>x'  ;

: set-gpios
[ifdef] olpc-cl2
   0 1e2bc io!@ \ TWSI4_SCL
   0 1e2c0 io!@ \ TWSI4_SDA \ FIXME: discover why this is set to 5 on power up
[then]
   touch-rst-gpio# dup gpio-set gpio-dir-out
   touch-tck-gpio# dup gpio-clr gpio-dir-out
;

\ Neonode requested 250 ms
: reset  ( -- )  touch-rst-gpio# dup gpio-clr gpio-set  d# 250 ms  ;
: hold-reset  ( -- )  touch-rst-gpio# gpio-clr  ;
: no-data?  ( -- no-data? )  touch-int-gpio# gpio-pin@  ;
: absent?  ( -- flag )
   board-revision h# 4b20  >=  if
      touch-hd-gpio# gpio-pin@  0=
   else
      false
   then
;

d# 250 constant /pbuf
0 value pbuf
0 value plen
0 value configure?

: pbuf-alloc  /pbuf alloc-mem to pbuf  ;
: pbuf-free  pbuf /pbuf free-mem  ;

: in?  ( -- got-data? )
   no-data?  if  false exit  then

   pbuf 2  read-bytes                           ( )
   pbuf 1+ c@                                   ( len )
   dup 2+ to plen                               ( len )

   pbuf 2+ swap  read-bytes                     ( )

   pbuf 2+ c@ h# 07 =  pbuf 3 + c@ 0=  and  if  ( )
      true to configure?
   then
   true
;

\ read incoming packets, ignoring those that don't match, until either
\ one matches, or a timeout occurs.
: anticipate  ( id msecs -- )
   get-msecs +                          ( id limit )
   begin
      in?  if
         over pbuf 2+ c@                ( id limit received-id )
         =  if  2drop exit  then
      then                              ( id limit )
      dup get-msecs -  0<               ( id limit timeout? )
   until                                ( id limit )
   drop                                 ( id )
   ." timeout waiting for " 2u.x cr     ( )
   r> rstrace >r
   pbuf /pbuf erase
;

: ?id-abort  ( id $message -- )
   rot  pbuf 2+ c@  <>  if
      pbuf plen cdump
      r> rstrace >r
      cr
      $abort
   else
      2drop
   then
;

: ?missing
   pbuf 3 + c@  h# e0 = abort" missing IR PCB"
;

: flush-input  ( -- )
   begin
      in?  if
         pbuf 2+ c@  h# 07 =  if  ?missing  then
      then
      no-data?
   until
;

: read-boot-complete  ( -- )
   in?  if
      h# 07 " response other than boot complete" ?id-abort
      ?missing
   then
;


: read-version
   h# 1e h# 01 h# ee  3 bytes-out  h# 1e d# 100 anticipate
   h# 1e " response other than status" ?id-abort
   pbuf 9 + le-w@  pbuf 7 + le-w@ wljoin  pbuf 5 + le-w@ pbuf 3 + le-w@ wljoin
   to version#
;

: initialise  ( -- )  h# 01 h# 01 h# ee  3 bytes-out  h# 01 d# 20 anticipate  ;

: set-resolution  ( -- )
   set-geometry
   screen-h wbsplit swap  screen-w wbsplit swap  h# 02 h# 05 h# ee  7 bytes-out
   h# 02 d# 20 anticipate
;

: start  ( -- )  h# 04 h# 01 h# ee  3 bytes-out  ;

: deactivate  ( -- )
   h# 00 h# 01 h# ee  3 bytes-out  h# 00 d# 100 anticipate
;

: deconfigure  ( -- )
   configure?  0=  if
      deactivate
      true to configure?
   then
;

: configure  ( -- )
   configure?  if
      read-version
      version# h# 6. d<  if  set-reverse-x  then
      initialise
      set-resolution
      start
      false to configure?
   then
;

variable refcount  0 refcount !

: open  ( -- okay? )
   absent?  if  ." no touchscreen expected" cr  false exit  then
   my-unit " set-address" $call-parent
   refcount @ 0=  if
      pbuf-alloc
      set-gpios
      no-data?  if
         reset
         no-data?  if
            ." no response to reset" cr
            pbuf-free  false  exit
         then
         ['] read-boot-complete  catch  ?dup  if
            .error
            ." failed to boot" cr
            pbuf-free  false  exit
         then
      else
         flush-input
      then
      ['] configure  catch  ?dup  if
         .error
         ." failed to configure" cr
         pbuf-free  false  exit
      then
   then
   refcount @ 1+  refcount !
   true
;

: close
   refcount @ 1-  0 max  refcount !
   refcount @ 0=  if
      deconfigure
      pbuf-free
   then
;

: flush
   deconfigure
   configure
;

: stream-poll?  ( -- false | x y buttons true )
   in?  if
      \ FIXME: only handles one subpacket
      pbuf 2+ c@ h# 04 = if
         pbuf 4 + w@  x>x'              ( x )
         pbuf 6 + w@                    ( x y )
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

: 4sp  ."     "  ;

: 8sp  ."         "  ;



: test-response  ( -- )
   6 0  do
      h# 40 h# 0 h# 0f 3 h# ee 5 bytes-out \ fss full level
      h# 0f d# 130 anticipate
      pbuf 2+ c@ dup 0= abort" missing response after fixed signal strength"
      h# 0f <> abort" response other than fixed signal strength"
   loop
;



[ifdef] nn-os \ open short test

[ifdef] nn-components
\ optional decoding of component identifiers

\ bit descriptions
\ shorts have been verified
\ a trailing ? means this combination is untested
string-array x-os

    ," PD13 open?"      \ 01 00 00 00 00 00 00 00
    ," PD14 open?"      \ 02 00 00 00 00 00 00 00
    ," PD15 open?"      \ 04 00 00 00 00 00 00 00
    ," PD16 open?"      \ 08 00 00 00 00 00 00 00
    ," PD17 open?"      \ 10 00 00 00 00 00 00 00
    ," PD18 open?"      \ 20 00 00 00 00 00 00 00
    ," PD19 open?"      \ 40 00 00 00 00 00 00 00
    ," PD20 open?"      \ 80 00 00 00 00 00 00 00

    ," PD21 open?"      \ 00 01 00 00 00 00 00 00
    ," PD22 open?"      \ 00 02 00 00 00 00 00 00
    ," PD23 open?"      \ 00 04 00 00 00 00 00 00
    ," PD24 open?"      \ 00 08 00 00 00 00 00 00
    ," PD25 open?"      \ 00 10 00 00 00 00 00 00
    ," PD26 open?"      \ 00 20 00 00 00 00 00 00
    ," PD27 open?"      \ 00 40 00 00 00 00 00 00
    ," PD28 open?"      \ 00 80 00 00 00 00 00 00

    ," PD13 short"      \ 00 00 01 00 00 00 00 00
    ," PD14 short"      \ 00 00 02 00 00 00 00 00
    ," PD15 short"      \ 00 00 04 00 00 00 00 00
    ," PD16 short"      \ 00 00 08 00 00 00 00 00
    ," PD17 short"      \ 00 00 10 00 00 00 00 00
    ," PD18 short"      \ 00 00 20 00 00 00 00 00
    ," PD19 short"      \ 00 00 40 00 00 00 00 00
    ," PD20 short"      \ 00 00 80 00 00 00 00 00

    ," PD21 short"      \ 00 00 00 01 00 00 00 00
    ," PD22 short"      \ 00 00 00 02 00 00 00 00
    ," PD23 short"      \ 00 00 00 04 00 00 00 00
    ," PD24 short"      \ 00 00 00 08 00 00 00 00
    ," PD25 short"      \ 00 00 00 10 00 00 00 00
    ," PD26 short"      \ 00 00 00 20 00 00 00 00
    ," PD27 short"      \ 00 00 00 40 00 00 00 00
    ," PD28 short"      \ 00 00 00 80 00 00 00 00

    ," IR12 short"      \ 00 00 00 00 01 00 00 00
    ," IR13 short"      \ 00 00 00 00 02 00 00 00
    ," IR14 short"      \ 00 00 00 00 04 00 00 00
    ," IR15 short"      \ 00 00 00 00 08 00 00 00
    ," IR16 short"      \ 00 00 00 00 10 00 00 00
    ," IR17 short"      \ 00 00 00 00 20 00 00 00
    ," IR18 short"      \ 00 00 00 00 40 00 00 00
    ," IR19 short"      \ 00 00 00 00 80 00 00 00

    ," IR20 short"      \ 00 00 00 00 00 01 00 00
    ," IR21 short"      \ 00 00 00 00 00 02 00 00
    ," IR22 short"      \ 00 00 00 00 00 04 00 00
    ," IR23 short"      \ 00 00 00 00 00 08 00 00
    ," IR24 short"      \ 00 00 00 00 00 10 00 00
    ," IR25 short"      \ 00 00 00 00 00 20 00 00
    ," IR26 short"      \ 00 00 00 00 00 40 00 00
    ," reserved?"       \ 00 00 00 00 00 80 00 00

    ," IR12 open?"      \ 00 00 00 00 00 00 01 00
    ," IR13 open?"      \ 00 00 00 00 00 00 02 00
    ," IR14 open?"      \ 00 00 00 00 00 00 04 00
    ," IR15 open?"      \ 00 00 00 00 00 00 08 00
    ," IR16 open?"      \ 00 00 00 00 00 00 10 00
    ," IR17 open?"      \ 00 00 00 00 00 00 20 00
    ," IR18 open?"      \ 00 00 00 00 00 00 40 00
    ," IR19 open?"      \ 00 00 00 00 00 00 80 00

    ," IR20 open?"      \ 00 00 00 00 00 00 00 01
    ," IR21 open?"      \ 00 00 00 00 00 00 00 02
    ," IR22 open?"      \ 00 00 00 00 00 00 00 04
    ," IR23 open?"      \ 00 00 00 00 00 00 00 08
    ," IR24 open?"      \ 00 00 00 00 00 00 00 10
    ," IR25 open?"      \ 00 00 00 00 00 00 00 20
    ," IR26 open?"      \ 00 00 00 00 00 00 00 40
    ," reserved?"       \ 00 00 00 00 00 00 00 80

end-string-array

string-array y-os

    ," PD4 open?"       \ 01 00 00 00 00 00
    ," PD3 open?"       \ 02 00 00 00 00 00
    ," PD2 open?"       \ 04 00 00 00 00 00
    ," PD1 open?"       \ 08 00 00 00 00 00
    ," PD12 open?"      \ 10 00 00 00 00 00
    ," PD11 open?"      \ 20 00 00 00 00 00
    ," PD10 open?"      \ 40 00 00 00 00 00
    ," PD9 open?"       \ 80 00 00 00 00 00

    ," PD8 open?"       \ 00 01 00 00 00 00
    ," PD7 open?"       \ 00 02 00 00 00 00
    ," PD6 open?"       \ 00 04 00 00 00 00
    ," PD5 open?"       \ 00 08 00 00 00 00
    ," PD12 short"      \ 00 10 00 00 00 00
    ," PD11 short"      \ 00 20 00 00 00 00
    ," PD10 short"      \ 00 40 00 00 00 00
    ," PD9 short"       \ 00 80 00 00 00 00

    ," PD8 short"       \ 00 00 01 00 00 00
    ," PD7 short"       \ 00 00 02 00 00 00
    ," PD6 short"       \ 00 00 04 00 00 00
    ," PD5 short"       \ 00 00 08 00 00 00
    ," PD4 short"       \ 00 00 10 00 00 00
    ," PD3 short"       \ 00 00 20 00 00 00
    ," PD2 short"       \ 00 00 40 00 00 00
    ," PD1 short"       \ 00 00 80 00 00 00

    ," IR11 short"      \ 00 00 00 01 00 00
    ," IR10 short"      \ 00 00 00 02 00 00
    ," IR9 short"       \ 00 00 00 04 00 00
    ," IR8 short"       \ 00 00 00 08 00 00
    ," IR7 short"       \ 00 00 00 10 00 00
    ," IR6 short"       \ 00 00 00 20 00 00
    ," IR5 short"       \ 00 00 00 40 00 00
    ," IR4 short"       \ 00 00 00 80 00 00

    ," IR3 short"       \ 00 00 00 00 01 00
    ," IR2 short"       \ 00 00 00 00 02 00
    ," IR1 short"       \ 00 00 00 00 04 00
    ," reserved?"       \ 00 00 00 00 08 00
    ," reserved?"       \ 00 00 00 00 10 00
    ," IR11 open?"      \ 00 00 00 00 20 00
    ," IR10 open?"      \ 00 00 00 00 40 00
    ," IR9 open?"       \ 00 00 00 00 80 00

    ," IR8 open?"       \ 00 00 00 00 00 01
    ," IR7 open?"       \ 00 00 00 00 00 02
    ," IR6 open?"       \ 00 00 00 00 00 04
    ," IR5 open?"       \ 00 00 00 00 00 08
    ," IR4 open?"       \ 00 00 00 00 00 10
    ," IR3 open?"       \ 00 00 00 00 00 20
    ," IR2 open?"       \ 00 00 00 00 00 40
    ," IR1 open?"       \ 00 00 00 00 00 80

end-string-array

defer our-os
' noop is our-os
[then]

d# 64 constant /x-os
d# 48 constant /y-os

: test-os-axis  ( axis -- )
   h# 21 h# 02 h# ee  4 bytes-out
   h# 21 d# 100 anticipate
   h# 21 " response other than open short" ?id-abort

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

   0 do                                 ( addr )
      dup c@                            ( addr byte )
      i 8 mod                           ( addr byte bit# )
      rshift 1 and  if                  ( addr )
         8sp
         [ifdef] nn-components
            i our-os count type
         [then]
         ."  ( bit " i .d ." )" cr
         fault
      then                              ( addr )
      i 8 mod  7 =  if  1+  then        ( addr' )
   loop drop                            ( )
   cr
;

: test-os
   ." Open and Short" cr
   4sp ." X Axis" cr  0 test-os-axis
   4sp ." Y Axis" cr  1 test-os-axis
;
[then]



[ifdef] nn-fss \ fixed signal strength test

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
   d# 64 swap h# 0f h# 03 h# ee  5 bytes-out
   h# 0f d# 60 anticipate
   h# 0f " response other than fixed signal strength" ?id-abort
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
;

: test-fss
   ." Fixed Signal Strength" cr
   4sp ." X Axis" cr  0 test-fss-axis
   4sp ." Y Axis" cr  1 test-fss-axis
;
[then]



[ifdef] nn-fss-all \ fixed signal strength test, all power levels

: test-fss-axis-all  ( axis power -- )
   swap h# 0f h# 03 h# ee  5 bytes-out
   h# 0f d# 60 anticipate
   pbuf 2+ c@ h# 0f = if
      pbuf 4 + c@ 0  do   ( )
         pbuf 5 + i + c@
         .d
      loop  cr
   then
;

: test-fss-all
   41 0 do ." x " i .d 0 i test-fss-axis-all loop
   41 0 do ." y " i .d 1 i test-fss-axis-all loop
;

[then]



0 [if] \ fixed signal strength test, averaged, all power levels

d# 100 value n  \ number of tests to average

xleds yleds max 2* constant /sums
create sums
/sums 4 * allot
: 0sums  sums /sums 4 * erase  ;

: rc-signal  ( n -- )
   dup /sums > abort" sum index too large"
   pbuf 5 + over + c@   ( n signal )
   swap 4 * sums +      ( signal address )
   dup @                ( signal address sum )
   rot + swap !         ( )
;

: rc-sample  ( axis power -- )
   swap h# 0f h# 03 h# ee  5 bytes-out
   h# 0f d# 20 anticipate
   pbuf 2+ c@ h# 0f = if
      pbuf 4 + c@ 0  do         ( )
	 i rc-signal
      loop
   then
;

: rc-axis  ( axis power -- )
   0sums                                                ( axis power )
   n 0  do  2dup rc-sample  loop                        ( axis power )
   2drop                                                ( )
   pbuf 4 + c@ 0  do  i 4 * sums + @ n / .d  loop cr    ( )
;

: rc
   41 0 do ." x " i .d 0 i rc-axis loop
   41 0 do ." y " i .d 1 i rc-axis loop
;

[then]



0 [if] \ fixed signal strength test, all power levels, as a response curve

: >scaled  ( x y -- x' y' )
   d# 3750 * d# 1000 /  d# 900 swap -
   swap d# 1850 * d# 100 / swap
;

: >pseudo  ( level -- colour )  \ a red-yellow-green pseudocolour bar
   d# 256 over -  2*  d# 255 min  swap  2*  d# 255 min  0  rgb>565
;

: (plot-response)  ( power axis -- )
   over >r                          ( power axis  r: power )
   h# 0f h# 03 h# ee  5 bytes-out   ( r: power )
   h# 0f d# 20 anticipate
   r>                               ( power)
   pbuf 2+ c@ h# 0f = if
      pbuf 4 + c@ 0  do             ( power )
         pbuf 5 + i + c@            ( power signal )
         over swap                  ( power x y )
         >scaled

         i 4 lshift >pseudo  -rot   9 9  ( color x y w h )
         fill-rectangle-noff             ( )
      loop                          ( power )
   then                             ( power )
   drop
;

: plot-response
   black 0 0 screen-w screen-h fill-rectangle-noff
   41 1 do i 0 (plot-response) loop
   41 1 do i 1 (plot-response) loop
   key drop
;

[then]



[ifdef] nn-ls \ low signals test
: test-ls-axis  ( axis -- )
   h# 0d h# 02 h# ee  4 bytes-out
   h# 0d d# 200 anticipate
   h# 0d " response other than low signals" ?id-abort

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
[then]



[ifdef] nn-fll \ forced LED levels test
: test-fll-signal  ( signal# signal-value led-level -- )
   dup 0= if
      fault
      rot ." fail on axis signal " .d
      ." with LED level " .d ." (too strong) "
      ." signal level " .d
      cr
      exit
   then
   dup h# c > if
      fault
      rot ." fail on axis signal " .d
      ." with LED level " .d ." (too weak) "
      ." signal level " .d
      cr
      exit
   then
   \ 2drop ." pass on axis signal " .d cr
   3drop
[ifdef] nn-components
   \ FIXME: express forced led levels faults in terms of IR PCB component names.
[then]
;

: (fll)  ( axis# -- )
   h# 20 h# 02 h# ee  4 bytes-out
   h# 1c d# 200 anticipate
;

: test-fll-axis  ( axis -- )
   (fll)
   pbuf 4 + c@  2/  0  do
      i pbuf 5 + over 3 * + >r ( i r:frag )
      2* dup  r@ 1+ c@  r@ c@ 4 rshift h# f and  test-fll-signal
      1+      r@ 2+ c@  r@ c@          h# f and  test-fll-signal
      r> drop ( )
   loop
;

: test-fll
   ." Forced LED Levels" cr
   4sp ." X Axis" cr  0 test-fll-axis
   4sp ." Y Axis" cr  1 test-fll-axis
;
[then]



[ifdef] nn-watch \ graphical signal tests


d# 30 value r \ size of blocks
d# 1200 2/ r 2/ - value yx \ the y axis' stable x coordinate
d#  900 2/ r 2/ - value xy \ the x axis' stable y coordinate

: bigdot  ( x y -- )
   pixcolor @  -rot   r r                   ( color x y w h )
   fill-rectangle-noff                      ( )
;

: >grey  ( level -- colour )  dup dup rgb>565  ;

: >pseudo  ( level -- colour )  \ a red-yellow-green pseudocolour bar
   d# 256 over -  2*  d# 255 min  swap  2*  d# 255 min  0  rgb>565
;

defer level>rgb
' >pseudo is level>rgb

: ys>xy  ( signal# -- x y )
   yx swap                              ( x signal# )
   screen-h yleds 2* / *                ( x y )
   r 2/ +                               ( x y )
;

: xs>xy  ( signal# -- x y )
   screen-w xleds 2* / *                ( x )
   r 2/ +
   x>x'                                 ( x' )
   d# 10 -
   xy                                   ( x y )
;

: big>little  ( x y -- x' y' )
   r 2/ + 3 -  swap
   r 2/ + 2 -  swap
;

0 value axis#

: draw-signal  ( signal# level -- x y )
   level>rgb pixcolor !                 ( signal# )
   axis# if                             ( signal# ) \ y
      ys>xy
   else                                 ( signal# ) \ x
      xs>xy
   then                                 ( x y  )
   2dup bigdot                          ( x y  )
;

: ?draw-fail  ( x y flag? -- )
   if                                   ( x y )
      white pixcolor !                  ( x y )
      big>little                        ( x' y' )
      dot                               ( )
   else
      2drop
   then                                 ( )
;


: watch-fll-signal  ( signal# signal-value led-level -- )
   >r                                   ( signal# signal-value  r: led-level )
   draw-signal                          ( x y  r: led-level )
   r>                                   ( x y led-level )
   h# c > ?draw-fail                    ( )
;

: watch-fll-axis  ( axis# -- )
   dup to axis#                         ( axis# )
   (fll)
   pbuf 4 + c@  2/  0  do
      i pbuf 5 + over 3 * + >r          ( i r:frag )
      2* dup  r@ 1+ c@  r@ c@ 4 rshift h# f and  watch-fll-signal
      1+      r@ 2+ c@  r@ c@          h# f and  watch-fll-signal
      r> drop                           ( )
   loop
;

: empty
   black 0 0 screen-w screen-h fill-rectangle-noff
;

: watch-fll
   empty
   begin
      0 watch-fll-axis
      1 watch-fll-axis  key?
   until
   key drop
   page
;



: watch-fss-signal  ( signal# level -- )
   dup >r                               ( signal# level  r: level )
   draw-signal                          ( x y  r: level )
   r>                                   ( x y level )
   1 < ?draw-fail                       ( )
;

d# 64 value fs \ fixed signal strength

: watch-fss-axis  ( axis# -- )
   dup to axis#                         ( axis# )
   fs swap h# 0f h# 03 h# ee  5 bytes-out
   h# 0f d# 200 anticipate
   pbuf 2+ c@ h# 0f = if
      pbuf 4 + c@ 0  do                 ( )
         i pbuf 5 + over + c@           ( signal# level )
         watch-fss-signal               ( )
      loop
   then
;

: watch-fss-sig  ( )
   d# 50 d# 18 at-xy ."  signal strength: " fs .d
   d# 50 d# 20 at-xy ."  d  down "
   d# 50 d# 21 at-xy ."  u  up   "
   d# 50 d# 22 at-xy ."  q  quit "
;

: watch-fss-key  ( stop-flag key -- stop-flag' )
   case
      h# 1b     of  drop true  endof
      [char] q  of  drop true  endof
      [char] u  of  fs 2* d# 64 min  to fs  watch-fss-sig  endof
      [char] d  of  fs 2/  d# 1 max  to fs  watch-fss-sig  endof
   endcase
;

: watch-fss
   watch-fss-sig  empty  watch-fss-sig  false
   begin					( stop-flag )
      0 watch-fss-axis
      1 watch-fss-axis  key?  if  key watch-fss-key  then
      dup
   until
   drop page
;

[then]



: press  ( line$ -- )
   type
   ." , press a key"
   key drop
   cr
;

: connect  " Connect IR PCB" press  ;
: disconnect  " Disconnect IR PCB" press  ;

: dump-events
   begin
      in?  if
         ." rx: "  pbuf plen  bounds  do
            i c@  2u.x  space
         loop  cr
      then
      key?
   until
   key drop
;

defer (ev)  ( x y -- )  \ touch event handler for tests
' noop to (ev)
0 value remaining
d# 30000 value test-timeout

: ev  ( handler -- )
   to (ev)
   get-msecs test-timeout +                     ( to )
   begin
      in?  if
         pbuf 2+ c@  h# 04 =  if                \ touch notification event
            pbuf 3 + c@  0 do                   \ per subpacket loop
               pbuf 4 + i 9 * + >r              (       r:addr )
               r@ w@ x>x'                       ( x     r:addr )
               r@ wa1+ w@                       ( x y   r:addr )
               r> 4 + c@                        ( x y id-state         )
               dup 2 rshift setcolor            ( x y id-state         )
               3 and 2 <> if                    ( x y )
                  (ev)                          ( ) \ not an up event
               else
                  2drop                         ( ) \ an up event
               then
            loop
         then
      then                                      ( to )
      dup get-msecs -  0<                       ( to timeout? )
      dup  if  fault  then                      ( to timeout? )
      key?  dup  if  key drop  then             ( to timeout? key? )
      or remaining 0=  or                       ( to exit? )
   until drop                                   ( )
;

: ev(
   configure
   cursor-off
   consume
   flush
   background
   -1 to remaining
;

: )ev
   cursor-on
   page
   ['] (.tsmsg) to .tsmsg
;


: scribble
   ev(  ['] dot  ev  )ev
;


0 value dx
0 value dy

xleds 1+ yleds 1+ *  constant /boxen
create boxen  /boxen  allot  \ non-zero means box is expected to be hit

: 0boxen  ( -- )  boxen /boxen erase  ;
: >boxen  ( bx by -- addr )  xleds * +  boxen +  ;

: dxdy  ( xleds yleds -- )
   0boxen
   screen-h swap / to dy
   screen-w swap / to dx
   0 to remaining
;

: bxby>xy  ( bx by -- x y )
   swap dx * swap dy *
;

: xy>bxby  ( x y -- bx by )
   swap dx / swap dy /
;

: box  ( bx by colour -- )
   -rot                                 ( colour bx by )
   bxby>xy                              ( colour x y )
   dx dy                                ( colour x y w h )
   fill-rectangle-noff
;

: hit  ( bx by -- )
   2dup >boxen dup c@  if               ( bx by >boxen )
      0 swap c!                         ( bx by )
      remaining 1- to remaining         ( bx by )
      green box                         ( )
   else                                 ( bx by >boxen )
      drop 2drop                        ( )
   then                                 ( )
;

: unhit  ( bx by -- )
   remaining 1+ to remaining
   2dup >boxen 1 swap c!                ( bx by )
   red box                              ( )
;

: unhit-all  ( -- )
   xleds 0 do
      yleds 0 do
         j i unhit
      loop
   loop
;

: prep
   xleds yleds dxdy
   unhit-all
;

: hit-xy  ( x y -- )
   screen-h mod swap screen-w mod swap  \ coerce stupid coordinates seen
   xy>bxby hit
;

: boxes
   ev(  prep  ['] hit-xy  ev  )ev
;


: .ta  ( -- )  d# 32 d#  4 at-xy  ."  Top Axis Test  " cr  ;
: .ba  ( -- )  d# 32 d# 25 at-xy  ."  Bottom Axis Test " cr  ;
: .la  ( -- )  d#  8 d# 14 at-xy  ."  Left Axis Test " cr  ;
: .ra  ( -- )  d# 55 d# 14 at-xy  ."  Right Axis Test " cr  ;

: ta0  ( -- )  xleds yleds dxdy     xleds 0     do  i 0         unhit  loop  ;
: ba0  ( -- )  xleds 1+ yleds dxdy  xleds 1+ 0  do  i yleds 1-  unhit  loop  ;
: la0  ( -- )  xleds yleds dxdy     yleds 0     do  0 i         unhit  loop  ;
: ra0  ( -- )  xleds yleds 1+ dxdy  yleds 1+ 0  do  xleds 1- i  unhit  loop  ;

: (ta)  ( x y -- )  dup  dy >=             if  2drop exit  then  hit-xy  ;
: (ba)  ( x y -- )  dup  screen-h dy - <=  if  2drop exit  then  hit-xy  ;
: (la)  ( x y -- )  over dx >=             if  2drop exit  then  hit-xy  ;
: (ra)  ( x y -- )  over screen-w dx - <=  if  2drop exit  then  hit-xy  ;

\ translate a premature keyboard exit into a fault
: r-fault?  ( -- )  remaining  if  fault  then  ;

: ta  ['] .ta to .tsmsg  ev(  ta0  ['] (ta) ev  )ev  r-fault?  ;
: ba  ['] .ba to .tsmsg  ev(  ba0  ['] (ba) ev  )ev  r-fault?  ;
: la  ['] .la to .tsmsg  ev(  la0  ['] (la) ev  )ev  r-fault?  ;
: ra  ['] .ra to .tsmsg  ev(  ra0  ['] (ra) ev  )ev  r-fault?  ;

: test-adjacent-axes
   get-msecs 7 and  \ pick random corner
   case
      0  of  ta ra  exit  endof
      1  of  ra ba  exit  endof
      2  of  ba la  exit  endof
      3  of  la ta  exit  endof
      4  of  ra ta  exit  endof
      5  of  ba ra  exit  endof
      6  of  la ba  exit  endof
      7  of  ta la  exit  endof
   endcase
;


: (lg-tooling)  test-os  test-fll  ;

: lg-tooling  ( -- error? )
   open  if
      ['] (lg-tooling)  catch  ?dup  if  .error  fault  then
   else
      fault
   then
   faults
   close
;

: ir-pcb-smt  ( -- error? )
   hold-reset  connect
   open  if
      ['] test-os catch  ?dup  if  .error  fault  then
   else
      fault
   then
   close
   hold-reset  disconnect
   faults
;

: ir-pcb-assy  ( -- error? )
   hold-reset  connect
   open  if
      ['] test-fll  catch  ?dup  if  .error  fault  then
      faults 0=  if
         ['] test-adjacent-axes  catch  ?dup  if  .error  fault  then
      then
   else
      fault
   then
   close
   hold-reset  disconnect
   faults
;

: mb-smt  ( -- error? )
   open  0=  if  true exit  then
   ['] show-version  catch  ?dup  if  .error  fault  then
   close
   faults
;

: mb-assy  ( -- error? )
   open  0=  if true exit  then
   ['] test-adjacent-axes  catch  ?dup  if  .error fault  then
   close
   faults
;

: selftest  ( -- error? )
   absent?  if  ." No touchscreen expected" cr  false exit  then

   0 to faults

   test-station case
      h#  1  of  mb-smt  exit  endof
      h#  2  of  mb-assy  exit  endof
      h#  4  of  mb-assy  exit  endof
      h# 11  of  ir-pcb-smt  exit  endof
      h# 12  of  ir-pcb-assy  exit  endof
      h# 13  of  lg-tooling  exit  endof
   endcase

   \ MB FINAL
   \ MB SHIP
   ['] open  catch  ?dup  if
      .error
      ." No touchscreen present" cr  false exit
   then                         ( okay? )
   0=  if  false exit  then

   diagnostic-mode?  if
      0 to faults
      show-version
      [ifdef] nn-os       test-os       [then]
      [ifdef] nn-fss      test-fss      [then]
      [ifdef] nn-fll      test-fll      [then]
      faults  if  close  true  exit  then
   then

   ['] test-response  guarded
   test-station 6 =  if  d# 86400.000 to test-timeout  then
   ['] scribble  guarded

   close false
;

finish-device
device-end

: test-touchscreen  ( -- error? )
   " /touchscreen" " selftest" execute-device-method if
      throw
   then
;

: test-pass-or-fail  ( function -- error? )
   catch  if
      show-fail  true
   else
      show-pass  false
   then
;

\ touch screen (test by) test station
: tsts  ( test-station -- error? )
   test-station  swap to test-station                   ( test-station )
   ['] test-touchscreen test-pass-or-fail               ( test-station error? )
   swap  to test-station                                ( error? )
;

: test-ir-pcb-assy  ( -- error? )  h# 12 tsts  ;
: test-lightguide   ( -- error? )  h# 13 tsts  ;

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
