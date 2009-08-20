\ See license at end of file
purpose: Bus-mastering DMA support for IDE driver

\ The basic programming model for bus-mastering IDE is standardized,
\ but some of the initialization differs from chip to chip.  The
\ first part of this file is generic and the latter part has some
\ case statements for chip-specific code sequences.

8 to dor-magic

c8 constant dma-read-cmd
ca constant dma-write-cmd

0 value dt-virtual
0 value dt-physical
0 value bm-regs

\ The DMA registers for the primary   channel are at 0, 2, and 4
\ The DMA registers for the secondary channel are at 8, a, and c
: >bm-reg  ( offset -- adr )  bm-regs +  log-drive 2 >  if  8 +  then  ;

: dma-cmd@   ( -- b )  0 >bm-reg rb@  ;
: dma-cmd!   ( b -- )  0 >bm-reg rb!  ;
: dma-stat@  ( -- b )  2 >bm-reg rb@  ;
: dma-stat!  ( b -- )  2 >bm-reg rb!  ;
: dma-dt@    ( -- l )  4 >bm-reg rl@  ;
: dma-dt!    ( l -- )  4 >bm-reg rl!  ;

: le-w!  ( w a -- )  >r wbsplit r@ ca1+ c! r> c!  ; 
: le-l!  ( l a -- )  >r lwsplit r@ wa1+ le-w! r> le-w!  ; 

: set-dma  ( adr len -- )
   h# 8000.0000 or  dt-virtual 4 +  le-l!
   dt-virtual le-l!
   dt-virtual dt-physical 8  " dma-sync" $call-parent
   dt-physical dma-dt!
   dma-stat@ dma-stat!   \ Clear old errors
;

: dma-wait  ( ms -- timeout? )
   0  do
      1 ms
      dma-stat@  dup 1 and 0=  swap 2 and  or  if
         false unloop exit
      then
   loop
   true
;

\ Sense and clear errors.  The bit masked by 04 is read-clear and means
\ that the interrupt is asserted.  The bit masked by 02 is read-clear and
\ means that an error has occurred.  Writing the current value back to the
\ register will clear whichever of those bits is active.
: dma-error?  ( -- flag )  dma-stat@ dup dma-stat!  2 and 0<>  ;

: dma-interrupt?  ( -- flag )  dma-stat@ 4 and ;

: dma-begin  ( dma-adr #blks direction -- dma-adr phys #blks )
   dma-cmd!                             ( dma-adr #blks )
   2dup /block@ * true " dma-map-in" $call-parent swap  ( adr phys #blks )
   2dup /block@ *  set-dma		( adr phys #blks )
   dma-cmd@ 1 or dma-cmd!               ( adr phys #blks )
;
: dma-end  ( adr phys #blks -- actual# )
   d# 500 dma-wait  if                         ( adr phys #blks )
      3drop 0 exit
   then                                        ( adr phys #blks )
   0 dma-cmd!                                  ( adr phys #blks )
   dma-interrupt?  if                          ( adr phys #blks )
      r-csr@ drop			\ Clear interrupt in drive
      dma-stat@ h# f0 and 4 or dma-stat!       ( adr phys #blks )
   then                                        ( adr phys #blks )

   dma-error?  if  0  else  dup  then  >r      ( adr phys #blks r: actual )

   /block@ * " dma-map-out" $call-parent       ( r: actual )

   r>                                          ( actual# )
;

: dma-rblocks  ( adr #blks -- actual#blks )
   8 dma-begin             ( adr phys #blks )
   dma-read-cmd r-csr!     ( adr phys #blks )
   dma-end                 ( actual#blks )
;

: dma-wblocks  ( adr #blks -- actual#blks )
   0 dma-begin             ( adr phys #blks )
   dma-write-cmd r-csr!    ( adr phys #blks )
   dma-end                 ( actual#blks )
;

: vendor-id  ( -- w )  my-space " config-w@" $call-parent  ;

h# 10ad constant symphony
h# 100b constant national
h# 10b8 constant acer
h# 10b9 constant acer1

: my-b@  ( offset -- value )  my-space +  " config-b@" $call-parent  ;
: my-b!  ( value offset -- )  my-space +  " config-b!" $call-parent  ;

: my-w@  ( offset -- value )  my-space +  " config-w@" $call-parent  ;
: my-w!  ( value offset -- )  my-space +  " config-w!" $call-parent  ;

\ During programmed I/O disk access, the Symphony/Winbond chip does not
\ handle accesses to odd-address ISA ports properly.  If such an
\ access occurs between the first and last programmed-I/O accesses
\ to the IDE data port, the data returned will be bus noise instead
\ of the actual data.  Sometimes it will return the last data that was
\ written to an odd-addressed port, and sometimes that data will have
\ decayed to ff.  It depends on the time elapsed since the last
\ write and the temperature.

: sl-start-hack  ( -- )  " disable-interrupts" eval  ;
: sl-end-hack    ( -- )  r-dor@ drop  " enable-interrupts" eval  ;
: open-pio  ( -- )
   vendor-id  symphony =  if
      ['] sl-start-hack to pio-start-hack
      ['] sl-end-hack   to pio-end-hack
   then
;

: drive-mask  ( -- mask )  1 log-drive 4 + lshift  ;

: (set-drive-cfg)  ( -- )
   \ Indicate that the drive is DMA-capable
   \ (We just assume that it is.  This means that we can't support
   \ ancient drives, but Oh Well.)
   dma-stat@  1  drive 5 +  lshift or  dma-stat!

   vendor-id  case
      national  of
         \ Set IDE prefetch buffer mode or ATAPI buffer mode
         h# 40 my-b@  drive-mask                        ( old mask )
         atapi-drive?@  if  or  else  invert and  then  ( new-value )
         h# 40 my-b!

         \ Set IRQ masks and buffer bypass modes
         h# 33  h# 41 my-b!

         \ Enable both pre-fetch buffers (03),
         \ use DMARQ/ACK mode for all drives (f0)
\         h# 42 my-b@  drive-mask or  3 or  h# 42 my-b!
         h# 42 my-b@  h# f3 or  h# 42 my-b!
      endof
   endcase
;
' (set-drive-cfg) to set-drive-cfg

: init-acer  ( -- )
   \ Now you might think that it would be proper to turn on bit 1
   \ of config register 50 at this point. Afterall, the book says
   \ this is how you turn on the IDE function. Well, if you do,
   \ you will regret it the rest of your life. This is an evil bit.
   \ EVIL EVIL EVIL!. Once on, the IDE regs go wonky, you'll never
   \ get them to behave again and it will otherwisw make your day
   \ miserable.
;

: (open-dma)  ( -- )
   \ XXX Check the drive capabilities and do this automatically if
   \ the drive can do DMA

   8 dma-alloc to dt-virtual
   dt-virtual 8 false " dma-map-in" $call-parent  to dt-physical

   h# 0100.0020 h# 10  +map-in  to bm-regs

   vendor-id  case
      acer   of  init-acer  endof	\ Acer Labs Aladdin IV M1533
      acer1  of  init-acer  endof	\ Acer Labs Aladdin IV M1533

\     national  of  endof	\ PC87560

      symphony  of		\ Winbond (nee Symphony Labs)
         ['] sl-start-hack to pio-start-hack
         ['] sl-end-hack   to pio-end-hack
         \ 255 read-aheads, PCI IRQ, enable both ports in mode 0
         h# 00.ff.08.b3  my-space h# 40 +  " config-l!" $call-parent
      endof

      ( default )
   endcase

   \ Enable bus mastering
   4 my-w@  4 or  4 my-w!

   ['] dma-rblocks to rblocks
   ['] dma-wblocks to wblocks
;
' (open-dma) to open-dma

: (close-dma) ( -- )
   ['] pio-rblocks to rblocks
   ['] pio-wblocks to wblocks

   \ Disable bus mastering
   4 my-w@  4 invert and  4 my-w!

   bm-regs        h# 10  map-out

   dt-virtual 8 dma-free 0 is dt-virtual 0 is dt-physical
;
' (close-dma) to close-dma

: dma  ( -- )
   save-dma-open
   ['] (open-dma)  to open-dma
   ['] (close-dma) to close-dma
;
: (pio)  ( -- )
   ['] open-pio   to open-dma
   ['] noop       to close-dma
   ['] noop       to set-drive-cfg
;
: pio  ( -- )
   save-dma-open
   (pio)
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
