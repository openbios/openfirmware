purpose: Code words for multitasking
\ See license at end of file

code (pause  (s -- )   \ go see if anybody else wants service
   stwu  tos,-4(sp)
   
   'user saved-ip  stw  ip,*
   'user saved-rp  stw  rp,*
   'user saved-sp  stw  sp,*

   'user link      lwz  up,*	\ get up for new task
   add	 up,up,base		\ Relocate it
   'user entry     lwz	t0,*	\ get pc for new task
   add    t0,t0,base
   mtspr  lr,t0
   bclr   20,0
end-code

label to-next-task  (s -- address-of-"next-task"-code )
   'user link      lwz  up,*	\ get up for new task
   add	 up,up,base		\ Relocate it
   'user entry     lwz	t0,*	\ get pc for new task
   add    t0,t0,base
   mtspr  lr,t0
   bclr   20,0
end-code

\ Called with up set to the user area address of the task to run
label task-resume (s -- )	\ start a task
   stwu   tos,-4(sp)
   'user saved-ip  lwz  ip,*
   'user saved-rp  lwz  rp,*
   'user saved-sp  lwz  sp,*
   lwz    tos,0(sp)
   addi   sp,sp,4
c;

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
