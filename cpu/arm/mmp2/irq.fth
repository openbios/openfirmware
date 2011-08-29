\ See license at end of file
purpose: Interrupt controller node for Marvell MMP2 (PXA688)

0 0  " d4282000"  " /" begin-package

" interrupt-controller" device-name
my-address my-space h# 400 reg

0 value base-adr
d# 64 constant #levels

: ic@  ( offset -- l )  base-adr + rl@  ;
: ic!  ( l offset -- )  base-adr + rl!  ;

: block-irqs  ( -- )  1 h# 110 ic!  ;
: unblock-irqs  ( -- )  0 h# 110 ic!  ;

: irq-enabled?  ( level -- flag )  /l* ic@ h# 20 and 0<>  ;
: enable-irq  ( level -- )  h# 21 swap /l* ic!  ;  \ Enable for IRQ1
: disable-irq  ( level -- )  0 swap /l* ic!  ;

: run-interrupt  ( -- )
   h# 104 ic@  dup h# 40 and  if               ( reg )
      h# 3f and                                ( level )
      dup disable-irq                          ( level )
      dup  interrupt-handlers over 2* na+ 2@   ( level  level xt ih )
      package( execute )package                ( level )
      enable-irq                               ( )
   else                                        ( reg )
      drop                                     ( )
   then                                        ( )
;

: open  ( -- flag )
   my-unit h# 400 " map-in" $call-parent to base-adr
\ Leave the IRQ table alone so as not to steal interrupts from the SP
\   block-irqs
\   d# 64 0  do  i disable-irq  loop
   unblock-irqs
   true
;
: close  ( -- )  ;

end-package

\ LICENSE_BEGIN
\ Copyright (c) 2010 FirmWorks
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
