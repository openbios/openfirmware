\ See license at end of file
purpose: Internet Protocol version 6 (IPv6) miscellaneous methods

hex

d# 16 constant /ipv6                 \ Bytes per IP address
/ipv6 buffer: my-ipv6-addr

0 value router-hop-limit
0 value router-flags
0 value router-lifetime
0 value router-reachable-time
0 value router-retrans-time

: copy-ipv6-addr  ( src dst -- )  /ipv6 move  ;

: .ipv6  ( buf -- )
   push-hex
   <#  dup /ipv6 + 2 -  do  i be-w@ u#s ascii : hold drop  -2 +loop  0 u#> 1 /string
   pop-base
   type space
;

0 value ipv6-ptr
0 value ipv6-cur-ptr
0 value ipv6-::-ptr
: ipv6-end-ptr  ( -- adr )    ipv6-ptr /ipv6 +  ;
: ipv6-c!    ( n -- )     ipv6-cur-ptr tuck    c! ca1+ to ipv6-cur-ptr  ;
: ipv6-w!    ( n -- )     ipv6-cur-ptr tuck be-w! wa1+ to ipv6-cur-ptr  ;
: ipv6-end?  ( -- flag )  ipv6-cur-ptr ipv6-end-ptr u>=  ;
: ipv4-ok?   ( -- flag )  ipv6-end-ptr ipv6-cur-ptr - 4 >=  ;
: decimal-byte  ( adr,len -- n )
   push-decimal  ['] safe->number catch  pop-base   ( n 0 | x x error )
   throw
   dup d# 255 u> throw                              ( n )
;
: hex-word  ( adr,len -- n )
   push-hex  ['] safe->number catch  pop-base     ( n 0 | x x error )
   throw                                          ( n )
   dup h# ffff u> throw                           ( n )
;
: ($ipv6#)  ( ip$ buf -- )
   0 to ipv6-::-ptr
   dup /ipv6 erase
   dup to ipv6-ptr to ipv6-cur-ptr
   begin  dup  while                              ( ip$ )
      ascii : left-parse-string                   ( r$ l$ )
      ?dup  if             \ hex-word or decimal ipv4 address
         ipv6-end? throw
         2 pick  if        \ Not the last field: hex-word
            hex-word ipv6-w!                      ( r$ )
         else              \ Last field: hex-word or ipv4 adr
            ascii . left-parse-string             ( r$' l$ )
            2 pick  if     \ Decimal ipv4 address
               ipv4-ok? not throw
               decimal-byte ipv6-c!
               3 0  do
                  ascii . left-parse-string       ( r$ l$ )
                  decimal-byte ipv6-c!
               loop  2drop                        ( r$ )
            else
               hex-word ipv6-w!  2drop            ( r$ )
            then
         then
      else
         drop                                     ( r$ )
         ipv6-::-ptr throw
      then
      dup  if
         over c@ ascii : =  if
            ipv6-::-ptr throw
            1 /string ipv6-cur-ptr to ipv6-::-ptr
         then
      then
   repeat  2drop                                  ( )
   ipv6-::-ptr  if                                \ :: encountered, insert zeroes
      ipv6-cur-ptr ipv6-::-ptr - >r               \ # of bytes to shift right
      ipv6-::-ptr ipv6-end-ptr r@ - r@ move       \ Shift right
      ipv6-::-ptr ipv6-end-ptr r> - over - erase  \ Zero for ::
   else
      ipv6-end? 0=  throw
   then
;

: $ipv6#  ( ip$ buf -- )
   ['] ($ipv6#)  catch  abort" Invalid IPv6 address"
;

: .ipv4-not-supported  ( -- )
   " IPv4 is not supported." $abort
;

0 [if]

Test cases:

" 2001:0DB8:0000:0000:0202:B3FF:FE1E:8329"
" 2001:db8:0:0:202:b3ff:fe1e:8329"
" 2001:db8::202:b3ff:fe1e:8329"
" 2001:db8::"
" 2000::"
" fe80::a00:46ff:fe64:768d"
" ::"
" ::1234"
" ::192.168.0.2"
" 0:0:0:0:0:0:192.168.0.2"
" ::c0a8:2"

Erroneous test cases:

" 123::456::789"
" xyz::"
" ::xyz"
" 123::456:xyz"
" xyz:123::456"
" 123:::456"
" 123"
" 123:456"
" ::192.xy.1.102"
" 192.168.1.102"
" ::192.168.1.2:1234"
" 0:0:0:0:0:192.168.0.2"
" 0:0:0:0:0:0:0:192.168.0.2"
" 0:1:2:3:4:5:6:7:8:9:a:b:c:d:e:f:10:11:12"

load-base $ipv6#
load-base .ipv6

[then]

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
