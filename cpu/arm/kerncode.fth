purpose: Kernel Primitives for ARM-Risc Processors ARM2 ARM250 ARM3 ARM4
\ See license at end of file

\ Allocate and clear the initial user area image
mlabel init-user-area   setup-user-area

\ We create the shared code for the "next" routine so that:
\ a) It will be in RAM for speed (ROM is often slow)
\ b) We can use the user pointer as its base address, for quick jumping

also forth
compilation-base  here-t                        \ Save meta dictionary pointer
\ Use the first version if the user area is separate from the dictionary
\ 0 dp-t !  userarea-t is compilation-base      \ Point it to user area
userarea-t dp-t !                               \ Point it to user area
previous

code-field: (next)   \ Shared code for next; will be copied into user area
\ also meta assembler
   ldr     pc,[ip],/token
end-code
\ previous

also forth
dp-t !  is compilation-base  previous    \ Restore meta dict. pointer

d# 32 equ #user-init      \ Leaves space for the shared "next"

hex meta assembler definitions
\ New: the following 3 definitions aren't in this file

\ The first version is for in-line NEXT
\ :-h next   ldr  pc,[ip],/token  ;-h
:-h next  " mov  pc,up" evaluate  ;-h
:-h c;     next  end-code ;-h
caps on
\ also register-names definitions
\ :-h base r7 ;-h
\ previous

\ Run-time actions for defining words:
\ In the Acorn-ARM2/250/3 implementation all words but code definitions are
\ called by a branch+link instruction. It branches to a relative-inline-
\ address and leaves the old pc/pcr in the link register r14.
\ The pfa of the word is just after the branch+link instruction.
\       bic     r0,link,#0xfc000003   or using the lnk macro
\       lnk     r0
\ Both instructions read the pfa to r0

meta definitions
code-field: douser
   psh     tos,sp
   lnk     r0
   ldr     r0,[r0]
   add     tos,r0,up
c;
code-field: dodoes
   psh     ip,rp
   lnk     ip
c;
code-field: dovalue
   psh     tos,sp
   lnk     r0
   ldr     r0,[r0]
   ldr     tos,[up,r0]
c;
code-field: docolon
   psh     ip,rp
   lnk     ip
c;
code-field: doconstant
   psh     tos,sp
   lnk     r0
   ldr     tos,[r0]
c;
code-field: dodefer
   lnk     r0
   ldr     r0,[r0]
   ldr     pc,[r0,up]
end-code
code-field: do2constant
   lnk     r0

   ldmia   r0,{r1,r2}
   stmdb   sp!,{r1,tos}
   mov     tos,r2
c;
code-field: docreate
   psh     tos,sp
   lnk     tos
c;

code-field: dovariable
   psh     tos,sp
   lnk     tos
c;

\ New: dopointer  (identical to doconstant)
\ New: dobuffer  (identical to doconstant)

:-h compvoc     compile-t <vocabulary> ;-h
code-field: dovocabulary
   ldr     pc,[pc,#-4]
end-code
compvoc         \ cfa of vocabulary is compiled here

\ New: :-h syscall:

\ Meta compiler words to compile code fields for child words
:-h place-cf-t      \ ( adr -- ) compile a branch+link to adr
   here-t -  2/ 2/ 2- 00ffffff and  eb000000 or  l,-t
;-h

\       psh tos,sp  bic tos,lk,#0xfc00.0003
\ :-h push-pfa     ( -- ) e52da004 ,  e3cea3ff , ;-h
\                         psh tos,sp  mov tos,lk
:-h push-pfa       ( -- ) e52da004 ,  e1a0a00e , ;-h
:-h code-cf        ( -- )  ;-h
:-h startdoes      ( -- )  push-pfa
                           dodoes       place-cf-t ;-h
:-h start;code     ( -- )                          ;-h  \ ???
:-h colon-cf       ( -- )  docolon      place-cf-t ;-h
:-h constant-cf    ( -- )  doconstant   place-cf-t ;-h
\ New: :-h buffer-cf   ( -- )  dobuffer   place-cf-t ;-h
\ New: :-h pointer-cf  ( -- )  dopointer  place-cf-t ;-h
:-h create-cf      ( -- )  docreate     place-cf-t ;-h
:-h variable-cf    ( -- )  dovariable   place-cf-t ;-h
:-h user-cf        ( -- )  douser       place-cf-t ;-h
:-h value-cf       ( -- )  dovalue      place-cf-t ;-h
:-h defer-cf       ( -- )  dodefer      place-cf-t ;-h
:-h 2constant-cf   ( -- )  do2constant  place-cf-t ;-h
:-h vocabulary-cf  ( -- )  dovocabulary place-cf-t ;-h

meta definitions

code isdefer  ( xt -- )
   ldr r0,[ip],1cell   \ Get CFA of target word
   ldr r0,[r0,1cell]   \ Get user number
   str tos,[r0,up]     \ Store value
   pop tos,sp          \ Fix stack
c;
code isvalue  ( n -- )
   ldr r0,[ip],1cell   \ Get CFA of target word
   ldr r0,[r0,1cell]   \ Get user number
   str tos,[r0,up]     \ Store value
   pop tos,sp          \ Fix stack
c;
code isuser  ( n -- )
   ldr r0,[ip],1cell   \ Get CFA of target word
   ldr r0,[r0,1cell]   \ Get user number
   str tos,[r0,up]     \ Store value
   pop tos,sp          \ Fix stack
c;
code isconstant  ( n -- )
   ldr r0,[ip],1cell   \ Get CFA of target word
   str tos,[r0,1cell]  \ Store value
   pop tos,sp          \ Fix stack
c;
code isvariable  ( n -- )
   ldr r0,[ip],1cell   \ Get CFA of target word
   str tos,[r0,1cell]  \ Store value
   pop tos,sp          \ Fix stack
c;

code (lit)  ( -- lit )
   psh     tos,sp
   ldr     tos,[ip],1cell
c;
code (dlit)  ( -- d )
   ldmia   ip!,{r0,r1}
   stmdb   sp!,{r0,tos}
   mov     tos,r1
c;
code execute   ( cfa -- )
   mov     r0,tos
   pop     tos,sp
   mov     pc,r0
end-code
code ?execute  ( cfa|0 -- )
   movs    r0,tos
   pop     tos,sp
   movne   pc,r0
c;
code @execute  ( adr -- )
   ldr     r0,[tos]
   pop     tos,sp
   mov     pc,r0
end-code

\ execute-ip  This word will call a block of Forth words given the address
\ of the first word.  It's used, for example, in try blocks where the
\ a word calls 'try' and then the words that follow it are called repeatedly.
\ This word, execute-ip, is used to transfer control back to the caller of
\ try and execute the words that follow the call to try.

\ see forth/lib/try.fth for more details.

code execute-ip  ( word-list-ip -- )
   psh      ip,rp
   mov      ip,tos
   pop      tos,sp
c;

\ Run-time actions for compiling words

code branch  ( -- )
\rel  ldr     r0,[ip]
\rel  add     ip,ip,r0
\abs  ldr     ip,[ip]
c;

code ?branch  ( flag -- )
   cmp     tos,#0
   pop     tos,sp
   addne   ip,ip,1cell
\rel  ldreq   r0,[ip]
\rel  addeq   ip,ip,r0
\abs  ldreq   ip,[ip]
c;

code ?0=branch  ( flag -- )
   cmp     tos,#0
   pop     tos,sp
   inceq   ip,1cell
\rel  ldrne   r0,[ip]
\rel  addne   ip,ip,r0
\abs  ldrne   ip,[ip]
c;


code (loop)  ( -- )
   ldr     r0,[rp]
   incs    r0,1
   strvc   r0,[rp]
\rel  ldrvc   r0,[ip]
\rel  addvc   ip,ip,r0
\abs  ldrvc   ip,[ip]
   nxtvc
   inc    rp,3cells
   inc    ip,1cell
c;

code (+loop)  ( n -- )
   ldr     r0,[rp]
   adds    r0,r0,tos
   strvc   r0,[rp]
   pop     tos,sp
\rel  ldrvc   r0,[ip]
\rel  addvc   ip,ip,r0
\abs  ldrvc   ip,[ip]
   nxtvc
   inc     rp,3cells
   inc     ip,1cell
c;

code (do)  ( l i -- )
   mov     r0,tos
   ldmia   sp!,{r1,tos}    ( r: loop-end-offset l+0x8000 i-l-0x8000 )
   psh     ip,rp          \ save the do offset address
   inc     ip,1cell
   inc     r1,#0x80000000
   sub     r0,r0,r1
   stmdb   rp!,{r0,r1}
c;

code (?do)  ( l i -- )
   mov     r0,tos
   ldmia   sp!,{r1,tos}
   cmp     r1,r0
\rel  ldreq   r0,[ip]
\rel  addeq   ip,ip,r0
\abs  ldreq   ip,[ip]
   nxteq
                ( r: loop-end-offset l+0x8000 i-l-0x8000 )
   psh     ip,rp          \ save the do offset address
   inc     ip,1cell
   inc     r1,#0x80000000
   sub     r0,r0,r1
   stmdb   rp!,{r0,r1}
c;

code i  ( -- n )
   psh      tos,sp
   ldmia    rp,{r0,r1}
   add      tos,r1,r0
c;
code ilimit  ( -- n )
   psh      tos,sp
   ldr      tos,[rp,1cell]
   inc      tos,#0x80000000
c;
code j  ( -- n )
   psh      tos,sp
   add      r2,rp,3cells
   ldmia    r2,{r0,r1}
   add      tos,r1,r0
c;
code jlimit  ( -- n )
   psh      tos,sp
   ldr      tos,[rp,4cells]
   inc      tos,#0x80000000
c;

code (leave)  ( -- )
   inc     rp,2cells        \ get rid of the loop indices
   ldr     ip,[rp],1cell
\rel   ldr     r0,[ip]          \ branch
\rel   add     ip,ip,r0
\abs   ldr     ip,[ip]
c;

code (?leave)  ( f -- )
   cmp     tos,#0
   pop     tos,sp
   nxteq
   inc     rp,2cells     \ get rid of the loop indices
   ldr     ip,[rp],1cell
\rel   ldr     r0,[ip]       \ branch
\rel   add     ip,ip,r0
\abs   ldr     ip,[ip]
c;

code unloop  ( -- )  inc rp,3cells  c;  \ Discard the loop indices

\ Run time code for the case statement
code (of)  ( selector test -- [ selector ] )
   mov     r0,tos
   pop     tos,sp
   cmp     tos,r0
\rel   ldrne   r0,[ip]
\rel   addne   ip,ip,r0
\abs   ldrne   ip,[ip]
   nxtne
   pop     tos,sp
   inc     ip,1cell
c;

\ (endof) is the same as branch, and (endcase) is the same as drop,
\ but redefining them this way makes the decompiler much easier.
code (endof)   ( -- )
\rel   ldr    r0,[ip]
\rel   add    ip,ip,r0
\abs   ldr    ip,[ip]
c;

code (endcase)  ( n -- )  pop tos,sp  c;

\ ($endof) is the same as branch, and ($endcase) is a noop,
\ but redefining them this way makes the decompiler much easier.
\ code ($case)  ( $ -- $ )  c;

code ($endof)   ( -- )
\rel   ldr    r0,[ip]
\rel   add    ip,ip,r0
\abs   ldr    ip,[ip]
c;

code ($endcase)  ( -- )  c;

code digit  ( char base -- digit true | char false )
   mov     r0,tos          \ r0 base
   ldr     r1,[sp]         \ r1 char
   and     r1,r1,#0xff
   cmp     r1,#0x41        \ ascii A
   >= if
      cmp     r1,#0x5b     \ ascii [
      inclt   r1,#0x20
   then
   mov     tos,#0          \ tos false
   decs    r1,#0x30
   nxtlt
   cmp     r1,#10
   >= if
      cmp     r1,#0x31
   nxtlt
      dec     r1,#0x27
   then
   cmp     r1,r0
   nxtge
   str     r1,[sp]
   mvn     tos,#0	\ tos true
c;

code cmove  ( from to cnt -- )
   movs    r0,tos       \ r0 cnt
   ldmia   sp!,{r1,r2,tos}
   nxteq
[ifndef] fixme
   cmp     r1,r2
   nxteq
[then]
   begin
      ldrb    r3,[r2],#1
      strb    r3,[r1],#1
      decs    r0,1
   0= until
c;
code cmove>  ( from to cnt -- )
   movs    r0,tos       \ r0 cnt
   ldmia   sp!,{r1,r2,tos}
   nxteq
[ifndef] fixme
   cmp     r1,r2
   nxteq
[then]
   begin
      decs    r0,1
      ldrb    r3,[r2,r0]
      strb    r3,[r1,r0]
   0= until
c;
[ifdef] use-slow-move
: move  ( src dst len -- )
   >r  2dup u>  if  r> cmove  else  r> cmove>  then
;
[else]
code move  ( src dst cnt -- )
   movs    r0,tos
   ldmia   sp!,{r1,r2,tos}
   nxteq
   cmp     r1,r2        
   nxteq
                \ r0:cnt  r1:dst  r2:src
   < if   \ copy bytes until: src is aligned or cnt=0
      cmp     r0,#4
      >= if
         begin
            ands    r3,r2,#3    
            ldrneb  r3,[r2],#1
            strneb  r3,[r1],#1
            decne   r0,1
         0= until        \ copy until source is word-aligned
         ands     r3,r1,#3
         0= if           \ longword optimizing is possible now

            begin
               decs    r0,4cells
               ldmgeia r2!,{r3,r4,r5,r6}
               stmgeia r1!,{r3,r4,r5,r6}
            < until
            inc     r0,4cells

            begin
               decs    r0,1cell
               ldrge   r3,[r2],1cell
               strge   r3,[r1],1cell
            < until
            inc     r0,1cell
         then
      then
      begin
         decs    r0,1
         ldrgeb  r3,[r2],#1
         strgeb  r3,[r1],#1
      0<= until
   else
      add     r1,r1,r0
      add     r2,r2,r0
      cmp     r0,#4
      >= if
         begin
            ands    r3,r2,#3
            ldrneb  r3,[r2,#-1]!
            strneb  r3,[r1,#-1]!
            decne   r0,1
         0= until        \ copy until source is word-aligned
         ands    r3,r1,#3    
         0= if           \ longword optimizing is possible now

            begin
               decs    r0,4cells
               ldmgedb r2!,{r3,r4,r5,r6}
               stmgedb r1!,{r3,r4,r5,r6}
            < until
            inc     r0,4cells

            begin
               decs    r0,1cell
               ldrge   r3,[r2,~1cell]!
               strge   r3,[r1,~1cell]!
            < until
            inc     r0,1cell

         then
      then
      begin
         decs    r0,1
         ldrgeb  r3,[r2,#-1]!
         strgeb  r3,[r1,#-1]!
      <= until
   then
c;
[then]

code noop  ( -- )   c;

code and  ( n1 n2 -- n3 )  pop r0,sp  and tos,tos,r0  c;
code or   ( n1 n2 -- n3 )  pop r0,sp  orr tos,tos,r0  c;
code xor  ( n1 n2 -- n3 )  pop r0,sp  eor tos,tos,r0  c;
[ifdef] fixme
code not     ( n1 -- n2 )  mvn tos,tos  c;
code invert  ( n1 -- n2 )  mvn tos,tos  c;

code lshift  ( n1 cnt -- n2 )  pop r0,sp  mov tos,r0,lsl tos  c;
code rshift  ( n1 cnt -- n2 )  pop r0,sp  mov tos,r0,lsr tos  c;
code <<      ( n1 cnt -- n2 )  pop r0,sp  mov tos,r0,lsl tos  c;
code >>      ( n1 cnt -- n2 )  pop r0,sp  mov tos,r0,lsr tos  c;
code >>a     ( n1 cnt -- n2 )  pop r0,sp  mov tos,r0,asr tos  c;
code +    ( n1 n2 -- n3 )  pop r0,sp  add tos,tos,r0  c;
code -    ( n1 n2 -- n3 )  pop r0,sp  rsb tos,tos,r0  c;
[else]
code +    ( n1 n2 -- n3 )  pop r0,sp  add tos,tos,r0  c;
code -    ( n1 n2 -- n3 )  pop r0,sp  rsb tos,tos,r0  c;
code not     ( n1 -- n2 )  mvn tos,tos  c;
code invert  ( n1 -- n2 )  mvn tos,tos  c;

code lshift  ( n1 cnt -- n2 )  pop r0,sp  mov tos,r0,lsl tos  c;
code rshift  ( n1 cnt -- n2 )  pop r0,sp  mov tos,r0,lsr tos  c;
code <<      ( n1 cnt -- n2 )  pop r0,sp  mov tos,r0,lsl tos  c;
code >>      ( n1 cnt -- n2 )  pop r0,sp  mov tos,r0,lsr tos  c;
code >>a     ( n1 cnt -- n2 )  pop r0,sp  mov tos,r0,asr tos  c;
[then]

code negate   ( n -- -n )  rsb tos,tos,#0  c;

code ?negate  ( n f -- n | -n )  cmp tos,#0  pop tos,sp  rsblt tos,tos,#0  c;

code abs   ( n -- [n] )  cmp tos,#0  rsbmi tos,tos,#0  c;

code min   ( n1 n2 -- n1|n2 )  pop r0,sp  cmp tos,r0  movgt tos,r0  c;
code umin  ( u1 u2 -- u1|u2 )  pop r0,sp  cmp tos,r0  movcs tos,r0  c;
code max   ( n1 n2 -- n1|n2 )  pop r0,sp  cmp r0,tos  movgt tos,r0  c;
code umax  ( u1 u2 -- u1|u2 )  pop r0,sp  cmp r0,tos  movcs tos,r0  c;

code up@  ( -- adr )  psh tos,sp  mov tos,up  c;
code sp@  ( -- adr )  psh tos,sp  mov tos,sp  c;
code rp@  ( -- adr )  psh tos,sp  mov tos,rp  c;
code up!  ( adr -- )  mov up,tos  pop tos,sp  c;
code sp!  ( adr -- )  mov sp,tos  pop tos,sp  c;
code rp!  ( adr -- )  mov rp,tos  pop tos,sp  c;

code >r   ( n -- )  psh tos,rp  pop tos,sp  c;
code r>   ( -- n )  psh tos,sp  pop tos,rp  c;
code r@   ( -- n )  psh tos,sp  ldr tos,[rp]  c;

code 2>r  ( n1 n2 -- )  mov r0,tos  ldmia sp!,{r1,tos}  stmdb rp!,{r0,r1}  c;
code 2r>  ( -- n1 n2 )  ldmia rp!,{r0,r1}  stmdb sp!,{r1,tos}  mov tos,r0  c;
code 2r@  ( -- n1 n2 )  ldmia rp,{r0,r1}   stmdb sp!,{r1,tos}  mov tos,r0  c;

code >ip  ( n -- )  psh tos,rp  pop tos,sp  c;
code ip>  ( -- n )  psh tos,sp  pop tos,rp  c;
code ip@  ( -- n )  psh tos,sp  ldr tos,[rp]  c;

: ip>token  ( ip -- token-adr )  /token -  ;

code exit    ( -- )  ldr ip,[rp],1cell  c;
code unnest  ( -- )  ldr ip,[rp],1cell  c;

code ?exit  ( flag -- )  cmp tos,#0  pop tos,sp  ldrne ip,[rp],1cell  c;

code tuck  ( n1 n2 -- n2 n1 n2 )  pop r0,sp  stmdb sp!,{r0,tos}  c;

code nip   ( n1 n2 -- n2 )  inc sp,1cell  c;

[ifdef] notdef
code lwsplit  ( n -- wlow whigh )
\   mov     r0,#0xffff
   mov     r0,#0xff
   orr     r0,r0,#0xff00
   and     r1,tos,r0
   psh     r1,sp
   mov     tos,tos,lsr #0x10
c;
code wljoin  ( w.low w.high -- n )
   pop     r0,sp
   orr     tos,r0,tos,lsl #0x10
c;
[then]
code wflip  ( n1 -- n2 )  mov tos,tos,ror #0x10   c;
code flip   ( w1 -- w2 )
   mov     r0,tos,lsr #8
   and     r1,tos,#0xff
   orr     tos,r0,r1,lsl #8
c;

code 0=   ( n -- f )  subs tos,tos,#1  sbc tos,tos,tos  c;
code 0<>  ( n -- f )  cmp tos,#0  mvnne tos,#0  c;
code 0<   ( n -- f )  mov tos,tos,asr #0  c;
code 0>=  ( n -- f )  mvn tos,tos,asr #0  c;
code 0>   ( n -- f )  bics tos,tos,tos,asr #0  mvnne tos,#0  c;
code 0<=  ( n -- f )  cmp tos,#0  mvnle tos,#0  movgt tos,#0  c;

code >    ( n1 n2 -- f )  pop r0,sp  cmp r0,tos  mvngt tos,#0  movle tos,#0 c;
code <    ( n1 n2 -- f )  pop r0,sp  cmp r0,tos  mvnlt tos,#0  movge tos,#0 c;
code =    ( n1 n2 -- f )  pop r0,sp  cmp r0,tos  mvneq tos,#0  movne tos,#0 c;
[ifdef] fixme
code <>   ( n1 n2 -- f )  pop r0,sp  subs tos,r0,tos  mvnne tos,#0  c;
code u>   ( u1 u2 -- f )  pop r0,sp  subs tos,tos,r0  sbc tos,tos,tos  c;
code u<=  ( u1 u2 -- f )  pop r0,sp  cmp r0,tos  mvnls tos,#0  movhi tos,#0 c;
code u<   ( u1 u2 -- f )  pop r0,sp  subs tos,r0,tos  sbc tos,tos,tos  c;
code u>=  ( u1 u2 -- f )  pop r0,sp  cmp r0,tos  mvncs tos,#0  movcc tos,#0 c;
code >=   ( n1 n2 -- f )  pop r0,sp  cmp r0,tos  mvnge tos,#0  movlt tos,#0 c;
code <=   ( n1 n2 -- f )  pop r0,sp  cmp r0,tos  mvnle tos,#0  movgt tos,#0 c;
[else]
code u<=  ( u1 u2 -- f )  pop r0,sp  cmp r0,tos  mvnls tos,#0  movhi tos,#0 c;
code u>=  ( u1 u2 -- f )  pop r0,sp  cmp r0,tos  mvncs tos,#0  movcc tos,#0 c;
code >=   ( n1 n2 -- f )  pop r0,sp  cmp r0,tos  mvnge tos,#0  movlt tos,#0 c;
code <=   ( n1 n2 -- f )  pop r0,sp  cmp r0,tos  mvnle tos,#0  movgt tos,#0 c;
code <>   ( n1 n2 -- f )  pop r0,sp  subs tos,r0,tos  mvnne tos,#0  c;
code u>   ( u1 u2 -- f )  pop r0,sp  subs tos,tos,r0  sbc tos,tos,tos  c;
code u<   ( u1 u2 -- f )  pop r0,sp  subs tos,r0,tos  sbc tos,tos,tos  c;
[then]

code drop  ( n1 n2 -- n1 )  pop tos,sp  c;
code dup   ( n1 -- n1 n1 )  psh tos,sp  c;
\ code ?dup  ( n1 -- 0 | n1 n1 )  cmp tos,#0  pshne tos,sp  c;
code over  ( n1 n2 -- n1 n2 n1 )  psh tos,sp  ldr tos,[sp,1cell]  c;
code swap  ( n1 n2 -- n2 n1 )  ldr r0,[sp]  str tos,[sp]  mov tos,r0  c;
code rot   ( n1 n2 n3 -- n2 n3 n1 )
   mov       r0,tos
   ldmia     sp!,{r1,tos}
   stmdb     sp!,{r0,r1}
c;
code -rot  ( n1 n2 n3 -- n3 n1 n2 )
   ldmia     sp!,{r1,r2}
   stmdb     sp!,{r2,tos}
   mov       tos,r1
c;
code 2drop  ( n1 n2 -- )           inc sp,1cell   pop tos,sp  c;
code 3drop  ( n1 n2 n3 -- )        inc sp,2cells  pop tos,sp  c;
code 4drop  ( n1 n2 n3 n4 -- )     inc sp,3cells  pop tos,sp  c;
code 5drop  ( n1 n2 n3 n4 n5 -- )  inc sp,4cells  pop tos,sp  c;
code 2dup   ( n1 n2 -- n1 n2 n1 n2 )  ldr r0,[sp]  stmdb sp!,{r0,tos}  c;
code 2over  ( n1 n2 n3 n4 -- n1 n2 n3 n4 n1 n2 )
   ldr       r0,[sp,2cells]
   stmdb     sp!,{r0,tos}
   ldr       tos,[sp,3cells]
c;
code 2swap  ( n1 n2 n3 n4 -- n3 n4 n1 n2 )
   mov       r0,tos
   ldmia     sp!,{r1,r2,r3}
   stmdb     sp!,{r0,r1}
   psh       r3,sp
   mov       tos,r2
c;
code 3dup   ( n1 n2 n3 -- n1 n2 n3 n1 n2 n3 )
   ldmia     sp,{r0,r1}
   stmdb     sp!,{r0,r1,tos}
c;
code pick   ( nm ... n1 n0 k -- nm ... n1 n0 nk )  ldr tos,[sp,tos,lsl #2]  c;

\ code roll  ( n -- )
\   add       r1,sp,tos,lsl #2
\   ldr       tos,r1,1cell  da
\   begin
\      ldria     r0,r1,1cell
\      str       r0,[r1],-2cells
\      cmp       r1,sp
\   < until
\   inc       sp,1cell
\ c;

\ code between  ( n min max -- flag )
\   mov       r1,tos
\   ldmia     sp!,{r0,r2}
\   mov       tos,#0
\   cmp       r2,r0
\   nxtlt
\   cmp       r2,r1
\   mvnle     tos,#0
\ c;

code 1+   ( n -- n+1 )   inc tos,1     c;
code 2+   ( n -- n+2 )   inc tos,2     c;
code 1-   ( n -- n-1 )   dec tos,1     c;
code 2-   ( n -- n-2 )   dec tos,2     c;
code 2/   ( n -- n/2 )   mov tos,tos,asr #1  c;
code u2/  ( u -- u/2 )   mov tos,tos,lsr #1  c;
code 2*   ( n -- 2n )    mov tos,tos,lsl #1  c;
code 4*   ( n -- 4n )    mov tos,tos,lsl #2  c;
code 8*   ( n -- 8n )    mov tos,tos,lsl #3  c;

code on   ( adr -- )  mvn r0,#0  str r0,[tos]  pop tos,sp  c;
code off  ( adr -- )  mov r0,#0   str r0,[tos]  pop tos,sp  c;
code +!   ( n adr -- )
   mov       r0,tos
   ldmia     sp!,{r1,tos}
   ldr       r2,[r0]
   add       r2,r2,r1
   str       r2,[r0]
c;

code l@  ( adr -- n )  ldr tos,[tos]  c;
[ifdef] arm4
\ Halfword access
code w!  ( w adr -- )
   pop       r0,sp
   h# e1ca00b0 asm,  \ strh r0,tos
   pop       tos,sp
c;
code w@  ( adr -- w )
   h# e1daa0b0 asm,   \ ldrh tos,tos
c;
code <w@  ( adr -- w )
   h# e1daa0f0 asm,   \ ldrsh tos,tos
c;

\ code w@         ( adr -- n )  ldrh  tos,[tos]   c;
\ code <w@        ( adr -- n )  ldrsh tos,[tos]   c;
\ code w!         ( n adr -- )
\   pop       r0,sp
\   strh      r0,[tos]
\   pop       tos,sp
\ c;
[else]
code w@   ( adr -- n )  ldr tos,[tos]  c;
code <w@  ( adr -- n )  ldr tos,[tos]  c;
code w!   ( n adr -- )  pop r0,sp  str r0,[tos]  pop tos,sp  c;
[then]
code l!   ( n adr -- )  pop r0,sp  str r0,[tos]  pop tos,sp  c;
code @    ( adr -- n )  ldr tos,[tos]  c;

code unaligned-@  ( adr -- n )
   bic       r1,tos,#3
   ldmia     r1,{r2,r3}
   and       r1,tos,#3
   movs      r1,r1,lsl #3
   movne     r2,r2,lsr r1
   rsbne     r1,r1,#0x20
   orrne     r2,r2,r3,lsl r1
   mov       tos,r2
c;
code c@  ( adr -- char )  ldrb tos,[tos]  c;
code !   ( n adr -- )  pop r0,sp  str r0,[tos]  pop tos,sp  c;
code unaligned-!  ( n adr -- )
   mov       r5,tos         \ r5: adr
   ldmia     sp!,{r4,tos}
   strb      r4,[r5],#1
   mov       r4,r4,ror #8
   strb      r4,[r5],#1
   mov       r4,r4,ror #8
   strb      r4,[r5],#1
   mov       r4,r4,ror #8
   strb      r4,[r5],#1
c;

code t!  ( n adr -- )
   mov       r5,tos         \ r5: adr
   ldmia     sp!,{r4,tos}
   strb      r4,[r5],#1
   mov       r4,r4,ror #8
   strb      r4,[r5],#1
   mov       r4,r4,ror #8
   strb      r4,[r5],#1
c;
code t@  ( adr -- w )
   ldrb      r0,[tos]
   ldrb      tos,[tos,#1]
   orr       r0,r0,tos,lsl #8
   ldrb      tos,[tos,#2]
   orr       tos,r0,tos,lsl #16
c;

code unaligned-w@  ( adr -- w )
   ldrb      r0,[tos]
   ldrb      tos,[tos,#1]

   orr       tos,r0,tos,lsl #8
c;
code unaligned-w!  ( w adr -- )
   pop       r0,sp
   strb      r0,[tos]
   mov       r0,r0,ror #8
   strb      r0,[tos,#1]

   pop       tos,sp
c;
: unaligned-l@  ( adr -- l )  unaligned-@  ;
: unaligned-l!  ( l adr -- )  unaligned-!  ;
: unaligned-d!  ( d adr -- )  tuck na1+ unaligned-!  unaligned-!  ;
: d@            ( adr -- d )  dup @  swap na1+ @  ;
: d!            ( d adr -- )  tuck na1+ ! ! ;

code c!  ( char adr -- )  pop r0,sp  strb r0,[tos]  pop tos,sp  c;
code 2@  ( adr -- n-high n-low )
   ldr       r0,[tos,1cell]
   psh       r0,sp
   ldr       tos,[tos]
c;
code 2!  ( n-high n-low adr -- )
   ldmia     sp!,{r0,r1}
   stmia     tos,{r0,r1}
   pop       tos,sp
c;

code d+  ( d1 d2 -- d1+d2 )
   ldmia     sp!,{r0,r1,r2}           \ tos r0       r1 r2
   adds      r0,r0,r2
   adc       tos,tos,r1
   psh       r0,sp
c;

code d-  ( d1 d2 -- d1-d2 )
   ldmia     sp!,{r0,r1,r2}     \ tos r0       r1 r2
   subs      r0,r2,r0
   sbc       tos,r1,tos
   psh       r0,sp
c;
code d<  ( d1 d2 -- f )
   ldmia     sp!,{r0,r1,r2}     \ tos r0       r1 r2
   subs      r2,r2,r0
   sbcs      r1,r1,tos
   movge     tos,#0
   mvnlt     tos,#0
c;
code d>=  ( d1 d2 -- f )
   ldmia     sp!,{r0,r1,r2}     \ tos r0       r1 r2
   subs      r2,r2,r0
   sbcs      r1,r1,tos
   movlt     tos,#0
   mvnge     tos,#0
c;
code d>  ( d1 d2 -- f )
   ldmia     sp!,{r0,r1,r2}     \ tos r0       r1 r2
   subs      r2,r0,r2
   sbcs      r1,tos,r1
   movge     tos,#0
   mvnlt     tos,#0
c;
code d<=  ( d1 d2 -- f )
   ldmia     sp!,{r0,r1,r2}     \ tos r0       r1 r2
   subs      r2,r0,r2
   sbcs      r1,tos,r1
   movlt     tos,#0
   mvnge     tos,#0
c;
code du<  ( d1 d2 -- f )
   ldmia     sp!,{r0,r1,r2}     \ tos r0       r1 r2
   subs      r2,r2,r0
   sbcs      r1,r1,tos
   sbc       tos,tos,tos
c;

code s>d  ( n -- d )
   psh       tos,sp
   mov       tos,tos,asr #0
c;
: u>d  ( n -- d )  0  ;
code dnegate  ( d -- -d )
   pop       r0,sp
   rsbs      r0,r0,#0
   rsc       tos,tos,#0
   psh       r0,sp
c;
code ?dnegate  ( d flag -- d )
   cmp       tos,#0
   pop       tos,sp
   < if
      pop       r0,sp
      rsbs      r0,r0,#0
      rsc       tos,tos,#0
      psh       r0,sp
   then
c;

code dabs  ( d -- d )
   cmp       tos,#0
   < if
      pop       r0,sp
      rsbs      r0,r0,#0
      rsc       tos,tos,#0
      psh       r0,sp
   then
c;
code d0=  ( d -- f )
   pop       r0,sp
   orrs      r0,r0,tos
   mvneq     tos,#0
   movne     tos,#0
c;
code d0<>  ( d -- f )
   pop       r0,sp
   orrs      r0,r0,tos
   mvnne     tos,#0
   moveq     tos,#0
c;
code d0<  ( d -- f )
   inc       sp,1cell
   mov       tos,tos,asr #0
c;
code d2*  ( d1 -- d2 )
   pop       r0,sp
   mov       tos,tos,lsl #1
   orr       tos,tos,r0,lsr #31
   mov       r0,r0,lsl #1
   psh       r0,sp
c;
code d2/  ( s1 -- d2 )
   pop       r0,sp
   movs      tos,tos,lsr #1
   mov       r0,r0,ror #0
   psh       r0,sp
c;
: d=    ( d1 d2 -- flag )  d- d0=  ;
: d<>   ( d1 d2 -- flag )  d=  0=  ;

: (d.)  (  d -- adr len )  tuck dabs <# #s rot sign #>  ;
: (ud.) ( ud -- adr len )  <# #s rot #>  ;

: d.    (  d -- )     (d.) type space  ;
: ud.   ( ud -- )    (ud.) type space  ;
: ud.r  ( ud n -- )  >r (ud.) r> over - spaces type  ;

: dmax  ( xd1 xd2 -- )  2over 2over d<  if  2swap  then  2drop  ;
: dmin  ( xd1 xd2 -- )  2over 2over d<  0=  if  2swap  then  2drop  ;

: m+    ( d1|ud1 n -- )  s>d  d+  ;
: 2rot  ( d1 d2 d3 -- d2 d3 d1 )  2>r 2swap 2r> 2swap  ;
: 2nip  ( $1 $2 -- $2 )  2swap 2drop  ;

: drot  ( d1 d2 d3 -- d2 d3 d1 )  2>r 2swap 2r> 2swap  ;
: -drot ( d1 d2 d3 -- d3 d1 d2 )  drot drot  ;
: dinvert  ( d1 -- d2 )  swap invert  swap invert  ;

: dlshift  ( d1 n -- d2 )
   tuck lshift >r                           ( low n  r: high2 )
   2dup bits/cell  swap - rshift  r> or >r  ( low n  r: high2' )
   lshift r>                                ( d2 )
;
: drshift  ( d1 n -- d2 )
   2dup rshift >r                           ( low high n  r: high2 )
   tuck  bits/cell swap - lshift            ( low n low2  r: high2 )
   -rot  rshift  or                         ( low2  r: high2 )
   r>                                       ( d2 )
;
: d>>a  ( d1 n -- d2 )
   2dup rshift >r                           ( low high n  r: high2 )
   tuck  bits/cell swap - lshift            ( low n low2  r: high2 )
   -rot  >>a  or                            ( low2  r: high2 )
   r>                                       ( d2 )
;
: du*  ( d1 u -- d2 )  \ Double result
   tuck u* >r     ( d1.lo u r: d2.hi )
   um*  r> +      ( d2 )
;
: du*t  ( ud.lo ud.hi u -- res.lo res.mid res.hi )  \ Triple result
   tuck um*  2>r  ( ud.lo u          r: res.mid0 res.hi0 )
   um*            ( res.lo res.mid1  r: res.mid0 res.hi0 )
   0  2r> d+      ( res.lo res.mid res.hi )
;

code fill       ( adr cnt char -- )
   orr       r2,tos,tos,lsl #8 
   ldmia     sp!,{r0,r1,tos}	\ r0-cnt r1-adr r2-data
   cmp       r0,#4
   > if
      orr    r2,r2,r2,lsl #0x10	\ Propagate character into high halfword
      begin			\ Fill initial unaligned part
         ands      r3,r1,#3
         decne     r0,1
         strneb    r2,[r1],#1
      0= until
      decs    r0,4
      begin
         strge   r2,[r1],#4
         decges  r0,4
      < until
      inc     r0,4
   then
   begin
      decs      r0,1
      strgeb    r2,[r1],#1
   < until
c;

code wfill       ( adr cnt w -- )
   mov       r2,tos
   ldmia     sp!,{r0,r1,tos}  \ r0-cnt r1-adr r2-data
   begin
      decs    r0,2
      strgeh  r2,[r1],#2
   < until
c;

\ tfill fills with a 3-byte value.  It's useful for 24bpp frame buffers
code tfill       ( adr cnt t -- )
   mov       r2,tos
   ldmia     sp!,{r0,r1,tos}  \ r0-cnt r1-adr r2-data
   mov       r3,r2,lsr #8
   mov       r4,r2,lsr #16
   begin
      decs    r0,3
      strgeb  r2,[r1],#1
      strgeb  r3,[r1],#1
      strgeb  r4,[r1],#1
   < until
c;


code lfill       ( adr cnt l -- )
   mov       r2,tos
   ldmia     sp!,{r0,r1,tos} \ r0-cnt r1-adr r2-data
   begin
      decs    r0,4
      strge   r2,[r1],#4
   < until
c;

\ Skip initial occurrences of bvalue, returning the residual length
code bskip  ( adr len bvalue -- residue )
   ldmia  sp!,{r0,r1}  \ r0-len r1-adr tos-bvalue
   mov    r2,tos       \ r2-bvalue
   movs   tos,r0       \ tos-len
   nxteq               \ Bail out if len=0

   begin
      ldrb   r0,[r1],#1
      cmp    r0,r2
      nxtne
      decs   tos,1
   = until
c;

\ Skip initial occurrences of lvalue, returning the residual length
code lskip  ( adr len lvalue -- residue )
   ldmia  sp!,{r0,r1}  \ r0-len r1-adr tos-lvalue
   mov    r2,tos       \ r2-lvalue
   movs   tos,r0       \ tos-len
   nxteq               \ Bail out if len=0

   begin
      ldr    r0,[r1],#4
      cmp    r0,r2
      nxtne
      decs   tos,4
   = until
c;

\ Find the first occurence of bvalue, returning the residual string
code bscan  ( adr len bvalue -- adr' len' )
   ldmia  sp!,{r0,r1}  \ r0-len r1-adr tos-bvalue
   mov    r2,tos       \ r2-bvalue
   movs   tos,r0       \ tos-len
   psheq  r1,sp
   nxteq               \ Bail out if len=0

   begin
      ldrb   r0,[r1],#1
      cmp    r0,r2
      deceq  r1,#1
      psheq  r1,sp
      nxteq
      decs   tos,1
   = until
   psh  r1,sp
c;

\ Find the first occurrence of wvalue, returning the residual string
code wscan  ( adr len wvalue -- adr' len' )
   ldmia  sp!,{r0,r1}  \ r0-len r1-adr tos-lvalue
   mov    r2,tos       \ r2-lvalue
   movs   tos,r0       \ tos-len
   psheq  r1,sp
   nxteq               \ Bail out if len=0

   begin
      ldrh   r0,[r1],#2
      cmp    r0,r2
      deceq  r1,#2
      psheq  r1,sp
      nxteq
      decs   tos,2
   <= until
   psh  r1,sp
   mov  tos,#0
c;

\ Find the first occurrence of lvalue, returning the residual string
code lscan  ( adr len lvalue -- adr' len' )
   ldmia  sp!,{r0,r1}  \ r0-len r1-adr tos-lvalue
   mov    r2,tos       \ r2-lvalue
   movs   tos,r0       \ tos-len
   psheq  r1,sp
   nxteq               \ Bail out if len=0

   begin
      ldr    r0,[r1],#4
      cmp    r0,r2
      deceq  r1,#4
      psheq  r1,sp
      nxteq
      decs   tos,4
   <= until
   psh  r1,sp
   mov  tos,#0
c;


\ code /link  ( -- /link )  psh tos,sp   mov tos,/link  c;

code /char  ( -- 1 )  psh tos,sp  mov tos,#1  c;
code /cell  ( -- 4 )  psh tos,sp  mov tos,1cell  c;

code chars  ( n1 -- n1 )  c;
code cells  ( n -- 4n )  mov  tos,tos,lsl #2  c;
code char+  ( adr -- adr1 )  inc tos,#1     c;
code cell+  ( adr -- adr1 )  inc tos,1cell  c;
code chars+  ( adr index -- adr1 )  pop r0,sp  add tos,r0,tos  c;
code cells+  ( adr index -- adr1 )  pop r0,sp  add tos,r0,tos,lsl #2  c;

code next-char  ( addr u -- addr-char u+char )
   dec       tos,1
   pop       r0,sp
   inc       r0,1
   psh       r0,sp
c;

code n->l  ( n.unsigned -- l )  c;
code ca+  ( adr index -- adr1 )  pop r0,sp  add tos,r0,tos  c;
code wa+  ( adr index -- adr1 )  pop r0,sp  add tos,r0,tos,lsl #1  c;
code la+  ( adr index -- adr1 )  pop r0,sp  add tos,r0,tos,lsl #2  c;
code na+  ( adr index -- adr1 )  pop r0,sp  add tos,r0,tos,lsl #2  c;
code ta+  ( adr index -- adr1 )  pop r0,sp  add tos,r0,tos,lsl #2  c;

code ca1+  ( adr -- adr1 )  inc tos,1  c;
code wa1+  ( adr -- adr1 )  inc tos,2  c;
code la1+  ( adr -- adr1 )  inc tos,1cell  c;
code na1+  ( adr -- adr1 )  inc tos,1cell  c;
code ta1+  ( adr -- adr1 )  inc tos,1cell  c;

code /c  ( -- 1 )  psh tos,sp  mov tos,#1  c;
code /w  ( -- 4 )  psh tos,sp  mov tos,#2  c;
code /l  ( -- 4 )  psh tos,sp  mov tos,#4  c;
code /n  ( -- 4 )  psh  tos,sp  mov tos,1cell  c;

code /c*  ( n1 -- n1 )  c;
code /w*  ( n1 -- n2 )  mov tos,tos,lsl #1  c;
code /l*  ( n1 -- n2 )  mov tos,tos,lsl #2  c;
code /n*  ( n1 -- n2 )  mov tos,tos,lsl #2  c;

code /t*  ( n1 -- n2 )  add tos,tos,tos,lsl #1  c;
code 3*   ( n1 -- n2 )  add tos,tos,tos,lsl #1  c;

8 equ nvocs     \ Number of slots in the search order

code upc  ( char -- upper-case-char )
   and       tos,tos,#0xff
   cmp       tos,#0x61      \ ascii a
   nxtlt
   cmp       tos,#0x7b      \ ascii {
   declt     tos,#0x20
c;
code lcc  ( char -- lower-case-char )
   and       tos,tos,#0xff
   cmp       tos,#0x41      \ ascii A
   nxtlt
   cmp       tos,#0x5b      \ ascii [
   inclt     tos,#0x20
c;
code comp  ( adr1 adr2 len -- -1 | 0 | 1 )
   inc       tos,1                \ tos length
   ldmia     sp!,{r0,r1}
   begin
      decs      tos,#1
   0<> while
      ldrb      r2,[r0],#1
      ldrb      r3,[r1],#1
      cmp       r3,r2
      movgt     tos,#1
      mvnlt     tos,#0
      nxtne
   repeat
   mov       tos,#0
c;
code caps-comp  ( adr1 adr2 len -- -1 | 0 | 1 )
   add     tos,tos,#1          \ tos length
   ldmia   sp!,{r0,r1}
   begin
      decs     tos,1
   0<> while
      mov     r2,#0
      ldrb    r2,[r0],#1
      cmp     r2,#0x41     \ ascii A
      > if
         cmp     r2,#0x5b  \ ascii [
         inclt   r2,#0x20
      then
      mov     r3,#0
      ldrb    r3,[r1],#1
      cmp     r3,#0x41     \ ascii A
      > if
         cmp     r3,#0x5b  \ ascii [
         inclt   r3,#0x20
      then
      cmp     r3,r2
      movgt   tos,#1
      mvnlt   tos,#0
      nxtne
   repeat
   mov     tos,#0
c;
code pack  ( str-adr len to -- to )
   mov     r0,tos        \ to
   ldmia   sp!,{r1,r2}
   ands    r1,r1,#0xff   \ set length flag
   strb    r1,[r0],#1
   0<> if
      begin
         ldrb    r3,[r2],#1
         strb    r3,[r0],#1
         decs    r1,#1
      0= until
   then
   mov     r1,#0
   strb    r1,[r0],#1
c;

code (')  ( -- n )  psh tos,sp  ldr tos,[ip],1cell  c;

\ Modifies caller's ip to skip over an in-line string
code skipstr  ( -- adr len)
   psh     tos,sp
   ldr     r0,[rp]
   ldrb    tos,[r0],#1
   psh     r0,sp
   add     r0,r0,tos
   inc     r0,1cell
   bic     r0,r0,#3
   str     r0,[rp]
c;
code (")  ( -- adr len)
   psh     tos,sp
   ldrb    tos,[ip],#1
   psh     ip,sp
   add     ip,ip,tos
   inc     ip,#4
   bic     ip,ip,#3
c;
code (n")  ( -- adr len)
   psh     tos,sp
   ldr     tos,[ip],#4
   psh     ip,sp
   add     ip,ip,tos
   inc     ip,#4
   bic     ip,ip,#3
c;
code traverse   ( adr direction -- adr' )
   mov     r0,tos         \ direction r0
   pop     tos,sp         \ adr -> tos
   add     tos,tos,r0
   begin
      ldrb    r1,[tos]
      and     r1,r1,#0x80
   0= while
      add     tos,tos,r0
   repeat
c;
code count      ( adr -- adr1 cnt )
   mov     r0,tos
   ldrb    tos,[r0],#1
   psh     r0,sp
c;
code ncount      ( adr -- adr1 cnt )
   mov     r0,tos
   ldr     tos,[r0],#4
   psh     r0,sp
c;

: instruction!  ( n adr -- )  tuck l!  /cell  sync-cache  ;

\ a colon-magic doesn't exist in this ARM version
: place-cf      ( adr -- )
   acf-align
   here - 2/ 2/ 2-   00ffffff and  eb000000 or
   here  /cell allot  instruction!
;
\ place a branch+link to target at adr
: put-cf   ( target adr -- )
   dup >r - 2/ 2/ 2-  00ffffff and  eb000000 or
   r> instruction!
;

: instruction,  ( n -- )  here /cell allot  instruction!  ;
: push-pfa  ( -- adr )
   e52da004  instruction,   \ psh tos,sp
\   e3cea3ff  instruction,   \ bic tos,lk,#0xfc00.0003
   e1a0a00e  instruction,   \ mov tos,lk
;

: origin-  ( adr -- offset )  origin -  ;
: origin+  ( offset -- adr )  origin +  ;

: code-cf  ( -- )   acf-align  ;
: code?  ( acf -- f )  \ True if the acf is for a code word
   @ h# ff000000 and  h# eb000000 <>
;
: >code  ( acf-of-code-word -- address-of-start-of-machine-code )  ;

\ Ip is assumed to point to (;code .  flag is true if
\ the code at ip is a does> clause as opposed to a ;code clause.

: colon-cf      ( -- )     docolon      origin+  place-cf  ;
: colon-cf?     ( adr -- flag )  word-type  docolon origin +  =  ;
: docolon       ( -- adr ) docolon      origin+ ;
: create-cf     ( -- )     docreate     origin+  place-cf  ;
: variable-cf   ( -- )     dovariable   origin+  place-cf  ;
: user-cf       ( -- )     douser       origin+  place-cf  ;
: value-cf      ( -- )     dovalue      origin+  place-cf  ;
: constant-cf   ( -- )     doconstant   origin+  place-cf  ;
: defer-cf      ( -- )     dodefer      origin+  place-cf  ;
: 2constant-cf  ( -- )     do2constant  origin+  place-cf  ;
: place-does    ( -- )     push-pfa     dodoesaddr token@ place-cf ;

: does-ip?  ( ip -- ip' flag )
   dup token@ ['] (does>) =  if  4 na+ true  else  na1+ false  then
;

: place-;code  ( -- )  ;

\ next is redefined in cpu/arm/code.fth so that it can be conditional
\ Version for next in user area
: next  ( -- )  h# e1a0f009 instruction,  ;
\ Version for in-line next
\ : next  ( -- )  h# e498f004 instruction,  ;

\ New: : pointer-cf  ( -- )  dopointer  literal origin+  place-cf  ;
\ New: : buffer-cf   ( -- )  dobuffer   literal origin+  place-cf  ;

\ uses  sets the code field of the indicated word so that
\ it will execute the code at action-clause-adr
: uses  ( action-clause-adr xt -- )  put-cf  ;

\ used  sets the code field of the most-recently-defined word so that
\ it executes the code at action-clause-adr
: used  ( action-clause-adr -- )  lastacf  uses  ;

\ operators using addresses, links and tokens
/a-t constant /a
: a@  ( adr -- adr )  l@ ;
: a!  ( adr adr -- )  set-relocation-bit l! ;
: a,  ( adr -- )      here  /a allot    a!  ;
\ : link@  ( adr -- adr )  @  ;
\ : link!  ( adr adr -- )  a! ;
\ : link,  ( adr -- )  a, ;
\ : link-here  ( adr -- )  align here  over @ link,  swap !  ;

/n-t constant /branch

\rel : branch,  ( offset -- )         ,  ;
\rel : branch!  ( offset where -- )   !  ;
\rel : branch@  ( where -- offset )   @  ;
\rel : >target  ( ip -- target )  ta1+ dup branch@ +  ( h# ffffc and )  ;
\abs : branch,  ( offset -- )         here +  a,  ;
\abs : branch!  ( offset where -- )   swap over +  swap a!  ;
\abs : branch@  ( where -- offset )   @  ;
\abs : >target  ( ip -- target )  ta1+ branch@  ;

/token constant /token
: token@  ( adr -- cfa ) l@  ;
: token!  ( cfa adr -- )  set-relocation-bit l!  ;
: token,  ( cfa -- )      here  /token allot  token!  ;

\ XXX this is a kludgy way to make a relocated constant
origin-t constant origin  /n negate allot-t  origin-t token,-t

: null  ( -- token )  origin  ;
: !null-link   ( adr -- )  null swap link!  ;
: !null-token  ( adr -- )  null swap token!  ;
: non-null?  ( link -- false | link true )
   dup origin =  if  drop false  else  true  then
;
: get-token?     ( adr -- false | acf  true )  token@ non-null?  ;
: another-link?  ( adr -- false | link true )  link@  non-null?  ;

\ The "word type" is a number which distinguishes one type of word
\ from another.  This is highly implementation-dependent.
\ For the ARM Implementation, this always returns the adress of the
\ code sequence for that word.

code >body  ( cfa -- pfa )
   ldr     r0,[tos]
   and     r0,r0,#0xff000000
   cmp     r0,#0xeb000000
   inceq   tos,1cell
c;
code body>  ( pfa -- cfa )
   ldr     r0,[tos,~/token]
   and     r0,r0,#0xff000000
   cmp     r0,#0xeb000000
   deceq   tos,1cell
c;
code word-type  ( cfa -- word-type )
   ldr     r0,[tos]
   and     r1,r0,#0xff000000
   cmp     r1,#0xeb000000
   moveq   r0,r0,lsl #8
   moveq   r0,r0,asr #6
   inceq   r0,8
   addeq   tos,tos,r0
\   bic     tos,tos,#0xfc000003
c;

4 constant /user#

\ Move to a machine alignment boundary. All ARM-Processors need
\ 32-bit alignment
: aligned      ( adr -- adr' )  /n round-up  ;
: acf-aligned  ( adr -- adr' )  aligned  ;
: acf-align    ( adr -- adr' )
   begin  here #acf-align 1- and  while  0 c,  repeat
   here 'lastacf token!
;

only forth also labels also meta
also arm-assembler helpers also arm-assembler definitions
:-h 'body   ( "name" -- variable-apf  adt-immed )
   [ also meta ]-h  '  ( acf-of-user-variable )  >body-t
   [ previous  ]-h  adt-immed
;-h
:-h 'code   ( "name" -- code-word-acf adt-immed )
   [ also meta ]-h  '  ( acf-of-user-variable )
   [ previous  ]-h adt-immed
;-h
:-h 'user#  ( "name" -- user#         adt-immed )
   [ also meta ]-h  '  ( acf-of-user-variable )  >body-t @-t
   [ previous  ]-h adt-immed
;-h
:-h 'user  ( "name" -- )
\   [ also register-names ] up [ previous ] drop  ( reg# )
   up drop    ( reg# )
   d# 16 lshift iop
   'user#				     ( value adt-immed )
   drop  d# 12 ?#bits iop
;
only forth also labels also meta also definitions

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
