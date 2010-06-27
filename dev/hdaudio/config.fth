purpose: Names for HD Audio Configuration Default values
\ See license at end of file

: config(   ( -- null-config-default )   0  ;

\ Connection types
  : 1/8"          ( u -- u )  h#    10000 or  ;
\ : 1/4"          ( u -- u )  h#    20000 or  ;
\ : atapi         ( u -- u )  h#    30000 or  ;
\ : rca           ( u -- u )  h#    40000 or  ;
\ : optical       ( u -- u )  h#    50000 or  ;
\ : other-digital ( u -- u )  h#    60000 or  ;
  : other-analog  ( u -- u )  h#    70000 or  ;
\ : din           ( u -- u )  h#    80000 or  ;
\ : xlr           ( u -- u )  h#    90000 or  ;
\ : rj-11         ( u -- u )  h#    a0000 or  ;
\ : combination   ( u -- u )  h#    b0000 or  ;
\ : other         ( u -- u )  h#    f0000 or  ;

\ Misc
  : no-detect     ( u -- u )  h#      100 or  ;	\ override jack presence detection

\ Colors
\ : unknown     ( u -- u )  h#     0000 or  ;
\ : black       ( u -- u )  h#     1000 or  ;
\ : grey        ( u -- u )  h#     2000 or  ;
\ : blue        ( u -- u )  h#     3000 or  ;
  : green       ( u -- u )  h#     4000 or  ;
\ : read        ( u -- u )  h#     5000 or  ;
\ : orange      ( u -- u )  h#     6000 or  ;
\ : yellow      ( u -- u )  h#     7000 or  ;
\ : purple      ( u -- u )  h#     8000 or  ;
  : pink        ( u -- u )  h#     9000 or  ;
\ : white       ( u -- u )  h#     e000 or  ;
\ : other-color ( u -- u )  h#     f000 or  ;

\ Device
  : line-out           ( u -- u )  h#   000000 or  ;
  : speaker            ( u -- u )  h#   100000 or  ;
  : hp-out             ( u -- u )  h#   200000 or  ;
\ : cd-in              ( u -- u )  h#   300000 or  ;
\ : spdif-out          ( u -- u )  h#   400000 or  ;
\ : other-digital-out  ( u -- u )  h#   500000 or  ;
\ : modem-line         ( u -- u )  h#   600000 or  ;
\ : modem-handset      ( u -- u )  h#   700000 or  ;
\ : line-in            ( u -- u )  h#   800000 or  ;
\ : aux                ( u -- u )  h#   900000 or  ;
  : mic-in             ( u -- u )  h#   a00000 or  ;
\ : telephony          ( u -- u )  h#   b00000 or  ;
\ : spdif-in           ( u -- u )  h#   c00000 or  ;
\ : other-digital-in   ( u -- u )  h#   e00000 or  ;
\ : other-device       ( u -- u )  h#   f00000 or  ;

\ : rear          ( u -- u )  h#  1000000 or  ;
  : front         ( u -- u )  h#  2000000 or  ;
  : left          ( u -- u )  h#  3000000 or  ;
  : right         ( u -- u )  h#  4000000 or  ;
  : top           ( u -- u )  h#  5000000 or  ;
\ : bottom        ( u -- u )  h#  6000000 or  ;
\ : rear-panel    ( u -- u )  h#  7000000 or  ;
\ : drive-bay     ( u -- u )  h#  8000000 or  ;
\ : riser         ( u -- u )  h# 17000000 or  ;
\ : hdmi          ( u -- u )  h# 18000000 or  ;
\ : atapi-loc     ( u -- u )  h# 19000000 or  ;
\ : lid-inside    ( u -- u )  h# 37000000 or  ;
\ : lid-outside   ( u -- u )  h# 38000000 or  ;

: jack          ( u -- u )  h# 00000000 or  ;
: internal      ( u -- u )  h# 10000000 or  ;
: unused        ( u -- u )  h# 40000000 or  ;
: builtin       ( u -- u )  h# 80000000 or  ;

\ LICENSE_BEGIN
\ Copyright (c) 2009 Luke Gorrie <luke@bup.co.nz>
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
