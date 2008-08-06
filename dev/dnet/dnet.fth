purpose: Ethenet Driver for Lattice Ethernet device (dnet)
\ See license at end of file

hex
headers

: copyright ( -- )
   ." Copyright (c) 2008 Dave Srl. All Rights Reserved." cr
;

\ Register offsets from the adapter’s base address

\ TODO remove the following
0 constant control \ 1 byte W/O - writing one bits causes things to happen
2 constant unicast-addr \ 6 bytes R/W - Ethernet address for reception
8 constant xmit-status \ 1 byte - 0 => busy 1 => okay else => error
9 constant xmit-fifo \ 1 byte - write repetitively to setup packet
a constant xmit-len \ 16 bits - length of packet to send
c constant rcv-rdy \ 1 byte - count of waiting packets
d constant rcv-fifo \ 1 byte - read repetitively to remove first packet
e constant rcv-len \ 16 bits
10 constant local-addr \ 6 bytes R/O - Factory-assigned Ethernet address
\ until here


\ dnet register definition

0 constant rx-len-fifo
4 constant rx-data-fifo
8 constant tx-len-fifo
c constant rx-data-fifo

100 constant verid
104 constant intr-src
108 constant intr-enb
10c constant rx-status
110 constant tx-status
114 constant rx-frames-cnt
118 constant tx-frames-cnt
11c constant rx-fifo-th
120 constant tx-fifo-th
124 constant sys-ctl
128 constant pause-tmr

200 constant macreg-data
204 constant macreg-addr
1 d# 31 << constant macreg-write

\ TODO: dnet rx & tx statistics counter registers


\ macreg register definition
0 constant macreg-mode
2 constant macreg-rxtx-mode
4 constant macreg-max_pkt_size
8 constant macreg-igp
a constant macreg-mac_addr_0
c constant macreg-mac_addr_1
e constant macreg-mac_addr_2
12 constant macreg-tx_rx_sts
14 constant macreg-gmii_mng_ctl
16 constant macreg-gmii_mng_dat

100000 constant /regs \ Total size of adapter’s register bank
10000000 constant /real-regs \ Total size of adapter’s register bank

: map-in ( addr space size -- virt ) " map-in" $call-parent ;

: map-out ( virt size -- ) " map-out" $call-parent ;

: my-w@ ( offset -- w ) my-space + " config-w@" $call-parent ;
: my-w! ( w offset -- ) my-space + " config-w!" $call-parent ;

" ethernet" device-name
" Lattice,tri-speed-eth" encode-string " compatible" property
" network" device-type

\ Some of Apple’s Open Firmware implementations have a bug in their map-in method. The
\ bug causes phys.lo and phys.mid to be treated as absolute addresses rather than
\ offsets even when working with relocatable addresses.
\ To overcome this bug, the Open Firmware Working Group in conjunction with Apple has
\ adopted a workaround that is keyed to the presence or absence of the add-range method
\ in the PCI node. If the add-range method is present in an Apple ROM, the map-in
\ method is broken. If the add-range property is absent, the map-in method behaves
\ correctly.
\ The following methods allow the FCode driver to accomodate both broken and working
\ map-in methods.
: map-in-broken? ( -- flag )
   \ Look for the method that is present when the bug is present
   " add-range" my-parent ihandle>phandle ( adr len phandle )
   find-method dup if nip then ( flag ) \ Discard xt if present
;

\ Return phys.lo and phys.mid of the address assigned to the PCI base address
\ register indicated by phys.hi .
: get-base-address ( phys.hi -- phys.lo phys.mid phys.hi )
   " assigned-addresses" get-my-property if ( phys.hi )
   ." No address property found!" cr
   0 0 rot exit \ Error exit
   then ( phys.hi adr len )
   rot >r ( adr len ) ( r: phys.hi )
   \ Found assigned-addresses, get address
   begin dup while ( adr len' ) \ Loop over entries
      decode-phys ( adr len' phys.lo phys.mid phys.hi )
      h# ff and r@ h# ff and = if ( adr len' phys.lo phys.mid ) \ This one?
         2swap 2drop ( phys.lo phys.mid ) \ This is the one
         r> exit ( phys.lo phys.mid phys.hi )
      else ( adr len’ phys.lo phys.mid ) \ Not this one
         2drop ( adr len’ )
      then ( adr len’ )
      decode-int drop decode-int drop \ Discard boring fields
   repeat
   2drop ( )
   ." Base address not assigned!" cr
   0 0 r> ( 0 0 phys.hi )
;

\ String comparision
: $= ( adr0 len0 adr1 len1 -- equal? )
   2 pick <> if 3drop false exit then ( adr0 len0 adr1 )
   swap comp 0=
;

\ Define "reg" property
\ PCI Configuration Space
my-address my-space encode-phys 0 encode-int encode+ 0 encode-int encode+

\ Memory Space Base Address Register 10
my-address my-space 0200.0010 or encode-phys encode+
0 encode-int encode+ /regs encode-int encode+

\ Memory Space Base Address Register 14
my-address my-space 0200.0014 or encode-phys encode+
0 encode-int encode+ /real-regs encode-int encode+

\ PCI Expansion ROM
my-address my-space h# 200.0030 or encode-phys encode+
0 encode-int encode+ h# 10.0000 encode-int encode+
" reg" property

-1 instance value chipbase
-1 instance value real-chipbase

: map-regs ( -- )
   map-in-broken? if
      my-space h# 8200.0010 or get-base-address ( phys.lo phys.mid phys.hi )
   else
      my-address my-space h# 200.0010 or ( phys.lo phys.mid phys.hi )
   then ( phys.lo phys.mid phys.hi )

   /regs map-in to chipbase
   4 dup my-w@ 2 or swap my-w! \ Enable memory space
   chipbase encode-int " address" property

   map-in-broken? if
      my-space h# 8200.0010 or get-base-address ( phys.lo phys.mid phys.hi )
   else
      my-address my-space h# 200.0014 or ( phys.lo phys.mid phys.hi )
   then ( phys.lo phys.mid phys.hi )

   /real-regs map-in to real-chipbase
   real-chipbase encode-int " real-address" property

;

: unmap-regs ( -- )
   4 dup my-w@ 4 invert and swap my-w! \ Disable memory space
   chipbase /regs map-out -1 to chipbase
   real-chipbase /real-regs map-out -1 to chipbase
   " address" delete-property
;

: e@ ( register -- byte ) real-chipbase 4000000 + + rb@ ;
: e! ( byte register -- ) real-chipbase 4000000 + + rb! ;
: ew@ ( register -- 16-bits ) real-chipbase 4000000 + + rw@ ;
: ew! ( 16-bits register -- ) real-chipbase 4000000 + + rw! ;
: el@ ( register -- 16-bits ) real-chipbase 4000000 + + rl@ ;
: el! ( 16-bits register -- ) real-chipbase 4000000 + + rl! ;

: mac@ ( register -- 16-bits)
	\ write address to address register
	macreg-addr el!
	\ read data register
	macreg-data el@
;

: mac! ( 16-bits register -- 16-bits )
	\ write data to data register
	swap macreg-data el!
	\ write address to address register
	macreg-write or macreg-addr el!

;

: control-on ( control-bit -- ) control e@ or control e! ;
: control-off ( control-bit -- ) invert control e@ and control e! ;

: reset-chip ( -- ) 1 control e! ;
: receive-on ( -- ) 2 control-on ;
: return-buffer ( -- ) 4 control-on ;
: start-xmit ( -- ) 8 control-on ;
: promiscuous ( -- ) 10 control-on ;
: loopback-on ( -- ) 20 control-on ;
: loopback-off ( -- ) 20 control-off ;

: receive-ready? ( -- #pkts-waiting ) rcv-rdy e@ ;
: wait-for-packet ( -- ) begin key? receive-ready? or until ;

\ Create local-mac-address property from the information in the chip
map-regs
6 alloc-mem ( mem-addr )
6 0 do local-addr i + rb@ over i + c! loop ( mem-addr )
6 2dup encode-string " local-mac-address" property ( mem-addr 6 )
free-mem
unmap-regs

: initchip ( -- )
   reset-chip
   \ Ask the host system for the station address and give it to the adapter
   mac-address 0 do ( addr )
   dup i + c@ unicast-addr i + e! ( addr )
   loop drop
   receive-on \ Enable reception
;

: net-init ( -- succeeded? )
   \ loopback-on loopback-test loopback-off if init-chip true else false then
   true
;

\ Check for incoming Ethernet packets while using promiscuous mode.
: watch-test ( -- )
   ." Looking for Ethernet packets." cr
   ." ’.’ is a good packet. ’X’ is a bad packet." cr
   ." Press any key to stop." cr
   begin
      wait-for-packet
      receive-ready? if
         rcv-len ew@ 8000 and 0= if ." ." else ." X" then
         return-buffer
      then
      key? dup if key drop then
   until
;

: (watch-net) ( -- )
   map-regs
   promiscuous
   net-init if watch-test reset-chip then
   unmap-regs
;

: le-selftest ( -- passed? )
   net-init
   \ dup if net-off then
;

external
: read ( addr requested-len -- actual-len )
   \ Exit if packet not yet available
   receive-ready? 0= if 2drop -2 exit then
      rcv-len ew@ dup 8000 and = if ( addr requested-len packet-len )
      3drop return-buffer \ Discard bad packet
      -1 exit
   then ( addr requested-len packet-len )

   \ Truncate to fit into the supplied buffer
   min ( addr actual-len )

   \ Note: For a DMA-based adapter, the driver would have to synchronize caches (e.g.
   \ with "dma-sync") and copy the packet from the DMA buffer into the result buffer.

   tuck bounds ?do rcv-fifo e@ i c! loop ( actual-len )
   return-buffer ( actual-len )
;

: close ( -- ) reset-chip unmap-regs ;

: open ( -- ok? )
   map-regs
   mac-address encode-string " mac-address" property
   \ initchip
   \ my-args " promiscuous" $= if promiscuous then

   \ Note: For a DMA-based adapter, the driver would have to allocate DMA memory for
   \ packet buffers, construct buffer descriptor data structures, and possibly
   \ synchronize caches (e.g. with "dma-sync").
   true
;

: write ( addr len -- actual )
   begin xmit-status e@ 0<> until
   \ Note: For a DMA-based adapter, the driver would have to copy the
   \ packet into the DMA buffer and synchronize caches (e.g. with "dma-sync").
   \ Copy packet into chip
   tuck bounds ?do i c@ xmit-fifo e! loop
   \ Set length register
   dup h# 64 max xmit-len ew!
   start-xmit
;

: load ( addr -- len )
   " obp-tftp" find-package if ( addr phandle )
      my-args rot open-package ( addr ihandle|0 )
   else ( addr )
      0 ( addr 0 )
   then ( addr ihandle|0 )
   dup 0= abort" Can’t open obp-tftp support package" ( addr ihandle )

   >r
   " load" r@ $call-method ( len )
   r> close-package
;

: selftest ( -- failed? )
   map-regs
   le-selftest 0=
   unmap-regs
;

: watch-net ( -- )
   selftest 0= if (watch-net) then
;
fcode-end

\ LICENSE_BEGIN
\ Copyright (c) 2008 Dave Srl
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
