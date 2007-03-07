\ See license at end of file
purpose: Machine-dependent interfaces used by the decompiler
hex

: low-dictionary-adr  ( -- adr )  origin  init-user-area +  user-size +  ;

nuser debug-next  \ Pointer to "next"
vocabulary bug   bug also definitions
nuser 'debug   \ code field for high level trace
nuser <ip      \ lower limit of ip
nuser ip>      \ upper limit of ip
nuser cnt      \ how many times thru debug next

label _flush_cache  ( -- )
   ret
end-code

label _disable_cache  ( -- )
   ret
end-code

\ Change all the next routines in the indicated range to jump through
\ the user area vector
code slow-next  ( high low -- )
   ax pop   ax pop
   _disable_cache #) call
   h# a7ff #  ax  mov		\ disp [up] jmp
   op: ax  0 [up]  mov
   'user# debug-next #  ax  mov	  \ 'disp' is user area offset of debug-next
   ax      2 [up]  mov
   _flush_cache #) call
c;

\ Change all the next routines in the indicated range to perform the
\ in-line next routine
code fast-next  ( high low -- )
   ax pop   ax pop
   _disable_cache #)  call
   h# 9020ffad #  ax  mov		\ ax lods  0 [ax] jmp  nop
   ax         0 [up]  mov
   _flush_cache #)    call
c;

label normal-next
   \ We have to expand the code for NEXT in-line here, because if
   \ we let the assembler macro do it, we'll end up with a jump right back
   \ to this routine
   ax lods   0 [ax] jmp
end-code

label debnext
   'user <ip   ip  cmp
   u>= if
      'user ip>   ip  cmp
      u< if
         'user cnt  ax  mov
	 ax             inc
         ax  'user cnt  mov
         2 #        ax  cmp
	 = if
            ax ax sub
	    ax  'user cnt         mov
\            normal-next #)   ax   lea
	    make-even 				\ word-align address
            normal-next   dup #)   ax   lea
            -4 allot  token, 			\ relocate address

            ax  'user debug-next  mov
            'user 'debug     w    mov
            0 [w]                 jmp
         then
      then
   then
   \ We have to expand the code for NEXT in-line here, because if
   \ we let the assembler macro do it, we'll end up with a jump right back
   \ to this routine
   ax lods   0 [ax] jmp		\ Next
end-code

\ Fix the next routine to use the debug version
: pnext   (s -- )  debnext debug-next a!  ;

\ Turn off debugging
: unbug   (s -- )  normal-next debug-next a!  ;

forth definitions
unbug
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
