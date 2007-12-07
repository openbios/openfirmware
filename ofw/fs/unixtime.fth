\ See license at end of file
purpose: Convert Unix seconds to time and date

decimal
\ date&time is number of seconds since 1970
create days/month
\ Jan   Feb   Mar   Apr   May   Jun   Jul   Aug   Sep   Oct   Nov   Dec
  31 c, 28 c, 31 c, 30 c, 31 c, 30 c, 31 c, 31 c, 30 c, 31 c, 30 c, 31 c,

: >d/m  ( day-in-year -- day month )
   12 0  do
      days/month i ca+ c@  2dup <  if
         drop 1+  i 1+  leave
      then
      -
   loop
;
: unix-seconds>  ( seconds -- s m h d m y )
   60 u/mod  60 u/mod  24 u/mod		( s m h days )
   [ 365 4 * 1+ ] literal /mod >r	( s m h day-in-cycle )  ( r: cycles )
   dup [ 365 365 + 31 + 29 + ] literal
   2dup =  if		\ exactly leap year Feb 29
      3drop 2 29 2			( s m h year-in-cycle d m )
   else
      >  if  1-  then	\ after leap year
      365 u/mod				( s m h day-in-year year-in-cycle )
      swap >d/m				( s m h year-in-cycle d m )
   then
   rot r> 4 * + 1970 +			( s m h d m y )
;
: >unix-seconds   ( s m h d m y -- seconds )	\ since 1970
   d# 1970 - 4 /mod [ d# 365 4 * 1+ ] literal *		( s m h d m yrs days )
   swap d# 365 * +					( s m h d m days )
   swap  1 max  d# 12 min				( s m h d days m' )
   1- 0 ?do  i days/month + c@ + loop			( s m h d days )
   + 1-							( s m h days )
   d# 24 * +   d# 60 * +   d# 60 * +
;

\ e.g.  time&date >unix-seconds 
\ >unix-seconds unix-seconds>	should have no net effect

hex

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
