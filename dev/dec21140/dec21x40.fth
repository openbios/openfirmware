\ See license at end of file
\ DEC FCode Ethernet driver
\ common code for 21040 and 21140

hex

" ethernet" device-name

" network" device-type

\ Register offsets from the adapter's base address

\ Control/Status Register Bits	-- long word access only!
00 constant mode	\ 
08 constant tpoll	\ 
10 constant rpoll	\ 
18 constant rbase	\ 
20 constant tbase	\ 
28 constant status	\ 
30 constant ctl		\ 
38 constant imask	\ 
40 constant missed	\ 
48 constant srom	\ 
58 constant timer	\ 
60 constant csr12	\ 
68 constant csr13	\ 
70 constant csr14	\ 
78 constant csr15	\ 

[ifndef] /regs
80 constant /regs	\ Total size of adapter's register bank
[then]

\ Configuration space registers
my-address my-space              encode-phys
                             0     encode-int encode+ 0 encode-int encode+

\ I/O space registers
0 0        my-space  0100.0010 + encode-phys encode+
                             0 encode-int encode+  /regs encode-int encode+

\ Memory space registers
0 0        my-space  0200.0014 + encode-phys encode+
                             0 encode-int encode+  /regs encode-int encode+
 " reg" property

0 instance value chipbase

: my-w@  ( offset -- w )  my-space +  " config-w@" $call-parent  ;
: my-w!  ( w offset -- )  my-space +  " config-w!" $call-parent  ;
: unmap-regs  ( -- )
   4 my-w@  6 invert and  4 my-w!
   chipbase /regs " map-out" $call-parent
;
: map-regs  ( -- )
   0 0  my-space h# 0200.0014 +  /regs " map-in" $call-parent  to chipbase
   4 my-w@  6 or  4 my-w!
;

: le-l!  ( l adr -- )
   >r lbsplit  r@ 3 + c!  r@ 2+ c!  r@ 1+ c!  r> c!
;
: le-l@  ( adr -- l )
   >r  r@ c@  r@ 1+ c@  r@ 2+ c@  r> 3 + c@  bljoin
;

\ Only long word accesses are allowed to the Control/Status registers
: e@  ( register -- 32-bits )  chipbase + rl@  ;
: e!  ( 32-bits register -- )  chipbase + rl!  ;

  70.0000 constant tstate

\ Register Bit Fields
\ Status

\ Control
0000.2000 constant transmit-enable
0000.0002 constant receive-enable

\ put single transmit descriptor last
     10 constant /desc
d# 1600 constant /buf
      1 constant #tbufs
     20 constant #rbufs
  #tbufs #rbufs + constant #bufs
  /desc #bufs * constant /descs
  /buf  #bufs * constant /bufs

0 value descs-phys
0 value bufs-phys
0 value desc-base
0 value buf-base
0 value descs
0 value bufs
0 value descs-end
0 value tdesc
0 value tbuf
0 value rdesc   

: +rdesc   ( -- )
   rdesc /desc +  dup descs-end u>= if
      drop descs
   then
   to rdesc
;

: round-up  ( n boundary -- n' )  1- tuck +  swap invert and  ;

: alloc-buffers   ( -- )
   /descs 4 + " dma-alloc" $call-parent to desc-base
   desc-base 4 round-up to descs  descs to rdesc
   descs /descs + /desc -  dup to tdesc  to descs-end
   /bufs 4 + " dma-alloc" $call-parent to buf-base
   buf-base 4 round-up to bufs
   bufs /bufs + /buf - to tbuf
;
: free-buffers   ( -- )
   descs descs-phys /descs " dma-map-out"  $call-parent
   desc-base /descs 4 + " dma-free" $call-parent
   bufs bufs-phys /bufs " dma-map-out" $call-parent
   buf-base  /bufs  4 + " dma-free" $call-parent
;

\ descriptor bit fields
  8000.0000 constant own
  0200.0000 constant end-of-ring
  0000.8000 constant rerror

d# 192 constant setup-size
\ setup-size buffer: setup-buf

: initchip  ( -- )
   1 mode e!  1 ms			\ Reset chip; disables interrupts
   h# 8000 mode e!  1 ms		\ Cache alignment 16
\   0 imask e!				\ disable interrupts
   -1 status e!				\ clear status
;

: >virtual   ( phys -- virt )  bufs-phys - bufs +  ;
: buf>physical  ( virt -- phys )  bufs - bufs-phys +  ;

: setup-descs  ( -- )

   \ setup descriptors
   descs /descs erase			\ clear all bits

   \ receive descriptors belong to the nic
   \ let each descriptor point to its own buffer
   bufs-phys   descs /descs bounds do
      own   i     le-l!
      /buf  i 4 + le-l!	\ also handles address-chained and end-of-ring
      dup   i 8 + le-l!
      /buf +  /desc
   +loop  drop

   0 tdesc le-l!	\ host owns transmit buffer

   \ flag final descriptors
   end-of-ring tdesc 4 + le-l!		
   end-of-ring /buf or descs-end /desc - 4 + le-l!

   descs descs-phys /descs " dma-push"  $call-parent

   \ set base registers to point to descriptor lists
   descs-phys      		rbase e!
   tdesc descs - descs-phys + 	tbase e!
;

defer set-interface  ' noop to set-interface
: make-setup-frame  ( -- )
   \ fill setup frame with broadcast address
   tbuf setup-size 0ff fill

   \ put our address into setup frame. Each 32-bit word of the setup
   \ frame contains 2 bytes of the MAC address.  Stranger than truth!
   tbuf
   mac-address  bounds  ?do                   ( dst-adr )
      i    c@  over    c!
      i 1+ c@  over 1+ c!   4 +
   2 +loop   drop
;
defer set-address
\ This is the standard way of setting the station address.
\ A few "compatible" chips do it a different way, though.
: (set-address)  ( -- error? )
   make-setup-frame
   tbuf  dup buf>physical  setup-size  " dma-push" $call-parent

   \ Ask the host system for the station address and give it to the adapter
   \ use transmit buffer as setup frame
   setup-size 0800.0000 or end-of-ring or  tdesc 4 + le-l!

   own tdesc le-l!
   tdesc dup  descs - descs-phys + /desc  " dma-push" $call-parent

   ctl e@  transmit-enable or  ctl e!	\ process setup frame
   
   d# 1 ms				\ Give chip time to do it
   tdesc dup  descs - descs-phys + /desc  " dma-pull" $call-parent
   tdesc le-l@  h# 7fff.ffff <>
;
' (set-address) is set-address
: setup-buffers   ( -- error? )
   descs /descs false " dma-map-in" $call-parent to descs-phys
   bufs  /bufs  true  " dma-map-in" $call-parent to bufs-phys
   setup-descs
   set-address
;
: release-buffer   ( -- )
   own rdesc le-l!
   rdesc dup  descs - descs-phys + /desc  " dma-push" $call-parent
   +rdesc  
;
: $=  ( adr0 len0 adr1 len1 -- equal? )
   2 pick <>  if  3drop false exit  then  ( adr0 len0 adr1 )
   swap comp 0=
;

external
: promiscuous  ( -- )  ctl e@  h# 40 or  ctl e!  ;

: read  ( adr requested-len -- actual-len  )
   \ Exit if packet not yet available
   rdesc dup  descs - descs-phys + /desc  " dma-pull" $call-parent
   rdesc le-l@ own and  if
      2drop -2 exit
   then

   rdesc le-l@ rerror and  if		( addr requested-len )
      release-buffer  2drop		\ Discard bad packet
      -1 exit
   then

   rdesc le-l@ 10 rshift 7fff and	( addr requested-len packet-len )
   \ Truncate to fit into the supplied buffer
   min				( adr copy-len )

   \ Note: For this DMA-based adapter, the driver must
   \ synchronize caches and copy the packet
   \ from the DMA buffer into the result buffer.
   dup >r					( adr copy-len )
   rdesc 8 + le-l@ dup >virtual  swap  r@  " dma-pull" $call-parent

   rdesc 8 + le-l@ >virtual  -rot move   r>	( actual-len )
   release-buffer
;

: close  ( -- )
   0 ctl e!  free-buffers  unmap-regs
;

: open  ( -- ok? )
   map-regs
   mac-address  encode-bytes   " mac-address" property 

   initchip		       \ Init the first time to enable the MIF 
   set-interface	       \ Configure the physical interface
   
\   initchip

   alloc-buffers 
   setup-buffers  if  close false  exit  then

   ctl e@  h# 40  my-args  " promiscuous" $=  if  or  else  invert and  then
   receive-enable or  ctl e!	 	\ enable reception

   true
;

: write  ( adr len -- actual )
   begin
      tdesc dup  descs - descs-phys + /desc  " dma-pull" $call-parent
      tdesc le-l@ own and
   0=  until				\ wait until free

   \ Note: For this DMA-based adapter, the driver must copy the
   \ packet into the DMA buffer and synchronize caches
   /buf min  tuck   tbuf swap move	( actual )

   tbuf dup buf>physical 2 pick  " dma-push" $call-parent  ( actual )

   \ Set length register
   dup  h# 64 max  6000.0000 or  end-of-ring or   tdesc 4 + le-l!
   own tdesc le-l!

   tdesc dup  descs - descs-phys + /desc  " dma-push" $call-parent

   1 tpoll e!		\ Start transmission
;

: load  ( adr -- len )
   " obp-tftp" find-package  if      ( adr phandle )
      my-args rot  open-package      ( adr ihandle|0 )
   else                              ( adr )
      0                              ( adr 0 )
   then                              ( adr ihandle|0 )

   dup  0=  if  ." Can't open obp-tftp support package" abort  then
                                     ( adr ihandle )

   >r
   " load" r@ $call-method           ( len )
   r> close-package
;

\ XXX hack
\ : selftest
\    open 0= if
\       true
\       exit
\    then
\ 
\    close
\ 
\    false
\ ;
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
