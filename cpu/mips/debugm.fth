purpose: CPU-dependent definitions for the source-level debugger
\ See license at end of file

create no-secondary-cache

true value debug-sync-cache?

: at  ( row column -- )  2drop  ;
: kill-line  ( -- )  ;

hex

: low-dictionary-adr  ( -- adr )  origin  init-user-area +  ;

nuser debug-next  \ Pointer to "next"
vocabulary bug   bug also definitions
nuser 'debug   \ code field for high level trace
nuser <ip      \ lower limit of ip
nuser ip>      \ upper limit of ip
nuser cnt      \ how many times thru debug next

\ Since we use a shared "next" routine, slow-next and fast-next are no-op's
alias slow-next 2drop  ( high low -- )
alias fast-next 2drop  ( high low -- )

[ifndef] np@
code np@  ( -- adr )  tos sp push   np tos move   c;
[then]

: copy-next  ( -- )
   \ Copy the normal next routine
   here  8 /n*  dup  allot   ( adr size )
   np@ -rot cmove
;

: sync-cache,  ( -- )
   asm(
\     np 0  5 cache     np 4  5 cache
   " 'user debug-sync-cache?" eval  $at  lw
   $at $0 <>  if
      nop
      np 0  h# 19  cache     np 4  h# 19 cache	\ WriteBack primary D$
[ifndef] no-secondary-cache
      np 0  h# 1b  cache     np 4  h# 1b cache	\ WriteBack secondary D$
      np 0  h# 12  cache     np 4  h# 12 cache	\ Invalidate secondary I$
[then]
      np 0  h# 10  cache     np 4  h# 10 cache	\ Invalidate primary I$
   then
\    3 $a2 li    h# 40 $a1 li   np  $a0 move   d# 1150 v0 li  syscall
   )asm
;

label normal-next
   copy-next
end-code

label debnext
   'user <ip  t0  lw
   bubble
   ip t0  t1  subu
   t1 0>= if  nop
      'user ip>  t0  lw
      bubble
      ip t0   t1  subu
      t1 0<= if  nop
         'user cnt   t0  lw
	 2           t1  li
         t0 1        t0  addiu
	 t0   'user cnt  sw
	 t0  t1  = if  nop
            $0               'user cnt  sw

            h# 8ea80000           t0    li      \ "ip 0  t0  lw"
            t0                    np 0  sw
            h# 01124021           t0    li      \ "w base  w  addu"
            t0                    np 4  sw
\ This is for the old version where the "bubble" macro assembles a nop
\            $0                    np 4  sw	\ nop

            sync-cache,

            \ Machine code for   'debug token@ execute
            'user 'debug   w   lw
	    bubble
            w  base        w   addu
            w 0            t1  lw
            bubble
            t1 base        t1  addu
	    t1                 jr
            nop
         then
      then
   then
   copy-next   
end-code

\ Fix the next routine to use the debug version
code pnext   (s -- )
   debnext origin -  t0   li            \ Relative address of debnext
   t0  base          t0   addu          \ Absolute address of debnext

   
   t0  4             t0   sll           \ Erase top 4 bits
   t0  6             t0   srl           \ Erase bottom 2 bits
   h# 0800.0000      t1   li            \ "j" instruction template
   t1 t0             t0   addu          \ "j debnext"
   t0              np 0   sw            \ Write to first location in "next"
   $0              np 4   sw            \ "nop"

   sync-cache,
c;

\ Turn off debugging
code unbug   (s -- )
   h# 8ea80000           t0    li       \ "ip 0  t0  lw"
   t0                    np 0  sw
   h# 01124021           t0    li       \ "w base  w  addu"
   t0                    np 4  sw
\ This is for the old version where the "bubble" macro assembles a nop
\   $0                    np 4  sw	\ "nop"

   sync-cache,
c;

forth definitions

\ Cannot execute cache instructions under development evironment.
[ifdef] debug-on-cobalt
unbug
[else]
normal-next debug-next !
[then]

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
