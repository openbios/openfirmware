purpose: Data structures and manuipulation routines for EHCI USB Controller
\ See license at end of file

hex
headers

\ XXX Isochronous is not supported in the current version of the EHCI driver

\ ---------------------------------------------------------------------------
\ Data structures for this implementation of the EHCI USB Driver include:
\   - qh-ptr	pointer to the asynchronous list of QHs
\   - framelist	pointer to the Periodic Frame List
\   - intr      internal array of interrupts
\ ---------------------------------------------------------------------------

\ Constants common to most EHCI data structures
1 constant TERMINATE

0 constant TYP_ITD
2 constant TYP_QH
4 constant TYP_SITD
6 constant TYP_FSTN

\ Pipe type
0 constant pt-ctrl
1 constant pt-bulk
2 constant pt-intr
3 constant pt-iso

\ ---------------------------------------------------------------------------
\ Periodic Frame List as defined by the EHCI Spec; 4-KB aligned
\
\ Each entry is composed of:  bit  0    TERMINATE
\                             bits 2:1  Pipe type
\                             bits 31:5 Frame List Link Pointer
\ ---------------------------------------------------------------------------

h# 1000 constant /align4kb

d# 1024 dup constant #framelist		\ # of entries in framelist
4 *         constant /framelist		\ Size of framelist

0 value framelist
0 value framelist-unaligned
0 value framelist-phys

: framelist!  ( n idx -- )  4 * framelist + le-l!  ;

: init-framelist  ( -- )
   \ Allocate framelist
   /framelist /align4kb aligned-alloc	( unaligned virt )
   swap to framelist-unaligned		( virt )
   dup to framelist			( virt )
   /framelist true dma-map-in to framelist-phys	( )

   \ Initialize framelist
   #framelist 0  do  TERMINATE i framelist!  loop
   framelist-phys periodic!
;

\ ---------------------------------------------------------------------------
\ Internal interrupt list corresponding with the Frame List
\ ---------------------------------------------------------------------------

struct
   4 field >intr-head
   4 field >intr-tail
dup constant /intr-entry
#framelist * constant /intr		\ Size of intr

0 value intr				\ Internal array of interrupts

: 'intr  ( idx -- adr )  /intr-entry * intr +  ;
: intr-head@  ( idx -- adr )  'intr >intr-head l@  ;
: intr-head!  ( adr idx -- )  'intr >intr-head l!  ;
: intr-tail@  ( idx -- adr )  'intr >intr-tail l@  ;
: intr-tail!  ( adr idx -- )  'intr >intr-tail l!  ;

: init-intr  ( -- )
   /intr alloc-mem dup to intr		\ Allocate intr
   /intr erase				\ Initialize intr
;

\ ---------------------------------------------------------------------------
\ Queue Element Transfer Descriptor (qTD) as defined by the EHCI Spec; 32-byte aligned
\ ---------------------------------------------------------------------------

struct					\ Beginning of qTD
   4 field >hcqtd-next			\ Next qTD pointer
   4 field >hcqtd-next-alt		\ Alternate next qTD pointer
   4 field >hcqtd-token			\ qTD token
   4 field >hcqtd-bptr0			\ Buffer pointer 0 (4KB aligned)
   4 field >hcqtd-bptr1			\ Buffer pointer 1
   4 field >hcqtd-bptr2			\ Buffer pointer 2
   4 field >hcqtd-bptr3			\ Buffer pointer 3
   4 field >hcqtd-bptr4			\ Buffer pointer 4
   4 5 * field >hcqtd-xbptrs		\ 64-bit buffer pointer extensions
dup constant /hcqtd
					\ Driver specific fields
   4 field >qtd-phys			\ Physical address of qTD
   4 field >qtd-next			\ Next qTD virtual address
   4 field >qtd-buf			\ Buffer virtual address
   4 field >qtd-pbuf			\ Buffer physical address
   4 field >qtd-/buf			\ Buffer length (per qTD)
   4 field >qtd-/buf-all		\ Buffer length (size of the entire buffer)
					\ Only the first qTD has the entire size of buffer
					\ For bulk and intr qTDs
d# 32 round-up
constant /qtd

\ >hcqtd-token constants
h# 0000.0000 constant TD_TOGGLE_DATA0
h# 8000.0000 constant TD_TOGGLE_DATA1
h# 8000.0000 constant TD_TOGGLE_MASK
h# 0000.8000 constant TD_IOC
h# 0000.0c00 constant TD_C_ERR_MASK
h# 0000.0400 constant TD_C_ERR1
h# 0000.0800 constant TD_C_ERR2
h# 0000.0c00 constant TD_C_ERR3
h# 0000.0000 constant TD_PID_OUT
h# 0000.0100 constant TD_PID_IN
h# 0000.0200 constant TD_PID_SETUP
h# 0000.00ff constant TD_STAT_MASK
h# 0000.0080 constant TD_STAT_ACTIVE
h# 0000.0040 constant TD_STAT_HALTED	\ Babble, error count=0, STALL
h# 0000.0020 constant TD_STAT_DBUFF	\ Data buffer error
h# 0000.0010 constant TD_STAT_BABBLE	\ Babble
h# 0000.0008 constant TD_STAT_XERR	\ Timeout, CRC, bad pid, etc
h# 0000.0004 constant TD_STAT_MISS_MF	\ Missed micro-frame
h# 0000.0000 constant TD_STAT_S_SPLIT	\ Start split transaction
h# 0000.0002 constant TD_STAT_C_SPLIT	\ Complete split transaction
h# 0000.0000 constant TD_STAT_OUT	\ Do OUT
h# 0000.0001 constant TD_STAT_PING	\ Do ping
h# 0000.0001 constant TD_STAT_SPLIT_ERR	\ Periodic split transaction ERR

: td-data>di-data  ( n -- n' )  TD_TOGGLE_MASK and  if  1  else  0  then  ;
: di-data>td-data  ( n -- n' )  if  TD_TOGGLE_DATA1  else  TD_TOGGLE_DATA0  then  ;

\ ---------------------------------------------------------------------------
\ Queue Head (QH) as defined by the EHCI Spec; 32-byte aligned
\ ---------------------------------------------------------------------------

struct					\ Beginning of QH fields
   4 field >hcqh-next			\ QH horizontal link pointer
   4 field >hcqh-endp-char		\ Endpoint characteristics
   4 field >hcqh-endp-cap		\ Endpoint capabilities
   4 field >hcqh-cur-pqtd		\ Current transaction descriptor pointer
/hcqtd field >hcqh-overlay		\ Transfer overlay area
dup constant /hcqh
					\ Driver specific fields
   4 field >qh-phys			\ QH's physical address
   4 field >qh-next			\ Next QH's virtual address
   4 field >qh-prev			\ Previous QH's virtual address
   4 field >qh-unaligned		\ QH's unaligned address
   4 field >qh-size			\ Size of QH+qTDs 
   4 field >qh-#qtds			\ # of qTDs in the list
d# 32 round-up
constant /qh

\ >hcqh-endp-char constants
h# 0800.0000 constant QH_CTRL_ENDP
h# 0000.8000 constant QH_HEAD
h# 0000.4000 constant QH_TD_TOGGLE
h# 0000.0080 constant QH_INACTIVE_NEXT
h# 0000.0000 constant QH_TUNE_RL_HS
h# 0000.0000 constant QH_TUNE_RL_TT

\ >hcqh-endp-cap constants
h# 4000.0000 constant QH_MULT1
h# 8000.0000 constant QH_MULT2
h# c000.0000 constant QH_MULT3


0 value qh-ptr				\ Head of all QHs

\ ---------------------------------------------------------------------------
\ QH and TDs for bulk, control and interrupt operations.
\ QH and its list of TDs are allocated as needed.
\ ---------------------------------------------------------------------------

: sync-qh      ( qh  -- )  dup >qh-phys  l@ /hcqh  dma-sync  ;
: sync-qtd     ( qtd -- )  dup >qtd-phys l@ /hcqtd dma-sync  ;
: sync-qhqtds  ( qh  -- )  dup >qh-phys  l@ over >qh-size l@  dma-sync  ;

: map-out-bptrs  ( qtd -- )
   dup >qtd-buf l@ over >qtd-pbuf l@ rot >qtd-/buf-all l@ hcd-map-out
;

: init-qh  ( qh.u,v,p len #qtds -- )
   3 pick >qh-#qtds l!			( qh.u,v,p len )
   2 pick >qh-size l!			( qh.u,v,p )
   over >qh-phys l!			( qh.u,v )
   TERMINATE 2 pick >hcqh-next le-l!	( qh.u,v )
   >qh-unaligned l!			( )
;
: link-qtds  ( qtd.v qtd.p #qtds -- )
   1- 0  ?do				( qtd.v qtd.p )
      TERMINATE 2 pick >hcqtd-next-alt le-l!	( qtd.v qtd.p )
      2dup swap >qtd-phys l!		( qtd.v qtd.p )
      /qtd +				( qtd.v qtd.p' )
      2dup swap >hcqtd-next le-l!	( qtd.v qtd.p )
      swap dup /qtd + tuck swap >qtd-next l!	( qtd.p qtd.v' )
      swap				( qtd.v qtd.p )
   loop

   \ Fix up the last qTD
   over >qtd-phys l!			( qtd.v )
   TERMINATE over >hcqtd-next le-l!	( qtd.v )
   TERMINATE swap >hcqtd-next-alt le-l!	( )
;
: link-qhqtd  ( qtd.p qh -- )
   >hcqh-overlay tuck			( qh.overlay qtd.p qh.overlay )
   >hcqtd-next le-l!			( qh.overlay )
   TERMINATE over >hcqtd-next-alt le-l!	( qh.overlay)
   \ We start with OUT instead of PING here because some broken USB keys don't
   \ support PING.  In bulk.fth, we add back the PING flag for bulk-out
   \ operations, where ping transactions can help significantly.
   TD_TOGGLE_DATA1 TD_STAT_OUT or swap >hcqtd-token le-l!	( )
;

: link-qhqtds  ( qtd.v qtd.p #qtds qh -- )
   2 pick swap link-qhqtd		( qtd.v qtd.p #qtds )	\ Link QH to qTD
   link-qtds				( )			\ Link qTDs
;

: alloc-qhqtds  ( #qtds -- qh qtd )
   dup >r  /qtd * /qh + dup >r		( len )  ( R: #qtds len )
   aligned32-alloc-map-in		( qh.u,v,p )  ( R: #qtds len )
   over r@ erase			( qh.u,v,p )  ( R: #qtds )
   3dup r> r@ init-qh			( qh.u,v,p )  ( R: #qtds )
   rot drop				( qh.v,p )  ( R: #qtds )
   over /qh + dup -rot			( qh qtd qh.p qtd )  ( R: #qtds )
   swap /qh +				( qh qtd qtd.v,p )  ( R: #qtds )
   r> 4 pick link-qhqtds		( qh qtd )
;

: free-qhqtds  ( qh -- )
   >r					( R: qh )
   r@ >qh-unaligned l@			( qh.u )  ( R: qh )
   r@ dup >qh-phys l@			( qh.u,v,p )  ( R: qh )
   r> >qh-size l@			( qh.u,v,p size )
   aligned32-free-map-out		( )
;
: reuse-qhqtds  ( #qtds qh -- qh qtd )
   swap dup >r  /qtd * /qh + >r		( qh )  ( R: #qtds len )
   dup >qh-unaligned l@ swap		( qh.u,v )  ( R: #qtds len )
   dup >qh-phys l@			( qh,u,v,p )  ( R: #qtds len )
   over r@ erase			( qh.u,v,p )  ( R: #qtds )
   3dup r> r@ init-qh			( qh.u,v,p )  ( R: #qtds )
   rot drop				( qh.v,p )  ( R: #qtds )
   over /qh + dup -rot			( qh qtd qh.p qtd )  ( R: #qtds )
   swap /qh +				( qh qtd qtd.v,p )  ( R: #qtds )
   r> 4 pick link-qhqtds		( qh qtd )
;

\ ---------------------------------------------------------------------------
\ qTD Buffer Pointers management
\ ---------------------------------------------------------------------------

5                    constant #bptr		\ There are 5 Buffer Pointers in qTD
h# 1000              constant /bptr		\ Size of buffer at each Buffer Pointer[i]
/bptr 1-	     constant bptr-ofs-mask	\ Current Offset mask
bptr-ofs-mask invert constant bptr-mask		\ Buffer Pointer mask
/bptr #bptr    *     constant /maxbptrs		\ Maximum size of transfer for a qTD
/bptr #bptr 1- *     constant /maxbptrs-1	\ Maximum size of 4 Buffer Pointers

\ Determine the size of transfer for a qTD
: cal-/bptr  ( phys len -- /xfer )
   over dup /bptr round-up =  if	( phys len )
      nip /maxbptrs min			( /xfer )
   else
      swap bptr-ofs-mask and		( len len0 )
      tuck - /maxbptrs-1 min +		( /xfer )
   then
;

\ Determine the number of Buffer Pointers necessary
: cal-#bptr  ( phys len -- #bptr )
   dup  0=  if  nip exit  then
   swap dup /bptr round-up swap -  ?dup  if
					( len len0 )
      -					( len-len0 )
      /bptr round-up /bptr / 1+		( #bptr )
   else					( len )
      /bptr round-up /bptr /		( #bptr )
   then
;

\ Determine the number of qTDs necessary for the entire transfer
: cal-#qtd  ( phys len -- #qtds )
   dup  0=  if  nip exit  then
   cal-#bptr #bptr /mod swap  if  1+  then
;

: fill-qtd-bptrs  ( buf phys len qtd -- actual )
   >r rot r@ >qtd-buf l!		( phys len )  ( R: qtd )
   dup r@ >qtd-/buf-all l!		( phys len )  ( R: qtd )
   over r@ >qtd-pbuf l!			( phys len )  ( R: qtd )
   over swap cal-/bptr tuck  		( actual phys actual )  ( R: qtd )
   dup r@ >qtd-/buf l!			( actual phys actual )  ( R: qtd )
   over swap cal-#bptr			( actual phys #bptr )  ( R: qtd )
   r> swap 0  ?do			( actual phys qtd )
      2dup >hcqtd-bptr0 i 4 * + le-l!	( actual phys qtd )
      swap /bptr + bptr-mask and swap	( actual phys' qtd )
   loop  2drop				( actual )
;

\ ---------------------------------------------------------------------------
\ Async scheduling
\ ---------------------------------------------------------------------------

: async-wait  ( -- )
   begin
      usbcmd@ h# 20 and  5 >>  usbsts@ h# 8000 and d# 15 >> 
   = until
;
: enable-async  ( phys -- )
   asynclist!                async-wait
   usbcmd@ h# 20 or usbcmd!  async-wait
;
: disable-async  ( -- )
   async-wait  usbcmd@ h# 20 invert and usbcmd!  async-wait
;

: insert-qh  ( qh -- )
   >r
   qh-ptr  if
      \ If there is another qh in the system, link the new qh to the existing
      \ qh head.
      qh-ptr r@ >qh-prev l!
      qh-ptr >qh-next l@ r@ >qh-next l!
      qh-ptr >hcqh-next le-l@ r@ >hcqh-next le-l!
      r@ qh-ptr >qh-next l!
      r@ >qh-phys l@ qh-ptr >hcqh-next le-l!
      r> sync-qhqtds
      qh-ptr sync-qh
   else
      \ If there is no qh in the system, link it to itself and mark it the
      \ head.
      r@ to qh-ptr
      r@ >hcqh-endp-char dup le-l@ QH_HEAD or swap le-l!
      r@ dup >qh-next l!
      r@ >qh-phys l@ dup TYP_QH or r@ >hcqh-next le-l!
      r> sync-qhqtds
      enable-async
   then
;

: remove-qh  ( qh -- )
   dup >qh-next l@ over =  if
      \ If qh is the only qh in the system, disable-async and exit
      drop disable-async
      0 to qh-ptr
   else
      \ Otherwise, qh.prev points to qh.next, fix up reclamation bits.
      \ Ring doorbell, wait for answer.
      \ Free qh, make sure the qh-ptr is up-to-date.
      dup >qh-prev l@ ?dup if		( qh prev.qh )
         over >hcqh-next le-l@ over >hcqh-next le-l!
         over >qh-next l@ swap >qh-next l!
         dup sync-qh
         dup >qh-next l@ qh-ptr <>  if
            dup >qh-prev l@ swap >qh-next l@ >qh-prev l!
         else
            drop
         then
      else
         >qh-next l@ to qh-ptr
         qh-ptr >hcqh-endp-char dup le-l@ QH_HEAD or swap le-l!
         0 qh-ptr >qh-prev l!
	 qh-ptr sync-qh
      then
      ring-doorbell
   then
;

\ ---------------------------------------------------------------------------
\ Interrupt scheduling
\ XXX Make it simple for now and igore interval and make it a fixed poll
\ XXX interval.
\
\ Empirically, the 4 ms poll interval works optimally with the usb keyboard.
\ ---------------------------------------------------------------------------

0 value #intr
d# 32 constant intr-interval		\ 4 ms poll interval

: #intr++  ( -- )  #intr 1+ to #intr  ;
: #intr--  ( -- )  #intr 1- to #intr  ;

: periodic-wait  ( -- )
   begin
      usbcmd@ h# 10 and  4 >>  usbsts@ h# 4000 and d# 14 >> 
   = until
;
: enable-periodic  ( -- )
   periodic-wait  usbcmd@ h# 10 or usbcmd!  periodic-wait
;
: disable-periodic  ( -- )
   periodic-wait  usbcmd@ h# 10 invert and usbcmd!  periodic-wait
;

: (insert-intr-qh)  ( qh idx -- )
   dup >r				( qh idx )  ( R: idx )
   intr-tail@ ?dup 0=  if		( qh )  ( R: idx )
      dup r@ intr-head!			( qh )  ( R: idx )
      dup >qh-phys l@ TYP_QH or r@ framelist!
					( qh )  ( R: idx )
   else					( qh tail )  ( R: idx )
      2dup >qh-next l!			( qh tail )  ( R: idx )
      over >qh-phys l@ TYP_QH or over >hcqh-next le-l!
					(  qh tail )  ( R: idx )
      over >qh-prev l!			( qh )  ( R: idx )
   then
   r> intr-tail!			( )
;
: insert-intr-qh  ( qh speed interval -- )
   drop					( qh speed )
   speed-high =  if  h# 0020  else  h# 1c01  then
   over >hcqh-endp-cap dup le-l@ rot or swap le-l!
   ( qh ) #framelist 0 do  dup i (insert-intr-qh)  intr-interval +loop  drop
   #intr 0=  if  enable-periodic  then
   #intr++
;

: (remove-intr-qh)  ( qh idx -- )
   >r					( qh )  ( R: idx )
   dup >qh-prev l@ ?dup  if  over >qh-next l@ swap >qh-next l!  then
   dup >qh-next l@ ?dup  if  over >qh-prev l@ swap >qh-prev l!  then
   r@ intr-head@ over =  if		( qh )  ( R: idx )
      dup >qh-next l@ dup r@ intr-head!	( qh nqh )  ( R: idx )
      ?dup  if  >qh-phys l@ TYP_QH or  else  TERMINATE  then  r@ framelist!
					( qh )  ( R: idx )
   then
   r@ intr-tail@ over =  if		( qh )  ( R: idx )
      dup >qh-prev l@ r@ intr-tail!	( qh )  ( R: idx )
   then
   r> 2drop
;
: remove-intr-qh  ( qh -- )
   #intr--
   ( qh ) #framelist 0  do  dup i (remove-intr-qh)  intr-interval +loop  drop
   #intr 0=  if  disable-periodic  then
;

\ ---------------------------------------------------------------------------
\ Wait for a QH to be done and process any errors.
\
\ When done? returns no error found yet, the caller should check if errors
\ were found in the TDs.
\ ---------------------------------------------------------------------------

0 value timeout

: .qtd-error  ( cc -- )
   dup TD_STAT_HALTED  and  if  " Stalled; "                USB_ERR_STALL       set-usb-error  then
   dup TD_STAT_DBUFF   and  if  " Data Buffer Error; "      USB_ERR_DBUFERR     set-usb-error  then
   dup TD_STAT_BABBLE  and  if  " Babble Detected; "        USB_ERR_BABBLE      set-usb-error  then
   dup TD_STAT_XERR    and  if  " CRC/Timeout/Bad PID; "    USB_ERR_CRC         set-usb-error  then
   dup TD_STAT_MISS_MF and  if  " Missed Micro-frame; "     USB_ERR_MICRO_FRAME set-usb-error  then
   TD_STAT_SPLIT_ERR   and  if  " Periodic split-x error; " USB_ERR_SPLIT       set-usb-error  then
;

: qh-done?  ( qh -- done? )
   >hcqh-overlay			( olay )
   dup >hcqtd-next le-l@ 		( olay pnext )
   swap >hcqtd-token le-l@ 		( pnext token )
   dup TD_STAT_HALTED and -rot		( halted? pnext token )
   TD_STAT_ACTIVE and 0= swap		( halted? inactive? pnext )
   TERMINATE = and			( halted? done? )
   or					( done?' )
;
: done?  ( qh -- usberr )
   begin
      process-hc-status
      ( qh ) dup sync-qh
      ( qh ) dup qh-done? ?dup 0=  if
         1 ms
         timeout 1- dup to timeout 0=
      then
   until

   ( qh ) qh-done? 0=  if  " Timeout" USB_ERR_TIMEOUT set-usb-error  then
   usb-error
;

: error?  ( qh -- usberr )
   dup >hcqh-endp-char le-l@ d# 12 >> 3 and
   speed-high =  if  h# fc  else  h# fd  then
   swap >hcqh-overlay >hcqtd-token le-l@  and ?dup  if  .qtd-error  then
   usb-error
;

: get-actual  ( qtd #qtd -- actual )
   0 -rot 0  ?do			( actual qtd )
      dup sync-qtd			( actual qtd )
      dup >hcqtd-token le-l@ dup TD_STAT_ACTIVE and 0=  if
         over >qtd-/buf l@		( actual qtd token len )
         swap d# 16 >> h# 7fff and -	( actual qtd len' )
         rot + swap			( actual' qtd )
      else
         drop				( actual qtd )
      then
      >qtd-next l@			( actual qtd )
   loop  drop				( qtd )
;

\ ---------------------------------------------------------------------------
\ Allocate a dummy qh to be head of the queue to get around the fact that
\ the VIA 2.0 controller does not stop async when told to.
\ ---------------------------------------------------------------------------

0 value dummy-qh

: alloc-dummy-qh  ( -- )
   dummy-qh 0=  if
      1 alloc-qhqtds			( qh qtd )
      drop to dummy-qh
      TERMINATE dummy-qh >hcqh-overlay >hcqtd-next le-l!
   then
   dummy-qh insert-qh
;

: free-dummy-qh  ( -- )
   dummy-qh ?dup  if  free-qhqtds  0 to dummy-qh  then
;

: ?alloc-dummy-qh  ( -- )
   0 my-w@ h# 1106 ( VIA ) =  if  alloc-dummy-qh  then
;

: (init-extra)  ( -- )
   ?alloc-dummy-qh
   init-intr
   init-framelist
;

' (init-extra) to init-extra

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
