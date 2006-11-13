\ See license at end of file
purpose: Create COM port nodes

[ifndef] no-com1-node
0 0  " i3f8"  " /isa"  begin-package
[ifdef] PREP
   4 encode-int                          " interrupts" property
[else]
   4 encode-int  3 encode-int encode+    " interrupts" property
[then]

   \ XXX The SuperIO data sheet implies that the clock rate is 24MHz/13, which
   \ is 1,846,153, while the ARC config data says 1,843,200.  The difference
   \ accounts for the 0.2% (actually .16%) error mentioned in the data sheet.
   \ Until we can determine whether or not NT can handle the truth, we will
   \ fudge the data and say it's 1,843,200
   \ d# 1846153 encode-int " clock-frequency" property
   d# 1843200 encode-int " clock-frequency" property

\   fload ${BP}/dev/ns16550a.fth
   fload ${BP}/dev/16550pkg/ns16550p.fth
   fload ${BP}/dev/16550pkg/isa-int.fth
end-package

: com1  ( -- adr len )  " com1"  ;  ' com1 to fallback-device

: use-com1  ( -- )
   " com1" " input-device" $setenv
   " com1" " output-device" $setenv
;
[then]

[ifndef] no-com2-node
0 0  " i2f8"  " /isa"  begin-package
[ifdef] PREP
   3 encode-int                          " interrupts" property
[else]
   3 encode-int  3 encode-int encode+    " interrupts" property
[then]

   d# 1843200 encode-int " clock-frequency" property
\   fload ${BP}/dev/ns16550a.fth
   fload ${BP}/dev/16550pkg/ns16550p.fth
   fload ${BP}/dev/16550pkg/isa-int.fth
end-package

: com2  ( -- adr len )  " com2"  ;
[then]
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
