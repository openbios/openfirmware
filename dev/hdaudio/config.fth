purpose: Names for HD Audio Configuration Default values
\ See license at end of file

: config(   ( -- null-config-default )   0  ;

: 1/8"        ( u -- u )  h#    10000 or  ;
: oanalog     ( u -- u )  h#    70000 or  ;	\ other analog
: overrd      ( u -- u )  h#      100 or  ;	\ override
: black       ( u -- u )  h#     1000 or  ;
: green       ( u -- u )  h#     4000 or  ;
: pink        ( u -- u )  h#     9000 or  ;
: hp-out      ( u -- u )  h#   200000 or  ;
: spdiff-out  ( u -- u )  h#   400000 or  ;
: mic-in      ( u -- u )  h#   a00000 or  ;
: line-in     ( u -- u )  h#   800000 or  ;
: line-out    ( u -- u )                  ;
: speaker     ( u -- u )  h#   100000 or  ;
: top         ( u -- u )  h#  5000000 or  ;
: right       ( u -- u )  h#  4000000 or  ;
: left        ( u -- u )  h#  3000000 or  ;
: front       ( u -- u )  h#  2000000 or  ;
: internal    ( u -- u )  h# 10000000 or  ;
: jack        ( u -- u )  h# 00000000 or  ;
: unused      ( u -- u )  h# 40000000 or  ;
: builtin     ( u -- u )  h# 80000000 or  ;

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
