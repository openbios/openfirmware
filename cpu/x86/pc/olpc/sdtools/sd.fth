\ See license at end of file
\needs mmap fload ioports.fth

: usage  ( -- )  ." CaFe SD exerciser.  Type help for more info." cr  ;
: help  ( -- )
   ." CaFe SD exerciser commands:" cr
   ."   All numbers are automatically in hex" cr
   cr
   ."   <offset> r            \ Display the 32-bit value" cr
   ."   <value> <offset> w    \ Write a 32-bit value" cr
   ."   <offset> <len>  ldump \ Dump a range of SD locations" cr
   ."   bye                   \ Quit the program" cr
   cr
   ." You can also use any Forth programming language command" cr
   cr
   ." Examples:" cr
   ." 315c r" cr
   ." 60006 315c w" cr
;

usage

hex
0 value sd-base

: sdl@  ( offset -- l )  sd-base + l@  ;
: sdw@  ( offset -- w )  sd-base + w@  ;
: sdb@  ( offset -- b )  sd-base + c@  ;

: sdl!  ( l offset -- )  sd-base + l!  ;
: sdw!  ( w offset -- )  sd-base + w!  ;
: sdb!  ( b offset -- )  sd-base + c!  ;

: r  ( offset -- )  sdl@ u.  ;
: w  ( l offset -- )  sdl!  ;

-1 value flash-base
\needs cdump  : cdump  ( adr len -- )  bounds  ?do  i c@ .x  loop  ;
\needs .mfg-data fload mfgdata.fth

\needs ms fload wrtime.fth

\needs dcon@ fload dconsmb.fth

: mode!    ( mode -- )    1 dcon!  ;
: hres!    ( hres -- )    2 dcon!  ;  \ def: h#  458 d# 1200
: htotal!  ( htotal -- )  3 dcon!  ;  \ def: h#  4e8 d# 1256
: hsync!   ( sync -- )    4 dcon!  ;  \ def: h# 1808 d# 24,8
: vres!    ( vres -- )    5 dcon!  ;  \ def: h#  340 d# 900
: vtotal!  ( htotal -- )  6 dcon!  ;  \ def: h#  390 d# 912
: vsync!   ( sync -- )    7 dcon!  ;  \ def: h#  403 d# 4,3
: timeout! ( to -- )      8 dcon!  ;  \ def: h# ffff
: scanint! ( si -- )      9 dcon!  ;  \ def: h# 0000
: bright!  ( level -- ) d# 10 dcon! ; \ def: h# xxxF

\needs vp@ fload dumpgamma.fth

: unimp  true abort" SPI reflashing is not implemented in this version"  ;
: spicmd! unimp ;  : spi-cmd-wait unimp ;  : power-off unimp ;
defer spi-start  defer spi@  defer spi!  defer spi-out  defer spi-reprogrammed
1 value spi-us
: disable-interrupts ;  : ignore-power-button ;
\needs ec@ fload ecio.fth
\needs ec-range fload ecdump.fth

: map-io  ( -- )
   h# fe01.0000 h#    4000 mmap to sd-base
   h# fff0.0000 h# 10.0000 mmap to flash-base
   h# fe00.8000 h#    4000 mmap to vp-base
   h# fe00.4000 h#    4000 mmap to dc-base
   h# fe00.0000 h#    4000 mmap to gp-base
;
map-io

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
