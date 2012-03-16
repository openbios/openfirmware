\ See license at end of file
purpose: Driver and diagnostic for Raydium RM-3150 Multitouch I2C Touchscreen

0 0  " 4,60"  " /twsi" begin-package
my-space encode-int  my-address encode-int encode+  " reg" property

\ XXX these are really platform-related, not touchscreen-related
: targets?  ( -- flag )  final-test?  ;
: .tsmsg  ( -- )  0 d# 27 at-xy  ." Touchscreen test.  Type a key to exit" cr  ;

fload ${BP}/cpu/arm/olpc/touchscreen-common.fth

d# 896 to touchscreen-max-x
d# 672 to touchscreen-max-y

d# 10 to #contacts

: ts-b!  ( b reg# -- )  " smbus-b!" $call-parent  ;
: ts-b@  ( reg# -- b )  " smbus-b@" $call-parent  ;

: 4b>xy  ( x.hi x.lo  y.hi y.lo -- x y )  swap bwjoin >r  swap bwjoin r>  ;

: touchscreen-present?  ( -- flag )
   h# a ['] ts-b@ catch  if            ( x )   
      drop false exit                  ( -- false )
   then                                ( max-x.hi )
   \ It would be nice to read all four bytes in one SMBUS transaction,
   \ but that doesn't work for these register locations - the first
   \ one reads correctly, and subsequent ones read as 0.  You must
   \ read them individually to get the right answer.
   h# b ts-b@  h# c ts-b@  h# d ts-b@  ( max-x.hi max-x.lo max-y.hi max-y.lo )
   4b>xy                               ( max-x max-y )
   touchscreen-max-y =                 ( max-y flag )
   swap touchscreen-max-x =  and       ( flag' )
;

: open  ( -- okay? )
   my-unit " set-address" $call-parent
   touchscreen-present?  dup  if   ( okay? )
      0 1 ts-b!                    ( okay? )  \ Set to polled mode
   then                            ( okay? )
   set-geometry
;

: touched?  ( -- flag )  d# 99 gpio-pin@ 0=  ;
: #touches  ( -- n )  h# 10 ts-b@   h# 7f and  ;

: pad-events  ( -- n*[ x.hi x.lo y.hi y.lo z ]  #touches )
   touched? 0=  if  false exit  then
   #touches >r  r@  if                                ( r: #touches )
      h# 11 1  r@ 5 *  " smbus-out-in" $call-parent   ( n*[ x.hi x.lo y.hi y.lo z ]  r: #touches )
   then                                               ( n*[ x.hi x.lo y.hi y.lo z ]  r: #touches )
   r>                                                 ( n*[ x.hi x.lo y.hi y.lo z ]  #touches )
;

: close  ( -- )
\   flush
   h# 82 1 ts-b!  \ Restore default interrupt mode
;

: track-n  ( .. xhi xlo yhi ylo z  #touches -- )
   ?dup 0=  if  exit  then     ( .. xhi xlo yhi ylo z  #touches -- )
   1-  0  swap  do             ( .. xhi xlo yhi ylo z )
      i setcolor               ( .. xhi xlo yhi ylo z )
      to pressure              ( .. xhi xlo yhi ylo )
      4b>xy  scale-xy          ( .. x y )

      targets?  if  ?hit-target   then     ( .. x y )

      dot
   -1 +loop
;

0 0 2value last-xy
false value last-down?
: no-touch  ( -- false | x y buttons true )
   last-down?  if
      \ Return up event for last "mouse" position
      false to last-down?
      last-xy 0 true
   else
      false
   then
;
: touch  ( -- false | x y buttons true )
   #touches  0=  if  false exit  then
   h# 11 1 4  " smbus-out-in" $call-parent   ( x.hi x.lo y.hi y.lo )
   4b>xy  scale-xy     ( x y )
   2dup to last-xy     ( x y )
   true to last-down?  ( x y )
   1 true              ( x y buttons true )
;
: stream-poll?  ( -- false | x y buttons true )
   touched?  if  touch  else  no-touch  then
;
: discard-n  ( .. #events -- )   5 *  0  ?do  drop  loop  ;

\ Needs 2 seconds of no-touch
: calibrate  ( -- )  h# 20 0 ts-b!  ;

: selftest  ( -- error? )
   open  0=  if
\     ." Touchscreen open failed"  true exit
      ." No touchscreen present" cr  false exit
   then

   \ Being able to open the touchpad is good enough in SMT mode
   smt-test?  if  close false exit  then

   calibrate   \ Needs 2 seconds of no-touch

   targets?  if
      ." Calibrating touchscreen" cr
      d# 2000 ms
   else
      ." Touchscreen test will start in 4 seconds" cr
      d# 4000 ms
   then

   cursor-off

   \ Consume already-queued keys to prevent premature exit
   begin  key?  while  key drop  repeat

   \ Consume already-queued trackpad events to prevent premature exit
   d# 100 0  do
      pad-events  ?dup  0=  if  leave  then  ( .. #events )
      discard-n                              ( )
   loop

   background
   begin
      ['] pad-events catch  ?dup  if  .error  close true exit  then
      track-n
   exit-test?  until

   close
   cursor-on
   page
   final-test?  if  selftest-failed?  else  false  then
;


end-package

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
