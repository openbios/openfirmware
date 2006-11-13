\ See license at end of file
purpose: Simple serial downloading

: gettext  ( adr len -- adr actual )
   bounds 2dup  ?do                  ( end start )
      diag-key  dup control D =  if  ( end start  char )
         drop  nip  i swap  leave    ( end' start )
      then                           ( end start  char )
      i c!
   loop                              ( end' start )
   tuck -                            ( adr actual )
;

: sload  ( -- )
   cleanup
   ." Ready for download.  Send file then type ^D"  cr
   load-base h# 20000
   \ Turn off interrupts for now because the interrupt handler takes too long
   \ and we lose characters.
   lock[  ['] gettext  catch  ]unlock  ?dup  if  throw  then  ( adr len )
   !load-size  drop
;
: dl  ( -- )  sload  loaded include-buffer  ;
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
