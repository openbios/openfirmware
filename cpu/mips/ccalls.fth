purpose: C subroutine and Unix system call interfaces for MIPS
\ See license at end of file

\ Defining words to construct Forth interfaces to C subroutines
\ and Unix system calls.  This is strongly implementation dependent, and will
\ require EXTENSIVE modifications for other Forth systems, other CPU's,
\ and other operating systems.
\
\ Defines:
\
\ syscall:    ( syscall# -- )        ( Input Stream: name arg-spec )
\ subroutine: ( adr -- )             ( Input Stream: name arg-spec )
\
\ This version is for MIPS Unix systems where ints, longs, and addresses
\ are all the same size.  Under this assumption, the only thing we have to
\ do to the stack arguments is to convert Forth strings to C strings.

decimal
only forth assembler also forth also hidden also definitions

variable #args  variable #results  variable arg#

: system-call ( syscall# -- )
   asm(
      ( call# )  v0 li                            
      syscall
      $a3 $0 <>  if
         $0   up  ['] errno >user#  sw   \ Delay slot
         v0   up  ['] errno >user#  sw
         -1   v0  li
      then
   )asm
;
: subroutine-call   ( subroutine-adr -- )
   asm( jal  nop )asm
;
: wrapper-call  ( call# -- )
   asm(
      'user syscall-vec  t0  lw		\ Get address of system call table
      bubble
      ( call# ) t0 swap  t0  lw		\ Address of routine
      bubble
      t0 ra jalr   nop
   )asm
;

: sys:  \ name ( call# -- )
   code
;
: $a#  ( -- reg )  arg# @ asm( $a0 )asm  + ;
: ?dec  ( -- )
   arg# @ 4 =  if  asm(  sp adec  )asm  then
;
: arg  ( -- )
   arg# @  if
      ?dec
      \ If the argument number is 4 or greater, we leave it on the stack
      arg# @  4 <  if
         asm(  sp  arg# @ 1- /l*   $a#  lw  )asm
      then
   else
      asm(  tos  $a0  move  )asm
   then
   1 arg# +!
;
: str  ( -- )
   arg# @  if
      ?dec
      arg# @  4 <  if
         asm(
            sp   arg# @ 1- /l*   $a#  lw
            bubble
            $a#  1               $a#  addiu
         )asm
      else
         asm(
            sp   arg# @ 1- /l*   $at  lw
            bubble
            $at  1               $at  addiu
            $at  sp    arg# @ 1- /l*  sw
         )asm
      then
   else
      asm(  tos  1  $a0  addiu  )asm
   then
   1 arg# +!
;   
: res  ( -- )  1 #results +!  ;
: }  ( -- )
   #results @  if
      #args @ 0=  if
         asm(
         tos  sp  push
         )asm
      then

      #args @ 3 >  if
         asm(
         sp  #args @    /l*  sp   addiu
         )asm
      else  #args @ 1 >  if
         asm(
         sp  #args @ 1- /l*  sp   addiu
         )asm
      then  then

      asm(  v0 tos  move   )asm
   else   \ No results
      #args @ 3 >  if
         asm(
         sp  #args @    /l*  tos  lw
         sp  #args @ 1+ /l*  sp   addiu
         )asm
      else  #args @  if
         asm(
         sp  #args @ 1- /l*  tos  lw
         sp  #args @    /l*  sp   addiu
         )asm
      then  then
   then
;
: scan-args ( -- )
   #args off
   0   ( marker )
   begin
      bl word  1+ c@
      case
      ascii l of  ['] arg    true  endof 
      ascii i of  ['] arg    true  endof 
      ascii a of  ['] arg    true  endof
      ascii s of  ['] str    true  endof 
      ascii - of             false endof
      ascii } of  ." Where's the -- ?" abort endof
      ( default ) ." Bad type specifier: " dup emit abort
    endcase
  while
    1 #args +!
  repeat
  arg# off
  begin  ?dup  while  execute  repeat
;
: do-call  ( ??? 'call-assembler -- ) \ ??? is args specific to the call type
   execute
;
: scan-results ( -- )
   #results off
   begin
      bl word  1+ c@
      case
      ascii l of                  true  endof 
      ascii i of                  true  endof 
      ascii a of                  true  endof 
      ascii s of  ." Can't return strings yet" abort   true  endof 
      ascii } of                  false endof
      ( default ) ." Bad type specifier: " dup emit
      endcase
   while
      1 #results +!
   repeat
   }
;
only forth hidden  also forth assembler  also forth  definitions
: {  \ args -- results }  ( -- )
   scan-args  do-call  scan-results    next
;
: syscall:  \ name  ( syscall# -- syscall# 'system-call )
   ['] system-call
   code   current @ context !    \ don't want to be in assembler voc
;
: subroutine:  \ name  ( adr -- adr 'subroutine-call )
   ['] subroutine-call code   current @ context !
;

only forth also definitions

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
