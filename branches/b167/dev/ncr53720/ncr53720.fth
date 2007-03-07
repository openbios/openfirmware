\ See license at end of file
purpose: Driver for NCR SCRIPTS-based SCSI chips
hex

headers

\ my-id is not an instance value because the host adapter
\ ID doesn't change depending on the target you're accessing
 0          value my-id            \ host adapter's selection ID
-1 instance value his-id           \ target's selection ID
-1 instance value his-lun          \ target's unit number

\ The following "pointers" are offsets from the beginning of the "table",
\ a DMA area used for communication between the system CPU and the "SCSI
\ SCRIPTS" microcode running on the NCR chip.
\ Each refers to an 8-byte data structure containing a 32-bit count
\ field followed by a 32-bit address field.

00 constant sendmsg-ptr
08 constant rcvmsg-ptr
10 constant cmd-ptr
18 constant device-ptr
20 constant status-ptr
28 constant extmsg-ptr
30 constant data-ptr

\ For short (16 bytes or less) data arrays, such as commands, messages,
\ and status, we preallocate fixed buffers at the end of the table
\ area, copying the actual data in and out, rather than pointing to it.
\ For such short items, it is easier and more efficient to copy than
\ to set up DMA pointers and separately synchronize DMA buffers (the
\ table has to be synchronized anyway, and the entire table can be
\ synchronized in one operation).
\ The following are the locations, expressed as offsets from the beginning
\ of the table, of those preallocated buffers.  When storing these
\ values in the address fields of the table "pointers", the base
\ address of the table must be added to the offsets given below.

50 constant msgout-buf
60 constant msgin-buf
61 constant extmsgin-buf
70 constant cmd-buf
80 constant stat-buf

90 constant /table	\ Total size of table area - pointers plus buffers


\ The following values are returned in the DSPS register when the
\ SCRIPTS processor stops execution for various reasons.
\ Most of the values are commented-out, because the code does
\ not need to test for those particular values.

     00 constant ok	\ Successful completion

\ 0ff01 constant reserved-phase
\ 0ff02 constant simple-msg
  0ff03 constant extended-msg
\ 0ff04 constant no-reselect-msg
\ 0ff05 constant no-disconnect-msg
\ 0ff06 constant reselected
\ 0ff07 constant selected


\ Offsets from the beginning of the SCRIPTS microcode for performing
\ various functions.  These values, added to the base address of the
\ microcode, are written to the SCRIPTS processor "program counter"
\ (DSP register) to initiate SCRIPTS processing.

 0 constant select-offset	\ Start transaction with selection
 8 constant switch-offset	\ Continue processing SCSI requests
d8 constant msgout-offset	\ Send a message


create rom-script	\ Microcode for the chip SCRIPTS processor
			\ Must be copied to DMA memory

\ select  -  0		Primary Entry Point
 47000018 l,	00000148 l,	\ SELECT ATN FROM device-ptr (18), REL(resel)

\ switch    - 8		Handle SCSI requests - resumption entry point
 878b0000 l,	00000030 l,	\ JUMP REL(msgin), WHEN MSG_IN
 868a0000 l,	000000c0 l,	\ JUMP REL(msgout), IF MSG_OUT
 828a0000 l,	000000c8 l,	\ JUMP REL(command_phase), IF CMD
 808a0000 l,	000000d0 l,	\ JUMP REL(dataout), IF DATA_OUT
 818a0000 l,	000000d8 l,	\ JUMP REL(datain), IF DATA_IN
 838a0000 l,	000000e0 l,	\ JUMP REL(end), IF STATUS
 98080000 l,	0000ff01 l,	\ INT reserved-phase (ff01)

\ msgin - 40
 1f000000 l,	00000008 l,	\ MOVE FROM rcvmsg (8), WHEN MSG_IN
 808c0001 l,	00000030 l,	\ JUMP REL(ext_msg), IF 0x01
 808c0004 l,	00000040 l,	\ JUMP REL(disc), IF 0x04
 60000040 l,	00000000 l,	\ CLEAR ACK
 808c0002 l,	ffffffa0 l,	\ JUMP REL(switch), IF 0x02 ; ign. SaveDataPtrs
 808c0007 l,	ffffff98 l,	\ JUMP REL(switch), IF 0x07 ; ign. MsgReject
 808c0003 l,	ffffff90 l,	\ JUMP REL(switch), IF 0x03 ; ign. RestDataPtrs
 98080000 l,	0000ff02 l,	\ INT simple-msg (ff02)

\ ext_msg - 80
 60000040 l,	00000000 l,	\ CLEAR ACK
 1f000000 l,	00000028 l,	\ MOVE FROM extmsg-ptr (28), WHEN MSG_IN
 98080000 l,	0000ff03 l,	\ INT extended-msg (ff03)

\ disc - 98
 7c027f00 l,	00000000 l,	\ MOVE SCNTL2 & 0x7f to SCNTL2 ;expect disconn.
 60000040 l,	00000000 l,	\ CLEAR ACK
 48000000 l,	00000000 l,	\ WAIT DISCONNECT
 54000000 l,	000000a0 l,	\ WAIT RESELECT REL(select)
 9f030000 l,	0000ff04 l,	\ INT no-reselect-msg, WHEN NOT MSG_IN
 1f000000 l,	00000008 l,	\ MOVE FROM rcvmsg (8), WHEN MSG_IN
 60000040 l,	00000000 l,	\ CLEAR ACK
 80880000 l,	ffffff30 l,	\ JUMP REL(switch)                 

\ msgout - d8		Send message  - Entry point for negotiation messages
 1e000000 l,	00000000 l,	\ MOVE FROM sendmsg-ptr (0), WHEN MSG_OUT
 80880000 l,	ffffff20 l,	\ JUMP REL(switch)

\ command_phase - e8
 1a000000 l,	00000010 l,	\ MOVE FROM cmd-ptr (10), WHEN CMD
 80880000 l,	ffffff10 l,	\ JUMP REL(switch)

\ dataout - f8
 18000000 l,	00000030 l,	\ MOVE FROM data-ptr (30), WHEN DATA_OUT
 80880000 l,	ffffff00 l,	\ JUMP REL(switch)

\ datain - 108
 19000000 l,	00000030 l,	\ MOVE FROM data-ptr (30), WHEN DATA_IN
 80880000 l,	fffffef0 l,	\ JUMP REL(switch)

\ end - 118
 1b000000 l,	00000020 l,	\ MOVE FROM status-ptr (20), WHEN STATUS
 9f030000 l,	0000ff05 l,	\ INT no-disconnect-msg (ff05), WHEN NOT MSG_IN
 1f000000 l,	00000008 l,	\ MOVE FROM rcvmsg (8), WHEN MSG_IN
 7c027f00 l,	00000000 l,	\ MOVE SCNTL2 & 0x7f to SCNTL2 ;expect disconn.
 60000040 l,	00000000 l,	\ CLEAR ACK
 48000000 l,	00000000 l,	\ WAIT DISCONNECT
 98080000 l,	00000000 l,	\ INT ok (0)

\ resel - 150
 98080000 l,	0000ff06 l,	\ INT reselected (ff06)

\ select - 158
 98080000 l,	0000ff07 l,	\ INT selected (ff07)

160 constant /script	\ Total size of microcode


\ The layout below assumes little-endian mode.  The definition of
\ "reg" takes care of matching the assumption and the reality, using
\ "endian-mask" to transform the byte addresses.  The constants are
\ offsets from the base address of the chip.

00 constant scntl0	( byte )
		\ c0 - full arbitration
		\ 20 - start arbitration
		\ 10 - assert ATN/ on a start sequence
		\ 08 - enable parity checking  (use 0)
		\ 04 - generate parity
		\ 02 - assert ATN/ on parity error (use 0)
		\ 01 - target mode (use 0)

01 constant scntl1	( byte )
		\ 80 - extra clock cycle of data setup time
		\ 40 - drive data bus (for testing or low-level)
		\ 20 - disable halt on parity error (for target mode)
		\ 10 - connected (read) (writeable for diags)
		\ 08 - assert RST/ (timed externally) 
		\ 04 - force bad parity (for diags)
		\ 02 - immediate arbitration (for multi-threading)
		\ 01 - start transfer (read) (for SCRIPTS)

02 constant scntl2	( byte )
		\ 80 - disconnect not expected.  Clear it
		\	  prior to some commands.  See doc
		\ 40 - chained mode (see CHMOV SCRIPTS command)
		\ 08 - Wide Send. (read)
		\ 01 - Wide Receive. (read)

03 constant scntl3	( byte )
		\ 70 - Synch. clock factor - Use 40
		\ 08 - enable wide mode
		\ 07 - clock factor - Use 40 but see spec

04 constant scid	( byte )
		\ 40 - enable response to reselection
		\ 20 - enable response to selection (target mode)
		\ 0f - SCSI ID 0-f

05 constant sxfer	( byte )
		\ e0 - synch. transfer period
		\ 0f - max. synch. offset - 0 for async.

06 constant sdid	( byte )
		\ 0f - SCSI destination ID.

07 constant gpreg	( byte )
		\ 10 - General purpose output pin
		\ 0f - input pins

08 constant sfbr	( byte )
		\ first byte received in an async. transfer

09 constant socl	( byte )
		\ 80 REQ  40 ACK  20 BSY  10 SEL
		\  8 ATN   4 MSG   2 C/D   1 I/O	For PIO

0a constant ssid	( byte RO )
		\ 80 - valid
		\ 0f - SCSI ID of the selecting device

0b constant sbcl	( byte RO )
		\ 80 REQ  40 ACK  20 BSY  10 SEL (read status)
		\  8 ATN   4 MSG   2 C/D   1 I/O   (of SCSI control lines)

0c constant dstat	( byte RO )
		\ 80 - DMA FIFO empty
		\ 40 - Host parity error
		\ 20 - Bus fault
		\ 10 - Aborted
		\ 08 - SCRIPT single step interrupt
		\ 04 - SCRIPT interrupt instruction executed
		\ 02 - Watchdog timeout
		\ 01 - Illegal instruction

0d constant sstat0	( byte RO )
		\ 80 - Input data latch LSB full
		\ 40 - Output data register LSB full
		\ 20 - Output data latch LSB full
		\ 10 - Arbitration in progress
		\ 08 - Lost arbitration
		\ 04 - Won arbitration
		\ 02 - RST line state
		\ 01 - Parity line state

0e constant sstat1	( byte RO )
		\ f0 - #bytes or words in FIFO
		\ 08 - Latched parity line state
		\ 04 - Latched MSG line state
		\ 02 - Latched C/D line state
		\ 01 - Latched I/O line state

0f constant sstat2	( byte RO )
		\ 80 - Input data latch MSB full
		\ 40 - Output data register MSB full
		\ 20 - Output data latch MSB full
		\ 08 - Latched parity line for high byte
		\ 02 - Last disconnect
		\ 01 - Parity line state for high byte

10 constant dsa		( long )
		\ Data structure address (base for table indirect)

14 constant istat	( byte )
		\ 80 - Abort current operation
		\ 40 - Reset chip (write 1 then 0)
		\ 20 - Flag to communicate with SCRIPTS
		\ 10 - Semaphore - Flag to communicate from SCRIPTS
		\ 08 - Connected (see scntl1)
		\ 04 - Interrupt on the fly (SCRIPTS flag)
		\ 02 - SCSI Interrupt Pending
		\ 01 - DMA Interrupt Pending
( 3 reserved )

18 constant ctest0	( byte )
		\ 80 - Disable bursting
		\ 60 - snoop control
		\ 08 - DMA FIFO parity (for testing)
		\ 04 - Even Host parity
		\ 02 - Transfer type bit (TT1)

19 constant ctest1	( byte RO )
		\ f0 - empty byte lanes at bottom of DMA FIFO
		\ 0f - full byte lanes at top of DMA FIFO

1a constant ctest2	( byte RO )
		\ 80 - Data transfer direction (1=in)
		\ 40 - Copy of 20 bit in ISTAT register
		\ 08 - DMA FIFO parity
		\ 04 - SCSI true end of process
		\ 02 - status of internal Data Request signal
		\ 01 - status of internal Data Acknowledge signal

1b constant ctest3	( byte )
		\ f0 - Chip revision level
		\ 08 - Flush DMA FIFO
		\ 04 - Clear DMA and SCSI FIFOs
		\ 02 - Fetch pin mode (irrelevant)
		\ 01 - Snoop pins mode (XXX SC1 affect SIZ0 !!!)

1c constant temp	( long )
		\ return address for SCRIPTS call instruction

20 constant dfifo	( byte )
		\ 7f - DMA FIFO count


21 constant ctest4	( byte RO? )
		\ 80 - Host bus MUX mode
		\ 40 - Tri-state chip pins (diags)
		\ 20 - Tri-state SCSI pins (diags)
		\ 10 - Read shadow copies of TEMP and DSA registers
		\ 08 - Enable host bus parity checking
		\ 07 - Select DMA byte lane (diags)

22 constant ctest5	( byte )
		\ 80 - Increment address pointer in DNAD
		\ 40 - Decrement clock byte counter
		\ 10 - 1: assert  0: deassert  for 08 bit
		\ 08 - force DMAWR

23 constant ctest6	( byte )
		\ data value to write to DMA FIFO

24 constant dbc		( triple )
		\ (24 bits) byte count for Block Move

27 constant dcmd	( byte )
		\ DMA command - format is instruction-dependent

28 constant dnad	( long )
		\ general purpose address pointer for SCRIPTS

2c constant dsp		( long )
		\ PC for SCRIPTS - writing it starts SCRIPTS execution

30 constant dsps	( long )
		\ Contains 2nd longword of SCRIPTS instruction or
		\ interrupt vector

34 constant scratcha	( long )
		\ Scratch register

38 constant dmode	( byte )
		\ c0 - burst length
		\ 30 - function code (irrelevant)
		\ 08 - function code 0 (irrelevant)
		\ 04 - Don't auto-increment DNAD
		\ 02 - tt0 mode (irrelevant)
		\ 01 - manual start - disable auto-start of SCRIPTS

39 constant dien	( byte )
		\ 40 - Host parity error interrupt mask
		\ 20 - Bus fault interrupt mask
		\ 10 - Abort interrupt mask
		\ 08 - SCRIPT step interrupt mask
		\ 04 - SCRIPT breakpoint interrupt mask
		\ 02 - Watchdog interrupt mask
		\ 01 - Illegal instruction interrupt mask

3a constant dwt		( byte )
		\ Watchdog timer - # of 16*BCLK ticks

3b constant dcntl	( byte )
		\ 40 - controls meaning of FC/TM pins (irrelevant)
		\ 20 - Enable STERM ack ?????
		\ 10 - Single Step mode
		\ 08 - 16-bit Host bus
		\ 04 - Start DMA (manual start, single step)
		\ 02 - Fast Arbitration
		\ 01 - 53C700 compatibility mode (affects SSID)

3c constant adder	( long RO )
		\ output of internal adder

40 constant sien0	( byte )	\ Interrupt mask bits
		\ 80 - phase mismatch
		\ 40 - function complete
		\ 20 - selected
		\ 10 - reselected
		\ 08 - gross error
		\ 04 - unexpected disconnect
		\ 02 - SCSI RST
		\ 01 - SCSI parity error

41 constant sien1	( byte )	\ Interrupt mask bits
		\ 04 - selection or reselection timeout
		\ 02 - general purpose timer expired
		\ 01 - handshake-to-handshake timer expired

42 constant sist0	( byte )	\ Interrupt status bits
		\ 80 - phase mismatch
		\ 40 - function complete
		\ 20 - selected
		\ 10 - reselected
		\ 08 - gross error
		\ 04 - unexpected disconnect
		\ 02 - SCSI RST
		\ 01 - SCSI parity error

43 constant sist1	( byte )	\ Interrupt status bits
		\ 04 - selection or reselection timeout
		\ 02 - general purpose timer expired
		\ 01 - handshake-to-handshake timer expired

44 constant slpar	( byte )
		\ XOR checksum of bytes sent or received

45 constant swide	( byte )
		\ residual byte from odd-length wide-mode transfer

46 constant macntl	( byte )
		\ 0f - If any of these bits is set, the MAC (near/far)
		\      pin will be asserted

47 constant gpcntl	( byte )
		\ 10 - 0 indicates that GPREG bit 4 is an output
		\ 0f - set to 0 to make the corresponding GPREG bit an output

48 constant stime0	( byte )
		\ f0 handshake-to-handshake timer period (encoded)
		\ 0f selection timeout period (encoded)

49 constant stime1	( byte )
		\ 0f general purpose timer period (encoded)
4a constant respid0	( byte )
		\ selection/reselection response ID (bitmask for ids 7..0)
4b constant respid1	( byte )
		\ selection/reselection response ID (bitmask for ids 15..8)

4c constant stest0	( byte )
		\ 08 - selection response logic test
		\ 04 - arbitration priority encoder test
		\ 02 - synchronous offset zero
		\ 01 - synchronous offset maximum

4d constant stest1	( byte )
		\ 80 - 8xx series: Use PCI clock instead of external oscillator
		\ 03 - 7xx series: SCSI FIFO parity for 2 byte lanes

4e constant stest2	( byte )
		\ 80 - SCSI control enable (diags)
		\ 40 - Reset SCSI offset (set it after gross error)
		\ 20 - Differential mode
		\ 10 - Loopback mode (diags)
		\ 08 - Tri-state SCSI drivers (for loopback mode)
		\ 04 - Always wide mode (set to 0)
		\ 02 - Glitch filter (must be 0 for fast mode)
		\ 01 - Low level mode (no DMA, no SCRIPTS)

4f constant stest3	( byte )
		\ 20 - Halt SCSI clock (saves power)
		\ 10 - Disable SASI single-initiator response
		\ 08 - All SCSI devices are wide
		\ 04 - Timer test mode (shortens timeouts)
		\ 02 - Clear SCSI FIFO full flags
		\ 01 - SCSI FIFO test mode (diag access to FIFO)

50 constant sidl	( word )
		\ SCSI input data latch (diags, PIO)
( 2 reserved )

54 constant sodl	( word )
		\ SCSI output data latch (diags, PIO)
( 2 reserved )

58 constant sbdl	( word )
		\ SCSI data bus, unlatched
( 2 reserved )

5c constant scratchb	( long )
		\ Scratch register


\ 8-bit chip register access
: reg@  ( reg# -- byte )  endian-mask xor  chip-base +  rb@  ;
: reg!  ( byte reg# -- )  endian-mask xor  chip-base +  rb!  ;

\ 32-bit chip register access
: reg-l!  ( long reg# -- )  chip-base +  rl!  ;
: reg-l@  ( reg# -- long )  chip-base +  rl@  ;

\ SCRIPTS memory access
: script-l!  ( l adr -- )
   >r lbsplit
   endian-mask  if
      r@     c!  r@ 1+ c!  r@ 2+ c!  r> 3 + c!
   else
      r@ 3 + c!  r@ 2+ c!  r@ 1+ c!  r>     c!
   then
;
: script-l@  ( adr -- long )
   >r
   endian-mask  if
      r@ 3 + c@  r@ 2+ c@  r@ 1+ c@  r>     c@
   else
      r@     c@  r@ 1+ c@  r@ 2+ c@  r> 3 + c@
   then
   bljoin
;

\ Turn bits on and off in chip registers
: bit-on  ( bitmask reg# -- )  tuck reg@ or  swap reg!  ;
: bit-off ( bitmask reg# -- )  tuck reg@ swap invert and  swap reg!  ;


false instance value debug?       \ Trace SCSI Phases
true  instance value scsi2?       \ Use SCSI-2 protocol with full messaging
true  instance value parity?      \ Check SCSI bus parity
true  instance value wide?        \ Use wide mode if target supports it
false instance value sync?        \ Use synchronous mode if target supports it
true  instance value fast?        \ Use fast mode if target supports it

: cdump  ( adr len -- )	  \ Debugging tool - display "len" bytes at "adr"
   base @ >r  hex
   bounds  ?do  i c@ 3 u.r  loop
   r> base !
;

: restore-initiator-id  ( -- )
   my-id 40 or  scid reg!  \ Selection ID, respond to reselection

   respid0 reg@  0=  if	   \ Rev C,D only
      1 my-id lshift  wbsplit  ( low high )
      respid1 reg!  respid0 reg!
   then
;
: chip-off  ( -- )  40 istat bit-on   ;
: chip-on   ( -- )  40 istat bit-off  ;

: restart  ( -- )  4 dcntl bit-on  ;   \ Used in single-step mode

default-burst-len  value burst-len    \ Number of 32-bit transfers per burst

: reset-chip  ( -- )
   chip-off  chip-on	   \ Abort any currently running scripts.

   restore-initiator-id

   \ The chip can theoretically transfer data at up to 20 MBytes/sec
   \ (I have measured > 15 MBytes/sec).  However, few current (1993)
   \ disks spin fast enough to do any better than 4 MBytes/sec.
   \ In asynchronous, narrow mode, with bursts turned off on a
   \ 20MHz SBus, I have measured about 4.2 MBytes/second (using a
   \ READ-BUFFER command).  Consequently, enabling the fancy speedups
   \ (wide mode, synchronous mode, burst mode) doesn't buy us anything
   \ with this generation of disks.

   burst-len case
      1  of  80 ctest0 reg!  endof   \ Disable bursting
      2  of                  endof   \ chip defaults to 2-transfer bursts
      4  of  40 dmode reg!   endof   \ 4-transfer bursts
   endcase

   ctest4-val ctest4 reg!	\ MUX mode?
   dcntl-val  dcntl  reg!	\ Host bus arbitration
   \ Other registers may need to be configured differently for
   \ different host bus interfaces.

   c4 scntl0 reg!       \ Full arbitration, generate parity
   0d stime0 reg!	\ 409.6 msec selection timeout, none on handshake
                        \ The SCSI-2 spec recommends 250 msec selection timeout

   2		        \ Use extended glitch filtering for now
   differential?  if  h# 20 or  then
   stest2 reg!
;
: set-modes  ( -- )
   debug?   if  10 dcntl  bit-on  then    \ Single-step bit
   parity?  if   6 scntl0 bit-on  then    \ Check parity bit
;

\ The following code relating to "reset-wait" allows the driver to support
\ older SCSI peripherals that hang the bus or do other bad things if they
\ are selected shortly after a bus reset.

\ 5 seconds appears to be about the right number.  At 4 seconds, the
\ Emulex MT-02 won't hang the SCSI bus, but it sometimes won't respond.
d# 5000 value scsi-reset-delay

create reset-done-time 0 ,
create resetting false ,

: reset-wait  ( -- )
   resetting @  if
      begin  get-msecs reset-done-time @ -  0>=  until
      resetting off
   then
;

: reset-scsi-bus  ( -- )
   8 scntl1 bit-on	\ Assert RST/ signal
   1 ms			\ RST/ must stay on at least 25 usec
   8 scntl1 bit-off	\ Deassert RST/ signal
   d# 250 ms		\ 250 ms RST/ recovery time


   \ After resetting the SCSI bus, we have to give the target devices
   \ some time to initialize their microcode.  Otherwise the first command
   \ may hang, as with Emulex MD21 and MT02 controllers.  We note the
   \ time when it is okay to access the bus (now plus some delay), and
   \ "start-command" will delay until that time is reached, if necessary.
   \ This allows us to overlap the delay with other work in many cases.

   get-msecs scsi-reset-delay + reset-done-time !  resetting on
;


: aligned-alloc  ( size -- unaligned-virt aligned-virtual )
   4 +  dma-alloc
   dup dup 3 and  if  3 + 3 invert and  then ( unaligned-virt aligned-virtual )
;
: aligned-free  ( virtual size -- )
   4 +  dma-free
;


false value parent-sync?
external
: dma-sync  ( virt phys size -- )
   parent-sync?  if  " dma-sync" $call-parent  else  2drop drop  then
;
headers

\ Access and initialization words for the DMA table that is used for
\ communication between the system CPU and the "SCSI SCRIPTS" microcode.

0 value table
0 value unaligned-table
0 value table-phys

: sync-table  ( -- )  table table-phys /table dma-sync  ;

: table-c@  ( offset -- byte )  table + c@  ;
: table-c!  ( byte offset -- )  table + c!  ;

\ Set a table "pointer" entry
: table!  ( address count offset -- )
   table +  tuck  script-l!    ( address offset )
   la1+ script-l!
;

\ Set a table "pointer" entry to point to a buffer within the table area
: itable!  ( buffer-offset count offset -- )
   rot table-phys + -rot table!
;

\ Set just the "count" field in a table "pointer"
: table-count!  ( count offset -- )  table +  script-l!  ;

: init-table ( -- )

   \ If the parent has a DMA synchronization routine, install it,
   \ otherwise leave the null version installed.
   " dma-sync" my-parent ihandle>phandle find-method  ( false | xt true )
   dup to parent-sync?  if  drop  then

   \ Allocate space for the table of addresses used by the table indirect
   \ commands.  The table must be aligned on a 32-bit boundary.

   /table aligned-alloc to table  to unaligned-table

   \ We must map this in now because itable! depends on table-phys
   table /table false  " dma-map-in" $call-parent  ( devaddr )  to table-phys

   msgout-buf    1  sendmsg-ptr itable!
   msgin-buf     1  rcvmsg-ptr  itable!
   extmsgin-buf  1  extmsg-ptr  itable!
   cmd-buf       6  cmd-ptr     itable!
   stat-buf      1  status-ptr  itable!

   table-phys dsa reg-l!
;

: release-table  ( -- )  unaligned-table /table aligned-free  ;

\ Copy the buffer 'adr len' into the table at 'buf-offset' and
\ write its starting address into the table pointer entry at ptr-offset

: table-move  ( adr len buf-offset ptr-offset -- len )
   >r
   swap >r  table +  r@ move  r> r> table-count!
;


\ Initialization of the SCSI SCRIPTS microcode, which must be located
\ in DMA memory.

0 value script
0 value unaligned-script
0 value script-phys
: init-script  ( -- )
   /script  aligned-alloc  to script  to unaligned-script
   rom-script  script  /script  bounds  ?do
      dup l@  i script-l!  la1+
   /l +loop   drop

   scsi2? 0=  if
      \ Use select-without-ATN for SCSI-1
      46000018 script select-offset + script-l!
   then
   script /script false  " dma-map-in" $call-parent  ( devaddr ) to script-phys
;
: release-script  ( -- )
   \ Reset the chip by toggling the reset bit.  Leave it in the "not reset"
   \ position because the NT driver doesn't clear it.  This is safe because
   \ the chip doesn't start executing the script until you tell it to do so.
\   chip-off chip-on

   unaligned-script /script aligned-free
;


\ This value depends on the clock frequency.  It really should be calculated
\ instead of being hardwired.

33 instance value clock-factors	\ Value for SCNTL3 register
				\ 70 - synch. divisor, 08 - wide, 07 - divisor
				\ The wide-mode bit and the synchronous
				\ divisor is per-target

\ Called if the data transfer was stopped before the requested number
\ of bytes were transferred.  This sometimes happens when you don't know
\ the exact number of bytes to ask for.

: flush-dma-fifo  ( -- )
   8 ctest3 bit-on

   \ Wait for FIFO to drain.
   begin  dbc reg-l@  7f and  dfifo reg@  7f and  = until

   8 ctest3 bit-off
;

: .script-address  ( -- )
   ."  at script address " dsp reg-l@  script-phys - 4 u.r
;

: >phase-message  ( phase -- adr len )
   case
      0 of  " data out"     endof
      1 of  " data in"      endof
      2 of  " command"      endof
      3 of  " status"       endof
      4 of  " res0"         endof
      5 of  " res1"         endof
      6 of  " message out"  endof
      7 of  " message in"   endof
   endcase
;
: .bits  ( b adr len -- )
    0  do                                     ( b adr )
      dup i + c@  2 pick 7 i - rshift 1 and   ( b adr char bit )
      if  h# 20 invert and  then  emit        ( b adr )
   loop                                   ( b adr )
   2drop                                      ( )
;
: .bus-status  ( -- )
   .script-address

   ."  Sbcl: " sbcl reg@ dup " rabstmci" .bits  ( sbcl-val )
   ."  Dstat: " dstat reg@ u.  ." Sstat0: " sstat0 reg@ u.

   \ Phase is meaningless if there is no request.
   dup h# 80 and  if
      ." Phase: " 7 and >phase-message type      ( )
   else
      drop
   then
   cr
;
\ : .phase-mismatch  ( -- )
\    ." Phase mismatch" .script-address
\    ." . Expecting `"  sbcl reg@ 7 and  >phase-message type  ." ' phase" cr
\ ;

\ Debugging tool - shows progress of SCRIPT execution while single-stepping
: .step  ( -- )
   dsp reg-l@ script-phys -  case
       0 of  ." Select "     endof
       8 of  ." | "          endof   \ Request wait
      40 of  ." MessageIn "  endof
      80 of  ." ExtMsgIn "   endof
      98 of  ." Disconnect " endof
      d8 of  ." MessageOut " endof
      e8 of  ." Command "    endof
      f8 of  ." DataOut "    endof
     108 of  ." DataIn "     endof
     118 of  ." Status" cr   endof
     150 of  ." Selected" cr endof
     158 of  ." Reselected" cr endof

   endcase
\ For low-level hardware debugging only; remove for production use
   " ??cr" eval .bus-status
;

: .illegal-instruction  ( -- )  ." Illegal instruction" .script-address cr  ;

: >script-message  ( int-code -- adr len )
   case
      0ff01 of  " Reserved phase"               endof
      0ff02 of  " Simple message"               endof
      0ff03 of  " Extended message"             endof
      0ff04 of  " No message after reselect"    endof
      0ff05 of  " No message after disconnect"  endof
      0ff06 of  " Reselected"                   endof
      0ff07 of  " Selected"                     endof
      ( default )  " Unknown script interrupt code" rot
   endcase
;
: .script-interrupt  ( -- )  
   ." Script interrupt: "  dsps reg-l@ >script-message type cr
;

\ Return a message string corresponding to a bit in the combined
\ interrupt status mask.
: >error-message  ( bit# -- adr len )
   case
       0 of  " Illegal instruction"   endof
       1 of  " Watchdog timeout"      endof
       2 of  " Script interrupt"      endof
       3 of  " Script step interrupt" endof
       4 of  " SBus Late Error"       endof
       5 of  " Bus fault "            endof
       6 of  " Host parity error"     endof
       7 of  " FIFO Empty"            endof
       8 of  " SCSI parity error"     endof
       9 of  " SCSI reset received"   endof
      0a of  " Unexpected disconnect" endof
      0b of  " SCSI gross error"      endof
      0c of  " Reselected"            endof
      0d of  " Selected"              endof
      0e of  " Arbitration Complete"  endof
      0f of  " Phase Mismatch"        endof
      10 of  " Handshake timer expired"         endof
      11 of  " General-purpose timer expired"   endof
      12 of  " Selection time-out"              endof
      ( default )  " No Error"  rot
   endcase
;

\ Display a message telling which bits of the combined interrupt
\ status mask were set.
: show-status  ( mask -- )
   13 0  do                                          ( mask )
      dup 1 and  if  i >error-message type cr  then
      2/
   loop
   drop
;  

\ Read the various interrupt status registers, concatenating them
\ into a single mask containing all the status bits.
\ 
\ |___0___|_SIST1_|_SISTO_|_DSTAT_|

0 value dma-fifo-empty

: get-istat  ( -- mask )
   istat reg@
   dup 2 and  if  sist0 reg@ sist1 reg@  else  0 0  then  ( istat sist0 sist1 )
   rot 1 and  if
      dstat reg@  dup 80 and to dma-fifo-empty   7f and   ( sist0 sist1 dstat )
   else
      0
   then  ( sist0 sist1 dstat )

   -rot 0 bljoin
;

\ Clear any pending interrupts
: clear-interrupts  ( -- )  begin  get-istat  0= until  ;

0 value deadline
0 instance value timeout
external
: set-timeout  ( n -- )  to timeout  ;
headers

\ The delay in the interrupt polling loop is empirically necessary.
\ Without it, incoming DMA data gets corrupted rather frequently.
\ ??? Is the data transfer reliable with the delay, or is this a
\ potential timebomb?

5 value poll-delay
: wait-for-interrupt  ( -- )
   begin
      \ Timeout=0 means continue indefinitely
      timeout 0=  get-msecs deadline - 0<  or
[ifdef] debug-scsi
key? abort" Aborted from keyboard"
[then]
   while
      poll-delay ms
      istat reg@ 3 and  if  exit  then
   repeat
;

\ Begin execution of the SCRIPT processor at the microcode offset "scriptp"
: start-script  ( scriptp -- )
   set-modes
   clear-interrupts

   sync-table                    ( scriptp )	\ Handoff DMA area

   script-phys  +  dsp reg-l!    ( )		\ Start script execution 
   debug?  if  .step  restart  then		\ Tickle processor if necessary

   wait-for-interrupt

   sync-table					\ Take back DMA area
;

defer error-reset   ' reset-chip to error-reset
' noop to error-reset

\ : abort-operation  ( -- )
\    error-reset  \ too severe?
\    \ 80 istat bit-on
\    \ wait-for-interrupt
\    \ begin  wait-for-interrup  istat reg@ 1 and  while
\    \    sist0 reg@ drop  sist1 reg@ drop
\    \ repeat
\    \ istat reg@ 2 and  if  0 istat reg!  then
\    \ dstat reg@  drop
\ ;


\ An abbreviated "low level" driver that reads SCSI data bytes one
\ at a time, handling the SCSI REQ/ACK handshake in software.  It is
\ used to read incoming "extended messages", which are typically very
\ short (2 or 3 bytes).  For these short messages, which also require
\ precise control of the relationship between the SCSI ATN and ACK
\ lines, the effort of synchronizing DMA, starting and stopping the
\ SCRIPTS processor, and handling the resulting state transitions
\ is more trouble than "bit-banging" the chip.

: wait-req     ( -- )  begin  sbcl reg@ 80 and      until  ;
: wait-no-req  ( -- )  begin  sbcl reg@ 80 and  0=  until  ;

: do-ack  ( ack-mask -- )   \ Preserve phase bits  and  ATN bit
   sbcl reg@ 7 and or  socl reg@ 8 and or  socl reg!
;
: -ack  ( -- )  wait-no-req  0 do-ack  ;
: +ack  ( -- )              40 do-ack  ;

: +atn  ( -- )  8 socl bit-on   ;

: read-scsi-byte  ( -- byte )
   wait-req             ( )
   sbdl reg@            ( byte )        \ Read message byte
   +ack                 ( )             \ ACK with same phase
;

: read-ext-msg  ( -- )
   \ The first extended message byte, containing the number of subsequent
   \ bytes, has been read into extmsgin-buf , but the ACK for that cycle
   \ has not yet been cleared.

   extmsgin-buf table-c@   ( length )
   0  do  -ack read-scsi-byte  extmsgin-buf 1+ i + table-c!  loop

   \ ACK is left asserted so we can respond with a message out if necessary.
;

: send-message  ( adr len -- scriptp false )
   msgout-buf sendmsg-ptr table-move   ( )   \ Copy in the message buffer
   +atn                 \ Set ATN to tell target we want to send a message
   -ack                 \ Clear residual ACK from preceding phase
   msgout-offset false
;

create msg-rej  7 c,
: send-message-reject  ( -- scriptp false )  msg-rej 1 send-message  ;

\ offperiod holds the synchronous offset and synchronous transfer
\ period for the target/unit that we are talking to.  It is encoded
\ as with the SXFER register.  If its value is -1, the appropriate
\ offset for the device is not known, and must be negotiated.
\ If its value is 0, we are using asychronous transfers.

-1 instance value offperiod	\ Per-target, encodes synch. offset,period

\ Minimum synchronous transfer period.
: min-period  ( -- nsecs )  fast?  if  d# 100  else  d# 200  then  ;

d#  8 constant max-offset       \ Number of deferred ACKs we can tolerate

\ Prescale divisor and dividend down by a factor of 10 to avoid a
\ large-divisor bug in some Open Boot implementations.  d# 100.000.000
\ is d# 1.000.000.000 nsecs/sec divided by 10.
d# 100.000.000 clock-frequency d# 10 /  /  constant fast-sync-clock-period

: sync-clock-period  ( -- nsecs )
   fast-sync-clock-period

   \ XXX this is naive - it assumes that the only two choices of
   \ clock divisor are /2 and /1.  For complete generality, we
   \ should support all of the available clock divisors.

   clock-factors 70 and  30  =  if  2*  then
;

create sync-msg   01 c, 03 c, 01 c, min-period c, max-offset c,

: dec.  ( n -- )  base @ >r  decimal .  r> base !  ;

\ When this is called, we have received a synchronous negotiation
\ message from the target.  Based on the target's capabilities and
\ our own capabilities (which depend on our clock frequency, as well
\ as the possibility that the user has specified asynchronous mode),
\ we calculate the best synchronous transfer characteristics, set
\ our transfer parameters accordingly, and respond with an outgoing
\ synchronous negotiation message telling the target what we decided.

defer handle-synch-negotiation
: (handle-synch-negotiation)  ( -- scriptp false )
   \ If the user told us not to use sync mode, tell target to
   \ use asynchronous mode
   sync?  0=  if
      0 sync-msg 4 + c!  sync-msg 5 send-message
      exit
   then

   \ The goal is to find the minimum number of internal clock cycles
   \ that will result in a synchronous transfer period greater than
   \ the larger of the two devices' minimum transfer period.

   \ Find the shortest period that both parties can handle.
   \ Periods are represented in synchronous negotiation messages
   \ in units of 4 nsecs.

   extmsgin-buf 2 + table-c@  4 *       ( target-period-nsecs )
   min-period  max                      ( period )

   \ If the target can do better than 200 nsecs, use fast mode
   dup d# 200 <  if
      2 stest2 bit-off    \ Turn off extended REQ/ACK glitch filter
      \ Turn off divide-by-two on synchronous clock
      clock-factors  f and  10 or  to clock-factors
      clock-factors scntl3 reg!
   then

   \ Convert to the number of internal clock cycles, rounding up
   \ if the desired period is not evenly divisible by the internal
   \ clock period.

   sync-clock-period 1- +  sync-clock-period /   ( #clocks )

   dup sync-clock-period *                       ( #clocks period )

   debug?  if
      ." Synchronous at "  dup  dec.  ." nsecs"
   then

   \ Put period, represented in 4 nsec units, in outgoing message
   4 / sync-msg 3 + c!                           ( #clocks )

   \ The chip represents clock cycle counts 4,5,...,11 with codes 0,1,...,7
   4 -                                           ( TP-code )
   d# 5 lshift   \ Move into the bit field       ( TP-code<< )

   extmsgin-buf 3 + table-c@  max-offset  min    ( TP-code<< offset )

   debug?  if  ." , offset " dup dec.  cr  then

   dup sync-msg 4 + c!              \ Put offset in outgoing message

   or        \ Merge bits
   dup  to offperiod                \ Remember it for later selections
   sxfer reg!                       \ Load it into the chip too

   sync-msg 5 send-message
;
['] (handle-synch-negotiation) to handle-synch-negotiation

\ When this is called, we have received a synchronous negotiation
\ message from the target.  We assume that we have already sent
\ the target our wide mode characteristics, and that the target is
\ responding, so we don't need to send a message back; we just
\ pick up his parameters and use them (he isn't supposed to tell
\ us a wider bus than we told him).

\ XXX What if the target gets reset without our knowledge and sends
\ us an unsolicited wide negotiation message?  Perhaps we need a
\ "wide negotiation expected" flag to control whether or not to
\ respond.

defer handle-wide-negotiation

: (handle-wide-negotiation)  ( -- scriptp false )
   extmsgin-buf 2 + table-c@  1 >=  if
      debug?  if  ." Wide mode accepted"  cr  then
      clock-factors  8 or  to clock-factors     \ Wide mode on
      8 scntl3 bit-on                           \ Turn it on now
   then
   -ack
   switch-offset false
;
['] (handle-wide-negotiation) to handle-wide-negotiation

\ XXX it would be better to integrate the handling of extended messages
\ and unexpected simple messages into one routine.  For now, however, all
\ unexpected simple messages are fatal (non-fatal ones are handled by
\ the SCRIPTS processor without our intervention).

: handle-ext-msg  ( -- scriptp false | result true )
   read-ext-msg		\ Finish reading the extended message

   \ ACK is still asserted.  We don't deassert it until we decode the
   \ message, because we may need to assert ATN before deasserting ACK,
   \ in order to send a response message

   extmsgin-buf 1 + table-c@  ( message-code )	\ Decode the message
   case
      0 of  send-message-reject        endof   \ modify data pointer
      1 of  handle-synch-negotiation   endof   \ synchronous negotiation
      2 of  send-message-reject        endof   \ SCSI-1 extended identify
      3 of  handle-wide-negotiation    endof   \ wide negotiation
      ( default )  send-message-reject  swap       \ Who knows?
   endcase
;

\ Return values for EXECUTE-COMMAND, representing various hardware
\ error conditions (i.e. reasons why the SCSI transaction didn't
\ complete through the status phase)

ff constant selection-failed
fe constant fatal-error
fd constant bus-reset
fc constant timed-out

\ Figure out what to do when the SCRIPTS processor interrupts.
\ Flag is true if we are finished, false if the script should be restarted.
\ "result" is either "ok" (0), "selection-failed", or "fatal-error"
\ "scriptp" is the script offset at which the script should be restarted.

: handle-interrupts  ( -- scriptp false | result true )
   \ Determine the cause of the interrupt and return a unique error number.
   get-istat                                 ( status )

   begin  dup 8 =  while            \ Single-step interrupt
      drop
      .step
      restart
      wait-for-interrupt  get-istat
   repeat

   \ The most likely and important case is a script interrupt,
   \ so we handle it near the top
   dup 4 and  if
      drop
      dsps reg-l@   case                     ( )   \ Get script interrupt code
         ok           of  0 true         exit  endof  \ Success
         extended-msg of  handle-ext-msg exit  endof  \ Extended msg

         ( default ) .script-interrupt  error-reset  fatal-error true  exit
      endcase      
   then

   \ A phase mismatch can happen if we asked for more bytes of data than
   \ the target was willing to supply, for example with a variable-length
   \ tape record, an inquiry command, or a mode sense command.

   dup 08000 and  if    \ Phase Mismatch     ( status )
      drop
      dma-fifo-empty 0=  if  flush-dma-fifo  then  \ Flush FIFO if not empty
      switch-offset false exit            \ Restart to try and finish command
   then

   dup 40000 and  if    \ Selection Timeout  ( status )
      drop selection-failed true exit
   then

   dup 20 and  if       \ SCSI Bus Reset received
      show-status
      error-reset       \ abort-operation?
      -1 to offperiod   \ Cancel negotiated transfer parameters
      bus-reset true exit  \ Don't continue script; maybe retry at high level
   then

   dup 32f73 and  if    \ Fatal Error        ( status )
      ." Fatal SCSI error " .script-address
      show-status
      error-reset
      fatal-error true  exit
   then                                      ( status )

   \ Timeout (no interrupt status)
   dup 0=  if  drop timed-out true  exit  then    ( status )

   \ The only cases left are "arbitration complete" (04000), which is
   \ not interesting, and "reselected" (01000)
   ." Unexpected SCSI Interrupt:"  cr  show-status  fatal-error true
;

\ Start the script at the selection phase entry point, and continue
\ to handle interrupts until the transaction has either completed or
\ aborted with a fatal error.  "result" is 0 for successful completion,
\ otherwise it is a nonzero code denoting the reason for the abort.

: run-script  ( -- result )
   get-msecs timeout +  to deadline

   select-offset            ( scriptp )
   begin                    ( scriptp )
      start-script          ( )
      handle-interrupts     ( next-scriptp false | result true )
   until                    ( result )
;


\ Called when the driver is already open, and is being opened again
: reopen-hardware  ( -- okay? )
   -1 to offperiod      \ Force renegotiation

   my-args  begin  dup  while       \ Execute mode modifiers
      ascii , left-parse-string            ( rem$ first$ )
      my-self ['] $call-method  catch  if  ( rem$ x x x )
         ." Unknown argument" cr
         3drop 2drop false exit
      then                                 ( rem$ )
   repeat                                  ( rem$ )
   2drop

   true
;

\ Called when the driver is not already open
: open-hardware  ( -- flag )

   reopen-hardware  0=  if  false exit  then

[ifdef] hack
h# 33 scntl3 reg!  \ Hack
[then]

   " scsi-initiator-id" get-inherited-property 0=  if
      decode-int  ( addr len n )  nip nip  ( n )
   else
      7                 \ Assume initiator ID is 7 if not told otherwise
   then              ( initiator-id )
   to my-id

   map
   reset-chip
   init-table
   init-script

   \ should perform a quick "sanity check" selftest here,
   \ returning true iff the test succeeds.

   true
;

\ Called when an instance, but not the last instance, of the driver
\ is being closed
: reclose-hardware  ( -- )  ;

\ Called when the last instance of driver is being closed
: close-hardware  ( -- )  release-script release-table unmap  ;

external
: reset  ( -- )  map  reset-scsi-bus  ( chip-off )  unmap  ;
headers

\ Reset the SCSI bus when we are probed.

[ifdef] Tokenizing-FCode
\ Map using the probe address, because my-unit is not valid until later
my-address chip-offset +  60  map-sbus  to chip-base
reset-scsi-bus  chip-off  unmap
[then]


\ Disconnect doesn't buy us anything; we're single-tasking

create identify-msg
   80 c,		    \ Identify message, don't allow disconnect
   01 c, 02 c, 03 c, 01 c,  \ Wide negotiation

: set-lun  ( -- )
   scsi2?  if      \ For SCSI-2, Merge LUN into identify message
      identify-msg c@ 0f invert and his-lun or  identify-msg c!
   else            \ For SCSI-1, Merge LUN into byte 1 of the command block
      cmd-buf 1+ table-c@  h# 1f and  his-lun 5 lshift or  cmd-buf 1+ table-c!
   then
;

: prepare-command  ( cmd-adr cmd-len -- )
   \ Set the cmd length field in the script table to the current cmd-length
   cmd-buf over cmd-ptr itable!

   \ Copy in the command buffer
   cmd-buf cmd-ptr table-move

   set-lun	\ Affects either identify message or command buffer

   debug?  if
      ." Command: "  cmd-buf table +  cmd-ptr table + script-l@  cdump  cr
   then 
;

\ Encode the synchronous offset, synchronous transfer period,
\ synchronous and asynchronous transfer periods, wide (or not) mode,
\ and target number into one 32-bit number, as used by the SCRIPTS
\ "SELECT" command.

: make-config-code  ( target -- code )
   0 offperiod rot clock-factors  bljoin  
;

\ Setup the identify message and possible wide negotiation message,
\ establishing the chip configuration according to previously-negotiated
\ modes.
: prepare-message  ( -- )
   identify-msg
   offperiod -1 =  if       \ First time we've talked to this device
      5                     \ Offer wide mode after identify message

      \ Report our width as either 16 or 8 bits, depending on wide?
      wide?  if  1  else  0  then  identify-msg 4 + c!

      0 to offperiod        \ Assume asynchronous transfer for starters
      33 to clock-factors   \ Wide mode off, slow synchronous for starters
   else
      1                     \ Just identify
   then                                    ( msg-adr,len )
      
   \ Copy in the message buffer
   msgout-buf sendmsg-ptr table-move       ( )

   his-id make-config-code  device-ptr table-count!  \ Set the target ID

;
external

\ We assume that the data buffer is DMA-accessible

: execute-command  ( data-adr,len dir cmd-adr,len -- hwresult | statbyte 0 )
   prepare-command                                 ( data-adr,len dir )
   drop                                            ( data-adr,len )

   prepare-message                                 ( data-adr,len )

   reset-wait  \ Let prior reset operations finish ( data-adr,len )

   dup  if                                         ( data-adr,len )
      2dup  false  dma-map-in                      ( data-adr,len phys )
      2dup swap data-ptr table!                    ( data-adr,len phys )

      run-script                                   ( data-adr,len phys hwres)

      >r swap dma-map-out  r>                      ( hwresult )
   else                                            ( data-adr,len )
      2drop run-script                             ( hwresult )
   then                                            ( hwresult )

   ?dup  0=  if                                    ( hwresult | )
      stat-buf table-c@  false                     ( statbyte false )
   then                                            ( hwresult | statbyte 0 )
;

: selftest  ( -- 0 | error-code )
   \ perform reasonably extensive selftest here, displaying
   \ a message if the test fails, and returning an error code if the
   \ test fails or 0 if the test succeeds.
   0
;

: set-address  ( unit target -- )
   dup his-id <>  if
      \ Switching targets forces renegotiation of transfer parameters
[ifdef] FastModes
      -1 to offperiod
[else]
      \ Some Quantum drives do bad things if you offer them wide mode; they
      \ reject the message, disconnect, and won't talk to you until you
      \ reselect them.
      0 to offperiod
      33 to clock-factors   \ Wide mode off, slow synchronous for starters
[then]
   then
   to his-id  to his-lun
;

\ Words to force the driver to use various modes other than the default
\ "best case" modes, which are:
\	scsi2, fast, wide, parity, notrace
\ These words are used as arguments when the device is opened,
\   for example:  /sbus/Antares,afws:scsi1,noparity/sd@2,0
\ These "forced suboptimal" modes may be useful for supporting
\ certain older devices, or for handling unforseen incompatibilities.

: debug-on  ( -- )  true  to debug?  ;
: slow      ( -- )  false to fast?   ;
: sync      ( -- )  true  to sync?   ;
: scsi1     ( -- )  false to scsi2?  ;
: noparity  ( -- )  false to parity? ;
: async     ( -- )
   false to sync?
   ['] send-message-reject to handle-synch-negotiation
;
: narrow    ( -- )
   false to wide?
   ['] send-message-reject to handle-wide-negotiation
;

headers
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
