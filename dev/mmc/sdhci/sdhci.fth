\ See license at end of file
\ SDHCI driver

hex

" sd" device-name

" mmc" device-type

\ Register offsets from the adapter's base address

0 instance value ioaddr
h# 100 constant /regs	\ Total size of adapter's register bank

: sdb@  ( offset -- b )  ioaddr +  rb@  ;
: sdb!  ( b offset -- )  ioaddr +  rb!  ;
: sdw@  ( offset -- w )  ioaddr +  rw@  ;
: sdw!  ( w offset -- )  ioaddr +  rw!  ;
: sdl@  ( offset -- l )  ioaddr +  rl@  ;
: sdl!  ( l offset -- )  ioaddr +  rl!  ;

: my-w@  ( offset -- w )  my-space +  " config-w@" $call-parent  ;
: my-w!  ( w offset -- )  my-space +  " config-w!" $call-parent  ;
: unmap-regs  ( -- )
   4 my-w@  6 invert and  4 my-w!
   ioaddr /regs " map-out" $call-parent
;
: map-regs  ( -- )
   0 0  my-space h# 0200.0014 +  /regs " map-in" $call-parent  to ioaddr
   4 my-w@  6 or  4 my-w!
;

: le-l!  ( l adr -- )
   >r lbsplit  r@ 3 + c!  r@ 2+ c!  r@ 1+ c!  r> c!
;
: le-l@  ( adr -- l )
   >r  r@ c@  r@ 1+ c@  r@ 2+ c@  r> 3 + c@  bljoin
;

: unmap-regs  ( -- )
   4 my-w@  7 invert and  4 my-w!            \ Disable
   ioaddr /regs " map-out" $call-parent
;
: map-regs  ( -- )
   \ 0 0  my-space h# 0200.0010 +  /regs " map-in" $call-parent  to ioaddr
   0 0  my-space h# 0100.0018 +  /regs " map-in" $call-parent  to ioaddr
   4 my-w@  3 or  4 my-w!       \ Enable memory and io
;


\ PCI registers

h# 00 constant pci-ifpio
h# 01 constant pci-ifdma
h# 02 constant pci-ifvendor

h# 40 /* 8 bits */ constant pci-slot-info
: pci-slot-info-slots  ( x -- n )  4 rshift 7 and  ;
h# 07 constant pci-slot-info-first-bar-mask

\ Controller registers

h# 00 constant dma-address  \ L

h# 04 constant block-size   \ W
: make-blksz  ( blksz dma -- n )
   7 and d# 12 lshift  swap h# fff and or
;

h# 06 constant block-count   \ W

h# 08 constant argument      \ L

h# 0C constant transfer-mode \ W
h# 01 constant trns-dma
h# 02 constant trns-blk-cnt-en
h# 04 constant trns-acmd12
h# 10 constant trns-read
h# 20 constant trns-multi

h# 0E constant command        \ W
h# 03 constant cmd-resp-mask
h# 08 constant cmd-crc
h# 10 constant cmd-index
h# 20 constant cmd-data

h# 00 constant cmd-resp-none
h# 01 constant cmd-resp-long
h# 02 constant cmd-resp-short
h# 03 constant cmd-resp-short-busy

: make-cmd  ( f c -- )  bwjoin  ;

h# 10 constant response

h# 20 constant buffer

h# 24 constant present-state     \ L
h# 00000001 constant cmd-inhibit
h# 00000002 constant data-inhibit
h# 00000100 constant doing-write
h# 00000200 constant doing-read
h# 00000400 constant space-available
h# 00000800 constant data-available
h# 00010000 constant card-present
h# 00080000 constant write-protect

h# 28 constant host-control  \ B
h# 01 constant ctrl-led
h# 02 constant ctrl-4bitbus

h# 29 constant power-control \ B
h# 01 constant power-on
h# 0A constant power-180
h# 0C constant power-300
h# 0E constant power-330

h# 2A constant block-gap-control \ B

h# 2B constant walk-up-control   \ B

h# 2C constant clock-control     \ W
8 constant divider-shift
h# 0004 constant clock-card-en
h# 0002 constant clock-int-stable
h# 0001 constant clock-int-en

h# 2E constant timeout-control   \ B

h# 2F constant software-reset    \ B
h# 01 constant reset-all
h# 02 constant reset-cmd
h# 04 constant reset-data

h# 30 constant int-status        \ L
h# 34 constant int-enable        \ L
h# 38 constant signal-enable     \ L

h# 00000001 constant int-response
h# 00000002 constant int-data-end
h# 00000008 constant int-dma-end
h# 00000010 constant int-space-avail
h# 00000020 constant int-data-avail
h# 00000040 constant int-card-insert
h# 00000080 constant int-card-remove
h# 00000100 constant int-card-int
h# 00010000 constant int-timeout
h# 00020000 constant int-crc
h# 00040000 constant int-end-bit
h# 00080000 constant int-index
h# 00100000 constant int-data-timeout
h# 00200000 constant int-data-crc
h# 00400000 constant int-data-end-bit
h# 00800000 constant int-bus-power
h# 01000000 constant int-acmd12err

h# 00007FFF constant int-normal-mask
h# FFFF8000 constant int-error-mask

0
int-response or
int-timeout or
int-crc or
int-end-bit or
int-index or
constant int-cmd-mask

int-data-end
int-dma-end or
int-data-avail or
int-space-avail or
int-data-timeout or
int-data-crc or
int-data-end-bit or
constant int-data-mask

h# 3C constant acmd12-err  \ W

\ 3E-3F reserved

h#       40 constant capabilities
h# 0000003F constant timeout-clk-mask

0 constant timeout-clk-shift
h# 00000080 constant timeout-clk-unit

8 constant clock-base-shift
h# 00003F00 constant clock-base-mask

16 constant max-block-shift
h# 00030000 constant max-block-mask

h# 00400000 constant can-do-dma
h# 01000000 constant can-vdd-330
h# 02000000 constant can-vdd-300
h# 04000000 constant can-vdd-180

\ 44-47 reserved for more caps

h# 48 constant max-current       \ L

\ 4C-4F reserved for more max current

\ 50-FB reserved

h#   FC constant slot-int-status \ W

h#   FE constant host-version    \ W
h# FF00 constant vendor-ver-mask
      8 constant vendor-ver-shift
h# 00FF constant spec-ver-mask
      0 constant spec-ver-shift

0 instance value clock    \ Current clock in MHz
0 instance value max-clk  \ Controller's max clock in MHz
0 instance value power    \ Current power setting
0 instance value blksz    \ Block size
0 instance value max-block  \ Controller's max block size
0 instance value buffer
0 instance value timeout_clk
0 instance value size
0 instance value use-dma?
0 instance value requested-blocks

0 value debug-nodma?
0 value debug-forcedma?
0 value debug-quirks?

\ Low level functions

: reset  ( mask -- )
   dup software-reset rb!                ( mask )
   reset-all and  if  0 to clock  then   ( mask )
   d# 100 ms                             ( mask )
   d# 100  0  do                         ( mask )
      dup  software-reset rb@  and 0=  if  drop unloop exit  then
      1 ms
   loop
   true abort" sdhci reset didn't complete"
;

0
int_bus_power   or   int_data_end_bit or
int_data_crc    or   int_data_timeout or  int_index or
int_end_bit     or   int_crc or           int_timeout or
int_card_remove or   int_card_insert or
int_data_avail  or   int_space_avail or
int_dma_end     or   int_data_end or      int_response or
constant init-intmask 

: init  ( -- )
   reset-all reset
   init-intmask int-enable    sdl!
   init-intmask signal-enable sdl!
;

: led-on   ( -- )  host-control sdb@  ctrl-led or  host-control sdb!  ;
: led-off  ( -- )  host-control sdb@  ctrl-led invert and  host-control sdb!  ;

\ Core functions

\ Len must be a multiple of 4, adr must be longword aligned
: read-pio  ( adr len -- )
   bounds  ?do
      begin  present-state sdl@ data-available and  until
      i blksize bounds  ?do
         \ XXX this assumes that the host is little-endian
         buffer sdl@  i l!
      /l +loop
   blksize +loop
;

: write-pio  ( adr len -- )
   bounds  ?do
      begin  present-state sdl@ space-available and  until
      i blksize bounds  ?do
          \ XXX this assumes that the host is little-endian
          i l@  buffer sdl!
      /l +loop
   blksize +loop
;

: timeout>count  ( timeout-clks timeout-ns -- count )
   d# 1000 /  swap clock / +   ( target-timeout )

  \ Figure out needed cycles.
  \ We do this in steps in order to fit inside a 32 bit int.
  \ The first step is the minimum timeout, which will have a
  \ minimum resolution of 6 bits:
  \ (1) 2^13*1000 > 2^22,
  \ (2) host->timeout_clk < 2^16
  \     =>
  \     (1) / (2) > 2^6

  1 d# 13 lshift  d# 1000 *  timeout_clk /   ( target current )

  h# e  0  do     ( target current )
     2dup >=  if  2drop i unloop exit  then  ( target current )
     2*                                      ( target current' )
  loop                                       ( target current' )
  2drop  h# e
;

\ blksz * blocks must be <= 524288
\ blksz must be < host_max-block
\ blocks must be <= 65535
: dma-prepare-data  ( blocks blksz timeout_clks timeout_ns -- )
   timeout>count timeout-control sdb!
\	int count;
\	count = pci_map_sg(host->chip->pdev, data->sg, data->sg_len,
\		(data->flags & MMC_DATA_READ)?PCI_DMA_FROMDEVICE:PCI_DMA_TODEVICE);
\	BUG_ON(count != 1);
\	writel(sg_dma_address(data->sg), DMA_ADDRESS);

\  ( count ) dma-address sdl!
   \ We do not handle DMA boundaries, so set it to max - 512 KiB
   ( blksz ) 7 make-blksz  block-size sdw!
   ( blocks )  block-count sdw!
;

: pio-prepare-data  ( blocks blksz timeout_clks timeout_ns -- )
   timeout>count timeout-control sdb!

   2dup * to size

   \ We do not handle DMA boundaries, so set it to max - 512 KiB
   ( blksz ) 7 make-blksz  block-size sdw!
   ( blocks )  block-count sdw!
;

: set-transfer-mode  ( blocks direction-in? -- )
   trns-blk-cnt-en                    ( blocks direction-in? mode )
   swap  if  trns-multi or  then      ( blocks mode' )
   swap  1 >  if  trns-read or  then  ( mode' )
   use-dma?   if  trns-dma  or  then  ( mode' )
   transfer-mode sdw!
;

: finish-data  ( -- )
\   use-dma?  if  dir-in?  dma-unmap  then

   \ Controller doesn't count down when in single block mode.

   requested-blocks dup  1 <>  if
      \ Should report an error if the residual #blocks is nonzero
      block-count sdw@ -
   then                  ( actual )
   requested-blocksz  *  ( bytes-transferred )

   need-stop?  \ data->stop

   data->stop  if
      \ Reset controller upon error conditions
      error?  if  reset-cmd reset  reset-data reset  then 
      send_command(host, data->stop);
   else
      finish_tasklet
   then
;

: wait-cmd-ready  ( mask -- )  \ some combination of cmd-inhibit and data-inhibit
\	mask = CMD_INHIBIT;
\	if ((cmd->data != NULL) || (cmd->flags & MMC_RSP_BUSY))
\		mask |= DATA_INHIBIT;
\
\	\ We shouldn't wait for data inhibit for stop commands, even
\	\ though they might use busy signaling
\	if (host->mrq->data && (cmd == host->mrq->data->stop))
\		mask &= ~DATA_INHIBIT;
    
   d# 10 0  do   ( mask )
      dup present-state sdl@  and 0=  if  drop unloop exit  then
      1 ms       ( mask )
   loop          ( mask )
   drop          ( )
   true abort" SDHCI controller inhibited"
;

opcode flags arg blocks blksz timeout_clks timeout_ns 
: send-command ( struct mmc_command *cmd -- )
	int flags;

	host->cmd = cmd;

	prepare_data(cmd->data);
	writel(cmd->arg, ARGUMENT);
	set_transfer_mode(cmd->data);

	if ((cmd->flags & MMC_RSP_136) && (cmd->flags & MMC_RSP_BUSY)) {
		printk(KERN_ERR "%s: Unsupported response type! ");
		cmd->error = MMC_ERR_INVALID;
		tasklet_schedule(&host->finish_tasklet);
		return;
	}

	if (!(cmd->flags & MMC_RSP_PRESENT))	flags = CMD_RESP_NONE;
	else if (cmd->flags & MMC_RSP_136)	flags = CMD_RESP_LONG;
	else if (cmd->flags & MMC_RSP_BUSY)	flags = CMD_RESP_SHORT_BUSY;
	else                    		flags = CMD_RESP_SHORT;

	if (cmd->flags & MMC_RSP_CRC)   flags |= CMD_CRC;
	if (cmd->flags & MMC_RSP_OPCODE)flags |= CMD_INDEX;
	if (cmd->data)  		flags |= CMD_DATA;

	sdw!(MAKE_CMD(cmd->opcode, flags), COMMAND);
}

: finish-command  ( -- )

	if (host->cmd->flags & MMC_RSP_PRESENT) {
		if (host->cmd->flags & MMC_RSP_136) {
			\ CRC is stripped so we need to do some shifting.
			for (i = 0;i < 4;i++) {
				host->cmd->resp[i] = readl(host->ioaddr +
					RESPONSE + (3-i)*4) << 8;
				if (i != 3)
					host->cmd->resp[i] |=
						readb(host->ioaddr +
						RESPONSE + (3-i)*4-1);
			}
		} else {
			host->cmd->resp[0] = readl(RESPONSE);
		}
	}

	host->cmd->error = MMC_ERR_NONE;

	if (host->cmd->data)
		host->data = host->cmd->data;
   else
      finish_tasklet
   then
;

: clock>divisor  ( clock -- div )
   1         ( clock div )
   begin     ( clock div )
      dup d# 256 =  if  nip exit  then  ( clock div )
      2dup  max-clk swap /              ( clock div clock max/div )
      >=  if  u2/ nip  exit  then       ( clock div )
      2*
   again
;
: wait-clock-stable  ( -- clk )
   d# 10 0  do   \ Wait max 10 ms
      clock-control sdw@              ( clk )
      dup clock-int-stable and  if  unloop exit  then  ( clk )
      drop                            ( )
      1 ms
   loop
   true abort" SDHCI clock never stabilized"
;
: set-clock  ( clock -- )
   dup clock =  if  drop exit  then      ( clock )
   0 clock-control sdw!
   dup 0=  if  to clock  exit  then      ( clock )

   clock>divisior                        ( div )

   divider-shift lshift  clock-int-en or  dup clock-control sdw!  ( )

   wait-clock-stable                     ( clk )

   clock-card-en or  clock-control sdw!  ( )

   to clock
;

: set-power  ( power -- )  \ 0, pwr-180, pwr-300, or pwr-330
   dup power =  if  drop exit  then
   dup to power             ( power )
   0 power-control sdb!     ( power )
   ?dup  if  power-on or  power-control sdb!  then
;

\ MMC callbacks

: request ( cmd... -- )
   led-on
   send-command
;

: set-ios  ( 4bit? power clock -- )
   \ Reset the chip on each power off.
   \ Should clear out any weird states.
   over  if  0 signal-enable sdl!  init  then  ( 4bit? power clock )
   set-clock                                   ( 4bit? power )
   set-power                                   ( 4bit? )

   host-control sdb@  ctrl-4bitbus             ( 4bit? hc-reg bit )
   rot if  or  else  invert and  then          ( hc-reg' )
   host-control sdb!                           ( )
;

: ro?  ( -- flag )
   present-state sdl@ write-protect and  0=
;

: card-present?  ( -- flag )
   present-state sdl@  card-present and  0<>
;

0 value clock-quirk?
: reset-controller  ( -- )
   \ Some controllers need this kick or reset won't work here
   clock-quirk?  if  clock  0 to clock  set-clock  then

   \ Spec says we should do both at the same time, but Ricoh
   \ controllers do not like that.
   reset-cmd reset
   reset-data reset

   led-off
;

: ack-interrupt  ( intmask bit -- intmask' )
   dup int-status sdl!
   invert and
;

\ Interrupt handling

0 instance value cmd-done?
0 instance value int-error-bits

int-timeout int-crc or int-end-bit or int-index or  constant cmd-int-error-bits

: cmd-irq  ( intmask -- intmask' )
   doing-cmd?  0=  if
      ." SDHCI: Command interrupt with no command in progress" cr
   then

   dup int-response and  if
      finish-command
      int-response ack-interrupt  \ XXX is this right?
      exit
   then

   dup cmd-int-error-bits and  if
      dup cmd-int-error-bits and  dup to int-error-bits  ack-interrupt
      finsh-tasklet
   then
;

int-data-timeout int-data-crc or  int-data-end-bit or  constant data-int-error-bits

: data-irq  ( intmask -- intmask' )
   doing-data?  0=  if
      \ A data end interrupt is sent with the response for the stop command.
      dup int-data-end and  0=  if
         ." SDHCI: Data interrupt with no data operation in progress" cr
      then
      exit
   then

   dup data-int-error-bits  and  if
      dup data-int-error-bits  and  dup to int-error-bits  ack-interrupt
      finish-data
      exit
   then

   dup int-data-avail int-space-avail or and  if
      transfer-pio
   then

   dup int-data-end  and  if
      finish-data
   then      
;

: wait-done  ( -- )
   int-status sdl@    ( intmask )

   dup  int-card-insert  and  if
      ." Card inserted" cr
      int-card-insert ack-interrupt
   then

   dup  int-card-remove  and  if
      ." Card removed" cr
      int-card-remove ack-interrupt
   then

   dup int-cmd-mask  and   if
      ...
      int-cmd-mask ack-interrupt
   then

   dup int-data-mask  and   if
      ...
      int-data-mask ack-interrupt
   then

   dup int-bus-power and   if
      ." SD device is using too much power" cr
      int-bus-power ack-interrupt
   then

   ( intmask )
   ." Unexpected interrupt bits " .x  cr
;

\ Device probing/removal

: open  ( -- flag )
   map-regs
   reset-all reset

   capabilities	sdl@   ( capabilities )

   false to use-dma?
   try-dma?  if        ( capabilities )
      dup can-do-dma and  if    ( capabilities )
         true to use-dma?
         \ XXX also check low byte of class config register to ensure dma IF present
         \ Turn on bus master bit in enable register
         4 my-w@  4 or  4 my-w!
         allocate-dma
      else
         false to use-dma?
         ." No DMA support in sdhci" cr
      then
   then

   dup clock-base-mask and  clock-base-shift rshift  ( capabilities mhz )
   d# 1000000 *  to max-clk                          ( capabilities )

   dup timeout-clock-mask and  timeout-clock-shift rshift  ( capabilities clks )
   over timeout-clk-unit and  if  d# 1000 *  then  to timeout-clk  ( capabilities )

   dup max-block-mask and  max-block-shift rshift    ( capabilities max-blk-cnt )
   d# 512 swap lshift  to max-block                  ( capabilities )

   \ XXX need to do something with the list of supported voltages
   drop                                              ( )

   \ DMA transfer is limited to 512KiB.

   init

   true
;

: close  ( -- )
   use-dma?  if  free-dma  then
   unmap-regs
   0 4 my-w!
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
