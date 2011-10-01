\ See license at end of file
purpose: Platform specifics for OLPC Camera on XO-1.5

h# 26 constant dcon-port
: dcon-setup  ( -- )  dcon-port to smb-port  h# 1a to smb-slave  ;
: smb-init    ( -- )  dcon-setup  smb-on  smb-pulses  ;

: dcon@  ( reg# -- word )  dcon-setup  smb-word@  ;
: dcon!  ( word reg# -- )  dcon-setup  smb-word!  ;

: cl!  ( l adr -- )  " mmio-base" $call-parent + rl!  ;
: cl@  ( adr -- l )  " mmio-base" $call-parent + rl@  ;

h# 42 constant ov-sid
h# 31 constant sccb-port

: camera-smb-setup  ( -- )  sccb-port to smb-port  ov-sid to smb-slave  ;
: ov@  ( reg -- data )  camera-smb-setup  smb-byte@  ;
: ov!  ( data reg -- )  camera-smb-setup  smb-byte!  ;

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
