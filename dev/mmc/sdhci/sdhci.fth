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

" sdhci" " compatible" string-property

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

: my-w@  ( offset -- w )  my-space + " config-w@" $call-parent  ;
: my-w!  ( w offset -- )  my-space + " config-w!" $call-parent  ;

: map-regs  ( -- )
   chip  if  exit  then
   0 0 h# 0200.0010 my-space +  /regs " map-in" $call-parent
   to chip
   6 4 my-w!
;
: unmap-regs  ( -- )
   chip  0=  if  exit  then
   0 4 my-w!
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

: present-state@  ( -- l )  h# 24 cl@  ;

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
0 instance value mmc?

\ 1 is reset_all, 2 is reset CMD line, 4 is reset DAT line
: sw-reset  ( mask -- )
   h# 2f  2dup  cb!   begin  2dup  cb@  and 0=  until  2drop
;
: reset-host  ( -- )
   0 to sd-clk
   1 sw-reset  \ RESET_ALL
;

: host-high-speed  ( -- )  h# 28 cb@  4 or  h# 28 cb!  ;
: host-low-speed   ( -- )  h# 28 cb@  4 invert and  h# 28 cb!  ;

: 4-bit  ( -- )  h# 28 cb@  2 or  h# 28 cb!  ;
: 1-bit  ( -- )  h# 28 cb@  2 invert and  h# 28 cb!  ;

\ : led-on   ( -- )  h# 28 cb@  1 or  h# 28 cb!  ;
\ : led-off  ( -- )  h# 28 cb@  1 invert and  h# 28 cb!  ;

\ There is no need to use the debounced version (the 3.0000 bits).
\ We poll for the card when the SDMMC driver opens, rather than
\ sitting around waiting for insertion/removal events.
\ The debouncer takes about 300 ms to stabilize.

: card-inserted?  ( -- flag )
   present-state@ h# 40000 and  h# 40000 =
;

: card-power-on  ( -- )
   \ Card power on does not work if a removal interrupt is pending
   h# c0  isr!              \ Clear any pending insert/remove events

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

: card-clock-slow  ( -- )  \ Less than 400 kHz, for init
   card-clock-off
   h# 8003 h# 2c cw!   \ Set divisor to 2^128, leaving internal clock on
   card-clock-on
;

: card-clock-25  ( -- )
   card-clock-off
   h# 103 h# 2c cw!   \ Set divisor to 2^1, leaving internal clock on
   card-clock-on
;
: card-clock-50  ( -- )
   card-clock-off
   h# 003     \ division = 2^0, clocks on

   \ OLPC-specific hack: fast clock doesn't work on the FPGA CaFe chip
   " board-revision" evaluate h# b20 <  if  drop h# 103  then

   h# 2c cw!   \ Set divisor to 2^0, leaving internal clock on
   card-clock-on
;

: data-timeout!  ( n -- )  h# 2e cb!  ;

: setup-host  ( -- )
   reset-host
   internal-clock-on

   h#   00 h# 28 cb!  \ Not high speed, 1-bit data width, LED off
   h# 000b h# 34 cw!  \ normal interrupt status en reg
            \ Enable: DMA Interrupt, Transfer Complete, CMD Complete
            \ Disable: Card Interrupt, Remove, Insert, Read Ready,
            \ Write Ready, Block Gap
   h# f1ff h# 36 cw!  \ error interrupt status en reg
   h# 0000 h# 38 cw!  \ Normal interrupt status interrupt enable reg
   h# 0000 h# 3a cw!  \ error interrupt status interrupt enable reg

   clear-interrupts
;

0 instance value dma-vadr
0 instance value dma-padr
0 instance value dma-len

: (dma-setup)  ( adr #bytes block-size -- )
   h# 7000 or  4 cw!                 ( adr #bytes )  \ Block size register
   dup to dma-len                    ( adr #bytes )  \ Remember for later
   over to dma-vadr                  ( adr #bytes )  \ Remember for later
   true  " dma-map-in" $call-parent  ( padr )        \ Prepare DMA buffer
   dup to dma-padr                   ( padr )        \ Remember for later
   0 cl!                                             \ Set address
;

: dma-setup  ( #blocks adr -- )
   over 6 cw!            ( #blocks adr ) \ Set block count
   swap /block *  /block ( adr #bytes block-size )  \ Convert to byte count
   (dma-setup)
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

0 instance value allow-timeout?
0 instance value timeout?

: .sderror  ( isr -- )
   esr@ dup esr!           ( isr esr )
   allow-timeout?  if      ( isr esr )
      dup 1 =  if  true to timeout?  2drop exit  then
   then                    ( isr esr )

   ." SDHCI: Error: ISR = " swap u.
   ." ESR = " dup u.  decode-esr
   ." Stopping" cr abort
   \      debug-me
;

: wait  ( mask -- )
   h# 8000 or                                     ( mask' )
   begin                                          ( mask )
      isr@  dup isr!                              ( mask isr )
   2dup and  0= while                             ( mask isr )
\     key?  if  key drop  debug-me  then          ( mask isr )
      \ DMA interrupt - the transfer crossed an address boundary
      8 and  if  0 cl@ 0 cl!  then                ( mask )
   repeat                                         ( mask isr )
   nip                                            ( isr )
   dup h# 8000 and  if   .sderror  else  drop  then   ( )
;

: wait-ready  ( -- )
   get-msecs d# 1000 +                    ( limit )
   begin    present-state@  1 and  while  ( limit )
      dup get-msecs - 0<  if
         ." SDHCI: command ready timeout" cr
         abort
      then
   repeat                                 ( limit )
   drop                                   ( )
;

: cmd  ( arg cmd mode -- )
   debug?  if  ." CMD: " over 4 u.r space   then
   wait-ready
   h# c cw!              ( arg cmd )  \ Mode
   swap 8 cl!            ( cmd )      \ Arg
   h# e cw!              ( )          \ cmd
   1 wait                ( )
;

\ The data transfer done indication (2 wait) just tells us that the
\ data has been transferred to the card; the card might still be
\ busy actually writing it to the media.
: wait-dat0  ( -- )  begin  present-state@ h# 10.0000 and  until  ;

\ start    cmd    arg  crc  stop
\ 47:46  45:40   39:8  7:1     0
\     2      6     32    7     1
\ Overhead is 16 bits

\ Response types:
\ R1: mirrored command and status
\ R3: OCR register
\ R6: RCA
\ R2: 136 bits (CID (cmd 2 or 9) or CSD (cmd 10))
\ R7: 136 bits (Interface condition, for CMD8)
\ In R2 format, the first 2 bits are start bits, the next 6 are
\ reserved.  Then there are 128 bits (16 bytes) of data, then the end bit

: response  ( -- l )   h# 10 cl@  ;

: buf+!  ( buf value -- buf' )  over l!  la1+  ;

\ Store in the buffer in little-endian form
: get-response136  ( buf -- )  \ 128 bits (16 bytes) of data.
\   h# 20  h# 10  do  i cl@ buf+!  4 +loop  drop
    >r
    h# 1c cl@  8 lshift  h# 1b cb@ or  r@ 0 la+ l!
    h# 18 cl@  8 lshift  h# 17 cb@ or  r@ 1 la+ l!
    h# 14 cl@  8 lshift  h# 13 cb@ or  r@ 2 la+ l!
    h# 10 cl@  8 lshift                r> 3 la+ l!
;

d# 64 instance buffer: scratch-buf

0 instance value rca
d# 16 instance buffer: cid

external
d# 16 instance buffer: csd
headers

: reset-card  ( -- )  0 0 0 cmd  0 to rca  1 ms  ;  \ 0 -

: send-op-cond  ( voltage-range -- ocr )  h# 0102 0 cmd  response  ; \ R3

\ Get card ID; Result is in cid buffer
: get-all-cids  ( -- )  0 h# 0209 0 cmd  cid get-response136  ;  \ 2 R2

\ Get relative card address
: get-rca  ( -- )  0 h# 031a 0 cmd  response  h# ffff0000 and  to rca  ; \ 3 R6 - SD
: set-rca  ( rca -- )  to rca  rca h# 031a 0 cmd  ; \ 3 R1 - MMC

: set-dsr  ( -- )  0 h# 0400 0 cmd  ;  \ 4 - UNTESTED

\ cmd6 (R1) is switch-function.  It can be used to enter high-speed mode
: switch-function  ( arg -- adr )
   scratch-buf  d# 64  d# 64  (dma-setup)
   h# 063b h# 11 cmd  ( response drop )
   2 wait
   dma-release
   scratch-buf
;

: deselect-card  ( -- )   0   h# 0700 0 cmd  ;  \ 7 - with null RCA
: select-card    ( -- )   rca h# 071b 0 cmd  ;  \ 7 R1b

: send-if-cond  ( -- )  h# 1aa h# 081a 0 cmd  ( response h# 1aa <>  if  ." Error"  then )   ;  \ 8 R7 (SD)

\ : send-ext-csd  ( adr -- )  0 h# 0812 0 cmd  ;  \ 8 R1 (MMC) Untested - requires data transfer

\ Get Card-specific data
: get-csd    ( -- )  rca  h# 0909 0 cmd  csd get-response136  ;  \ 9 R2
: get-cid    ( -- )  rca  h# 0a09 0 cmd  cid get-response136  ;  \ 10 R2 UNTESTED

: stop-transmission  ( -- )  rca  h# 0c1b 0 cmd  ;        \ 12 R1b UNTESTED

: get-status ( -- status )  rca  h# 0d1a 0 cmd  response  ;  \ 13 R1 UNTESTED

: go-inactive  ( -- )  rca  h# 0f00 0 cmd  ;         \ 15 - UNTESTED

: set-blocklen  ( blksize -- )  h# 101a 0 cmd  ;     \ 16 R1 SET_BLOCKLEN

\ Data transfer mode bits for register 0c (only relevant for reads, writes,
\ and switch-function)
\  1.0000  use DMA
\  2.0000  block count register is valid
\  4.0000  auto cmd12 to stop multiple block transfers
\  8.0000  reserved
\ 10.0000  direction: 1 for read, 0 for write
\ 20.0000  multi (set for multiple-block transfers)

: read-single     ( address -- )  h# 113a h# 13 cmd  ;  \ 17 R1 READ_SINGLE_BLOCK
: read-multiple   ( address -- )  h# 123a h# 37 cmd  ;  \ 18 R1 READ_MULTIPLE
: write-single    ( address -- )  h# 183a h# 03 cmd  ;  \ 24 R1 WRITE_SINGLE_BLOCK
: write-multiple  ( address -- )  h# 193a h# 27 cmd  ;  \ 25 R1 WRITE_MULTIPLE

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
: app-get-status  ( -- status )  app-prefix  0 h# 0d1a h# 12 cmd  response  ;  \ a13 R1 UNTESTED

: get-#write-blocks  ( -- n )  app-prefix  0 h# 161a 0 cmd  response  ;  \ a22 R1 UNTESTED

\ You might want to turn this off for data transfer, as it controls
\ a resistor on one of the data lines
: set-card-detect  ( on/off -- )  app-prefix  h# 2a1a 0 cmd  ;  \ a42 R1 UNTESTED
: get-scr  ( -- adr )
   scratch-buf  d# 8  d# 8  (dma-setup)
   app-prefix  0 h# 333a h# 11 cmd  ( response drop )  \ a51 R1
   2 wait
   dma-release
   scratch-buf
;

9 instance value address-shift
h# 8010.0000 value oc-mode  \ Voltage settings, etc.

: wait-powered  ( -- error? )
   false to mmc?

   9 to address-shift

   d# 100 0  do

      false to timeout?
      mmc?  if
         oc-mode send-op-cond   \ cmd2              ( ocr )
         timeout?  if  drop true  unloop exit  then ( ocr )
      else
         oc-mode set-oc         \ acmd41            ( ocr )
         timeout?  if  drop  true to mmc?  0  then  ( ocr )
      then                                       ( ocr )

      dup h# 8000.0000 and  if ( card-powered-on? )

         \ Card Capacity Status bit - High Capacity cards are addressed
         \ in blocks, so the block number does not have to be shifted.
         \ Standard capacity cards are addressed in bytes, so the block
         \ number must be left-shift by 9 (multiplied by 512).
         h# 4000.0000 and  if  0 to address-shift  then

         unloop false exit
      then
      drop d# 10 ms
   loop                      ( )

   ." SDHCI: Card didn't power up after 1 second" cr
   abort
;

: set-operating-conditions  ( -- error? )
   false to mmc?
   true to allow-timeout?

   \ SD version 2 adds CMD3.  Pre-v2 cards will time out.
   false to timeout?  send-if-cond      (  )
   timeout?   if  h# 0030.0000  else  h# 4030.0000  then  to oc-mode

   wait-powered  if  true exit  then

   false to allow-timeout?
   false
;

: set-timeout  ( -- )
   \ There is a CaFe bug in which the timeout code is off by one,
   \ which makes the timeout be half the requested length.
   \ But experience dictates that the timeout should be maxed out,
   \ so we use h# e, the max value that the hardware supports.
   h# e data-timeout!   \ 2^26 / 48 MHz = 1.4 sec
;

: configure-transfer  ( -- )
   mmc?  if
      1-bit
      \ We don't support 4-bit mode for MMC yet

      \ We don't support switching to high speed on MMC yet.
      \ Doing so requires reading the EXT_CSD block
   else
      2 set-bus-width  \ acmd6 - bus width 4
      4-bit
      /block set-blocklen  \ Cmd 16

      \ High speed didn't exist until SD spec version 1.10
      \ The low nibble of the first byte of SCR data is 0 for v1.0 and v1.01,
      \ 1 for v1.10, and 2 for v2.
      get-scr c@  h# f and  0=  if  exit  then

      \ Ask if high-speed is supported
      h# 00ff.fff1 switch-function d# 13 + c@  2  and  if
         h# 80ff.fff1 switch-function drop   \ Perform the switch
         \ Bump the host controller clock
         host-high-speed  \ Changes the clock edge
         card-clock-50
      else
         card-clock-25
      then
   then
;

\ Extract bit fields from CSD or CID  (adr is either csd or cid)
: @bits   ( bit# #bits adr -- bits )
   rot 8 -                     ( #bits adr bit# )  \ -8 accounts for elided CRC
   d# 32 /mod                  ( #bits adr off long#  )
   /l* rot + >r                ( #bits off  r: ladr )
   2dup + d# 32 >  if          ( #bits off  r: ladr )
      \ Get two longs and splice
      r@ l@ over rshift        ( #bits off l.low  r: ladr )
      r> la1+ l@               ( #bits off l.low l.high )
      rot  d# 32 swap -        ( #bits l.low l.high #shift )
      lshift or                ( #bits l )
   else                        ( #bits off  r: ladr )
      \ The field is contained in one longword
      r> l@  swap rshift       ( #bits l )
   then                        ( #bits l )
   swap dup d# 32 = if         ( l #bits )
      drop                     ( bits )
   else                        ( l #bits )
      1 swap lshift 1-  and    ( bits )
   then                        ( bits )
;

0 instance value writing?

\ This is the correct way to wait for programming complete.
: wait-write-done  ( -- )
   writing? 0=  if  exit  then                     ( limit )

   get-msecs d# 1000 +                              ( limit )
   begin  get-status 9 rshift h# f and  7 =  while  ( limit )
      dup get-msecs - 0<  if
         ." SDHCI: wait-write-done timeout" cr
         abort
      then
   repeat                                           ( limit )
   drop                                             ( )

   false to writing?
;

external

: attach-card  ( -- okay? )
   card-power-off d# 20 ms

   card-power-on  d# 20 ms  \ This delay is just a guess

   card-inserted?  0=  if  card-power-off  false exit  then   

   card-clock-slow  d# 10 ms  \ This delay is just a guess

   reset-card     \ Cmd 0

   set-operating-conditions  if  false exit  then

   get-all-cids   \ Cmd 2
   mmc?  if
      h# 10000 set-rca   \ Cmd 3 (MMC) - Get relative card address
   else
      get-rca        \ Cmd 3 (SD) - Get relative card address
   then

   card-clock-25

   get-csd           \ Cmd 9 - Get card-specific data

   select-card       \ Cmd 7 - Select

   configure-transfer

   set-timeout

   true
;

: dma-alloc   ( size -- vadr )  " dma-alloc"  $call-parent  ;
: dma-free    ( vadr size -- )  " dma-free"   $call-parent  ;

: r/w-blocks  ( addr block# #blocks in? -- actual )
   >r               ( addr block# #blocks r: in? )
   rot dma-setup    ( block# r: in? )
   wait-write-done
   address-shift lshift  r>  if
      read-multiple
   else
      write-multiple  true to writing?
   then
   2 wait
   dma-release
   dma-len /block /
;

0 value open-count
: open  ( -- )
   open-count 0=  if
      map-regs
      setup-host
   then
   open-count 1+ to open-count
   true
;

: close  ( -- )
   open-count  1 =  if
      wait-write-done
      card-clock-off
      card-power-off
      unmap-regs
   then
   open-count 1- 0 max  to open-count
;

: init   ( -- )
   map-regs
   \ One-time initialization of Marvell CaFe SD interface.
   \ Marvell told us to do this, but didn't say why.
   h# 0004 h# 6a cw!
   h# 7fff h# 60 cw!
   unmap-regs
;

external

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
