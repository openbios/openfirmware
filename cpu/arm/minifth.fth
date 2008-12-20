purpose: Forth-like peek/poke/memory-test monitor using only registers
\ See license at end of file

\ Requires the following external definitions:
\ isa-io-pa  ( -- n )	     \ Returns the base address of IO space
\ init-serial  ( -- )        \ May destroy r0-r3
\ getchar  ( -- r0: char )   \ May destroy r0-r3
\ putchar  ( r0: char -- )   \ May destroy r0-r3

\ The following code must run entirely from registers.  The following
\ register allocation conventions are used:
\  r0-r3	Argument passing and return, scratch registers for subroutines
\  r4		Return address for level 1 routines, scratch use for level 2+
\  r5		Return address for level 2 routines, scratch use for level 3+
\  r6-r7	Used as needed within higher-level subroutines
\  r8		Global state flags - bitmasks are:
\                  1	- spin mode
\                  2	- quiet mode
\                  4	- script mode
\                  8	- no-echo mode
\  r9		script pointer
\  r10-r13	4-element stack
\  r14		Link register for subroutine calls
\  r15		Program counter

\ Send a space character to the output device.
label putspace  ( -- )  \ Level 0, destroys: r0-r3 (because it calls putchar)
   mov  r0,#0x20
   b `putchar`
end-code

\ Send a newline sequence (CR-LF) to the output device.
label putcr  ( -- )  \ Level 1, destroys: r0-r4 (because it calls putchar)
   mov r4,lr
   mov  r0,#0x0d
   bl `putchar`
   mov  r0,#0x0a
   bl `putchar`
   mov pc,r4
end-code

\ Send ": " to the output device.
label putcolon  ( -- )  \ Level 1, destroys: r0-r4
   mov  r4,lr
   mov  r0,`char : #`
   bl `putchar`
   bl `putspace`
   mov  pc,r4
end-code

\ Accept input characters, packing up to 8 of them into the register pair
\ r0,r1.  The first character is placed in the least-significant byte of
\ r1, and for each subsequent character, the contents of r0,r1 are shifted
\ left by 8 bits to make room for the new character (shifting the most-
\ significant byte of r1 into the least-significant byte of r0).
\ A backspace character causes r0,r1 to be shifted right, discarding the
\ previous character.
\ The process terminates when a space or carriage return is seen.  The
\ terminating character is not stored in r0,r1.  Any unused character
\ positions in r0,r1 contain binary 0 bytes.
label getword  ( -- r0,r1 )  \ Level 4, destroys r0-r7
   mov  r5,lr
   mov  r6,#0		\ Clear high temporary holding register
   mov  r7,#0		\ Clear low temporary holding register

   begin
      tst  r8,#4  0<>  if
         ldrb r0,[r9],#1
         \ Translate linefeed to carriage return in script mode
         cmp  r0,#0x0a  =  if  mov r0,#0x0d  then
      else
         bl `getchar`   ( char in r0 )
      then

      cmp  r0,#0x0d  = if		\ carriage return
         tst r8,#8  0=  if		\ Check no-echo flag
            bl `putcr`			\ Echo CR-LF
         then
         mov r0,r6  mov r1,r7		\ Return packed word in r0,r1
         mov pc,r5			\ Return
      then

      cmp  r0,`control h`  <>  if
         cmp  r0,#0x20  <=  if		\ white space
            tst r8,#8  0=  if		\ Check no-echo flag
               \ In quiet mode, echo the input character; otherwise echo CR-LF
               tst r8,#2  0<>  if  bl `putchar`  else  bl `putcr`  then
            then
            mov r0,r6  mov r1,r7		\ Return packed word in r0,r1
            mov pc,r5			\ Return
         then
      then

      mov  r4,r0			\ Save character
      tst r8,#8  0=  if			\ Check no-echo flag
         bl `putchar`			\ Echo the character
      then

      cmp  r4,`control h`  = if
         \ Double-shift right one byte
         mov  r7,r7,lsr #8
         orr  r7,r7,r6,lsl #24
         mov  r6,r6,lsr #8
      else
         \ Double-shift left one byte and merge in the new character
         mov  r6,r6,lsl #8
         orr  r6,r6,r7,lsr #24
         orr  r7,r4,r7,lsl #8
      then
   again
end-code

\ Convert the ASCII hexadecimal characters packed into r0,r1 into a
\ 32-bit binary number, returning the result in r0 and non-zero in r1
\ if the operation succeeded.
\ If the operation failed (because of the presence of non-hex characters),
\ return 0 in r1, and an undefined value in r0.

\ Level 1, destroys: r0-r4
label convert-number  ( r0,r1: ascii -- r0: binary r1: okay? )
   mov r4,r0		\ Move high 4 ASCII characters away from r0
   mov r0,#0		\ Accumulator for output

   mov r3,#8		\ Loop counter - convert 8 nibbles
   begin
      \ Shift r4,r1 left one byte, putting result in r2
      mov  r2,r4,lsr #24		\ High byte in r2
      mov  r4,r4,lsl #8			\ Shift high word
      orr  r4,r4,r1,lsr #24		\ Merge from low word to high word
      mov  r1,r1,lsl #8			\ Shift low word

      cmp    r2,#0  <>  if

         cmp    r2,`char 0 #`
         movlt  r1,#0
         movlt  pc,lr			\ Exit if < '0'

         cmp    r2,`char 9 #`  <=  if	\ Good digit from 0-9
            sub    r2,r2,`char 0 #`
         else
            cmp    r2,`char A #`
            movlt  r1,#0
            movlt  pc,lr		\ Exit if < 'A'

            cmp    r2,`char F #`  <=  if
               sub    r2,r2,`char A d# 10 - #`
            else
               cmp    r2,`char a #`     \ possibly lower case hex digit
               movlt  r1,#0
               movlt  pc,lr		\ Exit if < 'a'

               cmp    r2,`char f #`
               movgt  r1,#0
               movgt  pc,lr		\ Exit if > 'f'

               sub    r2,r2,`char a d# 10 - #`
            then
         then
         add     r0,r2,r0,lsl #4
      then
      decs r3,1
   = until

   mvn r1,#0

   mov pc,lr
end-code

\ Display the number in r0 as an 8-digit unsigned hexadecimal number
label dot  ( r0 -- )  \ Level 3, destroys: r0-r6
   mov r4,lr
   mov r5,r0
   mov r6,#8
   begin
      mov r5,r5,ror #28
      and r0,r5,#0xf
      cmp r0,#10
      addge  r0,r0,`char a d# 10 - #`
      addlt  r0,r0,`char 0 #`
      bl `putchar`
      decs r6,1
   0= until

   mov r0,#0x20
   bl `putchar`

   mov pc,r4
end-code

transient
\ Macros for managing the mini-stack
: pop1  ( -- )
   " mov r10,r11  mov r11,r12  mov r12,r13"  evaluate
;
: pop2  ( -- )
   " mov r10,r12  mov r11,r13  mov r12,r13"  evaluate
;
: pop3  ( -- )
   " mov r10,r13  mov r11,r13  mov r12,r13"  evaluate
;
: push1  ( -- )
   " mov r13,r12  mov r12,r11  mov r11,r10"  evaluate
;

\ Macros to assemble code to begin and end command definitions
8 buffer: name-buf

\ Start a command definition
\ false value trace?
: t:  ( "name" -- cond )
   \ Get a name from the input stream at compile time and pack it
   \ into a buffer in the same form it will appear in the register
   \ pair when the mini-interpreter is executed at run-time
   name-buf 8 erase                       ( )
   parse-word                             ( adr len )
\ no-page 2dup type space
   dup 8 -  0 max  /string                ( adr' len' )  \ Keep last 8
   8 min  8 over - name-buf +  swap move  ( )

\ ['] $do-undefined behavior .name cr
   \ Assemble code to compare the register-pair contents against the name.
   name-buf     be-l@  " set r2,*  cmp r0,r2"  evaluate
   name-buf 4 + be-l@  " set r2,*  cmpeq r1,r2  =  if"  evaluate
;


\ End a command definition by:
\ a) Assembling code to jump back to the beginning of the loop after the
\    current definition has executed ("over again")
\ b) Resolve the "if" (conditional branch) that skips the current definition
\    if the name the user has entered does not match this definition.

: t;  ( loop-begin-adr if-adr --- loop-begin-adr )
   " over again  then" evaluate
;
resident

label put-string  ( -- )
   mov     r4,lr
   begin
      ldrb    r0,[r4],#1
      cmp     r0,#0
   <> while
      bl      `putchar`
   repeat

   add     r4,r4,#3		\ Align to word boundary
   bic     r4,r4,#3

   mov     pc,r4
end-code

\ Some system architectures place the boot ROM at a non-zero physical
\ address, in which case there must be a special "boot mode" that forces
\ zero-based addresses to hit the ROM until some action is taken to turn
\ off that mode.  jump-to-rom adds the "real" physical address of the
\ ROM to the return address so that it returns to the real physical address,
\ after which it will be safe to turn off boot mode.
label jump-to-rom
   bic    lr,lr,#0xff000000	\ In case we jump to the start address
   set    r0,`rom-pa #`
   add    pc,lr,r0
end-code

label minifth  ( -- <does not return> )  \ Level 5
   bl  `jump-to-rom`		\ Returns at the "real" ROM address

   bl  `init-serial`

   bl  `put-string`
   banner$ c$, 4 (align)

   mov r10,#0  mov r11,#0  mov r12,#0  mov r13,#0	\ Init stack
   mov  r8,#0						\ Init loop flag

   begin                      ( loop-begin-adr )
      tst r8,#6  0=  if     \ Display stack if neither silent nor scripting
  \      mov r0,r13  bl `dot`
         mov r0,r12  bl `dot`
         mov r0,r11  bl `dot`
         mov r0,r10  bl `dot`
         mov r0,`char o #`  bl `putchar`
         mov r0,`char k #`  bl `putchar`
         bl `putspace`
      then

      bl `getword`	\ Result in r0 and r1

      \ If the word is null (i.e. a bare space or return), do nothing
      cmp r0,#0  cmpeq r1,#0
      yet <> until		\ Branch back to the "begin" if r0,r1 = 0

      t: showstack  ( -- )
         bic r8,r8,#2
      t;

      t: quiet  ( -- )
         orr r8,r8,#2
      t;

      t: clear  ( ?? -- )
         mov r10,#0  mov r11,#0  mov r12,#0  mov r13,#0	 \ Init stack
      t;

      t: @  ( adr -- n )
         tst r8,#1  <>  if
            begin  ldr r0,[r10]  again
         then
         ldr r10,[r10]
      t;

      t: !  ( n adr -- )
         tst r8,#1  <>  if
            begin  str r11,[r10]  again
         then
         str r11,[r10]
         pop2
      t;

      t: !@  ( n adr -- n' )
         tst r8,#1  <>  if
            begin  str r11,[r10]  ldr r0,[r10]  again
         then
         str r11,[r10]
         ldr r10,[r10]
         mov r11,r12  mov r12,r13
      t;

      t: @@  ( adr2 adr1 -- n2 n1 )
         tst r8,#1  <>  if
            begin  ldr r0,[r10]  ldr r1,[r11]  again
         then
         ldr r10,[r10]
         ldr r11,[r11]
      t;

      t: !!  ( n2 adr2 n1 adr1 -- )
         tst r8,#1  <>  if
            begin  str r11,[r10]  str r13,[r12]  again
         then
         str r11,[r10]  str r13,[r12]  
         \ There's no reason to fix the stack because the arguments
         \ filled it up.
      t;

      t: !!@  ( n1 adr1 n2 adr2 -- n3 )
         tst r8,#1  <>  if
            begin  str r11,[r10]  str r13,[r12]  ldr r0,[r10]  again
         then
         str r11,[r10]  str r13,[r12]  ldr r10,[r10]
         \ There's no reason to fix the stack because the arguments
         \ filled it up.
      t;

      t: l@  ( adr -- l )
         tst r8,#1  <>  if
            begin  ldr r0,[r10]  again
         then
         ldr r10,[r10]
      t;

      t: l!  ( l adr -- )
         tst r8,#1  <>  if
            begin  str r11,[r10]  again
         then
         str r11,[r10]
         pop2
      t;

      t: l!@  ( n adr -- n' )
         tst r8,#1  <>  if
            begin  str r11,[r10]  ldr r0,[r10]  again
         then
         str r11,[r10]
         ldr r10,[r10]
         mov r11,r12  mov r12,r13
      t;

      t: c@  ( adr -- b )
         tst r8,#1  <>  if
            begin  ldrb r0,[r10]  again
         then
         ldrb r10,[r10]
      t;

      t: c!  ( b adr -- )
         tst r8,#1  <>  if
            begin  strb r11,[r10]  again
         then
         strb r11,[r10]
         pop2
      t;

      t: c!@  ( b adr -- b' )
         tst r8,#1  <>  if
            begin  strb r11,[r10]  ldrb r0,[r10]  again
         then
         strb r11,[r10]
         ldrb r10,[r10]
         mov r11,r12  mov r12,r13
      t;

      t: w@  ( adr -- w )
         tst r8,#1  <>  if
            begin  ldrh r0,[r10]  again
         then
         ldrh r10,[r10]
      t;

      t: w!  ( w adr -- )
         tst r8,#1  <>  if
            begin  strh r11,[r10]  again
         then
         strh r11,[r10]
         pop2
      t;

      t: w!@  ( n adr -- n' )
         tst r8,#1  <>  if
            begin  strh r11,[r10]  ldrh r0,[r10]  again
         then
         strh r11,[r10]
         ldrh r10,[r10]
         mov r11,r12  mov r12,r13
      t;

[ifdef] isa-io-pa
      t: pc@  ( port# -- b )
         set r0,`isa-io-pa #`
         tst r8,#1  <>  if
            begin  ldrb r1,[r10,r0]  again
         then

         ldrb r10,[r10,r0]
      t;

      t: pc!  ( b port# -- )
         set r0,`isa-io-pa #`
         tst r8,#1  <>  if
            begin  strb r11,[r10,r0]  again
         then
         strb r11,[r10,r0]
         pop2
      t;

      t: pw@  ( port# -- w )
         set r0,`isa-io-pa #`
         tst r8,#1  <>  if
            begin  ldrh r1,[r10,r0]  again
         then
         ldrh r10,[r10,r0]
      t;

      t: pw!  ( w port# -- )
         set r0,`isa-io-pa #`
         tst r8,#1  <>  if
            begin  strh r11,[r10,r0]  again
         then
         strh r11,[r10,r0]
         pop2
      t;

      t: pl@  ( port# -- l )
         set r0,`isa-io-pa #`
         tst r8,#1  <>  if
            begin  ldr r1,[r10,r0]  again
         then
         ldr r10,[r10,r0]
      t;

      t: pl!  ( l port# -- )
         set r0,`isa-io-pa #`
         tst r8,#1  <>  if
            begin  str r11,[r10,r0]  again
         then
         str r11,[r10,r0]
         pop2
      t;
[then]

      t: +  ( n1 n2 -- n1+n2 )
         add r10,r11,r10  mov r11,r12  mov r12,r13
      t;

      t: -  ( n1 n2 -- n1-n2 )
         sub r10,r11,r10  mov r11,r12  mov r12,r13
      t;

      t: and  ( n1 n2 -- n1&n2 )
         and r10,r11,r10  mov r11,r12  mov r12,r13
      t;

      t: or  ( n1 n2 -- n1|n2 )
         orr r10,r11,r10  mov r11,r12  mov r12,r13
      t;

      t: xor  ( n1 n2 -- n1^n2 )
         eor r10,r11,r10  mov r11,r12  mov r12,r13
      t;

      t: lshift  ( n1 n2 -- n1<<n2 )
         mov r10,r11,lsl r10  mov r11,r12  mov r12,r13
      t;

      t: rshift  ( n1 n2 -- n1>>n2 )
         mov r10,r11,lsr r10  mov r11,r12  mov r12,r13
      t;

      t: invert  ( n -- ~n )
         mvn r10,r10
      t;

      t: negate  ( n -- -n )
         rsb r10,r10,#0
      t;

      t: spin  ( -- )  \ Modifies next @/!-class command to loop forever
         mov r8,#1
      t;

      t: *  ( n1 n2 -- n1*n2 )
         mul r10,r11,r10  mov r11,r12  mov r12,r13
      t;

      t: .  ( n -- )
         mov r0,r10
         bl `dot`
         bl `putcr`
         pop1
      t;

      t: move  ( src dst len -- )
         cmp   r10,#0
         <>  if
            cmp   r11,r12
            u<  if
               begin
                  ldrb    r0,[r12],#1
                  strb    r0,[r11],#1
                  decs    r10,1
               0= until
            else
               begin
                  decs    r10,1
                  ldrb    r0,[r12,r10]
                  strb    r0,[r11,r10]
               0= until
            then
         then
         pop3
      t;

      t: compare  ( adr1 adr2 len -- -1 | offset )
         mov          r1,r10		\ Save len for later
         mvn          r0,#0		\ -1 - provisional return value
         inc          r10,1
         begin
            decs      r10,1
         0> while
            ldrb      r2,[r11],#1
            ldrb      r3,[r12],#1
            cmp       r2,r3
            subne     r0,r1,r10
         <> until
         then
         pop3
         push1
         mov r10,r0
      t;

      t: fill  ( adr len b -- )
         begin
            decs   r11,1
            strgeb r10,[r12],#1
         < until
         pop3
      t;

      t: check  ( adr len b -- )
         begin
            decs   r11,1
         >= while
            ldrb   r7,[r12],#1
            cmp    r7,r10
            <>  if
               sub    r0,r12,#1       bl     `dot`
               bl     `putcolon`
               mov    r0,r7           bl     `dot`
               bl     `putcr`
            then
         repeat
         pop3
      t;

      t: test  ( adr len b -- )
         mov     r0,r10
         mov     r1,r11
         mov     r2,r12
         begin
            decs   r11,1
            strgeb r10,[r12],#1
         < until
         mov     r10,r0
         mov     r11,r1
         mov     r12,r2
         begin
            decs   r11,1
         >= while
            ldrb   r7,[r12],#1
            cmp    r7,r10
            <>  if
               sub    r0,r12,#1       bl     `dot`
               bl     `putcolon`
               mov    r0,r7           bl     `dot`
               bl     `putcr`
            then
         repeat
         pop3
      t;

      t: lfill  ( adr len l -- )
         begin
            decs   r11,4
            strge  r10,[r12],#4
         < until
         pop3
      t;

      t: lcheck  ( adr len l -- )
         begin
            decs   r11,4
         >= while
            ldr    r7,[r12],#4
            cmp    r7,r10
            <>  if
               sub    r0,r12,#4       bl     `dot`
               bl     `putcolon`
               mov    r0,r7           bl     `dot`
               bl     `putcr`
            then
         repeat
         pop3
      t;

      t: ltest  ( adr len l -- )
         mov     r0,r10
         mov     r1,r11
         mov     r2,r12
         begin
            decs   r11,4
            strge  r10,[r12],#4
         < until
         mov     r10,r0
         mov     r11,r1
         mov     r12,r2
         begin
            decs   r11,4
         >= while
            ldr    r7,[r12],#4
            cmp    r7,r10
            <>  if
               sub    r0,r12,#4       bl     `dot`
               bl     `putcolon`
               mov    r0,r7           bl     `dot`
               bl     `putcr`
            then
         repeat
         pop3

      t;

      t: afill  ( adr len -- )
         begin
            decs   r10,4
            strge  r11,[r11],#4
         < until
         pop2
      t;

      t: acheck  ( adr len -- )
         begin
            decs   r10,4
         >= while
            ldr    r7,[r11]
            cmp    r7,r11
            <>  if
               mov    r0,r11          bl     `dot`
               bl     `putcolon`
               mov    r0,r7           bl     `dot`
               bl     `putcr`
            then
            add    r11,r11,#4
         repeat
         pop2
      t;

      t: atest
         mov     r0,r10
         mov     r1,r11
         begin
            decs   r10,4
            strge  r11,[r11],#4
         < until
         mov     r10,r0
         mov     r11,r1
         begin
            decs   r10,4
         >= while
            ldr    r7,[r11]
            cmp    r7,r11
            <>  if
               mov    r0,r11          bl     `dot`
               bl     `putcolon`
               mov    r0,r7           bl     `dot`
               bl     `putcr`
            then
            add    r11,r11,#4
         repeat
         pop2
      t;

      t: sum  ( adr len -- checksum )
         set r0,0
         begin
            decs   r10,1
            ldrgeb r1,[r11],#1
            addge  r0,r0,r1
         < until
         pop2
         push1
         mov  r10,r0
      t;

      t: erase  ( adr len -- )
         set r0,0
         begin
            decs   r10,1
            strgeb r0,[r11],#1
         < until
         pop2
      t;

      t: dump  ( adr len -- )
         begin
            decs   r10,1
         >= while
            mov    r0,r11          bl     `dot`
            bl     `putcolon`
            ldrb   r0,[r11],#1     bl     `dot`
            bl     `putcr`
         repeat
         pop2
      t;

      t: ldump  ( adr len -- )
         begin
            decs   r10,4
         >= while
            mov    r0,r11
            bl     `dot`
            bl     `putcolon`
            ldr    r0,[r11],#4
            bl     `dot`
            bl     `putcr`
         repeat
         pop2
      t;

      t: dup  ( n -- n n )
         mov r13,r12  mov r12,r11  mov r11,r10
      t;

      t: drop  ( n -- )
         mov r10,r11  mov r11,r12  mov r12,r13
      t;

      t: swap  ( n1 n2 -- n2 n1 )
         mov r0,r11  mov r11,r10  mov r10,r0
      t;

      t: over  ( n1 n2 -- n1 n2 n1 )
         mov r13,r12  mov r12,r11  mov r11,r10  mov r10,r12
      t;

      t: rot  ( n1 n2 n3 -- n2 n3 n1 )
         mov r0,r12  mov r12,r11  mov r11,r10  mov r10,r0
      t;

      t: -rot  ( n1 n2 n3 -- n3 n1 n2 )
         mov r0,r12  mov r12,r10  mov r10,r11  mov r11,r0
      t;

      t: icache-on  ( -- )
         mrc     p15, 0, r0, cr1, cr0, 0	\ write the control register
         orr     r0, r0, #0x1000		\ Turn on the icache
         mcr     p15, 0, r0, cr1, cr0, 0	\ write the control register
      t;

      t: icache-off  ( -- )
         mrc     p15, 0, r0, cr1, cr0, 0	\ write the control register
         bic     r0, r0, #0x1000		\ Turn off the icache
         mcr     p15, 0, r0, cr1, cr0, 0	\ write the control register
      t;

      \ Turning on the dcache and write buffer are not so simple, because
      \ the MMU must be on first.

      t: control@  ( -- n )
         push1
         mrc     p15, 0, r10, cr1, cr0, 0	\ read the control register
      t;

      t: control!  ( n -- )
         mcr     p15, 0, r10, cr1, cr0, 0	\ write the control register
         pop1
      t;

      t: script  ( address -- )
         mov     r9,r10
         orr     r8,r8,#0xc		\ Set script and no-echo flags
         pop1
      t;

      t: rom-script  ( offset -- )
         add     r9,r10,`rom-pa #`
         orr     r8,r8,#0xc		\ Set script and no-echo flags
         pop1
      t;

      t: fexit  ( -- )
         bic     r8,r8,#0xc		\ Clear script and no-echo flags
      t;

      t: scripts  ( -- )
         mov     r6,#0
         set     r7,`rom-pa h# 10000 +  #`
         begin
            ldrb    r0,[r7]
            cmp     r0,`ascii \ #`	\ If the script aread begings
            =  if			\ with a comment character
					\ display "s#: "
               mov    r0,`ascii s #`      bl `putchar`
               add    r0,r6,`ascii 0 #`   bl `putchar`
               mov    r0,`ascii : #`      bl `putchar`
               bl     `putspace`
               begin			\ display the first comment line
                  ldrb    r0,[r7],1	\ Get comment byte
                  cmp     r0,#0x0d	\ Carriage return?
                  cmpne   r0,#0x0a	\ Line feed?
               <> while
                  bl      `putchar`
               repeat
               bl      `putcr`
            then
            mov     r7,r7,lsr #12	\ Clear low bits
            mov     r7,r7,lsl #12
            add     r7,r7,#0x1000	\ Advance to next script
            add     r6,r6,#1
            cmp     r6,#10
         = until
      t;

      t: s0  ( -- )
         set     r9,`rom-pa h# 10000 +  #`
         orr     r8,r8,#0xc		\ Set script and no-echo flags
      t;

      t: s1  ( -- )
         set     r9,`rom-pa h# 11000 +  #`
         orr     r8,r8,#0xc		\ Set script and no-echo flags
      t;

      t: s2  ( -- )
         set     r9,`rom-pa h# 12000 +  #`
         orr     r8,r8,#0xc		\ Set script and no-echo flags
      t;

      t: s3  ( -- )
         set     r9,`rom-pa h# 13000 +  #`
         orr     r8,r8,#0xc		\ Set script and no-echo flags
      t;

      t: s4  ( -- )
         set     r9,`rom-pa h# 14000 +  #`
         orr     r8,r8,#0xc		\ Set script and no-echo flags
      t;

      t: s5  ( -- )
         set     r9,`rom-pa h# 15000 +  #`
         orr     r8,r8,#0xc		\ Set script and no-echo flags
      t;

      t: s6  ( -- )
         set     r9,`rom-pa h# 16000 +  #`
         orr     r8,r8,#0xc		\ Set script and no-echo flags
      t;

      t: s7  ( -- )
         set     r9,`rom-pa h# 17000 +  #`
         orr     r8,r8,#0xc		\ Set script and no-echo flags
      t;

      t: s8  ( -- )
         set     r9,`rom-pa h# 18000 +  #`
         orr     r8,r8,#0xc		\ Set script and no-echo flags
      t;

      t: s9  ( -- )
         set     r9,`rom-pa h# 19000 +  #`
         orr     r8,r8,#0xc		\ Set script and no-echo flags
      t;

      \ The original intention of "no-echo" and its inverse "echo" was
      \ to create a capability like "dl" whereby one could download a
      \ script over the serial line, but without requiring the use of
      \ memory.  However, this has the serious problem that there is
      \ no flow control, so commands that can take a long time (like
      \ memory tests) potentially cause input overrun.  Consequently,
      \ it's better to use quiet mode.  However, quiet mode has its own
      \ problem: few if any terminal programs support its character-echo
      \ flow control technique.  Character-echo flow control is not
      \ particularly great anyway - it can be fooled by generated output
      \ that happens to contain the next input character.
      t: no-echo  ( -- )
         orr     r8,r8,#0x8		\ Set no-echo flag
      t;

      t: echo  ( -- )
         bic     r8,r8,#0x8		\ Clear no-echo flag
      t;

      t: cr  ( -- )
         bl      `putcr`
      t;

      t: key  ( -- char )
         bl      `getchar`
         push1  mov r10,r0
      t;

      t: emit  ( char -- )
         mov     r0,r10
	 bl      `putchar`
         pop1
      t;

      \ This is useful for diagnostics in script mode, but essentially
      \ useless otherwise.
      t: .( ( "string" -- )
         begin
            tst  r8,#4  0<>  if		\ Script mode
               ldrb r0,[r9],#1
            else			\ Normal mode
               bl `getchar`   ( char in r0 )
            then
            cmp  r0,`char ) #`
         <> while
            bl `putchar`
         repeat
      t;

      \ This is useful for commentary in script mode, but essentially
      \ useless otherwise.
      t: \ ( "rest-of-line" -- )
         begin
            tst  r8,#4  0<>  if		\ Script mode
               ldrb r0,[r9],#1
            else			\ Normal mode
               bl `getchar`   ( char in r0 )
            then
            cmp    r0,#0x0a
            cmpne  r0,#0x0d
         = until
      t;

      t: goto  ( address -- )
         mov     pc,r10
      t;

      t: gettext  ( address -- length )
          mov   r4,r10
          begin
             bl      `getchar`
             cmp     r0,#4	\ Control-D (ASCII EOT)
          <> while
             strb    r0,[r4],#1
          repeat

          sub   r10,r4,r10
      t;

      t: getbytes  ( address length -- )
          begin
             decs    r10,1
          0>=  while
             bl      `getchar`
             strb    r0,[r11],#1
          repeat
          pop2
      t;

[ifdef] init-sequoia
      t: seq@  ( reg# -- w )
         set     r0, `isa-io-pa #`
         tst r8,#1  <>  if
            begin  strh r10,[r0, #0x24]  ldrh r10,[r0,#0x26]  again
         then
         strh    r10, [r0, #0x24]	\ Point to the register
         ldrh    r10, [r0, #0x26]	\ Get the data
      t;

      t: seq!  ( w reg# -- )
         set     r0, `isa-io-pa #`
         tst r8,#1  <>  if
            begin  strh r10,[r0, #0x24]  strh r11,[r0,#0x26]  again
         then
         strh    r10, [r0, #0x24]	\ Point to the register
         strh    r11, [r0, #0x26]	\ Get the data
         pop2
      t;
[then]

[ifdef] rom-pa
      t: rom   ( -- adr )
         push1  set r10,`rom-pa #`
      t;
[then]

[ifdef] isa-io-pa
      t: io   ( -- adr )
         push1  set r10,`isa-io-pa #`
      t;
[then]

[ifdef] mem0-pa
      t: mem0   ( -- adr )
         push1  set r10,`mem0-pa #`
      t;
[then]

[ifdef] mem1-pa
      t: mem1   ( -- adr )
         push1  set r10,`mem1-pa #`
      t;
[then]

[ifdef] mem2-pa
      t: mem2   ( -- adr )
         push1  set r10,`mem2-pa #`
      t;
[then]

[ifdef] mem3-pa
      t: mem3   ( -- adr )
         push1  set r10,`mem3-pa #`
      t;
[then]

      t: 1m  ( -- n )
         push1  mov r10,#0x100000
      t;

      t: 1m  ( -- n )
         push1  mov r10,#0x100000
      t;

      t: 1m  ( -- n )
         push1  mov r10,#0x100000
      t;

      t: 2m  ( -- n )
         push1  mov r10,#0x200000
      t;

      t: 4m  ( -- n )
         push1  mov r10,#0x400000
      t;

      t: 8m  ( -- n )
         push1  mov r10,#0x800000
      t;

      t: 16m  ( -- n )
         push1  mov r10,#0x1000000
      t;

      t: 32m  ( -- n )
         push1  mov r10,#0x2000000
      t;


      \ The word was not recognized; parse it as a number or complain
      bl `convert-number`  cmp r1,#0  <>  if  \ Number in r0
         \ Push the number
         push1  mov r10,r0   ( -- n )
      else
         \ The word was neither recognized nor numeric; complain
         mov r0,`char ? #`  bl `putchar`   bl `putcr`
      then

   again

end-code

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
