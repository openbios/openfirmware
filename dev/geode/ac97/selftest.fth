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
   dup 0>  abort" Playback only does attenuation - use a negative number"
   negate  1+ 2* 3 /  dup bwjoin  to plevel
;

: play  ( -- )
   open-out  plevel set-pcm-gain  0 h# 38 codec!
   record-base  record-len  audio-out drop  write-done
;

0 value wave
: wave++  ( -- wave )  wave 4 + dup 3f and 0= if negate then dup to wave  ;
: make-wave  ( -- )  record-base record-len bounds do wave++ dup wljoin i l! 4 +loop  ;
: selftest  ( -- error? )
   open 0=  if  ." Failed to open /audio" cr true exit  then
   record-len alloc-mem to record-base
   ." Play tone" cr
   make-wave play
   ." Record and playback" cr
   record play
   record-base record-len free-mem
   close false
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
