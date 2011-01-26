purpose: USB Data Packet Manipulation
\ See license at end of file

hex
headers

\ XXX This code assumes the device and configuration descriptors are ok.

false value class-in-dev?

: find-desc  ( adr type -- adr' )
   swap  begin  ?dup  while		( type adr )
      dup 1+ c@ 2 pick =  if  0  else  dup c@ +  then
					( type adr' )
   repeat  nip				( adr )
;

: find-intf-desc  ( adr intfidx -- adr )
   swap  begin				( intfidx adr )
      INTERFACE find-desc		( intfidx adr' )
   swap ?dup  while			( adr intfidx )
      1- swap				( intfidx' adr )
      dup c@ +				( intfidx adr' )
   repeat
;

: unicode$>ascii$  ( adr -- actual )
   dup c@ 2 - 2/ swap 2 + over 0  ?do	( actual adr' )
      dup i 2* 1+ + c@ 0=  if		\ ASCII
         dup i 2* + c@			( actual adr c )
      else				\ Non-ascii
         ascii ?			( actual adr c )
      then
      over 2 - i + c!			( actual adr )
   loop  drop
;

\ XXX In the future, maybe we can decode more languages.
: encoded$>ascii$  ( adr lang -- actual )
   drop unicode$>ascii$
;

headers

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
