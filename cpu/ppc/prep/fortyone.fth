purpose: Load image handler for PR*P/IBM "0x41" boot partition format
\ See license at end of file

defer set-aix-modes		' noop to set-aix-modes

[ifndef] residual-data
0 value residual-data

defer make-aix-l2-cache		' noop to make-aix-l2-cache
defer make-residual-data	' noop to make-residual-data
[then]

warning @  warning off
: init-program  ( -- )
   loaded  h# 400 round-up  swap h# 204 + le-l@  h# 400 round-up  =  if
      \ Mostly we don't care about the addresses, but we must be in real
      \ mode, big-endian, pr*p memory map.
      \ chrp?    <addresses>  real?  le?
      false    -1 -1 -1 -1 -1 true false test-modes
      ?mode-restart

      make-aix-l2-cache  make-residual-data

      loaded  sync-cache
      load-base h# 200 + le-l@  load-base +  load-base  (init-program)

      residual-data to %r3
      load-base to %r4

      msr@  h# 8030 invert and  to %msr	\ disable translations
   
      set-aix-modes

      exit
   then
   \ Otherwise, try other formats
   init-program
;

\ Handle IBTA format, i.e., AIX bootable tape images.
\ Block 0 (at load-base) contains a partition map.  Assume the first
\ entry in the map describes this image.
: init-program  ( -- )
   load-base be-l@ h# c9c2d4c1 ( "IBTA" in EBCDIC! ) =  if
      loaded  over  h# 1c6 + le-l@  /sector *    ( load-adr,len offset )
      /string                                    ( image-adr,len )
      dup !load-size                             ( image-adr,len )
      load-base swap move                        ( )
   then
   \ Fall through to regular 41-format handler
   init-program
;
warning !

\ LICENSE_BEGIN
\ Copyright (c) 1997 FirmWorks
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

