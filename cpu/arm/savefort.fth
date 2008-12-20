purpose: Save the Forth dictionary image in a file in ARM image format
\ See license at end of file

\ save-forth  ( filename -- )
\       Saves the Forth dictionary to a file so it may be later used under Unix
\
\ save-image  ( header-adr header-len init-routine-name filename -- )
\       Primitive save routine.  Saves the dictionary image to a file.
\       The header is placed at the start of the file.  The latest definition
\       whose name is the same as the "init-routine-name" argument is
\       installed as the init-io routine.

hex

variable dictionary-size

only forth also hidden also
hidden definitions

headerless

: dict-size  ( -- size-of-dictionary )  here origin -  aligned  ;
: rel-size  ( -- reloc-size )  dict-size  d# 31 +  d# 32 /  ;

headers

only forth also hidden also
forth definitions

h# 80 buffer: aif-header
   \ 00 NOP (BL decompress code)
   \ 04 NOP (BL self reloc code)
   \ 08 NOP (BL ZeroInit code)
   \ 0c BL entry (or offset to entry point for non-executable AIF header)
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

decimal

: aif!  ( n offset -- )  aif-header + !  ;
: nop!  ( offset -- )  h# e1a00000 swap aif!  ;

headerless
: $save-image  ( header header-len filename$ -- )
   $new-file                                  ( header header-len )

   relocation-off
   \ There is no need to copy the user area to the initial user area
   \ image because the user area is currently accessed in-place.

   ( header header-len )    ofd @  fputs      \ Write header
   origin  dict-size        ofd @  fputs      \ Write dictionary
   relocation-map rel-size  ofd @  fputs      \ Write the relocation table
   ofd @ fclose
   relocation-on
;
: make-arm-header  ( -- )
   \ Build the header
   aif-header    h# 80 erase
                 h# 00 nop!
                 h# 04 nop!
                 h# 08 nop!
   h# eb00001b   h# 0c aif!  \ branch to just after the header
   h# ef000011   h# 10 aif!  \ SWI_Exit
   h# 80         h# 14 aif!  \ Read-only image size = header size
   dict-size rel-size +  h# 18 aif!  \ Read-write size
   0             h# 1c aif!
   0             h# 20 aif!
   0             h# 24 aif!
   h# 8000       h# 28 aif!  \ Load base
   dictionary-size @  h# 8.0000 max  h# 2c aif!  \ Dictionary growth size
   h# 20         h# 30 aif!  \ 32-bit address mode
   0             h# 34 aif!
\   dict-size     h# 38 aif!  \ Dictionary size (Using a reserved field!)
\   origin        h# 3c aif!  \ Save base       (Using a reserved field!)
                 h# 40 nop!
   dict-size     h# 10 origin+ !  \ Dictionary size
   origin        h# 14 origin+ !  \ Save base
;
headers

\ Save an image of the target system in a file.
: $save-forth  ( str -- )
   2>r
   make-arm-header
   " sys-init-io" $find-name is init-io
   " sys-init"    init-save

   aif-header  h# 80  2r>  $save-image
;

only forth also definitions

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
