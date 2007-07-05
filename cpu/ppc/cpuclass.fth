purpose: Classify PowerPC CPUs into various general families
\ See license at end of file

headerless
\ At present, PowerPC CPUs can be grouped into several classes.
\ There are several characteristics that are the same across all
\ members of a class.  New classes and new class members appear
\ from time to time.  The 601 is handled elsewhere.

: 603-class?  ( -- flag )
   \ CPU-version 81 is for the 8240
   cpu-version  dup 3 =  over 6 = or  over 7 = or  over 8 = or  swap h# 81 = or
;
: 604-class?  ( -- flag )
   cpu-version  dup 4 =  over 9 = or  swap h# a = or
;
: 620-class?  ( -- flag )
   cpu-version  d# 20 =
;
: 704-class?  ( -- flag )		\ remove 54 to drop proto support.
   cpu-version  dup h# 54 =  swap h# 60 = or
;

: mach-5/pass1?  ( -- flag )
   pvr@ lwsplit h# a = swap h# 100 = and
;
: 823-class?  ( -- flag )
   cpu-version  h# 50 =
;

\ According to IBM, MACH-5 (PVR = A) revision 100 has a bug that requires
\ the BTAC bit be set to 1 in order to disable cacheing of branch addresses.
\ We set the BTAC disable bit in resetvec, here we turn it off if we are
\ running on anything other than a mach-5, version 100.
\ The BTAC bit is bit 30 of HID0. (Well actually, its the 0x00000002 bit
\ the way we look at it)

: fastest-mode  ( -- )
   604-class?  if
      \ Turn on 604 superscalar and dynamic branch prediction modes
      \ machine checks, and cache parity checking
      \ Turn off cache locks and bus parity checking
      hid0@ h# 84 or			( hid0' )
      mach-5/pass1? 0=  if		( hid0' )
         h# 02 invert and		( hid0'' )
      then				( hid0 )
      h# f008.3000 invert and hid0!	( )
   then
[ifdef] exponential
   \ 704-class? if
   cpu-version  h# 60 = if			\ non-proto x704
      \ Turn on 704 superscalar and set POE
      modes@ h# 3.0000 or modes!
   then
[then]
;

\ Some characteristics of various classes

: software-tlb-miss?  ( -- flag )  603-class? 823-class? or  ;
: sticky-cache-invalidate?  ( -- flag )  603-class?  ;

d# 64 value #tlb-lines
: configure-tlb  ( -- )
   cpu-version  case
       3 of  d# 32  endof
       6 of  d# 32  endof
   h# 50 of  d#  8  endof
   ( default ) #tlb-lines swap
   endcase
   to #tlb-lines
;
headers

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
