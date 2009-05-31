purpose: Driver for Via Unichrome Pro, model VX855


hex
headers


\ width and height are global instead of instance values because
\ the seltest method needs to get their values in a fresh instance
\ with re-running the open method.
d# 1280 ( instance ) value width	\ Frame buffer line width
d# 1024 ( instance ) value height	\ Screen height
d#   16 instance value depth		\ Bits per pixel
d# 1024 instance value /scanline	\ Frame buffer line width

: declare-props  ( -- )		\ Instantiate screen properties
   " width" get-my-property  if  
      width  encode-int " width"     property
      height encode-int " height"    property
      depth  encode-int " depth"     property
      /scanline  encode-int " linebytes" property
   else
      2drop
   then
;

: /fb  ( -- )  /scanline height *  ;	\ Size of framebuffer

0 instance value mmio-base

: map-io-regs  ( -- )
   mmio-base  if  exit  then
   (map-io-regs)  to mmio-base
   h# 4 my-space + " config-w@" $call-parent  7 or
   h# 4 my-space + " config-w!" $call-parent
;

: map-frame-buffer  ( -- )
   (map-frame-buffer)  to frame-buffer-adr
   frame-buffer-adr encode-int " address" property
;


\ \ VGA register access
\ 
\ \ reset attribute address flip-flop
\ : reset-attr-addr  ( -- )  h# 3da ( input-status1 )  pc@ drop  ;
\ 
\ : video-mode!  ( b -- )  reset-attr-addr  h# 03c0 pc!  ;
\ : attr!  ( b index -- )  reset-attr-addr h# 03c0 pc!  h# 03c0 pc!  ;
\ : attr@  ( index -- b )
\    reset-attr-addr  h# 03c0 pc!  h# 03c1 pc@  reset-attr-addr
\ ;
\ : grf!   ( b index -- )  h# 03ce pc!  h# 03cf pc!  ;
\ : grf@   ( index -- b )  h# 03ce pc!  h# 03cf pc@  ;
\ 
\ : crt@  ( index -- byte )  h# 3d4 pc!  h# 3d5 pc@  ;
\ : crt!  ( byte index -- )  h# 3d4 pc!  h# 3d5 pc!  ;
\ 
\ : seq@  ( index -- byte )  h# 3c4 pc!  h# 3c5 pc@  ;
\ : seq!  ( byte index -- )  h# 3c4 pc!  h# 3c5 pc!  ;
\ 
\ : misc@  ( -- byte )  h# 3cc pc@  ;
\ : misc!  ( byte -- )  h# 3c2 pc!  ;

: pll,  ( v44 v45 v46 misc -- )  bljoin l,  ;

\ Timing table for various resolutions

decimal
create res-table
\ width  height  htotal  hsync hsyncend  vtotal  vsync vsyncend        --pll-- misc
  640 w,  480 w,  800 w,  656 w,  752 w,  525 w,  489 w,  523 w,  hex  8d 10 05 cf pll,  decimal
  800 w,  600 w, 1056 w,  840 w,  968 w,  628 w,  600 w,  619 w,  hex  70 0c 05 0f pll,  decimal
 1024 w,  768 w, 1344 w, 1048 w, 1184 w,  806 w,  770 w,  776 w,  hex  b6 0c 05 cf pll,  decimal
 1200 w,  900 w, 1240 w, 1208 w, 1216 w,  912 w,  905 w,  907 w,  hex  9d 8c 85 cf pll,  decimal
 1280 w,  768 w, 1664 w, 1344 w, 1472 w,  798 w,  770 w,  777 w,  hex  6f 08 05 4f pll,  decimal
 1280 w,  800 w, 1680 w, 1352 w, 1480 w,  831 w,  802 w,  808 w,  hex  46 88 83 4f pll,  decimal
 1280 w, 1024 w, 1688 w, 1328 w, 1440 w, 1066 w, 1024 w, 1027 w,  hex  97 08 05 0f pll,  decimal
 1368 w,  768 w, 1800 w, 1440 w, 1584 w,  795 w,  768 w,  771 w,  hex  78 88 85 0f pll,  decimal
 1440 w,  900 w, 1904 w, 1520 w, 1672 w,  934 w,  902 w,  908 w,  hex  77 08 04 4f pll,  decimal
 1600 w, 1200 w, 2160 w, 1664 w, 1856 w, 1250 w, 1200 w, 1219 w,  hex  71 04 05 0f pll,  decimal
 1680 w, 1050 w, 2240 w, 1784 w, 1960 w, 1089 w, 1052 w, 1058 w,  hex  ce 08 05 4f pll,  decimal
 1920 w, 1080 w, 2576 w, 2048 w, 2248 w, 1120 w, 1082 w, 1103 w,  hex  79 04 05 0f pll,  decimal
 1920 w, 1200 w, 2592 w, 2056 w, 2256 w, 1245 w, 1202 w, 1224 w,  hex  87 04 05 4f pll,  decimal
here res-table - constant /res-table

: /res-entry  ( -- n )  8 /w* la1+  ;

\ width  height  htotal  hsync hsyncend  vtotal  vsync vsyncend        --pll-- misc
create mode3-table
\  640 w,  400 w,  800 w,  680 w,  776 w,  449 w,  412 w,  430 w,  hex  35 04 05 67 pll,  decimal
  640 w,  400 w,  800 w,  680 w,  776 w,  449 w,  412 w,  430 w,  hex  54 90 03 67 pll,  decimal

\ width  height  htotal  hsync hsyncend  vtotal  vsync vsyncend        --pll-- misc
create mode12-table
  640 w,  480 w,  800 w,  672 w,  768 w,  525 w,  490 w,  492 w,  hex  35 04 05 e3 pll,  decimal

0 value res-entry

: mode-3?   ( -- flag )  res-entry mode3-table  =  ;
: mode-12?  ( -- flag )  res-entry mode12-table =  ;

: find-timing-table  ( width height depth  -- error? )
   \ Mode12 check
   4 =  if  2drop mode12-table to res-entry  false exit  then   ( width height )

   \ Text mode 3 check
   dup d# 400 =  if  2drop mode3-table to res-entry  false exit  then  ( width height )

   res-table /res-table bounds  ?do  ( width height )
      over i w@ =  if                ( width height )
         dup i wa1+ w@ =  if         ( width height )
            i to res-entry           ( width height )
            2drop false              ( false )
            unloop exit
         then                        ( width height )
      then                           ( width height )
   /res-entry +loop                  ( width height )
   2drop true                        ( true)
;

hex

\ Stored values from table
: htotal   ( -- n )  res-entry 2 wa+ w@  ;
: hsync    ( -- n )  res-entry 3 wa+ w@  ;
: hsyncend ( -- n )  res-entry 4 wa+ w@  ;
: vtotal   ( -- n )  res-entry 5 wa+ w@  ;
: vsync    ( -- n )  res-entry 6 wa+ w@  ;
: vsyncend ( -- n )  res-entry 7 wa+ w@  ;
: pll      ( -- l )  res-entry 8 wa+ l@  ;
: miscval  ( -- b )  pll lbsplit nip nip nip  ;

\ Derived values
: hdisplay ( -- n )  width  ;
: hblank   ( -- n )
   width
   mode-3?   if  8 +  then
   mode-12?  if  8 +  then
;
: hblankend  ( -- n )
\  mode-3?  if  d# 288 exit  then
   mode-3?  if  d# 792 exit  then
   mode-12? if  d# 792 exit  then
   htotal
;
: vdisplay ( -- n )  height  ;
: vblank   ( -- n )
   height
   mode-3?   if  7 +  then
   mode-12?  if  8 +  then
;
: vblankend  ( -- n )
   mode-3?  if  d# 442 exit  then
   mode-12? if  d# 517 exit  then
   vtotal
;
\ End of section that determines the mode-dependent basic timing parameters

: use-ext-clock  ( -- )   misc@ h# c or misc!  ;
: set-primary-dotclock  ( clock -- )
   lbsplit drop  h# 46 seq!  h# 45 seq!  h# 44 seq!

   40 seq@  dup 2 or  40 seq!  2 invert and 40 seq!  \ Pulse VCK PLL reset high
;
: set/clr  ( value mask on? -- )  if  or  else  invert and  then  ;
: set-dvp-power  ( on? -- )
   h# 1e seq@  h# 30
   rot  set/clr
   h# 1e seq!
;
: set-vcp-power  ( on? -- )
   h# 1e seq@  h# c0
   rot  set/clr
   h# 1e seq!
;
: set-spread-spectrum  ( on? -- )
   h# 1e seq@  8
   rot  set/clr
   h# 1e seq!
;

: set-gamma  ( on? -- )
   >r
   h# 33 crt@  h# 80
   r@  set/clr
   h# 33 crt!
   
   \ DVP
   h# 32 crt@  h# 2
   r@  set/clr
   h# 32 crt!
   
   \ LCD
   h# 6a crt@  h# 2
   r>  set/clr
   h# 6a crt!
;
\ Unichrome driver uses the wrong bit for enabling DVP "Grammar" correction

: bitclr  ( value mask -- )  invert and  ;
: crt-mask  ( value mask reg# -- )
   >r r@ crt@   ( value mask oldval )
   over bitclr  ( value mask oldval' )
   -rot and or  ( val' )
   r> crt!
;
: seq-mask  ( value mask reg# -- )
   >r r@ seq@   ( value mask oldval )
   over bitclr  ( value mask oldval' )
   -rot and or  ( val' )
   r> seq!
;

: seq-set  ( mask reg# -- )  tuck seq@ or swap seq!  ;
: seq-clr  ( mask reg# -- )  tuck seq@ swap invert and swap seq!  ;

\ : crt-set  ( mask reg# -- )  tuck crt@ or swap crt!  ;
\ : crt-clr  ( mask reg# -- )  tuck crt@ swap invert and swap crt!  ;
: crt-clr  crt-clear  ;

: pixels>bytes  ( pixels -- bytes )
   depth d# 24 =  if  d# 32   else  depth  then  *  3 >>  ( bytes )
;
: bytes>chunks  ( bytes -- chunks )  3 >> 4 round-up  ;

: lower-power  ( -- )
   7f 19 seq!  \ clock gating
   30 1b seq!  \ clock gating
   f3 2d seq!  \ Power control enables
   ff 2e seq!  \ clock gating
   ff 3f seq!  \ clock gating
   5f 4f seq!  \ clock gating threshold
   df 59 seq!  \ clock gating
   01 36 crt!  \ Enable PCI power management control
   34 37 crt!  \ DAC power savings

   00 a8 seq!  \ leave on ROC ECK in C0
   00 a9 seq!  \ leave on ROC ECK in C1
   80 aa seq!  \ gate off ROC ECK in C4
   80 ab seq!  \ gate off ROC ECK in C3
   00 ac seq!  \ leave on ROC ECK in S3
   00 ad seq!  \ leave on ROC ECK in S1 Snapshot
   00 ae seq!  \ leave on ROC ECK in C4P
   00 af seq!  \ leave on ROC ECK in reserved state
;

: legacy-settings  ( -- )
   \ Some EGA legacy mode settings
   03 00 seq!  \ Release reset bits
   mode-3?  if  00  else  01  then
      01 seq!  \ 8/9 timing (0 for mode 3)
   mode-3?  if  03  else  0f  then
      02 seq!  \ Enable map planes 0 and 1 (3 for mode 3)
   00 03 seq!  \ Character map select
   mode-3?  if  02  else  0e  then
      04 seq!  \ Extended memory present (2 for mode 3)
   0d 0a crt!  \ Cursor start (text mode)
   0e 0b crt!  \ Cursor end (text mode)
   00 0e crt!  \ Cursor loc (text mode)
   00 0f crt!  \ Cursor loc (text mode)
   mode-3?  if  60  else  mode-12?  if  70  else  10  then  then
      11 crt!  \ Refreshes per line, disable vertical interrupt (60 in mode 3, 70 in mode 12)
   mode-12?  if  63  else  23  then
      17 crt!  \ address wrap, sequential access, not CGA compat mode (63 in mode 12)


   04 0e crt!  \ Make the register dump match the snapshots
   60 0f crt!
   01 49 crt!
;

: general-init  ( -- )
   1e seq@ 1 or 1e seq!  \ ROC ECK
   00 20 seq!  \ max queuing number (but manual recommends 4)
   10 22 seq!  \ (display queue request expire number)
   40 34 seq!  \ not documented
   01 3b seq!  \ not documented
   38 40 seq!  \ ECK freq
   30 4d seq!  \ preempt arbiter
   08 30 crt!  \ DAC speed enhancement
\  00 38 crt!  \ Signature 0 - not writable, empirically
\  21 39 crt!  \ Signature 1
\  32 3a crt!  \ Signature 2
   01 3b crt!  \ Scratch 2
   08 3c crt!  \ Scratch 3
   c0 f7 crt!  \ Spread spectrum
   01 32 crt!  \ real time flipping (I think we can ignore this)
;
\ SRs set in romreset: 35-38,39,4c,68,6d-6f,78,f3

: tune-fifos  ( -- )
   mode-3? mode-12? or  if  0c  else  20  then
      3f 16 seq-mask  \ FIFO threshold (VX855 value) (value is c in modes 3 and 12)
   mode-3? mode-12? or  if  1f  else  7f  then
      ff 17 seq-mask  \ FIFO depth (VX855 value)  (value is 1f in modes 3 and 12)
   60 ff 18 seq-mask  \ Display Arbiter (VX855 value)

   18 21 seq!  \ (typical request track FIFO number channel 0
   1f 50 seq!  \ FIFO
   81 51 seq!  \ FIFO
   00 57 seq!  \ FIFO
   08 58 seq!  \ FIFO
   20 66 seq!  \ request kill
   20 67 seq!  \ request kill
   20 69 seq!  \ request kill
   20 70 seq!  \ request kill
   0f 72 seq!  \ FIFO
   08 79 seq!  \ request kill
   10 7a seq!  \ request kill
   c8 7c seq!  \ request kill
;
: mode-independent-init  ( -- )
   general-init legacy-settings tune-fifos lower-power
;

: set-primary-vga-mode  ( -- )
   80 11 crt-clr  \ Enable writing to CRT0-7
   80 03 crt-set  \ Enable vertical retrace access
   01 10 seq!     \ Unlock extended registers

   miscval  misc!

\   0 0 seq!  \ Sequence registers

\   01 df 01 seq-mask
\   00       03 seq!

\   a2 e2 15 seq-mask   \ (22 for mode 3, for 6-bit LUT)
   22 e2 15 seq-mask   \ (22 for mode 3, for 6-bit LUT)
   depth case
          8 of  00  endof
      d# 16 of  14  endof
      d# 24 of  0c  endof
      d# 32 of  0c  endof
   endcase
   1c 15 seq-mask  

   28 fd 1a seq-mask  \ Extended mode memory access (value is 20 in modes 3 and 12)
   
   " "(00 00 00 00 00 00 05 0f ff)"  0  do  ( adr )
      dup c@  i grf!  1+
   loop  drop

   \ For mode  3, add:   10 5 grf!  0e 6 grf!  0 7 grf!
   mode-3?  if
      10 5 grf!
      0e 6 grf!
      00 7 grf!
   then
\ For mode 13, add:   40 5 grf!

   0 20 grf!  0 21 grf!  0 22 grf!

   \ AT6 is 6 not 14, AT8-f is 8-f, not 38-3f (different intensities)
   10 0  do  i i attr!  loop
   mode-3?  if  0c  else  01  then
      10 attr! \ mode control (0c for text mode 3)
   00 11 attr! \ overscan color
   0f 12 attr! \ color plane enable
   mode-3?  if  08  else  00  then
      13 attr! \ horizontal pixel pan - (08 for text mode 3)
   00 14 attr! \ high bits of color palette index

   htotal    3 >> 5 - dup 00 crt!  5 >> 08  36 crt-mask

   hdisplay  3 >> 1-  01 crt!
   hblank    3 >> 1-  02 crt!

   hblankend 3 >> 1-  dup 1f 03 crt-mask  dup 2 << 80 05 crt-mask  1 >> 20 33 crt-mask

   hsync     3 >>     dup 04 crt!  4 >> 10 33 crt-mask
   hsyncend  3 >> 1f 05 crt-mask

   vtotal 2-       dup 06 crt!  dup 8 >> 01 07 crt-mask  dup 4 >> 20 07 crt-mask  d# 10 >> 01 35 crt-mask
   vdisplay 1-     dup 12 crt!  dup 7 >> 02 07 crt-mask  dup 3 >> 40 07 crt-mask  8 >> 04 35 crt-mask
   
   \ Starting address
   0 0c crt!  0 0d crt!  0 34 crt!  0 3 48 crt-mask

   vsync           dup 10 crt!  dup 6 >> 04 07 crt-mask  dup 2 >> 80 07 crt-mask  9 >> 02 35 crt-mask
   vsyncend  0f 11 crt-mask

   \ Line compare value 3fff
   ff 18 crt!  10 7 crt-set  40 9 crt-set  10 35 crt-set

   \ HSYNC adjust
   mode-3?  if  01  else  mode-12?  if  00  else  06  then  then
      07 33 crt-mask  \ 01 for text mode 3, 00 for mode 12

   \ Max scan line value 0
   mode-3?  if  0f  else  00  then  1f 9 crt-mask
   1f 14 crt!  \ Underline location
 
   vblank    1-  dup 15 crt!  dup 5 >> 08 07 crt-mask  dup 4 >> 20 09 crt-mask  7 >> 08 35 crt-mask
   vblankend 1-      16 crt!

   00 08 crt!     \ Preset row scan
\  00 32 crt!     \ HSYNC delay, SYNC drive, gamma, end blanking, etc  Already set
   c8 33 crt-clr  \ Gamma, interlace, prefetch, HSYNC shift

   \ Offset
   mode-3?  if
      d# 40
   else
      width pixels>bytes to /scanline
      /scanline bytes>chunks
   then
   dup 13 crt!  3 >> e0 35 crt-mask

   \ fetch count
   hdisplay pixels>bytes bytes>chunks 8 +  dup 1 >> 1c seq!  9 >> 03 1d seq-mask
;

\ XXX unichrome has duplicate setting of regs CR32 and CR33 near end of ViaModePrimaryVGA

: set-primary-mode  ( width height depth -- error? )
   to depth  to height  to width
   width height depth find-timing-table  ?dup  if  exit  then

   80 17 crt-clr  \ Assert reset

   mode-independent-init

   \ Clean Second Path Status
   00 f6 6a crt-mask
   00 6b crt!
   00 6c crt!
   00 93 crt!

   set-primary-vga-mode

   08 1a seq-set  \ Enable MMIO

\   08 33 crt-set  \ Enable CRT prefetch (VESA BIOS doesn't set this)

\   depth 8 <> set-gamma   \ No gamma for 8bpp palette mode
   false set-gamma

   mode-3?  0=  if
      pll set-primary-dotclock
      use-ext-clock
   then

\  01 6b crt-clr  \ Appears to be reserved RO bit

   80 17 crt-set  \ Release reset
   false          \ No error
;

0 [if]
: set-secondary-dotclock  ( clock -- )
   lbsplit drop  h# 4a seq!  h# 4b seq!  h# 4c seq!

   40 seq@  dup 4 or  40 seq!  4 invert and 40 seq!  \ Pulse LCDCK PLL reset high
;
: set-secondary-vga-mode  ( mode -- )
   depth case
          8 of  00  endof
      d# 16 of  40  endof
      d# 24 of  80  endof
      d# 32 of  80  endof
   endcase
   c0 67 crt-mask

   htotal    1-  dup 50 crt!      8 >> 0f 55 crt-mask
   hdisplay  1-  dup 51 crt!      4 >> 70 55 crt-mask
   hblank    1-  dup 52 crt!      8 >> 07 54 crt-mask
   hblankend 1-  dup 53 crt!  dup 5 >> 38 54 crt-mask      5 >> 40 5d crt-mask

\ unichrome omits bit 11, which goes in CR5D[7]
   hsync         dup 56 crt!  dup 2 >> c0 54 crt-mask  dup 3 >> 80 5c crt-mask  4 >> 80 5d crt-mask
   hsyncend      dup 57 crt!      2 >> 40 5c crt-mask

   vtotal    1-  dup 58 crt!      8 >> 07 5d crt-mask
   vdisplay  1-  dup 59 crt!      5 >> 38 5d crt-mask
   
   vblank    1-  dup 5a crt!      8 >> 07 5c crt-mask
   vblankend 1-  dup 5b crt!      5 >> 38 5c crt-mask

   vsync         dup 5e crt!      3 >> e0 5f crt-mask
   vsyncend          5f 1f crt-mask

   \ Offset
   width pixels>bytes bytes>chunks  dup 66 crt!  8 >> 03 67 crt-mask

   \ fetch count
   hdisplay pixels>bytes bytes>chunks 8 +  dup 1 >>  65 crt!  7 >>  0c  67 crt-mask
;

: set-secondary-mode  ( -- )
   80 17 crt-clr  \ Assert reset - Turn off screen
   set-secondary-vga-mode
   \ Turn on power here?
   1e 6c crt-clr
   dotclock set-secondary-dotclock
   use-ext-clock   
   80 17 crt-set  \ Release reset
;
[then]

[ifdef] xo-board
: setup-lcd  ( -- )
   h# 80 h# f3 crt-set  \ 18-bit TTL LCD mode
   h# 10 h# 30 h# 1e crt-mask  \ DVP pads controlled by other control
\  h# 30 h# 30 h# 1e crt-mask  \ DVP pads controlled by PMS
\  h# 0f h# 0f h# 65 crt-mask  \ High drive for DVP

\  h# 80 h# 9b crt!  \ DVP mode - alpha:80, VSYNC:40, HSYNC:20, secondary:10, clk polarity:8, clk adjust:7
;
[then]

hex
0 [if]
: .cr
   h# 20 0  do
     i 2 u.r space
     i h# 10 bounds  do  i crt@ 3 u.r  loop  cr
   h# 10 +loop
   h# 100 h# 30  do
     i 2 u.r space
     i h# 10 bounds  do  i crt@ 3 u.r  loop  cr
   h# 10 +loop
;
: .sr
   h# 80 0  do
     i 2 u.r space
     i h# 10 bounds  do  i seq@ 3 u.r  loop  cr
   h# 10 +loop
   h# b0 h# a0  do
     i 2 u.r space
     i h# 10 bounds  do  i seq@ 3 u.r  loop  cr
   h# 10 +loop
;
: .gr  9 0 do  i grf@ 3 u.r loop  cr  ;

: bios-table-adr  ( -- adr )  h# c001b w@  h# c0000 +  ;
[then]

defer init-hook  ' noop is init-hook

: init-all  ( -- )		\ Initializes the controller
\  smb-init
   map-io-regs			\ Enable IO registers
   width height depth set-primary-mode drop
   declare-props		\ Setup properites
\   set-dac-colors		\ Set up initial color map
\   video-on			\ Turn on video

   map-frame-buffer
   depth case
      8      of  frame-buffer-adr /fb h#        0f  fill  endof
      d# 16  of  frame-buffer-adr /fb background-rgb  rgb>565  wfill  endof
      d# 32  of  frame-buffer-adr /fb h# ffff.ffff lfill  endof
   endcase
   h# f to background-color
;

: display-remove  ( -- )
;

: display-install  ( -- )
   init-all
   default-font set-font
   width  height                           ( width height )
   over char-width / over char-height /    ( width height rows cols )
   /scanline depth fb-install ( gp-install )  ( )
   init-hook
;

: display-selftest  ( -- failed? )  false  ;

' display-install  is-install
' display-remove   is-remove
' display-selftest is-selftest

" display"                      device-type
" ISO8859-1" encode-string    " character-set" property
0 0  encode-bytes  " iso6429-1983-colors"  property

\ LICENSE_BEGIN
\ Copyright (c) 2009 FirmWorks
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
