purpose: Data structures and manuipulation routines for OHCI USB Controller
\ See license at end of file

hex
headers

\ XXX Isochronous is not supported in the current version of the OHCI driver

\ ---------------------------------------------------------------------------
\ Data structures for this implementation of the OHCI USB Driver include:
\   - hcca 		256 bytes defined by OCHI Spec for USB HC
\   - ed-control	pointer to the control ED list
\   - ed-bulk		pointer to the bulk ED list
\   - intr		internal array of interrupts (to complement the hcca)
\ ---------------------------------------------------------------------------

\ ---------------------------------------------------------------------------
\ HcHCCA as defined by the OHCI Spec; 256-byte aligned
\ ---------------------------------------------------------------------------

0 value intr			\ Software interrupt buffer
0 value hcca			\ Virtual address of HcHCCA
0 value hcca-unaligned		\ Unaligned virtual address of HcHCCA
0 value hcca-phys		\ Physical address of HcHCCA

\ HCCA
d# 32 constant #intr

struct  ( hcca )
#intr 4 * field >hcca-intr	\ Physical addresses of interrupt EDs
2 field >hcca-frame
2 field >hcca-pad
4 field >hcca-done		\ Physical addresses of done EDs
d# 120 field >hcca-reserved
constant /hcca

: hcca!  ( padr idx -- )  4 * hcca + le-l!  ;

: init-hcca  ( -- )
   \ Allocate hcca
   /hcca aligned256-alloc
   dup to hcca				\ Aligned address
   swap to hcca-unaligned		\ Unaligned address
   /hcca true dma-map-in to hcca-phys	\ Physical address

   \ Initialize hcca
   hcca /hcca erase
   hcca hcca-phys /hcca dma-push
;

\ ---------------------------------------------------------------------------
\ Internal interrupt list per >hcca-intr entry
\
\ XXX I can see how this can be expanded to >intr-head32ms, >intr-tail32ms,
\ XXX and so on, to support the various poll intervals.  See comment on
\ XXX interrupt scheduling below.
\ ---------------------------------------------------------------------------
struct 				\ An entry of intr
   4 field >intr-head		\ Virtual address of interrupt head
   4 field >intr-tail		\ Virtual address of interrupt tail
   4 field >iso-head		\ Virtual address of isochronous head
   4 field >iso-tail		\ Virtual address of isochronous tail
dup constant /intr-entry
#intr * constant /intr

: init-intr  ( -- )
   /intr alloc-mem dup to intr		\ Allocate intr
   /intr erase				\ Initialize intr
;

: 'intr  ( idx -- adr )   /intr-entry * intr +  ;
: intr-head@  ( idx -- adr )  'intr >intr-head l@  ;
: intr-head!  ( adr idx -- )  'intr >intr-head l!  ;
: intr-tail@  ( idx -- adr )  'intr >intr-tail l@  ;
: intr-tail!  ( adr idx -- )  'intr >intr-tail l!  ;
: iso-head@   ( idx -- adr )  'intr >iso-head l@   ;
: iso-head!   ( adr idx -- )  'intr >iso-head l!   ;
: iso-tail@   ( idx -- adr )  'intr >iso-tail l@   ;
: iso-tail!   ( adr idx -- )  'intr >iso-tail l!   ;

\ ---------------------------------------------------------------------------
\ Endpoint descriptor (ED) as defined by the OHCI Spec; 16-byte aligned
\ ---------------------------------------------------------------------------

\ XXX If we add ed-control-tail & ed-bulk-tail, then insert-* does not have
\ XXX to disable the function, we need to skip tail until insert is done.

0 value ed-control		\ Virtual address of head of control ED list
0 value ed-bulk			\ Virtual address of head of bulk ED list

struct				\ Beginning of ED
4 field >hced-control		\ ED control info
4 field >hced-tdtail		\ Physical address of TD tail
4 field >hced-tdhead		\ Physical address of TD head
4 field >hced-next		\ Physical address of next ED
dup constant /hced
				\ Driver specific fields
4 field >ed-phys		\ Physical address of HC ED
4 field >ed-next		\ Pointer to the next endpoint
4 field >ed-prev		\ Pointer to the previous endpoint
4 field >ed-unaligned		\ Unaligned virtual address of the ED
4 field >ed-size		\ Size of EDs+TDs
d# 32 round-up			\ Multiple of 32 bytes
				\ 32 bytes because there are cases where
				\ EDs and TDs are allocated together
dup constant /ed		\ Size of each ed
#intr * constant /eds		\ Size of all eds allocated at a time

\ >hced-control constants
0000 constant ED_DIR_TD
0800 constant ED_DIR_OUT
1000 constant ED_DIR_IN
1800 constant ED_DIR_MASK

0000 constant ED_SPEED_FULL
2000 constant ED_SPEED_LO
2000 constant ED_SPEED_MASK

0000 constant ED_SKIP_OFF
4000 constant ED_SKIP_ON
4000 constant ED_SKIP_MASK

0000 constant ED_FORMAT_G
8000 constant ED_FORMAT_I
8000 constant ED_FORMAT_MASK

0000 constant ED_TOGGLE_DATA0
0002 constant ED_TOGGLE_DATA1
0002 constant ED_TOGGLE_MASK

0001 constant ED_HALTED

: ed-data>di-data  ( n -- n' )  ED_TOGGLE_MASK and  if  1  else  0  then  ;
: di-data>ed-data  ( n -- n' )  if  ED_TOGGLE_DATA1  else  ED_TOGGLE_DATA0  then  ;

: (set-skip)  ( ed skip-bit -- )
   >r
   dup >hced-control dup le-l@
   ED_SKIP_MASK invert and r> or
   swap le-l!
   dup >ed-phys l@ /hced dma-push
;
: ed-set-skip    ( ed -- )  ED_SKIP_ON  (set-skip)  ;
: ed-unset-skip  ( ed -- )  ED_SKIP_OFF (set-skip)  ;

\ ---------------------------------------------------------------------------
\ Transfer Descriptor (TD) as defined by the OHCI Spec:
\ general TDs are 16-byte aligned; isochronous TDs are 32-byte aligned.
\ ---------------------------------------------------------------------------

struct				\ Beginning of General TD fields
4 field >hctd-control		\ TD control info
4 field >hctd-cbp		\ Physical address of current buffer pointer
4 field >hctd-next		\ physical address of next TD
4 field >hctd-be		\ physical address of buffer end
dup constant /gtd
				\ Isochronous TD fields
2 field >hctd-offset0		\ Offset 0 / PSW 0
2 field >hctd-offset1		\ Offset 1 / PSW 1
2 field >hctd-offset2		\ Offset 2 / PSW 2
2 field >hctd-offset3		\ Offset 3 / PSW 3
2 field >hctd-offset4		\ Offset 4 / PSW 4
2 field >hctd-offset5		\ Offset 5 / PSW 5
2 field >hctd-offset6		\ Offset 6 / PSW 6
2 field >hctd-offset7		\ Offset 7 / PSW 7
dup constant /itd
				\ Driver specific fields
4 field >td-phys		\ Physical address of HC TD
4 field >td-next		\ Virtual address of next TD
4 field >td-cbp			\ Virtual address of current buffer pointer
4 field >td-pcbp		\ Physical address of current buffer pointer
4 field >td-/cbp-all		\ Buffer length (size of the entire buffer)
				\ For bulk and intr TDs
d# 32 round-up			\ Multiple of 32 bytes
constant /td

\ >hctd-control constants
0004.0000 constant TD_ROUND_ON
0000.0000 constant TD_ROUND_ERR
0004.0000 constant TD_ROUND_MASK

0000.0000 constant TD_DIR_SETUP
0008.0000 constant TD_DIR_OUT
0010.0000 constant TD_DIR_IN
0018.0000 constant TD_DIR_MASK

00c0.0000 constant TD_INTR_MIN
00e0.0000 constant TD_INTR_OFF
00e0.0000 constant TD_INTR_MASK

0000.0000 constant TD_TOGGLE_USE_ED
0200.0000 constant TD_TOGGLE_USE_LSB0
0300.0000 constant TD_TOGGLE_USE_LSB1
0100.0000 constant TD_TOGGLE_MASK
0c00.0000 constant TD_ERR_CNT_MASK

0000.0000 constant TD_CC_NOERROR
1000.0000 constant TD_CC_CRC
2000.0000 constant TD_CC_BITSTUFFING
3000.0000 constant TD_CC_DATATOGGLEMISMATCH
4000.0000 constant TD_CC_STALL
5000.0000 constant TD_CC_DEVICENOTRESPONDING
6000.0000 constant TD_CC_PIDCHECKFAILURE
7000.0000 constant TD_CC_UNEXPECTEDPID
8000.0000 constant TD_CC_DATAOVERRUN
9000.0000 constant TD_CC_DATAUNDERRUN
c000.0000 constant TD_CC_BUFFEROVERRUN
d000.0000 constant TD_CC_BUFFERUNDERRUN
f000.0000 constant TD_CC_NOTACCESSED
f000.0000 constant TD_CC_MASK

: td-data>di-data  ( n -- n' )  TD_TOGGLE_MASK and  if  1  else  0  then  ;
: di-data>td-data  ( n -- n' )  if  TD_TOGGLE_USE_LSB1  else  TD_TOGGLE_USE_LSB0  then  ;

\ ---------------------------------------------------------------------------

: init-struct  ( -- )
   init-struct
   0 to ed-control 0 to ed-bulk
   init-hcca
   init-intr
;

\ ---------------------------------------------------------------------------
\ ED and TDs for bulk, control and interrupt operations.
\ ED and its list of TDs are allocated as needed.
\ ---------------------------------------------------------------------------

: init-ed  ( ed.u,v,p len -- )
   2 pick >ed-size l!			( ed.u,v,p )
   over >ed-phys l!			( ed,u,v )
   >ed-unaligned l!			( )
;

: link-tds  ( td.v td.p #tds -- )
   1- 0  ?do				( td.v td.p )
      2dup swap >td-phys l!		( td.v td.p )
      /td + tuck over >hctd-next le-l!	( td.p' td.v )
      dup /td + tuck swap		( td.p td.v' td.v' td.v )
      >td-next l!			( td.p td.v )
      swap				( td.v td.p )
   loop
   swap >td-phys l!			( )
;
: link-edtd  ( td.p #tds ed -- )
   >r					( td.p #tds )  ( R: ed )
   1- /td * over +			( td.p ptail )  ( R: ed )
   r@ >hced-tdtail le-l!		( td.p )  ( R: ed )
   r> >hced-tdhead le-l!		( )
;
: link-edtds  ( td.v td.p #tds ed -- )
   >r 2dup r> link-edtd			( td.v td.p #tds )	\ Link ED to TD
   link-tds				( )			\ Link TDs
;
: alloc-edtds  ( #tds -- ed td )
   dup >r /td * /ed + dup >r		( len )  ( R: #tds len )
   aligned32-alloc-map-in		( ed.u,v,p )  ( R: #tds len )
   over r@ erase			( ed.u,v,p )  ( R: #tds len )
   3dup r> init-ed			( ed.u,v,p )  ( R: #tds )
   rot drop				( ed.v,p )  ( R: #tds )
   over /ed + dup -rot			( ed td ed.p td.v )  ( R: #tds )
   swap /ed + 				( ed td td.v td.p )  ( R: #tds )
   r> 4 pick link-edtds			( ed td )
;
: free-edtds  ( ed -- )
   >r					( R: ed )
   r@ >ed-unaligned l@			( ed.u )  ( R: ed )
   r@ dup >ed-phys l@			( ed.u,v,p )  ( R: ed )
   r> >ed-size l@			( ed.u,v,p size )
   aligned32-free-map-out		( )
;
: push-edtds  ( ed -- )
   dup >ed-phys l@			( ed.v,p )
   over >ed-size l@			( ed.v,p len )
   dma-push				( )
;
: pull-edtds  ( ed -- )
   dup >ed-phys l@			( ed.v,p )
   over >ed-size l@			( ed.v,p len )
   dma-pull				( )
;
: map-out-cbp  ( td -- )
   dup >td-cbp l@ over >td-pcbp l@ rot >td-/cbp-all l@ hcd-map-out
;

\ ---------------------------------------------------------------------------
\ Control scheduling
\ ---------------------------------------------------------------------------

: fixup-ed-next-prev  ( ed -- ed )
   dup >ed-prev l@ ?dup  if  over >ed-next l@ swap >ed-next l!  then
   dup >ed-next l@ ?dup  if  over >ed-prev l@ swap >ed-prev l!  then
;

: insert-ed  ( new-ed old-ed -- )
   ?dup 0=  if  drop exit  then		\ No old-ed, done
   2dup >ed-prev l!			\ old-ed's prev is new-ed
   2dup swap >ed-next l!		\ new-ed's next is old-ed
   >ed-phys l@ swap >hced-next le-l!	\ new-ed's hced-next is old-ed's phys
;

: insert-control-ed  ( ed -- )
   dup ed-control insert-ed
   to ed-control
;
: remove-control-ed  ( ed -- )
   fixup-ed-next-prev			( ed )
   dup ed-control =  if  >ed-next l@ to ed-control  else  drop  then
;

\ ---------------------------------------------------------------------------
\ Bulk scheduling
\ ---------------------------------------------------------------------------

: insert-bulk-ed  ( ed -- )
   dup ed-bulk insert-ed
   to ed-bulk
;
: remove-bulk-ed  ( ed -- )
   fixup-ed-next-prev			( ed )
   dup ed-bulk =  if  >ed-next l@ to ed-bulk  else  drop  then
;

\ ---------------------------------------------------------------------------
\ Interrupt scheduling
\ Schedule interrupt at the rate min(interval,2**x).
\
\ XXX Need to determines which scheduling queue for that rate has the smallest
\ committed bandwidth.
\
\ XXX To really implement the various poll intervals, the simplistic way is
\ XXX to have 32 dummy EDs for 1ms interval; 16 dummy EDs for 2ms interval;
\ XXX 8 dummy EDs for 4ms interval; 4 dummy EDs for 8ms interval; 
\ XXX 2 dummy EDs for 16ms interval; and, 1 dummy ED for 32ms interval.
\ XXX Then you link to the end of the lists of EDs for each interval.  Ughhh!
\
\ XXX For now, just implement fixed poll interval.
\
\ XXX On further thought, since we're polling the intr pipeline from the
\ XXX device driver, the driver driver can poll the intr at the interval
\ XXX specified.  And thus, the need to fully implement poll intervals at
\ XXX the HCD level is redundant.
\ ---------------------------------------------------------------------------

8 constant intr-interval

: (insert-intr-ed)  ( ed idx -- )
   dup >r				( ed idx )  ( R: idx )
   intr-tail@ ?dup 0=  if		( ed )  ( R: idx )
      dup r@ intr-head!			( ed )  ( R: idx )
      dup >ed-phys l@ r@ hcca!		( ed )  ( R: idx )
   else					( ed ted )  ( R: idx )
      2dup >ed-next l!			( ed ted )  ( R: idx )
      over >ed-phys l@ over >hced-next le-l!	( ed ted )  ( R: idx )
      over >ed-prev l!			( ed )  ( R: idx )
   then
   r@ iso-head@ over >ed-next l!	( ed )  ( R: idx )
   r> intr-tail!			( )
;
: insert-intr-ed  ( ed interval -- )
   drop
   #intr 0  do  dup i (insert-intr-ed)  intr-interval +loop  drop
;

: (remove-intr-ed)  ( ed idx -- )
   >r					( ed )  ( R: idx )
   fixup-ed-next-prev			( ed )  ( R: idx )
   r@ intr-head@ over =  if		( ed )  ( R: idx )
      dup >ed-next l@ dup r@ intr-head!	( ed ped )  ( R: idx )
      dup  if  >ed-phys l@  then  r@ hcca!
      					( ed )  ( R: idx )
   then
   r@ intr-tail@ over =  if		( ed )  ( R: idx )
      dup >ed-prev l@ r@ intr-tail!	( ed )  ( R: idx )
   then
   r> 2drop
;
: remove-intr-ed  ( ed -- )
   #intr 0  do  dup i (remove-intr-ed)  intr-interval +loop  drop
;

\ ---------------------------------------------------------------------------
\ Wait for an ED to be done and process any errors.
\
\ When done? returns no error found yet, the caller should should if errors
\ were found in the TDs.
\ ---------------------------------------------------------------------------

defer process-hc-status

0 value timeout

: .td-error  ( cc -- )
   case
      TD_CC_CRC			of  " CRC"			USB_ERR_CRC  endof
      TD_CC_BITSTUFFING		of  " Bit Stuffing"		USB_ERR_BITSTUFFING  endof
      TD_CC_DATATOGGLEMISMATCH	of  " Data Toggle Mismatch"	USB_ERR_DATATOGGLEMISMATCH  endof
      TD_CC_STALL		of  " Stall"			USB_ERR_STALL  endof
      TD_CC_DEVICENOTRESPONDING	of  " Device Not Responding"	USB_ERR_DEVICENOTRESPONDING  endof
      TD_CC_PIDCHECKFAILURE	of  " PID Check Failure"	USB_ERR_PIDCHECKFAILURE  endof
      TD_CC_UNEXPECTEDPID	of  " Unexpected PID"		USB_ERR_UNEXPECTEDPIC  endof
      TD_CC_DATAOVERRUN		of  " Data Overrun"		USB_ERR_DATAOVERRUN  endof
      TD_CC_DATAUNDERRUN	of  " Data Underrun"		USB_ERR_DATAUNDERRUN  endof
      TD_CC_BUFFEROVERRUN	of  " Buffer Overrun"		USB_ERR_BUFFEROVERRUN  endof
      TD_CC_BUFFERUNDERRUN	of  " Buffer Underrun"		USB_ERR_BUFFERUNDERRUN  endof
      TD_CC_NOTACCESSED		of  " Not Accessed"		USB_ERR_NOTACCESSED  endof
      ( default )  " Unknown Error" rot USB_ERR_UNKNOWN swap
   endcase
   set-usb-error
;

: error?  ( td -- usberr )
   begin
      dup >td-next l@  if		\ Process a real TD
         dup >hctd-control le-l@ TD_CC_MASK and  ?dup  if
            .td-error  drop 0		\ Error found in TD
         else
            >td-next l@			\ TD's ok, examine the next TD
         then
      else				\ Don't need to process last dummy TD
         drop 0
      then
   ?dup 0=  until
   usb-error
;

: ed-done?  ( ed -- done? )
   dup  >hced-tdhead le-l@ dup ED_HALTED and	( ed head halted? )
   swap h# ffff.fff0 and			( ed halted? head )
   rot >hced-tdtail le-l@ h# ffff.fff0 and =	( halted? head=tail? )
   or						( done? )
;

: done?  ( ed -- error? )
   begin
      process-hc-status
      dup pull-edtds
      dup ed-done? ?dup 0=  if
         1 ms
	 timeout 1- dup to timeout 0=
      then
   until
   ed-done? 0=  if  " Timeout" USB_ERR_TIMEOUT set-usb-error  then
   usb-error
;

: get-actual  ( td -- actual )
   dup >hctd-cbp le-l@ ?dup  if
      swap >td-pcbp l@ -
   else
      dup >hctd-be le-l@ swap >td-pcbp l@ - 1+
   then
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
