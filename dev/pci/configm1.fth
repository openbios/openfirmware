\ See license at end of file
purpose: Configuration space access using "configuration mechanism 1"

\ Ostensibly this applies to the PCI bus and thus should be in the PCI node.
\ However, many of the host bridge registers are accessed via this mechanism,
\ so it is convenient to make the configuration access words globally-visible.
\ This mechanism works for several different PCI host bridges.

headerless

defer config-map
: config-map-m1  ( config-adr -- port )
   dup  3 invert and  h# 8000.0000 or  h# cf8 pl!  ( config-adr )
   3 and  h# cfc or  io-base +
;
' config-map-m1 to config-map

headers

: config-l@  ( config-addr -- l )  config-map rl@  ;
: config-l!  ( l config-addr -- )  config-map rl!  ;
: config-w@  ( config-addr -- w )  config-map rw@  ;
: config-w!  ( w config-addr -- )  config-map rw!  ;
: config-b@  ( config-addr -- c )  config-map rb@  ;
: config-b!  ( c config-addr -- )  config-map rb!  ;
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
