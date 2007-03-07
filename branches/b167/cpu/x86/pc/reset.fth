\ See license at end of file
purpose: Warm reset

\ There are two ways to reset a PC.  Some use a bit in port 92, and
\ others use the keyboard controller.  We try both.

: eat-data  ( -- )  begin  h# 64 pc@  1 and  while  h# 60 pc@ drop  repeat  ;
: inbuf-wait  ( -- )  begin  h# 64 pc@  2 and  0= until  ;
: outbuf-wait  ( -- )  begin  h# 64 pc@  1 and  until  ;
: cmd-put  ( cmd -- )  inbuf-wait  h# 64 pc!  ;
: data-get  ( -- data )   outbuf-wait  h# 60 pc@  ;
: data-put  ( data -- data )   inbuf-wait  h# 60 pc!  ;
: kbd-reset-all  ( -- )
   eat-data                           \ Discard pending kbd data
   h# d0 cmd-put  data-get  ( val )   \ Get old output register value
   1 invert and             ( val' )  \ Clear RESET* bit
   h# d1 cmd-put  data-put  ( )       \ Write new output register val
;

: (reset-all)  ( -- )
   h# 92 pc@  1 invert and  dup  h# 92 pc!  1 or  h# 92 pc!  d# 1000 ms

   \ If port 92 doesn't work, try the keyboard controller reset
   kbd-reset-all  d# 1000 ms
;
' (reset-all) to reset-all
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
