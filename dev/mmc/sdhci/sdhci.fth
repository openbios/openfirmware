purpose: Driver for SDHCI (Secure Digital Host Controller)
\ See license at end of file

\ TODO:
\ Test timeouts
\ Test suspend/resume
\ Check card busy and cmd inhibit bits before sending commands
\ Test stop-at-block-gap
\ Test high speed mode
\ Test 1-bit data mode

\ begin-select /pci/pci11ab,4101

" sd" device-name
0  " #address-cells" integer-property
0  " #size-cells" integer-property

h# 4000 constant /regs

: phys+ encode-phys encode+  ;
: i+  encode-int encode+  ;

0 0 encode-bytes
0 0 h# 0000.0000  my-space +  phys+   0 i+  h# 0000.0100 i+   \ Config registers
0 0 h# 0100.0010  my-space +  phys+   0 i+         /regs i+   \ Frame buffer
" reg" property

0 value debug?

0 value chip

h# 200 constant /block  \ 512 bytes

: map-regs  ( -- )
   chip  if  exit  then
   0 0 h# 0200.0010 my-space +  /regs " map-in" $call-parent
   to chip
;
: unmap-regs  ( -- )
   chip  0=  if  exit  then
   chip  h# 4000  " map-out" $call-parent
   0 to chip
;

: cl!  ( l adr -- )  chip + rl!  ;
: cl@  ( adr -- l )  chip + rl@  ;
: cw!  ( w adr -- )  chip + rw!  ;
: cw@  ( adr -- w )  chip + rw@  ;
: cb!  ( b adr -- )  chip + rb!  ;
: cb@  ( adr -- b )  chip + rb@  ;

\ This is the lowest level general-purpose command issuer
\ Some shorthand words for accessing interrupt registers

\ By the way, you can't clear the error summary bit in the ISR
\ by writing 1 to it.  It clears automatically when the ESR bits
\ are cleared (by writing ones to the ESR bits that are set).
: isr@  ( -- w )  h# 30 cw@  ;
: isr!  ( w -- )  h# 30 cw!  ;
: esr@  ( -- w )  h# 32 cw@  ;
: esr!  ( w -- )  h# 32 cw!  ;

[ifdef] marvell
: enable-sd-int  ( -- )
   h# 300c cl@  h# 8000.0002 or  h# 300c cl!
;
: disable-sd-int  ( -- )
   h# 300c cl@  2 invert and  h# 300c cl!
;
: enable-sd-clk  ( -- )
   h# 3004 cw@  h# 2000 or  h# 3004 cw!
;
: disable-sd-clk  ( -- )
   h# 3004 cw@  h# 2000 invert and  h# 3004 cw!
;
[then]

: clear-interrupts  ( -- )
   isr@ drop  esr@ drop
   h# ffff isr!  \ Clear all normal interrupts
   h# ffff esr!  \ Clear all error interrupts
;

0 instance value sd-clk

: wp?  false  ;  \ XXX FIXME

\ 1 is reset_all, 2 is reset CMD line, 4 is reset DAT line
: sw-reset  ( mask -- )
   h# 2f  2dup  cb!   begin  2dup  cb@  and 0=  until  2drop
;
: reset-host  ( -- )
   0 to sd-clk
   1 sw-reset  \ RESET_ALL
   \ Marvell-specific
   wp?  if  h# 40004 4  else  h# 60006 6  then  h# 3038 cb!  h# 315c cl!
;

: init-dma  ( -- )
\   enable-sd-int   \ Marvell-specific
   /block h# 4000 or  4 cw!  \ h# 400 means 64K DMA boundary
;

: high-speed  ( -- )  h# 28 cb@  4 or  h# 28 cb!  ;
: low-speed   ( -- )  h# 28 cb@  4 invert and  h# 28 cb!  ;

: 4-bit  ( -- )  h# 28 cb@  2 or  h# 28 cb!  ;
: 1-bit  ( -- )  h# 28 cb@  2 invert and  h# 28 cb!  ;

\ : led-on   ( -- )  h# 28 cb@  1 or  h# 28 cb!  ;
\ : led-off  ( -- )  h# 28 cb@  1 invert and  h# 28 cb!  ;

\ There is no need to use the debounced version (the 3.0000 bits).
\ We poll for the card when the SDMMC driver opens, rather than
\ sitting around waiting for insertion/removal events.
\ The debouncer takes about 300 ms to stabilize.

: card-inserted?  ( -- flag )
   h# 24 cl@ h# 40000 and  h# 40000 =
;

: card-power-on  ( -- )
   \ XXX should use the capabilities register (40 cl@) to determine
   \ which power choices are available.
   h# c  h# 29  cb!   \ 3.0V
   h# d  h# 29  cb!   \ 3.0V + on
;
: card-power-off  ( -- )  0  h# 29  cb!  ;

: internal-clock-on  ( -- )
   h# 2c cw@  1 or  h# 2c cw!
   begin  h# 2c cw@  2 and  until
;
: internal-clock-off  ( -- )  h# 2c cw@  1 invert and  h# 2c cw!  ;

: card-clock-on   ( -- )  h# 2c cw@  4 or  h# 2c cw!  ;
: card-clock-off  ( -- )  h# 2c cw@  4 invert and  h# 2c cw!  ;

: data-timeout!  ( n -- )  h# 2e cb!  ;

: setup-host  ( -- )
   reset-host
   internal-clock-on
   init-dma

   h#   00 h# 28 cb!  \ Not high speed, 1-bit data width, LED off
   h# 00fb h# 34 cw!  \ normal interrupt status en reg
                         \ block gap event not enabled
   h# f1ff h# 36 cw!  \ error interrupt status en reg
   h# 0000 h# 38 cw!  \ Normal interrupt status interrupt enable reg
   h# 0000 h# 3a cw!  \ error interrupt status interrupt enable reg

   clear-interrupts
;

0 instance value dma-vadr
0 instance value dma-padr
0 instance value dma-len

: dma-setup  ( #blocks adr -- )
   over 6 cw!            ( #blocks adr ) \ Set block count
   swap /block *         ( adr #bytes )  \ Convert to byte count
   dup to dma-len        ( adr #bytes )  \ Remember for later
   over to dma-vadr      ( adr #bytes )  \ Remember for later
   true  " dma-map-in" $call-parent  ( padr )  \ Prepare DMA buffer
   dup to dma-padr       ( padr )        \ Remember for later
   0 cl!                                 \ Set address
;
: dma-release  ( -- )
   dma-vadr dma-padr dma-len  " dma-map-out" $call-parent
;

: decode-esr  ( esr -- )
   dup h# 8000 and  if   ." Vendor8, "  then
   dup h# 4000 and  if   ." Vendor4, "  then
   dup h# 2000 and  if   ." Vendor2, "  then
   dup h# 1000 and  if   ." Vendor1, "  then
   dup h#  800 and  if   ." Reserved8, "  then
   dup h#  400 and  if   ." Reserved4, "  then
   dup h#  200 and  if   ." Reserved2, "  then
   dup h#  100 and  if   ." Auto CMD12, "  then
   dup h#   80 and  if   ." Current Limit, "  then
   dup h#   40 and  if   ." Data End Bit, "  then
   dup h#   20 and  if   ." Data CRC, "  then

   dup h#   10 and  if   ." Data Timeout, "  then
   dup h#    8 and  if   ." Command Index, "  then
   dup h#    4 and  if   ." Command End Bit, "  then
   dup h#    2 and  if   ." Command CRC, "  then
   dup h#    1 and  if   ." Command Timeout, "  then
   drop  cr
;

: check-error  ( isr -- )
   dup h# 8000 and  if     \ Check for error
      ." Error: ISR = " dup u.  ." ESR = " esr@ dup u.
      dup esr!
      dup decode-esr
      true abort" Stopping"
\      debug-me
   then
   drop
;

: wait  ( mask -- isr )
   h# 8000 or                             ( mask' )
   begin  isr@  2dup and  0=  while       ( mask isr )
\     key?  if  key drop  debug-me  then  ( mask isr )
      drop                                ( mask )
   repeat                                 ( mask isr )
   debug?  if  ." ISR: " dup 4 u.r  cr  then
   tuck and isr!                          ( isr )
   check-error                            ( isr )
;

: cmd  ( arg cmd mode -- )
   debug?  if  ." CMD: " over 4 u.r space   then
   h# c cw!              ( arg cmd )  \ Mode
   swap 8 cl!            ( cmd )      \ Arg
   h# e cw!              ( )          \ cmd
   1 wait                ( )
;

\ start    cmd    arg  crc  stop
\ 47:46  45:40   39:8  7:1     0
\     2      6     32    7     1
\ Overhead is 16 bits

\ Response types:
\ R1: mirrored command and status
\ R3: OCR register
\ R6: RCA
\ R2: 136 bits (CID (cmd 2 or 9) or CSD (cmd 10))
\ In R2 format, the first 2 bits are start bits, the next 6 are
\ reserved.  Then there are 128 bits (16 bytes) of data, then the end bit

\ No need to mask, because cw@ is guaranteed to deliver exactly 16 bits
: response  ( -- l )   h# 10 cl@  ;

: buf+!  ( buf value -- buf' )  over l!  la1+  ;

\ Store in the buffer in little-endian form
: get-response136  ( buf -- )  \ 128 bits (16 bytes) of data.
   h# 20  h# 10  do  i cl@ buf+!  4 +loop  drop
;

0 instance value rca
d# 16 instance buffer: cid

external
d# 16 instance buffer: csd
headers

: reset-card  ( -- )  0 0 0 cmd  0 to rca  ;  \ 0 -

\ Get card ID; Result is in cid buffer
: get-all-cids  ( -- )  0 h# 0209 0 cmd  cid get-response136  ;  \ 2 R2

\ Get relative card address
: get-rca  ( -- )  0 h# 031a 0 cmd  response  h# ffff0000 and  to rca  ; \ 3 R6

: set-dsr  ( -- )  0 h# 0400 0 cmd  ;  \ 4 - UNTESTED

\ cmd6 (R1) is switch-function.  It can be used to enter high-speed mode

: deselect-card  ( -- )   0   h# 0700 0 cmd  ;  \ 7 - with null RCA
: select-card    ( -- )   rca h# 071b 0 cmd  ;  \ 7 R1b

\ Get Card-specific data
: get-csd    ( -- )  rca  h# 0909 0 cmd  csd get-response136  ;  \ 9 R2
: get-cid    ( -- )  rca  h# 0a09 0 cmd  cid get-response136  ;  \ 10 R2 UNTESTED

: stop-transmission  ( -- )  rca  h# 0c1b 0 cmd  ;        \ 12 R1b UNTESTED

: get-status ( -- status )  rca  h# 0d1a 0 cmd  response  ;  \ 13 R1 UNTESTED

: go-inactive  ( -- )  rca  h# 0f00 0 cmd  ;         \ 15 - UNTESTED

: set-blocklen  ( blksize -- )  h# 101a 0 cmd  ;     \ 16 R1 SET_BLOCKLEN

\ Data transfer mode bits for register 0c (only relevant for reads and writes)
\  1.0000  use DMA
\  2.0000  block count register is valid
\  4.0000  auto cmd12 to stop multiple block transfers
\  8.0000  reserved
\ 10.0000  direction: 1 for read, 0 for write
\ 20.0000  multi (set for multiple-block transfers)

: read-single     ( byte# -- )  h# 113a h# 13 cmd  ;  \ 17 R1 READ_SINGLE_BLOCK
: read-multiple   ( byte# -- )  h# 123a h# 37 cmd  ;  \ 18 R1 READ_MULTIPLE
: write-single    ( byte# -- )  h# 183a h# 03 cmd  ;  \ 24 R1 WRITE_SINGLE_BLOCK
: write-multiple  ( byte# -- )  h# 193a h# 27 cmd  ;  \ 25 R1 WRITE_MULTIPLE

: program-csd  ( -- )     0  h# 1b1a 0 cmd  ;  \ R1 27 UNTESTED
: protect     ( group# -- )  h# 1c1b 0 cmd  ;  \ R1b 28 UNTESTED
: unprotect   ( group# -- )  h# 1d1b 0 cmd  ;  \ R1b 29 UNTESTED
: protected?  ( group# -- 32-bits )  h# 1e1a cmd  response  ;  \ 30 R1 UNTESTED

: erase-blocks  ( block# #blocks -- ) \ UNTESTED
   dup  0=  if  2drop exit  then
   1- bounds        ( last first )
   h# 201a 0 cmd    ( last )   \ cmd32 - R1
   h# 211a 0 cmd    ( )        \ cmd33 - R1
   h# 261b 0 cmd               \ cmd38 - R1b (wait for busy)
;

\ cmd40 is MMC

\ See table 4-5 in sandisk spec
\ : lock/unlock  ( -- ) 0 h# 2a1a 0 cmd  ;  \ 42 R1 LOCK_UNLOCK not sure how it works

: app-prefix  ( -- )  rca  h# 371a 0 cmd  ;  \ 55 R1 app-specific command prefix

: set-bus-width  ( mode -- )  app-prefix  h# 61a 0 cmd  ;  \ a6 R1 Set mode

: set-oc ( ocr -- ocr' )  app-prefix  h# 2902 0 cmd  response  ;  \ a41 R3

\ This sends back 512 bits in a single data block.
: app-get-status  ( -- status )  app-prefix  0 h# 12.0d1a 0 cmd  response  ;  \ a13 R1 UNTESTED

: get-#write-blocks  ( -- n )  app-prefix  0 h# 161a 0 cmd  response  ;  \ a22 R1 UNTESTED

\ You might want to turn this off for data transfer, as it controls
\ a resistor on one of the data lines
: set-card-detect  ( on/off -- )  app-prefix  h# 2a1a 0 cmd  ;  \ a42 R1 UNTESTED
: get-scr  ( -- src )  app-prefix  0 h# 331a 0 cmd  response  ;  \ a51 R1 UNTESTED

h# 8008.0000 value oc-mode  \ Voltage settings, etc.
: set-operating-conditions  ( -- )
   begin
      oc-mode set-oc     ( ocr )  \ acmd41
      h# 8000.0000 and   ( card-powered-on? )
   0= while
      d# 10 ms
   repeat
;

: configure-transfer  ( -- )
   2 set-bus-width  \ acmd6 - bus width 4
   4-bit
   h# b data-timeout!   \ 2^24 / 48 MHz = 0.35 sec
   /block set-blocklen  \ Cmd 16
;

external

: attach-card  ( -- okay? )
   card-inserted?  0=  if  false exit  then   

   card-power-on  d# 20 ms  \ This delay is just a guess
   card-clock-on  d# 10 ms  \ This delay is just a guess

   reset-card     \ Cmd 0

   set-operating-conditions  

   get-all-cids   \ Cmd 2
   get-rca        \ Cmd 3 - Get relative card address
   get-csd        \ Cmd 9 - Get card-specific data
   select-card    \ Cmd 7 - Select

   configure-transfer
   true
;

: dma-alloc   ( size -- vadr )  " dma-alloc"  $call-parent  ;
: dma-free    ( vadr size -- )  " dma-free"   $call-parent  ;

: r/w-blocks  ( addr block# #blocks in? -- actual )
   >r               ( addr block# #blocks r: in? )
   rot dma-setup    ( block# r: in? )
   /block *  r>  if  read-multiple  else  write-multiple  then
   2 wait
   dma-release
   dma-len /block /
;

: open  ( -- )
   map-regs
   setup-host
   true
;

: close  ( -- )
   card-clock-off
   card-power-off
   unmap-regs
;

external

new-device
   " sdmmc" " $load-driver" eval drop
finish-device


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
