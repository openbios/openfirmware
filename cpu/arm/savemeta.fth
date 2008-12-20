purpose: Save the metacompiled kernel into a relocatable binary
\ See license at end of file

\ Binary relocation table stuff
\ The relocation information in a binary file appears after the data segment.
\ The relocation table is a bit map with one bit for every 32-bit word
\ in the binary image.  A one bit means that the longword is to be relocated.

\ Binary file header

only forth labels also forth also definitions

hex
create aif-header forth
        80 allot  aif-header  80 erase
        \ 00 NOP (BL decompress code)
        \ 04 NOP (BL self reloc code)
        \ 08 NOP (BL ZeroInit code)
	\ 0c BL entry
        \ 10 NOP (program exit instruction)
        \ 14 0   (Read-only section size)
        \ 18 Dictionary size, actual value will be set later
        \ 1c Reloc Size (ARM Debug size)
        \ 20 0 (ARM zero-init size)
        \ 24 0 (image debug type)
        \ 28 Reloc save base (image base)
        \ 2c Dictionary growth size (min workspace size)
        \ 30 d#32 (address mode)
        \ 34 0 (data base address)
        \ 38 reserved
        \ 3c reserved
        \ 40 NOP (debug init instruction)
        \ 44-7c unused (zero-init code)

only forth also meta also forth-h also definitions

: text-base     ( -- adr-t )    origin-t  ;
: text-size     ( -- n )        here-t text-base -  ;
: reloc-size    ( -- n )        text-size  1f +  5 >>  ;

: aif!  ( n offset -- )  aif-header + l-t!  ;
: nop!  ( offset -- )  th e1a00000 swap aif!  ;

\ Save an image of the target system in a file.
: $save-meta     ( name$ -- )
        $new-file
        \ Build and output the header
                   00 nop!
                   04 nop!
                   08 nop!
        eb00001b   0c aif!     \ branch to just after the header
        ef000011   10 aif!  \ SWI_Exit
        80         14 aif!  \ Read-only image size = header size
        text-size reloc-size +  18 aif!  \ Read-write size
        0          1c aif!
        0          20 aif!
        0          24 aif!
        8000       28 aif!  \ Relocation save base
        8.0000     2c aif!  \ Dictionary growth size
        20         30 aif!  \ 32-bit address mode
        0          34 aif!
\        text-size  38 aif!  \ Dictionary size (Using a reserved field!)
\        0          3c aif!  \ Save base       (Using a reserved field!)
                   40 nop!
        text-size  origin-t h# 10 + l!-t  \ Dictionary size
        0          origin-t h# 14 + l!-t  \ Save base

        aif-header 80                  ofd @  fputs
        text-base >hostaddr text-size  ofd @  fputs \ Text image
        relocation-map   reloc-size    ofd @  fputs \ Relocation map

        ofd @ fclose
;

\ LICENSE_BEGIN
\ Copyright (c) 2008 FirmWorks
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
