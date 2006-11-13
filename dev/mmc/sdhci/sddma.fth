\ See license at end of file
\ Driver for SD HCI interface (Marvell version)
\ .( Compiling) cr
\ Notes:
\ Got bad CRC (ESR = 4000) after pio-write-block

\ TODO:
\ Check error bits after wait-transfer
\ Test timeouts
\ Test suspend/resume
\ Check card busy and cmd inhibit bits before sending commands
\ Test multiple-block transfers and auto-cmd12
\ Test stop-at-block-gap
\ Test stop-clock-after-transfer (bit in command register)
\ Test full speed mode
\ Test 1-bit data mode
\ Fix the mode. values; the transfer mode bits are Marvell-specific

begin-select /pci/pci11ab,4100

" sd" device-name

0 value verbose?

\ Configure for differences between Marvell HCI and Simplified SD HCI spec
true value marvell?

0 value chip

h# 200 constant /block  \ 512 bytes

: map-regs  ( -- )
   chip  if  exit  then
   0 0 0200.0010 my-space +  h# 4000  " map-in" $call-parent
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

: enable-sd-int  ( -- )
   marvell?  if  h# 300c cl@  h# 8000.0002 or  h# 300c cl!  then
;
: disable-sd-int  ( -- )
   marvell?  if  h# 300c cl@  2 invert and  h# 300c cl!  then
;
: enable-sd-clk  ( -- )
   marvell?  if  h# 3004 cw@  h# 2000 or  h# 3004 cw!  then
;
: disable-sd-clk  ( -- )
   marvell?  if  h# 3004 cw@  h# 2000 invert and  h# 3004 cw!  then
;

: clear-interrupts  ( -- )
   isr@ drop  esr@ drop
   h# ffff isr!  \ Clear all normal interrupts
   h# ffff esr!  \ Clear all error interrupts
;

\ In SSDHCIS, register 2e is the timing control register
: reset-host  ( -- )  marvell?  if  h# 0100  h# 2e cw!  then  ;

: init-dma  ( -- )
   marvell?  if
      \ 7000 enables clocks to all three functions
      \ 4 sets master reset
      \ 8 clrs master reset
      \ 2 clrs sw reset
      h# 7006  h# 3004  cl!  \ Set master reset
      h# 700a  h# 3004  cl!  \ Clear master reset
   then
   enable-sd-int
   /block 4 cw!
;

: setup-host  ( -- )
   reset-host
   init-dma

   marvell?  if
      h# 7801 h# 28 cw!  \ host_ctl (push-pull driver, etc)
      h# fffb h# 34 cw!  \ normal interrupt status en reg
                      \ block gap event not enabled
      h# ffff h# 36 cw!  \ error interrupt status en reg

      h# ffff h# 38 cw!  \ Normal interrupt status interrupt enable register

      h# 0000 h# 42 cw!  \ auto12 arg low
      h# 0000 h# 44 cw!  \ auto12 arg high
      h# 0c00 h# 46 cw!  \ auto12 index
   then

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
   marvell?  if
      dup h# 8000 and  if   ." Reserved, "  then
      dup h# 4000 and  if   ." Write CRC, "  then
      dup h# 2000 and  if   ." Write CRC start bit, "  then
      dup h# 1000 and  if   ." Write CRC end bit, "  then
      dup h#  800 and  if   ." Response T bit, "  then
      dup h#  400 and  if   ." Transfer size mismatched, "  then
      dup h#  200 and  if   ." Command start bit, "  then
      dup h#  100 and  if   ." Auto CMD12, "  then
      dup h#   80 and  if   ." Command completion timeout, "  then
      dup h#   40 and  if   ." Read Data End Bit, "  then
      dup h#   20 and  if   ." Read Data CRC, "  then
   else
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
   then
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
      decode-esr
      true abort" Stopping"
\      debug-me
   then
   drop
;

: wait-done  ( -- isr )
   begin  isr@  dup  h# 8002 and  0=  while  ( isr )
      key?  if  key drop  debug-me  then  ( isr )
      drop                                ( )
   repeat                                 ( isr )
   verbose?  if  ." ISR: " dup 4 u.r  cr  then
   dup isr!                               ( isr )
;

: wait-no-response  ( -- )
   begin  isr@  dup 1 and  dup  0=  while     ( masked-isr )
      key?  if  key drop  debug-me  then  ( masked-isr )
      drop                                ( )
   repeat                                 ( masked-isr )
   verbose?  if  dup ." ISR: " 4 u.r space  cr  then
   isr!                                   ( )
;

: cmd  ( arg mode.cmd -- isr )
   \ XXX check the card busy and cmd inhibit bits in reg 24
   \ XXX set timeouts
   verbose?  if  ." CMD: " dup 4 u.r space   then
   swap 8 cl!            ( mode.cmd )  \ Arg
   lwsplit  h# c cw!     ( cmd )       \ Mode
   marvell?  if  4 or  then   \ Enable data CRC check
   dup h# e cw!          ( cmd )       \ cmd

   wait-done             ( cmd isr )
   swap 3 and  if  check-error  else  drop  then
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

\ XXX this response decoding is Marvell-specific.  The bit order and
\ alignment differs from the Simplified SD HCI spec.

\ No need to mask, because cw@ is guaranteed to deliver exactly 16 bits
: response  ( -- l )
   marvell?  if
      h# 10 cw@  d# 22 lshift     ( rsp-bits39:30 )
      h# 12 cw@      6 lshift or  ( rsp-bits39:14 )
      h# 14 cw@  d# 10 rshift or  ( rsp-bits39:8 )
   else
      h# 10 cl@
   then
;

\ This is fairly tricky.  The problem is that we get data from the
\ chip in 16-bit chunks, but its not aligned in any sane way on
\ byte boundaries.  The top 6 bits of the register at 0x10 are junk (all ones)
\ as are the bottom 2 bits of the register at 0x1e.
\ The approach we use is to merge 16 new bits of data above the 16 bits
\ we got in the previous iteration, shift it to align to byte boundaries,
\ then extract two bytes.
: rsp-extract  ( residue adr reg# -- residue' adr' )
   swap >r                      ( residue reg# r: adr )
   cw@  tuck  wljoin            ( residue' value r: adr )
   d# 10 rshift                 ( residue  aligned r: adr )
   wbsplit  r@ 1+ c!  r@ c!     ( residue  r: adr )
   r> 2+                        ( adr' residue' )
;

: buf+!  ( buf value -- buf' )  over le-l!  la1+  ;

\ Store in the buffer in little-endian form
: get-response136  ( buf -- )  \ 128 bits (16 bytes) of data.
   marvell?  if
      0  swap              ( residue buf )
      h# 10  h# 1e  do     ( residue buf )
         i rsp-extract     ( residue' buf' )
      -2 +loop             ( residue buf )

      nip  0 swap c!       ( )
   else
      h# 20  h# 10  do  i cw@ buf+!  4 +loop  drop
   then
;

0 instance value rca
d# 16 instance buffer: cid
d# 16 instance buffer: csd

: reset-card  ( -- )  0 0 cmd  0 to rca  ;  \ 0 -

\ Get card ID; Result is in cid buffer
: get-all-cids  ( -- )  0 h# 0209 cmd  cid get-response136  ;  \ 2 R2

\ Get relative card address
: get-rca  ( -- )  0 h# 031a cmd  response  h# ffff0000 and  to rca  ; \ 3 R6

: set-dsr  ( -- )  0 h# 0400 cmd  ;  \ 4 - UNTESTED

\ cmd6 (R1) is switch-function.  It can be used to enter high-speed mode

: deselect-card  ( -- )   0   h# 0700 cmd  ;  \ 7 - with null RCA
: select-card    ( -- )   rca h# 071b cmd  ;  \ 7 R1b

\ Get Card-specific data
: get-csd    ( -- )  rca  h# 0909 cmd  csd get-response136  ;  \ 9 R2
: get-cid    ( -- )  rca  h# 0a09 cmd  cid get-response136  ;  \ 10 R2 UNTESTED

: stop-transmission  ( -- )  h# 0c1b cmd  ;        \ 12 R1b UNTESTED

: get-status ( -- status )  rca  h# 0d1a cmd  response  ;  \ 13 R1 UNTESTED

: go-inactive  ( -- )  rca  h# 0f00 cmd  ;         \ 15 - UNTESTED

: set-blocklen  ( blksize -- )  h# 101a cmd  ;     \ 16 R1 SET_BLOCKLEN

\ Data transfer mode bits for register 0c (only relevant for reads and writes)
\  1.0000  use PIO instead of DMA
\  2.0000  count blocks transferred
\  4.0000  auto cmd12 to stop multiple block transfers
\  8.0000  reserved
\ 10.0000  direction: 1 for read, 0 for write
\ 20.0000  multi (set for multiple-block transfers)

: read-single     ( byte# -- )  h# 12.113a cmd  ;  \ 17 R1 READ_SINGLE_BLOCK
: read-multiple   ( byte# -- )  h# 36.123a cmd  ;  \ 18 R1 READ_MULTIPLE UNTESTED
: write-single    ( byte# -- )  h# 02.183a cmd  ;  \ 24 R1 WRITE_SINGLE_BLOCK
: write-multiple  ( byte# -- )  h# 26.193a cmd  ;  \ 25 R1 WRITE_MULTIPLE UNTESTED

: program-csd  ( -- )     0  h# 1b1a cmd  ;  \ R1 27 UNTESTED
: protect     ( group# -- )  h# 1c1b cmd  ;  \ R1b 28 UNTESTED
: unprotect   ( group# -- )  h# 1d1b cmd  ;  \ R1b 29 UNTESTED
: protected?  ( group# -- 32-bits )  h# 1e1a cmd  response  ;  \ 30 R1 UNTESTED

: erase-blocks  ( block# #blocks -- ) \ UNTESTED
   dup  0=  if  2drop exit  then
   1- bounds        ( last first )
   h# 201a cmd      ( last )   \ cmd32 - R1
   h# 211a cmd      ( )        \ cmd33 - R1
   h# 261b cmd                 \ cmd38 - R1b (wait for busy)
;

\ cmd40 is MMC

\ See table 4-5 in sandisk spec
\ : lock/unlock  ( -- ) 0 h# 2a1a cmd  ;  \ 42 R1 LOCK_UNLOCK not sure how it works

: app-prefix  ( -- )  rca  h# 371a  cmd  ;  \ 55 R1 app-specific command prefix

: set-bus-width  ( mode -- )  app-prefix  h# 61a cmd  ;  \ a6 R1 Set mode

: set-oc ( ocr -- ocr' )  app-prefix  h# 2902 cmd  response  ;  \ a41 R3

\ This sends back 512 bits in a single data block.
: app-get-status  ( -- status )  app-prefix  0 h# 12.0d1a cmd  response  ;  \ a13 R1 UNTESTED

: get-#write-blocks  ( -- n )  app-prefix  0 h# 161a cmd  response  ;  \ a22 R1 UNTESTED
\ You might want to turn this off for data transfer, as it controls
\ a resistor on one of the data lines
: set-card-detect  ( on/off -- )  app-prefix  h# 2a1a cmd  ;  \ a42 R1 UNTESTED
: get-scr  ( -- src )  app-prefix  0 h# 331a cmd  response  ;  \ a51 R1 UNTESTED

: wait-transfer  ( -- )
   begin  isr@  dup 2 and  0=  while  \ Test Transfer Complete bit
      drop
      key?  if  key drop  debug-me  then
      d# 1 ms
   repeat                  ( isr-val )
   dup isr!                    \ Clear interrupt
   check-error
;

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

   h# 7a01  h# 28 cw!   \ host_ctl,push pull, 4bit
   /block set-blocklen  \ Cmd 16
;

: attach-card  ( -- )
   reset-card     \ Cmd 0

   set-operating-conditions  

   get-all-cids   \ Cmd 2
   get-rca        \ Cmd 3 - Get relative card address
   get-csd        \ Cmd 9 - Get card-specific data
   select-card    \ Cmd 7 - Select

   configure-transfer
;

external

\ Any reasonable PCI bus should be able to transfer much more than this
: max-transfer  ( -- n )   h# 10000   ;

: read-blocks   ( addr block# #blocks -- #read )
   rot dma-setup    ( block# )
   /block * read-multiple
\   wait-transfer
   dma-release
   dma-len /block /
;
: write-blocks  ( addr block# #blocks -- #written )
   rot dma-setup    ( block# )
   /block * write-multiple
\   wait-transfer
   dma-release
   dma-len /block /
;

0 instance value ibuf  \ For testing
0 instance value obuf  \ For testing
: allocate-test-buffers  ( -- )
   ibuf  if  exit  then
   /block " dma-alloc" $call-parent  to ibuf
   /block " dma-alloc" $call-parent  to obuf
;

: check-results  ( -- )
   \ .. or compare
   ibuf obuf /block comp  if
      ." MISMATCH!!!" cr
      ibuf /block dump
      obuf /block dump
   else
      ." good" cr
   then
;

code pio-put1  ( buf chip #bytes -- )
   dx  pop            \ Byte count in dx
   bx  pop            \ chip in BX
   0 [sp]  si  xchg   \ SI on stack, buf in SI

   begin
      d# 16 #  cx   mov
      begin
         op:  h# 800 #  h# 30 [bx]  test  \ Test ISR 8-empty bit
      0<> until
      begin
         op: ax  lods
         op: ax  h# 20 [bx]  mov
      loopa
   d# 32 #  dx  sub
   0= until

   si pop    \ Restore SI
c;

code pio-put  ( buf chip #bytes -- )
   cx  pop            \ Byte count in CX
   bx  pop            \ chip in BX
   si  dx  mov        \ Save SI
   si  pop            \ buf in SI
   h# 20 #  bx  add   \ Point to data register for extra speed

   begin
      begin
         op:  h# 800 #  h# 10 [bx]  test  \ Test ISR 8-empty bit
      0<> until
      \ Unrolled loop
      op: ax  lods   op: ax  0 [bx]  mov
      op: ax  lods   op: ax  0 [bx]  mov
      op: ax  lods   op: ax  0 [bx]  mov
      op: ax  lods   op: ax  0 [bx]  mov
      op: ax  lods   op: ax  0 [bx]  mov
      op: ax  lods   op: ax  0 [bx]  mov
      op: ax  lods   op: ax  0 [bx]  mov
      op: ax  lods   op: ax  0 [bx]  mov
      op: ax  lods   op: ax  0 [bx]  mov
      op: ax  lods   op: ax  0 [bx]  mov
      op: ax  lods   op: ax  0 [bx]  mov
      op: ax  lods   op: ax  0 [bx]  mov
      op: ax  lods   op: ax  0 [bx]  mov
      op: ax  lods   op: ax  0 [bx]  mov
      op: ax  lods   op: ax  0 [bx]  mov
      op: ax  lods   op: ax  0 [bx]  mov
   d# 32 #  cx  sub
   0= until

   dx  si  mov    \ Restore SI
c;

code pio-get  ( buf chip #bytes -- )
   cx  pop            \ Byte count in CX
   bx  pop            \ chip in BX
   di  dx  mov        \ Save DI
   di  pop            \ buf in DI
   h# 20 #  bx  add   \ Point to data register for extra speed

   begin
      begin
         op:  h# 400 #  h# 10 [bx]  test  \ Test ISR 8-full bit
      0<> until
      \ Unrolled loop
      op: 0 [bx]  ax  mov   op:  ax  stos
      op: 0 [bx]  ax  mov   op:  ax  stos
      op: 0 [bx]  ax  mov   op:  ax  stos
      op: 0 [bx]  ax  mov   op:  ax  stos
      op: 0 [bx]  ax  mov   op:  ax  stos
      op: 0 [bx]  ax  mov   op:  ax  stos
      op: 0 [bx]  ax  mov   op:  ax  stos
      op: 0 [bx]  ax  mov   op:  ax  stos
      op: 0 [bx]  ax  mov   op:  ax  stos
      op: 0 [bx]  ax  mov   op:  ax  stos
      op: 0 [bx]  ax  mov   op:  ax  stos
      op: 0 [bx]  ax  mov   op:  ax  stos
      op: 0 [bx]  ax  mov   op:  ax  stos
      op: 0 [bx]  ax  mov   op:  ax  stos
      op: 0 [bx]  ax  mov   op:  ax  stos
      op: 0 [bx]  ax  mov   op:  ax  stos
   d# 32 #  cx  sub
   0= until

   dx  di  mov    \ Restore DI
c;

: pio-write-block  ( block# -- )
   1 6 cw!                   \ Block count
   /block *  h# 42.183a cmd  \ Addr WRITE_SINGLE_BLOCK (no DMA)
   obuf chip /block pio-put
\   wait-transfer
;

: pio-read-block  ( block# -- )
   1 6 cw!                   \ Block count
   /block *  h# 52.113a cmd  \ Addr READ_SINGLE_BLOCK (no DMA)
   ibuf chip /block  pio-get
\   wait-transfer
;

: write-block  ( block# -- )
   1 obuf dma-setup   ( block# )
   /block *  write-single  \ Addr xfer-mode WRITE_SINGLE_BLOCK

\   wait-transfer
   dma-release
;

: read-block  ( block# -- )
   1 ibuf dma-setup
   /block *  read-single   \ addr xfer_mode READ_SINGLE_BLOCK

\   wait-transfer
   dma-release
;

: test  ( -- )
   setup-host

   attach-card

   ." writing ..."
   obuf /block h# 5a fill  0 write-block
   cr

   deselect-card

   select-card

   ." reading ..."
   ibuf /block h# ff fill   0 read-block
   cr

   ." checking ..."
   check-results
;
: wr  ( val block# -- )
   swap obuf /block rot fill  ( block# )  dup write-block    ( block# )
   obuf /block h# 33 fill     ( block# )  dup write-block    ( block# )
   ibuf /block 0 fill         ( block# )      read-block     ( )
   ibuf 20 dump
;
\ This sequence fails:
\ 40 0 wr    \ Fails - Byte 2 is 73, not 33
\ b0 0 wr    \ Succeeds - all bytes are 33

\ I've tried several values with 0x40 bit set, and they all fail,
\ and the values with the 0x40 bit clear all succeed.

\ Write the pattern "00 00 40 00  00 00 00 00  00 00 00 00  ..."
\ Reads back as     "00 00 40 00  00 00 40 00  00 00 00 00  ..."
\ Doesn't happen if the 40 is in other locations.

\ Actually, it happens with the 40 in byte 6, the echo appears in byte 0xa

\ I wonder if this is just a bad block on the card?
\ No, it seems to happen at different block locations
0 [if]
ok obuf 200 erase  41 obuf e + c!  5 obuf 12 + c!
ok 0 write-block 0 read-block ibuf 40 dump
           0  1  2  3  4  5  6  7   8  9  a  b  c  d  e  f  0123456789abcdef
  1ff000  00 00 00 00 00 00 00 00  00 00 00 00 00 00 41 00  ..............A.
  1ff010  00 00 45 00 00 00 00 00  00 00 00 00 00 00 00 00  ..E.............
  1ff020  00 00 00 00 00 00 00 00  00 00 00 00 00 00 00 00  ................
  1ff030  00 00 00 00 00 00 00 00  00 00 00 00 00 00 00 00  ................
\ So it appears that it's just the 40 bit that gets "echoed"
\ Could it be that bit 22 on some 32-bit bus is not being driven properly?
\ Perhaps there is a timing problem inside the FPGA?  Maybe bit 22 is on
\ a slow net or something.
\ Oh, it also happens on bit 3, i.e. write 08 to byte offset 0, so bits
\ 3 and 22 have the problem.
\ For example:
\ obuf 200 erase  ffffffff obuf 4 + !
\ 0 write-block  0 read-block   ibuf 10 dump
\
\ Interesting - the byte-2 40 bit happens across write boundaries, to wit:
obuf 200 erase  ffffffff obuf 1fc + !   0 write-block
obuf 200 erase  0 write-block
0 read-block  ibuf 20 dump
           0  1  2  3  4  5  6  7   8  9  a  b  c  d  e  f  0123456789abcdef
  1ff000  00 00 40 00 00 00 00 00  00 00 00 00 00 00 00 00  ..@.............
  1ff010  00 00 00 00 00 00 00 00  00 00 00 00 00 00 00 00  ................
ok
  - The byte-0 08 bit is no longer failing (I turned the Geode board off
for several hours then rebooted it).
[then]

: pattern  ( -- )
   obuf /block erase
   -1 obuf !
   h# 12345678 obuf h# 10 + !
   h# 55555555 obuf h# 20 + !
   h# aaaaaaaa obuf h# 30 + !
;
: r  0 read-block  ibuf 80 ldump  ;
: w  0 write-block  ;
: p  0 pio-write-block  ;

: open  ( -- )
   map-regs
   allocate-test-buffers
   obuf h# 200 h# 00 fill
   ibuf h# 200 h# ff fill
   setup-host
   attach-card
   ." Card enumerated and selected" cr
   true
;
: loud  true to verbose?  ;
: quiet  false to verbose?  ;
loud
open
quiet


: help  ( -- )
   ." SD diagnostics examples:"  cr
   ." test              - Run read/write test" cr
   ." obuf 40 dump      - Dump first 0x40 bytes of the write buffer" cr
   ." ibuf 40 dump      - Dump first 0x40 bytes of the read buffer" cr
   ." pattern           - Init write buffer with a pattern" cr
   ." 1 write-block     - DMA write block 1 (the one at offset 0x200)" cr
   ." 3 read-block      - DMA read block 3 (the one at offset 0x600)" cr
   ." 1 pio-write-block - non-DMA write block 1" cr
   ." 3 pio-read-block  - non-DMA read block 1" cr
   ." loud              - Turn on verbose messages" cr
   ." quiet             - Turn off verbose messages" cr
   cr
   ." Open Firmware quick reference at http://firmworks.com/QuickRef.html" cr
;
.( Type "help" for some examples) cr
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
