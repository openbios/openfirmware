purpose: Interval timing functions
\ See license at end of file

headerless
code 601?  ( -- flag )
   stwu   tos,-1cell(sp)
   mfspr  tos,pvr
   rlwinm tos,tos,16,16,31
   cmpi   0,0,tos,1
   =  if
      set tos,-1
   else
      set tos,0
   then
c;

\ 604  TB is incremented at 1/4 the speed of the system bus.
\ at 40Mhz sysclk, there are 10000 counts/ms.
\ at 50Mhz sysclk, there are 12500 counts/ms.
\ default: 50Mhz
\ d#  8250 value counts/ms   \ For a 603 with a 33 MHz bus clock
\ d# 10000 value counts/ms   \ For a 604 with a 40 MHz bus clock
\ d# 12500 value counts/ms   \ For a 604 with a 50 MHz bus clock
\ d# 16500 value counts/ms   \ For a 604 with a 66 MHz bus clock

headers
d# 8250 value counts/ms   \ For a 603 with a 33 MHz bus clock

headerless
\ XXX Put in the actual ratios when IBM gets around to documenting
\ the encoding of the bus ratio field
\ create 620-ratios  ? c,  ? c,  ? c,  ? c,
: bus-ratio  ( -- n )
   620-class?  if
\      buscsr@ d# 22 2 bits 620-ratios + c@
      1          \ Temporary value
   else
      4
   then
;
headers
\ We want "microseconds" to have a range of at least 1 second
\ (1,000,000 microseconds) and as good a precision as possible
\ given that constraint.  We do this by choosing multiplier and
\ divisor values accordingly.
0 value us-multiplier
0 value us-divisor
: calibrate-microseconds  ( -- )
   \ The starting multiplier is counts/ms and the starting divisor is
   \ 1000 (microseconds/millisecond).  We can eliminate common factors
   \ without introducing inaccuracy, so we go ahead and do that.  The
   \ factors of 1000 are 2x2x2x5x5x5.

   d# 1000 counts/ms  ( denominator numerator )

   \ Remove powers of two
   begin  2dup or  1 and 0=  while  swap 2/ swap 2/  repeat  ( den' num' )

   \ Remove powers of 5
   begin                                    ( den num )
      over 5 mod 0=  over 5 mod 0=  and     ( den num flag )
   while                                    ( den num )
      swap 5 /  swap 5 /                    ( den' num' )
   repeat                                   ( den num )

   \ At this point, if the numerator is still too large (unlikely),
   \ we divide the numerator by the denominator and accept the loss
   \ in precision.
   dup d# 4294 >  if                        ( den num )
      swap /  1 swap                        ( 1 num' )
   then                

   \ If the numerator is *still* too large, we just live with the
   \ loss in range.  We could do something like use 64-bit arithmetic
   \ or loop over several calls to the low-level primitive, but we will
   \ cross that bridge when we get to it (it won't happen until we see
   \ a processor with a timebase tick rate of > 4K ticks/microsecond;
   \ the timebase rate is typically scaled down considerably from the
   \ instruction rate).
   to us-multiplier     to us-divisor
;

\ The 601 increments the RTC register pair and decrements the
\ decrementer register by 128 counts every 128 nsec, thus their
\ count values represent nanoseconds.  Other PowerPC processors
\ count bus clocks, with no absolute calibration.
: calibrate-ticker  ( -- )
   601?  if
      d# 1000000
   else
      d# 8250

      \ Current PowerPC processors run the timebase at 1/4 the bus clock
      " /" find-package  if
         " clock-frequency" rot  get-package-property 0=  if  ( n adr len )
            rot drop  get-encoded-int  d# 1000 /                 ( n' )
	    bus-ratio /
         then
      then

   then
   to counts/ms
   calibrate-microseconds
;
headerless

code get-rtclu  ( -- nsec sec )
   stwu  tos,-4(sp)
   begin		\ Loop until we get a consistent sample
      mfspr t1,rtcu
      mfspr t0,rtcl
      mfspr tos,rtcu
      cmp  0,0,t1,tos
   = until
   stwu  t0,-4(sp)
c;
code get-tb ( -- ticks.lo ticks.hi )
   stwu  tos,-4(sp)
   begin		\ Loop until we get a consistent sample
      isync
      mftb  t1,tbu
      mftb  t0,tb
      mftb  tos,tbu
      cmp  0,0,t1,tos
   = until
   stwu  t0,-4(sp)
c;
: get-msecs-601  ( -- ms )
   get-rtclu  d# 40000000 mod  d# 1000 *  swap counts/ms / +
;
: get-msecs-ppc  ( -- ms )  get-tb  counts/ms um/mod nip  ;
: (get-msecs)  ( -- ms )  601?  if  get-msecs-601  else  get-msecs-ppc  then  ;
' (get-msecs) to get-msecs

: ms-601  ( n -- )
   d# 1000 /mod             ( msec sec )
   swap counts/ms *  swap   ( nsec sec )
   get-rtclu                ( nsec sec nsec sec )
   rot +  -rot  + dup  d# 1000000000 >=  if
      d# 1000000000 -  swap 1+
   else
      swap
   then                     ( target-nsec target-sec )

   begin
      get-rtclu             ( target-nsec target-sec nsec sec )
      2 pick  2dup u>  if  5drop exit  then	( t-n t-s n s t-s )
      =  if
         2 pick  ( t-n t-s n t-n )  u>=  if  2drop  exit  then
      else
         drop
      then
   again
;
: ms-ppc  ( n -- )
   counts/ms um*             ( d.nsec )
   get-tb d+                ( d.target-ticks )

   begin
      get-tb                ( d.target-ticks d.ticks )
      2over d-              ( d.target-ticks d.diff )
      nip  0>=
   until
   2drop
;
: (ms)  ( n -- )  601?  if  ms-601  else  ms-ppc  then  ;
' (ms) to ms

code dec!  ( #ticks -- )	\ Store the decrementer register
   sync
   mtspr  dec,tos
   sync
   lwz    tos,0(sp)
   addi   sp,sp,1cell
c;

code dec@  ( -- #ticks )	\ Read the decrementer rgister
   stwu   tos,-1cell(sp)
   sync
   mfspr  tos,dec
c;
code tb@    ( -- ticks.lo )
   stwu  tos,-4(sp)
   isync
   mftb  tos,tb
c;


\ On a 60 MHz 8xx, the fixed overhead of this word is about .5 microseconds,
\ so the actual time delay is about half a count longer.  On faster processors,
\ the overhead might be somewhat smaller, although the multiply time, the
\ time to enable and disable interrupts, and the time to read the time base
\ register might not quite scale with the clock rate.

\ Delay at least n microseconds.  Interrupts remain enabled.
code unlocked-microseconds   ( #microseconds --  )
   'user us-multiplier lwz t0,*	\ Multiplier
   mullw  tos,t0,tos		\ Counts*125
   'user us-divisor lwz t0,*	\ Divisor
   divwu  tos,tos,t0		\ Counts
   mftb   t0,tb			\ Current time
   add    tos,tos,t0		\ Target time
   begin
      mftb  t0,tb		\ Get time
      subf. t0,tos,t0		\ Compare to target using circular arithmetic
   0>= until 			\ Spin until target time reached
   lwz tos,0(sp)		\ Clean up stack
   addi sp,sp,4
c;

\ Delay n microseconds with interrupts disabled.  This gives more precise
\ timing but keeps the processor from doing other things.
code microseconds  ( #microseconds --  )
   mfmsr  t1
   rlwinm t2,t1,0,17,15		\ Clear interrupt enable bit
   mtmsr  t2			\ Disable interrupts

   'user us-multiplier lwz t0,*	\ Multiplier
   mullw  tos,t0,tos		\ Counts*125
   'user us-divisor lwz t0,*	\ Divisor
   divwu  tos,tos,t0		\ Counts
   mftb   t0,tb			\ Current time
   add    tos,tos,t0		\ Target time
   begin
      mftb  t0,tb		\ Get time
      subf. t0,tos,t0		\ Compare to target using circular arithmetic
   0>= until 			\ Spin until target time reached
   lwz tos,0(sp)		\ Clean up stack
   addi sp,sp,4

   mtmsr  t1			\ Restore interrupts
c;

headers
stand-init: Calibrate
   calibrate-ticker
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
