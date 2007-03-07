\ See license at end of file
purpose: Avoid moving the SMI registers

dev /isa

\ This little hack works around the fact that, for a Cyrix/National
\ 5520 chip, one of the BARs maps a system-management-mode thing
\ that the BIOS tends to use behind our back.  If we remap it, the
\ system hangs.
: init  ( -- )
   " reg" get-my-property  0=  if
      get-encoded-int                                 ( config-adr )
      \ Is this the Cyrix chip?
      dup " config-l@" $call-parent  h# 21078  =  if  ( config-adr )
         \ It it already enabled?
         4 +  " config-w@" $call-parent  h# f  =  if  ( ena-reg )
            0 0  " assigned-addresses"  property
         then
      else                                            ( config-adr )
         drop                                         ( )
      then
   then
   init
;

device-end
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
