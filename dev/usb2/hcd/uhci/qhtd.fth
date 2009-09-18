purpose: Data structures and manuipulation routines for UHCI USB Controller
\ See license at end of file

\ XXX Isochronous is not supported in the current version of the UHCI driver

\ ---------------------------------------------------------------------------
\ Data structures for this implementation of the UHCI USB Driver include:
\   - frame-list (an array of 1024 entries of TD/QH pointers, physical)
\   - intr-qh (a queue head for interrupt transactions)
\   - low-qh (a queue head for control & bulk transactions for low-speed devices)
\   - full-qh (a queue head for control & bulk transactions for high-speed devices)
\ ---------------------------------------------------------------------------

hex
headers

\ Constants common to most UHCI data structures
1 constant TERMINATE

0 constant TYP_TD
2 constant TYP_QH

\ ---------------------------------------------------------------------------
\ Frame List as defined by the UHCI Spec; 4-KB aligned
\
\ Each entry is composed of:  bit 0     TERMINATE
\                             bit 1     1=QH, 0=TD
\                             bits 31:4	Frame List Pointer
\ ---------------------------------------------------------------------------

h# 1000 constant /align4kb

d# 1024 dup constant #framelist			\ # of entries in framelist
4 *         constant /framelist			\ Size of framelist

0 value framelist
0 value framelist-phys
0 value framelist-unaligned

: framelist!  ( n idx -- )  4 * framelist + le-l!  ;

\ ---------------------------------------------------------------------------
\ Queue Head as defined by the UHCI Spec; 16-byte aligned
\ ---------------------------------------------------------------------------

struct
   4 field >hcqh-next				\ QH link pointer
   4 field >hcqh-elem				\ Queue element link pointer
dup constant /hcqh
   8 +						\ Make it easier to look at
   4 field >qh-phys				\ QH's physical address
   4 field >qh-next				\ Virtual address of >hcqh-next
   4 field >qh-prev				\ Virtual address of previous QH
   4 field >qh-unaligned			\ QH's unaligned address
   4 field >qh-size				\ Size of QH+TDs
   4 field >qh-#tds				\ Number of TDs in >hcqh-elem
   4 field >qh-elem				\ Virtual address of >hcqh-elem
d# 16 round-up
constant /qh

\ ---------------------------------------------------------------------------
\ Transfer Descriptor as defined by the UHCI Spec; 16-byte aligned
\ ---------------------------------------------------------------------------
struct
   4 field >hctd-next				\ TD link pointer
   4 field >hctd-stat				\ TD control and status
   4 field >hctd-token				\ TD token
   4 field >hctd-buf				\ TD buffer pointer
dup constant /hctd
   4 field >td-phys				\ TD's physical address
   4 field >td-next				\ Next TD's virtual address
   4 field >td-buf				\ Virtual address of >hctd-buf
   4 field >td-pbuf				\ Physical address of >hctd-buf
   4 field >td-/buf-all				\ Buffer length (size of the entire buffer)
						\ Only the first TD has the entire size of buffer
						\ For bulk and intr TDs
d# 16 round-up
constant /td

\ >hctd-next constants
0 constant TD_BREADTH				\ Next transaction in next QH
4 constant TD_DEPTH				\ Next transaction in next TD

\ >hctd-stat constants
h# 2000.0000 constant TD_CTRL_SPD		\ Short packet detect
h# 1800.0000 constant TD_CTRL_C_ERR_MASK	\ Error counter bits
h# 0800.0000 constant TD_CTRL_C_ERR1		\ Interrupt on one error
h# 1000.0000 constant TD_CTRL_C_ERR2		\ Interrupt on two errors
h# 1800.0000 constant TD_CTRL_C_ERR3		\ Interrupt on three errors
h# 0400.0000 constant TD_CTRL_LOW		\ Low speed device
h# 0000.0000 constant TD_CTRL_FULL		\ Full speed device
h# 0200.0000 constant TD_CTRL_ISO		\ Isochonous select
h# 0100.0000 constant TD_CTRL_IOC		\ Interrupt on complete
h# 0080.0000 constant TD_STAT_ACTIVE		\ TD active
h# 0040.0000 constant TD_STAT_STALLED		\ TD stalled
h# 0020.0000 constant TD_STAT_DBUFERR		\ Data buffer error
h# 0010.0000 constant TD_STAT_BABBLE		\ Babble detected
h# 0008.0000 constant TD_STAT_NAK		\ NAK received
h# 0004.0000 constant TD_STAT_CRCTIME		\ CRC or timeout error
h# 0002.0000 constant TD_STAT_BITSTUFF		\ Bit stuff error
h# 00ff.0000 constant TD_STAT_MASK		\ Status mask

TD_STAT_STALLED TD_STAT_DBUFERR or TD_STAT_BABBLE or TD_STAT_CRCTIME or
TD_STAT_BITSTUFF or TD_STAT_NAK or constant TD_STAT_ANY_ERROR

h# 07ff constant TD_NULL_DATA_SIZE		\ Null data length
h# 07ff constant TD_ACTUAL_MASK			\ TD actual length mask

\ >hctd-token constants
h# 00ff constant TD_PID_MASK			\ PID mask
h# 002d constant TD_PID_SETUP
h# 0069 constant TD_PID_IN
h# 00e1 constant TD_PID_OUT

h# 0008.0000 constant TD_TOKEN_DATA1		\ Data1
h# 0000.0000 constant TD_TOKEN_DATA0		\ Data0
h# 0008.0000 constant TD_TOKEN_MASK		\ Data toggle mask

: di-data>td-data  ( n -- n' )  if  TD_TOKEN_DATA1  else  TD_TOKEN_DATA0  then  ;
: td-data>di-data  ( n -- n' )  TD_TOKEN_MASK and  if  1  else  0  then  ;

\ ---------------------------------------------------------------------------
\ Permanent QHs for interrupt, low-speed and high-speed transactions.
\
\ These are place holders so we know where to insert new QHs depending on
\ their characteristics easily.  
\ Link: intr-qh -> low-qh -> full-qh -> last-qh 
\
\ XXX My initial design was to have last-qh pointing to full-qh to allow
\ XXX reclaimation.  But I get all sort of HC errors.  Now, it's painfully
\ XXX slow but it gets there eventually.
\ ---------------------------------------------------------------------------

4 constant #fixed-qhs
0 value fixed-qh
0 value fixed-qh-phys
0 value fixed-qh-unaligned

: intr-qh  ( -- qh )  fixed-qh  ;
: low-qh   ( -- qh )  intr-qh /qh +  ;
: full-qh  ( -- qh )  low-qh  /qh +  ;
: last-qh  ( -- qh )  full-qh /qh +  ;

: link-qhs  ( virt phys #qh -- )
   0  do					( virt phys )
      2dup swap >qh-phys l!			( virt phys )
      dup /qh + TYP_QH or 2 pick >hcqh-next le-l! ( virt phys )
      over /qh + 2 pick >qh-next l!		( virt phys )
      i 0=  if  0  else  over /qh -  then	( virt phys prev ) 
      2 pick >qh-prev l!			( virt phys )
      TERMINATE 2 pick >hcqh-elem le-l!		( virt phys )
      /qh + swap /qh + swap			( virt' phys' )
   loop  2drop 					( virt phys )
;
: fixup-fixed-qhs  ( -- )
   TERMINATE last-qh >hcqh-next le-l!
   0 last-qh >qh-next l!
;
: alloc-qhs  ( #qh -- )
   /qh * dup >r aligned16-alloc-map-in		( qh.u,v,p )  ( R: size )
   over r> erase				( qh.u,v,p )
   to fixed-qh-phys to fixed-qh to fixed-qh-unaligned
;
: alloc-fixed-qhs  ( -- )
   #fixed-qhs alloc-qhs				( qh.u,v,p )
   fixed-qh fixed-qh-phys #fixed-qhs link-qhs
   fixup-fixed-qhs
;

: init-framelist  ( -- )
   \ Allocate framelist
   /framelist /align4kb aligned-alloc		( unaligned virt )
   swap to framelist-unaligned			( virt )
   dup to framelist				( virt )
   /framelist true dma-map-in to framelist-phys	( )

   \ Initialize framelist
   #framelist 0  do  fixed-qh-phys TYP_QH or i framelist!  loop
;

: init-lists  ( -- )
   framelist 0=  if
      alloc-fixed-qhs
      init-framelist
   then
;

\ ---------------------------------------------------------------------------
\ Dynamically allocate QH and TDs all transactions.
\ ---------------------------------------------------------------------------

: link-tds  ( td.v td.p #td -- )
   0  do
      over >r					( td.v,p )  ( R: td )
      dup r@ >td-phys l!			( td.v,p )  ( R: td )
      /td +					( td.v,p' )  ( R: td )
      dup r@ >hctd-next le-l!			( td.v,p )  ( R: td )
      swap /td + tuck r> >td-next l!		( td.v',p )
   loop
   drop /td -					( td.v' )
   TERMINATE over >hctd-next le-l!		( td.v' )
   0 swap >td-next l!				( )
;
: link-qhtds  ( td.v td.p qh -- )
   >r						( td.v,p )  ( R: qh )
   dup TYP_TD or r@ >hcqh-elem le-l!		( td.v,p )  ( R: qh )
   over r@ >qh-elem l!				( td.v,p )  ( R: qh )
   r> >qh-#tds l@ link-tds			( )
;
: init-qh  ( qh.u,v,p size #tds -- )
   3 pick >qh-#tds l!				( qh.u,v,p size )
   2 pick >qh-size l!				( qh.u,v,p )
   over >qh-phys l!				( qh.u,v )
   >qh-unaligned l!				( )
;

: alloc-qhtds  ( #td -- qh td )
   dup >r /td * /qh + dup >r			( size )  ( R: #td size )
   aligned16-alloc-map-in			( qh.u,v,p )  ( R: #td size )
   over r@ erase				( qh.u,v,p )  ( R: #td )
   3dup r> r> init-qh				( qh.u,v,p )
   rot drop					( qh.v,p )
   over /qh + dup -rot				( qh td qh.p td )
   swap /qh +					( qh td td.v,p )
   3 pick link-qhtds				( qh td )
;

: free-qhtds  ( qh -- )
   dup >qh-unaligned l@ over >qh-phys l@ 2 pick >qh-size l@
   aligned16-free-map-out
;

: sync-qhtds  ( qh -- )
   dup >qh-phys l@ over >qh-size l@  dma-sync
;

: map-out-buf  ( td -- )
   dup >td-buf l@ over >td-pbuf l@ rot >td-/buf-all l@ hcd-map-out
;

\ ---------------------------------------------------------------------------
\ Transaction scheduling
\ ---------------------------------------------------------------------------

: insert-qh  ( qh head -- )
   >r						( qh )  ( R: head )
   \ Fixup the QH link pointers
   r@ >hcqh-next le-l@ over >hcqh-next le-l!	( qh )  ( R: head )
   dup >qh-phys l@ TYP_QH or r@ >hcqh-next le-l! ( qh )  ( R: head )

   \ Fixup the next QH's pointers
   dup r@ >qh-next l@ >qh-prev l!		( qh )  ( R: head )

   \ Fixup QH's pointers
   r@ >qh-next l@ over >qh-next l!		( qh )  ( R: head )
   r@ over >qh-prev l!				( qh )  ( R: head )

   \ Fixup head's pointers
   r> >qh-next l!				( )
;

\ Due to the fact that we have fixed QHs, an allocated QH will always be
\ in between two other QHs.
: remove-qh  ( qh -- )
   dup >qh-next l@ over >qh-prev l@ >qh-next l!
   dup >qh-prev l@ over >qh-next l@ >qh-prev l!
   dup >hcqh-next le-l@ swap >qh-prev l@ >hcqh-next le-l!
;

: insert-ctrl-qh  ( qh speed -- )
   TD_CTRL_LOW =  if  low-qh  else  full-qh  then
   insert-qh
;

: insert-bulk-qh  ( qh speed -- )  insert-ctrl-qh  ;

: insert-intr-qh  ( qh interval -- )  drop intr-qh insert-qh  ;

\ ---------------------------------------------------------------------------
\ Wait for a QH to be done and proocess any errors.
\ ---------------------------------------------------------------------------

defer process-hc-status
0 value timeout

: .td-error  ( stat -- )
   dup TD_STAT_STALLED  and  if  " Stalled; "            USB_ERR_STALL set-usb-error        then
   dup TD_STAT_DBUFERR  and  if  " Data Buffer Error; "  USB_ERR_DBUFERR set-usb-error      then
   dup TD_STAT_BABBLE   and  if  " Babble Detected; "    USB_ERR_BABBLE set-usb-error       then
   dup TD_STAT_CRCTIME  and  if  " CRC/Timeout Error; "  USB_ERR_CRC set-usb-error          then
   dup TD_STAT_BITSTUFF and  if  " Bitstuff Error; "     USB_ERR_BITSTUFFING set-usb-error  then
       TD_STAT_NAK      and  if  " NAK"                  USB_ERR_NAK set-usb-error          then
;

: qh-done?  ( qh -- done? )  >hcqh-elem le-l@  TERMINATE and  ;

: done?  ( qh -- error? )
   begin
      process-hc-status  usb-error  if
         true
      else
         dup sync-qhtds
         dup qh-done? ?dup 0=   if
            1 ms
	    timeout 1- dup to timeout 0=
         then
      then
   until

   ( qh ) dup qh-done? 0=  if
      " Timeout" USB_ERR_TIMEOUT set-usb-error
      TERMINATE over >hcqh-elem le-l!		\ Terminate QH
      sync-qhtds
      1 ms
   else
      drop
   then
   usb-error
;

: error?  ( td -- error? )
   false swap  begin				( error? td )
      dup >hctd-stat le-l@ TD_STAT_ANY_ERROR and ?dup  if
         .td-error
         2drop true 0				( error? stop )
      else					( error? td )
         >td-next l@				( error? td' )
      then
   ?dup 0=  until
;

: get-actual  ( td #td -- actual )
   0 -rot 0  ?do				( actual td )
      dup >hctd-stat le-l@ dup TD_STAT_ACTIVE and 0=  if
         TD_ACTUAL_MASK and                     ( actual td size-code )
         dup TD_NULL_DATA_SIZE =  if  drop 0  else  1+  then  ( actual td this-size )
         rot + swap				( actual' td )
      else  drop  then
      >td-next l@				( actual td' )
   loop  drop					( actual )
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
