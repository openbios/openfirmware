\needs start-assembling  fload ${BP}/cpu/x86/asmtools.fth
\needs write-dropin      fload ${BP}/forth/lib/mkdropin.fth

fload ${BP}/cpu/x86/mmuparam.fth

hex

fload ${BP}/cpu/x86/pc/finddi.fth	\ find-dropin and other tools

h#  3e.0000 constant inflate-base
h#  30.0000 constant workspace

start-assembling
protected-mode

label my-entry
   e9 c,  0 ,				\ To be patched later
end-code

[ifdef] debug-startup
fload ${BP}/cpu/x86/pc/dot.fth		\ Numeric output
[then]

fload ${BP}/cpu/x86/pc/romfind.fth	\ find-dropin

label testsub
   ret
end-code

label startup
   cli cld

   80  70  isa-c!			\ Disable NMI
   71 # dx mov  dx al in		\ Why do we do this?

   " start" $find-dropin,   \ Assemble call to find-dropin with literal arg
   \ What should we do it this fails?  Perhaps call a default routine
   \ to try to initialize com1 and display a message?
   \ For now, we assume success

   d# 32 #  ax  add				\ Skip dropin header

   \ This is effectively a CALL, but since memory isn't on yet, we can't
   \ use the stack, so an actual call instruction won't work.  Instead,
   \ we explicitly calculate the return address and put it in the SP register.
   \ The routine that we call has to know that, and return via that register,
   \ instead of just doing a "ret".

   here 7 + asm-base - ResetBase + #  sp  mov	\ Put return address in sp
   ax jmp					\ Execute the dropin

   \ Return here with memory turned on
   h# 8.0000 #  sp  mov

   \ Now we can use the stack and do conventional subroutine calls

[ifdef] debug-startup
init-com1

carret report
linefeed report
ascii F report
ascii o report
ascii r report
[then]

\ fload ${BP}/cpu/x86/pc/ramtest.fth

0 [if]
ax ax xor
h# 12345678 #  bx mov
bx 0 [ax] mov
h# 5555aaaa #  4 [ax] mov
0 [ax] dx  mov
dx bx cmp  <>  if  ascii B report  ascii A report  ascii D report  begin again  then
[then]

   fload ${BP}/cpu/x86/pc/resetend.fth
end-code

also 386-assembler
startup  my-entry  put-branch
previous

end-assembling

writing romreset.di
asm-base  here over -  0  " reset" write-dropin
ofd @ fclose

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
