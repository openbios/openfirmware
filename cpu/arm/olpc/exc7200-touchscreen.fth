\ See license at end of file
purpose: Driver and diagnostic for EETI EXC7200 Multitouch I2C Touchscreen

0 0  " 4,8"  " /twsi" begin-package
my-space encode-int  my-address encode-int encode+  " reg" property

\ XXX these are really platform-related, not touchscreen-related
: targets?  ( -- flag )  true  ;  \ Used to be "final-test?"
: .tsmsg  ( -- )  0 d# 27 at-xy  ." Touchscreen test.  Hit both targets to exit" cr  ;

fload ${BP}/cpu/arm/olpc/touchscreen-common.fth

h# 7fff to touchscreen-max-x
h# 7fff to touchscreen-max-y

2 to #contacts

\ Try to receive a mouse report packet.  If one arrives within
\ 20 milliseconds, return true and the decoded information.
\ Otherwise return false.
: pad?  ( -- false | x y z down? contact# true )
   d# 99 gpio-pin@  if  false exit  then
   d# 10 " get" $call-parent    ( 4 flags xlo xhi ylo yhi zlo zhi 0 0 )
   2drop bwjoin >r  bwjoin >r  bwjoin >r   ( 4 flags  r: z y x )
   swap  4 <>  if                          ( flags  r: z y x )
      r> r> r> 4drop false   exit          ( -- false )
   then
   dup h# 82 and  h# 82 <>  if             ( flags  r: z y x )
      r> r> r> 4drop false   exit          ( -- false )
   then                                    ( flags  r: z y x )

   r> r> scale-xy                          ( flags  x' y'  r: z )

   r> 3 roll                               ( x y z flags )
   dup 1 and 0<>                           ( x y z flags down? )
   swap 2 rshift  h# 1f and                ( x y z down? contact# )
   true                                    ( x y z down? contact# true )
;
: stream-poll?  ( -- false | x y buttons true )
   pad?  if               ( x y z down? contact# )
      0=  if              ( x y z down? )
	 nip 1 and  true  ( x y buttons true )
      else                ( x y z down? )
         4drop false      ( false )
      then                ( false | x y buttons true )
   else                   ( )
      false               ( false )
   then                   ( false | x y buttons true )
;

\ Display raw data from the device, stopping when a key is typed.
: show-pad  ( -- )
   begin
      pad?  if  . . . . . cr  then
   key? until
;

: track  ( x y z down? contact# -- )
   setcolor                       ( x y z down? )
   0=  if                         ( x y z )
      3drop  undot  exit          ( -- )
   then                           ( x y z )
   to pressure                    ( x y )

\    dup 5 and 5 =  if  background  load-base ptr !  then

   targets?  if                   ( x y )
      ?hit-target                 ( x y )
   then                           ( x y )

   dot
;
: touchscreen-present?  ( -- flag )
   d# 10 " get" ['] $call-parent catch  if   ( x x x )
      3drop false
   else                ( n n n n n n n n n n )
      4drop 4drop 2drop true
   then
;

: flush  ( -- )  begin  d# 10 ms  pad?  while  2drop 3drop  repeat  ;

: open  ( -- okay? )
   my-unit " set-address" $call-parent  true
   \ Read once to prime the interrupt
   d# 10 " get" $call-parent  4drop 4drop 2drop

   set-geometry

   flush
;

: close  ( -- )  flush  ;

: selftest  ( -- error? )
   open  0=  if
      ." Touchscreen open failed"  true exit
   then

   touchscreen-present?  0=  if
      ." Touchscreen doesn't respond"  true exit
   then

   \ Being able to open the touchpad is good enough in SMT mode
   smt-test?  if  close false exit  then

   targets? 0=  if
      ." Touchscreen test will start in 4 seconds" cr
      d# 4000 ms
   then

   cursor-off

   \ Consume already-queued keys to prevent premature exit
   begin  key?  while  key drop  repeat

   \ Consume already-queued trackpad events to prevent premature exit
   flush

   background
   begin
      ['] pad? catch  ?dup  if  .error  close true exit  then
      if  track  then
   exit-test?  until

   flush

   close
   cursor-on
   page
   targets?  if  selftest-failed?  else  false  then
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
