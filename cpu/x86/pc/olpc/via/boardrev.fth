purpose: Determine the board revision based on hardware and EC info
\ See license at end of file

0 value board-revision

: atest?  ( -- flag )  board-revision h# d10 <  ;

\ Constructs a string like "B4" or "preB4" or "postB4"
: model-name$  ( -- model$ )
   board-revision  h# 10 /mod               ( minor major )
   swap  dup 8 =  if                        ( major minor )
      drop " "                              ( major prefix$ )
   else                                     ( major minor )
      8 <  if  " pre"  else  " post"  then  ( major prefix$ )
   then                                     ( major prefix$ )
   push-hex
   rot <# u# u# drop hold$ 0 u#>            ( adr len )
   pop-base
   2dup + 2-  2  upper                      ( model$ )  \ Upper case for base model
;

: enable-uart  ( -- )  h# 40 h# 8846 config-b!  ;

warning @ warning off
\ Do this in stand-init-io so the serial port is enabled prior
\ to the early interact point
: stand-init-io
   stand-init-io

[ifndef] notdef
   ['] board-id@ catch  if  0  then   case
      0      of  0       endof  \ EC broken
      ( board-id )  dup h# 10 * 8 +  swap  \ E.g. b3 -> b38
   endcase
[else]
   \ wait-ib-empty
   \ autowack-off
   0 h# 68 pc!
   h# d08
[then]

   to board-revision

   \ Cache the board revision in CMOS RAM so the early startup code
   \ can get it without having to wait for the EC.
   board-revision dup h# 82 cmos!  invert h# 83 cmos!
;
warning !

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
