purpose: Vendor/product table manipulation
\ See license at end of file

headers
hex

\ Each vendor/product table has two fields (each /w length).
\ XXX May consider expanding the table to include a name field for each
\ XXX entry so that we can support drastically different devices without
\ XXX resorting to a super driver.

/w 2* constant /vendor-product

: find-vendor-product?  ( vid pid list /list -- flag )
   >r >r 0 -rot r> r>  bounds  ?do
      over i w@ = 		( flag vid pid vid=? )
      over i wa1+ w@ = and	( flag vid pid flag' )
      if  rot drop true -rot leave  then	( flag vid pid )
   /vendor-product +loop 	( flag' vid pid )
   2drop
;


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
