purpose: Interface to cryptographic code for firmware image validation
\ See license at end of file

h# c0000 constant verify-base  \ The address the code is linked to run at
h# d0000 constant verify-bss   \ The address the code is linked to run at
h# 10000 constant /verify-bss
h# 9c000 constant verify-stack
0 value /verify

0 value crypto-loaded?
: load-crypto  ( -- error? )
   crypto-loaded?  if  false exit  then
   " verify" find-drop-in  0=  if
      ." Can't find crypto code" cr  true exit
   then  ( prog$ )
   dup to /verify                          ( prog$ )
   verify-base /verify 0 mem-claim drop    ( prog$ )
   2dup verify-base swap move  free-mem    ( )
   true to crypto-loaded?
   false
;
: unload-crypto  ( -- )
   crypto-loaded?  0=  if  exit  then
   verify-base /verify mem-release
   false to crypto-loaded?
;

: signature-bad?  ( data$ sig$ key$ hashname$ -- mismatch? )
   $cstr
   verify-bss /verify-bss erase    ( 0 data$ sig$ key$ 'hashname )
   verify-base  verify-stack  sp-call  >r  ( 0 data$ sig$ key$ 'hashname )
   3drop 4drop  begin 0= until             ( )
   r>  ( result )
;

\ This is a hack that saves a lot of memory.  The crypto verifier
\ code has a mode where it will just compute and return the hash value,
\ instead of going on to verify the hash's signature.  In that mode,
\ we use sig$ for the address and length of the result buffer, key-adr
\ to return the actual return length, and pass in key-len = 0 to denote
\ that we want only hashing.

variable hashlen
d# 128 buffer: hashbuf
: crypto-hash  ( data$ hashname$ -- result$ )
   2>r  0 -rot  hashbuf d# 128  hashlen 0  2r>   ( 0 data$ sig$ key$ hashname$ )
   signature-bad?  h# fffff and  abort" Hash failed"   ( )
   hashbuf hashlen @
;

\ Another hack - if the hashname is "des", the arguments to signature-bad?
\ are  ( 0 plain$ cipher$ key$ hashname$="des" -- error? )
\ plain$, cipher$, and key$ are all 8-byte arrays - ciper$ is output
: des  ( data$ key$ -- result$ )
   2>r  0 -rot  hashbuf 8  2r>  " des"   ( 0 data$ ciper$ key$ hashname$ )
   signature-bad?  h# fffff and  abort" DES failed"   ( )
   hashbuf 8
;




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
