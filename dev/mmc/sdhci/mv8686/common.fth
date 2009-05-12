purpose: Common ethernet driver stuff
\ See license at end of file

hex
headers

false instance value debug?

: debug-on  ( -- )  true to debug?  ;

: dma-alloc    ( size -- virt )              " dma-alloc" $call-parent    ;
: dma-free     ( virt size -- )              " dma-free" $call-parent     ;

: usec  ( us -- )  " us" evaluate  ;

: 4drop  ( n1 n2 n3 n4 -- )  2drop 2drop  ;

\ Little endian operations
: le-w@   ( a -- w )   dup c@ swap ca1+ c@ bwjoin  ;
: le-w!   ( w a -- )   >r  wbsplit r@ ca1+ c! r> c!  ;
: le-l@   ( a -- l )   >r  r@ c@  r@ 1+ c@  r@ 2+ c@  r> 3 + c@  bljoin  ;
: le-l!   ( l a -- )   >r lbsplit  r@ 3 + c!  r@ 2+ c!  r@ 1+ c!  r> c!  ;

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


defer link-up?	       ( -- up? )		' true to link-up?
defer reset-nic        ( -- )			' noop to reset-nic
defer start-nic        ( -- )			' noop to start-nic
defer stop-nic         ( -- )			' noop to stop-nic

external
defer get-mac-address  ( -- adr len )		' mac-adr$ to get-mac-address
headers

: max-frame-size  ( -- size )  d# 1514  ;

: property-or-abort  ( name$ -- n )
   2dup get-my-property  if          ( name$ )
      ." Can't find property " type cr  stop-nic abort
   then                              ( name$ value$ )
   2swap 2drop  decode-int  nip nip  ( n )
;

: find-fw  ( $ -- adr len )
   over " rom:" comp  if
      " boot-read" evaluate		\ Not a dropin
      " loaded" evaluate
   else
      4 - swap 4 + swap " find-drop-in" evaluate  0=  if  null$  then
   then
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
