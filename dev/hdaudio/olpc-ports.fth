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
: select-internal-mic  ( -- )
   mux  1 set-connection  internal-mic enable-hp-input
;
: select-external-mic  ( -- )
   mux  0 set-connection  external-mic enable-hp-input
;
\ Set this to use the internal mic even if an external mic is plugged in
false value force-internal-mic?
: set-recording-port  ( -- )
   external-mic pin-sense?  force-internal-mic? 0=  and  if
      select-external-mic
   else
      select-internal-mic
   then
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
