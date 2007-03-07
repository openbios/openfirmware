\ See license at end of file

\ Converts stack addresses to the address of the corresponding location
\ in the stack save areas.

decimal
only forth also hidden also forth definitions

headerless
: rssave-end  ( -- adr )  rssave rs-size +  ;
: pssave-end  ( -- adr )  pssave ps-size +  ;

: in-return-stack?  ( adr -- flag )  rp0 @ rs-size -  rp0 @   between  ;
: in-data-stack?  ( adr -- flag )  sp0 @ ps-size -  sp0 @   between  ;

headers
\ Given an address within the stack, translate it to the corresponding
\ address within the saved stack area.
: >saved  ( adr -- save-adr )
   dup  in-data-stack?               ( adr flag )
   if  sp0 @ -  pssave-end +  then   ( adr' )
   dup  in-return-stack?             ( adr flag )
   if  rp0 @ -  rssave-end +  then   ( adr'' )
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
