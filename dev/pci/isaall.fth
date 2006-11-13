\ See license at end of file
purpose: Create nodes for the usual complement of ISA devices

fload ${BP}/dev/pci/isacom.fth			\ Serial ports

[ifndef] no-lpt
0 0  " i378"  " /isa" begin-package
fload ${BP}/dev/pci/isalpt.fth			\ Parallel port
end-package

\ : probe-lpt   ( -- )
\    0 0  " i3bc"  " /isa" begin-package
\    " parallel" do-drop-in
\    end-package
\ ;
[then]

[ifndef] no-floppy-node
0 0  " i3f0"  " /isa" begin-package
fload ${BP}/dev/isafdc/loadfdc.fth		\ Floppy
end-package

also forth definitions
: probe-floppy  ( -- )  " /isa/fdc" " probe" execute-device-method drop  ;
previous definitions

devalias floppy /isa/fdc/disk
[then]

[ifndef] no-keyboard
fload ${BP}/dev/pci/isakbd.fth			\ Keyboard and mouse
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
