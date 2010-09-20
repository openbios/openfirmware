purpose: Early-startup code for Conexant CX2058x codec
\ See license at end of file

\ This runs at early startup time when the system is still running assembly
\ language.  It is used both for cold boot and for resume from S3.
\ It compiles a verb table and blasts it out to the codec as quickly as possible.
\ The reason we need to do this is to ensure that the critical settings for
\ thermal and overcurrent protection in the Vendor node are always applied,
\ especially in the resume-from-S3 case where we have no opportunity to run
\ Forth code.  Secondarily, we also get a chance to set the Configuration
\ Default registers.

\ Put the words for compiling the verb table in the transient dictionary so
\ the don't take up space in the ROM image
transient

0 value codec
0 value node

: set-node  ( node-id -- )  to node  ;

fload ${BP}/dev/hdaudio/cx2058x-nodes.fth  \ Node names

fload ${BP}/dev/hdaudio/config.fth    \ Names for configuration settings

0 value #verbs

: place-verb  ( verb+data -- )
   node d# 20 lshift or
   codec d# 28 lshift or
   ,
   #verbs 1+ to #verbs
;
: config-verb  ( data-byte verb-code -- )
   8 lshift  or  place-verb
;
: )config  ( value -- )
   h# f0 or                   ( value )  \ Null association
   lbsplit  swap 2swap swap   ( high hmid lmid low )
   h# 71c config-verb
   h# 71d config-verb
   h# 71e config-verb
   h# 71f config-verb
;

: start-verb-table  ( -- )
   " 0 to #verbs  label verb-table" evaluate
;
: end-verb-table  ( -- )  ;

h# 100000 constant corb   \ Physical address of DMA command buffer
h# 101000 constant rirb   \ Physical address of DMA response buffer

resident

hex
start-verb-table
   porta  f0700 place-verb  \ This is sacrificial, in case of problems with the first command

   porta  config(  1/8" green left hp-out jack     )config
   porta  config(  1/8" green left hp-out jack     )config
   portb  config(  1/8" pink left mic-in jack      )config
   portc  config(  builtin internal top mic-in no-detect other-analog )config
   portd  config(  unused line-out no-detect       )config
   porte  config(  unused line-out no-detect       )config
   portf  config(  unused line-out no-detect       )config
   portg  config(  builtin internal front speaker no-detect other-analog )config
   porth  config(  unused line-out no-detect       )config
   porti  config(  unused line-out no-detect       )config
   portj  config(  unused line-out no-detect       )config
   portk  config(  unused line-out no-detect       )config

   vendor  \ Vendor node

   \ Codec registers
   21000 place-verb      \ Undocumented register
   22000 place-verb      \ Undocumented register
   23000 place-verb      \ Undocumented register
   24000 place-verb      \ Undocumented register
   25000 place-verb      \ Undocumented register
   26000 place-verb      \ Undocumented register
   27000 place-verb      \ Undocumented register
   28000 place-verb      \ Undocumented register
   290a8 place-verb      \ high-pass filter, semi-manual mode, 600Hz cutoff \ Conexant: 29088 - 150Hz
   2A000 place-verb      \ low-pass filter (for subwoofers) off
   2B002 place-verb      \ Undocumented register
   2C020 place-verb      \ Undocumented register
   2D000 place-verb      \ Undocumented register
   2E000 place-verb      \ Undocumented register
   2F000 place-verb      \ Undocumented register  \ Conexant once recommended 2f800 but now are saying 2f000
                                                  \ 800 enables a debounce delay for class-D overcurrent;
                                                  \ the latest info is that no-debounce provides better protection
   \ Analog registers
   31000 place-verb      \ Undocumented register
   32000 place-verb      \ Undocumented register
   33000 place-verb      \ Undocumented register
   34003 place-verb      \ Maximum output power for speaker - see Class-DSpeakerPower.pdf
   35000 place-verb      \ Undocumented register
   3600A place-verb      \ Undocumented register
   37000 place-verb      \ Undocumented register
   38022 place-verb      \ over-current / short-circuit protection, 2.6A threshold
   39057 place-verb      \ temperature protection at 79.5C
   3A000 place-verb      \ Undocumented register
   \ Digital registers
   4154d place-verb      \ Undocumented register \ Conexant once recommended 41541 but now are saying 4154d
                                                 \ "d" instead of "1" turns on Intel ECR15B support, which
                                                 \ is apparently needed for Window WHQL certification.
   42011 place-verb      \ over-temperature shutdown of class-D amplifier
   43000 place-verb      \ This documented as a status register and thus is presumably read-only.  Why write to it?
   44000 place-verb      \ Undocumented register
   45600 place-verb      \ Undocumented register
   4600C place-verb      \ Undocumented register
   4701F place-verb      \ Undocumented register
   48004 place-verb      \ Undocumented register
   49040 place-verb      \ Undocumented register
   4C000 place-verb      \ Undocumented register

   afg  \ Audio Function Group node

   71C00 place-verb      \ Undocumented register
   71D00 place-verb      \ SPDIF OFF BUT Int-Mic on        \ Undocumented register
   71E00 place-verb      \ Undocumented register
   71F00 place-verb      \ disable software GSMark protection
   71F00 place-verb      \ disable software GSMark protection - repeat in case of end condition issues
   72033 place-verb      \ Low byte of product ID
   72108 place-verb      \ High byte of product ID
   7222d place-verb      \ Low byte of vendor ID
   72315 place-verb      \ High byte of vendor ID
end-verb-table

\ Subroutine to turn on the HD Audio controller, push the verb table to the codec,
\ then turn things back off.

label init-codec
   hdac-pci-base h# a010 config-wl  \ Set PCI base address for HD Audio
   6 h# a004 config-ww              \ Enable it for memory space and bus mastering

   h# 01 #  hdac-pci-base h# 08 + #)  mov  \ Release controller reset

   h# 1000 # cx mov    \ Maximum number of wait loop iterations
   begin
      h# 80 # al in    \ ~1us delay
      cx dec  0<>  if  \ Not timeout
         hdac-pci-base h# 08 + #)  ax  mov  \ wait for controller to come out of reset
         1 # al test
      else
         cx inc        \ Force exit from loop
      then
   0<> until

   d# 350 wait-us   \ Wait for Codec to wake up (250 needed; extra for good measure)

   h# 00 #  hdac-pci-base h# 4c + #)  byte  mov  \ CORB DMA off

   h# 1000 # cx mov    \ Maximum number of wait loop iterations
   begin
      h# 80 # al in   \ ~1us delay
      cx dec  0<>  if  \ Not timeout
         hdac-pci-base h# 4c + #)  al  mov  \ wait for CORB DMA off
         2 # al test
      then
   0= until

       corb #  hdac-pci-base h# 40 + #)       mov  \ CORB lower base address
          0 #  hdac-pci-base h# 44 + #)       mov  \ CORB upper base address
op:       0 #  hdac-pci-base h# 48 + #)       mov  \ CORB write pointer
op: h# 8000 #  hdac-pci-base h# 4a + #)       mov  \ CORB read pointer reset
          2 #  hdac-pci-base h# 4e + #)  byte mov  \ CORB size - 256 entries

          2 #  hdac-pci-base h# 4c + #)  byte mov  \ CORB DMA on

   h# 00 #  hdac-pci-base h# 5c + #)  byte  mov  \ RIRB DMA off

   h# 1000 # cx mov    \ Maximum number of wait loop iterations
   begin
      h# 80 # al in   \ ~1us delay
      cx dec  0<>  if  \ Not timeout
         hdac-pci-base h# 5c + #)  al  mov  \ wait for RIRB DMA off
         2 # al test
      then
   0= until

       rirb #  hdac-pci-base h# 50 + #)       mov  \ RIRB lower base address
          0 #  hdac-pci-base h# 54 + #)       mov  \ RIRB upper base address
op: h# 8000 #  hdac-pci-base h# 58 + #)       mov  \ RIRB write pointer reset
          2 #  hdac-pci-base h# 5e + #)  byte mov  \ RIRB size - 256 entries

          2 #  hdac-pci-base h# 5c + #)  byte mov  \ RIRB DMA on

   \ Copy the verb table to the CORB DMA area
   #verbs # cx mov
   verb-table asm-base - asm-origin + # si mov
   corb # di mov
   rep movs

   op:  #verbs #  hdac-pci-base h# 48 + #)  mov   \ Hand off the verbs by setting the CORB write pointer

   h# 1000 # cx mov    \ Maximum number of wait loop iterations
   begin
      h# 80 # al in   \ ~1us delay
      cx dec  0<>  if  \ Not timeout
         op: hdac-pci-base h# 4a + #)  ax  mov     \ Read CORB read pointer to catch up with write pointer
         op: #verbs #  ax  cmp                     \ Wait for it to catch up
      then
   0= until

   h# 1000 # cx mov
   begin
      h# 80 # al in   \ ~1us delay
      cx dec  0<>  if  \ Not timeout
         op: hdac-pci-base h# 58 + #)  ax  mov     \ Read RIRB write pointer
         op: #verbs 1- #  ax  cmp                  \ Wait for it to catch up
      then
   0= until

   d# 100 wait-us  \ Just in case

   h# 00 #  hdac-pci-base h# 4c + #)  byte  mov    \ CORB DMA off
   h# 00 #  hdac-pci-base h# 5c + #)  byte  mov    \ RIRB DMA off
   h# 00 #  hdac-pci-base h# 08 + #)  mov          \ Reset controller

   0 h# a004 config-ww              \ Disable memory space and bus mastering

   ret
end-code


\ LICENSE_BEGIN
\ Copyright (c) 2010 FirmWorks
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
