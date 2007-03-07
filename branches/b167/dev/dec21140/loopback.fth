\ See license at end of file
purpose: MIF interface to PHY

hex
headers

: phy-loopback-off  ( -- )
   ctl e@ h# c00 invert and ctl e!
   setup-mii? drop set-mac-interface
;
: phy-loopback-10   ( -- )
   h# 13 mii-read  4 invert and  h# 13 mii-write	\ 10Mbps
   h#  0 mii-read  h# 3000 invert and h# 4100 or  h#  0 mii-write
			\ loopback, 10Mbps, disable A/N, FD
   set-mac-interface
   ctl e@ h# 800 or ctl e!	\ ext loopback
   d# 100 ms
;
: phy-loopback-100  ( -- )
   h# 13 mii-read  4 or  h# 13 mii-write	\ 100Mbps
   h#  0 mii-read  h# 1000 invert and h# 6100 or  h#  0 mii-write
			\ loopback, 100Mbps, disable A/N, FD
   set-mac-interface
   ctl e@ h# 800 or ctl e!				\ MAC at 100Mbps, ext lb
   d# 100 ms
;

create loopback-prototype
   ff c, 00 c,                                        \ Ones and zeroes
   01 c, 02 c, 04 c, 08 c, 10 c, 20 c, 40 c, 80 c,    \ Walking ones
   fe c, fd c, fb c, f7 c, ef c, 0df c, 0bf c, 7f c,  \ Walking zeroes
   55 c, aa c,
   ff c, 00 c,                                        \ Ones and zeroes
   01 c, 02 c, 04 c, 08 c, 10 c, 20 c, 40 c, 80 c,    \ Walking ones
   fe c, fd c, fb c, f7 c, ef c, 0df c, 0bf c, 7f c,  \ Walking zeroes
   55 c, aa c,
   ff c, 00 c,                                        \ Ones and zeroes
   01 c, 02 c, 04 c, 08 c, 10 c, 20 c, 40 c, 80 c,    \ Walking ones
   fe c, fd c, fb c, f7 c, ef c, 0df c, 0bf c, 7f c,  \ Walking zeroes
   55 c, aa c,
d# 12 d# 60 + constant /loopback

/loopback buffer: (loopback-buffer)
/loopback buffer: (receive-buffer)

: loopback-buffer  ( -- adr len )
   (loopback-buffer)   ( adr )
   mac-address drop    over              6 cmove   \ Set source address
   mac-address drop    over 6 +          6 cmove   \ Set destination address
   loopback-prototype  over d# 12 +  /loopback d# 12 - cmove   \ Set buffer contents
   /loopback
;
: receive-buffer  ( -- adr len )  (receive-buffer) /loopback  ;

: pdump  ( adr -- )
   base @ >r  hex
   dup          d# 10  bounds  do  i c@  3 u.r  loop  cr
   d# 10 + dup  d# 10  bounds  do  i c@  3 u.r  loop  cr
   d# 10 + dup  d# 10  bounds  do  i c@  3 u.r  loop  cr
   d# 10 + dup  d# 10  bounds  do  i c@  3 u.r  loop  cr
   d# 10 + dup  d# 10  bounds  do  i c@  3 u.r  loop  cr
   d# 10 +      d# 10  bounds  do  i c@  3 u.r  loop  cr
   r> base !
;
: check-data  ( padr i-adr,len -- flag )
   >r  2dup
   d# 12 +  r> d# 12 - comp  if
      ." Received packet contained incorrect data.  Expected: " cr
      swap  pdump
      ." Observed:" cr
      d# 12 + pdump
      false
   else
      2drop true
   then
;

: wait-for-read  ( adr len -- len | 0 )
   get-msecs d# 5000 + >r		( adr len )  ( R: s )
   begin
      2dup read over =  if		( adr len )  ( R: s )
         over 6 + mac-address comp 0=  if
            nip r> drop exit		( len )
         then
      then
      get-msecs r@ >			( adr len timeout? )  ( R: s )
   until  2drop r> drop 0		( 0 )
;

\ According to the 21143 doc, other packages may be received.
\ So, we filter those out.
\ But so far I've not seen the sent package come back.  Hmmm!!!
: loopback-test  ( -- flag )
   loopback-buffer tuck write <> if
      ." send failed." cr
   else
      receive-buffer wait-for-read 0=  if
         ." Did not receive expected loopback packet." cr
      else         (  buf-handle data-address length )
	 loopback-prototype receive-buffer check-data  if
            ." Loopback ok" cr
         then
      then
   then
   
   phy-loopback-off
;

external
: loopback-test-10   ( -- flag )
   ." 10Mbps loopback test" cr
   phy-loopback-10  loopback-test  
;
: loopback-test-100  ( -- flag )
   ." 100Mbps loopback test" cr
   phy-loopback-100  loopback-test  
;
: loopback-test  ( -- flag )  loopback-test-10  loopback-test-100  ;
headers

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
