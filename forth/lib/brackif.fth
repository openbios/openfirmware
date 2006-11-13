\ See license at end of file

\ Adapted from the version published in the ANS Forth spec.
\ That version was originally developed by Mitch Bradley.


: [else]  ( -- )
   1  begin						( level )
      begin  parse-word dup  while			( level adr len )
         $canonical               			( level adr len )
         2dup s" [if]"     $=        >r			( level adr len )
         2dup s" [ifdef]"  $=  r> or >r			( level adr len )
         2dup s" [ifndef]" $=  r> or     if		( level adr len )
	    2drop 1+					( level' )
         else						( level adr len )
	    2dup  s" [else]"  $=  if			( level adr len )
	       2drop 1- dup  if  1+  then		( level' )
	    else					( level adr len )
	       s" [then]"  $=  if  1-  then		( level')
            then					( level' )
	    ?dup 0=  if  exit  then			( level' )
         then						( level' )
      repeat						( level adr len )
      2drop						( level' )
   refill 0= until					( level' )
   drop
; immediate

: [if]  ( flag -- )  0=  if  postpone [else]  then  ; immediate

: [then]  ( -- )  ;  immediate

: [ifdef]  ( "name" -- )
   $defined  nip  dup 0=  if  nip  then  postpone [if]
; immediate

: [ifndef]  ( "name" -- )
   $defined  nip  0= dup  if  nip  then  postpone [if]
; immediate
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
