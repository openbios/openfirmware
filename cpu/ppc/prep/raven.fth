purpose: "Raven" PCI Bridge Controller Access Methods
\ See license at end of file

h# feff.0000 constant raven-addr

: pcic-l@  ( offset -- l )  raven-addr + be-l@  ;
: pcic-w@  ( offset -- l )  raven-addr + be-w@  ;
: pcic-c@  ( offset -- l )  raven-addr + c@  ;

: pcic-l!  ( l offset -- )  raven-addr + be-l!  ;
: pcic-w!  ( l offset -- )  raven-addr + be-w!  ;
: pcic-c!  ( l offset -- )  raven-addr + c!  ;

: raven?  ( -- flag )		      \ True if we have a Raven controller
   0 pcic-l@  h# 10574801 =
;

: r-rev@  ( -- b )  6 pcic-c@  ;	\ Chip revision

: r-csr@  ( -- w )  h# 0a pcic-w@  ;	\ Control and status register
: r-csr!  ( w -- )  h# 0a pcic-w!  ;

: csr-or  ( w -- )  r-csr@  or  r-csr!  ;

\ Is PCI in little endian?
: pci-le?  ( -- le? )  r-csr@  h# 8000 and  ;

\ Set PCI bus to little endian
: pci-le  ( -- )  h# 8000 csr-or  ;

\ PCI Read will complete before writes
: pci-flush-before-read  ( -- )  h# 1000 csr-or  ;

\ PPC master ties up bus during xfer
: buss-hog  ( -- )  h# 800 csr-or  ;

\ PPC Read will complete before writes
: ppc-flush-before-read  ( -- )  h# 400 csr-or  ;

\ Set PPC bus timeouts
\  0 = 256 uS
\  1 =  64 uS
\  2 =   8 uS
\  3 = disable
: ppc-bus-timeout  ( 0|1|2|3 -- )
   r-csr@  h# 300 invert and  8 lshift or  r-csr!
;

\ Set 64-bit mode
: p64  ( -- )  h# 80 csr-or  ;

\ Turn on open-pic controller
: open-pic-enable  ( -- )  h# 20 csr-or  ;

\ Read module-id bits, tells us who owns he bus in MP systems
\ 0 = device on ABG0
\ 1 = device on ABG1
\ 2 = device on ABG2
\ 3 = Raven
: mid@  ( -- master-id )  r-csr@  h# 3 and  ;

: r-feature@  ( -- w )  h# 8 pcic-w@  ;
: r-feature!  ( w -- )  h# 8 pcic-w!  ;

: r-prescaler@  ( -- b )  h# 10 pcic-c@  ;
: r-prescaler!  ( b -- )  h# 10 pcic-c!  ;


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

