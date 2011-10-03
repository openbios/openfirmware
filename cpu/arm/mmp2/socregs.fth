\ See license at end of file
purpose: Register access words for MMP2 registers used by many functional units

: +io  ( offset -- va )  io-va +  ;
: io!  ( value offset -- )  +io l!  ;
: io@  ( offset -- value )  +io l@  ;

: +apbc  ( offset -- io-offset )  h# 01.5000 +  ;  \ APB Clock Unit
: +pmua  ( offset -- io-offset )  h# 28.2800 +  ;  \ CPU Power Management Unit
: +mpmu  ( offset -- io-offset )  h# 05.0000 +  ;  \ Main Power Management Unit
: +scu   ( offset -- io-offset )  h# 28.2c00 +  ;  \ System Control Unit
: +icu   ( offset -- io-offset )  h# 28.2000 +  ;  \ Interrupt Controller Unit

: io-set  ( mask offset -- )  dup io@  rot or  swap io!  ;
: io-clr  ( mask offset -- )  dup io@  rot invert and  swap io!  ;

: icu@  ( offset -- value )  +icu io@  ;
: icu!  ( value offset -- )  +icu io!  ;

: mpmu@  ( offset -- l )  +mpmu io@  ;
: mpmu!  ( l offset -- )  +mpmu io!  ;

: pmua@  ( offset -- l )  +pmua io@  ;
: pmua!  ( l offset -- )  +pmua io!  ;

: apbc@  ( offset -- l )  +apbc io@  ;
: apbc!  ( l offset -- )  +apbc io!  ;

\ LICENSE_BEGIN
\ Copyright (c) 2011 FirmWorks
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
