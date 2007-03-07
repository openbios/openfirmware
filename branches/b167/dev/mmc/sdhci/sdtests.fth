
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
         op:  h# 800 #  h# 4 [bx]  test  \ Test Present State Buffer Read bit
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
   2 wait
;

: x-pio-get  ( dst chip len -- )
   nip  bounds  ?do
      begin  h# 24 cl@ h# 800 and 0= while  key?  if  i ibuf - . key drop debug-me  then  repeat
      h# 20 cl@ i l!
      h# 20 cl@ i la1+ l!
   8 +loop
;
: chunk-pio-get  ( dst chip len -- )
   begin  h# 24 cl@ h# 800 and 0= while  key?  if  i ibuf - . key drop debug-me  then  repeat
   nip  bounds  ?do   h# 20 cl@ i l!  /l +loop
;

: pio-read-block  ( block# -- )
   1 6 cw!                   \ Block count
   /block *  h# 52.113a cmd  \ Addr READ_SINGLE_BLOCK (no DMA)
\   h# 20 wait
\   ibuf chip /block  pio-get
   ibuf chip /block  x-pio-get
\   wait-transfer
;

: write-block  ( block# -- )
   1 obuf dma-setup   ( block# )
   /block *  write-single  \ Addr xfer-mode WRITE_SINGLE_BLOCK
   2 wait
   dma-release
;

: read-block  ( block# -- )
   1 ibuf dma-setup
   /block *  read-single   \ addr xfer_mode READ_SINGLE_BLOCK
   2 wait
   dma-release
;

: test  ( -- )
   setup-host

   attach-card drop

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

: init-tests
   allocate-test-buffers
   obuf h# 200 h# 00 fill
   ibuf h# 200 h# ff fill
;

: loud  true to verbose?  ;
: quiet  false to verbose?  ;

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

