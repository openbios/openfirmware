\ See license at end of file
purpose: Chip-independent part of interrupt dispatch code

0 value pic-node
: enable-interrupt   ( level -- )  " enable-irq"  pic-node $call-method  ;
: disable-interrupt  ( level -- )  " disable-irq" pic-node $call-method  ;

: stray-interrupt  ( level -- )
   ." Unexpected interrupt on IRQ" dup .d cr
   disable-interrupt				\ To prevent recurrence
;

0 value interrupt-handlers
: interrupt-handler!  ( xt int# -- )
   my-self swap  interrupt-handlers swap 2* na+  2!
;
: interrupt-handler@  ( int-level -- xt )
   interrupt-handlers swap 2* na+ 2@  drop
;

: (dispatch-interrupt)  ( -- )  " run-interrupt" pic-node $call-method  ;

: (init-dispatcher)  ( -- )
   pic-node  0=  if
      " /interrupt-controller" open-dev to pic-node
      " #levels" pic-node $call-method                         ( #levels )
      dup 2* /n*  alloc-mem to interrupt-handlers              ( #levels )
      0  do  ['] stray-interrupt  i interrupt-handler!  loop   ( 0 )
      ['] (dispatch-interrupt) to dispatch-interrupt
   then
;
' (init-dispatcher) to init-dispatcher

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
