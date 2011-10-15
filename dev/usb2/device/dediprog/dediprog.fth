\ See license at end of file
purpose: Dediprog SF100 SPI FLASH programmer driver

\ Mostly untested

\ VID: 0483  PID: dada

0 instance value inbuf
0 instance value outbuf

: alloc-buffers  ( -- )
   h# 10 dma-alloc to inbuf
   h# 10 dma-alloc to outbuf
;
: free-buffers  ( -- )
   inbuf h# 10 dma-free
   outbuf h# 10 dma-free
;
: ?error  ( usberr -- )
   ?dup  if
      noop  \ Patch debug-me here if desired
      push-hex
      ." Dediprog: USB error " .  cr
      pop-base
   then
;
: set-millivolts  ( mv -- )
   case
      0       of      0  endof
      d# 1800 of  h# 12  endof
      d# 2500 of  h# 11  endof
      d# 3300 of  h# 10  endof
      d# 3500 of  h# 10  endof
      ( -- )  ." Unsupported voltage" cr  abort
   endcase
   >r  0 0  h# ff r>  h# 42 9  control-set ?error
;
\ Speed#      0       1        2      3      4      5     6     7
\ KHz     24000 ,  8000 ,  12000 , 3000 , 2180 , 1500 , 750 , 375 ,
\ Divisor     1       3        2      8     11     16    32    64
\ Base clock frequency is 24 MHz = 24000 kHz

: set-speed  ( speed# -- )
   >r  0 0  h# ff  r>  h# 42  h# 61  control-set ?error
;
0 value offset
: seek  ( d.offset -- error? )
   if  ." Dediprog: seek offset too large" cr  drop true exit  then
   to offset
   false
;
   
: spi-read  ( adr len start -- actual )

;
: send  ( readadr,len writeadr,len -- )
   2 pick  if  1  else 0  then  >r      ( readadr,len writeadr,len r: readlen )
   r>  h# ff  h# 42 1  control-set ?error   ( readadr,len )
   dup  if
      0  h# bb8  h# c2 1  control-get ?error  drop
   else
      2drop
   then
;
: check-devicestring  ( -- error? )
   0 inbuf c!
\  inbuf 1  h# ef03  0  h# c3 7  control-get ... \ From rsmith snoop
   inbuf 1  0 0  h# c3  h# 7  control-get  if  true exit  then  ( actual )
   1 <>  if  true exit  then
   inbuf c@ h# ff <>  if  true exit  then
   inbuf h# 10  h# ff h# ff  h# c2  h# 8  control-get  if  true exit  then
   h# 10 <>  if  true exit  then
   ." Opened " inbuf h# 10 type cr
   " SF100"  inbuf swap comp 0=
;
: command-a  ( -- )
   0 inbuf c!  inbuf 1  0 0  h# c3  h# b  control-get  ?error ( n )
   1 <>  ?error
   inbuf c@  h# 6f <> ?error
;
: command-c  ( -- )  0 0  0 0  h# 42     4  control-set  ?error  ;
: write  ( adr len -- )
;
: open  ( -- flag )
   set-device?  if  false exit  then
   device set-target
   reset?  if
      configuration set-config  if
         ." userial: set-config failed" cr
         false exit
      then
      bulk-in-pipe bulk-out-pipe reset-bulk-toggles
   then
   alloc-buffers
   inbuf h# 10 bulk-in-pipe begin-bulk-in
   command-a
   command-a
   check-devicstring  if  free-buffers false exit then
   dediprog-command-c
   d# 3500 set-millivolts

   true
;
: close  ( -- )
   0 set-millivolts
;
\ Send sequence
\ w 9f r4 ef 30 11 00
\ w 9f r3 ef 30 11
\ w 9f r2 ef 30
\ w 15 r2 00 00
\ w4 ab 00 00 00 r3 10 10 10
\ w4 ab 00 00 00 r2 10 10
\ w4 90 00 00 00 r3 ef 10 ef
\ w4 90 00 00 00 r2 ef 10
\ set-voltage 0
\ device string
\ CTL: 42 07 0009 0007 0
\ set-voltage 0x10 (3V3)
\ set-speed 0x02
\ set-voltage 0
\ device string
\ command-a
\ command-a
\ command-a
\ set-voltage 0
\ command-a
\ device string
\ CTL: 42 07 0009 0005 0
\ set-voltage 0x10
\ device string (c3,07  c2,08)
\ CTL: 42 07 0009 0005 0
\ set-voltage 0x10

\ CTL: 42 20 0000 0000 4  Data: 80 00 00 02
\ Bulk IN EP 82:  512 bytes: 02 01 01 02 01 5d ff ff ff ff 02 ...
\ Bulk IN EP 82:  512 bytes: 09 b5 75 82 ...
\ ...
\ Last one is URB 220, data: ff .. ff 09 b2 c2 54
\ URB 221:
\ CTL: 42 20 0000 00ff 0
\ set-voltage 0x10
\ CTL: 42 01 00ff 0001 1  wdata: 05 -> 00  status  (01 bit is write in progress)
\ CTL: 42 01 00ff 0001 1  wdata: 06 write-enable
\ CTL: 42 01 00ff 0001 1  wdata: 05 -> 02  status  (02 bit is write-enable)

\ CTL: 42 01 00ff 0001 4  wdata: d8 00 00 00  erase (adr-hi,mid,lo)
\ CTL: 42 01 00ff 0001 1  wdata: 05 -> 03  status

\ again again ... eventually returns 00 instead of 03 at URB 264, 266

\ CTL: 42 01 00ff 0001 1  wdata: 06 write-enable
\ CTL: 42 01 00ff 0001 1  wdata: 05 -> 02  status

\ CTL: 42 30 0000 0000 4  wdata: 00 01 00 01

\ URB 271
\ Bulk out EP 02 512 bytes data: 02 01 01 02 01 5d ff ff ff ff ff 02 05 fc ...

\ many more
\ URB 527
\ CTL: 42 01 00ff 0001 1  wdata: 05
\ CTL: C2 01 0bb8 0000 1  rdata: 00
\ set-voltage 0
\ CTL: 42 07 0009 0006 0
\ set-voltage 0
\ set-voltage 0
