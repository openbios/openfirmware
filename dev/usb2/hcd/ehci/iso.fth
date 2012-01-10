purpose: EHCI USB Controller Isochronous Pipes Transaction Processing
\ See license at end of file

hex
headers

\ XXX Need to implement isochronous OUT
\ XXX Need to implement siTD for devices behind a hub

1 constant ISO_LAG              \ # of frames to skip when inserting new iTDs

\ ---------------------------------------------------------------------------
\ Example device driver usage:
\   init-iso-in      \ To allocate and initialize isochronous data structures
\   begin-iso-in     \ To link the framelist and iTDs
\   get-iso-in       \ To read streamed data
\   end-iso-in       \ To deallocate data structures (e.g., during close)
\   restart-iso-in   \ To restart after a long lapse in order to get fresh data
\ ---------------------------------------------------------------------------

\ ---------------------------------------------------------------------------
\ Internal isochronus IN variables
\ ---------------------------------------------------------------------------

0 instance value iso-in-itd
0 instance value iso-in-itd-phys
0 instance value iso-in-itd-unaligned
0 instance value iso-in-#itd

0 instance value iso-in-buf
0 instance value iso-in-buf-phys
0 instance value iso-in-buf-unaligned
0 instance value iso-in-/buf

0 instance value iso-in-pipe
0 instance value iso-in-/payload
0 instance value iso-in-mult
0 instance value iso-in-interval

0 instance value iso-in-cur-itd       \ Next IN iTD to process
0 instance value iso-in-frame         \ Last framelist[] used by the IN iTDs
0 instance value iso-in-#uframe       \ Total # of micro-frames in the IN iTDs
0 instance value iso-in-uframe-cnt    \ Micro-frame count in processing iTDs

\ ---------------------------------------------------------------------------
\ Isochronous Transaction Descriptor (iTD) as defined by the EHCI Spec; 32-byte aligned
\ ---------------------------------------------------------------------------

0 instance value itd-struct

4 8 * constant /itd-xstat
4 7 * constant /itd-bptr
struct
   \ DMA fields
   4          field >itd-link         \ Next iTD or QH pointer
   /itd-xstat field >itd-xstat        \ iTD Transaction Status & Control List
   /itd-bptr  field >itd-bptr         \ iTD Buffer Page Pointer List
   /itd-bptr  field >itd-xptrs        \ 64-bit buffer pointer extensions
dup constant /itd-sync
   \ Non-dma fields
   /n field >itd-phys                 \ iTD's physical address
   /n field >itd-buf                  \ Virtual address of the first >itd-bptr
   /n field >itd-frame                \ Index into framelist where iTD resides
   /itd-xstat field >itd-xstat-copy   \ original >itd-xstat for easy restart
d# 32 round-up
constant /itd-struct

: set-itd-struct  ( itd# -- )  /itd-struct * iso-in-itd + to itd-struct  ;

h# 7000.0000 constant ITD_STATUS
h# 8000.0000 constant ITD_ACTIVE
h# 4000.0000 constant ITD_ERR_OVERRUN
h# 2000.0000 constant ITD_ERR_BABBLE
h# 1000.0000 constant ITD_ERR_CRC
h# 0000.0800 constant ITD_IN
h# 0000.0000 constant ITD_OUT

: alloc-itd  ( #itd -- unaligned-virt aligned-virt phys )
   /itd-struct * dup >r aligned32-alloc-map-in  ( unalign virt phys )  ( R: /itd )
   over r> erase
;
: free-itd  ( -- )
   iso-in-itd-unaligned iso-in-itd iso-in-itd-phys
   iso-in-#itd /itd-struct * aligned32-free-map-out
;

: copy-itd-xstat     ( -- )
   itd-struct dup >itd-xstat swap >itd-xstat-copy /itd-xstat move  
; 
: restore-itd-xstat  ( -- )
   TERMINATE itd-struct >itd-link le-l!
   itd-struct dup >itd-xstat-copy swap >itd-xstat /itd-xstat move  
; 

0 value pbuf       \ Next physical data buffer address
0 value vbuf       \ Next virtual data buffer address
0 value rlen       \ Remaining data len
0 value tlen       \ Transaction length

: init-itd-xstat  ( -- )
   pbuf h# fff and                    ( offset )
   8 0  do                            ( offset )
      rlen 0 max  tlen  min ?dup  if  ( offset len )
         d# 16 <<  ITD_ACTIVE or      ( offset xctrl )
         over or  itd-struct >itd-xstat 4 i * + le-l!     ( offset )
         tlen +	  	       	      ( offset )
         rlen tlen - to rlen
      then
   loop  drop
   copy-itd-xstat
;
: init-itd  ( itd# -- )
   dup set-itd-struct
   /itd-struct * iso-in-itd-phys + itd-struct >itd-phys !
   TERMINATE  itd-struct >itd-link le-l!
   vbuf pbuf h# fff and - itd-struct >itd-buf !
   init-itd-xstat
   pbuf dup h# fff and tlen 8 * + d# 12 >> 7 and 1+  0  do    ( pbuf )
      dup h# ffff.f000 and itd-struct >itd-bptr 4 i * + le-l! ( pbuf )
      h# 1000 +                                               ( pbuf' )
   loop  drop
   tlen 8 * dup pbuf +  to pbuf
                vbuf +  to vbuf
   itd-struct >itd-bptr dup     le-l@  target or  iso-in-pipe  8 << or  swap le-l!
   itd-struct >itd-bptr 4 + dup le-l@  ITD_IN or  iso-in-/payload   or  swap le-l!
   itd-struct >itd-bptr 8 + dup le-l@  iso-in-mult  or                  swap le-l!
;

: free-iso  ( -- )
   iso-in-itd 0=  if  exit  then
   free-itd
   iso-in-buf iso-in-buf-phys iso-in-/buf  dma-map-out
   iso-in-buf-unaligned iso-in-/buf h# 1000  aligned-free
   0 to iso-in-buf
;
: (init-iso-in)  ( #uframe pipe interval -- )
   1 swap 1- << to iso-in-interval	       ( #uframe pipe )
   dup to iso-in-pipe  			       ( #uframe pipe )
   over to iso-in-#uframe                      ( #uframe pipe )
   target di-maxpayload@                       ( #uframe max )
   dup d# 11 >> 3 and 1+ dup to iso-in-mult    ( #uframe mult max )
   swap h# 7ff and dup to iso-in-/payload      ( #uframe mult xlen )
   * * dup to iso-in-/buf                      ( #uframe /buf )
   dup h# 1000 aligned-alloc                   ( /buf buf-unalign buf )
   tuck to iso-in-buf  to iso-in-buf-unaligned ( /buf buf )
   swap true dma-map-in  to iso-in-buf-phys    ( )
;

external
: init-iso-in  ( #uframe pipe interval -- )
   \ Round up #uframe to multiple of 8
   rot 8 round-up -rot

   \ Initialize the iso in variables and allocate data buffers
   (init-iso-in)

   \ Setup temporary variables for init-itd
   iso-in-/payload iso-in-mult * to tlen      \ Transaction length
   iso-in-buf-phys to pbuf    	    	       \ Data buffer physical addr
   iso-in-buf      to vbuf                     \ Data buffer virtual addr
   iso-in-/buf     to rlen		       \ Remaining data buffer len

   \ Allocate and initialize the iTDs
   iso-in-#uframe 8 / dup to iso-in-#itd       ( #itd )
   dup alloc-itd  to iso-in-itd-phys to iso-in-itd to iso-in-itd-unaligned  ( #itd )
   ( #itd )  0  do  i init-itd  loop
;
headers

: framelist@   ( idx -- n )  4 * framelist +  le-l@  ;
: framelist@!  ( itd-phys idx -- )
   dup >r framelist@ dup TERMINATE and  if  \ Nothing in the entry
      drop                                  ( itd-phys )  ( R: idx )
   else					    \ Link and replace the entry
      itd-struct >itd-link le-l!	    ( itd-phys )  ( R: idx )
   then
   itd-struct over /itd-sync dma-push       ( itd-phys )  ( R: idx )
   TYP_ITD or r> framelist!                 ( )
;

0 value cur-fidx
: interval+       ( frame -- frame' )  iso-in-interval + h# 3ff and  ;
: cur-fidx+       ( -- )       cur-fidx interval+  to cur-fidx  ;
: get-cur-fidx    ( -- fidx )  frindex@ 2 + ISO_LAG + 3 >> h# 3ff and  ;

external
: begin-iso-in  ( -- )
   \ Find the next frame and start putting into the framelist and link
   \ to any existing qhs
   0 to iso-in-cur-itd
   get-cur-fidx to cur-fidx
   iso-in-#itd 0  do
      i set-itd-struct
      itd-struct >itd-phys @ cur-fidx framelist@!  \ Link into framelist
      cur-fidx itd-struct >itd-frame !             \ Save itd's framelist index
      cur-fidx to iso-in-frame	     		   \ Update last frame in iTDs
      cur-fidx+		                	   \ Next framelist index
   loop
   #intr #iso or  0=  if  enable-periodic  then
   #iso++
;

headers
: wait-frame-safe  ( idx -- )
   3 <<
   begin
      frindex@ h# ffff.fff8 and over <>
   until  drop
;
: restore-framelist  ( -- )
   \ Remove an iTD from the framelist
   itd-struct >itd-link le-l@  itd-struct >itd-frame @  framelist!
;

: restart-itd  ( -- )
   \ Restore the link for the framelist[itd.frame]
   restore-framelist

   \ Init link and restore the transaction fields in the iTD
   restore-itd-xstat

   \ Put the iTD in framelist[lastframe+interval]
   iso-in-frame interval+ dup to iso-in-frame  dup itd-struct >itd-frame !
   itd-struct >itd-phys @ swap  framelist@!
;

: .itd-error  ( xstat -- )
   ITD_STATUS and  ?dup 0=  if  exit  then
   dup ITD_ERR_OVERRUN and  if  " Data Overrun; "        USB_ERR_DATAOVERRUN  set-usb-error  then
   dup ITD_ERR_BABBLE  and  if  " Babble Detected; "     USB_ERR_BABBLE       set-usb-error  then
       ITD_ERR_CRC     and  if  " CRC/Timeout/Bad PID; " USB_ERR_CRC          set-usb-error  then
;

: cur-in-itd++  ( -- )
   iso-in-cur-itd 1+ dup iso-in-#itd =  if  drop 0  then
   to iso-in-cur-itd
;

external
\ Process the iTDs.  Returns false when the microframe is not ready.
\ Otherwise copy data into adr,len and return the actual len and status nibble.
\
\ When the last uframe in the iTD is processed, inc cur-itd and restart-itd
\
: get-iso-in  ( adr len -- false | actual error? true )
   clear-usb-error
   iso-in-cur-itd set-itd-struct              ( adr len )
   itd-struct >itd-frame @  wait-frame-safe   ( adr len )
   itd-struct dup >itd-phys @ /itd-sync dma-pull
   iso-in-uframe-cnt 7 and                    ( adr len uframe# )
   4 * itd-struct >itd-xstat + le-l@          ( adr len xstat )
   dup ITD_ACTIVE and  if  3drop false exit  then    \ Not done yet
   dup >r .itd-error                          ( adr len xstat )  ( R: xstat )
   r@ h# 7fff and                             ( adr len buf-offset )  ( R: xstat )
   itd-struct >itd-buf @ + -rot               ( buf adr len )  ( R: xstat )
   
   r> d# 16 >> h# fff and min dup >r  move    ( )  ( R: actual )
   r> usb-error true                          ( actual error? true )
   iso-in-uframe-cnt 1+ dup to iso-in-uframe-cnt ( actual error? true uframe# )
   7 and 0=  if  restart-itd cur-in-itd++  then  ( actual error? true )
;

: end-iso-in  ( -- )
   \ Remove itds from the framelist
   iso-in-#itd  0  do
      i set-itd-struct
      itd-struct >itd-frame @ wait-frame-safe
      restore-framelist
   loop  1 ms

   #iso--
   #intr #iso or  0=  if  disable-periodic  then
;

: restart-iso-in  ( -- )
   end-iso-in

   \ Restore fields in the iTD
   iso-in-#itd  0  do
      i set-itd-struct
      restore-itd-xstat
   loop

   begin-iso-in
;

headers
: (end-extra)  ( -- )
   (end-extra)
   iso-in-itd 0=  if  exit  then
   end-iso-in
   free-iso
;
' (end-extra) to end-extra

[ifndef] notdef
\ Debug aids
: sys-ldump  ( adr len -- )  " ldump" evaluate  ;
: .itd  ( -- )
   iso-in-itd  iso-in-#itd /itd-struct *  sys-ldump
;
: .xstat  ( -- )
   iso-in-#itd 0  do
      i set-itd-struct
      itd-struct >itd-xstat /itd-xstat sys-ldump
   loop
;
\ Debug aids for video streaming only (and only if ITD_ACTIVE are all 0s)
0 value tln
0 value tframe
: push-decimal  ( -- )  " push-decimal" evaluate  ;
: tlen+  ( len -- )  dup  if  h# c -  then  tln + to tln  ;
: tframe++  ( -- )  tframe 1+ to tframe  ;
: 0vid  ( -- )  0 to tln  0 to tframe  ;
: .tlen  ( -- )  tframe push-decimal (.) type pop-base ." :" tln u. cr  ;
: .vid  ( -- )
   0vid
   iso-in-#itd 0  do
      i set-itd-struct
      8 0  do
         itd-struct >itd-xstat i la+ le-l@          ( xstat )
         dup d# 16 >> h# fff and                    ( xstat len )
         dup tlen+ tframe++  if                     ( xstat )
            h# 7fff and itd-struct >itd-buf @ + ca1+ c@
            dup u. 2 and  if  .tlen 0vid  then
         else
            drop
         then
      loop
   loop
   .tlen
;
[then]

\ LICENSE_BEGIN
\ Copyright (c) 2011 FirmWorks
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

