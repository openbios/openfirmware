\ See license at end of file
purpose: Conexant CX2058x CODEC driver words reflecting OLPC port usage

: headphone-jack  ( -- )  porta  ;
: external-mic  ( -- )  portb  ;
: internal-mic  ( -- )  portc  ;
: dc-input  ( -- )  portf  ;
: internal-speakers  ( -- )  portg  ;
: speakers-on  ( -- )  internal-speakers  power-on  ;
: speakers-off  ( -- )  internal-speakers  power-off ;

\ Set this to use the speakers even if the headphone jack is plugged
false value force-speakers?
: set-playback-port  ( -- )
   headphone-jack pin-sense?  force-speakers? 0=  and  if  \ headphones attached
      speakers-off
   else                            \ no headphones
      speakers-on
   then
;
\ Connection #2 is for port e which is unused on OLPC
: select-dc-input  ( -- )
   mux  3 set-connection  dc-input enable-hp-input
;
: select-internal-mic  ( -- )
   mux  1 set-connection  internal-mic enable-hp-input
;
: select-external-mic  ( -- )
   mux  0 set-connection  external-mic enable-hp-input
;
\ Set this to use the internal mic even if an external mic is plugged in
false value force-internal-mic?
false value mic-bias-off?
: set-recording-port  ( -- )
   external-mic pin-sense?  force-internal-mic? 0=  and  if
\ select-dc-input does not work for some reason I haven't yet discovered
\ When you try to do a loopback test through the dc input, the received
\ sample values are all 0
\      mic-bias-off?  if  select-dc-input  else  select-external-mic  then
      select-external-mic
   else
      select-internal-mic
   then
;
: .2xuc  ( n -- )
   push-hex
   <# u# u# u#>
   2dup bounds ?do
      i c@  h# 61 >=  if
         i c@  h# 20 -  i c!
      then
   loop
   type
   pop-base
;
: .vendor-table  ( -- )
   vendor
   " "(a1 a2 a3 a4 a5 a6 a7 a8 a9 aa ab ac ad ae af b1 b2 b3 b4 b5 b6 b7 b8 b9 ba c1 c2 c3 c4 c5 c6 c7 c8 c9 cc)"
   bounds  ?do
      ." [0x0" node .2xuc  i c@ .2xuc  ." 000] = "
      i c@ d# 12 << cmd? .x  cr
   loop
;

\ LICENSE_BEGIN
\ Copyright (c) 2010 FirmWorks
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
