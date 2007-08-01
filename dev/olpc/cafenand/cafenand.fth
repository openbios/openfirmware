\ See license at end of file
purpose: Driver for the NAND FLASH section of the OLPC CaFe chip

" nandflash" device-name
" olpc,cafenand" model
" olpc,cafenand" " compatible" string-property

h# 4000 constant /regs

my-address my-space               encode-phys
    0 encode-int encode+  h# 0 encode-int encode+

my-address my-space h# 200.0010 + encode-phys encode+
    0 encode-int encode+  /regs encode-int encode+

" reg" property

: my-w@  ( offset -- w )  my-space +  " config-w@" $call-parent  ;
: my-w!  ( w offset -- )  my-space +  " config-w!" $call-parent  ;

0 instance value chip

: cl!  ( l adr -- )  chip + rl!  ;
: cl@  ( adr -- l )  chip + rl@  ;
: cw@  ( adr -- w )  chip + rw@  ;

: map-regs ( -- )
   0 0  h# 0200.0010 my-space +  /regs " map-in" $call-parent to chip
   4 my-w@  6 or  4 my-w!
;

: unmap-regs
   chip /regs " map-out" $call-parent
\   4 my-w@  6 invert and  4 my-w!  \ No need to turn it off
;

h#     800 instance value /page
h#  2.0000 instance value /eblock

h# 40 constant /oob
h# e constant /ecc
h# e constant bb-offset  \ Location of bad-block table signature in OOB data

\ This resets the NAND controller in case the DMA gets hung or something
: soft-reset  ( -- )  1 h# 3034 cl!  0 h# 3034 cl!  ;

: timing-configure  ( -- )
   \ The following timing values are calculated from the Hynix and Samsung
   \ datasheets based on a clock cycle time of 10.4 nS.
   h# 1010.0900 h# 24 cl!  \ Timing1
   h#    1.0102 h# 28 cl!  \ Timing2 - recommended by Marvell
   h# 1000.0000 h# 2c cl!  \ Timing3
;
[ifdef] notdef
: sloppy-timing  ( -- )
   h# ffff.ffff h# 24 cl!  \ Timing1
   h# ffff.ffff h# 28 cl!  \ Timing2
   h# ffff.ffff h# 2c cl!  \ Timing3
;
[then]

: clr-ints  ( -- )   h# ffff.ffff h# 10 cl!  ;

\ Wait not busy - XXX need timeout
: ctrl-wait  ( -- )  begin  h# c cl@  h# 8000.0000 and 0=  until  ;

\ Bit 19 in the command (0) register is reserved according to the
\ version of the CaFe chip spec that we have, but Jerry Zheng says
\ that it chooses the chip select - 0 for CS0, 1 for CS1.

1 instance value chip-boundary  \ Boundary between chip 0 and chip 1
0 instance value cs-mask        \ Chip-select bit for command 0 register
: chip0  ( -- )  0 to cs-mask  ;
: chip1  ( -- )  h# 80000 to cs-mask  ;

: set-chip  ( page# -- page#' )
   dup  chip-boundary >=  if  chip-boundary -  chip1  else  chip0  then
;

\ For erase-block, the address that is sent to the chip is formatted
\ differently than for reads and writes.
: set-erase-page  ( page# -- )  set-chip  lwsplit  h# 20 cl!  h# 1c cl!  ;

: set-page  ( page# offset -- )  h# 1c cl!  set-chip h# 20 cl!  ;

: >cmd  ( cmd# #nonmem #address-bytes -- cmdval )
   dup  if  1- d# 27 lshift h# 4000.0000 or  then  ( cmd# #nm adr-field )
   over 1 and  d# 20 lshift  or  \ #nm[0]          ( cmd# #nm adr+nm0 )
   swap h# e and  d# 21 lshift  or  \ #nm[3:1]     ( cmd# adr+nm )
   or  h# 8000.0000 or
;

\   cmd      #nonmem
\              #adr
\ h#        90 4 1 >cmd constant read-id-cmd      \ Not needed
h#   20.0070 1 0 >cmd constant read-status-cmd
h# 0420.0000 0 5 >cmd constant read-cmd
h# 0220.0080 0 6 >cmd constant write-cmd  \ The 6 adds a dummy address cycle to meet tADR for Hynix

: wait-mask  ( bitmask -- )
   begin  dup h# 10 cl@  and  until  ( bitmask )
   h# 10 cl!   \ Clear status bit
;
: wait-dma  ( -- )  h# 1000.0000 wait-mask  ;
: wait-cmd  ( -- )  h# 8000.0000 wait-mask  ;

\ Control3 - no reset, no BAR write protect
: write-disable  ( -- )  0 8 cl!  ;
: write-enable  ( -- )  h# 4000.0000 8 cl!  ;

: cmd  ( cmd cmd2 -- )
   /page d# 10 rshift  3 and  d# 28 lshift  or  4 cl!  ( cmd )
   cs-mask or  0 cl!                                   ( )
;

: datalen  ( n -- )  h# 18 cl!  ;

: read-status  ( -- b )  read-status-cmd 0 cmd  wait-cmd  h# 30 cl@ h# ff and  ;
\ : read-id  ( -- )  0 0 set-page read-id-cmd 0 cmd  wait-cmd  h# 30 cl@  ;
: dma-off  ( -- )  0 h# 40 cl!  ;

: wait-write-done  ( -- error? )
   0               ( status )
   begin           ( status )
     drop          ( )
     read-status   ( status )
     dup h# 40 and ( status flag )
   until           ( status )
   \ If the value is completely 0 I think it means write protect     
   1 and  0<>      ( error? )
   write-disable
;

\ Assumes that the range doesn't straddle a page boundary
: generic-read  ( len page# offset cmd cmd2 -- chip-adr )
   >r >r                     ( len page# offset r: cmd cmd2 )
   set-page  dma-off         ( len r: cmd cmd2 )
   datalen                   ( r: cmd cmd2 )
   r> r> cmd wait-cmd        ( )
   chip h# 1000 +            ( adr )
;
: pio-read  ( adr len page# offset -- )
   2 pick >r
   read-cmd h# 130 generic-read        ( adr chip-adr r: len )
   swap r> move                        ( )
;

: pio-write-raw  ( adr len page# offset -- )
   write-enable
   dma-off  set-page  dup datalen         ( adr len )
   chip h# 2000 +  swap  move             ( )
   write-cmd h# 0000.0110 cmd  wait-cmd   ( ) \ No Auto ECC
   wait-write-done                        ( error? )
   drop
;

: pio-write-page  ( adr page# -- error? )
   write-enable  dma-off                  ( adr page# )
   0 set-page                             ( adr )
   /page h# e +  dup datalen              ( adr len )
   chip h# 2000 +  swap  move             ( )
   write-cmd h# 4800.0110 cmd  wait-cmd   ( ) \ 4000. Auto ECC, 0800. R/S ECC
   wait-write-done                        ( error? )
;

: read-oob  ( page# -- adr )
   /oob  swap  h# 800  read-cmd  h# 130 generic-read
;

: read-rst  ( -- )  h# 8000.0000 h# c cl!  ;

0 instance value dma-vadr
0 instance value dma-padr
0 instance value dma-len

: dma-setup  ( adr #bytes #ecc direction-in? -- )
   >r                       ( adr #bytes #ecc )
   datalen                  ( adr #bytes )
   over to dma-vadr         ( adr #bytes )     \ Remember for later
   dup  to dma-len          ( adr #bytes )     \ Remember for later
   tuck false " dma-map-in" $call-parent  ( #bytes padr )  \ Prepare DMA buffer
   dup to dma-padr          ( #bytes padr )           \ Remember for later
   h# 44 cl!  0 h# 48 cl!   ( #bytes )                \ Set address
   r> if  h# a000.0000  else  h# 8000.0000  then  ( bits )
   or h# 40 cl!
;

: dma-release  ( -- )
   dma-vadr dma-padr dma-len  " dma-map-out" $call-parent
;

: slow-dma-read  ( adr len page# offset -- )
   set-page
   dup  true dma-setup                  ( )
   read-cmd h# 0800.0130 cmd  wait-dma  ( adr chip-adr r: len )
   dma-release                          ( )
;

: /dma-buf  ( -- n )  /page /oob +  ;
0 instance value dma-buf-pa
0 instance value dma-buf-va
defer do-lmove
h# 10 buffer: syndrome-buf
: syndrome  ( -- adr )
   8  0  do  h# 50 i wa+ cw@  i syndrome-buf array!  loop
   syndrome-buf
;

: read-page  ( adr page# -- error? )
   0 set-page                          ( adr )
   /page /ecc +  h# 18 cl!             ( adr )
   dma-buf-pa h# 44 cl!                ( adr )
   0 h# 48 cl!                         ( adr )
   /page h# a000.0000 or  h# 40 cl!    ( adr )
   read-cmd h# 0800.0130 cmd  wait-dma ( adr )

   h# 3c cl@  h# 40000 and  if         ( adr )      \ ECC error
      dma-buf-va syndrome correct-ecc  ( adr uncorrectable? )
   else                                ( adr )
      false                            ( adr error? )
   then                                ( adr error? )

   dma-buf-va rot /page do-lmove       ( error? )
;

: dma-write-raw  ( adr len page# offset -- )
   write-enable                        ( adr len page# offset )
   set-page                            ( adr len )
   dup  false dma-setup                ( )
   write-cmd h# 110 cmd wait-cmd       ( )
   wait-write-done                     ( error? )
   dma-release                         ( error? )
   drop
;

: dma-write-page  ( adr page# -- error? )  \ Size is fixed
   write-enable                          ( adr page# )
   0 set-page                            ( adr )
   h# 800 h# 80e  false dma-setup        ( )
   write-cmd h# 4800.0110 cmd wait-cmd   ( )  \ Auto-ECC, RS, write cmd
   wait-write-done                       ( error? )
\   dma-release
;

: write-page   ( adr page# -- error? )  dma-write-page  ;
: write-bytes  ( adr len page# offset -- )  pio-write-raw  ;

3 value #erase-adr-bytes  \ Chip dependent
: erase-block  ( page# -- )
   write-enable
   set-erase-page
   h# 20.0060 0 #erase-adr-bytes >cmd  h# 1d0 cmd
   wait-write-done                       ( error? )
   drop
;

: read-id  ( -- adr )  8  0 0  h# c420.0090  0  generic-read  ;

: send-reset-cmd  ( -- )
   ctrl-wait
   h# 8000.00ff 0 cmd  wait-cmd  \ NAND Reset command
;

: init  ( -- )
   write-disable

   send-reset-cmd

   0 h# 14 cl!  \ Interrupts off
   clr-ints
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
