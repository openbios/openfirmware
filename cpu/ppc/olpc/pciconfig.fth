purpose: PCI configuration space access for Marvell MV64660
\ See license at end of file

\ Ostensibly this applies to the PCI bus and thus should be in the PCI node.
\ However, many of the host bridge registers are accessed via this mechanism,
\ so it is convenient to make the configuration access words globally-visible.
\ This mechanism works for several different PCI host bridges.

headerless

: config-map  ( config-adr -- port )
   dup  3 invert and  h# 8000.0000 or  h# 3.0c78 mv-l!  ( config-adr )
   3 and  h# 3.0c7c or
;

headers

: config-l@  ( config-addr -- l )  config-map mv-l@  ;
: config-l!  ( l config-addr -- )  config-map mv-l!  ;
: config-w@  ( config-addr -- w )  config-map mv-w@  ;
: config-w!  ( w config-addr -- )  config-map mv-w!  ;
: config-b@  ( config-addr -- c )  config-map mv-b@  ;
: config-b!  ( c config-addr -- )  config-map mv-b!  ;

\ LICENSE_BEGIN
\ Copyright (c) 2007 FirmWorks
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
