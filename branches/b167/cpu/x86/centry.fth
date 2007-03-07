\ See license at end of file
purpose: Client interface handler code

: cfield  over constant +  ;
struct
4 cfield >ax
4 cfield >bx
4 cfield >cx
4 cfield >dx
4 cfield >si
4 cfield >di
4 cfield >bp
4 cfield >sp
4 cfield >flags
buffer: cif-reg-save

code cif-return  ( return-value -- )  \ !csp
   ax pop				\ return value

   'user cif-reg-save bx mov		\ Address of register save area in bx
   >sp [bx] sp mov	>bp [bx] bp mov	\ restore some registers
   >si [bx] si mov	>di [bx] di mov	
   >cx [bx] cx mov	>dx [bx] dx mov
   >flags [bx] push     >bx [bx] bx mov
   popf
   ret
end-code

\ make-cif-thunk must create a thunk that dispatches to the version of
\ save-state that assumes a hardware-generated exception stack frame
\ because cif-exit constructs that type of frame.
\ It pretends to be a trace trap ( int 1 ) because int 3 breakpoint
\ traps require manual fixup to the eip value.
\ The net affect is as if the client program were interrupted just
\ before the instruction following the client-handler call.

0 value cif-thunk
: make-cif-thunk  ( -- )
   [ also hidden ]
   ['] save-state behavior >r
   ['] save-state-common to save-state
   h# 1 make-thunk   ( adr sel )	\ pretend to be a trace trap
   r> to save-state
   [ previous ]   drop to cif-thunk
;

\ cif-exit is called from a client service like "exit" or "enter".
\ Instead of returning normally, it restores the CPU state to the state
\ that would exist just after the client handler returned, and then
\ invokes "save-state" as if an exception had occurred just before
\ executing the instruction just after the call to the client handler.
\ 
\ None of the services that use cif-exit have result values.

code cif-exit  !csp  ( -- )
   'user cif-thunk  ax mov

   'user cif-reg-save bx mov		\ Address of register save area in bx
   >sp [bx] sp mov	\ restore caller stack

   cx pop		\ eip for return address in cx
   >flags [bx] push     \ Create a stack frame that looks like an interrupt
   cs push		\ 
   cx push		\ Now stack has ... eflags cs eip
   ax push		\ Setup to return to thunk

   >bp [bx] bp mov	\ Restore the rest of the registers
   >si [bx] si mov
   >di [bx] di mov	
   >cx [bx] cx mov
   >dx [bx] dx mov
   >bx [bx] bx mov

   ax ax xor		\ Pretend that the client interface returned "okay"

   ret			\ "return" to thunk, which will then go to save-state
end-code

: cif-exec  ( args ... -- )  do-cif cif-return  ;

label cif-handler
   \ Registers:
   \ eax		argument array pointer
   \ ebp,esp,esi,edi,eaqx,ebx,ecx,edx		preserved
   \ bp,si,ax,di  <=> rp,ip,w,up

   pushf				\ protect until ready to save
   di push
   si push
   bx push
   
\ Get the origin address
   here 5 + #) call   here origin -  ( offset )
   bx  pop
   ( offset ) #  bx  sub	\ Origin in bx

\ Find the user area
   'body main-task origin - # up mov	\ get offset
   bx up add				\ add current origin
   0 [up]  up  mov			\ Fetch value from PFA

   \ Set the interpreter pointer
   'body cif-exec origin - # ip mov
   bx ip add				\ add current origin

   'user cif-reg-save bx mov	\ Address of register save area in ebx
   >bx [bx] pop
   >si [bx] pop		>di [bx] pop
   >flags [bx] pop
   sp >sp [bx] mov	bp >bp [bx] mov	\ save some registers
   cx >cx [bx] mov	dx >dx [bx] mov

   'user sp0 sp mov
   'user rp0 rp mov
   cld

   ax push				\ argument array pointer
c;

\ call client's callback function
\ return value is in args array
code callback-call  ( args vector -- )
   dx pop	ax pop			\ args in ax, vector in dx
   dx call
c;

\ Force allocation of buffer
stand-init: CIF
   cif-reg-save drop  make-cif-thunk  
;
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
