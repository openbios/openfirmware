purpose: Interface to cryptographic code for firmware image validation
\ See license at end of file

h# c0000 constant crypto-base  \ The address the code is linked to run at
h# c0000 constant hasher-base  \ The address the code is linked to run at

variable hashlen
d# 128 buffer: hashbuf

: hash  ( data$ hashname$ -- result$ )
   " hasher" find-drop-in  0=  if  4drop true exit  then  ( data$ hashname$ prog$ )
   2dup hasher-base swap move  free-mem          ( data$ hashname$ )

   d# 128 hashlen !      
   2>r  swap  hashlen hashbuf  2swap  2r> $cstr  ( &reslen resbuf datalen databuf hashname-cstr )

   hasher-base  dup h# 10 -  sp-call  abort" Hash failed"  drop 4drop  ( )
   hashbuf hashlen @
;

h# f value which-hashes
: signature-bad?  ( data$ sig$ -- mismatch? )
   " crypto" find-drop-in  0=  if  4drop true exit  then  ( data$ sig$ prog$ )
   2dup crypto-base swap move  free-mem                   ( data$ sig$ )
      
   " pubkey" find-drop-in  0=  if  4drop true exit  then  ( data$ sig$ key$ )
   2>r                 ( data$ sig$ r: key$ )
   swap  2swap  swap   ( siglen sigadr datalen dataadr r: key$ )
   2r@ swap  2swap     ( siglen sigadr keylen keyadr datalen dataadr r: key$ )

   which-hashes

   crypto-base  dup h# 10 -  sp-call  >r  3drop 4drop  r>  ( result  r: key$ )
   2r> free-mem

\ XXX free-mem in suspend.fth and fw.bth after find-drop-in
\ XXX clean out dead code in usb.fth
;

1 [if]

\ Check that the version is an upgrade?

: >rom-name$  ( device$ -- path$ )
   image-name-buf place                      ( )
   " :\boot\olpcfw.rom" image-name-buf $cat  ( )
   image-name$
;
: sig-name$  ( -- path$ )
   image-name$ + 4 -  " .rom" caps-comp 0=  if
      " sig"  image-name$ + 3 -  swap move
      image-name$
   else
      2drop  " "
   then
;
: $dev-update-flash  ( device$ -- )
   >rom-name$  $get-image  if  exit  then          ( data$ )

   sig-name$ $get-image  if
      ." Missing firmware update signature file: " sig-name$ type  cr
      free-mem exit
   then   ( data$ sig$ )  

   2over 2over  signature-bad?  if                 ( data$ sig$ )
      ." Firmware update image signature mismatch: " sig-name$ type  cr
      free-mem  free-mem  exit
   then                                            ( data$ sig$ )

   free-mem                                        ( data$ )

   2dup flash-buf swap move                        ( data$ )
   tuck free-mem                                   ( data-len )
   ['] ?image-valid  catch  if                     ( x )
      drop  ." Firmware image failed sanity checks" cr  ( )
      exit
   then                                            ( x )

   true to file-loaded?
   reflash
;
[then]

: getbin     " usb8388.bin" find-drop-in 0= abort" No usb8388.bin"  ;
: getsig     " usb8388.sig" find-drop-in 0= abort" No usb8388.sig"  ;
: tc  ( -- )
   getbin  getsig
   signature-bad?  if
      ." Signature was bad, expected good" cr
   then

   getbin  over 1 swap +!
   getsig
   signature-bad?  0=  if
      ." Signature was good, expected bad (corrupt image)" cr
   then

   getbin
   getsig  over 40 +  1 swap +!
   signature-bad?  0=  if
      ." Signature was good, expected bad (corrupt signature)" cr
   then
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
