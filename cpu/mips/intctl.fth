purpose: Device node for MIPS R4000 internal interrupt controller
\ See license at end of file

" interrupt-controller" device-name
my-address my-space  h# 20  reg

0 value pic-base

: >mask  ( bit# -- mask )  1 swap lshift  ;
: this-interrupt  ( -- irq# )
   cause@  8 rshift h# ff and     ( mask )
   8 0  do  dup i >mask and  if  drop i true unloop exit  then  loop   ( mask )
   drop false
;
: interrupt-mask@  ( -- mask )  sr@ 8 rshift h# ff and  ;
: interrupt-mask!  ( mask -- )  8 lshift  sr@  h# ff00 invert and  or  sr!  ;
: enable-irq  ( irq# -- )
   >mask  interrupt-mask@  or  interrupt-mask!
;
: disable-irq  ( irq# -- )
   >mask  interrupt-mask@  swap invert and  interrupt-mask!
;
: clear-interrupt  ( irq# -- )  1 swap lshift  1 pic-base >offset rb!  ;
: open  ( -- flag )
   pic-base 0=  if
      my-address my-space  h# 38  " map-in" $call-parent  to pic-base
      \ 0 interrupt-mask!
   then
   pic-base 0<>
;
: slot-vector@  ( slot# -- vector )  pic-base >offset rb@  ;
: close  ( -- )  ;

\ LICENSE_BEGIN
\ Copyright (c) 2009 FirmWorks
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
