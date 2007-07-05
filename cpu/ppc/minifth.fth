purpose: Forth-like peek/poke/memory-test monitor using only registers
\ See license at end of file

\ Requires the following external definitions:
\ isa-io-pa  ( -- n )	     \ Returns the base address of IO space
\ init-serial  ( -- )        \ May destroy r3-r7
\ getchar  ( -- r3: char )   \ May destroy r3-r7
\ putchar  ( r3: char -- )   \ May destroy r3-r7

\ The following code must run entirely from registers.  The following
\ register allocation conventions are used:
\  r3-r7	Argument passing and return, scratch registers for subroutines
\  r8		Return address for level 1 routines, scratch use for level 2+
\  r9		Return address for level 2 routines, scratch use for level 3+
\  r10-r11	Used as needed within higher-level subroutines
\  r12		Global state flags
\  r13		As-yet unassigned
\  r14-r17	4-element stack
\  r18		script pointer

\ Send a space character to the output device.
label putspace  ( -- )  \ Level 0, destroys: r3-r7 (because it calls putchar)
   set  r3,h#20
   putchar b *
end-code

\ Send a newline sequence (CR-LF) to the output device.
label putcr  ( -- )  \ Level 1, destroys: r3-r8 (because it calls putchar)
   mfspr r8,lr
   set  r3,h#0d   putchar bl *
   set  r3,h#0a   putchar bl *
   mtspr lr,r8
   bclr 20,0
end-code

\ Send ": " to the output device.
label putcolon  ( -- )  \ Level 1, destroys: r3-r8
   mfspr  r8,lr
   char : set  r3,*  putchar bl *
   putspace bl *
   mtspr  lr,r8
   bclr   20,0
end-code

\ Accept input characters, packing up to 8 of them into the register pair
\ r3,r4.  The first character is placed in the least-significant byte of
\ r4, and for each subsequent character, the contents of r3,r4 are shifted
\ left by 8 bits to make room for the new character (shifting the most-
\ significant byte of r4 into the least-significant byte of r3).
\ A backspace character causes r3,r4 to be shifted right, discarding the
\ previous character.
\ The process terminates when a space or carriage return is seen.  The
\ terminating character is not stored in r3,r4.  Any unused character
\ positions in r3,r4 contain binary 0 bytes.
label getword  ( -- r3,r4 )  \ Level 4, destroys r3-r11
   mfspr  r9,lr
   set  r10,0		\ Clear high temporary holding register
   set  r11,0		\ Clear low temporary holding register

   begin
      andi.  r3,r12,4  0<>  if
         lbz   r3,0(r18)
         addi  r18,r18,1
         \ Translate linefeed to carriage return in script mode
         cmpi  0,0,r3,h#0a  =  if  set r3,h#0d  then
      else
         getchar bl *  ( char in r3 )
      then

      cmpi  0,0,r3,h#0d  = if		\ carriage return
         andi.  r0,r12,8  0=  if	\ Check no-echo flag
            putcr bl *			\ Echo CR-LF
         then
         mr r3,r10  mr r4,r11		\ Return packed word in r3,r4
         mtspr lr,r9
         bclr 20,0			\ Return
      then

      control h  cmpi  0,0,r3,*  <>  if \ backspace
         cmpi  0,0,r3,h#20  =  if	\ white space
            andi. r0,r12,8  0=  if	\ Check no-echo flag
               \ In quiet mode, echo the input character; otherwise echo CR-LF
               andi. r0,r12,2  0<>  if  putchar bl *  else  putcr bl *   then
            then
            mr r3,r10  mr r4,r11	\ Return packed word in r3,r4
            mtspr lr,r9
            bclr 20,0			\ Return
         then
      then

      mr  r8,r3				\ Save character
      andi. r0,r12,8  0=  if		\ Check no-echo flag
         putchar bl *			\ Echo the character
      then

      control h cmpi  0,0,r8,*  = if
         \ Double-shift right one byte
         rlwinm  r11,r11,24,8,31
         rlwimi  r11,r10,24,0,7
         rlwinm  r10,r10,24,0,23
      else
         \ Double-shift left one byte and merge in the new character
         rlwinm  r10,r10,8,0,23
         rlwimi  r10,r11,8,24,31
         rlwinm  r11,r11,8,0,23
         or      r11,r11,r8
      then
   again
end-code

\ Convert the ASCII hexadecimal characters packed into r3,r4 into a
\ 32-bit binary number, returning the result in r3 and non-zero in r4
\ if the operation succeeded.
\ If the operation failed (because of the presence of non-hex characters),
\ return 0 in r4, and an undefined value in r3.

\ Level 1, destroys: r3-r8
label convert-number  ( r3,r4: ascii -- r3: binary r4: okay? )
   mr r8,r3		\ Move high 4 ASCII characters away from r3
   set r3,0		\ Accumulator for output

   set r6,8		\ Loop counter - convert 8 nibbles
   mtspr ctr,r6
   begin
      \ Shift r8,r4 left one byte, putting result in r6
      rlwinm  r6,r8,8,24,31		\ High byte in r6
      rlwinm  r8,r8,8,0,23		\ Shift high word
      rlwimi  r8,r4,8,24,31		\ Merge from low word to high word
      rlwinm  r4,r4,8,0,23		\ Shift low word

      cmpi    0,0,r6,0  <>  if

         char 0  cmpi   0,0,r6,*
         <  if
            set  r4,0
            bclr 20,0			\ Exit if < '0'
         then

         char 9  cmpi  0,0,r6,*  <=  if	\ Good digit from 0-9
            char 0 negate  addi r6,r6,*
         else
            char A  cmpi   0,0,r6,*
            <  if
               set  r4,0
               bclr 20,0		\ Exit if < 'A'
            then

            char F  cmpi  0,0,r6,*  <=  if
               char A d# 10 - negate  addi  r6,r6,*
            else
               char a  cmpi  0,0,r6,*   \ possibly lower case hex digit
               <  if
                  set  r4,0
                  bclr 20,0		\ Exit if < 'a'
               then

               char f  cmpi  0,0,r6,*
               >  if
                  set  r4,0
                  bclr 20,0		\ Exit if > 'f'
               then

               char a d# 10 -  negate  addi  r6,r6,*
            then
         then
         rlwinm  r3,r3,4,0,27
         or      r3,r3,r6
      then
   countdown

   set r4,-1

   bclr 20,0
end-code

\ Display the number in r3 as an 8-digit unsigned hexadecimal number
label dot  ( r3 -- )  \ Level 3, destroys: r3-r10
   mfspr r8,lr
   set r9,8
   mtspr ctr,r9
   mr r9,r3
   begin
      rlwinm r9,r9,4,0,31
      andi. r3,r9,h#f
      cmpi 0,0,r3,10
      >=  if
         char a d# 10 -  addi  r3,r3,*
      else
         char 0          addi  r3,r3,*
      then
      putchar bl *
   countdown

   set r3,h#20  putchar bl *

   mtspr lr,r8
   bclr  20,0
end-code

transient
\ Macros for managing the mini-stack
: pop1  ( -- )
   " mr r14,r15  mr r15,r16  mr r16,r17"  evaluate
;
: pop2  ( -- )
   " mr r14,r16  mr r15,r17  mr r16,r17"  evaluate
;
: pop3  ( -- )
   " mr r14,r17  mr r15,r17  mr r16,r17"  evaluate
;
: push1  ( -- )
   " mr r17,r16  mr r16,r15  mr r15,r15"  evaluate
;
: spush  ( -- )
   " mr r17,r16  mr r16,r15  mr r15,r14  mr r14,r3"  evaluate
;

\ Macros to assemble code to begin and end command definitions
8 buffer: name-buf

\ Start a command definition
: t:  ( "name" -- cond )
   \ Get a name from the input stream at compile time and pack it
   \ into a buffer in the same form it will appear in the register
   \ pair when the mini-interpreter is executed at run-time
   name-buf 8 erase                       ( )
   parse-word                             ( adr len )
   dup 8 -  0 max  /string                ( adr' len' )  \ Keep last 8
   8 min  8 over - name-buf +  swap move  ( )

   \ Assemble code to compare the register-pair contents against the name.
   name-buf     be-l@  " set r6,*  cmp 0,0,r3,r6  =  if"  evaluate
   name-buf 4 + be-l@  " set r6,*  cmp 0,0,r4,r6  then  =  if"  evaluate
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

label minifth  ( -- <does not return> )  \ Level 5
   init-serial bl *

[ifdef] notdef
set r10,0
begin
   mr r3,r10
   dot bl *
   putcr bl *
   addi r10,r10,1
again
[then]

   set r14,0  set r15,0  set r16,0  set r17,0	\ Init stack
   set r12,0					\ Init loop flag

   begin                      ( loop-begin-adr )
      andi. r0,r12,6  0=  if     \ Display stack if neither silent nor scripting
  \      mr r3,r17  dot bl *
         mr r3,r16  dot bl *
         mr r3,r15  dot bl *
         mr r3,r14  dot bl *
         char o  set r3,*  putchar bl *
         char k  set r3,*  putchar bl *
         putspace bl *
      then

      getword bl *	\ Result in r3 and r4

      \ If the word is null (i.e. a bare space or return), do nothing
      cmpi 0,0,r3,0  =  if  cmpi 0,0,r4,0  then
      yet <> until		\ Branch back to the "begin" if r3,r4 = 0

      t: showstack  ( -- )
         rlwinm  r12,r12,0,31,29  \ Clear the 2 bit
      t;

      t: quiet  ( -- )
         or r12,r12,2
      t;

      t: clear  ( ?? -- )
         set r14,0  set r15,0  set r16,0  set r17,0	 \ Init stack
      t;

      t: @  ( adr -- n )
         andi. r0,r12,1  <>  if
            begin  lwz r3,0(r14)  again
         then
         lwz r14,0(r14)
      t;

      t: !  ( n adr -- )
         andi. r0,r12,1  <>  if
            begin  stw r15,0(r14)  again
         then
         stw r15,0(r14)
         pop2
      t;

      t: l@  ( adr -- l )
         andi. r0,r12,1  <>  if
            begin  lwz r3,0(r14)  again
         then
         lwz r14,0(r14)
      t;

      t: l!  ( l adr -- )
         andi. r0,r12,1  <>  if
            begin  stw r15,0(r14)  again
         then
         stw r15,0(r14)
         pop2
      t;

      t: c@  ( adr -- b )
         andi. r0,r12,1  <>  if
            begin  lbz r3,0(r14)  again
         then
         lbz r14,0(r14)
      t;

      t: c!  ( b adr -- )
         andi. r0,r12,1  <>  if
            begin  stb r15,0(r14)  again
         then
         stb r15,0(r14)
         pop2
      t;

      t: w@  ( adr -- w )
         andi. r0,r12,1  <>  if
            begin  lhz r3,0(r14)  again
         then
         lhz r14,0(r14)
      t;

      t: w!  ( w adr -- )
         andi. r0,r12,1  <>  if
            begin  sth r15,0(r14)  again
         then
         sth r15,0(r14)
         pop2
      t;

      t: pc@  ( port# -- b )
         isa-io-pa set r3,*
         andi. r0,r12,1  <>  if
            begin  lbzx r4,r14,r3  again
         then

         lbzx r14,r14,r3
      t;

      t: pc!  ( b port# -- )
         isa-io-pa set r3,*
         andi. r0,r12,1  <>  if
            begin  stbx r15,r14,r3  again
         then
         stbx r15,r14,r3
         pop2
      t;

      t: pw@  ( port# -- w )
         isa-io-pa set r3,*
         andi. r0,r12,1  <>  if
            begin  lhzx r4,r14,r3  again
         then
         lhzx r14,r14,r3
      t;

      t: pw!  ( w port# -- )
         isa-io-pa set r3,*
         andi. r0,r12,1  <>  if
            begin  sthx r15,r14,r3  again
         then
         sthx r15,r14,r3
         pop2
      t;

      t: pl@  ( port# -- l )
         isa-io-pa set r3,*
         andi. r0,r12,1  <>  if
            begin  lwzx r4,r14,r3  again
         then
         lwzx r14,r14,r3
      t;

      t: pl!  ( l port# -- )
         isa-io-pa set r3,*
         andi. r0,r12,1  <>  if
            begin  stwx r15,r14,r3  again
         then
         stwx r15,r14,r3
         pop2
      t;

      t: config-l!  ( l config-adr -- )
         set     r3,h#8000.0000
         or      r14,r14,r3		\ Set access enable bit
         config-addr set r3,*
         stwbrx  r14,0,r3		\ Set address
         sync
         config-data set r3,*
         andi. r0,r12,1  <>  if
            begin  stwbrx r15,0,r3  sync  again
         then
         stwbrx r15,0,r3  sync
         pop2
      t;

      t: cl!  ( l config-adr -- )	\ Shorter name
         set     r3,h#8000.0000
         or      r14,r14,r3		\ Set access enable bit
         config-addr set r3,*
         stwbrx  r14,0,r3		\ Set address
         sync
         config-data set r3,*
         andi. r0,r12,1  <>  if
            begin  stwbrx r15,0,r3  sync  again
         then
         stwbrx r15,0,r3  sync
         pop2
      t;

      t: config-l@  ( config-adr -- l )
         set     r3,h#8000.0000
         or      r14,r14,r3		\ Set access enable bit
         config-addr set r3,*
         stwbrx  r14,0,r3		\ Set address
         sync
         config-data set r3,*
         andi. r0,r12,1  <>  if
            begin  lwbrx r14,0,r3  sync  again
         then
         lwbrx r14,0,r3  sync
      t;

      t: cl@  ( config-adr -- l )	\ Shorter name
         set     r3,h#8000.0000
         or      r14,r14,r3		\ Set access enable bit
         config-addr set r3,*
         stwbrx  r14,0,r3		\ Set address
         sync
         config-data set r3,*
         andi. r0,r12,1  <>  if
            begin  lwbrx r14,0,r3  sync  again
         then
         lwbrx r14,0,r3  sync
      t;

      t: +  ( n1 n2 -- n1+n2 )
         add r14,r15,r14  mr r15,r16  mr r16,r17
      t;

      t: -  ( n1 n2 -- n1-n2 )
         subf r14,r14,r15  mr r15,r16  mr r16,r17
      t;

      t: and  ( n1 n2 -- n1&n2 )
         and r14,r15,r14  mr r15,r16  mr r16,r17
      t;

      t: or  ( n1 n2 -- n1|n2 )
         or r14,r15,r14  mr r15,r16  mr r16,r17
      t;

      t: xor  ( n1 n2 -- n1^n2 )
         xor r14,r15,r14  mr r15,r16  mr r16,r17
      t;

      t: lshift  ( n1 n2 -- n1<<n2 )
         slw r14,r14,r15  mr r15,r16  mr r16,r17
      t;

      t: rshift  ( n1 n2 -- n1>>n2 )
         srw r14,r14,r15  mr r15,r16  mr r16,r17
      t;

      t: invert  ( n -- ~n )
         nor r14,r14,r14
      t;

      t: negate  ( n -- -n )
         neg r14,r14
      t;

      t: spin  ( -- )  \ Modifies next @/!-class command to loop forever
         set r12,1
      t;

      t: *  ( n1 n2 -- n1*n2 )
         mullw r14,r15,r14
      t;

      t: .  ( n -- )
         mr r3,r14
         dot bl *
         putcr bl *
         pop1
      t;

      t: move  ( src dst len -- )
         cmpi   0,0,r14,0
         <>  if
            cmpl 0,0,r15,r16
            <  if
               begin
                  lbz     r3,0(r16)
                  addi    r16,r16,1
                  stb     r3,0(r15)
                  addi    r15,r15,1
                  addic.  r14,r14,-1
               0= until
            else
               begin
                  addic.  r14,r14,-1
                  lbzx    r3,r16,r14
                  stbx    r3,r15,r14
               0= until
            then
         then
         pop3
      t;

      t: compare  ( adr1 adr2 len -- -1 | offset )
         mr           r4,r14		\ Save len for later
         set          r3,-1             \ -1 - provisional return value
         addi         r14,r14,1
         begin
            addic.    r14,r14,-1
         0> while
            lbz       r5,0(r15)
            lbz       r6,0(r16)
            cmp       0,0,r5,r6
            <>  if  subf.  r3,r14,r4  then
         <> until
         then
         pop3
         push1
         mr r14,r3
      t;

      t: fill  ( adr len b -- )
         cmpi 0,0,r15,0  <>  if
            addi  r16,r16,-1
            mtspr ctr,r15
            begin
               stbu r14,1(r16)
            countdown
         then
         pop3
      t;

      t: lfill  ( adr len l -- )
         cmpi 0,0,r15,0  <>  if
            addi r16,r16,-4
\            rlwinm r15,r15,2,0,29
            rlwinm r15,r15,30,2,31
            mtspr ctr,r15
            begin
               stwu  r14,4(r16)
            countdown
         then
         pop3
      t;

      t: afill  ( adr len -- )
         cmpi 0,0,r14,0  <>  if
\            rlwinm r14,r14,2,0,29
            rlwinm r14,r14,30,2,31
            mtspr ctr,r14
            begin
               stw   r15,(r15)
               addi  r15,r15,4
            countdown
         then
         pop2
      t;

      t: check  ( adr len b -- )
         addi   r16,r16,-1
         begin
            addic. r15,r15,-1
         >= while
            lbzu   r11,1(r16)
            cmp    0,0,r11,r14
            <>  if
               mr    r3,r16          dot bl *
               putcolon bl *
               mr    r3,r11          dot bl *
               putcr bl *
            then
         repeat

         pop3
      t;

      t: lcheck  ( adr len l -- )
         addi  r16,r16,-4
         begin
            addic. r15,r15,-4
         >= while
            lwzu   r11,4(r16)
            cmp    0,0,r11,r14
            <>  if
               mr    r3,r16          dot bl *
               putcolon bl *
               mr    r3,r11           dot bl *
               putcr bl *
            then
         repeat
         pop3
      t;

      t: acheck  ( adr len -- )
         addi      r15,r15,-4
         begin
            addic. r14,r14,-4
         >= while
            lwzu   r11,4(r15)
            cmp    0,0,r11,r15
            <>  if
               mr    r3,r15          dot bl *
               putcolon bl *
               mr    r3,r11          dot bl *
               putcr bl *
            then
         repeat
         pop2
      t;

      t: erase  ( adr len -- )
         set r3,0
         cmpi  0,0,r14,0  <> if
            addi r15,r15,-1
            begin
               stbu r3,1(r15)
            countdown
         then
         pop2
      t;

      t: dump  ( adr len -- )
         begin
            addic. r14,r14,-1
         >= while
            mr    r3,r15           dot bl *
            putcolon bl *
            lbz   r3,0(r15)        dot bl *
            putcr bl *
            addi  r15,r15,1
         repeat
         pop2
      t;

      t: ldump  ( adr len -- )
         begin
            addic.  r14,r14,-4
         >= while
            mr    r3,r15         dot bl *
            putcolon bl *
            lwz   r3,0(r15)      dot bl *
             putcr bl *
            addi  r15,r15,4
         repeat
         pop2
      t;

      t: dup  ( n -- n n )
         mr r17,r16  mr r16,r15  mr r15,r14
      t;

      t: drop  ( n -- )
         mr r14,r15  mr r15,r16  mr r16,r17
      t;

      t: swap  ( n1 n2 -- n2 n1 )
         mr r3,r15  mr r15,r14  mr r14,r3
      t;

      t: over  ( n1 n2 -- n1 n2 n1 )
         mr r17,r16  mr r16,r15  mr r15,r14  mr r14,r16
      t;

      t: rot  ( n1 n2 n3 -- n2 n3 n1 )
         mr r3,r16  mr r16,r15  mr r15,r14  mr r14,r3
      t;

      t: -rot  ( n1 n2 n3 -- n3 n1 n2 )
         mr r3,r16  mr r16,r14  mr r14,r15  mr r15,r3
      t;

      t: script  ( address -- )
         mr      r18,r14
         ori     r12,r12,h#c		\ Set script and no-echo flags
         pop1
      t;

      t: rom-script  ( offset -- )
         rom-pa  set    r10,*
         add     r18,r14,r10
         ori     r12,r12,h#c		\ Set script and no-echo flags
         pop1
      t;

      t: fexit  ( -- )
         rlwinm   r12,r12,0,30,27	\ Clear script and no-echo flags (h#0c)
      t;

      t: scripts  ( -- )
         set    r10,0
         rom-pa h# 10000 + 1-  set     r11,*
         begin
            lbzu     r0,1(r11)
            ascii \   cmpi  0,0,r0,*	\ If the script aread begings
            =  if			\ with a comment character
					\ display "s#: "
               ascii s   set    r3,*       putchar bl *
               ascii 0   addi   r3,r10,*   putchar bl *
               ascii :   set    r3,*       putchar bl *
               putspace bl *
               begin			\ display the first comment line
                  lbzu    r3,1(r11)	\ Get comment byte
                  cmpi    0,0,r3,h#0d	\ Carriage return?
                  <>  if  cmpi  0,0,r3,h#0a  then	\ Line feed?
               <> while
                  putchar bl *
               repeat
               putcr bl *
            then
            rlwinm  r11,r11,0,0,19		\ Clear 12 low bits
            addi    r11,r11,h#fff		\ Advance to next script
            addi    r10,r10,1
            cmpi    0,0,r10,10
         = until
      t;

      t: s0  ( -- )
         rom-pa h# 10000 + 1-   set     r18,*
         ori     r12,r12,h#c		\ Set script and no-echo flags
      t;

      t: s1  ( -- )
         rom-pa h# 11000 + 1-   set     r18,*
         ori     r12,r12,h#c		\ Set script and no-echo flags
      t;

      t: s2  ( -- )
         rom-pa h# 12000 + 1-   set     r18,*
         ori     r12,r12,h#c		\ Set script and no-echo flags
      t;

      t: s3  ( -- )
         rom-pa h# 13000 + 1-   set     r18,*
         ori     r12,r12,h#c		\ Set script and no-echo flags
      t;

      t: s4  ( -- )
         rom-pa h# 14000 + 1-   set     r18,*
         ori     r12,r12,h#c		\ Set script and no-echo flags
      t;

      t: s5  ( -- )
         rom-pa h# 15000 + 1-   set     r18,*
         ori     r12,r12,h#c		\ Set script and no-echo flags
      t;

      t: s6  ( -- )
         rom-pa h# 16000 + 1-   set     r18,*
         ori     r12,r12,h#c		\ Set script and no-echo flags
      t;

      t: s7  ( -- )
         rom-pa h# 17000 + 1-   set     r18,*
         ori     r12,r12,h#c		\ Set script and no-echo flags
      t;

      t: s8  ( -- )
         rom-pa h# 18000 + 1-   set     r18,*
         ori     r12,r12,h#c		\ Set script and no-echo flags
      t;

      t: s9  ( -- )
         rom-pa h# 19000 + 1-   set     r18,*
         ori     r12,r12,h#c		\ Set script and no-echo flags
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
         ori     r12,r12,h#8		\ Set no-echo flag
      t;

      t: echo  ( -- )
         rlwinm    r12,r12,0,29,27	\ Clear no-echo flag
      t;

      t: cr  ( -- )
         putcr bl *
      t;

      t: key  ( -- char )
         getchar bl *
         push1  mr r14,r3
      t;

      t: emit  ( char -- )
         mr     r3,r14
	 putchar bl *
         pop1
      t;

      \ This is useful for diagnostics in script mode, but essentially
      \ useless otherwise.
      t: .( ( "string" -- )
         begin
            andi.  r3,r12,4  0<>  if		\ Script mode
               lbz  r3,0(r18)
               addi r18,r18,1
            else				\ Normal mode
               getchar bl *   ( char in r3 )
            then
            char )  cmpi  0,0,r3,*
         <> while
            putchar bl *
         repeat
      t;

      \ This is useful for commentary in script mode, but essentially
      \ useless otherwise.
      t: \ ( "rest-of-line" -- )
         begin
            andi.  r3,r12,4  0<>  if		\ Script mode
               lbz r3,0(r18)
            else			\ Normal mode
               getchar bl *   ( char in r3 )
            then
            cmpi   0,0,r3,h#0a
            <>  if  cmpi  0,0,r3,h#0d  then
         = until
      t;

      t: goto  ( address -- )
         mr     r3,r11  mr r4,r12  mr r5,r13
         mtspr  lr,r15
         bclr   20,0
      t;

      t: gettext  ( address -- length )
          addi   r8,r14,-1
          begin
             getchar bl *
             cmpi    0,0,r3,4	\ Control-D (ASCII EOT)
          <> while
             stbu    r0,1(r8)
          repeat

          addi  r8,r8,1
          subf  r14,r14,r8
      t;

      t: getbytes  ( address length -- )
          begin
             addic.  r14,r14,-1
          0>=  while
             getchar bl *
             stb     r3,0(r15)
             addi    r15,r15,1
          repeat
          pop2
      t;

[ifdef] rom-pa
      t: rom   ( -- adr )
         push1  rom-pa set r14,*
      t;
[then]

[ifdef] isa-io-pa
      t: io   ( -- adr )
         push1  isa-io-pa set r14,*
      t;
[then]

[ifdef] mem0-pa
      t: mem0   ( -- adr )
         push1  mem0-pa set r14,*
      t;
[then]

[ifdef] mem1-pa
      t: mem1   ( -- adr )
         push1  mem1-pa set r14,*
      t;
[then]

[ifdef] mem2-pa
      t: mem2   ( -- adr )
         push1  mem2-pa set r14,*
      t;
[then]

[ifdef] mem3-pa
      t: mem3   ( -- adr )
         push1  mem3-pa set r14,*
      t;
[then]

      t: 1m  ( -- n )
         push1  set r14,h#100000
      t;

      t: 2m  ( -- n )
         push1  set r14,h#200000
      t;

      t: 4m  ( -- n )
         push1  set r14,h#400000
      t;

      t: 8m  ( -- n )
         push1  set r14,h#800000
      t;

      t: 16m  ( -- n )
         push1  set r14,h#1000000
      t;

      t: 32m  ( -- n )
         push1  set r14,h#2000000
      t;

[ifdef] load-nano-extras  load-nano-extras  [then]

      \ The word was not recognized; parse it as a number or complain
      convert-number bl *  cmpi 0,0,r4,0  <>  if  \ Number in r3
         \ Push the number
         spush      ( -- n )
      else
         \ The word was neither recognized nor numeric; complain
         char ?  set r3,*  putchar bl *   putcr bl *
      then

   again

end-code

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
