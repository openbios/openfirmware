purpose: PCI access and misc words for ATH9K driver
\ See license at end of file

headers
hex

" wlan" device-name
" wireless-network" device-type

168c constant ATHEROS_ID
true value in-little-endian?
variable opencount 0 opencount !

0 value chipbase
2.0000 value /regs
: reg@  ( r -- v )  chipbase + rl@  ;
: reg!  ( v r -- )  chipbase + rl!  ;
: reg@!  ( v m r -- )  dup reg@  rot invert and  rot or  swap reg!  ;

: my-b@  ( offset -- b )  my-space +  " config-b@" $call-parent  ;
: my-b!  ( b offset -- )  my-space +  " config-b!" $call-parent  ;

: my-w@  ( offset -- w )  my-space +  " config-w@" $call-parent  ;
: my-w!  ( w offset -- )  my-space +  " config-w!" $call-parent  ;

: map-regs  ( -- )
   0 0 my-space h# 0200.0010 + /regs " map-in" $call-parent to chipbase
   4 my-w@  6 or  4 my-w!
;
: unmap-regs  ( -- )
   4 my-w@  6 invert and  4 my-w!
   chipbase /regs " map-out" $call-parent
;

: dma-sync     ( virt phys size -- )         " dma-sync" $call-parent     ;
: dma-alloc    ( size -- virt )              " dma-alloc" $call-parent    ;
: dma-free     ( virt size -- )              " dma-free" $call-parent     ;
: dma-map-in   ( virt size cache? -- phys )  " dma-map-in" $call-parent   ;
: dma-map-out  ( virt phys size -- )         " dma-map-out" $call-parent  ;

\ Little endian operations
: le-w@   ( a -- w )   dup c@ swap ca1+ c@ bwjoin  ;
: le-w!   ( w a -- )   >r  wbsplit r@ ca1+ c! r> c!  ;
: le-l@   ( a -- l )   >r  r@ c@  r@ 1+ c@  r@ 2+ c@  r> 3 + c@  bljoin  ;
: le-l!   ( l a -- )   >r lbsplit  r@ 3 + c!  r@ 2+ c!  r@ 1+ c!  r> c!  ;

\ Big endian operations
: be-w@   ( a -- w )   dup ca1+ c@ swap c@ bwjoin  ;
: be-w!   ( w a -- )   >r wbsplit r@ c! r> ca1+ c!  ;
: be-l@   ( a -- l )   dup wa1+ be-w@ swap be-w@ wljoin  ;
: be-l!   ( l a -- )   >r lwsplit r@ be-w! r> wa1+ be-w!  ;

\ Misc helpers
: $, ( adr len -- )  here over allot  swap move  ;
: 4drop  ( n1 n2 n3 n4 -- )  2drop 2drop  ;
: cdump  ( adr len -- )  bounds  ?do  i c@  3 u.r  loop  ;
: $=  ( $1 $2 -- flag )
   rot tuck <>  if  3drop false exit  then
   comp 0=
;
: /string  ( adr len n -- )  tuck  2swap +  -rot -  ;
: round-up  ( n align -- n' )  1- tuck + swap invert and  ;

\ Debug helpers
false instance value debug?
defer vemit             ' drop  to vemit
defer vtype             ' 2drop to vtype
defer vcdump            ' 2drop to vcdump
: (vtype)   ( adr len -- )  type  cr  ;
: (vcdump)  ( adr len -- )  cdump cr  ;
: enable-emit  ( -- )
   ['] emit     to vemit
   ['] (vtype)  to vtype
   ['] (vcdump) to vcdump
;
: disable-emit  ( -- )
   ['] drop to vemit
   ['] 2drop to vtype
   ['] 2drop to vcdump
;

\ Response wait time (ms)
d# 1,000 constant resp-wait-short
d# 1,500 constant resp-wait-long
d# 5,000 constant resp-wait-xlong
resp-wait-short instance value resp-wait

\ MAC addresses
6 constant /mac-adr
create mac-adr 0 c, 3 c, 7f c, 0 c, 0 c, 0 c, 0 c, 0 c,
: mac-adr$  ( -- $ )  mac-adr /mac-adr  ;

/mac-adr buffer: target-mac
: target-mac$  ( -- $ )  target-mac /mac-adr  ;

\ Data rates
d# 12  constant #rates
create supported-rates 02 c, 04 c, 0b c, 16 c, 0c c, 12 c, 18 c, 24 c,
                       30 c, 48 c, 60 c, 6c c,
#rates buffer: common-rates

\ WPA/WPA2 keys
0 value ktype                   \ Key type
0 value ctype-g                 \ Group (multicast) cipher type
0 value ctype-p                 \ Pairwise (unicast) cipher type

\ ktype values
0 constant kt-wep
1 constant kt-wpa
2 constant kt-wpa2
h# ff constant kt-none

d# 16 constant /aes
d# 32 constant /tkip
/tkip buffer: g-tkip
/aes  buffer: g-aes
/tkip buffer: p-tkip
/aes  buffer: p-aes

\ ctype-x values
0 constant ct-none
1 constant ct-tkip
2 constant ct-aes

\ hardware key type values
0 constant KEYTABLE_TYPE_40
1 constant KEYTABLE_TYPE_104
3 constant KEYTABLE_TYPE_128
4 constant KEYTABLE_TYPE_TKIP
5 constant KEYTABLE_TYPE_AES   \ DO NOT use this
6 constant KEYTABLE_TYPE_CCM   \ AES (CCM)
7 constant KEYTABLE_TYPE_CLR

1 value grp-idx              \ groupwise key table idx
0 value pair-idx             \ pairwise key table idx
0 value wep-idx              \ wep key table idx (0-3)

d# 16 buffer: wep1  0 constant /wep1
d# 16 buffer: wep2  0 constant /wep2
d# 16 buffer: wep3  0 constant /wep3
d# 16 buffer: wep4  0 constant /wep4
: wep1$  ( -- $ )  wep1 /wep1  ;
: wep2$  ( -- $ )  wep2 /wep2  ;
: wep3$  ( -- $ )  wep3 /wep3  ;
: wep4$  ( -- $ )  wep4 /wep4  ;
: wep-key$  ( idx -- $ )
   case
      0  of  wep1 /wep1  endof
      1  of  wep2 /wep2  endof
      2  of  wep3 /wep3  endof
      3  of  wep4 /wep4  endof
      ( otherwise )  0 0 rot
   endcase
;
external
: set-wep  ( wep4$ wep3$ wep2$ wep1$ idx -- ok? )
   to wep-idx
   dup to /wep1 wep1 swap move
   dup to /wep2 wep2 swap move
   dup to /wep3 wep3 swap move
   dup to /wep4 wep4 swap move
   true
;
: set-key-type  ( ctp ctg ktype -- )  to ktype  to ctype-g  to ctype-p  ;
headers
: key-wep?    ( -- wep? )   ktype kt-wep =  ;
: key-wpa?    ( -- wpa? )   ktype kt-wpa =  ;
: key-wpa2?   ( -- wpa2? )  ktype kt-wpa2 =  ;
: key-wpax?   ( -- wpa|wap )  key-wpa? key-wpa2? or  ;
: pkey-tkip?  ( -- tkip? )  key-wpax?  if  ctype-p ct-tkip =  else false  then  ;
: gkey-tkip?  ( -- tkip? )  key-wpax?  if  ctype-g ct-tkip =  else false  then  ;
: pkey-aes?   ( -- tkip? )  key-wpax?  if  ctype-p ct-aes  =  else false  then  ;
: gkey-aes?   ( -- tkip? )  key-wpax?  if  ctype-g ct-aes  =  else false  then  ;

false value wep-enabled?
false value gkey-enabled?
false value pkey-enabled?
: key-enabled?  ( -- flag )  wep-enabled? pkey-enabled?  or  ;

\ OUI values (big-endian)
h# 0050.f201 constant wpa-tag                   \ WPA tag
h# 0050.f202 constant moui-tkip                 \ WPA cipher suite TKIP
h# 0050.f204 constant moui-aes                  \ WPA cipher suite AES
h# 000f.ac02 constant oui-tkip                  \ WPA2 cipher suite TKIP
h# 000f.ac04 constant oui-aes                   \ WPA2 cipher suite AES
h# 000f.ac02 constant aoui                      \ WPA2 authentication suite
h# 0050.f202 constant amoui                     \ WPA authentication suite

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
