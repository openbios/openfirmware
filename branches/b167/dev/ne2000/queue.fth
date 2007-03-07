\ See license at end of file
purpose: Packet queue routines

\ Maintain a linked list of packets that were received while transmitting.

\ Since the firmware mostly uses request/response protocols, the expected
\ queue length is either 0 or 1.  However, since the queue is stored as a
\ linked list with dynamically allocated and freed entries, it costs very
\ little to make the maximum size rather large.

d# 32 constant max#queued	\ Toss old packets after this number

variable rx-queue
0 value #queued

struct  \ Queue entry
/n field >link
/n field >length
 0 field >data
constant /q-header

: init-queue  ( -- )  0 to #queued  0 rx-queue !  ;

\ Do not execute this is #queued is 0
: deque-oldest  ( -- handle )
   0  rx-queue                      ( prev this )
   begin  dup >link @  dup  while   ( prev this next )
      rot drop                      ( prev' this' )
   repeat                           ( prev-handle oldest-handle 0 )
   rot >link !                      ( oldest-handle )
   #queued 1- to #queued
;

: release-buffer  ( handle -- )  dup  >length @  /q-header +  free-mem  ;

: drain-queue  ( -- )
   #queued  0  ?do  deque-oldest release-buffer  loop
;

: new-buffer  ( packet-length -- handle adr len )
   #queued max#queued >=  if  deque-oldest release-buffer  then
   
   dup /q-header + alloc-mem       ( packet-length handle )
   2dup >length !                  ( packet-length handle )
   dup >data rot                   ( handle adr len )
;

: enque-buffer  ( handle -- )
   rx-queue @  over >link !  rx-queue !
   #queued 1+ to #queued
;

: ?return-queued  ( adr len -- adr len false  |  actual true )
   #queued  0=  if  false exit  then
   deque-oldest  >r                     ( adr len r: handle )
   r@ >length @  min                    ( adr actual r: handle )
   tuck  r@ >data -rot move             ( actual r: handle )
   r> release-buffer                    ( actual )
   true
;
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
