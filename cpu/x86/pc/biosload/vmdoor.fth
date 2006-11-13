\ See license at end of file
purpose: Forth functions duplicating the vmware toolbox functions

\ See http://chitchat.tripod.co.jp/vmware/backdoor.html for documentation

code vmdoor  ( param cmd -- ax bx cx dx )
   h# 564D5868 # ax mov		\ Magic Number
   cx pop			\ BACKDOOR_COMMAND_NUMBER
   bx pop			\ COMMAND_SPECIFIC_PARAMETER
   h# 5658 # dx mov		\ Port Number
   dx ax in
   ax push  bx push   cx push  dx push
c;

: get-mouse  ( -- x y )  0 4 vmdoor 3drop lwsplit swap  ;
: set-mouse  ( x y -- )  swap wljoin 5 vmdoor  4drop  ;

: vm-clip-len  ( -- len )  0 6 vmdoor  3drop  ;
: vm-get-clip  ( adr len -- )  bounds  ?do  0 7 vmdoor 3drop  i !  4 +loop  ;

: vm-set-clip  ( adr len -- )
   dup 8 vmdoor 4drop      ( adr len )  \ Declare length
   bounds  ?do  i @ 9 vmdoor 4drop  4 +loop
;

: vm-version  ( -- false | minor major true )
   0 h# a vmdoor drop swap
   h# 564d5868 =  if  swap true  else  2drop false  then
;

d# 40 buffer: vm-info-buf
: vm-devinfo  ( dev# -- adr len connected? )
   d# 40 0 do   ( dev# )
      i over wljoin h# b vmdoor 2drop swap 0= abort" No device"
      vm-info-buf i + l!
   4 +loop
   drop
   vm-info-buf cscount  vm-info-buf d# 36 + @
;

: vm-disconnect ( dev# -- okay? )  h# c vmdoor 3drop  ;
: vm-connect    ( dev# -- okay? )  h# 8000 wljoin vm-disconnect  ;

\ 01:grab on enter  02:ungrab on exit  04:scroll near edge
\ 10:host copy/paste 40:fullscreen  80:enter fullscreen mode
\ 400:time synchronization
: vm-getpref ( -- bitmask )  0 h# d vmdoor 3drop  ;
: vm-setpref ( bitmask -- )  h# e vmdoor 4drop  ;
: vm-screen  ( -- x y )  0 h# f vmdoor 3drop lwsplit swap  ;
: vm-config  ( -- mem-mb )  0 h# 14 vmdoor 3drop  ;
: vm-time    ( -- sec usec tz )  0 h# 17 vmdoor nip  ;
\ LICENSE_BEGIN
\ Copyright (c) 2006 FirmWorks
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
