\ See license at end of file
purpose: Parse and display EDID information

\ Detailed timing descriptors
0 value the-dtd

: dtd@  ( offset -- n )  the-dtd + c@  ;
: dtd-pixclk  ( -- pix/10kHz )  0 dtd@ 1 dtd@ bwjoin   ;
: dtd-hactive  ( -- pix )  2 dtd@  4 dtd@ 4 rshift bwjoin  ;
: dtd-hblank   ( -- pix )  3 dtd@  4 dtd@ h# f and bwjoin  ;
: dtd-vactive  ( -- pix )  5 dtd@  7 dtd@ 4 rshift bwjoin  ;
: dtd-vblank   ( -- pix )  6 dtd@  7 dtd@ h# f and bwjoin  ;
: dtd-hsoffs   ( -- pix )  8 dtd@  d# 11 dtd@ 6 rshift 3 and bwjoin  ;
: dtd-hswidth  ( -- pix )  9 dtd@  d# 11 dtd@ 4 rshift 3 and bwjoin  ;
: dtd-vsoffs   ( -- pix )  d# 10 dtd@  4 rshift  d# 11 dtd@ 6 rshift 3 and bwjoin  ;
: dtd-vswidth  ( -- pix )  d# 10 dtd@  h# f and  d# 11 dtd@ 4 rshift 3 and bwjoin  ;
: dtd-hdisplay ( -- mm  )  d# 12 dtd@  d# 14 dtd@  4 rshift bwjoin  ;
: dtd-vdisplay ( -- mm )   d# 13 dtd@  d# 14 dtd@  h# f and bwjoin  ;
: dtd-hborder  ( -- pix )  d# 15 dtd@  ;
: dtd-vborder  ( -- pix )  d# 16 dtd@  ;
: dtd-features ( -- bits ) d# 17 dtd@  ;

: .dd  ( n -- )  push-decimal  (.) type  pop-base  ;
: .+-  ( n -- )  if  ." +"  else  ." -"  then  ;
: .dtd  ( adr -- )
   to the-dtd
   dtd-pixclk  ( pixclk/10khz )
   push-decimal
   <# u# u# [char] . hold u#s u#> type ."  MHz "
   dtd-hactive .dd ." x" dtd-vactive .dd  space
  \ ." " dtd-hdisplay .dd ." x" dtd-vdisplay .dd ." mm "
   ." Blank: "  dtd-hblank .dd  ." ," dtd-vblank .dd
   ."  Sync: "
      dtd-features 2 and .+-
      dtd-hswidth .dd  ." @" dtd-hsoffs .dd
   ." ," 
      dtd-features 4 and .+-
      dtd-vswidth .dd  ." @" dtd-vsoffs  .dd
   ."  Border: "  dtd-hborder .dd   ." ," dtd-vborder .dd  cr
   pop-base
;

string-array timing-names
   ," 800x600@60"
   ," 800x600@56"
   ," 640x480@75"
   ," 640x480@72"
   ," 640x480@67"
   ," 640x480@60"
   ," 720x400@88"
   ," 720x400@70"
   ," 1280x1024@75"
   ," 1024x768@75"
   ," 1024x768@72"
   ," 1024x768@60"
   ," 1024x768@87"
   ," 832x624@75"
   ," 800x600@75"
   ," 800x600@72"
   ," ?x?@?"
   ," ?x?@?"
   ," ?x?@?"
   ," ?x?@?"
   ," ?x?@?"
   ," ?x?@?"
   ," ?x?@?"
   ," 1152x870@75"
end-string-array

0 value the-edid
: edid@  ( offset -- byte )  the-edid + c@  ;

: .yres  ( xres 2nd -- )
   6 rshift  case
      0 of  d# 16 d# 10  endof
      1 of  d#  4 d#  3  endof
      2 of  d#  5 d#  4  endof
      3 of  d# 16 d#  9  endof
   endcase
   swap */ .dd
;
: .std  ( xrescoded 2nd -- )
   over 1 =  if  2drop exit  then    ( xrescoded 2nd )
   swap d# 31 + 8 * dup .dd  ." x"   ( 2nd xres )
   over .yres  ." @"                 ( 2nd )
   h# 3f and d# 60 + .dd  space      ( )
;

: .timings  ( -- )
   ." VESA timings:" cr
   d# 35 edid@  d# 36 edid@  d# 37 edid@  0  bljoin  ( n )
   d# 24 0  do
      dup 1 i lshift and  if  i timing-names count type space  then
   loop drop
   d# 54 d# 38  do
      i edid@ i 1+ edid@  .std
   2 +loop
   cr
;
: .more-std  ( offset -- )
    5 +  d# 12  bounds  do
       i edid@ i 1+ edid@  .std
    2 +loop
;
: .edid-text  ( offset -- )
    5 +  d# 13  bounds  do
       i edid@ dup  h# a =  if  drop cr unloop exit  then
       emit
    loop
    cr
;
: .other  ( offset -- )
   dup 3 + edid@  case  ( offset )
      h# fa of  dup .more-std  endof
      h# fb of  ( white point data )  endof
      h# fc of  dup ." Name: " .edid-text    endof
      h# fd of  ( monitor range limits )  endof
      h# fe of  dup ." Text: " .edid-text   endof
      h# ff of  dup ." Serial#: " .edid-text   endof
   endcase
   drop
;
: .dtds   ( -- )
   ." Detailed timings:" cr
   d# 126  d# 54  do
      i edid@  if
         i the-edid +  .dtd
      else
         i .other
      then
   d# 18 +loop
;


\ CEA-861 Extension
0 value the-cea
: cea@  ( offset -- byte )  the-cea + c@  ;

: ?.+  ( n -- n )  dup  if  ." +"  then  ;
: peel-bit  ( n -- n' flag )  dup u2/  swap 1 and  0<>  ;

\ Audio sample rates
: .cea-freqs  ( n -- )
   peel-bit  if   ." 32"  ?.+  then
   peel-bit  if   ." 44"  ?.+  then
   peel-bit  if   ." 48"  ?.+  then
   peel-bit  if   ." 88"  ?.+  then
   peel-bit  if   ." 96"  ?.+  then
   peel-bit  if  ." 176"  ?.+  then
   peel-bit  if  ." 192"       then
   ." kHz"  drop
;
\ Audio sample widths
: .cea-bits  ( n -- )
   peel-bit  if  ." 16"  ?.+  then
   peel-bit  if  ." 20"  ?.+  then
   peel-bit  if  ." 24"       then
   ." bits"  drop
;

string-array format-names
( 0 )  ," Reserved0"
( 1 )  ," LPCM"
( 2 )  ," AC-3"
( 3 )  ," MPEG1"
( 4 )  ," Moffset size 3"
( 5 )  ," MPEG2"
( 6 )  ," AAC"
( 7 )  ," DTS"
( 8 )  ," ATRAC"
( 9 )  ," SACD"
( 10 ) ," DD+"
( 11 ) ," DTS-HD"
( 12 ) ," TrueHD"
( 13 ) ," DST"
( 14 ) ," WMA"
( 15 ) ," Format15"
end-string-array

: .cea-audio  ( offset size -- )
   ." Audio: "
   bounds  ?do
      i cea@ dup 3 rshift h# f and format-names count type ." ,"  ( byte )
      7 and 1+ .d ." channels,"
      i 1+ cea@ .cea-freqs ." @"
      i 2+ cea@ .cea-bits  space
   3 +loop
   cr
;

\ CEA-861 short names for display modes
string-array short-names
 (  0 ) ," ?"
 (  1 ) ," DMT0659"    \  4:3          640x480p @ 59.94/60Hz
 (  2 ) ," 480p"       \  4:3          720x480p @ 59.94/60Hz
 (  3 ) ," 480pH"      \ 16:9          720x480p @ 59.94/60Hz
 (  4 ) ," 720p"       \ 16:9         1280x720p @ 59.94/60Hz
 (  5 ) ," 1080i"      \ 16:9        1920x1080i @ 59.94/60Hz
 (  6 ) ," 480i"       \  4:3    720(1440)x480i @ 59.94/60Hz
 (  7 ) ," 480iH"      \ 16:9    720(1440)x480i @ 59.94/60Hz
 (  8 ) ," 240p"       \  4:3    720(1440)x240p @ 59.94/60Hz
 (  9 ) ," 240pH"      \ 16:9    720(1440)x240p @ 59.94/60Hz
 ( 10 ) ," 480i4x"     \  4:3       (2880)x480i @ 59.94/60Hz
 ( 11 ) ," 480i4xH"    \ 16:9       (2880)x480i @ 59.94/60Hz
 ( 12 ) ," 240p4x"     \  4:3       (2880)x240p @ 59.94/60Hz
 ( 13 ) ," 240p4xH"    \ 16:9       (2880)x240p @ 59.94/60Hz
 ( 14 ) ," 480p2x"     \  4:3         1440x480p @ 59.94/60Hz
 ( 15 ) ," 480p2xH"    \ 16:9         1440x480p @ 59.94/60Hz
 ( 16 ) ," 1080p"      \ 16:9        1920x1080p @ 59.94/60Hz
 ( 17 ) ," 576p"       \  4:3          720x576p @ 50Hz
 ( 18 ) ," 576pH"      \ 16:9          720x576p @ 50Hz
 ( 19 ) ," 720p50"     \ 16:9         1280x720p @ 50Hz
 ( 20 ) ," 1080i25"    \ 16:9        1920x1080i @ 50Hz*
 ( 21 ) ," 576i"       \  4:3    720(1440)x576i @ 50Hz
 ( 22 ) ," 576iH"      \ 16:9    720(1440)x576i @ 50Hz
 ( 23 ) ," 288p"       \  4:3    720(1440)x288p @ 50Hz
 ( 24 ) ," 288pH"      \ 16:9    720(1440)x288p @ 50Hz
 ( 25 ) ," 576i4x"     \  4:3       (2880)x576i @ 50Hz
 ( 26 ) ," 576i4xH"    \ 16:9       (2880)x576i @ 50Hz
 ( 27 ) ," 288p4x"     \  4:3       (2880)x288p @ 50Hz
 ( 28 ) ," 288p4xH"    \ 16:9       (2880)x288p @ 50Hz
 ( 29 ) ," 576p2x"     \  4:3         1440x576p @ 50Hz
 ( 30 ) ," 576p2xH"    \ 16:9         1440x576p @ 50Hz
 ( 31 ) ," 1080p50"    \ 16:9        1920x1080p @ 50Hz
 ( 32 ) ," 1080p24"    \ 16:9        1920x1080p @ 23.98/24Hz
 ( 33 ) ," 1080p25"    \ 16:9        1920x1080p @ 25Hz
 ( 34 ) ," 1080p30"    \ 16:9        1920x1080p @ 29.97/30Hz
 ( 35 ) ," 480p4x"     \  4:3       (2880)x480p @ 59.94/60Hz
 ( 36 ) ," 480p4xH"    \ 16:9       (2880)x480p @ 59.94/60Hz
 ( 37 ) ," 576p4x"     \  4:3       (2880)x576p @ 50Hz
 ( 38 ) ," 576p4xH"    \ 16:9       (2880)x576p @ 50Hz
 ( 39 ) ," 1080i25"    \ 16:9 1080i(1250 Total) @ 50Hz*
 ( 40 ) ," 1080i50"    \ 16:9        1920x1080i @ 100Hz
 ( 41 ) ," 720p100"    \ 16:9         1280x720p @ 100Hz
 ( 42 ) ," 576p100"    \  4:3          720x576p @ 100Hz
 ( 43 ) ," 576p100H"   \ 16:9          720x576p @ 100Hz
 ( 44 ) ," 576i50"     \  4:3    720(1440)x576i @ 100Hz
 ( 45 ) ," 576i50H"    \ 16:9    720(1440)x576i @ 100Hz
 ( 46 ) ," 1080i60"    \ 16:9        1920x1080i @ 119.88/120Hz
 ( 47 ) ," 720p120"    \ 16:9         1280x720p @ 119.88/120Hz
 ( 48 ) ," 480p119"    \  4:3          720x480p @ 119.88/120Hz
 ( 49 ) ," 480p119H"   \ 16:9          720x480p @ 119.88/120Hz
 ( 50 ) ," 480i59"     \  4:3    720(1440)x480i @ 119.88/120Hz
 ( 51 ) ," 480i59H"    \ 16:9    720(1440)x480i @ 119.88/120Hz
 ( 52 ) ," 576p200"    \  4:3          720x576p @ 200Hz
 ( 53 ) ," 576p200H"   \ 16:9          720x576p @ 200Hz
 ( 54 ) ," 576i100"    \  4:3    720(1440)x576i @ 200Hz
 ( 55 ) ," 576i100H"   \ 16:9    720(1440)x576i @ 200Hz
 ( 56 ) ," 480p239"    \  4:3          720x480p @ 239.76/240Hz
 ( 57 ) ," 480p239H"   \ 16:9          720x480p @ 239.76/240Hz
 ( 58 ) ," 480i119"    \  4:3    720(1440)x480i @ 239.76/240Hz
 ( 59 ) ," 480i119H"   \ 16:9    720(1440)x480i @ 239.76/240Hz
 ( 60 ) ," 720p24"     \ 16:9         1280x720p @ 23.98/24Hz
 ( 61 ) ," 720p25"     \ 16:9         1280x720p @ 25Hz
 ( 62 ) ," 720p30"     \ 16:9         1280x720p @ 29.97/30Hz
 ( 63 ) ," 1080p120"   \ 16:9        1920x1080p @ 119.88/120Hz
end-string-array

false value 1080p-support?
false value 1080p-native?
false value 720p-native?
: .cea-video  ( offset size -- )
   false to 720p-native?  false to 1080p-native?    false to 1080p-support?
   ." CEA/HDMI Modes: "
   bounds  ?do
      i cea@                            ( code )
      dup h# 80 and  if                 ( code )
          ." *" h# 7f and               ( index )
          dup d#  4 =  if  true  to  720p-native?  then
          dup d# 16 =  if  true  to 1080p-native?  then
      then                              ( index )
      dup d# 16 =  if  true to 1080p-support?  then
      short-names count type space      ( )
   loop
   cr
;

: .2x  ( n -- )  push-hex  <# u# u# u#> type  pop-base  ;
: .cea-vendor  ( offset size -- )
   ." Vendor: "
   over 2 + cea@ .2x ." :" over 1 + cea@ .2x ." :" over cea@ .2x   ( offset size )
   ."  SPA " over 3 + cea@ .2x ." ."  over 4 + cea@ .2x            ( offset size )
   5 /string  bounds ?do  i cea@ .2x space  loop                   ( )
   cr
;

\ Speaker configurations.  Long ago, in a galaxy far away, one
\ good speaker was considered good enough.  Then marketing
\ invented stereo so they could sell more speakers, and the
\ rest is history.
: .cea-speaker  ( offset size -- )
   drop cea@
   peel-bit  if  ." Front_L+R "         then  \ Stereo
   peel-bit  if  ." LFE "               then  \ Subwoofer   makes 2.1
   peel-bit  if  ." Front_Center "      then  \ Center fill makes 3.1
   peel-bit  if  ." Rear_L+R "          then  \ Ambience    makes 5.1
   peel-bit  if  ." Rear_Center "       then  \ 7.1 ...
   peel-bit  if  ." Front_Center_L+R "  then  \ How many speakers do they want to sell you?
   peel-bit  if  ." Rear_Center_L+R "   then  \ How can you live without twelve speakers?
   drop
;

: .data-block  ( offset -- advance )
   dup 1+  swap cea@                  ( offset' tag )
   dup h# 1f and swap                 ( offset size tag )
   5 rshift case                      ( offset size )
      1 of  2dup .cea-audio   endof   ( offset size )
      2 of  2dup .cea-video   endof   ( offset size )
      3 of  2dup .cea-vendor  endof   ( offset size )
      4 of  2dup .cea-speaker endof   ( offset size )
   endcase                            ( offset size )
   nip 1+                             ( advance )
;
: .cea-data  ( -- )
   2 cea@  4  ?do
      i .data-block   ( advance )
   +loop
;
: .cea-dtds  ( -- )
   ." CEA Detailed Timings:" cr
   2 cea@  the-cea +       ( adr )
   begin  dup w@  while    ( adr )
      dup .dtd             ( adr )
      d# 18 +              ( adr' )
   repeat                  ( adr )
   drop                    ( )
;

: .cea-ext  ( adr -- )
   to the-cea
   1 cea@ 3 <>  if
      ." CEA version " 1 cea@ .d ." not supported" cr
      exit    
   then
   .cea-data
   .cea-dtds   
;
: .edid-extension  ( adr -- )
   dup c@  case
      2 of  dup .cea-ext  endof
      \ Ignoring other extensions for now
   endcase
   drop
;
: .extensions  ( -- )
    d# 126 edid@  0  ?do
       the-edid i 1+ h# 80 * +  .edid-extension
    loop
;
: dump-edid  ( adr len -- )
   0=  if  drop exit  then   ( adr )
   to the-edid
   the-edid  " "(00ffffffffffff00)" comp  if
      ." Not an EDID" cr
      exit
   then
   d# 21 edid@ .dd ." x" d# 22 edid@ .dd ."  cm " cr
   .timings
   .dtds
   .extensions
;
\ Wait for an HDMI monitor to be connected
: wait-hdmi  ( -- )
   " hdmi-present?"  $call-screen 0=  if
      ." Connect an HDMI monitor ..."
      begin  " hdmi-present?" $call-screen  until
      cr
   then
;
: get-hdmi-edid  ( -- adr len )
   " /hdmi-ddc" open-dev  dup  if    ( ih )
      " edid$" 2 pick $call-method   ( ih adr len )
      rot close-dev                  ( adr len )
   else
      " "
   then
;
: choose-hdmi-resolution  ( -- )
   ." Turning on monitor at "
   1080p-native?   if   ." 1080p" 1080p   else   \ First choice
   720p-native?    if   ." 720p"   720p   else   \ Second choice
   1080p-support?  if   ." 1080p" 1080p   else   \ No native, use 1080p if supported
      ." 720p"   720p   ."  (guess)"             \ Fallback
   then then then
   cr
;
: .hdmi  ( -- )
   wait-hdmi
   get-hdmi-edid dump-edid
   choose-hdmi-resolution
;

\ LICENSE_BEGIN
\ Copyright (c) 2012 FirmWorks
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
