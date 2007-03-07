\ See license at end of file

\ Output Formatting
decimal
headerless

variable lmargin    0 lmargin !
variable rmargin   79 rmargin !
: ?line  (s n -- )
   #out @ +    rmargin @ >  if  cr  lmargin @ spaces  then
;
: ?cr  (s -- )  0 ?line  ;
: to-column  (s column -- )  #out @  -  1 max spaces  ;

variable tabstops  8 tabstops !
: ?to-column ( string-length starting-column -- )
   tuck + rmargin @ >  if
      drop cr  lmargin @ spaces
   else
      #out @ - spaces
   then
;
: .tab  ( string-length -- )
   \ Find the next tab stop after the current cursor position
   rmargin @ tabstops @ +  dup lmargin @  do   ( string-length target-column )
      i  #out @   >=  if  drop i leave  then   ( string-length target-column )
   tabstops @ +loop                            ( string-length target-column )
   ?to-column
;
headers
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
