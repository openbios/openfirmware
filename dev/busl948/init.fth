\ See license at end of file
purpose: Initialization code for Bus Logic 948/958  SCSI Cards

\ Bus Logic SCSI Driver
\
\ This driver is for the following Bus Logic SCSI Adapter models:
\	BT-948
\	BT-958

\ Known Problems/Issues:
\	None so far...

\ Description
\
\ These controllers use a BA80C32 controller chip. A custom PCI-SCSI
\ chip. The chip can be accessed in one of two modes, PIO or DMA. There
\ are only a total of 5 registers that one needs to deal with for PIO.
\ These registers are:
\
\	Register	Address			Access
\
\	Control		pci-base + 0		WO
\	Status		pci-base + 0		RO
\	Command/Param	pci-base + 1		WO
\	Data In Reg	pci-base + 1		RO
\	Interrupt Reg	pci-base + 1		RO
\
\ As a far as the command register goes, here are the legal commands:

\	Command		Meaning
\
\	00		Test CMDC Interrupt
\	01		Initialize Mailbox
\	02		Start Mailbox Command
\	03		Start BIOS Command
\	04		Inquire Board ID
\	05		Enable OMBR Interrupt
\	06		Set SCSI Selection Timeout
\	07		Set Time On Bus
\	08		Set Time Off Bus
\	09		Set Bus Transfer Rate
\	0a		Inquire Installed Devices
\	0b		Inquire Configuration
\	0d		Inquire Setup Information
\	1a		Write Adapter Local RAM
\	1b		Read Adapter Local RAM
\	1c		Write Bus Master Chip FIFO
\	1d		Read Bu Master Chip FIFO
\	1f		Echo Data Byte
\	20		Host Adapter Diagnostic
\	21		Set Adapter Options
\	23		Inquire Installed Devices For Target ID 8-15
\	81		32-Bit Mode Initialize Mailbox
\	8d		Inquire Extended Setup Information
\	96		Enable Wide Mode CCB
\

hex
headers

" scsi" device-name
" scsi-2" device-type
" scsi" encode-string " name" property
" BusLogic" encode-string " model" property

false instance value debug?	\ Trace SCSI Phases.
true  instance value scsi2?	\ Use SCSI-2 protocol with full messaging.
true  instance value parity?	\ Check SCSI bus parity.
true  instance value wide?	\ Use wide mode if target supports it.
true  instance value sync?	\ Use synchronous mode if target supports it.
true  instance value fast?	\ Use fast mode if target supports it.

\ Now we encode the reg property.

: +int  ( adr len i -- adr len' )
   encode-int encode+ 
;

\ PCI base
0 0  my-space               encode-phys         0 +int           0 +int 
\ Main register set
0 0  my-space h# 100.0010 + encode-phys encode+ 0 +int  /scsi-regs +int
\ Memory Mapped IO
0 0  my-space h# 100.0014 + encode-phys encode+ 0 +int  h# 1000 +int

" no-rom" get-my-property 0=  if
   2drop
else
   0 0 my-space h# 100.0030 + encode-phys encode+ 0 +int h# 4000 +int	\ ROM
then

" reg" property

\ Now we create two methods for mapping in and out 
\ the controller's registers.

: map-scsi-regs  ( -- ) 		\ Map-in and enable IO access.
   \ h# 0100.0000 means relocatable I/O space
   0 0 my-space h# 0100.0010 +  /scsi-regs  " map-in" $call-parent to scsi-base
   \ Enable io & DMA space response.
   4 c-l@ 5 or 4 c-l!
;

: unmap-scsi-regs  ( -- )		\ Disable I/O space response.
   scsi-base  /scsi-regs  " map-out"  $call-parent
   -1 to scsi-base
   4 c-l@ 5 invert and 4 c-l!
;

\ Now for the main driver code. The following methods are the ones
\ used during runtime to talk to the controller.

: selection-timeout  ( -- )
   10 alloc-mem >r
   1  r@ c!
   0  r@ 1 + c!
   h# ff  r@ 2 + c!
   h# ff r@ 3 + c!
   r@ 4	6		( adr len 6 )
   cmd-param!		( )
   r> 10 free-mem
;

: reset-board  ( -- )			\ Resets the controller.
   soft-reset
   d# 100 ms				\ Wait a bit.
   begin
      ha-ready?
   until
   begin
      reset-int
      int-reg@ 0=
   until
   selection-timeout
;

: get-phys-addr  ( v len -- dma )	\ Returns the physical address
   false dma-map-in			\ The false means non-cacheable.
;

-1 instance value his-id		\ SCSI target.
-1 instance value his-lun		\ SCSI LUN.

external

: set-address  ( unit target -- )	\ Sets the target and LUN.
   to his-id  to his-lun  
;

headers
 
-1 value pccb

\ h# 1 value /sense
\ -1 value psense

: allocate-ccb  ( -- )		\ Allocates a block of memory for the ccb.
   /ccb dma-alloc to pccb
;

: release-ccb  ( -- )		\ Releases the ccb memory.
  pccb /ccb free-mem
   -1 to pccb
;

-1 value pmailbox

: allocate-mailbox  ( -- )	\ Get a mailbox pointer
   /mailbox dma-alloc to pmailbox
   pmailbox /mailbox erase
;

: release-mailbox  ( -- )
   pmailbox /mailbox free-mem
;

create identify-msg
   80 c,			\ Identify message, don't allow disconnect

: set-lun  ( -- )
   scsi2?  if      \ For SCSI-2, Merge LUN into identify message
      identify-msg c@ 0f invert and his-lun or  identify-msg c!
   else            \ For SCSI-1, Merge LUN into byte 1 of the command block
      his-lun pccb >lun/tag c!
   then
;

headers

: ccb-l! ( l adr -- )                   \ This word takes the input l value
   >r           ( l )                   \ and writes it properly to the 
   lwsplit      ( lo hi )               \ controler's registers accounting
   wbsplit      ( lo hbl hbh )          \ for the byte lane swapping that
   swap         ( lo hbh hbl )          \ occurs.
   rot          ( hbh hbl lo )
   wbsplit      ( hbh hbl lbl lbh )
   swap         ( hbh hbl lbh lbl )
   r@ 0 + rb!   ( hbh hbl lbh )
   r@ 1 + rb!   ( hbh hbl )
   r@ 2 + rb!   ( hbh )
   r> 3 + rb!   ( - )
;

: build-cdb  ( data-adr data-len data-dir cmd-adr cmd-len -- )

   \ This word builds the cp packet that is sent to the controller.

   pccb /ccb erase				\ First, lets flush the thing.
   his-id pccb >target c!			\ Set the SCSI ID.

   set-lun					\ Pumps the LUN in accordingly.

   his-lun			( ... lun )
   wide-mode  if
      h# 3f and			( ... lun )	\ Wide mode
   else
      7 and			( ... lun )	\ Narrow mode
   then
   pccb >lun/tag c!		( ... )

   \ Set cdb length
   dup pccb >cdb-len c!		( data-adr data-len data-dir cmd-adr cmd-len )

   \ Now copy the cdb block into ccb
   pccb >cdb swap move		( data-adr data-len data-dir )

   \ Data direction auto-select by command
   drop 0 pccb >ccb-cntl c!	( date-adr data-len )

   pccb >data-len ccb-l!	( data-adr )

   pccb >data-ptr ccb-l!	(  )

   \ We do not use auto-sense in this driver
   0 pccb >sense-ptr ccb-l!	(  )
   \ Disables auto-sense
   1 pccb >sen-len c!		(  )
;

: b-l! ( l adr -- )				\ Saves l  a byte at a time
   >r			( l )
   lbsplit		( l.lo l.1 l.2 lo.h )
   r@ 3 + c!
   r@ 2 + c!
   r@ 1 + c!
   r> c!
;

: setup-mailbox  ( -- )
   pmailbox 0 get-phys-addr	( adr )
   lbsplit 			( lo hi )
   10 alloc-mem >r		( lo b b hi )	\ Get some temp space
   1 r@ c!			( lo b b hi )	\ Declare 1 mailbox
   r@ 4 + c!			( lo b b )	\ Write msb
   r@ 3 + c!			( lo b )
   r@ 2 + c!			( lo )
   r@ 1 + c!			( )		\ Write lsb
   r@ 5 h# 81			( adr len  81 )
   cmd-param!					\ Punch the mailbox base
   r> 10 free-mem				\ Release the temp space
   begin
      cs-reg@ 20 and 0=
   until
;

: (send-cdb)  ( -- )			\ Send the cp to the chip.
   ha-ready? 0=  if
\      ." send-cdb error, HA not ready!" cr
   then
   pccb	0			( adr 0 )
   get-phys-addr		( phys )
   0 pmailbox >in1-sdstat c!		\ Init SD status byte to 0
   0 pmailbox >in1-btstat c!		\ Init HA status byte to 0
   pmailbox >out1-adr b-l!		\ Write the cdb pointer to the mailbox
   1 pmailbox >out1-ac  c!		\ Set mailbox active flag
   2 cmd-p!				\ Start mailbox command 
					\ ( cmd 2 does not affect interupts)
;

: send-cdb  ( -- )

   begin

      (send-cdb)				\ Send the ccb

      begin					\ Wait until interupted
         int-reg@		( int )
         h# 80 and 0<>		( )
      until

      int-reg@			( int )
      h# 81  =  if		( )		\ This is what we want
          true			( true )
      else
         cs-reg@ h# 20 and 0<>  if
            release-mailbox
            allocate-mailbox
            reset-int
            setup-mailbox
         else
            int-reg@ h# 84 =  if
               true				\ Check condition
               pmailbox >in1-sdstat c@ . 
               pmailbox >in1-btstat c@ . 
               hard-reset
               ha-ready? . cr
               reset-int
               setup-mailbox
            else
               ." unknown failure!" cr
               ." cs-reg: " cs-reg@ . cr
               ." int-reg: " int-reg@ . cr
            then
         then
         false			( false )
      then
      reset-int
   until
;

: (exec)  ( dma-adr dma-len dir cmd-adr cmd-len -- )

   \ (exec) builds, then sends the cdb packet. It returns after 
   \ the DMA succeeds, or times-out, whichever occurs first.

   build-cdb
   send-cdb

   get-msecs cmd-start !
   begin
      get-msecs cmd-start @ -  cmd-wait @ > if
         reset-board true
         setup-mailbox
         exit
      then
      pmailbox >in1-cc c@ 0<> 
   until

;

external

: execute-command ( dma-adr dma-len dir cmd-adr cmd-len -- hwresult | status 0 )

   \ This is the main word that this driver needs to supply. All of the
   \ work to this point was just to get this word. This word is called
   \ by the high level scsi routines (hacom.fth) to do the dirty work
   \ of sending and receiving data to or from the SCSI controller.

   >r >r >r		( dma-adr dma-len )	\ Hide away dir cmd-adr/len
   dup if		( dma-adr dma-len )

      \ Non 0 data length, have to map it in.
      2dup false dma-map-in	( dma-adr dma-len dma )
      2dup swap r> r> r>    ( dma-adr dma-len dma dma,len dir cmd-adr cmd-len )
      (exec)		    ( dma-adr dma-len dma )
      swap dma-map-out	    ( - )
   else			    ( dma-adr dma-len )
      r> r> r> (exec)	    ( - )
   then

   pmailbox >in1-cc c@ 1 =  if
      0 0 			( 0 0 )		\ The ideal answer
   else
      pmailbox >in1-sdstat c@ dup 0<>  if
         0			( status 0 )	\ Check or retry
      else
         drop pmailbox >in1-btstat c@ ( hwerror )	\ Big BooBoo
      then
   then

   0 pmailbox >in1-cc c!			\ Blow off flag
;

headers

: init-board ( -- bad? )	\ Initializes the board
   ha-ready? 0=  if
      hard-reset
   then
   int-reg@ 0<>  if		\ Interrupt is still there, 
      reset-int			\ Try to clear it.
   then
   int-reg@ 0<>  if		\ Still there, try something more drastic
      hard-reset
   then
   int-reg@ 0=  if
      ha-ready?  0=
   else
      true
   then
;

: close-hardware  ( -- )	\ Cleans up buffers and mappings
   release-ccb
   unmap-scsi-regs
;

: open-hardware  ( -- okay? )			\ Opens the device
   map-scsi-regs
   init-board if
      init-board if
         close-hardware false exit
      then
   then
   h# e get-extended-info 1 and 0<>  if	\ See if we need "wide" property
      set-wide-mode			\ Use wide-mode CCBs
      " wide" get-my-property  if	\ It may already be there
         0 encode-int " wide" property	\ Nope, add it
      else
         2drop				\ Yep, don't add it again
      then
   then
   allocate-mailbox
   setup-mailbox
   allocate-ccb
   selection-timeout
   true
;

: reopen-hardware  ( -- flag )
   true
;

: reclose-hardware  ( -- )
;

external

h# 14 constant bus-reset

: reset-scsi-bus  ( -- )		\ Forces SCSI bus reset
   10 cs-reg! 
;

h# 8000 constant my-max
: max-transfer  ( -- n )
   " max-transfer" ['] $call-parent catch if
      2drop my-max
   then
   my-max min
;

headers

: debug-on  ( -- )  true  to debug?  ;
: narrow    ( -- )  false to wide?   ;
: slow      ( -- )  false to fast?   ;
: async     ( -- )  false to sync?   ;
: scsi1     ( -- )  false to scsi2?  ;
: noparity  ( -- )  false to parity? ;


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
