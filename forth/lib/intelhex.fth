\ See license at end of file
purpose: Intel hex format decoder

\ Defines:
\  parse-ihex-record  ( adr len -- data-adr data-len offset type )

variable ihex-sum

: ihex-char  ( adr len -- adr' len' char )
   dup 0= abort" Unexpected end of ihex line"
   over c@ >r 1 /string r>
;
: ihex-nibble  ( adr len -- adr' len' nibble )
   ihex-char h# 10 digit  0= abort" Bad hex character in ihex data"
;
: ihex-byte  ( adr len -- adr' len' byte )
   ihex-nibble >r  ihex-nibble r> 4 lshift or
   dup ihex-sum +!
;
: ihex-address  ( adr len -- adr' len' word )
   ihex-byte >r  ihex-byte r> bwjoin
;

h# 20 buffer: ihex-data
: parse-ihex-record  ( adr len -- data-adr data-len offset type )
   ihex-char  [char] : <> abort" Bad start character in ihex file"

   ihex-sum off                      ( adr len )
   ihex-byte >r                      ( adr len r: datalen )
   ihex-address -rot                 ( offset adr len r: datalen )
   ihex-byte -rot                    ( offset type adr len r: datalen )
   r@ h# 20 > abort" Ihex record too long"
   r@ 0  ?do                         ( offset type adr len r: datalen )
      ihex-byte ihex-data i + c!     ( offset type adr len r: datalen )
   loop                              ( offset type adr len r: datalen )
   ihex-byte drop                    ( offset type adr len r: datalen )
   ihex-sum @ h# ff and  abort" Bad ihex checksum"
   2drop                             ( offset type r: datalen )
   ihex-data r>  2swap               ( data-adr data-len offset type )
;

\ LICENSE_BEGIN
\ Copyright (c) 2012 FirmWorks
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
