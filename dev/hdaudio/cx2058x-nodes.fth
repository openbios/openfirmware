purpose: Node names for Conexant CX2058x HD Audio CODEC
\ See license at end of file

: afg    ( -- )      1 set-node  ;  \ Audio Function Group
: dac1   ( -- )  h# 10 set-node  ;
: adc1   ( -- )  h# 14 set-node  ;
: mux    ( -- )  h# 17 set-node  ;      \ mux between port b and port c
: mux2   ( -- )  h# 18 set-node  ;
: porta  ( -- )  h# 19 set-node  ;
: portb  ( -- )  h# 1a set-node  ;    \ Port B - OLPC external mic
: portc  ( -- )  h# 1b set-node  ;    \ Port C - OLPC internal mic
: portd  ( -- )  h# 1c set-node  ;    \ Port D - OLPC unused
: porte  ( -- )  h# 1d set-node  ;    \ Port E - OLPC unused
: portf  ( -- )  h# 1e set-node  ;    \ Port F - OLPC DC input
: portg  ( -- )  h# 1f set-node  ;    \ Port G - speaker driver
: porth  ( -- )  h# 20 set-node  ;    \ Port H - S/PDIF out
: porti  ( -- )  h# 22 set-node  ;    \ Port I - S/PDIF out
: portj  ( -- )  h# 23 set-node  ;    \ Digital mic 1/2
: vendor ( -- )  h# 25 set-node  ;    \ Vendor-specific controls
: portk  ( -- )  h# 27 set-node  ;    \ Port K - Dig Mic 3/4

\ LICENSE_BEGIN
\ Copyright (c) 2009 Luke Gorrie <luke@bup.co.nz>
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
