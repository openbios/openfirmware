\ See license at end of file
purpose: Display driver for Intel Pineview using 1280x800 LCD panel on LVDS

\ This is an i915 variant.  The driver hardcodes some assumptions about display
\ resolution and output device.

\ 0 0  " 2,0"  " /pci" begin-package

" display" device-name

\ Configuration space registers
my-address my-space              encode-phys
                             0     encode-int encode+ 0 encode-int encode+

\ MMIO register bank
0 0        my-space  0200.0010 + encode-phys encode+
                             0 encode-int encode+  h# 80000 encode-int encode+

\ I/O Space registers
0 0        my-space  h# 0100.0014 + encode-phys encode+
                             0 encode-int encode+  8 encode-int encode+

\ Aperture
0 0        my-space  h# 0200.0018 + encode-phys encode+
                             0 encode-int encode+  h# 1000.0000 encode-int encode+

\ GATT
0 0        my-space  h# 0200.001c + encode-phys encode+
                             0 encode-int encode+  h# 0004.0000 encode-int encode+

 " reg" property

: my-l@  ( offset -- l )  my-space + " config-l@" $call-parent  ;
: my-l!  ( l offset -- )  my-space + " config-l!" $call-parent  ;
: my-w@  ( offset -- w )  my-space + " config-w@" $call-parent  ;
: my-w!  ( w offset -- )  my-space + " config-w!" $call-parent  ;

false value scaled?

d# 16 value depth

0 value vdc
: page-bits  ( n -- n' )  h# fff invert and  ;

: pci-len  ( bar-offset -- len )
   >r
   r@ my-l@         ( oldval )
   -1 r@ my-l!      ( oldval )
   r@ my-l@         ( oldval writable-bits )
   swap r> my-l!    ( writable-bits )
   h# f invert and  ( top-bits )
   invert 1+        ( len )
;

0 value gtt
0 value gatt

0 value gtt-phys
0 value gatt-phys
0 value gtt-start
0 value /gtt
0 value /gatt
0 value stolen-base
0 value scratch-page
0 value scratch-page-pa

h# 20.0000 value /fb   \ Enough for 1280x800x16bpp

: mmio@  ( offset -- l )  vdc + rl@  ;
: mmio!  ( l offset -- )  vdc + rl!  ;

: adr>page#  ( adr -- page# )  d# 12 rshift  ;
: page#>adr  ( page# -- adr )  d# 12 lshift  ;
h# 1000 constant /page

: map-bar  ( phys.lo len bar# -- vadr )
   swap >r                       ( phys.lo bar# r: len )
   my-space + h# 200.0000 +      ( phys.lo phys.hi r: len )
   0 swap  r>                    ( phys.lo,mid,hi len )
   " map-in" $call-parent
;

: /stolen  ( -- n )
   h# 52 my-w@ 4 >> h# f and  case
      0 of  0   endof
      1 of  h# 10.0000  endof
      3 of  h# 80.0000  endof
      true abort" Invalid value in Graphics Mode Select field"
   endcase
;
: init-gtt  ( -- )
   h# 18 my-l@ page-bits to gatt-phys
   h# 1c my-l@ page-bits to gtt-start
   h# 1c pci-len to /gtt               \ Can also be determined from config register 52
   h# 18 pci-len to /gatt
   h# 5c my-l@   to stolen-base

   h# 0  /gtt  h# 1c map-bar to gtt

   \ Insert the stolen pages into the GTT
   stolen-base 1 +                         ( pte-template )
   /stolen  0  do                          ( pte-template )
      dup i +   gtt i adr>page# la+  rl!   ( pte-template )
   /page +loop                             ( pte-template )
   drop

   \ Fill the rest of the GTT with PTEs for a scratch page
   /page " dma-alloc" $call-parent to scratch-page
   scratch-page h# 1000 false " dma-map-in" $call-parent to scratch-page-pa

   /gatt /stolen  ?do
      scratch-page-pa 1+  gtt i adr>page# la+  rl!
   /page +loop

   gtt /gtt + /page - rl@ drop  \ Sync
;
: memory-setup  ( -- )
   h# 0     h# 80000 h# 10 map-bar  to vdc   \ &
   4 my-w@ 7 or 4 my-w!            \ Enable bus mastering, memory and I/O access
   
   init-gtt

   " address" get-my-property  if
      gatt-phys  encode-int " address" property
      h# 0 /fb  h# 18 map-bar  to frame-buffer-adr
   else
      decode-int to frame-buffer-adr
      2drop
   then
;

\ Geometry for 1280x800 LCD

d# 1280 constant hdisplay
d# 1296 constant hsstart
d# 1344 constant hsend
d# 1440 constant htotal

d#  800 constant vdisplay
d#  801 constant vsstart
d#  804 constant vsend
d#  818 constant vtotal

d# 1024 value width  \ If scaled is false, will be replaced with hdisplay
d#  768 value height \ If scaled is false, will be replaced with vdisplay

\ h# d804.0000 constant dpll-val    \ VCO, high speed, VGA disable, LVDS, clock div 10, post div 4
h# 8480.0000 constant dpll-val-a  \ Pipe A &
h# 9802.0000 constant dpll-val-b  \ Pipe B &
dpll-val-b constant dpll-val

h# 0020.0074 constant fp-val      \ N, M1, M2 divisors &
h# 9500.0000 constant dspcntr-val \ Enable, NoGamma, 16bpp ? no alpha, pipe b &

\ Empirically this has no effect.  It is probably for CRT output
\ : dac-on  ( -- )
\    h# c000.0018 h# 61100 mmio!  \ 80000000-DAC_ON 40000000-PIPEB 10-PVSYNC 8-PHSYNC
\ ;

: bytes/line  ( -- n )  width  depth 8 /  *  ;

h# 0000 constant pipe-a
h# 1000 constant pipe-b
pipe-b value pipe

: mmio!!  ( value offset -- )  tuck mmio!  mmio@ drop  ;

: pipe@  ( offset -- n )  pipe + mmio@  ;
: pipe!  ( n offset -- )  pipe + mmio!  ;
: pipe!! ( n offset -- )  pipe + mmio!! ;

h# 70180 constant dspcntr-reg
h# 70184 constant dspbase-reg
h# 70008 constant pipeconf-reg
h# 61230 constant pfit-reg
h# 61180 constant lvds-reg

\ Packs two 16-bit values into a 32-bit register, offsetting
\ each value by -1
: crtconf!  ( low high reg -- )
   >r  swap 1-  swap 1-  wljoin  r>   pipe!
;

\ A few of the pipe-dependent registers are at offsets of 4
\ instead of h# 1000.

: +pipe  ( offset -- offset' )  pipe  if  4 +  then  ;

: fpreg!  ( value -- )  h# 6040  +pipe  mmio!  ;

: dpll!  ( value -- )
   h# 6014 +pipe  mmio!!
   d# 150 " us" evaluate
;
: dpll@  ( -- value )  h# 6014 +pipe  mmio@  ;
: wait-vblank  ( -- )  d# 30 ms  ;

h# 8000.0000 constant enable-bit

: load-lut  ( -- )
   100 0  do
      i i i 0 bljoin  h# a000 pipe 2/ + i la+ l!
   loop
;

: crtc-dpms-off  ( -- )  \ CRTC prepare method
   \ Disable display plane
   dspcntr-reg pipe@          ( val )
   dup enable-bit and  if   ( val )
      enable-bit invert and  dspcntr-reg pipe!
      dspbase-reg pipe@  dspbase-reg pipe!!
   else
      drop
   then
   wait-vblank

   \ Disable display pipes
   pipeconf-reg pipe@         ( val )
   dup enable-bit and  if   ( val )
      enable-bit invert and  pipeconf-reg pipe!!
   else
      drop
   then
   wait-vblank
		
   dpll@ dup enable-bit and   if
      enable-bit invert and dpll!
   else
      drop
   then
;

: crtc-dpms-on  ( -- )   \ CRTC commit method
   dpll@ dup enable-bit and  0=  if      ( value )
      dup dpll!                          ( value )
      enable-bit or  dup dpll!  dpll!    ( )
   else                                  ( value )
      drop                               ( )
   then

   pipeconf-reg pipe@  dup enable-bit  and  0=  if
      enable-bit or  pipeconf-reg pipe!
   else
      drop
   then

   dspcntr-reg pipe@  dup enable-bit and  if
      enable-bit or  dspcntr-reg pipe!
      dspbase-reg pipe@  dspbase-reg pipe!
   else
      drop
   then

   load-lut
;

: lvds-set-mode  ( -- )
   \ When using LVDS, you have to do this little dance to turn on the PLL

   fp-val fpreg!
   dpll-val enable-bit invert and  dpll!  \ VCO_ENABLE off for now

   lvds-reg mmio@      \ LVDS configuration
      h# c030.0300 or  \  LVDS_PORT_EN , LVDS_PIPEB_SELECT , LVDS_A0A2_CLKA_POWER_UP  ?? what is 30.0000 bit
      h# 0000.003c invert and  \ ! LVDS_CLKB_POWER_UP , ! LVDS_B0B3_POWER_UP
   lvds-reg mmio!!

   fp-val fpreg!
   dpll-val dpll!  \ VCO_ENABLE on

   \ Double write because Linux driver does it because BIOS does it
   dpll-val dpll!  \ VCO_ENABLE on

   \ Now that the dance is over we can configure the geometry

   hdisplay   htotal  h# 60000  crtconf!  \ H Display
   hdisplay   htotal  h# 60004  crtconf!  \ H Blanking
   hsstart    hsend   h# 60008  crtconf!  \ H Sync
   vdisplay   vtotal  h# 6000c  crtconf!  \ V Display
   vdisplay   vtotal  h# 60010  crtconf!  \ V Blanking
   vsstart    vsend   h# 60014  crtconf!  \ V Sync

   bytes/line      h# 70188  pipe!        \ Pitch (stride)
   width   height  h# 70190  crtconf!     \ Size
   0               h# 7018c  pipe!        \ Position
   height   width  h# 6001c  crtconf!     \ Pipe source
   enable-bit pipeconf-reg pipe!!         \ Pipe config

   wait-vblank

   dspcntr-val dspcntr-reg pipe!   \ Display control

   0 dspbase-reg pipe!             \ PIPExBASE

   enable-bit h# 71400 mmio!  \ Disable VGA plane

   wait-vblank  
;

false value backlight-inverse?
: set-backlight  ( percentage -- )
   h# 61254 mmio@ lwsplit nip   ( percent max )
   1 invert and  >r             ( percent r: max' )
   d# 20 max                    ( percentage' r: max )
   r@ * d# 100 /                ( duty-cycle  r: max )
   backlight-inverse?  if       ( duty-cycle  r: max )
      r@ swap -                 ( duty-cycle' )
   then                         ( duty-cycle  r: max )
   1 invert and                 ( duty-cycle  r: max ) \ Low bit must be 0
   r> wljoin h# 61254 mmio!     ( )  \ BLC_PWM_CTL
;

d# 100 value backlight-val

h# 61200 constant pp-status
h# 61204 constant pp-control
: lvds-on  ( -- )
   pp-control mmio@ 1 or  pp-control mmio!  \ POWER_TARGET_ON
   begin  pp-status mmio@  enable-bit and  until
   backlight-val set-backlight
;
: lvds-off  ( -- )
   0 set-backlight
   pp-control mmio@ 1 invert and  pp-control mmio!
   begin  pp-status mmio@  enable-bit and  0=  until
;

: .ps  pp-status mmio@ .  ;
: pctl  pp-control mmio! ;

: lvds-scaling  ( -- )
   scaled?  if  h# 8000.2668  else  0  then
   pfit-reg mmio!
\   pipe h# 1000 /  d# 29 lshift  pfit-reg mmio!
;
: setmode  ( -- )
   scaled?  if  d# 1024 d# 768  else  hdisplay vdisplay  then
   to height  to width
   memory-setup
   lvds-off               \ Output prepare method
   crtc-dpms-off          \ CRTC prepare method
   lvds-set-mode          \ CRTC mode_set method
   lvds-scaling           \ Output mode_set method
   crtc-dpms-on           \ CRTC commit method
   lvds-on                \ Output commit method
;

: erase-frame-buffer  ( -- )
   frame-buffer-adr /fb    ( adr len )
   depth case
      8      of  h# 0f           fill  endof
      d# 16  of  h# ffff         " wfill" evaluate  endof
      d# 32  of  h# ffff.ffff    " lfill" evaluate  endof
      ( default )  nip nip
   endcase
   h# f to background-color
;
: map-frame-buffer  ( -- )
   0 /fb h# 18 map-bar to frame-buffer-adr
;
: dump-regs  ( -- )
   h# 80000 0  do
      i mmio@  dup 0<>  swap h# ffffffff <>  and  if
	 i 5 u.r  i mmio@ 9 u.r cr
      then
   4 +loop
;

: declare-props  ( -- )		\ Instantiate screen properties
   " width" get-my-property  if  
      width   encode-int " width"     property
      height  encode-int " height"    property
      depth   encode-int " depth"     property
      bytes/line  encode-int " linebytes" property
   else
      2drop
   then
;

defer gp-install  ' noop to gp-install

: set-terminal  ( -- )
   width  height                              ( width height )
   over char-width / over char-height /       ( width height rows cols )
   bytes/line depth " fb-install" evaluate gp-install     ( )
;


0 value open-count

: display-remove  ( -- )
   open-count 1 =  if
   then
   open-count 1- 0 max to open-count
;

: display-install  ( -- )
   open-count 0=  if
      setmode
      declare-props		\ Setup properites
      map-frame-buffer
      erase-frame-buffer
   else
      map-frame-buffer
   then
   default-font set-font
   set-terminal
   open-count 1+ to open-count
;

: display-selftest  ( -- failed? )  false  ;

' display-install  is-install
' display-remove   is-remove
' display-selftest is-selftest

" display"                      device-type
" ISO8859-1" encode-string    " character-set" property
0 0  encode-bytes  " iso6429-1983-colors"  property
