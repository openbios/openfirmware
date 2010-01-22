\ See license at end of file
purpose: Cross-covariance audio selftest

support-package: audio-test

code mono-covar  ( adr1 adr2 #samples -- d.sum )
   cx pop

   ax pop    \ adr2 in ax
   bx pop    \ adr1 in bx
   si push
   di push
   bp push

   ax si mov
   bx di mov

   bp bp xor   \ Zero accumulator
   bx bx xor

   begin
      op: ax lods
      cwde
      ax dx mov
      op: 0 [di] ax mov
      2 [di]  di  lea
      cwde
      dx imul
      ax bx add
      dx bp adc
   loopa

   bp ax mov

   bp pop
   di pop
   si pop

   bx push
   ax push
c;
code stereo-mono-covar  ( stereo-adr1 stereo-adr2 #samples -- d.sum )
   cx pop

   ax pop    \ adr2 in ax
   bx pop    \ adr1 in bx
   si push
   di push
   bp push

   ax si mov
   bx di mov

   bp bp xor   \ Zero accumulator
   bx bx xor

   begin
      op: ax lods
      cwde
      ax dx mov
      op: 0 [di] ax mov
      4 [di]  di  lea    \ Skip 2 samples for stereo
      cwde
      dx imul
      ax bx add
      dx bp adc
   loopa

   bp ax mov

   bp pop
   di pop
   si pop

   bx push
   ax push
c;
code stereo-covar  ( stereo-adr1 stereo-adr2 #samples -- d.sum )
   cx pop

   ax pop    \ adr2 in ax
   bx pop    \ adr1 in bx
   si push
   di push
   bp push

   ax si mov
   bx di mov

   bp bp xor   \ Zero accumulator
   bx bx xor

   begin
      op: ax lods
      2 [si]  si  lea    \ Skip other channel sample for stereo
      cwde
      ax dx mov
      op: 0 [di] ax mov
      4 [di]  di  lea    \ Skip 2 samples for stereo
      cwde
      dx imul
      ax bx add
      dx bp adc
   loopa

   bp ax mov

   bp pop
   di pop
   si pop

   bx push
   ax push
c;
code mono-wsum  ( adr len -- d.sum )
   cx pop

   ax pop    \ adr in ax
   si push
   bp push

   ax si mov

   bp bp xor   \ Zero accumulator
   bx bx xor

   begin
      op: ax lods
      cwde
      cwd        \ Actually cdq
      ax bx add
      dx bp adc
   loopa

   bp ax mov

   bp pop
   si pop

   bx push
   ax push
c;
code stereo-wsum  ( adr #samples -- d.sum )
   cx pop

   ax pop    \ adr in ax
   si push
   bp push

   ax si mov

   bp bp xor   \ Zero accumulator
   bx bx xor

   begin
      op: ax lods
      2 [si]  si  lea    \ Skip other channel sample for stereo
      cwde
      cwd        \ Actually cdq
      ax bx add
      dx bp adc
   loopa

   bp ax mov

   bp pop
   si pop

   bx push
   ax push
c;
: mono-wmean  ( adr len -- n )
   2/ tuck  mono-wsum         ( d.sum len )
   rot m/mod nip              ( mean )
;
: stereo-wmean  ( adr len -- n )
   2/ 2/ tuck  stereo-wsum         ( d.sum len )
   rot m/mod nip              ( mean )
;
: -mono-wmean  ( adr len -- )
   2dup mono-wmean    ( adr len mean )
   -rot  bounds  ?do  ( mean )
      i <w@ over - h# 7fff min  h# -7fff max  i w!
   /w +loop           ( mean )
   drop               ( )
;
: -stereo-wmean  ( adr len -- )
   2dup stereo-wmean  ( adr len mean )
   -rot  bounds  ?do  ( mean )
      i <w@ over - h# 7fff min  h# -7fff max  i w!
   /l +loop           ( mean )
   drop               ( )
;
: lose-6db  ( adr len -- )
   bounds  ?do            ( )
      i <w@  2/  i w!     ( )
   /w +loop               ( )
;

create testarr    100 0 do  0 w,  100 w,  loop

create testarr2   100 0 do  0 w,  -100 w,  loop

: .covar#  ( d.covar -- )
   push-decimal
   d# 1000000000 m/mod nip  8 .r
   pop-base
;
: .m-covar  ( adr1 adr2 len end-start -- )
   do
       i 3 u.r space    ( adr1 adr2 len )
       3dup swap i wa+ swap mono-covar  ( adr1 adr2 len d.covar )
       .covar# cr       ( adr1 adr2 len )
   loop                 ( adr1 adr2 len )
   3drop                ( )
;
: .sm-covar  ( adr1 adr2 len end start -- )
   do
      i 3 u.r space     ( adr1 adr2 len )
      3dup swap i wa+ swap stereo-mono-covar  ( adr1 adr2 len d.covar )
      .covar#  cr       ( adr1 adr2 len )
   loop                 ( adr1 adr2 len )
   3drop                ( )
;

0. 2value total-covar
: sm-covar-sum  ( adr1 adr2 len end start -- d.covar )
   0. to total-covar
   do
      3dup swap i wa+ swap stereo-mono-covar  ( adr1 adr2 len d.covar )
      total-covar d+  to total-covar          ( adr1 adr2 len )
   loop                 ( adr1 adr2 len )
   3drop                ( )
   total-covar
;
: sm-covar-abs-sum  ( adr1 adr2 len end start -- d.covar )
   0. to total-covar
   do
      3dup swap i wa+ swap stereo-mono-covar  ( adr1 adr2 len d.covar )
      dabs  total-covar d+  to total-covar    ( adr1 adr2 len )
   loop                 ( adr1 adr2 len )
   3drop                ( )
   total-covar
;

: ss-covar-abs-sum  ( adr1 adr2 len end start -- d.covar )
   0. to total-covar
   do
      3dup swap i la+ swap stereo-covar       ( adr1 adr2 len d.covar )
      dabs  total-covar d+  to total-covar    ( adr1 adr2 len )
   loop                 ( adr1 adr2 len )
   3drop                ( )
   total-covar
;


0 value max-index
0. 2value max-covar
: mono-covar-max  ( adr1 adr2 #samples max-dly min-dly -- index )
   -1 to max-index                     ( adr1 adr2 #samples max-dly min-dly )
   0. to max-covar                     ( adr1 adr2 #samples max-dly min-dly )

   do                                  ( adr1 adr2 #samples )
       3dup swap i wa+ swap mono-covar ( adr1 adr2 #samples d.covar )
       dabs                            ( adr1 adr2 #samples |d.covar| )
       max-covar 2over d<  if          ( adr1 adr2 #samples |d.covar| )
          to max-covar  i to max-index ( adr1 adr2 #samples )
       else                            ( adr1 adr2 #samples |d.covar| )
          2drop                        ( adr1 adr2 #samples )
       then                            ( adr1 adr2 #samples )
   loop                                ( adr1 adr2 #samples )
   3drop
   max-index
;
: stereo-mono-covar-max  ( adr1 adr2 #samples max-dly min-dly -- index )
   -1 to max-index                       ( adr1 adr2 #samples max-dly min-dly )
   0. to max-covar                       ( adr1 adr2 #samples max-dly min-dly )

   do                                    ( adr1 adr2 #samples )
       3dup swap i wa+ swap stereo-mono-covar ( adr1 adr2 #samples d.covar )
       dabs                              ( adr1 adr2 #samples |d.covar| )
       max-covar 2over d<  if            ( adr1 adr2 #samples |d.covar| )
          to max-covar  i to max-index   ( adr1 adr2 #samples )
       else                              ( adr1 adr2 #samples |d.covar| )
          2drop                          ( adr1 adr2 #samples )
       then                              ( adr1 adr2 #samples )
   loop                                  ( adr1 adr2 #samples )
   3drop
   max-index
;
: mono-variance  ( adr len -- d.variance )
   >r  dup  r> 2/  mono-covar
;
: left-variance  ( adr len -- d.variance )
   >r  dup  r> 2/ 2/ stereo-covar
;
: right-variance  ( adr len -- d.variance )
   >r  wa1+ dup  r> 2/ 2/ stereo-covar
;

h# 40000 value /pb  \ Stereo - 10000 is okay for fixture, 40000 is better for case, 
: pb  load-base  ;
h# 21000 value /rb  \ Mono (stereo for loopback)  - 8100 for fixture, 21000 for case, 
: rb  load-base  1meg +  ;

: d..  ( -- )  <# # # # # ascii . hold # # # # ascii . hold #s #> type space  ;
: find-max-mono  ( -- )
   pb        rb   /pb 2 / h# 100 -  d# 160 d# 120  mono-covar-max .d   max-covar d..
;
: find-max-left  ( -- )
   pb       rb   /pb 4 / h# 100 -   d# 160 d# 120  stereo-mono-covar-max .d  max-covar d..
;
: find-max-right  ( -- )
   pb wa1+  rb   /pb 4 / h# 100 -   d# 160 d# 120  stereo-mono-covar-max .d  max-covar d..
;

: #samples  ( -- n )  /pb 4 / h# 100 -  ;
: left-range   ( -- stereo-adr mono-adr #points )  pb      rb  #samples  ;
: right-range  ( -- stereo-adr mono-adr #points )  pb wa1+ rb  #samples  ;
: left-stereo-range   ( -- stereo-adr mono-adr #points )  pb      rb        #samples  ;
: right-stereo-range  ( -- stereo-adr mono-adr #points )  pb wa1+ rb  wa1+  #samples  ;

: fixture-analyze-left  ( -- )
   left-range  d# 146 d# 141 sm-covar-sum  dnegate
   left-range  d# 165 d# 155 sm-covar-sum          d+
   left-range  d# 190 d# 180 sm-covar-sum  dnegate d+
   .covar#
;
: fixture-analyze-right  ( -- )
   right-range  d# 146 d# 141 sm-covar-sum  dnegate
   right-range  d# 165 d# 155 sm-covar-sum          d+
   right-range  d# 190 d# 180 sm-covar-sum  dnegate d+
   .covar#
;

0 value debug?
: >ratio  ( sum1 sum2 -- ratio*10 )
   debug?  if  over .d dup .d ." : "  then
   1 max  d# 10  swap */
   debug?  if  dup .d cr  then
;
\ Reasonable threshold is d# 25
: fixture-ratio-left  ( -- error? )
   left-range  d# 240 d# 140 sm-covar-abs-sum nip  ( sum1 ) 
   left-range  d# 400 d# 300 sm-covar-abs-sum nip  ( sum1 sum2 )
   >ratio
   d# 25 <
;
: fixture-ratio-right  ( -- error? )
   right-range  d# 240 d# 140 sm-covar-abs-sum nip  ( sum1 ) 
   right-range  d# 400 d# 300 sm-covar-abs-sum nip  ( sum1 sum2 )
   >ratio
   d# 25 <
;

\ This compares the total energy within the impulse response band to the
\ total energy in a similar-length band 
: case-ratio-left  ( -- error? )
   left-range  d# 200 d# 140 sm-covar-abs-sum  nip ( sum1.high )
   left-range  d# 540 d# 400 sm-covar-abs-sum  nip ( sum1.high sum2.high )
   >ratio
   d# 30 <
;
: case-ratio-right  ( -- error? )
   right-range  d# 330 d# 140 sm-covar-abs-sum  nip ( sum1.high )
   right-range  d# 590 d# 400 sm-covar-abs-sum  nip ( sum1.high sum2.high )
   >ratio
   d# 15 <
;

\ This compares the total energy within the impulse response band to the
\ total energy in a similar-length band 
: loopback-ratio-left  ( -- error? )
   left-stereo-range  d# 148 d# 128 ss-covar-abs-sum  nip ( sum1.high )
   left-stereo-range  d# 220 d# 200 ss-covar-abs-sum  nip ( sum1.high sum2.high )
   >ratio
   d# 70 <
;
: loopback-ratio-right  ( -- error? )
   right-stereo-range  d# 148 d# 128 ss-covar-abs-sum  nip ( sum1.high )
   right-stereo-range  d# 220 d# 200 ss-covar-abs-sum  nip ( sum1.high sum2.high )
   >ratio
   d# 70 <
;

d# 1024 /w* buffer: impulse-response

: calc-sm-impulse  ( offset -- )  \ offset is 0 for left or 2 for right
   pb +  rb  #samples                         ( adr1 adr2 #samples )
   d# 1024 0  do
      3dup swap i wa+ swap stereo-mono-covar  ( adr1 adr2 #samples d.covar )
      d# 50000000 m/mod nip                   ( adr1 adr2 #samples n.covar )
      impulse-response i wa+ w!               ( adr1 adr2 #samples )
   loop                 ( adr1 adr2 len )
   3drop                ( )
;
: .samples  ( adr end start -- )
   do
      i push-decimal 3 u.r pop-base                  ( adr )
      dup i wa+ <w@  push-decimal 8 .r pop-base  cr  ( adr )
   loop                                              ( adr )
   drop
;
d# -23 value test-volume   \ d# -23 for test fixture, d# -9 for in-case
defer analyze-left
defer analyze-right
defer fix-dc

: prepare-signal  ( -- out-adr, len in-adr,len )
   pb /pb bounds  do  random-byte  i c!  loop
   pb      /pb -stereo-wmean
   pb wa1+ /pb -stereo-wmean
   pb /pb lose-6db
   pb /pb  rb /rb
   disable-interrupts
;
: analyze-signal  ( -- error? )
   enable-interrupts
   rb /rb fix-dc
   false                        ( error? )
   analyze-left  if             ( error? )
      ." Left channel failure" cr
      1+
   then

   analyze-right  if
      ." Right channel failure" cr
      2+
   then
;

: setup-fixture  ( -- )
   h# 20000 to /pb          \ Medium burst
   /pb 2/ h# 1000 + to /rb  \ Mono reception (internal mic)
\   ['] fixture-analyze-left  to analyze-left
\   ['] fixture-analyze-right to analyze-right
   ['] fixture-ratio-left  to analyze-left
   ['] fixture-ratio-right to analyze-right
   ['] -mono-wmean to fix-dc
;
: setup-case  ( -- )
\   xxx - this needs to use the internal speakers and mic even though the loopback cable is attached
   h# 40000 to /pb          \ Long burst for better S/N on far away speaker
   /pb 2/ h# 1000 + to /rb  \ Mono reception (internal mic)
   ['] case-ratio-left  to analyze-left
   ['] case-ratio-right to analyze-right
   ['] -mono-wmean to fix-dc
;
: setup-loopback  ( -- )
   h# 10000 to /pb          \ Short burst
   /pb h# 1000 + to /rb     \ Stereo reception
   ['] loopback-ratio-left  to analyze-left
   ['] loopback-ratio-right to analyze-right
   ['] -stereo-wmean to fix-dc
;
: open  ( -- okay? )  true  ;
: close  ( -- )  ;
end-support-package

0 [if]
: make-tone2  ( freq -- )
   sample-rate to fs  ( freq )  set-freq

   \ Start with everything quiet
   record-base record-len erase

   record-base  make-cycle  drop

   \ Duplicate left into right
   record-base  #cycle /l*  bounds  ?do  i w@  i wa1+ w!  /l +loop

   \ Replicate the wave template
   record-base /cycle +   record-len /cycle -  bounds  ?do
      record-base  i  /cycle  move
   /cycle +loop
;
: freqtest  ( frequency -- )
   open-in  48kHz  16bit mono    with-adc d# 73 input-gain
   \ -23 prevents obvious visible clipping
   open-out 48kHz  16bit stereo  d# -23 set-volume

   pb to record-base  /pb to record-len
   make-tone2

   lock[  \ Prevent timing jitter due to interrupts
   pb /pb   rb /rb out-in
   ]unlock
   rb waveform
;
[then]

\ LICENSE_BEGIN
\ Copyright (c) 2010 FirmWorks
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
