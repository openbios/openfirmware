purpose: Conexant CX2058x codec
\ See license at end of file
hex

\ \ Conexant

: power-on   ( -- )  h# 70500 cmd  ;
: power-off  ( -- )  h# 70503 cmd  ;
: power-on-all  ( -- )
   " "(01 10 11 12 14 15 16 17 18 19 1a 1b 1c 1d 1e 1f 20 21 22 23 24)"
   bounds  do  i c@ to node  power-on  loop
;   

: volume-on-all  ( -- )
   h# 14 to node  h# 36006 cmd  h# 35006 cmd
   h# 23 to node  h# 36004 cmd  h# 35004 cmd
   h# 17 to node  h# 3a004 cmd  h# 39004 cmd
   h# 18 to node  h# 3a004 cmd  h# 39004 cmd
   h# 14 to node  h# 36200 cmd  h# 35200 cmd
   h# 10 to node  h# 3a03e cmd  h# 3903e cmd
;

: cx2058x-open  ( -- )
   h# 10 to dac
   h# 14 to adc
   power-on-all
   volume-on-all
;

: cx2058x-close  ( -- )
   1 to node ( function group) power-off
;

h# 1a value mic-in   \ Port B
h# 1b value mic      \ Port C
h# 17 value mux      \ mux between the two

: pin-sense?       ( -- ? )  h# f0900 cmd? h# 8000.0000 and 0<>  ;
: set-connection   ( n -- )  h# 70100 or cmd   ;
: enable-hp-input  ( -- )    h# 70721 cmd  ;

: cx2058x-enable-recording  ( -- )
   mic-in to node  pin-sense?  if
      mux to node  0 set-connection  mic-in to node enable-hp-input
   else
      mux to node  1 set-connection  mic to node enable-hp-input
   then
;

: cx2058x-disable-recording  ( -- )  ;

: cx2058x-enable-playback   ( -- )
   h# 10 to node  h# 70640 cmd   h# 20000 stream-format or cmd
;
: cx2058x-disable-playback  ( -- )  ;

: cx2058x-init ( -- )
   ['] cx2058x-open  to open-codec
   ['] cx2058x-close to close-codec
   ['] cx2058x-enable-recording  to enable-codec-recording
   ['] cx2058x-disable-recording to disable-codec-recording
   ['] cx2058x-enable-playback   to enable-codec-playback
   ['] cx2058x-enable-playback   to disable-codec-playback
;

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
