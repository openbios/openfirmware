\ See license at end of file
purpose: Access and FLASH programming for KB3731 EC via its "EDI" interface

\ The following code depends on externally-privided low-level SPI bus
\ access primitives that are defined in "bbedi.fth" for the "native"
\ case (EC and CPU on the same machine).  They can also be implemented
\ for tethered programming from a different machine like an XO-1.5.
\
\ Low-level primitives:
\  spi-start  ( -- )      - Init SPI bus
\  spi-cs-on  ( -- )      - Assert SPI-bus CS#
\  spi-cs-off ( -- )      - Deassert SPI-bus CS#
\  spi-out    ( byte -- ) - Send byte
\  spi-in     ( -- byte ) - Receive byte

0 value edi-chip-id
: kb9010?  ( -- flag )  edi-chip-id 4 =  ;

: efcfg    ( -- reg# )  kb9010?  if  h# fead  else  h# fea0   then  ;
: efcmd    ( -- reg# )  kb9010?  if  h# feac  else  h# fea7   then  ;
: efdat    ( -- reg# )  kb9010?  if  h# feab  else  h# feaa   then  ;
: rst8051  ( -- reg# )  kb9010?  if  h# ff14  else  h# f010   then  ;
: ecreboot ( -- reg# )  kb9010?  if  h# ff01  else  h# f018   then  ;

\ Issues with .py code
\ A14:A8 should be A15:A8 several places
\ inconsistent use of handle vs gd.handle in edi_erase_chip

\ KB9010 stuff...
d# 59 d# 1024 * constant /kb9010-flash
h# fe80 constant wdtcfg
h# fe81 constant wdtpf
h# fe82 constant wdt
h# fea2 constant shccfg
\ h# fea5 constant xbicfg \ Unused
h# fea6 constant xbics
\ h# feae constant efdatr \ Unused
\ h# feaf constant emfburw
h# feb2 constant xbiwp
\ h# feb6 constant xbipump
\ h# feb7 constant xbifm
\ h# feb8 constant sbivr
h# feb9 constant xbis
h# ff0d constant clkcfg
h# ff0f constant pllcfg
h# ff1d constant ecsts
h# ff1f constant pllcfg2
h# ff14 constant pxcfg

\ end KB9010 stuff...

d# 128 constant /flash-page
defer edi-progress  ' drop to edi-progress  ( n -- )

: edi-cmd,adr  ( offset cmd -- )   \ Send command plus 3 address bytes
   spi-cs-on     ( offset cmd )
   spi-out       ( offset )
   lbsplit drop  spi-out spi-out spi-out  ( )
;
: edi-b!  ( byte offset -- )  \ Write byte to address inside EC chip
   h# 40 edi-cmd,adr spi-out spi-cs-off
;
[ifndef] edi-wait-b
: edi-wait-b  ( -- b )  \ Wait for and receive EC response byte
   d# 100 0  do
      spi-in              ( d )
      dup h# 5f <>  if    ( d )
         dup h# 50 =  if  ( d )
            drop
            spi-in        ( b )
            spi-cs-off    ( b )
            unloop exit
         then             ( d )
         spi-cs-off       ( d )
	 \ The setup in the CL4 has can also report zeros when inactive.
         2dup h# ff = 00 = or abort" EDI byte in inactive"
	 ." Unknown EDI byte in response: " .h cr
         true abort" EDI byte in confused"
      then                ( d )
      drop
   loop
   spi-cs-off
   true abort" EDI byte in timeout"
;
[then]
: edi-b@  ( offset -- b )  \ Read byte from address inside EC chip
   h# 30 edi-cmd,adr  edi-wait-b
;
: edi-next-b@  ( -- b )  \ Read the next EC byte - auto-increment address
   spi-cs-on  h# 33 spi-out  edi-wait-b
;
: edi-disable  ( -- )  \ Turn off the EC EDI interface
   spi-cs-on
   h# f3 spi-out
   spi-in      ( b )
   spi-cs-off
   h# 8c <>  if
      ." Unexpected response from edi-disable" cr
   then 
;

0 [if]
: edi-w@  ( offset -- w )  \ Read 16-bit word from address inside EC chip
   dup 1+  edi-b@         ( offset b.low )
   swap edi-b@            ( b.low b.high )
   bwjoin
;
[else]
: edi-w@  ( offset -- w )  \ Read 16-bit word from address inside EC chip
   edi-b@ edi-next-b@ swap bwjoin
;
[then]
: reset-8051  ( -- )  \ Reset 8-5
   rst8051 edi-b@  1 or  rst8051 edi-b!
;
: unreset-8051  ( -- )  \ Reset 8-5
   rst8051 edi-b@  1 invert and  rst8051 edi-b!
   d# 2000 ms
;

\ 0 in bit 0 selects masked ROM as code source for 8051, 1 selects FLASH
\ The 8051 should be in reset mode when changing that bit.

: select-flash  ( -- )  \ Setup for access to FLASH inside the EC
   kb9010?  if  exit  then
   h# f011 edi-b@  1 or  h# f011 edi-b!
;

: edi-read-id  ( -- id )
   spi-cs-on  h# 3e spi-out  spi-in  spi-cs-off
;

: probe-rdid  ( -- found? )  \ Verify that the EC is the one we think it is
   select-flash
   h# f01c ['] edi-w@ catch  if   ( x )
      drop false exit             ( -- false )
   then                           ( id )

   1 invert and  h# 3730 =
;

: finished?  ( b -- flag )
   kb9010?  if  2 and 0=  else  h# 80 =  then
;
: wait-flash-busy  ( -- )  \ Wait for an erase/programming operation to complete
   get-msecs  h# 1000 +    ( limit )
   begin                   ( limit )
      efcfg edi-b@         ( limit b )
      finished?  if        ( limit )
         drop exit         ( -- )
      then                 ( limit )
      dup get-msecs - 0<=  ( limit timeout? )
   until                   ( limit )
   drop
   true abort" EDI FLASH busy timeout"
;

: flash-cmd  ( b -- )  efcmd edi-b!  ;

: set-offset  ( offset -- )
   lbsplit drop                                   ( offset-low mid hi )
   kb9010?  if  h# feaa edi-b!  else  drop  then  ( offset-low mid )
   h# fea9 edi-b!  h# fea8 edi-b!                 ( )
;

: erase-page  ( offset -- )
   wait-flash-busy     ( offset )
   set-offset          ( )
   h# 20 flash-cmd     ( )
;

: erase-chip  ( -- )  
   0 set-offset  \ New code does this (and does not wait-flash-busy)
   wait-flash-busy  h# 60 flash-cmd  wait-flash-busy
;

: send-byte  ( b offset -- )  set-offset  efdat edi-b!  2 flash-cmd  ;

: edi-program-page  ( adr offset -- )
   \ Clear HVPL
   wait-flash-busy  h# 80 flash-cmd  ( adr offset )

   wait-flash-busy                ( adr offset )  \ Necessary?

   \ Fill the page buffer
   swap  /flash-page  bounds  do  ( offset )
      i c@  over  send-byte       ( offset )
      1+                          ( offset' )
   loop                           ( offset )
   drop                           ( )

   \ Commit the buffer to the FLASH memory
   wait-flash-busy                ( )  \ Redundant wait?
   h# 70 flash-cmd                ( )  \ Program page command
   wait-flash-busy                ( )
;

: edi-program-flash  ( adr len offset -- )
   cr                                          ( adr len offset )
   swap  0  ?do                                ( adr offset )
      (cr i .                                  ( adr offset )
      dup i + ec-flags-offset <>  if           ( adr offset )
         dup i + erase-page                    ( adr offset )
         over i +  over i +  edi-program-page  ( adr offset )
      then                                     ( adr offset )
      i edi-progress                           ( adr offset )
   /flash-page +loop                           ( adr offset )
   2drop                                       ( )
;
: edi-read-flash  ( adr len offset -- )
   over 0=  if  3drop exit  then  ( adr len offset )
   edi-b@                         ( adr len byte )
   third c!                       ( adr len )
   1 /string  bounds  ?do         ( )
      edi-next-b@ i c!            ( )
   loop                           ( )
;

: trim@  ( offset -- b )
   set-offset
   h# 90 flash-cmd
   wait-flash-busy
   efdat edi-b@   \ reg: efdat
;
: trim-tune  ( -- )
\   firmware-id  0=  if
      \ Read trim data and write to register (for ENE macros)
      h# 100 trim@  h# 5a =  if
         \ Low Voltage Detect TRIM register
         h# f035 edi-b@               ( val )
         h# 1f invert and             ( val' )
         h# 101 trim@ h# 1f and  or   ( val' )
         h# f035 edi-b!               ( )

         \ Int Oscillator Control register - HKCOMOS32K
         h# f02b edi-b@               ( val )
         h# 0f invert and             ( val' )
         h# 102 trim@ h# 0f and  or   ( val' )
         h# f02b edi-b!               ( )
      then

      \ Read trim data and write to register (for HHNEC macros)
      h# 1ff trim@  0<>  if
         \ XBIMISC register - S[4:0]
         h# fea6 edi-b@               ( val )
         h# 1f invert and             ( val' )
         h# 1f0 trim@ h# 1f and  or   ( val' )
         h# fea6 edi-b!               ( )
         
         \ XBI Pump IP register - Pdac[3:0] | Ndac[3:0]
         h# 1f1 trim@ 4 lshift        ( val )
         h# 1f2 trim@ h# 0f and or    ( val' )
         h# fea3 edi-b!               ( )
         
         \ XBI Flash IP register - Bdac[3:0]
         h# fea4 edi-b@               ( val )
         h# 0f invert and             ( val' )
         h# 1f4 trim@ h# 0f and  or   ( val' )
         h# fea4 edi-b!               ( )
         
         \ XB VR IP register - Tctrim[3:0] | Abstrim[3:0]  (Vref temp coef and absolute value)
         h# 1f5 trim@ 4 lshift        ( val )
         h# 1f6 trim@ h# 0f and or    ( val' )
         h# fea5 edi-b!               ( )
         
         \ XBI Flash IP register - Itim[3:0] - Must be last
         h# fea4 edi-b@               ( val )
         h# f0 invert and             ( val' )
         h# 1f4 trim@ 4 lshift  or    ( val' )
         h# fea4 edi-b!               ( )
         
         3 us  \ Required after Itim[3:0] update

         \ XBI Embedded Flash Configuration register
         h# 10 h# fea0 edi-b!    \ Set FLASH clock

         h# fea0 edi-b@  h# d0  =  if
            ." Warning - XBIECFG is 0xd0" cr
         then
      then
\   then
;
: set-chip-id  ( -- )
   ['] edi-read-id  catch  if        ( )
       edi-read-id                   ( id )
   then                              ( id )
   to edi-chip-id
;
: kb9010-init  ( -- )
   h# 00 xbics  edi-b!
   h# 00 xbiwp  edi-b! \ Clear XBI write protection
   h# ff wdt    edi-b! \ Disable WDT
   h# 00 wdtcfg edi-b!
   h# 00 wdtpf  edi-b!
   h# 00 shccfg edi-b! \ Disable SHC
   h# 0c clkcfg edi-b! \ Set the 8051 to 32Mhz
   h# 08 efcfg  edi-b! \ Enable the embedded flash cmd mode
;
base @ hex
create special-row     1f0 w,  1f1 w,  1f2 w,  1f4 w,  1f5 w,  1f6 w,  1f3 w,
create dest-regs      feb9 w, feb6 w, feb6 w, feb7 w, feb8 w, feb8 w, feb7 w,
create source-bits      1f c,   0f c,   0f c,   0f c,   07 c,   1f c,   0f c,
create dest-bits        1f c,   f0 c,   0f c,   0f c,   e0 c,   1f c,   f0 c,
create shift-cnt         0 c,    4 c,    0 c,    0 c,    5 c,    0 c,    4 c,
base !
: kb9010-trimtune  ( -- )
   h# 1ff trim@  0<>  if
      7 0  do
         special-row i wa+ w@  edi-b@         ( data )
         source-bits i ca+ c@  or             ( field )
         shift-cnt   i ca+ c@  lshift         ( field' )
         dest-regs   i wa+ w@  edi-b@         ( field dest )
         dest-bits   i ca+ c@  invert and or  ( dest' )
         dest-regs   i wa+ w@  edi-b!         ( )
      loop
      wait-flash-busy
   then
   h# 80 trim@  h# 5a =  if
      ecsts edi-b@                   ( old-ecsts )
      dup 4 or  ecsts edi-b!         ( old-ecsts )  \ chipid is now pllcfg2

      xbis edi-b@  h# 3f and               ( old-ecsts xbis-bits )
      h# 81 trim@ 3 and  6 lshift or       ( old-ecsts xbis-value )
      xbis edi-b!                          ( old-ecsts )

      h# 82 trim@ h# f and 4 lshift        ( old-ecsts pll-high )
      h# 83 trim@ h# f0 and 4 rshift or    ( old-ecsts pll-value )
      pllcfg edi-b!                        ( old-ecsts )

      pllcfg2 edi-b@ h# 3f and             ( old-ecsts pll2-bits )
      h# 82 trim@ h# 30 and 2 lshift or    ( old-ecsts pll2-value )
      pllcfg2 edi-b!                       ( old-ecsts )
      
      ecsts edi-b!                         ( )
   then
;
: edi-open  ( -- )
   \ slow-edi-clock   \ Target speed between 1 and 2 MHz
   spi-start

   \ dummy read, to activate EDI and can fail so ignore the fail
   h# ff22 ['] edi-b@ catch if noop else drop then
   
   set-chip-id

   \ The first operation often fails so retry it
   ['] select-flash  catch  if  select-flash  then
   reset-8051

   kb9010?  if
      kb9010-init
      kb9010-trimtune
   else
      trim-tune
   then
   \ fast-edi-clock   \ Target speed up to 16 MHz
   \ reset
;
: edi-open-active  ( -- )
   spi-start
   ['] select-flash  catch  if  select-flash  then
;

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
