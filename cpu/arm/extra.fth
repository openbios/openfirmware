purpose: Additional kernel code words
\ See license at end of file

hex

code  (llit)  ( -- lit )  psh tos,sp  ldmia ip!,{tos,pc}  c;

code perform  ( adr -- )  ldr r0,[tos]  pop tos,sp  mov pc,r0  end-code 

code hash  ( str-adr voc-ptr -- thread )
   pop     r0,sp              \ string
   ldrb    r0,[r0,#1] 
 #threads-t 1- #
   and     r0,r0,*
   ldr     tos,[tos,1cell]    \ get user#
   add     tos,tos,up         \ Get thread base address
   add     tos,tos,r0,lsl #2
c;

\ Starting at "link", which is the address of a memory location
\ containing a link to the acf of a word in the dictionary, find the
\ word whose name matches the string "adr len", returning the link
\ field address of that word if found.

\ Assumes the following header structure - [N] is size in bytes:
\    pad[0-3]  name-characters[n]  name-len&flags[1]  link[4]  code-field[4]
\                                  ^                  ^        ^
\                                  anf                alf      acf
\ The link field points to the *code field* of the next word in the list.
\ Padding is added, if necessary, before the name characters so that
\ acf is aligned on a 4-byte boundary.

code ($find-next)  ( adr len link -- adr len alf true | adr len false )
   \ !!!! the next line should ONLY be included for RiscOS Forthmacs testing
\   adr     base,'body origin
   ldr     base,[pc,`'body origin swap here 8 + - swap`]
   ldr     r5,[tos]                  \ link is kept in r5
   mov     tos,#0                    \ false is the default return value

\   cmp     r5,#0                     \ ?exit if link=BASE
   cmp     r5,base                   \ ?exit if link=BASE
   nxteq
   begin
\     add     r5,r5,base             \ r5 absolute adr
      dec     r5,1cell               \ r5 at linkfield
      sub     r2,r5,#1               \ r2 set to len/flag-adr
      ldrb    r0,[r2]
      ands    r0,r0,#0x1f            \ r0: mask len of $find-next
      0<> if
         ldmia   sp,{r3,r4}          \ r3 len;   r4 adr

         cmp     r3,r0               \ both strings have same len?
         0= if
            sub     r2,r2,r3         \ r2: adr of potential $find-next
            begin
               decs    r3,#1
            >= while
               ldrb    r0,[r4],#1
               ldrb    r1,[r2],#1    \ compare one char each
               cmp     r0,r1         \ comm: CAPS not tested ?
            0<> until then
            cmn     r3,#1            \ all characters tested?
            0= if
               psh     r5,sp         \ push link-adr ...
               mvn     tos,#0        \ ... and true
               next
            then
         then
      then
      ldr     r5,[r5]
      cmp     r5,BASE                \ link = BASE ?
   0= until
c;

[ifdef] notdef
code l+  ( l1 l2 -- l3 )  pop r0,sp  add tos,tos,r0  c;
code l-  ( l1 l2 -- l3 )  pop r0,sp  rsb tos,tos,r0  c;

code lnegate  ( l -- -l )  rsb tos,tos,#0  c;

code labs  ( l -- [l] )  cmp tos,#0  rsbmi tos,tos,#0  c;

code l2/  ( l -- l/2 )  mov tos,tos,asr #1  c;

code lmin  ( l1 l2 -- l1|l2 )  pop r0,sp  cmp tos,r0  movgt tos,r0  c;
code lmax  ( l1 l2 -- l1|l2 )  pop r0,sp  cmp r0,tos  movgt tos,r0  c;
[then]

code s->l  ( n -- l )  c;
code l->n  ( l -- n )  c;
code n->a  ( n -- a )  c;
code l->w  ( l -- w )  mov tos,tos,lsl #16  mov tos,tos,lsr #16  c;
code n->w  ( n -- w )  mov tos,tos,lsl #16  mov tos,tos,lsr #16  c;
code w->n  ( n -- w )  mov tos,tos,lsl #16  mov tos,tos,asr #16  c;  \ Sign extend

code l>r  ( l -- )  psh tos,rp  pop tos,sp  c;
code lr>  ( -- l )  psh tos,sp  pop tos,rp  c;

#align-t     constant #align
#acf-align-t constant #acf-align
#talign-t    constant #talign

: align  ( -- )  #align (align)  ;
: taligned  ( adr -- adr' )  #talign round-up  ;
: talign  ( -- )  #talign (align)  ;

: wconstant  ( "name" w -- )  header constant-cf ,  ;

\ LICENSE_BEGIN
\ Copyright (c) 1997 FirmWorks
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
