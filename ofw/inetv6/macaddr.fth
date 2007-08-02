\ See license at end of file
purpose: MAC (Ethernet) address reporting and display functions

headers
false config-flag local-mac-address?
: mac-address		( -- adr len )
   local-mac-address? if
      " local-mac-address" get-inherited-property 0=  if  ( adr len )
         dup 6 =  if   exit   else  2drop  then
      then
   then

   \ Didn't get a valid "local-mac-address" property, so use the system one
   system-mac-address    ( adr len )
;

\ Display Ethernet address
: u..  ( n -- )  (.2) type  ;
: .enaddr  ( addr-buff -- )
   push-hex
   5 0 do  dup c@ u.. 1+  ." :"  loop  c@ u..
   pop-base
;
headers
: .enet-addr  ( -- )  system-mac-address drop  .enaddr  ;
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
