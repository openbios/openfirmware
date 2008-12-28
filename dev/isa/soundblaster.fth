purpose: SoundBlaster driver
copyright: Copyright 1997 FirmWorks  All Rights Reserved

hex

headers
\needs +i            : +i  ( adr len n -- adr' len' )   encode-int encode+  ;
\needs encode-null   : encode-null  ( -- adr len )  0 0 encode-bytes   ;
\needs microseconds  : microseconds  ( n -- )  0 do  d# 4 0 do loop  loop  ;

0 0  " i220"  " /isa" begin-package
   " sound"  device-name
   " sound"  device-type

   h# 10 encode-int      " #channels"   property

   encode-null " built-in" property

   encode-null
      d#  9 encode-int encode+  1 encode-int encode+	\ Input (capture)
      d# 15 encode-int encode+  1 encode-int encode+	\ Output (playback)
   " interrupts"  property

   encode-null
   \ Channel Type(2=F)  DataBits  CountBits  BusMastering?
      0 +i      3 +i      8 +i     d# 16 +i      0 +i	\ First channel
      5 +i      3 +i      8 +i     d# 16 +i      0 +i	\ Second channel
   " dma" property


true instance value use-dma?		\ set at open
false instance value polled-mode?	\ set at read/write/tone

: dma-alloc    ( n -- vaddr )  " dma-alloc" $call-parent  ;
: dma-free     ( vaddr n -- )  " dma-free" $call-parent  ;

1 value dma-channel#
: >chan  ( offset -- port )  dma-channel# wa+  ;
: low-page  ( -- port )  " "(87 83 81 82)" drop dma-channel# + c@  ;
: high-page  ( -- port )  low-page h# 400 +  ;
: dma-setup  ( vadr len write-memory? -- vadr devaddr len )
   if  44  else  48  then  dma-channel# +  b pc!   \ single transfer, increment addr,
				                   \ no autoinit, ch 0
   \ Autoinit adds the 0x10 bit

   2dup true  " dma-map-in" $call-parent  swap     ( vadr devadr len )

   \ Load count
   0 c pc!		        \ Reset address byte pointer
   dup 1- wbsplit  swap  1 >chan pc!  1 >chan pc!  ( vadr devadr len )

   \ Load address
   0 c pc!		        \ Reset address byte pointer
   over  lbsplit  2swap  swap
   0 >chan pc!  0 >chan pc!	( vadr devadr len page-byte hi-byte )
   swap low-page pc!		( vadr devadr len hi-byte )
   high-page pc!		( vadr devadr len )

   c0 d6 pc!  			\ Set cascade mode for channel 4
   0 d4 pc!			\ Release channel 4 (master for chs. 0-3)

   0 dma-channel# +  a pc!	\ Release channel

\   10 8 pc!			\ re-enable the chip
;
: dma-wait  ( vaddr devaddr len -- timeout? )
   1 dma-channel# <<  true swap
   d# 400  0  do
      dup 8 pc@  and  if  nip 0 swap  leave  then
      d# 10 ms
   loop
   drop
   >r
   " dma-map-out" $call-parent
   r>
;

: mixer!   ( byte regnum -- )  h# 224 pc!  h# 225 pc!  ;
: mixer@   ( regnum -- byte)   h# 224 pc!  h# 225 pc@  ;

\ 82 is the IRQ status register
: irq-wait  ( vaddr devaddr len bit -- timeout? )
   true swap            ( vaddr devaddr len timeout? bit )
   d# 400  0  do        ( vaddr devaddr len timeout? bit )
      dup 82 mixer@  and  if  nip 0 swap  leave  then
      d# 10 ms          ( vaddr devaddr len timeout? bit )
   loop                 ( vaddr devaddr len timeout? bit )
   drop                 ( vaddr devaddr len timeout? )
   >r
   " dma-map-out" $call-parent
   r>
;

\ The SCR0 value "1c" enables the audio device at port 220, the joystick
\ at port 201, and establishes the port address of (but does not enable)
\ the FM synthesizer at port 388.
: enable  ( -- )
\   0 h# fb pc!  0 h# e0 pc!  h# 1c h# e1 pc!   0 h# f9 pc!
   3 h# 40 mixer!       \ Enable the synthesizer and game ports
;

: read1  ( -- byte )  begin  h# 22e pc@ h# 80 and  until  h# 22a pc@  ;

: wait-reset  ( -- )
   get-msecs
   begin                                                 ( old-ms )
     h# 22e pc@ h# 80 and  if                            ( old-ms )
        h# 22a pc@  h# aa =  if  drop exit  then         ( old-ms )
     then                                                ( old-ms )
     get-msecs over -  2 >=                              ( old-ms flag )
  until                                                  ( old-ms )
  drop
;

: rddata@  ( -- b )  22c pc@  ;
: cmd  ( cmd -- )  begin  rddata@  h# 80 and  0= until  h# 22c pc!  ;
: cmd1!  ( data cmd -- data )  cmd cmd  ;
: cmd1@  ( cmd -- data )  cmd read1  ;
: cmd2!  ( data data cmd -- data )  cmd cmd cmd  ;
: cmd2@  ( cmd -- data data )  cmd read1 read1  ;

: put8  ( byte -- )  10 cmd1!  ;
: get8  ( -- byte )  20 cmd1@  ;
\ : put16  ( word -- )  11 cmd1!  ;
\ : get16  ( -- word )  21 cmd1@  ;

: start-out8-normal   ( length -- )  1-  wbsplit swap  14 cmd2!  ;
\ : start-out16-normal  ( length -- )  1-  wbsplit swap  15 cmd2!  ;
: start-out8-auto     ( length -- )  1-  wbsplit swap  1c cmd2!  ;
\ : start-out16-auto    ( length -- )  1-  wbsplit swap  1d cmd2!  ;

: start-out8-fast  ( -- )  90 cmd  ;
: start-out16-fast  ( -- )  91 cmd  ;
: halt-dma8  ( -- )  d0 cmd  ;
\ d1 and d3 above
: continue-dma8  ( -- )  d4 cmd  ;
: halt-dma16  ( -- )  d5 cmd  ;
: continue-dma16  ( -- )  d6 cmd  ;
: exit-dma16  ( -- )  d9 cmd  ;
: exit-dma8  ( -- )  da cmd  ;
\ e0 returns the bitwise inverse of its argument byte, for probing
\ e3 returns a copyright string
\ e4 writes a test register, e8 reads it back
\ f2 and f3 force an irq

\ : start-in8-normal   ( length -- )  1-  wbsplit swap  24 cmd2!  ;
\ : start-in16-normal  ( length -- )  1-  wbsplit swap  25 cmd2!  ;
\ : start-in8-auto     ( length -- )  1-  wbsplit swap  2c cmd2!  ;
\ : start-in16-auto    ( length -- )  1-  wbsplit swap  2d cmd2!  ;

: set-block-size  ( n -- )  1-  wbsplit swap  48 cmd2!  ;

: set-time-constant  ( b -- )  40 cmd1!  ;   \ rate = 1,000,000 / (256 - n)
: set-freq           ( w -- )  1- wbsplit swap  41 cmd2!  ;  \ 

0 instance value sample-counts
0 instance value sample-rate

: 1sample-time  ( -- )  sample-counts  0  do  loop  ;
: sb-sample!  ( byte -- )  put8 1sample-time  ;
: sb-sample@  ( -- byte )  get8 1sample-time  ;
: passthrough  ( seconds -- )
   sample-rate *  0  do  get8 put8 1sample-time  loop
;

: set-sample-rate  ( hz -- )
   dup to sample-rate
   ms-factor d# 1000 rot */  to sample-counts
;

: 8kmono  ( -- )  d# 131  set-time-constant  h# 8000 set-sample-rate  ;
: 8kstereo  ( -- )  d# 16000  set-freq  h# 8000 set-sample-rate  ;
: 16kmono  ( -- )  d# 16000  set-freq  h# 16000 set-sample-rate ;
: 11kmono  ( -- )  d# 165  set-time-constant  h# 11025 set-sample-rate  ;
: 11kstereo  ( -- )  d# 11025  set-freq  h# 11025 set-sample-rate  ;
: 22kmono    ( -- )  d# 22050  set-freq  h# 22050 set-sample-rate  ;

: dac>mixer  ( -- )  d# 100 ms  h# d1 cmd  ;
: undac>mixer  ( -- )  d# 25 ms  h# d3 cmd  ;
: reset  ( -- )
   enable  
   1 h# 226 pc!  
   d# 300 ms  0 h# 226 pc!  wait-reset  dac>mixer
;

[ifndef] rounded-/
\ Integer division which rounds to nearest instead of truncating
: rounded-/  ( dividend divisor -- rounded-result )
   swap 2*  swap /  ( result*2 )
   dup 1 and +      \ add 1 to the result if it is odd
   2/               ( rounded-result )
;
[then]

defer sample!  ['] sb-sample! to sample!
defer sample@  ['] sb-sample@ to sample@

: dma-sample@  ( adr size -- actual )
\   dup set-block-size
   tuck                ( size  adr size )
   true dma-setup      ( size  vadr devadr len )
   \ use "2 irq-wait" for 16-bit DMA
   1 irq-wait  if  drop 0  then   ( actual )
;
: dma-sample!  ( adr size -- actual )
\   dup set-block-size
   tuck                   ( size adr size )
   false dma-setup        ( size vadr devadr len )
   dac>mixer              ( size vadr devadr len )
   dup start-out8-normal  ( size vadr devadr len )
   1 irq-wait  if  drop 0  then   ( actual )
   undac>mixer                  ( actual )
;

\ Mixer 80 is IRQ#
\ Mixer 81 is DMA  hdma and dma
\ Mixer 82 is IRQ status

: stereo  ( -- )  2 h# 0e mixer!  ;
: mono    ( -- )  0 h# 0e mixer!  ;

: reset-mixer  ( -- )  0 0 mixer!  ;

: dac-volume  ( l/r -- )  14 mixer!  ;
: mic-mix-volume  ( l/r )  1a mixer!  ;
: record-mic   ( -- )  0 1c mixer!  ;
: record-cd    ( -- )  2 1c mixer!  ;
: record-line  ( -- )  6 1c mixer!  ;
: record-mixer ( -- )  7 1c mixer!  ;

: master-volume  ( l/r -- )  22 mixer!  ;
: fm-volume  ( l/r -- )  26 mixer!  ;
: auxa-volume  ( l/r -- )  28 mixer!  ;
: auxb-volume  ( l/r -- )  2a mixer!  ;
: pc-speaker-volume  ( l/r -- )  2c mixer!  ;
\ : line-volume  ( l/r -- )  2e mixer!  ;

h# cc constant initial-gain

external

\ Determine chip type by looking for register bit differences
: init  ( -- )
   enable
   " SoundBlaster"
   2dup model                ( $ )
   encode-string
\     " pnpPNP,b007" encode-string encode+   \ Windows Sound System compatible
   " pnpPNP,b002" encode-string encode+   \ SoundBlaster Pro compatible
   " pnpPNP,b000" encode-string encode+   \ SoundBlaster compatible
   " compatible" property

   \ Probe for the FM synthesizer

   h# 220 my-space d# 16  encode-reg  ( adr len )  \ Soundblaster

   \ If the synthesizer address port is writeable, add the synthesizer
   \ register to the property value

   h# 5a 38a pc!  38a pc@  h# 5a =  if
      h# 388 my-space d#  4  encode-reg encode+   \ Synthesizer
   then
   " reg" property

   \ Put the synthesizer address port back to its default value, just in case
   1 h# 38a pc!
;

: dma  ( -- )  true to use-dma?  ;
: pio  ( -- )  false to use-dma?  ;
: change-mode  ( -- )
   my-args  begin  dup  while       \ Execute mode modifiers
      ascii , left-parse-string            ( rem$ first$ )
      my-self ['] $call-method  catch  if  ( rem$ x x x )
         ." Unknown argument" cr
         3drop 2drop false exit
      then                                 ( rem$ )
   repeat                                  ( rem$ )
   2drop
;
: open  ( -- flag? )
   change-mode
   reset 
   initial-gain master-volume
   true  
;
: close  ( -- )  0 master-volume  ;

: read  ( addr size -- actual )
   use-dma?  if
      false to polled-mode?

      dup dma-alloc over 2dup 2>r
      dma-sample@
      nip 2r@ drop -rot dup >r move r>
      2r> dma-free
   else
      true to polled-mode?

      tuck  bounds ?do  sample@  i c!  loop
   then
;
: write  ( adr size -- actual )
   use-dma?  if
      false to polled-mode?

      dup dma-alloc swap 2dup 2>r move
      2r@ dma-sample!
      2r> dma-free
   else
      true to polled-mode?
      tuck  bounds ?do  i c@ sample!  loop
   then
;
decimal

\ This table contains all 4 quadrants of the sine function, biased with the
\ zero point at d# 128, and beginning at -pi/2 radians (-90 degrees).  This
\ is convenient for sampling.
create sine
   0 c,    3 c,   10 c,   22 c,   38 c,   57 c,   79 c,  104 c,
 128 c,  152 c,  177 c,  199 c,  218 c,  234 c,  246 c,  253 c,
 255 c,  253 c,  246 c,  234 c,  218 c,  199 c,  177 c,  152 c,
 128 c,  104 c,   79 c,   57 c,   38 c,   22 c,   10 c,    3 c,
hex

0 value sample-buf
0 value /sample-buf

\ Play a tone of the given frequency and duration
: tone  ( hz msecs -- )
   8kmono

   8 *                                  ( hz samples )
   dup to /sample-buf  dup dma-alloc  to sample-buf

   \ We divide the circle into 64K counts, increment the angle by "delta"
   \ counts each sample, and pick the closest entry in the sine table.
   \ Here we compute the delta angle from the frequency as:
   \   delta (counts/sample) =
   \      freq (cycles/sec) * 64K (counts/cycle) / 8000 (samples/sec)

   swap  d# 16 lshift  d# 8000 /  swap  ( delta samples )

   true to polled-mode?                 ( delta samples )

   0 swap  0  do                        ( delta angle )
      \ Round to nearest sample ("400 +).  For lower distortion,
      \ we could increase the number of entries in the sine table
      \ and/or interpolate between entries, but it hardly seems
      \ worth the trouble for this application.
      dup  h# 400 +  d# 11 rshift  h# 1f and  sine + c@

      sample-buf i + c!

      \ Update angle, taking advantage of 2-complement arithmetic
      \ to do the modulus for us.  We don't worry about the carry
      \ into the high bits here, because the "1f and" above will
      \ throw them away for us.
      over +                            ( delta angle' )
   loop                                 ( delta angle' )
   2drop                                ( )

   sample-buf /sample-buf dma-sample! drop
   sample-buf /sample-buf dma-free
;

: ring-bell  ( -- )
   open drop
   d# 2000  d# 100  tone  close
;
end-package

also forth definitions
stand-init: Sound
   " /isa/sound" " init" execute-device-method drop
;
previous definitions
