purpose: Driver for RTC portion og M48T559
\ See license at end of file

hex
headerless
" rtc" device-name
" rtc" device-type

" m48t559-rtc" encode-string
" compatible" property

my-address    my-space  encode-phys  4 encode-int encode+
" reg" property

h# 1ff8 constant rtc-base

: rtc-set-adr  ( offset -- data-adr )
   rtc-base +  wbsplit  nv-adr-high pc!  nv-adr-low pc!  nv-data
;
: rtc@  ( offset -- n )  lock[ rtc-set-adr pc@ ]unlock  ;
: rtc!  ( n offset -- )  lock[ rtc-set-adr pc! ]unlock  ;
: inhibit-updates  ( -- )  lock[ 0 rtc@  h# 40 or  0 rtc! ]unlock ;
: enable-writes  ( -- )  lock[ 0 rtc@  h# 80 or  0 rtc! ]unlock ;
: start-updates  ( -- )  lock[ 0 rtc@  h# c0 invert and  0 rtc! ]unlock ;

\ Going to carve out a few more bytes, just under the start of the rtc regs
\ to use as a place to put things like the century and maybe battery status

\ So our map looks like:
\
\   Offset	Value	        Where
\
\   0x1fff	year	        RTC
\   0x1ffe	month	        RTC
\   0x1ffd	date		RTC
\   0x1ffc	day		RTC
\   0x1ffb	hours		RTC
\   0x1ffa	minutes		RTC
\   0x1ff9	seconds		RTC
\   0x1ff8	control		RTC		<- rtc-base address
\   0x1ff7	watchdog	RTC
\   0x1ff6	interrupts	RTC
\   0x1ff5	alarm date	RTC
\   0x1ff4	alarm hours	RTC
\   0x1ff3	alarm minutes	RTC
\   0x1ff2	alarm seconds	RTC
\   0x1ff1	unused		RTC
\   0x1ff0	flags		RTC
\   0x1fef	mac		NVRAM
\   0x1fee	mac		NVRAM
\   0x1fed	mac		NVRAM
\   0x1fec	mac		NVRAM
\   0x1feb	mac		NVRAM
\   0x1fea	mac		NVRAM
\   0x1fe9	mac checksum	NVRAM
\   0x1fe8	century		NVRAM

: cmos-base-adr  ( -- adr )  rtc-base h# 10 -  ;
: cmos-set-addr  ( offset -- data-adr )
   cmos-base-adr + wbsplit  nv-adr-high pc!  nv-adr-low pc!  nv-data
;
: cmos@  ( offset -- b )  cmos-set-addr pc@  ;
: cmos!  ( b offset -- )  cmos-set-addr pc!  ;

: century!  ( b -- )  0 cmos!  ;
: century@  ( -- b )  0 cmos@  ;

: check-battery  ( -- error? )
   " status" get-my-property 0=  if
      decode-string 2nip  " bad battery" $=  nip exit
   then

   -8 rtc@ h# 10 and		( error? )  \ Get battery status
   dup if			( error? )
      " bad battery"		( error $ )
   else				( 0 )
      " okay"			( 0 $ )
   then				( error? $ )
   encode-string  " status" property	( error? )
;

true value first-open?
: open  ( -- ok? )
   first-open?  if   
      check-battery drop
      false to first-open?
   then
   true
;
: close  ;

: bcd>  ( bcd -- binary )  dup h# f and  swap 4 >>  d# 10 *  +  ;
: >bcd  ( binary -- bcd )  d# 10 /mod  4 << +  ;

: bcd-time&date  ( -- s m h d m y century )
   inhibit-updates
   1 rtc@  2 rtc@  3 rtc@  5 rtc@  6 rtc@  7 rtc@ century@ ( s m h d m y c )
   start-updates
;
: bcd!  ( n offset -- )  swap >bcd  swap rtc!  ;

: get-time  ( -- s m h d m y )
   bcd-time&date  >r >r >r >r >r >r
   bcd>  r> bcd>  r> bcd>  r> bcd>  r> bcd>  r> bcd>  r> bcd> ( s m h d m y c )

   \ We allow the century byte to force the year to 20xx, but not to force
   \ it to 19xx, because that would cause a problem when the century
   \ rolls over.
   dup  d# 20 <>  if
      drop  dup d# 94 <  if  d# 20  else  d# 19  then
   then

   d# 100 * +  		\ Merge century with year
;
: set-time  ( s m h d m y -- )
   enable-writes
   d# 100 /mod  century!  7 bcd!  6 bcd!  5 bcd!  3 bcd!  2 bcd!  1 bcd!
   r> d# 11 rtc!                            ( )
   start-updates
;
\ LICENSE_BEGIN
\ Copyright (c) 1997 FirmWorks
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
