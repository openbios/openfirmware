purpose: Interface to Via "Padlock" hardare random number generator

: enable-padlock  ( -- )  cr4@ h# 200 or cr4!  ;  \ SSE enable

code random-bytes  ( adr len -- )
   cr4 ebx mov  ebx eax mov  h# 200 # eax or  eax cr4 mov
   cx pop
   0 [sp] di xchg
   3 # dx mov
   begin
      h# 0f c, h# a7 c, h# c0 c,
      ax cx sub
   0= until
   0 [sp] di xchg
   ebx cr4 mov
c;
code random-byte  ( -- n )
   cr4 ebx mov  ebx eax mov  h# 200 # eax or  eax cr4 mov
   ax ax xor  ax push
   di cx mov
   sp di mov
   3 # dx mov
   begin
      h# 0f c, h# a7 c, h# c0 c,
      ax ax or
   0<> until
   cx di mov
   ebx cr4 mov
c;

create sha256-constants
h# 6A09E667 , h# BB67AE85 , h# 3C6EF372 , h# A54FF53A ,
h# 510E527F , h# 9B05688C , h# 1F83D9AB , h# 5BE0CD19 ,

d# 128 d# 16 +  buffer: (sha-buf)
: sha-buf  (sha-buf) d# 16 round-up  ;

code do-sha  ( inbuf len outbuf -- )
   ax pop
   cx pop
   0 [sp] si xchg
   di push
   ax di mov
   ax ax xor
   rep  h# 0f c,  h# a6 c,  h# d0 c,   
   di pop
   si pop
c;
: init-sha  ( -- )  sha256-constants sha-buf d# 32 move  ;
: sha-256  ( adr len -- adr' len' )
   enable-padlock
   init-sha
   sha-buf do-sha
   sha-buf h# 20  2dup lbflips
;

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
