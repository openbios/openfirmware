purpose: AC97 Driver for Geode CS5536 companion chip
\ See license at end of file

hex
headers

" audio" device-name
" sound" device-type
1 encode-int " #input-channels" property
2 encode-int " #output-channels" property
d# 16 encode-int " sample-precisions" property
d# 16 encode-int " sample-frame-size" property
\ frame-rate encode-int " input-frame-rates" property
\ frame-rate encode-int " output-frame-rates" property
" 16bit-LE-unsigned-linear" 2dup encode-string " input-encoding-types" property
encode-string " output-encoding-types" property
" AC97,CODEC" encode-string " compatible" property

d# 128 constant /chipbase

0 value au
false value fatal-error?

: +int   ( $1 n -- $2 )   encode-int encode+  ;

\ Configuration space registers
my-address my-space        encode-phys          0 +int          0 +int

\ Register in PCI I/O space
0 0  h# 0100.0010 my-space  + encode-phys encode+  0 +int  /chipbase +int

" reg" property

: my-w!  ( w offset -- )  my-space +  " config-w!" $call-parent  ;
\ : my-l!  ( offset -- l )  my-space +  " config-l!" $call-parent  ;

: map-regs    ( -- )
   0 0  my-space h# 100.0010 +  /chipbase " map-in"  $call-parent  to  au
   5 4 my-w!
;
: unmap-regs  ( -- )
   au /chipbase " map-out" $call-parent
   0 4 my-w!
;

: dma-alloc  ( size -- virt )  " dma-alloc" $call-parent  ;
: dma-free   ( virt size -- )  " dma-free" $call-parent  ;
: dma-map-in   ( virt size cache? -- phys )  " dma-map-in" $call-parent  ;
: dma-map-out  ( vaddr devaddr n -- )  " dma-map-out" $call-parent  ;

\ PRD buffers
struct  ( prd-entry )
   4 field >prd-addr
   2 field >prd-length
   2 field >prd-status
constant /prd-entry

h# 8000 constant eot
h# 4000 constant eop
h# 2000 constant prd-loop

0 value prd-in-virt
0 value prd-in-phys
0 value prd-in-len

0 value prd-out-virt
0 value prd-out-phys
0 value prd-out-len

: set-prd-entry  ( phys-adr len prd -- )
   >r
   0  r@ >prd-status w!
   r@ >prd-length w!
   r> >prd-addr   l!
;
: set-eot  ( prd -- )  eot swap >prd-status w!  ;

h# fffc constant /prd-buf    \ Largest transfer that one PRD can control

\ PRD table allocation
: alloc-prds  ( datalen -- virt phys prds-len )
   /prd-buf /mod  swap  if  1+  then   ( #prds )
   /prd-entry *                        ( prds-len )
   dup dma-alloc                       ( prds-len virt )
   2dup swap  true dma-map-in          ( prds-len virt phys )
   rot                                 ( virt phys prds-len )
;
: free-prds  ( virt phys len -- )
   >r                                  ( virt phys r: len )
   over swap r@ dma-map-out            ( virt )
   r> dma-free                         ( )
;

\ AC '97 CODEC controller stuff
struct  ( dma-regs )
   1 field >dma-cmd
   1 field >dma-status
   2+  ( reserved )
   4 field >dma-prd
constant /dma-regs

: stat@  ( -- l )  au 8 +  rl@  ;
: stat!  ( l -- )  au 8 +  rl!  ;
: cmd@   ( -- l )  au h# c +  rl@ ;
: cmd-wait  ( -- )
   true  d# 192 0 do
      cmd@ h# 10000 and  0=  if  drop false leave  then
   loop
   to fatal-error?
;
: cmd!  ( l -- )  cmd-wait  au h# c +  rl! ;
\ : 1us  ( -- )  ms-factor d# 1000 / spins  ;
\ : rst  ( -- )  h# 40.0000 stat!  1us  0 stat!  ;
: codec-ready?  ( -- flag )  stat@ h# 80.0000 and 0<>  ;

: codec!  ( value reg# -- )
   d# 24 << or  h# 1.0000 or  cmd!
   begin  cmd@ h# 1.0000 and  0=  until
;
: codec@  ( reg# -- value )
   \ 192 is a ~60us delay to wait until the status tag is cleared.

   stat@ drop   ( reg# )    \ Clear old status
   d# 24 <<  h# 8001.0000 or  cmd!

   \ wait until status new
   true                      ( error? )
   d# 192  0  do             ( error? )
      stat@  h# 2.0000 and  if  0= leave  then
   loop
   to fatal-error?
   stat@  h# ffff and
;

: iand  ( n1 mask -- n2 )  invert and  ;
: codec-set  ( mask reg# -- )  tuck codec@  or         swap codec!  ;
: codec-clr  ( mask reg# -- )  tuck codec@  swap iand  swap codec!  ;

: >dma-regs  ( channel# -- adr )  /dma-regs *  h# 20 +  au +  ;
: start-dma  ( prd-phys-adr in? channel# -- )
   >dma-regs >r
   r@ >dma-status rb@ drop	\ Clear errors
   swap r@ >dma-prd  rl!	\ Set address
   8 and 1 or r> >dma-cmd rb!	\ Set direction and go bits
;

: dma-wait  ( channel# -- )
   >dma-regs >dma-cmd  begin  ( adr )
      dup rb@ 1 and  0=       ( adr flag )
   until                      ( adr )
   drop                       ( )
;

\ : dma-wait  ( channel# -- )
\    >dma-regs  begin  dup >dma-status rb@ 1 and  until drop   ( regs-adr )
\ ;
\ : dma-done  ( channel# -- )
\    >dma-regs dup >dma-cmd rb@ 1 invert and swap >dma-cmd rb!
\ ;

: db>volume  ( atten-db -- regval )
   2*                    ( db*2 )
   3 /                   ( regval ) \ scale by 1.5 dB steps
   h# 1f max             ( regval' )
   dup wljoin            ( left,right )
;


\ AC '97 CODEC stuff
: set-master-volume     ( value -- )  ( db>volume )      2 codec!  ;  \ XXX handle balance too
: set-headphone-volume  ( value -- )  ( db>volume )      4 codec!  ;
: set-mono-volume       ( value -- )  ( db>volume )      6 codec!  ;
: set-tone-volume       ( value -- )  ( db>volume )      8 codec!  ;  \ XXX handle balance too
: set-pcbeep-volume     ( value -- )  ( db>volume )  h#  a codec!  ;
: set-pcm-gain          ( db -- )     ( db>volume )  h# 18 codec!  ;
: set-record-gain       ( db -- )     ( db>volume )  h# 1c codec!  ;
: set-linein-volume  ( value -- )     ( db>volume )  h# 10 codec!  ;
: enable-playback    ( -- )  h#  808 set-linein-volume  ;
: disable-playback   ( -- )  h# 8808 set-linein-volume  ;
: set-linein         ( -- )  h# 404 h# 1a codec!  ;

: set-mic-db  ( db -- )
   dup d# 12 >  if       ( db )
      d# 20 -  h# 40     ( db' base-regval )  \ Boost gain by 20 dB
   else                  ( db )
      0                  ( db base-regval )
   then                  ( db base-regval )
   swap                  ( base-regval db )
   d# 12 swap -          ( base-regval attenuation )
   0 max                 ( base-regval attenuation' )
   2* 3 / h# 1f min      ( base-regval reg-low )
   or                    ( regval )
   h# e codec!
;

: mic-mute  ( -- )  h# 8008 h# e codec!  ;

: mic+0db   ( -- )  h# 40  h# 0e codec-clr  ;
: mic+20db  ( -- )  h# 40  h# 0e codec-set  ;

: mic-input  ( -- )  0  h# 1a codec!  ;


0 value device-id
: get-device-id  ( -- )
   h# 7c codec@  8 <<  h# 7e codec@ 8 >> or  to device-id
;

d# 48000 instance value sample-rate
0 instance value s/ms

: set-sample-rate  ( hz -- )  to sample-rate  ;

: open-in  ( -- )
   sample-rate d# 1000 / to s/ms   ( hz )
   sample-rate  h# 32 codec!
   0 set-record-gain
   mic+0db
   mic-input
;
: amp-default-on?  ( -- flag )  " gx?" eval  ;
: close-in  ( -- )
\   h# 8000 set-record-gain		\ mute
;
: codec-set  ( bitmask reg# -- )  dup >r codec@ or  r> codec!  ;
: codec-clr  ( bitmask reg# -- )  dup >r codec@ swap invert and  r> codec!  ;
: amplifier-on   ( -- )
   h# 8000 h# 26  amp-default-on?  if  codec-clr  else  codec-set  then
;
: amplifier-off  ( -- )
   h# 8000 h# 26  amp-default-on?  if  codec-set  else  codec-clr  then
;

: open-out  ( -- )
   amplifier-on
   disable-playback
   sample-rate d# 1000 / to s/ms
   sample-rate  dup h# 2c codec!  dup h# 2e codec!  h# 30 codec!
   0 set-master-volume
\   0 set-mono-volume
   h# 0f0f set-headphone-volume
   h# 808 set-pcm-gain		\ enable line-out
   h# 808 h# 38 codec!		\ enable surround out (headphones)
   h# 000 h# 76 codec!  	\ Route mixer out to headphones
;
: close-out  ( -- )
   h# 8808 set-pcm-gain			\ mute
   h# 8000 set-master-volume
   h# 8000 set-mono-volume
   amplifier-off
;

0 instance value last-prd

: fill-prds  ( phys len prd-virt -- last-prd )
   swap  begin                           ( phys prd len )
      3dup  /prd-buf min                 ( phys prd len  phys prd this-len )
      tuck >r   set-prd-entry            ( phys prd len  r: this-len )
      r@  -                              ( phys prd len' r: this-len )
   dup  while                            ( phys prd len' r: this-len )
      rot r> + -rot                      ( phys' prd len' )
      swap /prd-entry + swap             ( phys' prd' len' )
   repeat                                ( phys prd len' r: this-len )
   rot r> 3drop                          ( prd )
   dup set-eot                           ( prd )
   to last-prd
;

1 constant in-channel
: audio-in  ( adr len -- actual )
   dup 0=  if  nip exit  then            ( adr len )

   dup alloc-prds  to prd-in-len  to prd-in-phys  to prd-in-virt  ( adr len )
   tuck  true  dma-map-in                ( len phys )

   over prd-in-virt  fill-prds

   prd-in-phys true in-channel start-dma

   in-channel dma-wait
   prd-in-virt prd-in-phys prd-in-len free-prds
;

6 constant out-channel

\ I don't know why it's necessary to use channel 6 (surround)
\ instead of channel 0 (PCM).  The data sheet says that the
\ headphones can be driven from the mixer output.
: audio-out  ( adr len -- actual )
   dup 0=  if  nip exit  then            ( adr len )

   dup alloc-prds  to prd-out-len  to prd-out-phys  to prd-out-virt  ( adr len )
   tuck  true  dma-map-in                ( len phys )

   over prd-out-virt  fill-prds          ( len )

   prd-out-phys false out-channel start-dma  ( len )
;

: open-args  ( -- arg$ )  my-args ascii : left-parse-string 2swap 2drop  ;
: parse-args  ( -- flag )
   open-args  begin  dup  while       \ Execute mode modifiers
      ascii , left-parse-string            ( rem$ first$ )
      my-self ['] $call-method  catch  if  ( rem$ x x x )
         ." Unknown argument" cr
         3drop 2drop false exit
      then                                 ( rem$ )
   repeat                                  ( rem$ )
   2drop
   true
;

external

: stats  ( adr len -- min max avg )
   >r >r  h# 9000 h# -9000 0   ( min max sum r: len adr )
   r> r@ bounds  ?do           ( min max sum r: len )
      i <w@  +                 ( min max sum' r: len )
      swap  i <w@  max  swap   ( min max' sum r: len )
      rot   i <w@  min  -rot   ( min' max sum r: len )
   /w +loop                    ( min max sum )
   r> 2/ /                     ( min max avg )
;

: hpf-on   ( -- )  h# 1000  h# 5c codec-clr  ;
: hpf-off  ( -- )  h# 1000  h# 5c codec-set  ;

: vbias-off  ( -- )  4  h# 76 codec-set  ;
: vbias-on   ( -- )  4  h# 76 codec-clr  ;

: vbias-low   ( -- )  8  h# 76 codec-clr  ;
: vbias-high  ( -- )  8  h# 76 codec-set  ;

: playback  ( -- )  open-out enable-playback  ;

\ : 8khz    ( -- )  d# 8000 set-sample-rate  ;
: 48khz   ( -- )  d# 48000 set-sample-rate  ;
: default ( -- )  48khz disable-playback  ;

: open  ( -- ok? )
   map-regs
   codec-ready?  0=  if  false exit  then
   get-device-id
   fatal-error?  if  false exit  then
   default
   1  h# 2a codec-set   \ Enable variable rate
   parse-args  0=  if  unmap-regs false exit  then
   true
;
: close  ( -- )  unmap-regs  ;

: read   ( adr len -- actual )
\   fatal-error?  if  2drop 0 exit  then
   open-in  audio-in  close-in
;

: write  ( adr len -- actual )
\   fatal-error?  if  2drop 0 exit  then
   open-out  audio-out
;
: write-done  ( -- )
   6 dma-wait
   prd-out-virt prd-out-phys prd-out-len free-prds
   close-out  
;

headers

\ : init-pci  ( -- )
\    4001.1000 10 my-l!			\ program BAR
\    6 4 my-w!				\ enable memory mapped I/O
\ ;
: init-audio  ( -- )
   map-regs

\   fill-table				\ Fill mulaw table
\   punch-table
   set-linein
   close-out
   close-in
   disable-playback   

   unmap-regs
\   fatal-error?  if  ." ERROR:  Audio is broken." cr  then
;

: init  ( -- )
\   init-pci
\   make-properties
   init-audio
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
