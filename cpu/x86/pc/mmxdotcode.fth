\ See license at end of file
purpose: Low-level numeric output for tracing startup code

\ Requires MMX registers

protected-mode

label mm0emit  ( mm0: char ax: retadr -- )
   ax mm1 movd
   dx mm4 movd
   
   h# 3fd # dx mov  begin   dx al in   h# 40 # al and  0<> until
   h# 3f8 # dx mov  mm0 ax movd  al dx out
   h# 3fd # dx mov  begin   dx al in   h# 40 # al and  0<> until

   mm4 dx movd
   mm1 ax movd

   ax jmp 
end-code

label mm0dot  ( mm0: n ax: retadr -- )
   ax mm1 movd
   bx mm2 movd
   cx mm3 movd
   dx mm4 movd

   mm0 bx movd
   8 # cx mov

   begin
      bx 4 # rol
      bl al mov

      h# f # al and
      d# 10 #  al  cmp
      >=  if
         ascii a d# 10 - #  al  add
      else
         ascii 0 #  al  add
      then

      al ah mov

      h# 3fd # dx mov  begin   dx al in   h# 40 # al and  0<> until
      3f8 # dx mov  ah al mov   al dx out
   loopa
   h# 3fd # dx mov  begin   dx al in   h# 40 # al and  0<> until
   h# 3f8 # dx mov  h# 20 # al mov  al dx out
   h# 3fd # dx mov  begin   dx al in   h# 40 # al and  0<> until

   mm4 dx movd
   mm3 cx movd
   mm2 bx movd
   mm1 ax movd

   ax jmp 
end-code

label mm0dump  ( mm0: adr mm1: len ax: retadr -- )
   ax mm6 movd
   bx mm5 movd
   cx mm4 movd
   dx mm3 movd
   si mm2 movd

   mm0 si movd
   mm1 cx movd 

   begin
      al lods
      al bl mov

      bl al mov

      4 # al shr
      h# f # al and
      d# 10 #  al  cmp
      >=  if
         ascii a d# 10 - #  al  add
      else
         ascii 0 #  al  add
      then

      al ah mov

      h# 3fd # dx mov  begin   dx al in   h# 40 # al and  0<> until
      3f8 # dx mov  ah al mov   al dx out

      bl al mov

      h# f # al and
      d# 10 #  al  cmp
      >=  if
         ascii a d# 10 - #  al  add
      else
         ascii 0 #  al  add
      then

      al ah mov

      h# 3fd # dx mov  begin   dx al in   h# 40 # al and  0<> until
      3f8 # dx mov  ah al mov   al dx out

      h# 3fd # dx mov  begin   dx al in   h# 40 # al and  0<> until
      
      si ax mov  h# f # al and  0=  if
         h# 0d # al mov   h# 3f8 # dx mov  al dx out
         h# 3fd # dx mov  begin   dx al in   h# 40 # al and  0<> until
         h# 0a # al mov  h# 3f8 # dx mov  al dx out
      else
         h# 20 # al mov  h# 3f8 # dx mov  al dx out
      then

      h# 3fd # dx mov  begin   dx al in   h# 40 # al and  0<> until
   cx dec  0= until

   mm2 si movd
   mm3 dx movd
   mm4 cx movd
   mm5 bx movd
   mm6 ax movd

   ax jmp 
end-code

label mm0cfg-dump  ( mm0: adr mm1: len ax: retadr -- )
   ax mm6 movd
   bx mm5 movd
   cx mm4 movd
   dx mm3 movd
   si mm2 movd

   mm0 si movd
   mm1 cx movd 

   begin
      si ax mov
      h# 7fff.fffc # ax and
      h# 8000.0000 # ax or
      h# cf8 # dx mov
      ax dx out
      si dx mov
      3 # dx and
      h# cfc # dx add
      dx al in
      si inc

      al bl mov

      bl al mov

      4 # al shr
      h# f # al and
      d# 10 #  al  cmp
      >=  if
         ascii a d# 10 - #  al  add
      else
         ascii 0 #  al  add
      then

      al ah mov

      h# 3fd # dx mov  begin   dx al in   h# 40 # al and  0<> until
      3f8 # dx mov  ah al mov   al dx out

      bl al mov

      h# f # al and
      d# 10 #  al  cmp
      >=  if
         ascii a d# 10 - #  al  add
      else
         ascii 0 #  al  add
      then

      al ah mov

      h# 3fd # dx mov  begin   dx al in   h# 40 # al and  0<> until
      3f8 # dx mov  ah al mov   al dx out

      h# 3fd # dx mov  begin   dx al in   h# 40 # al and  0<> until
      
      si ax mov  h# f # al and  0=  if
         h# 0d # al mov   h# 3f8 # dx mov  al dx out
         h# 3fd # dx mov  begin   dx al in   h# 40 # al and  0<> until
         h# 0a # al mov  h# 3f8 # dx mov  al dx out
      else
         h# 20 # al mov  h# 3f8 # dx mov  al dx out
      then

      h# 3fd # dx mov  begin   dx al in   h# 40 # al and  0<> until
   cx dec  0= until

   mm2 si movd
   mm3 dx movd
   mm4 cx movd
   mm5 bx movd
   mm6 ax movd

   ax jmp 
end-code

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
