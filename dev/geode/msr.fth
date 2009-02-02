purpose: Encode various Geode address routing MSRs
\ See license at end of file

: msr-clr  ( bitmask msr# -- )  >r  invert  r@  msr@  -rot  and  swap r> msr!  ;
: msr-set  ( bitmask msr# -- )  >r  r@  msr@  -rot  or  swap r> msr!  ;

: page#  ( adr -- page# )  d# 12 rshift  ;

: p2d-format  ( low high offset type -- msr.low msr.high )
   d# 28 lshift               ( low high offset type<< )
   swap 8 lshift or           ( low high offset,type )
   over d# 12 rshift  or  >r  ( low high r: msr.high )
   d# 20 lshift or  r>        ( msr.low msr.high )
;

: >p2d-range  ( base size type -- d.msrval )
   >r                    ( base size            r: type )
   bounds  page#         ( end base-page        r: type )
   swap page# 1-         ( base-page last-page  r: type )
   0  r>  p2d-format     ( msr.low msr.hi' )
;
: >p2d-range-offset  ( base size dst-base type -- d.msrval )
   >r                    ( base size                         r: type )
   2 pick - page# -rot   ( offset-page base size             r: type )
   bounds  page#         ( offset-page end base-page         r: type )
   swap page# 1-         ( offset-page base-page last-page   r: type )
   rot  r>  p2d-format   ( msr.low msr.hi' )
;
h# fffff. 2constant p2d-range-disabled

: set-p2d-range  ( base size type msr# -- )  >r  >p2d-range  r> msr!  ;

: set-p2d-range-offset  ( base size dst-base type msr# -- )
   >r  >p2d-range-offset  r> msr!
;

: p2d-range-off  ( msr# -- )  p2d-range-disabled  rot msr!  ;

: >p2d-bm  ( base size type -- d.msrval )
   >r                 ( base size               r: type )
   negate page#       ( base mask-page       r: type )
   swap page#         ( base-page mask-page  r: type )
   0  r>  p2d-format  ( msr.low msr.hi' )
;
: >p2d-bm-offset  ( base size dst-base type -- d.msrval )
   >r                    ( base size dst-base              r: type )
   2 pick - page#  -rot  ( offset-page base size           r: type )
   negate page#          ( offset-page base mask-page      r: type )
   swap page#            ( offset-page mask-page base-page r: type )
   rot  r>  p2d-format   ( msr.low msr.hi )
;
h# ff.fff00000. 2constant p2d-bm-disabled

: set-p2d-bm  ( base size type msr# -- )   >r  >p2d-bm  r> msr!  ;

: set-p2d-bm-offset  ( base size dst-base type msr# -- )
   >r >p2d-bm-offset  r> msr!
;

: p2d-bm-off  ( msr# -- )  p2d-bm-disabled  rot msr!  ;

: >iod-bm  ( base size type -- d.msrval )
   >r                   ( base size   r: type )
   negate h# fffff and  ( base mask   r: type )
   swap                 ( mask base   r: type )
   0  r>  p2d-format    ( msr.low msr.hi' )
;
: set-iod-bm  ( base size type msr# -- )   >r  >iod-bm  r> msr!  ;
alias iod-bm-off p2d-bm-off

: >rconf  ( base-adr size mode -- d.msrval )
   >r                ( base-adr size     r: mode )
   bounds            ( end-adr base-adr  r: mode )
   r> or             ( end-adr msr.low  )
   swap h# 1000 -    ( msr.low msr.high )
;
0. 2constant rconf-disabled

: set-rconf  ( base-adr size mode msr# -- )  >r >rconf r> msr!  ;

: >io-rconf  ( base-adr size mode -- d.msrval )
   >r                           ( base-adr size    r: mode )
   bounds                       ( end-adr base-adr  r: mode )
   d# 12 lshift  r> or          ( end-adr msr.low  )
   swap 4 - d# 12 lshift  1 or  ( msr.low msr.high )
;

: set-io-rconf  ( base-adr size mode msr# -- )  >r >io-rconf r> msr!  ;

: rconf-off  ( msr# -- )  rconf-disabled  rot msr!  ;


: >usb-kel  ( base-adr size ena -- d.msrval )
   >r            ( base-adr size  r: type )
   negate r> or  ( msr.lo msr.hi )
;
: set-usb-kel   ( base-adr size ena msr# -- )  >r >usb-kel r> msr!  ;
: set-usb-base  ( base-adr type msr# -- )  msr!  ;
: usb-base-off  ( msr# -- )  0. rot  msr!  ;
: usb-kel-off   ( msr# -- )  0. rot  msr!  ;

: pci-speed  ( -- hz )
   h# 4c00.0014 rdmsr drop    ( low )
   1 7 << and  if  d# 66,666,667  else d# 33,333,333  then
;
: gl-speed  ( -- hz )
   pci-speed                         ( hz )
   h# 4c00.0014 rdmsr  nip >r        ( hz r: high )
   r@ 6 rshift 1 and  if  2/  then   ( hz' r: high )
   r> 7 rshift h# 1f and 1+ *        ( hz' )
;
: cpu-speed  ( -- hz )
   pci-speed                         ( hz )
   h# 4c00.0014 rdmsr  nip >r        ( hz r: high )
   r@ 1 and  if  2/  then            ( hz' r: high )
   r> 1 rshift h# 1f and 1+ *        ( hz' )
;

\ LICENSE_BEGIN
\ Copyright (c) 2008 FirmWorks
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
