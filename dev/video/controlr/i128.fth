\ See license at end of file
purpose: Imagine 128 Methods

\ PCI code for Imagine 128 boards

\ Currently, this driver only supports 1024 x 768, 60 Hz.

hex
headers

\ Variables to hold pointers to io-base registers
-1 instance value io-base5
-1 instance value io-base4

\ Some helpers to shorten following code
: gbase   ( -- adr )  io-base5  ;		\ Address of RBASE_G
: id      ( -- adr )  io-base5 h# 18 +  ;	\ Address of ID
: config1 ( -- adr )  io-base5 h# 1c +  ;	\ Address of CONFIG1
: config2 ( -- adr )  io-base5 h# 20 +  ;	\ Address of CONFIG2
: rbaseg  ( -- adr )  io-base4  ;		\ RBASEG base adr
: rbasew  ( -- adr )  io-base4 h# 2000 +  ;	\ RBASEW base adr
: rbasea  ( -- adr )  io-base4 h# 4000 +  ;	\ RBASEA base adr

\ Mapping Methods...

\ Maps in the in-frequently used io registers
: map-i128-io-regs  ( -- )
   0 0 my-space h# 100.0024 + h# 100 map-in to io-base5   
   4 c-l@ 1 or 4 c-l!
   0 0 my-space h# 200.0020 + h# 1.0000 map-in to io-base4
   4 c-l@ 2 or 4 c-l!
;

\ Mpas out the io registers
: unmap-i128-io-regs  ( -- )
   io-base5 h# 100 map-out
   4 c-l@ 1 invert and 4 c-l!
   -1 to io-base5
   io-base4 h# 1.0000 map-out
   -1 to io-base4		\ Do not disable memory access bit! FB needs it
;

\ Map in the frame buffer
: map-i128-frame-buffer  ( -- )
   0 0 my-space h# 200.0010 + /fb map-in to frame-buffer-adr
;

\ Map out the frame buffer
: unmap-i128-frame-buffer  ( -- )
   frame-buffer-adr /fb map-out
   4 c-l@ 2 invert and 4 c-l!
   -1 to frame-buffer-adr
;

\ Methods to read and write the "softreg"
: softreg   ( -- adr )  io-base5 h# 28 +  ;	\ Softreg is 28 off of base5
: softreg@  ( -- w )  softreg rw@ ;
: softreg!  ( w -- )  softreg rw! ;

: led-off  ( -- )			\ Turns off the bright red LED
   softreg@ h# 100 or softreg!
;

: led-on  ( -- )			\ Turns on the not so bright red LED
   softreg@ h# 100 invert and softreg!
;

\ DAC Access Methods

\ The following "i128-<somethin>" are all used to talk to the RAMDAC.
\ These methods are plugged into "defered" words that the RAMDAC calls.
\ This allows the RAMDAC code to be written independent of the controller
\ code.

: i128-index!  ( index -- )		\ Generic writing of an index address
   wbsplit		( lo hi )
   swap			( hi lo )
   rbaseg h# 10 + rl!	( hi )
   rbaseg h# 14 + rl!	( )
;
  
: i128-idac@  ( index -- data )		\ Performs indexed DAC read
   i128-index!			( )
   rbaseg h# 18 + rl@ ff and	( data )
;

: i128-idac!  ( data index -- )		\ Performs indexed DAC write
   i128-index!		( data )
   rbaseg h# 18 + rl!	( )
;

: i128-rmr@  ( -- b )  h# ff  ;		\ Not used used so far
: i128-rmr!  ( b -- )  drop  ;

\ Read and write to the LUT
: i128-plt@  ( -- b )  rbaseg h# 1c + rl@ h# ff and  ;
: i128-plt!  ( b -- )  rbaseg h# 1c + rl!  ;

: i128-rindex!  ( index -- )  h# 4000 or i128-index!  ;
: i128-windex!  ( index -- )  i128-rindex!  ;

: use-i128-dac-methods  ( -- )	\ Assigns i128 version of DAC access words
   ['] i128-rmr@ to rmr@
   ['] i128-rmr! to rmr!
   ['] i128-plt@ to plt@
   ['] i128-plt! to plt!
   ['] i128-rindex! to rindex!
   ['] i128-windex! to windex!
   ['] i128-index!  to index!
   ['] noop  to rs@
   ['] 2drop to rs!
   ['] i128-idac@ to idac@
   ['] i128-idac! to idac!
;

\ The format of the crt-data-<whatever> tables is:
\	create <whatever>
\	2  "l" size entries describing interrupt settings (typically 0)
\		Vertical (typically 0)
\		Horizontal (typically 0)
\	10 "l" size entries describing the CRT timing values
\		CRT start Address (typically 0)
\		Display Pitch (Addr delta between vertically adjacent pixels)
\		Horizontal Active in character clocks
\		Horizontal Blank in character clocks
\		Horizontal Front Porch in character clocks
\		Horizontal Sync Width in character clocks
\		Vertical Display Total in lines
\		Vertical Blanks in lines
\		Vertical Front Porch in lines
\		Vertical Sync Width in lines
\	2 "l" size entries for the global config regs
\		CONFIG1 value (io-base5 + h# 18)
\		CONFIG2 value (io-base5 + h# 20)
\	1 "l" size entry for crt configuration register 2

create crt-data-1024
0 l,		\ Vertical interupt
0 l,		\ Horizontal interupt
0 l,		\ CRT Start Address
d# 1024 l,	\ Display Pitch 
d# 1024 8 / l,	\ Horizontal active (In VClks)
d# 320 8 / l,	\ Horizontal Blank (In VClks)
d# 24 8 / l,	\ Horizontal Front Porch (In VClks)
d# 136 8 / l,	\ Horizontal Sync Width (In VCliks)
d# 768 l,	\ Vertical Display Total (In Lines)
d# 38 l,	\ Vertical Blank (In Lines)
d# 3 l,		\ Vertical Front Porch (In Lines)
d# 6 l,		\ Vertical Sync Width (In Lines)
h# 0103.3f15 l,	\ Config1
h# 0017.0f14 l,	\ Config2
h# 0104.0101 l,	\ CRT config register 2

\ Some more shorthand helpers
: config1@  ( -- l )  config1 rl@ ;	\ Read config1 register
: config1!  ( l -- )  config1 rl! ;	\ Write config1 register
: config2@  ( -- l )  config2 rl@ ;	\ Read config2 register
: config2!  ( l -- )  config2 rl! ;	\ Write config2 register

defer crt-data				\ Plug this with resolution data
['] crt-data-1024 to crt-data		\ Default this to something

: program-crt-regs  ( -- )
   d# 13 0 do
\      crt-data-1024 i la+ l@		\ CRT regs start at rbaseg + 0x20
      crt-data i la+ l@		\ CRT regs start at rbaseg + 0x20
      rbaseg h# 20 + i la+ rl!
   loop
   0 rbaseg h# 54 + rl!			\ Zoom factor
;

: crt-config-1@  ( -- reg )		\ Read CRT configuration register 1
   rbaseg h# 58 + rl@
;

: crt-config-1!  ( reg -- )		\ Write CRT configuration register 1
   rbaseg h# 58 + rl!
;

: crt-config-2@  ( -- reg )		\ Read CRT configuration register 2
   rbaseg h# 5c + rl@
;

: crt-config-2!  ( reg -- )		\ Write CRT configuration register 2
   rbaseg h# 5c + rl!
;

: i128-video-on  ( -- )			\ Enable video
   crt-config-1@ 40 or crt-config-1!
;

: i128-video-off  ( -- )		\ Disable video
   crt-config-1@ 40 invert and crt-config-1!
;

: softreg-clk!  ( w -- )		\ Write soft reg, then clear load-clk
   softreg!		( )
   softreg@		( w )
   h# 200 invert and	( w' )
   softreg!		( )
;

: mem-clk-45  ( -- )		\ Sets the memory clock to 40 Mhz
   softreg@ h# 0f invert and	( old' )	\ Get old reg value
   h# 200 or			( old|200 )	\ Set load clock
   h# d or			( old|200|d )	\ Set 45 Mhz Mem clk
   softreg-clk!			( )
;

: engine-clk-40  ( -- )
   softreg@ h# 30 invert and	( old' )	\ Get old bits
   h# 200 or			( old|200 )	\ Set load clock
   softreg-clk!			( )
;

: init-i128-controller  ( -- )

   \ For multiple resolutions, we can modify this first bit of
   \ of init to select the proper tables etc.

   1024-resolution			\ Call back to generic init code
   ['] crt-data-1024 to crt-data	\ Local resolution setup

   \ From here on, the intent is for the code to be generic, e.g.
   \ after resolution table is selcted, the following code works
   \ the regardless of choice.

   mem-clk-45				\ Set mem clk to 45 Mhz
   engine-clk-40			\ Set engine clk to 40 Mhz

   crt-data d# 12 la+ l@		\ Set the config1 register
   config1!

   crt-data d# 13 la+ l@		\ Set the config2 register
   config2!

   0 crt-config-1!			\ Initialize
   0 crt-config-2!			\ Initialize   
   program-crt-regs			\ Set basic timings

   crt-config-1@ 2 or crt-config-1!	\ Positive VSync
   crt-config-1@ 30 or crt-config-1!	\ Enable vertical and horizontal syncs
   crt-config-1@ 100 or crt-config-1!	\ SCLK is output

   crt-data d# 14 la+ l@		\ Set the crt configuration 2 register
   crt-config-2!

   0 rbasew rl!				\ Init read write masks
   h# ffff.ffff rbasew h# 24 + rl!	\ Write mask
   c rbasew 8 + rl!			\ Window size to 4MB
   0 rbasew h# 10 + rl!			\ ORG to 0
   0 rbasew h#  c + rl!			\ PGE to 0
;

: reinit-i128-controller  ( -- )
   led-off
;

: use-i128-words  ( -- )		\ Turns on the i128 specific words
   ['] map-i128-io-regs to map-io-regs
   ['] unmap-i128-io-regs to unmap-io-regs
   ['] map-i128-frame-buffer to map-frame-buffer
   ['] unmap-i128-frame-buffer to unmap-frame-buffer
   ['] init-i128-controller to init-controller
   ['] reinit-i128-controller to reinit-controller
   ['] i128-video-on to video-on
   use-i128-dac-methods
;

: probe-dac  ( -- )			\ Chained DAC prober
   n9? 0=  if
      probe-dac
   else
      use-ibm561-dac
   then
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
