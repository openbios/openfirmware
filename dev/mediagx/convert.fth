\ See license at end of file
purpose: Convert digital audio streams to 48KHz from lower sample rates

\ The key conversion routine defined herein is:
\
\  convert-frequency
\     ( sample phase fin fout inbuf #in outbuf 'getsample -- sample' phase' )
\     converts "#in" samples from the buffer "inbuf" into the appropriate
\     number of output samples, storing them in the buffer "outbuf".
\     The arguments are described below.
\
\ Additional routines:
\
\  mono>stereo  ( outbuf #samples -- )
\     copies "#samples" 16-bit samples from the left-channel part of "outbuf"
\     to the right channel.
\
\  lin16mono    ( -- 'getsample )
\  lin16stereo  ( -- 'getsample )
\  ... etc.
\     returns the address of a "get input sample" routine for use with
\     convert-frequency.
\
\ convert-frequency  Arguments 
\   'getsample     - the address of a subroutine for reading the input
\                    sample.  It is called with the input address in
\                    in ESI, and returns the next sample value in EAX,
\                    in 2's complement linear format with the most
\		     significant bits left-justified in the 32-bit word.
\                    It updates the address in ESI to point to the next sample.
\
\   outbuf         - the beginning address of the output buffer.
\                    convert-frequency write to alternate 16-bit words of
\                    outbuf, converting only one channel of data.  In
\                    order to convert a stereo audio source, you can
\                    call convert-frequency twice, once for each channel,
\                    supplying starting values for "outbuf" that differ
\                    by two.
\
\   #in            - The number of input samples to convert.
\
\   inbuf          - the beginning address of the output buffer.
\                    This address is passed as an argument to the
\                    "getsample" routine the first time that it is called;
\                    subsequent calls to "getsample" get the address
\                    that the previous call returned.
\
\   fout           - the output sample frequency in KHz (usually 48)
\
\   fin            - the input sample frequency in KHz (e.g. 8, 11, 44)
\
\   phase	   - the number of internal "counts" until the next
\                    input sample is needed.  The first time you call
\                    convert-frequency on a new stream of input data,
\                    this should be set to the same value as fin.
\                    For subsequent calls on later portions of the same
\                    input data stream, use the value that was returned
\                    by the previous call.  Doing so prevents phase jitter
\                    at the boundaries between buffers.  If you are doing
\                    stereo, you will need to maintain a separate copy of
\                    this value for each channel.
\
\   sample         - the starting/ending sample value.  The first time you
\                    call convert-frequency on a new stream of input data,
\                    set this to the current value of the DAC digital
\                    input (in canonical form - 32-bit 2'complement,
\                    left justified), or 0 if you don't know the current
\                    DAC value.  For subsequent calls on later portions
\                    of the same input data stream, use the value that was
\                    returned by the previous call.  Doing so prevents pops
\                    at the boundaries between buffers.  If you are doing
\                    stereo, you will need to maintain a separate copy of
\                    this value for each channel.

\ Access functions for getting data samples from various input formats,
\ returning values in the canonical format, which is twos-complement
\ linear left-justified in a 32-bit word.

\ 16-bit 2's complement monaural - sample.w, sample.w, ...
label lin16mono  ( si:inptr -- si:inptr' ax:value )
   op: ax  lods
   ax  d# 16 #  shl
   ret
end-code

\ 16-bit 2's complement monaural - sample.w, X.w, sample.w, X.w, ...
label lin16stereo  ( si:inptr -- si:inptr' ax:value )
   op: ax  lods
   2 #  si  add
   ax  d# 16 #  shl
   ret
end-code

\ 8-bit 2's complement monaural - sample.b, sample.b, ...
label lin8mono  ( si:inptr -- si:inptr' ax:value )
   op: al  lods
   ax  d# 24 #  shl
   ret
end-code

\ 8-bit offset-binary monaural - sample.b, sample.b, ...
label offset8mono  ( si:inptr -- si:inptr' ax:value )
   op: al  lods
   d# 127  al  sub	\ Convert from offset-binary (0=-max, 128=0, 255=+max)
   ax  d# 24 #  shl
   ret
end-code

\ 8-bit 2's complement stereo - sample.b, X.b, sample.b, X.b, ...
label lin8stereo  ( si:inptr -- si:inptr' ax:value )
   op: al  lods
   ax  d# 24 #  shl
   si  inc
   ret
end-code

\ 8-bit offset-binary stereo - sample.b, X.b, sample.b, X.b, ...
label offset8stereo  ( si:inptr -- si:inptr' ax:value )
   op: al  lods
   d# 127  al  sub	\ Convert from offset-binary (0=-max, 128=0, 255=+max)
   ax  d# 24 #  shl
   si  inc
   ret
end-code

[ifdef] ulaw-table
0 value ulaw-table-offset
label ulaw8mono  ( si:inptr -- si:inptr' ax:value )
   bx  push

   ax ax xor
   al lods
   
   \ If speed were critical, we could save 2 or 3 instructions by
   \ using a 256-entry lookup table instead of a 128-entry one.
   \ We could save 1 instruction just by storing the table in
   \ reverse order.

   \ Convert from ulaw to linear by table lookup
   0 #)  bx  lea    here 4 -  ulaw8mono -  to ulaw-table-offset
   al not			    \ Invert the ulaw code bits
   al shl			    \ Scale by /w and put high bit in carry
   op:  0 [bx] [ax] *1  ax  mov	    \ Read linear value
   carry?  if  op: ax  neg  then    \ Negate if necessary (test carry from shl)

   ax  d# 16 #  shl
   
   bx  pop
   ret
end-code
: punch-table  ( -- )  ulaw-table  ulaw8mono ulaw-table-offset + !  ;
[then]

\ Duplicates left-channel samples into right channel
code mono>stereo  ( outbuf #samples -- )
   cx pop  bx pop
   begin
      op:  0 [bx]  ax  mov
      op:  ax  2 [bx]  mov
      4 #          bx  add
   loopa
c;

transient
\ Macros defining address calculations for stack-resident variables
: getsample  " 2 /n* [sp]" evaluate  ;	\ Pointer to routine to get sample
: outp       " 3 /n* [sp]" evaluate  ;	\ Output array pointer
: remaining  " 4 /n* [sp]" evaluate  ;	\ Number of remaining input samples
: inp        " 5 /n* [sp]" evaluate  ;	\ Output array pointer
: fout       " 6 /n* [sp]" evaluate  ;	\ Input frequency (KHz)
: fin        " 7 /n* [sp]" evaluate  ;	\ Input frequency (KHz)
: nextin     " 8 /n* [sp]" evaluate  ;	\ Counts to next input sample
: sample     " 9 /n* [sp]" evaluate  ;	\ Last sample
resident

code convert-frequency
   ( sample phase fin fout inbuf #in outbuf 'getsample -- sample' phase' )
   si push   di push

   \ Register usage:
   \ scratch                         ax
   \ current sample value            bx
   \ counts to next output sample    cx
   \ current delta                   dx
   \ input pointer		     si
   \ output pointer		     di

   inp    si  mov		\ Initialize input pointer register
   outp   di  mov		\ Initialize output pointer register
   nextin cx  mov		\ Initialize "counts to next input sample"
   sample bx  mov		\ Initialize current sample register

   begin			\ Loop over output samples
      fin  cx  sub   <=  if	\ Decrement/test "counts to next input sample"
				\ It's time to get a new input sample ...

         remaining  dec		\ Update "remaining inputs" counter
         0<  if
            fin     cx  add     \ Restore "counts" value
            di          pop
            si          pop
            6 /n* # sp  add
            cx  0 [sp]  mov	\ Return new #c value
            bx  4 [sp]  mov	\ Return new last value
            next
         then

         fout       cx  add	\ Update counts to next input sample

         getsample      call	\ result in ax, si updated

         \ Compute the delta between successive output samples; its the
         \ difference between old and new input samples, scaled by the
         \ ratio output-frequency/input-frequency
         bx         ax  sub	\ ax: absolute delta

         fin    ( ax )  imul	\ DX:AX  delta * input frequency
         fout           idiv	\ Scale by denominator - output frequency
         ax         dx  mov     \ Move to "delta" variable

         \ Now DX contains the new "delta" value, with the implied binary
         \ point in the middle of the word, i.e. between bits 15 and 16
      then

      dx         bx  add	\ Update sample value

      bx         ax  mov
      ax    d# 16 #  shr	\ Use only 16 MSB of sample

      op:  ax        stos	\ Store 16-bit sample
      2 #        di  add	\ Skip other channel (left or right)

   again
c;
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
