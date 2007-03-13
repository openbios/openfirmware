purpose: HMAC MD5 message-digest routines
\ See license at end of file

\ md5digest = MD5 (K XOR opad, MD5(K XOR ipad, text))
\   where K is an n byte key
\         ipad is 64 0x36
\         opad is 64 0x5c
\         text is the data being protected

/digest buffer: md5-idigest		\ md5-idigest = MD5(K XOR ipad, text))
/digest buffer: md5-tkey
: ?md5-reset-key  ( key$ -- key$' )
   dup d# 64 >  if
      md5digest				( digest$ )
      md5-tkey swap move		\ Save new key
      md5-tkey /digest			( key$ )
   then
;
: hmac-md5  ( datan$..data1$ n key$ -- digest$ )
   ?md5-reset-key			( datan$..data1$ n key$' )
   2dup key>keypad >r >r		( datan$..data1$ n )  ( R: key$ )

   \ md5-idigest = MD5(K XOR ipad, text)
   keypad h# 36 xor-keypad		( datan$..data1$ n )  ( R: key$ )
   MD5Init				( datan$..data1$ n )  ( R: key$ )
   keypad /keypad MD5Update		( datan$..data1$ n )  ( R: key$ )
   0  ?do  MD5Update  loop		( )  ( R: key$ )
   MD5Final				( )  ( R: key$ )
   md5digest md5-idigest /digest move	( )  ( R: key$ )

   \ md5digest = MD5(K XOR opad, md5-idigest)
   r> r> key>keypad			( )
   keypad h# 5c xor-keypad
   MD5Init
   keypad /keypad MD5Update
   md5-idigest /digest MD5Update
   MD5end				( digest$ )
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

