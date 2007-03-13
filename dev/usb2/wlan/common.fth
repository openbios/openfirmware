purpose: Common USB ethernet driver stuff
\ See license at end of file

hex
headers

\ Interface to /supplicant support package
0 value supplicant-ih
: $call-supplicant  ( ...$ -- ... )  supplicant-ih $call-method  ;
: do-associate   ( -- flag )  " do-associate" $call-supplicant  ;
: process-eapol  ( adr len -- )  " process-eapol" $call-supplicant  ;
: .scan  ( adr -- )  " .scan" $call-supplicant  ;

defer ?process-eapol		['] 2drop to ?process-eapol

\ String comparision
: $=  ( adr0 len0 adr1 len1 -- equal? )
   2 pick <>  if  3drop false exit  then  ( adr0 len0 adr1 )
   swap comp 0=
;
: /string  ( adr len cnt -- adr+n len-n )  tuck - -rot + swap  ;

create mac-adr 0 c, 0 c, 0 c, 0 c, 0 c, 0 c, 0 c, 0 c,
6 constant /mac-adr
: mac-adr$  ( -- adr len )  mac-adr /mac-adr  ;

: null$  ( -- adr len )  " "  ;

\ Big endian operations
: be-w@   ( a -- w )   dup ca1+ c@ swap c@ bwjoin  ;
: be-w!   ( w a -- )   >r wbsplit r@ c! r> ca1+ c!  ;
: be-l@   ( a -- l )   dup wa1+ be-w@ swap be-w@ wljoin  ;
: be-l!   ( l a -- )   >r lwsplit r@ be-w! r> wa1+ be-w!  ;

\ Dumps
: .2  ( n -- )  <# u# u# u#> type  ;
: .enaddr  ( adr -- )
   base @ >r d# 16 base !		( adr len )  ( R: base )
   5 0  do  dup c@ .2 1+ ." :"  loop  c@ .2
   r> base !				( )
;
: 3u.r  ( n -- )  <# bl hold u# u#s u#> type  ;
: cdump  ( adr len -- )
   base @ >r d# 16 base !		( adr len )  ( R: base )
   bounds  ?do  i c@ 3u.r  loop		( )  ( R: base )
   r> base !				( )
;
: ?cr   ( -- )  " ??cr" evaluate  ;
: vdump  ( adr len -- )  debug?  if  " dump"  evaluate  else  2drop  then  ;
: vldump ( adr len -- )  debug?  if  " ldump" evaluate  else  2drop  then  ;
: vtype  ( adr len -- )  debug?  if  type cr  else  2drop  then  ;


defer init-nic         ( -- )			' noop to init-nic
defer wrap-msg         ( adr len -- adr' len' )	' noop to wrap-msg
defer unwrap-msg       ( adr len -- adr' len' )	' noop to unwrap-msg
defer link-up?	       ( -- up? )		' true to link-up?
defer reset-nic        ( -- )			' noop to reset-nic
defer start-nic        ( -- )			' noop to start-nic
defer stop-nic         ( -- )			' noop to stop-nic

external
defer get-mac-address  ( -- adr len )		' mac-adr$ to get-mac-address
headers

: max-frame-size  ( -- size )  d# 1514  ;

0 value vid
0 value pid

0 value outbuf
d# 2048 value /outbuf   \ Power of 2 larger than max-frame-size
                        \ Override as necessary

0 value inbuf
d# 2048 value /inbuf    \ Power of 2 larger than max-frame-size
                        \ Override as necessary

: init-buf  ( -- )
   outbuf 0=  if  /outbuf dma-alloc to outbuf  then
   inbuf  0=  if  /inbuf  dma-alloc to inbuf   then
;
: free-buf  ( -- )
   outbuf  if  outbuf /outbuf dma-free  0 to outbuf  then
   inbuf   if  inbuf  /inbuf  dma-free  0 to inbuf   then
;

: property-or-abort  ( name$ -- n )
   2dup get-my-property  if          ( name$ )
      ." Can't find property " type cr  stop-nic abort
   then                              ( name$ value$ )
   2swap 2drop  decode-int  nip nip  ( n )
;

: init  ( -- )
   init
   " vendor-id"  property-or-abort  to vid
   " device-id"  property-or-abort  to pid
;

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
