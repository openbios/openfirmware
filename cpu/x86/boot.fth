\ See license at end of file

\ Version for running Forth under DOS, either under the Phar Lap
\ DOS Extender or under the Zortech C DOS Extender.

\ Boot code (cold and warm start).  The cold start code is executed
\ when Forth is initially started.  Its job is to initialize the Forth
\ virtual machine registers.  The warm start code is executed when Forth
\ is re-entered, perhaps as a result of an exception.

hex

only forth also labels also meta also definitions

0 constant main-task

: init-user  (s -- )  ;

0 value #args
0 value args

variable memtop

[ifdef] big-endian-t
\ Byte swap the pointers in the argument array
: bswap-args  ( -- )  #args 0  ?do  args i na+  dup @  swap le-l!  loop  ;
: (cold-hook  ( -- )  (cold-hook  bswap-args  ;
' (cold-hook is cold-hook
[then]

create cold-code  ( -- )  assembler
mlabel cold-code

forth-h
h# e9 origin-t c!-t			  \ Relative jump with 32-bit offset
here-t  origin-t 5 +  -  origin-t 1+  !-t \ Offset relative to instruction end
assembler

\ The segment registers are set correctly, and the stack pointer is
\ at the top of the memory region reserved for Forth

\ Get the origin address
   here-t 5 + #) call   here-t origin-t -  ( offset )
   bx  pop
   ( offset ) #  bx  sub	\ Origin in bx
   
   20 [bx] di lea
   di 'user up0 mov      \ initialize up0 (needed for future relocation)

\ Set the value of flat? so later code can determine whether or
\ not it is safe to do things like setting the stack segment descriptor,
\ intercepting exceptions, probing for a DPMI server, etc.

  8 [sp]  ax  mov	\ Caller's CS, or 0 if we are unsegmented
  ax  ax  or
  0<>  if
     false #  ax  mov	\ CS not zero - we are running segmented
  else
     true #  ax  mov	\ CS zero - we are running flat
  then
  ax  'user flat?  mov

\ Prepare to allocate high memory for the stacks and stuff
\ Allocate buffers from image_end down Hi-RAM allocation pointer

   sp  ax mov

[ifdef] notdef
\ this version is ROMable   
\ Allocate the RAM copy of the User Area
   user-size-t #   sp	sub

\ Copy the initial User Area image to the RAM copy
   userarea-t [bx]  si   lea	\ Source address for copy
   sp		    di   mov	\ Destination of copy
   user-size-t #    cx   mov	\ Number of bytes to copy
   cld   rep byte movs

   sp               di   mov	\ Set user pointer
[else]
   userarea-t [bx]  di   lea	\ Source address for copy
[then]

\ XXX need to swap bytes
\ Set main-task so the exception handler can find the user area
   di   'body main-task [bx]  mov

   ?bswap-ax
   ax     'user memtop   mov     \ Set heap pointer

   h# 10 [bx]       ax   mov	\ #args
   ?bswap-ax
   ax      'user #args   mov

   h# 14 [bx]       ax   mov	\ args
   ?bswap-ax
   ax       'user args   mov

\ At this point, the stack pointer has been set to the top of the stack area
\ and the user pointer has been set to the bottom of the initial user area
\ image.

\ Establish the return stack and set the rp0 user variable
   sp        rp          mov	\ Set rp
[ifdef] big-endian-t
   rp ax mov
   ?bswap-ax
   ax        'user rp0   mov
[else]
   rp        'user rp0   mov
[then]
   rs-size-t #  sp       sub    \ allocate space for the return stack

\ Establish the Parameter Stack
[ifdef] big-endian-t
   sp ax mov
   ?bswap-ax
   ax        'user sp0   mov
[else]
   sp        'user sp0   mov
[then]
   sp           ax       mov
   ps-size-t #  ax       sub    \ allocate space for the data stack
   ax      'user limit   mov	\ Set dictionary limit

\ Enter Forth
   'body cold [bx]  ip   lea
c;

create ztc-startup   ( -- )  assembler

\ This is for the Zortech C DOS Extender version which extracts the starting
\ address from location c and jumps directly to it.

forth-h
\ here-t  origin-t h# c +  le-l!-t  \ Address of ztc-startup relative to origin
here-t  h# 0c  token!-t  \ Address of ztc-startup relative to origin
assembler

\ The stack contains:
\ ( Data selector [4 bytes], memory size [4 bytes], return-address [6 bytes] )

   bp push
   sp bp mov
   si push
   di push
   8 [bp] dx mov                \ DX - caller's CS

   ds si  mov		\ SI - caller's DS
   ss di  mov		\ DI - caller's SS
   sp cx  mov		\ CX - caller's SP

   0c [bp] ax mov               \ Memory top
   10 [bp] ds mov
   ds  bx  mov

   bx  ss  mov			\ Get onto new stack
   ax  sp  mov

   \  GS       FS       ES       DS       CS       SS       SP
   gs push  fs push  es push  si push  dx push  di push  cx push  


   dx  h# a #)  op: mov   \ Fix selector of far pointer at origin + 6
                          \ Zortech C appears to store it incorrectly
                          \      memtop @ 8 + le-l@  h# a le-w!
   
   bx  es  mov
   bx  fs  mov
   bx  gs  mov

   cold-code #) jmp		\ Proceed with the usual startup
end-code

create unix-startup   ( -- )  assembler

\ This is the entry point for the Unix wrapper

forth-h
\ here-t  origin-t h# 18 +  le-l!-t  \ Address of unix-startup relative to origin
here-t  h# 18  token!-t  \ Address of unix-startup relative to origin
assembler

\ The stack contains:
\  ( memory top [4 bytes], CS=0 [4 bytes],  return-address [4 bytes] )

   bp push
   sp bp mov
   si push
   di push
   8 [bp] dx mov                \ DX - caller's CS

   ds si  mov		\ SI - caller's DS
   ss di  mov		\ DI - caller's SS
   sp cx  mov		\ CX - caller's SP

   0c [bp] ax mov               \ Memory top
   ax  sp  mov

   \  GS       FS       ES       DS       CS       SS       SP
   gs push  fs push  es push  si push  dx push  di push  cx push  

   cold-code #) jmp		\ Proceed with the usual startup
end-code

create warm-code  ( -- )  assembler
\ Set the base address
\   here-t 4 +        call	\ address of next instruction in spc
\   here-t 4 -  base  set	\ relative address of current instruction
\   spc base    base  sub	\ subtract them to find the base address
\
\ \ Set the User Pointer
\   'body main-task  up set	\ relative address of main-task parameter field
\   up base          up   add	\ absolute address of main-task parameter field
\   up               up   get	\ read the value
\
\   'user sp0        sp   ld	\ Establish the Parameter Stack
\   'user rp0        rp   ld	\ Establish the Return Stack
\   'body warm       ip   set	\ Set IP to execute warm
\   ip base          ip   add

next
meta

decimal

\ : install-warm  ( -- )  warm-code origin  put-branch  ;
\ : install-cold  ( -- )  cold-code origin  put-branch  ;
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
