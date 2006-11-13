\ See license at end of file
purpose: Register access words

\ These versions of the "r" words treat addresses in the top 64K
\ as I/O addresses, performing I/O cycles instead of memory cycles.

\ Equivalent to:
\ : rb@  ( adr -- b )
\    dup h# ffff.0000 u>=  if  h# ffff and pc@  else  c@  then
\ ;

code rb@  ( adr -- b )
   dx pop
   ax  ax  xor
   h# ffff.0000 #  dx  cmp
   u>=  if
      h# ffff #  dx  and
      dx  al  in
   else
      0 [dx]  al  mov
   then
   ax push
c;
code rw@  ( adr -- w )
   dx pop
   ax  ax  xor
   h# ffff.0000 #  dx  cmp
   u>=  if
      h# ffff #  dx  and
      op:  dx  ax  in
   else
      op:  0 [dx]  ax  mov
   then
   ax push
c;
code rl@  ( adr -- l )
   dx pop
   h# ffff.0000 #  dx  cmp
   u>=  if
      h# ffff #  dx  and
      dx  ax  in
   else
      0 [dx]  ax  mov
   then
   ax push
c;
code rb!  ( b adr -- )
   dx pop
   ax pop
   h# ffff.0000 #  dx  cmp
   u>=  if
      h# ffff #  dx  and
      al  dx  out
   else
      al  0 [dx]  mov
   then
c;
code rw!  ( w adr -- )
   dx pop
   ax pop
   h# ffff.0000 #  dx  cmp
   u>=  if
      h# ffff #  dx  and
      op:  ax  dx  out
   else
      op:  ax  0 [dx]  mov
   then
c;
code rl!  ( l adr -- )
   dx pop
   ax pop
   h# ffff.0000 #  dx  cmp
   u>=  if
      h# ffff #  dx  and
      ax  dx  out
   else
      ax  0 [dx]  mov
   then
c;
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
