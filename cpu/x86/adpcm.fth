\ See license at end of file
purpose: decode IMA/DVI ADPCM .wav file

\ Uncompressed data format:
\   16-bit Left, 16-bit Right, ...
\
\ Compressed data format:
\   nibbles	0.hi 0.lo  1.hi 1.lo  2.hi 2.lo  3.hi 3.lo  4.hi 4.lo  5.hi 5.lo ...
\               L1   L0    L3   L2    L5   L4    L7   L6    R1   R0    R3   R2   ...

\ Work on one channel at a time.

0 value val-pred			\ predicted value
0 value index				\ current step change index
0 value in-val				\ place to keep (encoded) input value
0 value in-skip				\ # bytes to skip on channel input
0 value out-skip			\ # bytes to skip on channel output
0 value buf-skip			\ toggle flag for writing values

0 value #ch                             \ # channels
0 value blk-size                        \ # bytes per compressed block
0 value #sample/blk                     \ (blk-size-(#ch*4)) + 1

decimal
create index-table -1 , -1 , -1 , -1 , 2 , 4 , 6 , 8 ,
                   -1 , -1 , -1 , -1 , 2 , 4 , 6 , 8 ,

create stepsize-table			\ 89 entries
    7 , 8  , 9 , 10 , 11 , 12 , 13 , 14 , 16 , 17 ,
    19 , 21 , 23 , 25 , 28 , 31 , 34 , 37 , 41 , 45 ,
    50 , 55 , 60 , 66 , 73 , 80 , 88 , 97 , 107 , 118 ,
    130 , 143 , 157 , 173 , 190 , 209 , 230 , 253 , 279 , 307 ,
    337 , 371 , 408 , 449 , 494 , 544 , 598 , 658 , 724 , 796 ,
    876 , 963 , 1060 , 1166 , 1282 , 1411 , 1552 , 1707 , 1878 , 2066 ,
    2272 , 2499 , 2749 , 3024 , 3327 , 3660 , 4026 , 4428 , 4871 , 5358 ,
    5894 , 6484 , 7132 , 7845 , 8630 , 9493 , 10442 , 11487 , 12635 , 13899 ,
    15289 , 16818 , 18500 , 20350 , 22385 , 24623 , 27086 , 29794 , 32767 ,
hex

0 value 'index-table
0 value 'stepsize-table

: init-ch-vars  ( in out -- in' out' )
   over <w@ dup to val-pred             \ The first entry is the initial value
   over w!
   over 2 + c@ to index                 \ And the initial index
   out-skip +
   swap in-skip + swap
;

code adpcm-decode-sample  ( in out sample# -- in' out' )
   \ Get the delta value
   eax pop                              ( in out )
   7 # eax and 0=  if
      4 [esp] ecx mov                   \ Read the next 4 bytes
      0 [ecx] ebx mov
      'user in-skip ecx mov             \ Increment in to the next data for the channel
      ecx 4 [esp] add
   else
      'user in-val ebx mov
      ebx 4 # shr
   then
   ebx 'user in-val mov                 \ Save the input data
   h# f # ebx and                       \ delta

   \ Compute difference and new predicated value
   \ Computes 'vpdiff = (delta+0.5)*step/4', but see comment in adpcm-coder.
   'user index eax mov                  \ index
   'user 'stepsize-table ecx mov        \ address of stepsize-table
   0 [ecx] [eax] *4 ecx mov             \ step = stepsize-table[index]

   ecx eax mov  eax 3 # shr             \ vpdiff

   4 # bl test 0<>  if   ecx eax add  then
   2 # bl test 0<>  if   ecx edx mov  edx 1 # shr  edx eax add  then
   1 # bl test 0<>  if   ecx edx mov  edx 2 # shr  edx eax add  then

   \ Clamp down output value
   'user val-pred edx mov
   8 # ebx test 0=  if
      eax edx add
   else
      eax edx sub
   then
   d# 32767 # edx cmp >  if  d# 32767 # edx mov  then
   d# -32768 # edx  cmp <  if  d# -32768 # edx mov  then
   edx 'user val-pred mov               \ Update valpred
   0 [esp] eax mov                      \ out
   op: dx 0 [eax] mov                   \ [out] = valpred
   'user out-skip eax mov
   eax 0 [esp] add                      \ Advance out pointer

   \ Update index value
   'user 'index-table eax mov           \ address of index-table
   0 [eax] [ebx] *4 eax mov             \ index-table[delta]

   'user index eax add                  \ index+index-table[delta]
   0 # eax cmp <  if  eax eax xor  then
   d# 88 # eax cmp >  if  d# 88 # eax mov  then
   eax 'user index mov                  \ Update index
c;

: adpcm-decode-ch  ( in out #sample -- )
   0  ?do
      i adpcm-decode-sample             ( in' out' )
   loop  2drop
;

: adpcm-decode-blk  ( in out #sample -- )
   #ch 0  ?do                           ( in out #sample )
      2 pick i /l * +                   ( in out #sample in' )
      2 pick i /w * +                   ( in out #sample in out' )
      init-ch-vars			( in out #sample in' out' )
      2 pick 1-                         ( in out #sample in out #sample-1 )
      adpcm-decode-ch                   ( in out #sample )
   loop  3drop                          ( )
;

: adpcm-decoder  ( in out #sample #ch blk-size -- )
   index-table to 'index-table
   stepsize-table to 'stepsize-table

   dup to blk-size                      ( in out #sample #ch blk-size )
   over 4 * - 1+ to #sample/blk         ( in out #sample #ch )
   dup to #ch                           ( in out #sample #ch )
   dup /l * to in-skip                  ( in out #sample #ch )
       /w * to out-skip                 ( in out #sample )

   begin  dup 0>  while                 ( in out #sample )
      3dup #sample/blk min adpcm-decode-blk
      rot blk-size +                    ( out #sample in' )
      rot #sample/blk #ch * wa+         ( #sample in out' )
      rot #sample/blk -                 ( in out #sample' )
   repeat  3drop
;

\ Decode an .wav file
\
\ .wav file format:
\ "RIFF" L<len of file> "WAVE"
\ "fmt " L<len of fmt data> W<compression code> W<#channels> L<sample rate>
\        L<bytes/second>] W<block align> W<bits/sample> W<extra bytes>
\        W<#samples/block>]
\ "fact" L<len of fact> L<#samples>
\ "data" L<len of data> <blocks of data>
\
\ Each <block of data> contains:
\        W<sample> B<index> B<0> per channel
\        (block size - 1) samples of compressed data

: find-wav-chunk?  ( in chunk$ -- in' true | false )
   rot dup 4 + le-l@ over + swap h# c + ( chunk$ in-end in' )
   begin  2dup u>  while                ( chunk$ in-end in )
      dup 4 pick 4 pick comp 0=  if     ( chunk$ in-end in )
         nip nip nip true exit          ( in true )
      then
      4 + dup le-l@ + 4 +               ( chunk$ in-end in' )
   repeat  4drop
   false
;

: wav-ok?  ( in -- ok? )
   dup " RIFF" comp  swap 8 + " WAVE" comp  or 0=
;

: fmt-ok?  ( in -- #ch blk-size true | false )
   " fmt " find-wav-chunk? 0=  if  false exit  then   ( in' )
   dup      8 + le-w@ h# 11 =              \ compression code: DVI_ADPCM
   over h# 16 + le-w@     4 = and  if      \ bits/sample
      dup   h#  a + le-w@                  ( #ch )
      swap  h# 14 + le-w@  true            ( #ch blk-size true )
   else
      drop false                           ( false )
   then
;

: fact-ok?  ( in -- #sample true | false )
   " fact" find-wav-chunk? dup  if  swap 8 + le-l@ swap  then
;

: data-ok?  ( in -- in' true | false )
   " data" find-wav-chunk? dup  if  swap 8 + swap  then
;

: adpcm-decode  ( in out -- actual )
   over wav-ok? not  if  2drop 0 exit  then       ( in out )
   swap dup data-ok? not  if  2drop 0 exit  then  ( out in in' )
   -rot dup fact-ok? not  if  3drop 0 exit  then  ( in' out in #sample )
   swap     fmt-ok?  not  if  3drop 0 exit  then  ( in' out #sample #ch blk-size )
   2 pick 2 pick /w * * >r                        ( in' out #sample #ch blk-size )  ( R: actual )
   adpcm-decoder r>                               ( actual )
;

: adpcm-size  ( in -- actual )
   dup  wav-ok?  not  if  drop 0 exit  then       ( in )
   dup  fact-ok? not  if  drop 0 exit  then       ( in #sample )
   swap fmt-ok?  not  if  drop 0 exit  then       ( #sample #ch blk-size )
   drop /w * *                                    ( actual )
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
