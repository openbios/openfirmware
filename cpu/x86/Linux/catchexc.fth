\ See license at end of file

decimal

only forth also hidden also  forth definitions
d# 64 constant #signals

\ Ideally, we should determine /fpstate at runtime by searching
\ for the "retcode" signature 0077b858
\ h# 264 constant /fpstate  \ Determined empirically by dumping with gdb
h# 26c constant /fpstate  \ Determined empirically by dumping with gdb

\ retcode    -   8
\ extramask  -   8
\ fpstate    - 264
\ sigcontext -  58
\ signal#    -   4
\ retaddr    -   4

: enterforth
   \ Adjust pc if it has been incremented past the trap
   int# 3 =  if  %eip 1- to %eip  then
   handle-breakpoint
;

label reenter
   \ We get here from then end of save-state, either by branching directly
   \ or by modifying the return address in the DPMI exception frame.

   make-odd 			 	\ word-align address
   'body main-task   dup #  dx  mov
   -4 allot  token, 			\ rewrite address as relocatable

   0 [dx]             up  mov		\ Establish user pointer

   \ Establish the Data and Return stacks
   'user rp0          rp   mov
   'user sp0          sp   mov

   \ Restart the Forth interpreter.
   cld

   \ Execute enterforth
\   'body enterforth #)  ip  lea
   make-even 				\ word-align for relocation
   'body enterforth  dup #)  ip  lea
   -4 allot  token, 			\ rewrite address as relocatable   
c;

\ This is the signal handler.  When it is called, the stack contains:
\
\   struct sigcontext  ( See /usr/include/asm/sigcontext.h )
\   signal number
\   return address
\
\ We copy the data from sigcontext and fiddle the EIP value in sigcontext
\ so that Forth is re-entered at the enterforth addresss

\ For reference, sigcontext contains:
\   gs, fs, es, ds                           00..0c
\   edi, esi, ebp, esp, ebx, edx, ecx, eax   10..2c
\   trapno, err, eip, cs                     30..3c
\   eflags, esp_at_signal, ss, *fpstate      40..4c
\   oldmask, cr2                             50..54

label save-state-signal

   make-odd 			 	\ word-align address
   'body main-task   dup #  dx  mov
   -4 allot  token, 			\ rewrite address as relocatable

   0 [dx]             up  mov		\ Establish user pointer
   'user cpu-state    bx  mov		\ Base address of save area

   sp                 si  mov           \ Address of return address

   cld         \ Increment pointers
   ax lods  ax  offset-of %esp2  [bx]  mov
   ax lods  ax  offset-of sig#   [bx]  mov

   ax lods  ax  offset-of %gs    [bx]  mov
   ax lods  ax  offset-of %fs    [bx]  mov
   ax lods  ax  offset-of %es    [bx]  mov
   ax lods  ax  offset-of %ds    [bx]  mov

   ax lods  ax  offset-of %edi   [bx]  mov
   ax lods  ax  offset-of %esi   [bx]  mov
   ax lods  ax  offset-of %ebp   [bx]  mov
   ax lods  ax  offset-of %esp   [bx]  mov		\ Correct ESP value will be set later
   ax lods  ax  offset-of %ebx   [bx]  mov
   ax lods  ax  offset-of %edx   [bx]  mov
   ax lods  ax  offset-of %ecx   [bx]  mov
   ax lods  ax  offset-of %eax   [bx]  mov

   ax lods  ax  offset-of int#   [bx]  mov  \ trapno
   ax lods  ax  offset-of %error [bx]  mov  \ Save err

   ax lods  ax  offset-of %eip   [bx]  mov

   \ Change the resume address to go to "reenter"
   make-odd 			 	\ word-align address
   'body reenter   dup #  ax mov
   -4 allot  token, 			\ rewrite address as relocatable
   ax  -4 [si]  mov                     \ Resume at reenter address

   ax lods  ax  offset-of %cs      [bx]  mov
   ax lods  ax  offset-of %eflags  [bx]  mov
   ax lods                                    \ Skip esp_at_signal
   ax lods  ax  offset-of %ss      [bx]  mov
   ax lods                                    \ Skip *fpstate
   ax lods  ax  offset-of %esp1    [bx]  mov  \ Hijack esp1 for oldmask
   ax lods  ax  offset-of %cr3     [bx]  mov  \ Hijack cr3 for cr2
   /fpstate #  si  add                        \ Skip fpstate
   ax lods  ax  offset-of %ss0     [bx]  mov  \ Hijack ss0 for extramask0
   ax lods  ax  offset-of %ss1     [bx]  mov  \ Hijack ss1 for extramask1

   ax ax xor      ax dec
   ax offset-of %state-valid [bx]  mov	\ mark saved state as valid

   \ Copy the entire Forth data stack and return stack areas to a save area.
   up dx mov    \ Save UP

   \ Data Stack  (load si first because di is the user pointer!)
   'user sp0          si   mov
   'user pssave       di   mov    \ Address of data stack save area
   ps-size #          si   sub    \ Bottom of data stack area (in longwords)

   ps-size 4 / #      cx   mov    \ Size of data stack area
   rep  movs

   dx up mov    \ Get user pointer back

   \ Return Stack  (load si first because di is the user pointer!)
   'user rp0          si   mov
   'user rssave       di   mov    \ Address of return stack save area
   rs-size #          si   sub    \ Bottom of return stack area

   rs-size 4 / #      cx   mov    \ Size of return stack area (in longwords)
   rep  movs

   ret
end-code

h# 400 buffer: restart-stack
0 value restart-sp

code (restart  ( -- )
   \ Restore the Forth stacks.

   cld                            \ Increment pointers
   up  bx    mov	   	  \ Save UP because it is di
   
   \ Data Stack
   'user pssave       si    mov   \ Address of data stack save area
   'user sp0          di    mov   \ Top of data stack area

   ps-size #          di    sub   \ Bottom of data stack area
   ps-size 4 / #      cx    mov   \ Size of data stack area (in longwords)
   rep movs


   \ Return Stack
   bx  up  mov			  \ Restore UP for 'user
   'user rssave       si    mov   \ Address of return stack save area
   'user rp0          di    mov   \ Top of return stack area

   rs-size #          di    sub   \ Bottom of return stack area
   rs-size 4 / #      cx    mov   \ Size of return stack area (in longwords)
   rep movs

   \ Restore registers

   bx  up  mov		        	\ Restore UP for 'user
   'user cpu-state    bx   mov		\ Base address of save area

   'user restart-sp   sp   mov          \ Establish a stack for the next steps

   h# 80cd0000 #           push         \ tail of retcode
   h# 0077b858 #           push         \ retcode - ax pop  d# 119 # ax mov  h# 80 int
   offset-of %ss1    [bx]  push         \ Actually extramask
   offset-of %ss0    [bx]  push
   /fpstate #  sp  sub                  \ Space for fpstate
   offset-of %cr3    [bx]  push         \ Actually cr2
   offset-of %esp1   [bx]  push         \ Actually oldmask
   0 #                     push         \ *fpstate
   offset-of %ss     [bx]  push         \ ss
   offset-of %esp    [bx]  push         \ esp_at_signal
   offset-of %eflags [bx]  push
   offset-of %cs     [bx]  push
   offset-of %eip    [bx]  push
   offset-of %error  [bx]  push
   offset-of int#    [bx]  push         \ Actually trapno

   offset-of %eax    [bx]  push
   offset-of %ecx    [bx]  push
   offset-of %edx    [bx]  push
   offset-of %ebx    [bx]  push
   offset-of %esp    [bx]  push
   offset-of %ebp    [bx]  push
   offset-of %esi    [bx]  push
   offset-of %edi    [bx]  push

   offset-of %ds     [bx]  push
   offset-of %es     [bx]  push
   offset-of %fs     [bx]  push
   offset-of %gs     [bx]  push

   offset-of sig#    [bx]  push
   offset-of %esp2   [bx]  push   \ Actually return address

   ret

end-code
' (restart is restart



hidden definitions

#signals /n* buffer: old-signals

defer save-state
' save-state-signal to save-state

: set-signal  ( handler signal# -- old-handler )
   d# 92 syscall 2drop retval
;
: catch-signal  ( signal# -- )
   save-state over  set-signal  ( signal# old-handler )
   old-signals rot na+ !
;
: uncatch-signal  ( signal# -- )  old-signals over na+ @  swap set-signal drop  ;

: uncatch-signals  ( -- )
   d# 02 uncatch-signal	\ SIGINT
   d# 04 uncatch-signal	\ SIGILL
   d# 05 uncatch-signal	\ SIGTRAP
   d# 07 uncatch-signal	\ SIGBUS
   d# 08 uncatch-signal	\ SIGFPE, Divide by 0
   d# 11 uncatch-signal	\ SIGSEGV
;

forth definitions
: catch-signals  ( -- )
   pssave drop  rssave drop	\ Force buffer allocation
   [ 0 alloc-reg ] literal alloc-mem is cpu-state

   d# 02 catch-signal	\ SIGINT
   d# 04 catch-signal	\ SIGILL
   d# 05 catch-signal	\ SIGTRAP
   d# 07 catch-signal	\ SIGBUS
   d# 08 catch-signal	\ SIGFPE, Divide by 0
   d# 11 catch-signal	\ SIGSEGV
;

[ifdef] $save-forth
: $save-forth  ( name$ -- )
   uncatch-signals  $save-forth  catch-signals
;
[then]
only forth also definitions

\ Linux signal names

string-array exception-names
( 00 ) ," "
( 01 ) ," "
( 02 ) ," Interrupt"
( 03 ) ," "
( 04 ) ," Illegal Instruction"
( 05 ) ," Trap"
( 06 ) ," "
( 07 ) ," Bus error"
( 08 ) ," Floating point error or divide-by-0"
( 09 ) ," "
( 10 ) ," "
( 11 ) ," Segmentation fault"
end-string-array

: (.exception)  ( -- )
   sig# 5 =  if
      int# 3 <>  if  ." Int 0x" .x  then
      exit
   then
   
   sig#  d# 11 <=  if  sig# exception-names ". cr  exit  then
   push-decimal sig# (u.) type cr pop-base
;
' (.exception) is .exception
: print-breakpoint
   .exception
   interactive? 0=  if bye then	\ Restart only if a human is at the controls
   ??cr quit
;
\ ' print-breakpoint is handle-breakpoint

\ defer restart  ( -- )
hidden also
: sys-init
   sys-init
   restart-stack h# 400 +  to restart-sp
   catch-signals
   false to hardware-step?
   restartable? off
;
only forth also definitions

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
