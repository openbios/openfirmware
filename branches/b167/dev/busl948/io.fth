\ See license at end of file
purpose: IO Definitions for Bus Logic 948/958 SCSI Cards

\ This file contails the basic IO operations used
\ to talk to the DPT SCSI controller boards.

\ For ease of use in later methods, we define the following three sturctures
\ now. These structures describe the layout of the controller chips PIO
\ registers, the returned status packet and the command packet.

hex 
headers

\ Sturcture to define where PCI SCSI registers are.
struct
   01 field >cntl/st-reg
   01 field >cmd/dat-reg
   01 field >int-reg
   01 +
constant /scsi-regs

\ Structure to define the CCB structure.
struct
   01 field >op-code		( 0 )
   01 field >ccb-cntl		( 1 )
   01 field >cdb-len		( 2 )
   01 field >sen-len		( 3 )
   04 field >data-len		( 4 - 7 )
   04 field >data-ptr		( 8 - 11 )
   01 field >r1			( 12 )
   01 field >r2			( 13 )
   01 field >btstat		( 14 )
   01 field >sdstat		( 15 )
   01 field >target		( 16 )
   01 field >lun/tag		( 17 )
   0c field >cdb		( 18 - 29 )
   01 field >r3			( 30 )
   05 field >r4			( 31 - 35 )
   04 field >sense-ptr		( 36 - 39 )
constant /ccb

struct
   04 field >out1-adr
   01 field >in1-r1
   01 field >in1-r2
   01 field >in1-r3
   01 field >out1-ac
   04 field >in1-adr
   01 field >in1-btstat
   01 field >in1-sdstat
   01 field >in1-r4
   01 field >in1-cc
constant /mailbox

\ This first batch of words is simply to make following code easier to write.

: c-l@  ( offset -- l )			\ Shorthand helper...
   my-space + " config-l@" $call-parent
;

: c-l!  ( l offset -- )			\ Shorthand helper...
   my-space + " config-l!" $call-parent
;

: c-w@  ( offset -- w )                            \ Shorthand helper...
   my-space + " config-w@" $call-parent
;

: c-w! ( w offset -- )                             \ Shorthand helper...
   my-space + " config-w!" $call-parent
;

: vendor-id  ( -- w )  0 c-w@  ;	\ Reads Vendor ID
: dev-id     ( -- w )  2 c-w@  ;	\ Reads PCI device ID register.

\ Now some real low level PIO words to talk to the command/status register
\ and the interrupt register

-1 value scsi-base

: cs-reg@  ( -- b )			\ Read control/status register.
   scsi-base >cntl/st-reg rb@
;

: cs-reg!  ( b -- )			\ Write control/status register.
   scsi-base >cntl/st-reg rb!
;

: cd-reg@  ( -- b )			\ Read command/data register.
   scsi-base >cmd/dat-reg rb@
;

: cd-reg!  ( b -- )			\ Write command/data register.
   scsi-base >cmd/dat-reg rb!
;

: int-reg@  ( -- b )			\ Read interupt register.
   scsi-base >int-reg rb@
;

: busy-wait  ( -- )	\ Waits until busy bit in cmd/stat reg is cleared.
   begin
      cs-reg@ 8 and 0=	\ Check bit 3 of status reg, 0 means not busy
   until
;

: reset-int  ( -- )  20 cs-reg! ;	\ Resets interupt

: ha-ready?  ( -- flag )		\ Is host adapter ready?
   cs-reg@ 10 and 0<>
;

: cd-busy?  ( -- flag )			\ Is controller busy?
   cs-reg@ 8 and
;

: data?  ( -- flag )			\ Is data-in ready for read?
   cs-reg@ 4 and 0<>
;

variable cmd-wait
d# 5000 cmd-wait !
variable cmd-start

external

: set-timeout  ( ms -- )  cmd-wait ! ;	\ Sets timeout value

headers

: cmd!  ( b -- )	\ Writes command and waits until done
   
   get-msecs cmd-start !
   begin
      ha-ready?  if	\ Must not write command if adapter is not ready
         cd-reg!
         true
      else
         get-msecs cmd-start @ - cmd-wait @ >  if
            ." Host adapter not ready!" cr
            exit
         then
         false
      then
   until

   \ Now we wait until command completes

   begin
      get-msecs cmd-start @ - cmd-wait @ > if
         exit			\ Bail if time limit reached
      then
      int-reg@ 84 =		\ Look for interupt, if present we are done
   until

   reset-int			\ Clear the interupt
;

: cmd-p!  ( b -- )		\ Writes command but does not wait

   get-msecs  cmd-wait !
   begin
      ha-ready?  if		\ Do not write command if adapter is not ready
         cd-reg!
         true
      else
         get-msecs cmd-start @ - cmd-wait @ >  if
            exit
         then
         false
      then
   until

;

: cmd-p-end  ( -- )		\ Finish off paramter command write

   get-msecs  cmd-start	!	\ Init timeout counter
   begin
      get-msecs cmd-start @ - cmd-wait @ > if
         cmd-start @ . cmd-wait @ . cr
         exit			\ Bail if time limit reached
      then
      int-reg@ 84 =		\ Look for interupt, if present we are done
   until

   reset-int			\ Clear the interupt
;

: param!  ( b -- )		\ Writes to parameter register

   begin
      cd-busy? 0=		\ Wait until paramter register is ready
   until

   cd-reg!			\ Write the byte to paramter register
;

: param@  ( -- b )		\ Reads parmater bytes

   begin
      data?			\ Wait until data ready
   until

   cd-reg@			\ Read it
;

: hard-reset  ( -- )  80 cs-reg! ;	\ Forces hard reset
: soft-reset  ( -- )  40 cs-reg! ;	\ Forces soft reset

\ Now we move up a level to some intermediate methods. The methods send
\ or obtain information from the controler using the cs and cd registers

: test-cmdc  ( -- ok? )			\ Tests the CMDC interupt
   reset-int
   0 cd-reg!
   int-reg@ 4 and 0<>
   reset-int
;

: get-board-info  ( -- )

   4 cmd-p!				\ Write 4 to command reg
   param@	( b )
   param@	( b b )
   param@	( b b b )
   param@	( b b b b )
   cmd-p-end

   ." Firmware revision level is: " . cr
   ." Host adapter FW version is: " . cr
   ." Custom features byte:       " . cr
   ." Bus Logic Board Type:       " . cr
;

: get-extended-info  ( byte# -- b )
   h# 8d cd-reg!	( byte# )
   d# 300 ms		( byte# )
   dup  cd-reg!		( byte# )
   1 - 0 do
      param@ drop
   loop
   param@		( b )
   cmd-p-end
;

: decode-luns  ( b -- )			\ Prints status info
   8 0 do
      dup 1 and 0<>  if
         ."             Lun " i . ." is present" cr
      then
      1 rshift
   loop
   drop
;

: show-installed-devs  ( -- )
   
   a cmd-p!
   8 0 do
      param@
      dup 0<>  if
         ." Target " i . cr
         decode-luns
      else
        drop
      then
   loop
   cmd-p-end
;

: cmd-param!  ( adr len cmd -- )

   cmd-p!	( adr len )		\ Write the initial command
   bounds do
      i c@ param!			\ Write the paramters
   loop
   cmd-p-end	( )			\ Finish the command
;

false value wide-mode

: set-wide-mode  ( -- )
   true to wide-mode
   h# 96 cmd-p!
   h# 1 param!
   cmd-p-end
;

: set-narrow-mode  ( -- )
   false to wide-mode
   h# 96 cmd-p!
   h# 0 param!
   cmd-p-end
;

: help  ( -- )
   cr
   ." You can: " cr
   ."   get-board-info" cr
   ."   show-installed-devs" cr
   cr
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
