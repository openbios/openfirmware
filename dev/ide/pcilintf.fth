\ See license at end of file
\ PCI IDE controller will remain in legacy mode until the OS driver
\ for native PCI IDE is loaded.

: int+  ( adr len n -- adr' len' )  encode-int encode+  ;

my-address my-space  encode-phys  0 int+ 0 int+

\ h# 1f0 0  h# 8100.0000  encode-phys  encode+  0 int+ 8 int+
\ h# 3f6 0  h# 8100.0000  encode-phys  encode+  0 int+ 2 int+
\ h# 170 0  h# 8100.0000  encode-phys  encode+  0 int+ 8 int+
\ h# 376 0  h# 8100.0000  encode-phys  encode+  0 int+ 2 int+
\ my-address my-space  h# 100.0020 + encode-phys encode+  0 int+ h# 10 int+

\ my-address my-space  h# 200.0024 + encode-phys encode+  0 int+ h# 10 int+

h#  1f0 0  h# 8100.0010  encode-phys  encode+  0 int+ 8 int+
h#  3f6 0  h# 8100.0014  encode-phys  encode+  0 int+ 2 int+
h#  170 0  h# 8100.0018  encode-phys  encode+  0 int+ 8 int+
h#  376 0  h# 8100.001c  encode-phys  encode+  0 int+ 2 int+
\ h# f000 0  h# 8100.0020  encode-phys  encode+  0 int+ h# 10 int+
my-address my-space  h# 100.0020 + encode-phys encode+  0 int+ h# 10 int+

" reg" property

: +map-in  ( offset size -- virt )
   >r my-address rot my-space +  r> " map-in" $call-parent
;
: map-out  ( virt size -- )  " map-out" $call-parent  ;

-1 value isa-io-base

\ Map the device into virtual address space
: (map)  ( -- base1 dor1 base2 dor2 )
   my-space 9 + dup " config-b@"  $call-parent
       5 invert and  swap  " config-b!"  $call-parent	\ Legacy mode

   0 0 h# 8100.0000  h# 1.0000  " map-in" $call-parent to isa-io-base

   h# 1f0 isa-io-base +
   h# 3f6 isa-io-base +
   h# 170 isa-io-base +
   h# 376 isa-io-base +

   my-space 4 + dup " config-w@"  $call-parent
        1 or  swap  " config-w!"  $call-parent	\ Enable
;

\ Release the mapping resources used by the device
: (unmap)  ( base1 dor1 base2 dor2 -- )
   my-space 4 + dup " config-w@"  $call-parent
        1 invert and  swap  " config-w!"  $call-parent	\ Disable

   2drop 2drop
   isa-io-base h# 1.0000  " map-out" $call-parent
   -1 to isa-io-base
;
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
