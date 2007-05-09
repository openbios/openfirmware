purpose: Diagnostics for AC97 Driver for Geode CS5536 companion chip
\ See license at end of file

0 value record-base
h# 80000 value record-len

0 value mic-boost?
h# 808 value rlevel
: set-rlevel  ( db -- )
   dup d# 20 >=  if  d# 20 -  true  else  false then  ( db' boost? )
   to mic-boost?                                       ( db )
   h# 22 min  1+ 2* 3 /  dup bwjoin  to rlevel
;

: establish-level  ( -- )
   mic-boost?   if  mic+20db  else  mic+0db  then
   rlevel set-record-gain
   d# 250 ms    \ Settling time for DC offset filter
;

: record  ( -- )
   open-in  establish-level
   record-base  record-len  audio-in drop
;

h# 0 value plevel
: set-plevel  ( db -- )
   dup 0>  if  drop 0  then
   negate  1+ 2* 3 /  dup bwjoin  to plevel
;

h# 0 value glevel
: set-glevel  ( db -- )
   dup 0>  if  drop 0  then
   negate  1+ 2* 3 /  dup bwjoin  to glevel
;

: play  ( -- )
   open-out  plevel set-pcm-gain  glevel h# 38 codec!
   record-base  record-len  audio-out drop  write-done
;

create sin-half
d#     0 w,
d#  3212 w,
d#  6393 w,
d#  9512 w,
d# 12539 w,
d# 15446 w,
d# 18204 w,
d# 20787 w,
d# 23170 w,
d# 25329 w,
d# 27245 w,
d# 28898 w,
d# 30273 w,
d# 31356 w,
d# 32137 w,
d# 32609 w,
d# 32767 w,
d# 32609 w,
d# 32137 w,
d# 31356 w,
d# 30273 w,
d# 28898 w,
d# 27245 w,
d# 25329 w,
d# 23170 w,
d# 20787 w,
d# 18204 w,
d# 15446 w,
d# 12539 w,
d# 9512 w,
d# 6393 w,
d# 3212 w,



0 value wave
: wave++  ( -- wave )
   wave h# 800 + dup h# 7fff and 0= if negate then dup to wave
;
: cycle  ( adr -- adr' )
   d# 32  0  do                   ( adr )
      sin-half i wa+ w@  over w!  ( adr value )
      la1+                        ( adr' )
   loop                           ( adr )
   d# 32  0  do                   ( adr )
      sin-half i wa+ w@ negate  over w!   ( adr value )
      la1+                        ( adr' )
   loop                           ( adr' )
;

: make-wave  ( -- )
   record-base record-len 2/  bounds      ( endadr startadr )
   begin  2dup u>  while  cycle  repeat   ( endadr startadr )
   2drop

   record-base record-len bounds          ( endadr startadr )
   record-len 2/ + wa1+
   begin  2dup u>  while  cycle  repeat   ( endadr startadr )
   2drop
;

0 value raw-buf
0 value /raw-buf

: selftest-args  ( -- arg$ )  my-args ascii : left-parse-string 2drop  ;

: ?play-wav-file  ( -- )
   selftest-args dup 0=  if  2drop exit  then
   " $play-wav-loop" $find 0=  if  2drop  else  catch drop  then
;

: selftest  ( -- error? )
   open 0=  if  ." Failed to open /audio" cr true exit  then
   0 set-plevel  0 set-glevel
   ?play-wav-file
   record-len alloc-mem to record-base
   ." Play tone" cr
   0 set-plevel  d# -12 set-glevel
   make-wave play
   ." Recording ..." cr
   0 set-plevel  0 set-glevel
   record
   ." Playing ..." cr
   play
   record-base record-len free-mem
   close false
;

\ LICENSE_BEGIN
\ Copyright (c) 2007 FirmWorks
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
