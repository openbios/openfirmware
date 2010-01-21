\ See license at end of file
purpose: Driver for Via Unichrome Pro, model VX855

hex
headers

\ These are non-instance values because we don't want to change
\ their values on a nested open as happens with selftest and
\ the camera sub-node's selftest.

0 value fb-va
0 value mmio-base

d# 1280 value width	\ Frame buffer line width
d# 1024 value height	\ Screen height
d#   16 value depth	\ Bits per pixel
d# 1024 value /scanline	\ Frame buffer line width

\ This writes a memory variable that the early startup code can find,
\ so the resume-from-S3 path can do the right thing
: note-mode  ( mode# -- )  video-mode-adr !  ;
: note-native-mode  ( -- )  native-mode# note-mode  ;

: create-edid-property  ( -- )
   " edid" get-my-property  if  ( )
      " edid" find-drop-in  if  ( adr len )
         2dup encode-bytes  " edid" property  free-mem
      then     ( )
   else        ( adr len )
      2drop    ( )
   then        ( )
;

: declare-props  ( -- )		\ Instantiate screen properties
   " width" get-my-property  if  
      width  encode-int " width"     property
      height encode-int " height"    property
      depth  encode-int " depth"     property
      /scanline  encode-int " linebytes" property
      create-edid-property
   else
      2drop
   then
;

: /fb  ( -- )  /scanline height *  ;	\ Size of framebuffer

\ The "graphmem" method is use by the subordinate camera driver ($call-parent)
\ and by the GUI code ($call-screen) to get the address of some scratch memory
\ in the display controller's space.

: graphmem  ( -- adr )  fb-va /fb +  ;

: map-io-regs  ( -- )
   mmio-base  if  exit  then
   (map-io-regs)  to mmio-base
   h# 4 my-space + " config-w@" $call-parent  7 or
   h# 4 my-space + " config-w!" $call-parent
;

: map-frame-buffer  ( -- )
   (map-frame-buffer)  to fb-va
   fb-va encode-int " address" property
;

: pll,  ( v44 v45 v46 misc -- )  bljoin l,  ;

\ Timing table for various resolutions

decimal
create res-table
\ width  height  htotal  hsync hsyncend  vtotal  vsync vsyncend        --pll-- misc      --vckpll---
  640 w,  480 w,  800 w,  656 w,  752 w,  525 w,  490 w,  523 w,  hex  05 10 8d cf pll,  04 10 97 00 pll,  decimal \ 25.175 MHz nominal
  800 w,  600 w, 1056 w,  840 w,  968 w,  628 w,  600 w,  619 w,  hex  05 0c 70 0f pll,  00 00 00 00 pll,  decimal \ 40.000 MHz nominal
 1024 w,  768 w, 1344 w, 1048 w, 1184 w,  806 w,  770 w,  776 w,  hex  05 0c b6 cf pll,  00 00 00 00 pll,  decimal \ 65.000 MHz nominal

\ This supposedly matches the Geode setup - 56.199 MHz (Geode is 56.229)
\ 1200 w,  900 w, 1240 w, 1208 w, 1216 w,  912 w,  905 w,  910 w,  hex  05 0c 9d cf pll,  00 00 00 00 pll,  decimal

\ This clock value doesn't work very well with iga1, but it is good with iga2/lcd - 57.273 MHz
\ 1200 w,  900 w, 1264 w, 1210 w, 1242 w,  912 w,  900 w,  910 w,  hex  05 0c a0 cf pll,  00 00 00 00 pll,  decimal

\ 1200 w,  900 w, 1264 w, 1210 w, 1242 w,  912 w,  900 w,  910 w,  hex  85 8c 9d cf pll,  00 00 00 00 pll,  decimal
\ 1200 w,  900 w, 1240 w, 1208 w, 1216 w,  912 w,  905 w,  907 w,  hex  85 8c 9d cf pll,  00 00 00 00 pll,  decimal

\ VIA's latest recommendation - 56.916 MHz
  1200 w,  900 w, 1240 w, 1206 w, 1214 w,  912 w,  905 w,  907 w,  hex  05 0c 9f cf pll,  00 00 00 00 pll,  decimal

0 [if]
 1280 w,  768 w, 1664 w, 1344 w, 1472 w,  798 w,  770 w,  777 w,  hex  05 08 6f 4f pll,  00 00 00 00 pll,  decimal
 1280 w,  800 w, 1680 w, 1352 w, 1480 w,  831 w,  802 w,  808 w,  hex  83 88 46 4f pll,  00 00 00 00 pll,  decimal
 1280 w, 1024 w, 1688 w, 1328 w, 1440 w, 1066 w, 1024 w, 1027 w,  hex  05 08 97 0f pll,  00 00 00 00 pll,  decimal
 1368 w,  768 w, 1800 w, 1440 w, 1584 w,  795 w,  768 w,  771 w,  hex  85 88 78 0f pll,  00 00 00 00 pll,  decimal
 1440 w,  900 w, 1904 w, 1520 w, 1672 w,  934 w,  902 w,  908 w,  hex  04 08 77 4f pll,  00 00 00 00 pll,  decimal
 1600 w, 1200 w, 2160 w, 1664 w, 1856 w, 1250 w, 1200 w, 1219 w,  hex  05 04 71 0f pll,  00 00 00 00 pll,  decimal
 1680 w, 1050 w, 2240 w, 1784 w, 1960 w, 1089 w, 1052 w, 1058 w,  hex  05 08 ce 4f pll,  00 00 00 00 pll,  decimal
 1920 w, 1080 w, 2576 w, 2048 w, 2248 w, 1120 w, 1082 w, 1103 w,  hex  05 04 79 0f pll,  00 00 00 00 pll,  decimal
 1920 w, 1200 w, 2592 w, 2056 w, 2256 w, 1245 w, 1202 w, 1224 w,  hex  05 04 87 4f pll,  00 00 00 00 pll,  decimal
[then]
here res-table - constant /res-table

: /res-entry  ( -- n )  8 /w* 2 la+  ;

\ width  height  htotal  hsync hsyncend  vtotal  vsync vsyncend        --pll-- misc      --vckpll---
create mode3-entry
  640 w,  400 w,  800 w,  688 w,  784 w,  449 w,  413 w,  415 w,  hex  85 90 8c 67 pll,  04 10 97 00 pll,  decimal

\ This standard timing works but you have to adjust the sync by "06 07 33 crt-mask"
\ 640 w,  400 w,  800 w,  656 w,  752 w,  449 w,  413 w,  415 w,  hex  03 90 54 67 pll,  04 10 97 00 pll,  decimal
\ Standard timings according to http://www.epanorama.net/documents/pc/vga_timing.html:
\ 640(width)+8(border)=648(hblank)  648(hblank)+8(frontporch)=656(hsync)
\ 656(hsync)+96(syncwidth)=752(hsyncend)
\ 752(hsyncend)+40(backporch)=792(hblankend)  792(hblankend)+8(border)=800(htotal)
\ This works when CR33[2:0] = 6

\ But the following values actually work - aligning the text properly with the screen - and match BIOS numbers
\ 640(width)+8(border)=648(hblank)  648(hblank)+40(frontporch)=688(hsync)
\ 688(hsync)+96(syncwidth)=784(hsyncend)
\ 784(hsyncend)+8(backporch)=792(hblankend)  792(hblankend)+8(border)=800(htotal)
\ This works when CR33[2:0] = 0

\ width  height  htotal  hsync hsyncend  vtotal  vsync vsyncend        --pll-- misc      --vckpll---
create mode12-entry
   640 w,  480 w,  800 w,  672 w,  768 w,  525 w,  490 w,  492 w,  hex  85 90 8c e3 pll,  04 10 97 00 pll,  decimal

\ Standard timings according to http://www.epanorama.net/documents/pc/vga_timing.html:
\ 640(width)+8(border)=648(hblank)  648(hblank)+8(frontporch)=656(hsync)
\ 656(hsync)+96(syncwidth)=752(hsyncend)
\ 752(hsyncend)+40(backporch)=792(hblankend)  792(hblankend)+8(border)=800(htotal)

0 value res-entry

: mode-3?   ( -- flag )  res-entry mode3-entry  =  ;
: mode-12?  ( -- flag )  res-entry mode12-entry =  ;

: find-timing-table  ( width height -- error? )
   \ Mode12 check
   over d# 640 =  depth 4 =  and  if  2drop mode12-entry to res-entry  false exit  then   ( width height )

   \ Text mode 3 check
   dup d# 400 =  if  2drop mode3-entry to res-entry  false exit  then  ( width height )

   res-table /res-table bounds  ?do  ( width height )
      over i w@ =  if                ( width height )
         dup i wa1+ w@ =  if         ( width height )
            i to res-entry           ( )
            2drop false              ( false )
            unloop exit
         then                        ( width height )
      then                           ( width height )
   /res-entry +loop                  ( width height )
   2drop true                        ( true)
;

hex

0 value mode-timing   : mode   mode-timing  to res-entry  ;
0 value panel-timing  : panel  panel-timing to res-entry  ;

\ Stored values from table
: hdisplay ( -- n )  res-entry 0 wa+ w@  ;
: vdisplay ( -- n )  res-entry 1 wa+ w@  ;
: htotal   ( -- n )  res-entry 2 wa+ w@  ;
: hsync    ( -- n )  res-entry 3 wa+ w@  ;
: hsyncend ( -- n )  res-entry 4 wa+ w@  ;
: vtotal   ( -- n )  res-entry 5 wa+ w@  ;
: vsync    ( -- n )  res-entry 6 wa+ w@  ;
: vsyncend ( -- n )  res-entry 7 wa+ w@  ;
: pll      ( -- l )  res-entry 8 wa+ l@  ;
: vpll     ( -- l )  res-entry 8 wa+ la1+ l@  ;
: miscval  ( -- b )  pll lbsplit nip nip nip  ;

\ Derived values
: hblank   ( -- n )
   hdisplay
   mode-3?   if  8 +  then
   mode-12?  if  8 +  then
;
: hblankend  ( -- n )
\  mode-3?  if  d# 288 exit  then
   htotal
   mode-3?  if  8 -  then
   mode-12? if  8 -  then
;
: vblank   ( -- n )
   vdisplay
   mode-3?   if  7 +  then  \ vertical borders are only 7 in mode 3
   mode-12?  if  8 +  then
;
: vblankend  ( -- n )
   vtotal
   mode-3?  if  7 -  exit  then  \ vertical borders are only 7 in mode 3
   mode-12? if  8 -  exit  then
;
\ End of section that determines the mode-dependent basic timing parameters

: use-ext-clock  ( -- )   misc@ h# c or misc!  ;
: set-vclk  ( clock -- )
   lbsplit drop  h# 44 seq!  h# 45 seq!  h# 46 seq!

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

: effective-depth  ( depth -- depth' )
   depth d# 24 =  if  d# 32   else  depth  then   
;
: bytes>chars   ( bytes -- chars )  3 >>  ;
: chars>bytes   3 <<  ;
: pixels>bytes  ( pixels -- bytes )
   depth 4 = if  2/ exit  then
   effective-depth  *  ( bits )  3 >>  ( bytes )
;

: set-pitch  ( -- )  width pixels>bytes to /scanline  ;
: set-depth  ( depth -- )
   to depth
   \ The following is correct for framebuffers without extra padding
   \ at the end of each scanline.  Adjust /scanline for others.
   set-pitch
   depth case
      d# 16 of  ['] w!  ['] /w*  ['] wa+  endof
      d# 24 of  ['] l!  ['] /l*  ['] la+  endof
      d# 32 of  ['] l!  ['] /l*  ['] la+  endof
      ( default )  >r  ['] c!  ['] noop  ['] +  r>
   endcase
   to pixel+  to pixel*  to pixel!
;

: set-resolution  ( width height depth -- )  set-depth  to height  to width  ;

: lower-power  ( -- )
   7f 19 seq!  \ clock gating
   f0 1b seq!  \ clock gating
   ff 2d seq!  \ Power control enables
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
   00 00 seq!  \ Reset sequencer
   mode-3?  if  00  else  01  then   01 seq!  \ 8/9 timing (0 for mode 3)
   mode-3?  if  03  else  0f  then   02 seq!  \ Enable map planes 0 and 1 (3 for mode 3)
   00 03 seq!  \ Character map select
   mode-3?  if  02  else  06  then   04 seq!  \ Extended memory present (2 for mode 3)
   03 00 seq!  \ Release reset bits

   mode-3?  if  0d  else  00  then   0a crt!  \ Cursor start (text mode)
   mode-3?  if  0e  else  00  then   0b crt!  \ Cursor end (text mode)
   00 0e crt!  \ Cursor loc (text mode)
   00 0f crt!  \ Cursor loc (text mode)
   mode-3? mode-12? or  if  60  else  00  then  f0 11 crt-mask  \ Refreshes per line, disable vert intr
   mode-12?  if  63  else  23  then  17 crt!  \ address wrap, sequential access, not CGA compat mode
;

: general-init  ( -- )
   1e seq@ 1 or 1e seq!  \ ROC ECK
   00 20 seq!  \ max queuing number (but manual recommends 4)
   14 22 seq!  \ (display queue request expire number)
   40 34 seq!  \ not documented
   01 3b seq!  \ not documented
   38 40 seq!  \ ECK freq
   30 4d seq!  \ preempt arbiter
   08 30 crt!  \ DAC speed enhancement
   01 3b crt!  \ Scratch 2
   08 3c crt!  \ Scratch 3
   c0 f7 crt!  \ Spread spectrum
   01 32 crt!  \ real time flipping (I think we can ignore this)
;
\ SRs set in romreset: 35-38,39,4c,68,6d-6f,78,f3

: tune-fifos  ( -- )
   mode-3? mode-12? or  if  0c  else  20  then  3f 16 seq-mask  \ FIFO threshold (VX855 value)
   1f 17 seq!  \ FIFO depth (VX855 value)
   4e 18 seq!  \ Display Arbiter (VX855 value)

   18 21 seq!  \ (typical request track FIFO number channel 0
   1f 50 seq!  \ FIFO
   81 51 seq!  \ FIFO - 81 enable Northbridge FIFO
   00 57 seq!  \ FIFO
   08 58 seq!  \ Display FIFO low threshold select
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

: htotal1!  ( -- )
   dup  bytes>chars 5 - dup 00 crt!  5 >> 08  36 crt-mask   ( htotal )
   \ There are some "underflow" bits in CR47
   6 and  case
      0 of  00  endof
      2 of  80  endof
      4 of  40  endof
      6 of  08  endof
   endcase
   c8 47 crt-mask
;
: hdisplay1!  bytes>chars 1-  01 crt!  ;
: hblank1!    bytes>chars 1-  02 crt!  ;

: hblankend1! bytes>chars 1-  dup 1f 03 crt-mask  dup 2 << 80 05 crt-mask  1 >> 20 33 crt-mask  ;

: hsync1!     bytes>chars     dup 04 crt!  4 >> 10 33 crt-mask  ;
: hsyncend1!  bytes>chars     1f 05 crt-mask  ;

: vtotal1!   2-     dup 06 crt!  dup 8 >> 01 07 crt-mask  dup 4 >> 20 07 crt-mask  d# 10 >> 01 35 crt-mask  ;
: vdisplay1! 1-     dup 12 crt!  dup 7 >> 02 07 crt-mask  dup 3 >> 40 07 crt-mask  8 >> 04 35 crt-mask  ;
   
\ Starting address
: start1!  ( offset -- )  lbsplit 3 and 3 48 crt-mask  34 crt!  0d crt!  0c crt!  ;

: vsync1!           dup 10 crt!  dup 6 >> 04 07 crt-mask  dup 2 >> 80 07 crt-mask  9 >> 02 35 crt-mask  ;
: vsyncend1!        0f 11 crt-mask  ;

: vblank1!    1-  dup 15 crt!  dup 5 >> 08 07 crt-mask  dup 4 >> 20 09 crt-mask  7 >> 08 35 crt-mask  ;
: vblankend1! 1-      16 crt!  ;

: hoffset1! ( bytes -- )  bytes>chars dup 13 crt!  3 >> e0 35 crt-mask  ;
: hfetch1!  ( bytes -- )  bytes>chars  1 >> 4 +  dup 1c seq!  8 >> 03 1d seq-mask  ;

: bpp1!  ( depth -- )
   case
       4  of  00  endof
       8  of  mode-3?  if  00  else  22  then  endof
   d# 16  of  b6  endof
   d# 32  of  ae  endof
   ( default )  ae swap
   endcase
   fe 15 seq-mask
;

: fifo-depth1!      ( n -- )  1 >>  1-  17 seq!  ;
: fifo-threshold1!  ( n -- )  2 >>  dup 3f 16 seq-mask  1 << 80 16 seq-mask   ;
: expire1!          ( n -- )  2 >>  1f 22 seq-mask  ;
: high-threshold1!  ( n -- )  2 >>  dup 3f 18 seq-mask  1 << 80 18 seq-mask  ;

\ This calculates the pulse ending position given the low-bits of the
\ end match value, the pulse start position, and the number of bits
\ in the end counter.  It is used to work out when a blanking or sync
\ end will occur for a VGA-style timing controller that abbreviates
\ the end counter by omitting the high bits.

: after-start  ( low-bits start mask -- final-value )
   >r                   ( low-bits start )
   tuck  r@ invert and  ( start low-bits base-high-bits )
   +                    ( start provisional-final-value )
   \ If final is less than start, the end will occur on the next
   \ wraparound of the counter.
   tuck >  if           ( provisional-final-value )
      r@ 1+ +           ( final-value )
   then                 ( final-value )
   r> drop
;

: htotal1@
   00 crt@  36 crt@ 08 and 5 << or  5 +  3 <<
   47 crt@ c8 and  case
      08  of  6 +  endof
      40  of  4 +  endof
      80  of  2 +  endof
   endcase
;
: hdisplay1@   01 crt@  1+  3 <<  ;
: hblank1@     02 crt@  1+  3 <<  ;
\ The mask below should be 7f instead of 3f, but for some reason the standard mode 3 timings
\ don't set the blank end bit [6] in CR33[5], so you get wildly wrong answers with the 7f mask
\ : hblankend1@  03 crt@  1f and  05 crt@ 80 and 2 >> or  33 crt@ 20 and 1 << or  hblank1@ bytes>chars 1-  3f after-start  1+  3 <<  ;
: hblankend1@  03 crt@  1f and  05 crt@ 80 and 2 >> or  33 crt@ 20 and 1 << or  hblank1@ bytes>chars 1-  7f after-start  1+  3 <<  ;
: hsync1@      04 crt@  33 crt@ 10 and 4 << or  3 <<  ;
: hsyncend1@   05 crt@  1f and  hsync1@ bytes>chars  1f after-start   3 <<  ;

: vtotal1@     06 crt@  07 crt@ 1 and 8 << or  07 crt@ 20 and 4 << or  35 crt@ 1 and d# 10 << or  2+  ;
: vdisplay1@   12 crt@  07 crt@ 2 and 7 << or  07 crt@ 40 and 3 << or  35 crt@ 4 and 8 << or  1+  ;
: vsync1@      10 crt@  07 crt@ 4 and 6 << or  07 crt@ 80 and 2 << or  35 crt@ 2 and 9 << or    ;
: vsyncend1@   11 crt@  0f and  vsync1@ 0f after-start    ;
: vblank1@     15 crt@  07 crt@ 8 and 5 << or  09 crt@ 20 and 4 << or  35 crt@ 8 and 7 << or  1+  ;
: vblankend1@  16 crt@  vblank1@ 1- ff after-start 1+  ;

: start1@  0c crt@  0d crt@  34 crt@  48 crt@ 3 and  bljoin  ;

: hoffset1@   ( -- bytes )  13 crt@  35 crt@ e0 and 3 << or  chars>bytes  ;
: hfetch1@    ( -- bytes )  1c seq@  1d seq@ 03 and 8 << or  4 -  1 << chars>bytes  ;

: bpp1@  ( -- depth )
   15 seq@ fe and  case
       0  of      4  endof
      22  of      8  endof
      b6  of  d# 16  endof
      ae  of  d# 32  endof
      ( default )  8  swap
   endcase
;

: fifo-depth1@      ( -- n )  17 seq@ 1+  1 <<  ;
: fifo-threshold1@  ( -- n )  16 seq@ 3f and  16 seq@ 80 and 1 >> or  2 <<  ;
: expire1@          ( -- n )  22 seq@ 1f and  2 <<  ;
: high-threshold1@  ( -- n )  18 seq@ 3f and  18 seq@ 80 and 1 >> or  2 << ;

: bpp2!  ( depth -- )
   case
       4  of  00  endof
       8  of  00  endof
   d# 16  of  40  endof
   d# 24  of  c0  endof
   d# 30  of  80  endof
   d# 32  of  c0  endof
   ( default ) c0 swap
   endcase
   c0 67 crt-mask
;
: fifo-depth2!      ( n -- )  3 >>  1-  dup 4 << f0 68 crt-mask  dup 3 << 80 94 crt-mask  2 << 80 95 crt-mask  ;
: fifo-threshold2!  ( n -- )  2 >>  dup 0f 68 crt-mask  70 95 crt-mask  ;
: expire2!          ( n -- )  2 >>  7f 94 crt-mask  ;
: high-threshold2!  ( n -- )  2 >>  dup 0f 92 crt-mask  4 >> 07 95 crt-mask  ;

: init-grf-regs  ( -- )
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
;
: init-attr-regs  ( -- )
   " "(00 01 02 03 04 05 14 07 38 39 3a 3b 3c 3d 3e 3f 01 00 0f 00 00)"
   0  do  ( adr )  dup c@  i attr!  1+  loop  drop

   mode-3?  if
      0c 10 attr! \ mode control
      08 13 attr! \ horizontal pixel pan
   then

   palette-on
;

: set-primary-vga-mode  ( -- )
   80 11 crt-clr  \ Enable writing to CRT0-7
   80 03 crt-set  \ Enable vertical retrace access
   01 10 seq!     \ Unlock extended registers

   miscval  misc!

   depth bpp1!

   08 cd 1a seq-mask  \ Extended mode memory access (unnecessary but okay for modes 3 and 12)

   init-grf-regs

   init-attr-regs

   htotal    htotal1!

   hdisplay  hdisplay1!
   hblank    hblank1!

   hblankend hblankend1!

   hsync     hsync1!
   hsyncend  hsyncend1!

   vtotal    vtotal1!
   vdisplay  vdisplay1!
   
   \ Starting address
   0 start1!

   vsync     vsync1!
   vsyncend  vsyncend1!

   \ Line compare value 3fff
   ff 18 crt!  10 7 crt-set  40 9 crt-set  10 35 crt-set

   \ HSYNC adjust
   mode-3?  if  05  else  mode-12?  if  00  else  06  then  then
      07 33 crt-mask  \ 01 for text mode 3, 00 for mode 12

   \ Max scan line value 0
   mode-3?  if  0f  else  00  then  1f 9 crt-mask
   mode-3?  if  1f  else  00  then  14 crt!  \ Underline location
 
   vblank    vblank1!
   vblankend vblankend1!

   00 08 crt!     \ Preset row scan
\  00 32 crt!     \ HSYNC delay, SYNC drive, gamma, end blanking, etc  Already set
   c8 33 crt-clr  \ Gamma, interlace, prefetch, HSYNC shift

   set-pitch
   \ Offset
   mode-3? mode-12? or  if  d# 320  else  /scanline  then  hoffset1!

   \ fetch count
   hdisplay  mode-3? mode-12? or  if  2*  else  pixels>bytes  then  hfetch1!
;

: set-primary-mode  ( -- )
   width height find-timing-table  if  exit  then

   80 17 crt-clr  \ Assert reset

   mode-independent-init

\   00 93 crt!   \ Undocumented register for VX855

   set-primary-vga-mode

   08 1a seq-set  \ Enable MMIO

\   08 33 crt-set  \ Enable CRT prefetch (VESA BIOS doesn't set this)

   depth 8 > set-gamma   \ No gamma for 4bpp mode or 8bpp palette mode

   mode-3? mode-12? or  if  vpll  else  pll  then  set-vclk  use-ext-clock
   mode-3? mode-12? or  if  02 47 crt-set  then  \ LCD simultaneous mode backdoor register for 8/9 Dot Clocks

\  01 6b crt-clr  \ Appears to be reserved RO bit

   80 17 crt-set  \ Release reset
;

: set-lcdck  ( clock -- )
   lbsplit drop  h# 4a seq!  h# 4b seq!  h# 4c seq!

   40 seq@  dup 4 or  40 seq!  4 invert and 40 seq!  \ Pulse LCDCK PLL reset high
;

: set-eck  ( clock -- )
   lbsplit drop  h# 47 seq!  h# 48 seq!  h# 49 seq!

   40 seq@  dup 1 or  40 seq!  1 invert and 40 seq!  \ Pulse ECK PLL reset high
;

: htotal2!    1-  dup 50 crt!      8 >> 0f 55 crt-mask ;
: hdisplay2!  1-  dup 51 crt!      4 >> 70 55 crt-mask ;
: hblank2!    1-  dup 52 crt!      8 >> 07 54 crt-mask ;
: hblankend2! 1-  dup 53 crt!  dup 5 >> 38 54 crt-mask      5 >> 40 5d crt-mask ;

\ unichrome omits bit 11, which goes in CR5D[7]
: hsync2!         dup 56 crt!  dup 2 >> c0 54 crt-mask  dup 3 >> 80 5c crt-mask  4 >> 80 5d crt-mask ;
: hsyncend2!      dup 57 crt!      2 >> 40 5c crt-mask ;

: vtotal2!    1-  dup 58 crt!      8 >> 07 5d crt-mask ;
: vdisplay2!  1-  dup 59 crt!      5 >> 38 5d crt-mask ;
   
: vblank2!    1-  dup 5a crt!      8 >> 07 5c crt-mask ;
: vblankend2! 1-  dup 5b crt!      5 >> 38 5c crt-mask ;

: vsync2!     1-   dup 5e crt!      3 >> e0 5f crt-mask ;
: vsyncend2!  1-                         1f 5f crt-mask ;

: hoffset2!   ( bytes -- )  bytes>chars  dup 66 crt!  dup 8 >> 03 67 crt-mask  3 >> 80 71 crt-mask  ;
: hfetch2!    ( bytes -- )  bytes>chars  dup 1 >>  65 crt!  7 >>  0c  67 crt-mask  ;

: start2!     ( offset -- )  2 rshift  lbsplit drop  64 crt!  63 crt!  fc 62 crt-mask  ;
: qdepth!     ( depth -- )  4 lshift  f0 68 crt-mask  ;  \ Unused bits in regs 94 and 95 too

: htotal2@     50 crt@  55 crt@      f and 8 << or  1+  ;
: hdisplay2@   51 crt@  55 crt@ 4 >> 7 and 8 << or  1+  ;
: hblank2@     52 crt@  54 crt@      7 and 8 << or  1+  ;
: hblankend2@  53 crt@  54 crt@ 3 >> 7 and 8 << or  5d crt@ 6 >> 1 and d# 11 << or  1+  ;
: hsync2@      56 crt@  54 crt@ 6 >> 3 and 8 << or  5c crt@ 7 >> 1 and d# 10 << or  5d crt@ 7 >> 1 and d# 11 << or  ;
: hsyncend2@   57 crt@  5c crt@ 6 >> 1 and 8 << or  hsync2@ 1ff after-start  ;

: vtotal2@     58 crt@  5d crt@      7 and 8 << or  1+  ;
: vdisplay2@   59 crt@  5d crt@ 3 >> 7 and 8 << or  1+  ;
: vblank2@     5a crt@  5c crt@      7 and 8 << or  1+  ;
: vblankend2@  5b crt@  5c crt@ 3 >> 7 and 8 << or  1+  ;
: vsync2@      5e crt@  5f crt@ 5 >> 7 and 8 << or  1+  ;
: vsyncend2@   5f crt@ 1f and  vsync2@ 1f invert and  or  dup vsync2@ <  if  20 +  then  1+  ;

: hoffset2@   ( -- bytes )  66 crt@  67 crt@ 3 and 8 << or  71 crt@ 7 >> 1 and d# 10 << or  chars>bytes  ;
: hfetch2@    ( -- bytes )  65 crt@  67 crt@ 2 >> 3 and 8 << or  1 << chars>bytes  ;

: start2@     ( -- offset )  62 crt@ fe and  63 crt@  64 crt@  0  bljoin  2 <<  ;
: qdepth@     ( -- depth )  68 crt@ f0 and  4 >>  ;  \ Unused bits in regs 94 and 95 too

: bpp2@  ( -- depth )
   67 crt@ c0 and  case
       0  of      8  endof
      40  of  d# 16  endof
      80  of  d# 30  endof
      c0  of  d# 32  endof
   endcase
;

: simultaneous-mode-3?  ( -- flag )  height d# 400 =  ;
: simultaneous-mode-12?  ( -- flag )  depth 4 =  ;

: set-pitch2  ( -- )
   depth bpp2!
   20 67 crt-clr  \ Turn off interlace bit

   \ Offset - distance from one scanline to the next in the memory array
   set-pitch

   \ I'm unsure how the 808 is calculated for simultaneous mode 3, but the
   \ value is what BIOS uses.  It might not matter.
   simultaneous-mode-3?  simultaneous-mode-12? or  if  d# 808  else  /scanline  then  hoffset2!

   \ fetch count - number of bytes to fetch from memory for each scanline
   \ If this smaller than hdisplay, the last data replicates horizontally to the right
   width  simultaneous-mode-3?  simultaneous-mode-12? or  if  8 + 4 *  else  pixels>bytes  then  hfetch2!
;
: set-secondary-timings  ( -- )
   htotal    htotal2!
   hdisplay  hdisplay2!
   hblank    hblank2!
   hblankend hblankend2!

\ unichrome omits bit 11, which goes in CR5D[7]
   hsync     hsync2!
   hsyncend  hsyncend2!

   vtotal    vtotal2!
   vdisplay  vdisplay2!
   
   vblank    vblank2!
   vblankend vblankend2!

   vsync     vsync2!
   vsyncend  vsyncend2!

   set-pitch2
;

: panel-resolution  ( -- w h )  d# 1200 d# 900  ;

\ Shadow frame buffer - used for mirroring the primary display onto the secondary

: htotals!     bytes>chars 5 -  dup 6d crt!  5 >> 08 71 crt-mask  ;
: hblankends!  bytes>chars 1-       6e crt!  ;

: vtotals!     2-  dup 6f crt!      8 >> 07 71 crt-mask  ;
: vdisplays!   1-  dup 70 crt!      4 >> 70 71 crt-mask  ;
   
: vblanks!     1-  dup 72 crt!      4 >> 70 74 crt-mask  ;
: vblankends!  1-  dup 73 crt!      8 >> 07 74 crt-mask  ;

: vsyncs!          dup 75 crt!      4 >> 70 76 crt-mask  ;
: vsyncends!                             0f 76 crt-mask  ;

: htotals@     6d crt@  71 crt@ 08 and 5 << or  5 + 3 <<  ;
: hblankends@  6e crt@  1+  3 <<  ;

: vtotals@     6f crt@  71 crt@ 07 and 8 << or  2+  ;
: vdisplays@   70 crt@  71 crt@ 70 and 4 << or  1+  ;
   
: vblanks@     72 crt@  74 crt@ 70 and 4 << or  1+  ;
: vblankends@  73 crt@  74 crt@ 07 and 8 << or  1+  ;

: vsyncs@      75 crt@  76 crt@ 70 and 4 << or   ;
: vsyncends@   76 crt@  0f and  vsyncs@ 0f invert and  or  dup  vsyncs@ <  if  10 +  then  ;

: random-stuff  ( -- )
   0 start2!          \ Second display starting address

   f qdepth!

   \ The next 2 lines connect IGA2 (second display) to the DVP1 (LCD) output interface
   c8 c8 6a crt-mask  \ 2nd display enabled (80), not reset (40), first hw power sequence (8)
   00 0e 6b crt-mask  \ Simultaneous mode (8) off, IGA2 Screen Disable (4) off, IGA2 Off Selection method (2) for IGA2
   60 60 88 crt-mask  \ LVDS sequential (40), flip by line (20), 24 output bit (1=>0) for no dithering
   01 07 8a crt-mask  \ LCD adjust LP
   10 10 97 crt-mask  \ LVDS channel 2 - secondary display
   1b ff 9b crt-mask  \ DVP mode - alpha:80, VSYNC:40, HSYNC:20, secondary:10, clk polarity:8, clk adjust:7

   08 7f 94 crt-mask  \ Expire number
   11 f7 95 crt-mask  \ extension bits for display queue depth and read thresholds

   8b ff a7 crt-mask  \ expected vertical display low (IGA1; maybe irrelevant for secondary channel)
   01 07 a8 crt-mask  \ expected vertical display high (IGA1; maybe irrelevant for secondary channel)
;

: set-secondary-mode  ( device-width device-height -- )
   find-timing-table  if  exit  then

   80 17 crt-clr  \ Assert reset - Turn off screen
   set-secondary-timings
   random-stuff
   mode-independent-init
   \ Turn on power here?
   1e 6c crt-clr  \ 10=>0: VCK source is VCK PLL  0e=>0: LCDCK PLL RefClk from X1 Pin
   pll set-lcdck
   use-ext-clock   
   80 17 crt-set  \ Release reset
;

: scaling-on  ( -- )  07 79 crt-set  ;
: scaling-off ( -- )  07 79 crt-clr  ;

: olpc-lcd-mode  ( -- )
   panel-resolution d# 32 set-resolution

   c0 1b seq-set  \ Secondary display clock on

   panel-resolution set-secondary-mode

\  60 9b crt-set  \ Sync polarity - negative
   60 78 seq-set  \ Sync polarity - negative

   scaling-off    \ Disable scaling
   37 a3 crt-clr  \ iga2 from S.L., start addr

   30 1e seq-set  \ Power up DVP1 pads

   0c 2a seq-set  \ Power up LVDS pads
\  2b fb h# d2 crt-mask
\  c0 h# d4 crt-set
\  40 h# e8 crt-clr
   80 f3 crt-set  \ 18-bit TTL mode
   0a f9 crt!     \ V1 Mode Exit-to-Ready Time Control (?)
   0d fb crt!     \ IGA2 Interlace VSYNC Timing Register
\   00 08 h# 6b crt-mask  \ Not simultaneous mode

   40 16 seq-set  \ manual says the bit is reserved, but the viafb driver says "CRT path set to IGA2"
   80 59 seq-clr  \ Turn off IGA1 in power control register
;
: olpc-crt-off  ( -- )
   80 59 seq-clr  \ Turn off IGA1 in power control register
   30 1b seq-clr  \ IGA1 engine clock off
   30 36 crt-set  \ DAC off
;
: olpc-crt-on  ( -- )
   80 59 seq-set  \ Turn on IGA1 in power control register
   30 1b seq-set  \ IGA1 engine clock on
   30 36 crt-clr  \ DAC on
;
: olpc-lcd-off  ( -- )
   c0 1b seq-clr  \ IGA2 engine clock off
;

\ The table of scaling params below appears to be half of a Gaussian function,
\ probably for "Gaussian blur" interpolation.  The other half is probably
\ obtained by used the values in a mirror-image fashion.
: set-scaling-params  ( -- )
   " "(01 02 03 04 07 0a 0d 13 16 19 1c 1d 1e 1f)"  ( adr len )
   0  do  dup i + c@  h# 7a i +  crt!  loop           ( adr )
   drop
;

: hscale!  ( hscale -- )
   \ Distribute the H scale factor among various register bit fields
   dup 3 h# 9f crt-mask                        ( hscale )
   dup 2 rshift h# 77 crt!                     ( hscale )
   d# 10 rshift 4 lshift h# 30 h# 79 crt-mask  ( )
;
: hscale@  ( -- factor*4096 )
   h# 9f crt@ 3 and
   h# 77 crt@ 2 lshift or
   h# 79 crt@ 4 rshift 3 and  d# 10 lshift or
;
: hscale-on   ( -- )  c0 a2 crt-set  ;
: hscale-off  ( -- )  c0 a2 crt-clr  ;
: vscale!  ( vscale -- )
   \ Distribute the V scale factor among various register bit fields
   dup 3 lshift 8 h# 79 crt-mask               ( vscale )
   dup 1 rshift h# 78 crt!                     ( vscale )
   9 rshift 6 lshift h# c0 h# 79 crt-mask      ( )
;
: vscale@  ( -- vscale )
   h# 79 crt@ 3 rshift 1 and
   h# 78 crt@ 1 lshift  or
   h# 79 crt@ 6 rshift 3 and 9 lshift  or
;
: vscale-on  ( -- )  08 a2 crt-set  ;
: vscale-off ( -- )  08 a2 crt-clr  ;

: scale-lcd  ( -- )
   scaling-on
   set-scaling-params \ Interpolation coefficients  ( )

   hdisplay  width   2dup >  if                   ( panel mode )
      \ Calculate the H scale factor
      1-  d# 4096  rot 1-  */                     ( hscale )
      hscale!  hscale-on                          ( )
   else                                           ( )
      2drop  hscale-off                           ( )
   then                                           ( )

   vdisplay  height  2dup >  if                   ( panel mode )
      \ Calculate the V scale factor
      1-  d# 2048  rot 1-  */                     ( vscale )
      vscale!  vscale-on                          ( )
   else                                           ( )
      2drop  vscale-off                           ( )
   then

   \ vdisplay1 must contain a non-zero value in at least one of its bit
   \ fields, otherwise the screen will be blank when vertical scaling is on.
   \ Any non-1 (which becomes 0) value in vdisplay1 suffices.
   vdisplay1@ 1 =  if  0 vdisplay1!  then

   set-pitch2
;

: set-mode-timing  
   width height  find-timing-table   if  exit  then
   res-entry to mode-timing
;
: set-panel-timing
   panel-resolution find-timing-table  if  exit  then
   res-entry to panel-timing
;

\                           2ndChanReset   2ndChanEna/Dis !2ndChanReset
: enable-channel2   ( -- )  40 6a crt-clr  80 6a crt-set  40 6a crt-set  ;
: disable-channel2  ( -- )  40 6a crt-clr  80 6a crt-clr  40 6a crt-set  ;

: simultaneous-on   ( -- )  08 6b crt-set  ;
: simultaneous-off  ( -- )  08 6b crt-clr  ;

\ Second channel is IGA2


\                        2ndChannelEna  Reserved       Simultaneous
: iga1>crt       ( -- )                 40 16 seq-clr  ;                   \ Common: 16:00 6a:40 6b:00
: iga2>crt       ( -- )  c0 6a crt-set  40 16 seq-set  ;                   \ 6a maybe should be enable-channel2
: iga1+2>crt     ( -- )  c0 6a crt-set  40 16 seq-set  simultaneous-on  ;  \ 6a maybe should be enable-channel2

: pwr1-on  ( -- )  08 6a crt-set  ;

\                        Simultaneous      1stHwPwrSeq    2ndChannelEnable
: iga1>lcd       ( -- )  simultaneous-off  pwr1-on        disable-channel2  ;
: iga2>lcd       ( -- )  simultaneous-off  pwr1-on        enable-channel2   ;
: iga1+2>lcd     ( -- )  simultaneous-on   pwr1-on        disable-channel2  ;

\ CR91 register is "Software Control Power Sequence".  The common settings have it at 80, which is
\ the "Off" state for "Software Direct On/Off Display Period in the Panel Path"

0 [if]
\ CR96 register is not documented in GPM_Chrome9 HCM_R010
: iga1>dvp0      ( -- )  iga1>lcd                10 96 crt-clr  ;
: iga2>dvp0      ( -- )  iga2>lcd    00 91 crt!  10 96 crt-set  ;
: iga1+2>dvp0    ( -- )  iga1+2>lcd  00 91 crt!  10 96 crt-set  ;
[then]

\ CR9b register is "Digital Video Port 1 Function Select 0"; 10 bit is primary/secondary data source select
: iga1>dvp1      ( -- )  iga1>lcd                10 9b crt-clr  ;
: iga2>dvp1      ( -- )  iga2>lcd    00 91 crt!  10 9b crt-set  ;  \ This is the mode OLPC normally uses
: iga1+2>dvp1    ( -- )  iga1+2>lcd  00 91 crt!  10 9b crt-set  ;

0 [if]
\ CR99 register is "LVDS Channel 1 Function Select 0"; 10 bit is primary/secondary data source select
: iga1>lvds0     ( -- )  iga1>lcd                10 99 crt-clr  ;
: iga2>lvds0     ( -- )  iga2>lcd                10 99 crt-set  ;
: iga1+2>lvds0   ( -- )  iga1+2>lcd              10 99 crt-set  ;

alias iga1>lvds0+1   iga1>lvds0
alias iga2>lvds0+1   iga2>lvds0
alias iga1+2>lvds0+1 iga1+2>lvds0

\ CR99 register is "LVDS Channel 2 Function Select 0"; 10 bit is primary/secondary data source select
: iga1>lvds1     ( -- )  iga1>lcd                10 97 crt-clr  ;
: iga2>lvds1     ( -- )  iga2>lcd                10 97 crt-set  ;
: iga1+2>lvds1   ( -- )  iga1+2>lcd              10 97 crt-set  ;
[then]

0 value bias
: timing-scale  ( value -- value' )
   mode simultaneous-mode-3? simultaneous-mode-12? or  if  \ Can't use mode-3? here because res-entry isn't pointing to mode3-entry
      \ Ratio of VCK to LCDCK, from known settings for those clocks
      d# 338 d# 569
   else
      mode hdisplay  panel hdisplay
   then
   */
;
\ For 640x400 (text mode 3) and 640x480x4 (graphics mode 12) where you need IGA1 for its VGA-ness
: expanded  ( -- )
   set-mode-timing
   set-panel-timing

   panel htotal  timing-scale  htotals!
   panel htotal  timing-scale  hblankends!

   \ LCD Tuning.doc does not mention setting the CRTC Htotal (htotal1!)
   \ nor the CRTC Hblankend (hblankend1!).  I wonder if that means that
   \ the shadow values are used instead?
   \ mode  hdisplay   htotal1!
   \ mode  hblankend  hblankend!

   mode  hdisplay   hdisplay1!
   mode  hblank     hblank1!

   mode  hsync      hsync1!
   mode  hsyncend   hsyncend1!
   
   panel htotal     htotal2!
   panel hdisplay   hdisplay2!

   panel hdisplay   hblank2!
   panel hblankend  hblankend2!  \ Fine tune
   panel hsync      hsync2!
   panel hsyncend   hsyncend2!

   panel vtotal     dup vtotal2!     vtotals!
   panel vdisplay   dup vdisplay2!   vdisplays!

   panel vdisplay   dup vblank2!     vblanks!
   panel vblankend  dup vblankend2!  vblankends!
   panel vsync      dup vsync2!      vsyncs!
   panel vsyncend   dup vsyncend2!   vsyncends!

   scale-lcd

   mode  vpll set-vclk
   panel  pll set-lcdck

   disable-channel2
   simultaneous-on
;

: centered  ( -- )
   set-mode-timing
   set-panel-timing

   scaling-off

   \ To center the display, we move the blanking and sync signals to the
   \ so the blanking starts at the right side of the mode-width display
   \ that is centered within the larger panel-width area.
   \ We preserve the width of the blanking and sync pulses (the same as
   \ for the native-resolution case), and also preserve the "front porch"
   \ distance between blanking start and sync start.
   \ Basically everything - blank start/end and sync start/end - moves
   \ left by the same amount.

   \ Compute the bias distance - half the (panel - mode) width difference
   panel hdisplay  mode hdisplay  -  2/  to bias

   panel htotal             htotal2!
   mode  hdisplay           hdisplay2!

   panel hdisplay   bias -  hblank2!
   panel hblankend  bias -  hblankend2!
   panel hsync      bias -  hsync2!
   panel hsyncend   bias -  hsyncend2!

\   panel hdisplay  mode hdisplay  -  2/  mode hdisplay +  dup  hblank2!  ( hblank2 )
\   panel hdisplay  mode hdisplay  +  2/  dup hblank2!                    ( hblank2 )

   \ Move the blanking end by the same amount, keeping the blanking time constant
   \ hblankend hblank -  is the blanking time
\   dup panel hblankend panel hblank -  +  hblankend2!                    ( hblank2 )

   \ Similarly, move the sync pulse, preserving its width and offset from hblank
\   panel hsync  panel hblank -  +  dup hsync2!                           ( hsync2 )
\   panel hsyncend  panel hsync -  +  hsyncend2!                          ( )

   \ The offset and fetch counts for the inset display are the mode values
   mode hdisplay  pixels>bytes  hfetch2!
   mode hdisplay  pixels>bytes  d# 80 -  hoffset2!

   \ The primary (IGA1) engine uses the mode values
   mode hdisplay  htotal1!    \ Added; not in LCD Tuning.doc
   mode hdisplay  hdisplay1!  \ !! possible adjust by +1

   mode hdisplay  hblank1!
   mode hblankend hblankend1!

\   panel htotal   hblankends!   Was here

   mode hsync     hsync1!
   mode hsyncend  hsyncend1!

   mode hdisplay  pixels>bytes  hfetch1!   \ Added; not in LCD Tuning.doc
   mode hdisplay  pixels>bytes  hoffset1!  \ Added; not in LCD Tuning.doc

   \ XXX turn off scaling

   \ The shadow uses the panel size for horizontal
   panel htotal  htotals!
   panel htotal  hblankends!

   \ The vertical is similar to the horizontal - mode-width display inset
   \ in the panel total, with blanking and sync pulses moved upward for centering.
   \ The vertical timings for the secondary and shadow controllers are the same in this case.
   panel vdisplay  mode vdisplay  - 2/  to bias

   panel vtotal             dup vtotal2!     vtotals!
   mode  vdisplay           dup vdisplay2!   vdisplays!

   panel vdisplay   bias -  dup vblank2!     vblanks!
   panel vblankend  bias -  dup vblankend2!  vblankends!
   panel vsync      bias -  dup vsync2!      vsyncs!
   panel vsyncend   bias -  dup vsyncend2!   vsyncends!

   panel pll set-vclk
   panel pll set-lcdck

   enable-channel2  \ Ensure that second display channel is on
;

: common-settings  ( -- )
    01 FF 10 seq-mask	\ Unlock
    02 02 15 seq-mask	\ Enable extended display mode
    08 BF 16 seq-mask	\ Display FIFO normal threshold
    1F FF 17 seq-mask	\ Display FIFO depth
    4E FF 18 seq-mask	\ PREQ higher than TREQ (40), Display FIFO High Reg Threshold
    08 FB 1A seq-mask	\ Disable read cache, Not reset, Enable extended mode memory access, primary LUT
    F0 FF 1B seq-mask	\ Gated primary and secondary clocks, Primary LUT on
    01 07 1E seq-mask	\ ROC ECK On
    00 F0 2A seq-mask	\ Original Type Spread Spectrum Control
    00 FF 58 seq-mask	\ Display FIFO Low Threshold
    00 FF 59 seq-mask	\ Disable numerous GFX-NM modes and IGA1
    FF FF 2D seq-mask	\ VCK and LCK PLL power on - several clocks gated
    00 FF 09 crt-mask	\ Initial crt-mask09=0
    00 8F 11 crt-mask	\ IGA1 initial  Vertical end
    00 7F 17 crt-mask	\ IGA1 CRT Mode control init
    1E FF 0A crt-mask	\ Cursor Start
    00 FF 0B crt-mask	\ Cursor End
    00 FF 0E crt-mask	\ Cursor Location High
    00 FF 0F crt-mask	\ Cursor Location Low
    00 FF 32 crt-mask	\ HSYNC no delay, Low CRT Sync, Disable Display End Blanking, Disable DVP Gamma, Frame flipping
    00 7F 33 crt-mask	\ Primary Display No interlace, overflow bits, Disable prefetch mode, 3-character early HSYNC
    00 FF 34 crt-mask	\ Starting address overflow
    00 FF 35 crt-mask	\ Overflow for several parameters
    00 08 36 crt-mask	\ Htotal overflow
    00 FF 69 crt-mask	\ Disable second display interrupt
    60 FD 6A crt-mask	\ Enable and unreset second display channel
    00 FF 6B crt-mask	\ Various normal modes
    00 FF 6C crt-mask	\ VCK and LCDCK - ref from X1, PLL output
    01 FF 7A crt-mask	\ LCD Scaling Parameter 1
    02 FF 7B crt-mask	\ LCD Scaling Parameter 2
    03 FF 7C crt-mask	\ LCD Scaling Parameter 3
    04 FF 7D crt-mask	\ LCD Scaling Parameter 4
    07 FF 7E crt-mask	\ LCD Scaling Parameter 5
    0A FF 7F crt-mask	\ LCD Scaling Parameter 6
    0D FF 80 crt-mask	\ LCD Scaling Parameter 7
    13 FF 81 crt-mask	\ LCD Scaling Parameter 8
    16 FF 82 crt-mask	\ LCD Scaling Parameter 9
    19 FF 83 crt-mask	\ LCD Scaling Parameter 10
    1C FF 84 crt-mask	\ LCD Scaling Parameter 11
    1D FF 85 crt-mask	\ LCD Scaling Parameter 12
    1E FF 86 crt-mask	\ LCD Scaling Parameter 13
    1F FF 87 crt-mask	\ LCD Scaling Parameter 14
    40 FF 88 crt-mask	\ LCD Panel Type - first channel sequential, flip by frame, 24 bits
    00 FF 89 crt-mask	\ LCD Timing Control 0 - not documented
    88 FF 8A crt-mask	\ LCD Timing Control 1 - 88 is reserved bits - rest is FLM and LP adjust valuse
    81 FF D4 crt-mask	\ Second power sequence control - LVDS Second Channel2 Sequential format, Power Seq Timer secondary
    80 FF 91 crt-mask	\ 24/12 bit LVDS Data off (doc calls this bit "Software Direct On/Off Display Period in the Panel Path"
    00 FF 96 crt-mask	\ Overflow bits for display q depth, read thresholds 1 and 2
    00 FF 97 crt-mask	\ LVDS Channel 2 - data source from primary display
    00 FF 99 crt-mask	\ LVDS Channel 1 - data source from primary display
    00 FF 9B crt-mask	\ DVP mode
    FF FF D2 crt-mask	\ TMDS/LVDS control register. - turn on various enables and some reserved bits
;

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

: init-primary-display  ( -- )
   panel-resolution set-primary-mode
;

: .scale  ( factor denom -- )
   push-decimal
   d# 1000 swap */   ( factor*1000 )
   <# u# u# u# [char] . hold u#> type
   pop-base
;
: .scale-factors  ( -- )
   ." Hscale: "  hscale@  d# 4096 .scale  space
   ." Vscale: "  vscale@  d# 4096 .scale  cr
;

: .3  3 u.r  ;
: .5  5 u.r  ;
: .timings
   push-decimal
   ." IGA1: "
   hdisplay1@ .5 hblank1@ .5 hsync1@ .5 hsyncend1@ .5 hblankend1@ .5 htotal1@ .5
   2 spaces
   vdisplay1@ .5 vblank1@ .5 vsync1@ .5 vsyncend1@ .5 vblankend1@ .5 vtotal1@ .5
   cr
   ." IGA2: "
   hdisplay2@ .5 hblank2@ .5 hsync2@ .5 hsyncend2@ .5 hblankend2@ .5 htotal2@ .5
   2 spaces
   vdisplay2@ .5 vblank2@ .5 vsync2@ .5 vsyncend2@ .5 vblankend2@ .5 vtotal2@ .5
   cr
   ." Shad: "
   htotals@ .5 hblankends@ .5
   d# 22 spaces
   vdisplays@ .5 vblanks@ .5 vsyncs@ .5 vsyncends@ .5 vtotals@ .5 vblankends@ .5
   cr
   ." fetch1: " hfetch1@ . ." offset1: " hoffset1@ . ." bpp1: " bpp1@ .  cr
   ." fetch2: " hfetch2@ . ." offset2: " hoffset2@ . ." bpp2: " bpp2@ .  cr
   hex
   ." VCK: " h# 44 seq@ .3 h# 45 seq@ .3 h# 46 seq@ .3 3 spaces
   ." ECK: " h# 47 seq@ .3 h# 48 seq@ .3 h# 49 seq@ .3 3 spaces
   ." LCK: " h# 4a seq@ .3 h# 4b seq@ .3 h# 4c seq@ .3 cr
   ." MISC " misc@ .x
   .scale-factors
   pop-base
;

defer init-display  ' init-primary-display is init-display

: erase-frame-buffer  ( -- )
   fb-va /fb    ( adr len )
   depth case
      8      of  h# 0f                     fill  endof
      d# 16  of  background-rgb  rgb>565  wfill  endof
      d# 32  of  h# ffff.ffff             lfill  endof
      ( default )  nip nip
   endcase
   h# f to background-color
;
: init-frame-buffer  ( -- )		\ Initializes the controller
   map-frame-buffer
   erase-frame-buffer
;

defer gp-install  ' noop to gp-install

: set-terminal  ( -- )
   width  height                              ( width height )
   over char-width / over char-height /       ( width height rows cols )
   /scanline effective-depth fb-install gp-install   ( )
;

: change-resolution  ( new-width new-height new-depth -- )
   set-resolution  ( )
   scale-lcd
   set-terminal
\   " page" evaluate
\   erase-frame-buffer
;

0 value open-count

: display-remove  ( -- )
   open-count 1 =  if
   then
   open-count 1- 0 max to open-count
;

: display-install  ( -- )
   open-count 0=  if
      map-io-regs		\ Enable IO registers
      init-display
      init-frame-buffer
      declare-props		\ Setup properites
   then
   default-font set-font
   set-terminal
   fb-va to frame-buffer-adr
   open-count 1+ to open-count
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
