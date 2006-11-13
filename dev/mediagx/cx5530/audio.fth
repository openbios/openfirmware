\ See license at end of file
purpose: Cyrix 5530 I/O Companion Function 3 driver

hex headers

\ Should be somewhere else.
code lfill  (s start-addr count char -- )
   di dx mov
   cld   ds ax mov   ax es mov   ax pop   cx pop  cx 2 # shr  di pop
   rep   ax stos
   dx di mov
c;

d# 48,000 constant frame-rate
frame-rate d# 1000 / constant f/ms

" audio" device-name
" sound" device-type
2 encode-int " #input-channels" property
2 encode-int " #output-channels" property
d# 16 encode-int " sample-precisions" property
d# 16 encode-int " sample-frame-size" property
frame-rate encode-int " input-frame-rates" property
frame-rate encode-int " output-frame-rates" property
" 16bit-LE-unsigned-linear" 2dup encode-string " input-encoding-types" property
encode-string " output-encoding-types" property
" AC97,CODEC" encode-string " compatible" property

d# 128 constant /chipbase

0 value au
false value fatal-error?

: +int   ( $1 n -- $2 )   encode-int encode+  ;

\ Configuration space registers
my-address my-space        encode-phys          0 +int          0 +int

\ Memory Mapped I/O space registers
4001.1000 0  my-space  8200.0010 + encode-phys encode+  0 +int  /chipbase +int

" reg" property

: my-b@  ( offset -- b )  my-space +  " config-b@" $call-parent  ;
: my-b!  ( b offset -- )  my-space +  " config-b!" $call-parent  ;

: my-w@  ( offset -- w )  my-space +  " config-w@" $call-parent  ;
: my-w!  ( w offset -- )  my-space +  " config-w!" $call-parent  ;

: my-l@  ( offset -- l )  my-space +  " config-l@" $call-parent  ;
: my-l!  ( offset -- l )  my-space +  " config-l!" $call-parent  ;

: map-in   " map-in"  $call-parent  ;
: map-out  " map-out" $call-parent  ;

: map-regs    ( -- )  0 0  my-space h# 0200.0010 +  /chipbase map-in  to  au  ;
: unmap-regs  ( -- )  au /chipbase map-out  ;

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

3 constant #prd-entry
/prd-entry #prd-entry * constant /prds
0 value prd-in-virt
0 value prd-in-phys
0 value prd-out-virt
0 value prd-out-phys

: >prd-in-entry  ( entry# -- virt-adr )  /prd-entry * prd-in-virt +  ;
: >prd-in-phys   ( entry# -- phys-adr )  /prd-entry * prd-in-phys +  ;
: set-prd-in-entry  ( phys-adr len flags entry# -- )
   >prd-in-entry  >r
   r@ >prd-status le-w!
   r@ >prd-length le-w!
   r> >prd-addr   le-l!
;
: >prd-out-entry  ( entry# -- virt-adr )  /prd-entry * prd-out-virt +  ;
: >prd-out-phys   ( entry# -- phys-adr )  /prd-entry * prd-out-phys +  ;
: set-prd-out-entry  ( phys-adr len flags entry# -- )
   >prd-out-entry  >r
   r@ >prd-status le-w!
   r@ >prd-length le-w!
   r> >prd-addr   le-l!
;
: set-prd-in-flags-len  ( len flags entry# -- )
   >prd-in-entry tuck >prd-status le-w!
   >prd-length le-w!
;
: set-prd-out-flags-len  ( len flags entry# -- )
   >prd-out-entry tuck >prd-status le-w!
   >prd-length le-w!
;

\ DMA buffers
h# f000 constant /dma-buf
#prd-entry 1- constant #dma-buf
/dma-buf #dma-buf * constant /bufs
0 value cur-dma-in
0 value cur-dma-out
0 value dma-in-virt
0 value dma-in-phys
0 value dma-out-virt
0 value dma-out-phys

: next-dma-entry  ( cur -- next )  1+ dup  #dma-buf  =  if  drop 0  then  ;
: cur-dma-in+   ( -- )  cur-dma-in  next-dma-entry to cur-dma-in   ;
: cur-dma-out+  ( -- )  cur-dma-out next-dma-entry to cur-dma-out  ;
: >dma-in-entry  ( entry# -- virt-adr )  /dma-buf * dma-in-virt +  ;
: >dma-in-phys   ( entry# -- phys-adr )  /dma-buf * dma-in-phys +  ;
: >dma-out-entry  ( entry# -- virt-adr )  /dma-buf * dma-out-virt +  ;
: >dma-out-phys   ( entry# -- phys-adr )  /dma-buf * dma-out-phys +  ;

\ buffer allocation
: init-prds-in  ( -- )
   #dma-buf 0 do
      i >dma-in-phys   /dma-buf  eop  i  set-prd-in-entry
   loop
   prd-in-phys   0  prd-loop  #dma-buf  set-prd-in-entry
;
: init-prds-out  ( -- )
   #dma-buf 0 do
      i >dma-out-phys  /dma-buf  eop  i  set-prd-out-entry
   loop
   prd-out-phys  0  prd-loop  #dma-buf  set-prd-out-entry
;
: init-buffers  ( -- )
   \ allocate data buffers for bus mastering
   /bufs dma-alloc dup to dma-in-virt
   /bufs false dma-map-in to dma-in-phys
   /bufs dma-alloc dup to dma-out-virt
   /bufs false dma-map-in to dma-out-phys

   \ allocate PRDs
   /prds dma-alloc dup to prd-in-virt
   /prds false dma-map-in to prd-in-phys
   /prds dma-alloc dup to prd-out-virt
   /prds false dma-map-in to prd-out-phys

   \ init PRDs
   init-prds-in
   init-prds-out
;
: free-buffers  ( -- )
   dma-in-virt  dma-in-phys /bufs dma-map-out
   dma-in-virt  /bufs dma-free
   dma-out-virt dma-out-phys /bufs dma-map-out
   dma-out-virt /bufs dma-free

   prd-in-virt prd-in-phys /prds dma-map-out
   prd-in-virt /prds dma-free
   prd-out-virt prd-out-phys /prds dma-map-out
   prd-out-virt /prds dma-free
;

\ AC '97 CODEC controller stuff
struct  ( dma-regs )
   1 field >dma-cmd
   1 field >dma-status
   2+  ( reserved )
   4 field >dma-prd
constant /dma-regs

: stat@  au 8 +  rl@ ;
: stat!  au 8 +  rl! ;
: cmd@  au c +  rl@ ;
: cmd-wait  ( -- )
   true  d# 192 0 do
      cmd@ h# 10000 and  0=  if  drop false leave  then
   loop
   to fatal-error?
;
: cmd!  cmd-wait au c +  rl! ;
: 1us  ms-factor d# 1000 / spins  ;
: rst  h# 40.0000 stat!  1us  0 stat!  ;
: codec!  ( value reg# -- )  d# 24 << or  cmd!  ;
: codec@  ( reg# -- value )
   \ 192 is a ~60us delay to wait until the status tag is cleared.
   d# 192 0 do
      stat@  h# 3.0000 and  h# 1.0000 =  if  leave  then
   loop
   h# 80 or  d# 24 <<  cmd!
   \ wait until status valid and status tag is set.
   true d# 192 0 do
      stat@  h# 3.0000 and  h# 3.0000 =
      if  drop false leave  then
   loop
   to fatal-error?
   stat@ ffff and
;

: >dma-regs  ( channel# -- adr )  /dma-regs *  h# 20 +  au +  ;
: set-dma  ( prd-phys-adr in? channel# -- )
   >dma-regs >r
   8 and r@ >dma-cmd rb!		\ Set direction bit
   r@ >dma-status rb@ drop		\ Clear errors
   r> >dma-prd    rl!			\ Set address
;

: dma-go  ( channel# -- )  >dma-regs  dup rb@  1 or  swap rb!  ;
: dma-wait  ( channel# -- )
   >dma-regs  begin  dup >dma-status rb@ 1 and  until drop   ( regs-adr )
;
: dma-done  ( channel# -- )
   >dma-regs dup >dma-cmd rb@ 1 invert and swap >dma-cmd rb!
;

\ AC '97 CODEC stuff
: set-master-volume  ( value -- )
   \ XXX handle balance too
   ( db>volume )  2 codec!
;
: set-headphone-volume  ( value -- )
   ( db>volume )  4 codec!
;
: set-mono-volume  ( value -- )
   ( db>volume )  6 codec!
;
: set-tone-volume  ( value -- )
   \ XXX handle balance too
   ( db>volume )  8 codec!
;
: set-pcbeep-volume  ( value -- )
   ( db>volume )  a codec!
;
: set-pcm-gain  ( db -- )
   ( db>volume )  h# 18 codec!
;
: set-record-gain  ( db -- )
   ( db>volume )  h# 1c codec!
;
: set-linein  ( -- )
   404 h# 1a codec!
;
: set-linein-volume  ( value -- )
   ( db>volume )  10 codec!
;
: enable-playback  ( -- )
   h# 808 set-linein-volume
;
: disable-playback  ( -- )
   h# 8808 set-linein-volume
;

0 value vendor-id
: get-vendor-id  ( -- )
   h# 7c codec@  8 <<  h# 7e codec@ 8 >> or  to vendor-id
;

414453  constant  id-ad1819
4e5343  constant  id-lm4548

d# 48000 instance value sample-rate
0 instance value s/ms

: open-in  ( -- )
   sample-rate dup d# 1000 / to s/ms
   vendor-id  id-ad1819 =  if  78  else  32  then  codec!
   0 set-record-gain
;
: close-in  ( -- )
   h# 8000 set-record-gain		\ mute
;
: open-out  ( -- )
   disable-playback
   sample-rate d# 1000 / to s/ms
   frame-rate vendor-id  id-ad1819 =  if  78  else  2c  then  codec!
   h# 808 set-pcm-gain			\ enable line-out
   0 set-master-volume
   0 set-mono-volume
;
: close-out  ( -- )
   h# 8808 set-pcm-gain			\ mute
   h# 8000 set-master-volume
   h# 8000 set-mono-volume
;

200 value timeout-threshold
0 value #non-eop
false value audio-alarm-installed?
defer audio-in-hook		' noop to audio-in-hook
: audio-alarm  ( -- )
   1 >dma-regs >dma-status rb@ 1 and
   if
      audio-in-hook
      cur-dma-in+
      0 to #non-eop
   else
      #non-eop 1+ to #non-eop
   then
;
: .audio-in-timeout  ( -- )  ." FATAL ERROR: Audio input timeout." cr  ;
: audio-in-timeout?  ( -- timeout? )  #non-eop timeout-threshold >  ;
: install-audio-alarm  ( -- )  ['] audio-alarm d# 18 alarm  ;
: ?uninstall-audio-alarm  ( -- )
   audio-alarm-installed?  if
      false to audio-alarm-installed?
      1 dma-done
      ['] audio-alarm 0 alarm
   then
;
: ?install-audio-alarm  ( -- )
   audio-alarm-installed? 0=  if
      init-prds-in prd-in-phys true 1 set-dma
      0 to cur-dma-in
      0 to #non-eop
      true to audio-alarm-installed?
      install-audio-alarm
      1 dma-go
   then
;

0 instance value badr
0 instance value blen
0 instance value blen/dma-buf
0 instance value #eop			\ # of eop expected
0 instance value last-eop
0 instance value /last-dma
4 instance value /sample		\ # bytes per sample
defer sample@		' @ to sample@
defer sample!		' ! to sample!
0 value sample>
defer >sample		' noop to >sample

: setup-prds-in  ( adr len -- )
   to blen to badr
   /dma-buf 4 /sample / / to blen/dma-buf
   blen blen/dma-buf /mod swap 0>  if  1+  then
   to #eop
;
: conv-in-sample  ( src dst len -- )
   0 ?do					( src dst )
      over @ >sample				( src dst sample )
      over i + sample!				( src dst )
      swap 4 + swap				( src' dst )
   /sample +loop  2drop				( )
;

0 value eop-cnt
: (audio-in)  ( -- )
   eop-cnt 1+ to eop-cnt
   cur-dma-in >dma-in-entry badr blen blen/dma-buf min dup >r conv-in-sample
   badr r@ + to badr
   blen r> - to blen
   eop-cnt #eop =  if  ['] noop to audio-in-hook  then
;

: audio-in  ( adr len -- actual )
   tuck  setup-prds-in				( actual )
   dup blen/dma-buf mod ?dup  0=  if  blen/dma-buf  then  to  /last-dma

   0 to eop-cnt
   ['] (audio-in) to audio-in-hook
   ?install-audio-alarm

   begin  eop-cnt #eop =  audio-in-timeout? or  until
   audio-in-timeout?  if
      .audio-in-timeout
      drop 0
   then
;

fload ${BP}/dev/mulaw.fth
fload ${BP}/dev/mediagx/convert.fth
0 value stereo?		\ source buffer in stereo?
0 value ls		\ previous left sample value
0 value rs		\ previous right sample value
0 value #lc		\ internal counts til next left input sample
0 value #rc		\ internal counts til next right input sample
0 value outs		\ sample source buffer
0 value outd		\ sample dest buffer
0 value outl		\ sample length (# samples in source buffer)

: setup-prds-out  ( adr len -- )
   to blen to badr
   0 to cur-dma-out			\ dma buffer to output from
   init-prds-out
   /dma-buf 4 /sample / / s/ms * f/ms / to blen/dma-buf
   blen blen/dma-buf /mod over 0>  if  1+  then ( mod #eop )
   dup to #eop					( mod #eop )
   #dma-buf <=  if				( mod )
      ?dup  0=  if  /dma-buf  then		( last-dma-len )
      eop eot or #eop 1- set-prd-out-flags-len	( )
   else						( mod )
      drop					( )
   then						( )
   #eop #dma-buf - to last-eop
;

0 value r
: conv-out-sample2  ( src dst len -- )
   rot swap bounds ?do                          ( dst )
      f/ms r + s/ms /mod swap to r              ( dst #repeat )
      4* 2dup + -rot                            ( dst' dst #repeat*4 )
      i sample@ lfill	                        ( dst' )
   /sample +loop drop                           ( )
;

: conv-out-sample  ( src dst len -- )
   /sample / to outl to outd to outs
   ls #lc s/ms f/ms outs outl outd sample> convert-frequency
   to #lc to ls
   stereo?  if
      rs #rc s/ms f/ms outs 2+ outl outd 2+ sample> convert-frequency
      to #rc to rs
   else
      outd outl mono>stereo
   then
;
: audio-out  ( adr len -- actual )
   prd-out-phys false 0 set-dma			( adr len )
   tuck setup-prds-out				( actual )

   badr sample@  stereo?  if  lwsplit  else  0 swap  then
   to ls to rs
   s/ms dup to #lc to #rc

   \ advance slen, and badr
   badr dma-out-virt blen blen/dma-buf #dma-buf * min	( actual src dst len )
   dup >r conv-out-sample			( actual )
   blen r@ - to blen				( actual )
   badr r> + to badr				( actual )

   0 dma-go					( actual )
   #eop 1+ 1 ?do				( actual )
      0 dma-wait				( actual )
      blen 0>  if				( actual )
         badr cur-dma-out >dma-out-entry	( actual src dst )
	 blen blen/dma-buf min dup >r		( actual src dst len )
         conv-out-sample r>			( actual len )
         i last-eop =  if
            blen  eop eot or  cur-dma-out  set-prd-out-flags-len
         then
         blen over - to blen			( actual len )
         badr + to badr				( actual )
         cur-dma-out+				( actual )
      then
   loop						( actual )
   0 dma-done
;

: parse-args  ( -- flag )
   my-args  begin  dup  while       \ Execute mode modifiers
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

: playback  ( -- )  open-out enable-playback  ;

: 8khz    ( -- )  d# 8000 to sample-rate  ;
: 48khz   ( -- )  d# 48000 to sample-rate  ;
: linear  ( -- )
   ['] noop to sample>
;
: stereo  ( -- )
   linear
   true to stereo?
   4 to /sample
   ['] l@ to sample@
   ['] l! to sample!
   lin16stereo to sample>  
;
: 8bit    ( -- )
   false to stereo?
   1 to /sample
   ['] c@ to sample@
   ['] c! to sample!
   lin8mono to sample>  
;
: 16bit   ( -- )
   linear
   false to stereo?
   ['] w@ to sample@
   ['] w! to sample!
   2 to /sample
   lin16mono to sample>  
;
: mulaw   ( -- )
   8bit
   ulaw8mono to sample>
;
: default ( -- )  stereo 48khz disable-playback  ;

: open  ( -- ok? )
   fatal-error?  if  false exit  then
   map-regs
   get-vendor-id
   default
   set-linein
   parse-args  0=  if  unmap-regs false exit  then
   init-buffers
   true
;
: close  ( -- )
   ?uninstall-audio-alarm unmap-regs free-buffers  
;

: read   ( adr len -- actual )
   fatal-error?  if  2drop 0 exit  then
   open-in  audio-in  close-in
;

: write  ( adr len -- actual )
   fatal-error?  if  2drop 0 exit  then
   open-out  audio-out  close-out  
;

headers

: init-pci  ( -- )
   4001.1000 10 my-l!			\ program BAR
   6 4 my-w!				\ enable memory mapped I/O
;
: init-audio  ( -- )
   map-regs

   fill-table				\ Fill mulaw table
   punch-table
   set-linein
   close-out
   close-in
   disable-playback   

   unmap-regs
   fatal-error?  if  ." ERROR:  Audio is broken." cr  then
;

: init  ( -- )
   init-pci
   make-properties
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
