\ See license at end of file
purpose: Date and Time-of-day access

decimal
variable tmstruct
: tmfield  \ name  ( offset -- offset' )
   create  dup ,  la1+
   does> @  tmstruct @ +
;

struct   \ tm struct returned by 4.2 localtime call
tmfield tm_sec
tmfield tm_min 
tmfield tm_hour
tmfield tm_mday
tmfield tm_mon
tmfield tm_year
tmfield tm_wday
tmfield tm_yday
tmfield tm_isdst
drop

: (today  ( -- timeval-struct-adr )  64 syscall retval tmstruct !  ;
: today  ( -- day month year)
   (today  tm_mday l@   tm_mon  l@ 1+  tm_year l@ 1900 +
;
: now  ( -- sec min hour )  (today  tm_sec l@  tm_min l@  tm_hour l@  ;
: time-zone  ( -- minutes-west-of-GMT)  68 syscall retval  ;
: .time-zone  ( -- )   72 syscall retval cscount type  ;

string-array months
   ," January"
   ," February"
   ," March"
   ," April"
   ," May"
   ," June"
   ," July"
   ," August"
   ," September"
   ," October"
   ," November"
   ," December"
end-string-array

: .month  ( index -- )  1- months  ".  ;
: date$  ( day month year -- )
   push-decimal
   <#
     u# u# u# u#
     bl hold  [char] , hold
     drop swap u# u#s
     bl hold
     swap 1- months count hold$
   u#>
   pop-base
;
: .date  ( day month year -- )
   push-decimal
   swap .month space
   swap 2 .r ." , "
   .
   pop-base
;
: 2.r  ( n -- )  (.2) type  ;
: time$  ( secs mins hours -- adr len )
   push-decimal
   rot <# u# u# [char] : hold drop swap u# u# [char] : hold drop u# u# u#>
   pop-base
;
: .time  ( secs mins hours -- )
   push-decimal
   2 .r  ." :" 2.r ." :" 2.r
   space .time-zone
   pop-base
;
: .now  ( -- )  now .time  ;
: .today  ( -- )  today .date  ;
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
