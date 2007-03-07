\ See license at end of file
purpose: Save file in pre-relocated format

hex

only forth also definitions

0 value romcrc


: putbyte   ( b -- )   romcrc over crcgen to romcrc
                       ofd @ fputc  ;
: putword   ( w -- )   wbsplit swap putbyte putbyte  ;
: putlong   ( l -- )   lwsplit swap putword putword  ;

0 value target-origin 
0 value offset

: write-image   ( a n -- )
   bounds do
      i >relbit bittest if
	i l@ offset + putlong   /l
      else
	i w@          putword   /w
      then
   +loop
;

defer header-hook  ' noop is header-hook

: save-r-image  ( filename$ base-adr len -- )
   is code-size  is code-adr	( filename$ )
   $new-file
   header-hook
   target-origin origin - to offset
   relocation-off
   code-adr  code-size  write-image
   relocation-on
;

: save-abs-rom  ( filename$ base -- )
   ['] wrapper-vectors behavior >r
   ['] forth-vectors   behavior >r
   ['] noop to wrapper-vectors
   ['] noop to forth-vectors
   patchboot
   
   align   

   to target-origin
   " stand-init" init-save

   " stand-init" $find drop  is init-environment
   " startup" $find drop  is cold-hook

   " stand-init-io" $find drop  is init-io

   origin h# 10 +  8  erase		\ Clear #args,args argument locations
   target-origin  origin h# 1c +  le-l!	\ Set relocation base address

   \ Set user initialization table
   up@ init-user-area origin + user-size  move  ( pstr )

   h# ffff to romcrc

   origin  here over -  save-r-image

   ofd @ fclose

   r> to forth-vectors
   r> to wrapper-vectors
;

only forth also definitions

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
