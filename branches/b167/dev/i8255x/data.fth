\ See license at end of file
purpose: Register access methods for i82559

hex
headers

\ Data structure fields are in little-endian.
\ Define some little-endian read and write operators.
: le-w@   ( a -- w )   dup c@ swap ca1+ c@ bwjoin  ;
: le-w!   ( w a -- )   >r  wbsplit r@ ca1+ c! r> c!  ;
: le-l@   ( a -- l )   >r  r@ c@  r@ 1+ c@  r@ 2+ c@  r> 3 + c@  bljoin  ;
: le-l!   ( l a -- )   >r lbsplit  r@ 3 + c!  r@ 2+ c!  r@ 1+ c!  r> c!  ;

\ ***************************************************************************
\ 			CSR (Command Status Registers)
\ ***************************************************************************
: csr-l@  ( register -- l )  csr-base + rl@  ;
: csr-l!  ( l register -- )  csr-base + rl!  ;
: csr-w@  ( register -- w )  csr-base + rw@  ;
: csr-w!  ( w register -- )  csr-base + rw!  ;
: csr-b@  ( register -- b )  csr-base + rb@  ;
: csr-b!  ( b register -- )  csr-base + rb!  ;

: cmd@       ( -- b )   2 csr-b@  ;  \ Read  scb command byte
: cmd!       ( b -- )   2 csr-b!  ;  \ Write scb command byte
: cmd-wait   ( -- )     begin  cmd@ 0=  until  ;
: cmdw!      ( b -- )	cmd-wait cmd!  ;
: int!       ( b -- )   3 csr-b!  ;  \ Set interrupt masks
: stat@      ( -- b )   0 csr-b@  ;  \ Read  CU/RU status
: int@       ( -- b )   1 csr-b@  ;  \ Read  scb STAT/ACK byte
: ack!       ( b -- )   1 csr-b!  ;  \ Acknowledge pending interrupts
: gp@        ( -- l )   4 csr-l@  ;  \ Read  scb general pointer
: gp!        ( l -- )   4 csr-l!  ;  \ Write scb general pointer
: cmd-gp!    ( b l -- )  cmd-wait gp! cmd!  ;

: port!      ( l -- )   8 csr-l!  ;  \ Write PORT
: (flash@)   ( -- w )   c csr-w@  ;  \ Read  flash control register
: (flash!)   ( w -- )   c csr-w!  ;  \ Write flash control register
: (eeprom@)  ( -- w )   e csr-w@  ;  \ Read  eeprom control register
: (eeprom!)  ( w -- )   e csr-w!  ;  \ Write eeprom control register
: mdi@       ( -- l )  10 csr-l@  ;  \ Read  MDI control register
: mdi!       ( l -- )  10 csr-l!  ;  \ Write MDI control register
: rxdmabc@   ( -- l )  14 csr-l@  ;  \ Read  Rx DMA byte count
: rxdmabc!   ( l -- )  14 csr-l!  ;  \ Write Rx DMA byte count
: rxbc@      ( -- b )  18 csr-b@  ;  \ Read  early RCV interrupt Rx byte count
: rxbc!      ( b -- )  18 csr-b!  ;  \ Write early RCV interrupt Rx byte count
: fc-ctl!    ( b -- )  1a csr-b!  ;  \ Write flow control command register
: fc-th!     ( b -- )  19 csr-b!  ;  \ Write flow control threshold register
: pmdr@      ( -- b )  1b csr-b@  ;  \ Read  power management driver register
: gctl!      ( b -- )  1c csr-b!  ;  \ Write general control register
: gstat@     ( -- b )  1d csr-b@  ;  \ Read  general status register

\ ***************************************************************************
\ 			SCB (System Control Block)
\ ***************************************************************************

\ int@, ack!
01 constant int-fc-pause
02 constant int-early-receive
04 constant int-sw
08 constant int-mdi
10 constant int-ru-not-ready
20 constant int-cu-not-active
40 constant int-ru-receive
80 constant int-cu-done-cmd

\ stat@
c0 constant cus-mask
00 constant cus-idle
40 constant cus-suspended
80 constant cus-lpq
c0 constant cus-hpq

3c constant rus-mask
00 constant rus-idle
04 constant rus-suspended
08 constant rus-no-response
10 constant rus-ready
24 constant rus-suspended-no-rbds
28 constant rus-no-response-no-rbds
30 constant rus-ready-no-rbds

\ cmd!
00 constant cmd-nop
01 constant cmd-ru-start
02 constant cmd-ru-resume
03 constant cmd-ru-ddma			\ RCV DMA redirect
04 constant cmd-ru-abort
05 constant cmd-ru-hds			\ load header data size
06 constant cmd-ru-base
07 constant cmd-ru-rbd-resume
10 constant cmd-cu-start
20 constant cmd-cu-resume
30 constant cmd-cu-hpq-start
40 constant cmd-dmp-base		\ load dump counters address
50 constant cmd-dmp-cnt			\ dump statistical counters
60 constant cmd-cu-base
70 constant cmd-dmp-rst-cnt		\ dump & reset statistical counters
a0 constant cmd-cu-sresume		\ cu static resume
b0 constant cmd-cu-hpq-resume

\ int!
01 constant int-mask-inta
02 constant int-gen-sw
04 constant int-mask-er
08 constant int-mask-rnr
30 constant int-mask-cna
40 constant int-mask-fr
80 constant int-mask-cx

\ ***************************************************************************
\ 			CBL (Command Block List)
\ ***************************************************************************
struct
   2 field >stat
   2 field >cmd
   4 field >next
constant /cb-hdr

0000 constant cb-cmd-nop
0001 constant cb-cmd-ia			\ individual address setup
0002 constant cb-cmd-cfg
0003 constant cb-cmd-mia		\ multicast address setup
0004 constant cb-cmd-tx
0005 constant cb-cmd-ucode		\ download micro-code
0006 constant cb-cmd-dump
0007 constant cb-cmd-diag

8000 constant cb-complete
2000 constant cb-ok

8000 constant cb-eol
4000 constant cb-suspend
2000 constant cb-intr


0 value /cb-buf
0 value cb-buf
0 value cb-phys
0 value cb-unaligned

: cb-wait  ( v p l -- ok? )
   begin  3dup dma-pull 2 pick >stat le-w@ cb-complete and  until
   2drop >stat le-w@ cb-ok and
;
: cb-free  ( -- )
   /cb-buf 0=  if  exit  then
   cb-buf cb-phys /cb-buf dma-map-out
   cb-unaligned /cb-buf /align4 aligned-free
   0 0 0 0 to /cb-buf to cb-buf to cb-phys to cb-unaligned
;
: cb-alloc  ( len -- )
   /cb-buf  if  cb-free  then
   /cb-hdr + dup to /cb-buf  alloc-buf4
   to cb-phys to cb-buf to cb-unaligned
   cb-buf /cb-buf erase
   cmd-cu-base 0 cmd-gp!
;
: cb-go  ( -- ok? )
   cb-buf cb-phys /cb-buf dma-push
   cmd-cu-start cb-phys cmd-gp!
   cb-buf cb-phys /cb-buf cb-wait
   cb-free
;

\ ---------------------------------------------------------------------------
\ 			CB Dump
\ ---------------------------------------------------------------------------

d# 596 value /cb-dump
0 value cb-dump-buf
0 value cb-dump-phys
: alloc-cb-dump  ( -- )
   cb-dump-buf 0=  if
      /cb-dump dma-alloc dup to cb-dump-buf
      /cb-dump false dma-map-in to cb-dump-phys
   then
;
: free-cb-dump  ( -- )
   cb-dump-buf  if
      cb-dump-buf cb-dump-phys /cb-dump dma-map-out
      cb-dump-buf /cb-dump dma-free
      0 0 to cb-dump-buf to cb-dump-phys
   then
;
: cb-dump  ( adr len -- actual )
   /n cb-alloc
   alloc-cb-dump
   cb-dump-phys cb-buf /cb-hdr + le-l!
   cb-cmd-dump cb-eol or cb-buf >cmd le-w!
   cb-go  drop
   cb-dump-buf -rot move  /cb-dump
   free-cb-dump
;

\ ---------------------------------------------------------------------------
\			Configure
\ ---------------------------------------------------------------------------
: cb-cfg!  ( b idx -- )  cb-buf /cb-hdr + + c!  ;
: cb-cfg-stable  ( -- adr len )
   " "(08 04 00 01 00 00 32 02)"
;
: cb-cfg-ltable  ( -- adr len )
\      00 01 02 03 04 05 06 07 08 09 10 11 12 13 14 15 16 17 18 19 20 21
   " "(16 04 00 01 00 00 32 02 01 00 28 00 60 00 f2 00 00 00 73 80 20 00)"
;
: cb-cfg-table!  ( adr len -- )
   0  ?do  dup  i + c@ i cb-cfg!  loop  drop
;
: (cb-cfg-reinit)  ( -- )  cb-cfg-stable cb-cfg-table!  ;
: (cb-cfg-init)    ( -- )  cb-cfg-ltable cb-cfg-table!  ;
: cb-cfg-promiscuous  ( -- )
   d# 22 cb-alloc
   (cb-cfg-init)
   cb-cmd-cfg cb-eol or cb-buf >cmd le-w!
   01 d# 15 cb-cfg!
   cb-go drop
;
: cb-cfg-init  ( -- )
   d# 22 cb-alloc
   (cb-cfg-init)
   cb-cmd-cfg cb-eol or cb-buf >cmd le-w!
   cb-go  drop
;
: cb-cfg-reinit  ( -- )
   d# 8 cb-alloc
   (cb-cfg-reinit)
   cb-cmd-cfg cb-eol or cb-buf >cmd le-w!
   cb-go  drop
;

\ ---------------------------------------------------------------------------
\			TCB (Transmit Command Block)
\ ---------------------------------------------------------------------------
struct
   /cb-hdr +
   4 field >tcb-tbd
   2 field >tcb-#byte
   1 field >tcb-threshold
   1 field >tcb-#tbd
constant /tcb

1000 constant tcb-underrun

0008 constant tcb-flexible
0000 constant tcb-crc
0010 constant tcb-no-crc

8000 constant tcb-eof

80 constant tcb-threshold	\ 1-e0 * 8 bytes

0 value tcb
0 value tcb-phys
0 value tcb-unaligned

struct
   4 field >tbd-buf
   2 field >tbd-len
   2 field >tbd-pad
constant /tbd

0 value tbd
0 value tbd-phys
0 value tbd-unaligned

: alloc-tcb  ( -- )  /tcb alloc-buf4 to tcb-phys to tcb to tcb-unaligned  ;
: alloc-tbd  ( -- )  /tbd alloc-buf4 to tbd-phys to tbd to tbd-unaligned  ;
: free-tcb  ( -- )
   tcb  if
      tcb tcb-phys /tcb dma-map-out
      tcb-unaligned /tcb /align4 aligned-free
      0 0 0 to tcb to tcb-phys to tcb-unaligned
   then
;
: free-tbd  ( -- )
   tbd  if
      tbd tbd-phys /tbd dma-map-out
      tbd-unaligned /tbd /align4 aligned-free
      0 0 0 to tbd to tbd-phys to tbd-unaligned
   then
;

: init-tcb  ( padr -- )
   tcb /tcb erase
   cb-cmd-tx cb-eol or tcb-flexible or tcb-crc or tcb >cmd le-w!
   tcb >tcb-tbd le-l!
   tcb-threshold tcb >tcb-threshold c!
   01 tcb >tcb-#tbd c!
   tcb-eof tcb >tcb-#byte le-w!
   tcb tcb-phys /tcb dma-push
;
: init-tbd  ( padr len -- )
   3fff and tcb-eof or tbd >tbd-len le-w!
   tbd >tbd-buf le-l!
   0 tbd >tbd-pad le-w!
   tbd tbd-phys /tbd dma-push
;
: tx-go  ( padr len -- ok? )
   init-tbd
   tbd-phys init-tcb
   cmd-cu-start tcb-phys cmd-gp!
   tcb tcb-phys /tcb cb-wait
;

[ifdef]  notdef
\ ---------------------------------------------------------------------------
\ 			Statistical Counters (DWORD aligned)
\ ---------------------------------------------------------------------------
0 value dmp-cnt
0 value dmp-cnt-phys
0 value dmp-cnt-unaligned
d# 68 value /dmp-cnt		\ Length depends on byte 6 of config cmd

: wait-stat-cnt  ( w -- )
   \ Last word is the completion status and should equal w when done.
   dmp-cnt /dmp-cnt + 4 -  swap
   begin
      dmp-cnt dmp-cnt-phys /dmp-cnt dma-pull
      over le-l@ over = 
   until  2drop
;
: init-stat-cnt  ( -- )
   dmp-cnt 0=  if
      /dmp-cnt alloc-buf4
      to dmp-cnt-phys to dmp-cnt to dmp-cnt-unaligned
      cmd-dmp-base dmp-cnt-phys cmd-gp!
   then
   dmp-cnt /dmp-cnt erase
   dmp-cnt dmp-cnt-phys /dmp-cnt dma-push
;
: free-stat-cnt  ( -- )
   dmp-cnt 0=  if  exit  then
   dmp-cnt dmp-cnt-phys /dmp-cnt dma-map-out
   dmp-cnt-unaligned /dmp-cnt /align4 aligned-free
   0 0 0 to dmp-cnt to dmp-cnt-phys to dmp-cnt-unaligned
;
: dump-stat-cnt  ( adr len -- actual )
   init-stat-cnt
   cmd-dmp-cnt cmdw!
   a005 wait-stat-cnt
   dmp-cnt -rot move
   /dmp-cnt  free-stat-cnt
;
: reset-stat-cnt  ( adr len -- actual )
   init-stat-cnt
   cmd-dmp-rst-cnt cmdw!
   a007 wait-stat-cnt
   dmp-cnt -rot move
   /dmp-cnt  free-stat-cnt
;
[then]

\ ***************************************************************************
\ 			RDA (Receive Frame Area)
\ ***************************************************************************
d# 2000 constant /rfd-data
struct
   /cb-hdr +
   4 field >rfd-rbd
   2 field >rfd-actual
   2 field >rfd-size
/rfd-data field >rfd-data
constant /rfd
10 constant #rfd

0010 constant rfd-header
0008 constant rfd-flexible
8000 constant rfd-eol
4000 constant rfd-suspend

3fff constant rfd-actual-mask
4000 constant rfd-update
8000 constant rfd-eof

0001 constant rfd-tco
0002 constant rfd-ia-mismatch	\ Dest addr does not match IA
0004 constant rfd-mismatch	\ Dest addr does not match IA, MA or broadcast
0010 constant rfd-err-rx	\ RX_ER pin was asserted
0020 constant rfd-err-type-len	\ TYPE frame or len>1500 bytes
0080 constant rfd-err-short	\ <64 bytes
0100 constant rfd-err-overrun	\ dma overrun failure to acquire system bus
0200 constant rfd-err-long	\ Incoming frame is too long
0400 constant rfd-err-align
0800 constant rfd-err-crc
8000 constant rfd-complete
2000 constant rfd-ok

0 value rfd
0 value rfd-phys
0 value rfd-unaligned
0 value cur-rfd

: >rfd-idx  ( idx -- idx' )  dup #rfd >=  if  drop 0  then  ;
: cur-rfd+  ( -- )  cur-rfd 1+ >rfd-idx to cur-rfd  ;
: >rfd  ( idx -- adr )  >rfd-idx /rfd * rfd +  ;
: >rfd-phys  ( idx -- adr )  >rfd-idx /rfd * rfd-phys +  ;
: alloc-rfd  ( -- )  #rfd /rfd * alloc-buf4 to rfd-phys to rfd to rfd-unaligned  ;
: free-rfd  ( -- )
   rfd  if
      rfd rfd-phys /rfd #rfd * dma-map-out
      rfd-unaligned /rfd #rfd * /align4 aligned-free
      0 0 0 to rfd to rfd-phys to rfd-unaligned
   then
;
: init-rfd  ( -- )
   0 to cur-rfd
   #rfd 0  do
      i 1+ #rfd =  if  rfd-suspend  else  0  then
      i >rfd >cmd le-w!
      0 i >rfd >stat le-w!
      i 1+ >rfd-phys i >rfd >next le-l!
      ffff.ffff i >rfd >rfd-rbd le-l!
      0 i >rfd >rfd-actual le-w!
      /rfd-data i >rfd >rfd-size le-w!
      i >rfd i >rfd-phys /rfd dma-push
   loop
   cmd-ru-base 0 cmd-gp!
;
: rx-start   ( -- )  cmd-ru-start rfd-phys cmd-gp!  ;
: rx-resume  ( -- )  cmd-ru-resume cmdw!  ;
: ?rx-start  ( -- )  stat@ rus-mask and rus-idle =  if  rx-start  then  ;
: ?rx-resume ( -- )  stat@ rus-mask and rus-suspended =  if  rx-resume  then  ;

\ ***************************************************************************
\ 			EEPROM
\ ***************************************************************************
2 constant eeprom-op-read
1 constant eeprom-op-write

: eeprom-delay  ( -- )  1 ms  ;
: eeprom-b!     ( b -- )  1 and 2 << 3 or (eeprom!) eeprom-delay  ;
: eeprom-clk1   ( -- )  0 eeprom-b!  ;
: eeprom-clk0   ( -- )  2 (eeprom!) eeprom-delay  ;
: eeprom-cs     ( -- )  2 (eeprom!)  ;
: eeprom-uncs   ( -- )  0 (eeprom!)  ;

: eeprom-start  ( -- )  1 eeprom-b! eeprom-clk0  ;
: eeprom-op!  ( op -- )
   eeprom-cs
   eeprom-start
   dup 1 >> eeprom-b! eeprom-clk0
   eeprom-b! eeprom-clk0
;
: eeprom-bs!  ( data min max -- )
   ?do
      dup i >> eeprom-b!  eeprom-clk0
   -1 +loop  drop
;
0 value /eeprom
: eeprom-adr!  ( adr -- )   0 /eeprom 1- eeprom-bs!  ;
: eeprom-w!    ( data -- )  0 d# 15 eeprom-bs!  ;
: eeprom-b@     ( -- b )  (eeprom@)  3 >> 1 and  ;
: eeprom-w@     ( -- w )
   0  0 d# 15  do
      eeprom-clk1  eeprom-b@ i << or  eeprom-clk0
   -1 +loop
;

: set-/eeprom  ( -- )
   /eeprom  if  exit  then
   1 to /eeprom
   eeprom-op-read eeprom-op!		\ send start and read to eeprom
   8 0  do				\ send address to eeprom
      0 eeprom-b! eeprom-clk0
      eeprom-b@  if  /eeprom 1+ to /eeprom  else  leave  then
   loop
   eeprom-w@  drop
   eeprom-uncs
;
: eeprom@  ( i -- w )
   eeprom-op-read eeprom-op!
   eeprom-adr!
   eeprom-w@
   eeprom-uncs
;

: enable-eeprom!   ( -- )  0 eeprom-op! h# 30 eeprom-adr! eeprom-uncs  ;
: disable-eeprom!  ( -- )  0 eeprom-op!     0 eeprom-adr! eeprom-uncs  ;
: eeprom!  ( w i -- )
   enable-eeprom!
   eeprom-op-write eeprom-op!
   eeprom-adr! eeprom-w! eeprom-uncs
   disable-eeprom!
;

\ ***************************************************************************
\			PORT
\ ***************************************************************************
0 value port-dump	\ 16-byte aligned
0 value port-dump-phys
0 value port-dump-unaligned
d# 150 /n* constant /port-dump

: port-reset  ( -- )  0 port! 1 ms  ;
: port-sel-reset  ( -- )  2 port! 1 ms  ;
: init-port-dump  ( -- )
   port-dump 0=  if
      /port-dump alloc-buf16
      to port-dump-phys to port-dump to port-dump-unaligned
   then
   port-dump /port-dump erase
;
: free-port-dump  ( -- )
   port-dump 0=  if  exit  then
   port-dump port-dump-phys /port-dump dma-map-out
   port-dump-unaligned /port-dump /align16 aligned-free
   0 0 0 to port-dump to port-dump-phys to port-dump-unaligned
;
: port-dump  ( adr len -- actual )
   init-port-dump port-dump-phys 3 + port!
   port-dump -rot move /port-dump
   free-port-dump
;

\ ***************************************************************************
\			MDI (Management Data Interface)
\ ***************************************************************************
: mdi-wait  ( -- )  begin  mdi@ 1000.0000 and  until  ;
: phy@  ( reg -- w )  d# 16 << 1 d# 21 << or 2 d# 26 << or mdi!  mdi-wait  mdi@ ffff and  ;
: phy!  ( w reg -- )  d# 16 << or 1 d# 21 << or 1 d# 26 << or mdi!  mdi-wait  ;

[ifdef]  notdef
Reg 0: control: PHY reset, loopback, 100/10, enable auto-neg, restart auto-neg, full/half
Reg 1: status:  auto-neg complete, link up/down, jabber
Reg 4: local neg advert
Reg 5: partner ability
Reg 6: neg expansion
Reg 16: control & status
Reg 17: special control
Reg 18: clock test & control
Reg 19-25: counters
Reg 26: equalizer control & status
Reg 27: LED
[then]

\ ***************************************************************************
\			 Data structures initialization
\ ***************************************************************************
: init-buffers  ( -- )
   alloc-tcb
   alloc-tbd
   alloc-rfd  init-rfd
;

: free-buffers  ( -- )
   free-tcb
   free-tbd
   free-rfd
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
