\ Contents: Boot-code for ARM Risc_OS Code
\ See license at end of file

hex
nuser memtop            \ The top of the memory used by Forth
0 value #args           \ The process's argument count
0 value  args           \ The process's argument list

0 constant main-task    \ This pointer will be changed at boot

code start-forth        ( r6: header r7: syscall-vec r8: memtop )
                        ( r10: argc  r11: argv  r12: initial-heap-size )
    \ Binary relocation.  This code reads the relocation bitmap and
    \ relocates each longword marked by a 1 bit in the bitmap.  Each
    \ bit in the bitmap represents an aligned address in the program
    \ image, thus there is one relocation bit for each 32-bit word in
    \ the program image.  The bits in relocation bitmap are numbered
    \ in big-endian order.
    \ The 0x80 bit corresponds to a lower address than then 0x40 bit, etc.
   add     r0,r6,#0x80             \ forth-image
   ldr     r1,[r0,#0x10]           \ /dictionary
   ldr     r3,[r0,#0x14]           \ old origin
   mov     r2,r1,asr #2            \ words to relocate
   add     r1,r0,r1           \ dictionary size plus forth-image
   cmp     r3,r0              
   <> if
      dec     r2,#1               
      \ variables:
      \ r0: The startof the program image
      \ r1: The ending address of the program image,
      \     equal to the starting address of the relocation bitmap 
      \ r2: bit-to-relocate
      \ r3: origin at saving time

      begin  
         and     r4,r2,#7     
         mov     r5,#0x80          
         mov     r4,r5,lsr r4
         ldrb    r5,[r1,r2,asr #3]
         ands    r4,r4,r5      
         0<> if
            ldr     r4,[r0,r2,lsl #2]
            sub     r4,r4,r3      
            add     r4,r4,r0              
            str     r4,[r0,r2,lsl #2]
         then
         subs    r2,r2,#1     
      <= until
   then

   \ set user-pointer up
   
   add     up,r0,`init-user-area #`    \ set user-pointer
   str     r1,'user dp         	       \ set here

   str     r8,'user memtop
   sub     sp,r8,#0x40                 \ Guard band
   \ Now the stacks are just below the end of our memory

   str     r7,'user syscall-vec
   str     r10,'user #args
   str     r11,'user args

   \ At this point, the stack pointer is at the top of the unused
   \ memory and the user pointer has been set to the bottom of the
   \ initial user area image.
   str     up,'user up0
   str     up,[pc,`'body main-task swap here 8 + - swap`]
   mov     rp,sp                \ set return-stack pointer
   str     rp,'user rp0
   rs-size-t 100 + #
   dec     sp,*
   dec     sp,#0x20              
   str     sp,'user sp0

   mov     r8,sp

   ps-size-t #
   dec     r8,*
   sub     r8,r8,r12            \ Heap size
   str     r8,'user limit       \ Initial heap will be from limit to bottom of stack

   inc     sp,1cell             \ account for the top of stack register

   adr     ip,'body cold
c;

code cold-code          ( r0: loadaddr  r1: functions  r2: memtop ... )
                        ( r3: argc      sp[0]: argv )
   here-t  8  put-call

   \ Put the arguments in safe registers
   mov     r6,r0            \ r6 points to header
   mov     r7,r1            \ r7: functions
   mov     r8,r2            \ r8: memtop
   \  r9 is up
   mov     r10,r3           \ r10: argc
   ldr     r11,[sp]         \ r11: argv
   mov     r12,#0           \ r11: initial-heap-size

   b       'code start-forth
end-code

: init-user  ;

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
