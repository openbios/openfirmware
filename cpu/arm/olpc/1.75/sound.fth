0 0  " d42a0c00"  " /" begin-package
" audio" name
my-space h# 40 reg

: sspa!  ( n offset -- )  h# d42a.0c00 + l!  ;  \ Write a register in SSPA1
: sspa@  ( offset -- n )  h# d42a.0c00 + l@  ;  \ Read a register in SSPA1
: adma!  ( n offset -- )  h# d42a.0800 + l!  ;
: adma@  ( offset -- n )  h# d42a.0800 + l@  ;

: audio-clock-on  ( -- )
   h# 600 h# d428.290c l!  d# 10 us  \ Enable
   h# 610 h# d428.290c l!  d# 10 us  \ Release reset
   h# 710 h# d428.290c l!  d# 10 us  \ Enable
   h# 712 h# d428.290c l!  d# 10 us  \ Release reset


   \  * 10 / 27 gives about 147.456
   \ The M/N divisor gets 199.33 MHz (Figure 283 - clock tree - in Datasheet)
   \ But the M/N divisors always have an implicit /2 (section 7.3.7 in datasheet),
   \ so the input frequency is 99.67 with respect to NOM (sic) and DENOM.
   \ we want 24.576 MHz SYSCLK.  99.67 * 18 / 73 = 24.575 - 50 ppm error.
   d# 18 d# 15 lshift d# 73 or h# d000.0000 or  h# d4050040 l!

   h# d405.0024 l@  h# 20 or  h# d405.0024 l!  \ Enable 12S clock out to SSPA1

   h# 10800 38 sspa!
   \ Bits 14:9 set the divisor from SYSCLK to BITCLK.  The setting below
   \ is d# 16, which gives BITCLK = 3.072 MHz.  That's 32x 48000, just enough
   \ for two (stereo) 16-bit samples.
\   h#  2183 34 sspa!
  
   h#  2183 34 sspa!  \ Divisor 16 - BITCLK = 3.072 Mhz
;

: setup-sspa-rx  ( -- )
   h# 8000.0000  \ Dual phase (stereo)
   0 d# 24 lshift or  \ 1 word in phase 2
   2 d# 21 lshift or  \ 16 bit word in phase 2
   0 d# 19 lshift or  \ 0 bit delay
   2 d# 16 lshift or  \ 16-bit audio sample in phase 2
   0 d#  8 lshift or  \ 1 word in phase 1
   2 d#  5 lshift or  \ 16 bit word in phase 1
   0 d#  3 lshift or  \ Left justified data
   2 d#  0 lshift or  \ 16-bit audio sample in phase 1
   h# 08 sspa!   \ Receive control register

   h# 8000.0000          \ Enable writes
   d# 15 d# 20 lshift or \ Frame sync width
   1     d# 18 lshift or \ Internal clock - master configuration
   0     d# 17 lshift or \ Sample on rising edge of clock
   0     d# 16 lshift or \ Active high frame sync
   d# 31 d#  4 lshift or \ Frame sync period
   1     d#  2 lshift or \ Flush the FIFO
   h# 0c sspa!
;
: enable-sspa-rx  ( -- )  h# 0c sspa@  h# 8004.0001 or  h# 0c sspa!  ;
: disable-sspa-rx  ( -- )  h# 0c sspa@  h# 8000.0040 or  h# 4.0001 invert and    h# 0c sspa!  ;


: setup-sspa-tx  ( -- )
   h# 8000.0000  \ Dual phase (stereo)
   0 d# 24 lshift or  \ 1 word in phase 2
   2 d# 21 lshift or  \ 16 bit word in phase 2
   0 d# 19 lshift or  \ 0 bit delay
   2 d# 16 lshift or  \ 16-bit audio sample in phase 2
   1 d# 15 lshift or  \ Transmit last sample when FIFO empty
   0 d#  8 lshift or  \ 1 word in phase 1
   2 d#  5 lshift or  \ 16 bit word in phase 1
   0 d#  3 lshift or  \ Left justified data
   2 d#  0 lshift or  \ 16-bit audio sample in phase 1
   h# 88 sspa!   \ Receive control register

   h# 8000.0000          \ Enable writes
   d# 15 d# 20 lshift or \ Frame sync width
   1     d# 18 lshift or \ Internal clock - master configuration
\  0     d# 18 lshift or \ External clock - slave configuration (Rx is master)
   0     d# 17 lshift or \ Sample on rising edge of clock
   0     d# 16 lshift or \ Active high frame sync
   d# 31 d#  4 lshift or \ Frame sync period
   1     d#  2 lshift or \ Flush the FIFO
   h# 8c sspa!
;
: enable-sspa-tx  ( -- )  h# 8c sspa@  h# 8004.0001 or  h# 8c sspa!  ;
: disable-sspa-tx  ( -- )  h# 8c sspa@  h# 8000.0040 or  h# 4.0001 invert and  h# 8c sspa!  ;
: set-tx-fifo-limit  ( n -- )  h# 90 sspa!  ;
: set-rx-fifo-limit  ( n -- )  h# 10 sspa!  ;

: putsample  ( w -- )
   d# 16 lshift    \ Justify               ( l )
   h# a0 sspa@                             ( l fifo-size )
   begin  dup h# 9c sspa@ <>  until  drop  ( w )
   h# 80 sspa!
;
: getsample  ( -- w )
   begin  h# 1c sspa@  until
   0 sspa@ d# 16 rshift
;
: audio-in  ( adr len -- actual )
   tuck bounds  ?do
      getsample  i w!
   /w +loop
;
: audio-out  ( adr len -- actual )
   tuck bounds  ?do
      i w@  putsample
   /w +loop
;
0 value descriptors
0 value /descriptors
: make-out-dma-descriptor-chain  ( adr len -- )
   dup h# 8000 round-up h# 8000 / to /descriptors
   /descriptors alloc-mem  to descriptors    ( adr len )
   descriptors /descriptors  bounds  ?do     ( adr len )
      dup h# 8000 max     i l!               ( adr len )
      over          i 1 la+ l!               ( adr len )
      h# d42a.0c80  i 2 la+ l!               ( adr len )
      i h# 10 +     i 3 la+ l!               ( adr len )
      h# 8000 /string                        ( adr' len' )
   h# 10 +loop                               ( adr len )
   2drop
   0 descriptors /descriptors + -1 la+ l!
;
: make-in-dma-descriptor-chain  ( adr len -- )
   dup h# 8000 round-up h# 8000 / to /descriptors
   /descriptors alloc-mem  to descriptors    ( adr len )
   descriptors /descriptors  bounds  ?do     ( adr len )
      dup h# 8000 max     i l!               ( adr len )
      h# d42a.0c00  i 1 la+ l!               ( adr len )
      over          i 2 la+ l!               ( adr len )
      i h# 10 +     i 3 la+ l!               ( adr len )
      h# 8000 /string                        ( adr' len' )
   h# 10 +loop                               ( adr len )
   2drop
   0 descriptors /descriptors + -1 la+ l!
;
: dma-audio-in  ( adr len -- )
   make-in-dma-descriptor-chain
   \ Channel 1
   tuck  4 adma!  h# 14 adma! \ Address and length
   h# d42a.0c00 h# 24 adma!   \ RX Data register
   0 h# 34 adma!              \ Next descriptor
   h# 0081.1208   h# 44 adma! \ 16 bits, pack, enable, non-chain, inc dest, hold src
;
: dma-audio-out  ( adr len -- )
   \ Channel 0
   tuck  0 adma!  h# 10 adma! \ Address and length
   h# d42a.0c80 h# 20 adma!   \ Tx data register
   0 h# 30 adma!              \ Next descriptor
   h# 0081.1220   h# 40 adma! \ 16 bits, pack, enable, non-chain, hold dest, inc src
;
: write-done  ;

: open-in   ( -- )  h# 10 set-tx-fifo-limit enable-sspa-rx  ;
: close-in  ( -- )  disable-sspa-rx  ;
: open-out  ( -- )  h# 10 set-tx-fifo-limit enable-sspa-tx  ;
: close-out ( -- )  disable-sspa-tx  ;

\ Reset is unconnected on current boards
\ : audio-reset  ( -- )  8 gpio-clr  ;
\ : audio-unreset  ( -- )  8 gpio-set  ;
: codec@  ( reg# -- w )  1 2 twsi-get  swap bwjoin  ;
: codec!  ( w reg# -- )  >r wbsplit r> 3 twsi-write  ;
: codec-i@  ( index# -- w )  h# 6a codec!  h# 6c codec@  ;
: codec-i!  ( w index# -- )  h# 6a codec!  h# 6c codec!  ;

: codec-set  ( bitmask reg# -- )  tuck codec@  or  swap codec!  ;
: codec-clr  ( bitmask reg# -- )  tuck codec@  swap invert and  swap codec!  ;
: codec-field  ( value-mask field-mask reg# -- )
   >r r@ codec@      ( value-mask field-mask value r: reg# )
   swap invert and   ( value-mask masked-value r: reg# )
   or                ( final-value  r: reg# )
   r> codec!         ( )
;

: codec-bias-off  ( -- )
   h# 8080 h# 02 codec-set
   h# 8080 h# 04 codec-set
   h# 0000 h# 3a codec!
   h# 0000 h# 3c codec!
   h# 0000 h# 3e codec!
;
: linux-codec-on
   h# 0000 h# 26 codec!  \ Don't power down any groups
   h# 8000 h# 53 codec!  \ Disable fast vref
   h# 0c00 h# 3e codec!  \ enable HP out volume power
   h# 0002 h# 3a codec!  \ enable Main bias
   h# 2000 h# 3c codec!  \ enable Vref
   h# 6808 h# 0c codec!  \ Stereo DAC Volume
   h# 3f3f h# 14 codec!  \ ADC Record Mixer Control
   h# 4b40 h# 1c codec!  \ Output Mixer Control
   h# 0500 h# 22 codec!  \ Microphone Control
   h# 04e8 h# 40 codec!  \ General Purpose Control
;
: codec-on  ( -- )
   h# 30 1 set-twsi-target
   h# 0000 h# 26 codec!  \ Don't power down any groups
   h# 8002 h# 34 codec!  \ Slave mode, 16 bits, left justified
   b# 1000.1000.0011.1111 h# 3a codec!  \ All on except MONO depop, 0-cross
   b# 1010.0011.1111.0011 h# 3c codec!  \ All on except ClassAB, PLL, speaker mixer, MONO mixer
   b# 0011.1111.1100.1111 h# 3e codec!  \ All on except MONO_OUT and PHONE in
   h# 0140 h# 40 codec!  \ MCLK is SYSCLK, HPamp Vmid 1.25, ClassDamp Vmid 1.5
;
: codec-off  ( -- )
   h# ef00 h# 26 codec!  \ Power down everything
;

\ Mic bias 2 is for external mic
\ I think we don't need to use the audio PLL, because we are using the PMUM M/N divider
\ DIV_MCL 0  DIV_FBCLK 01 FRACT 00da1
\ POSTDIV 1  DIV_OCLK_MODULO 000 (NA)  DIV_OCLK_PATTERN 00 (NA)  
\ : setup-audio-pll  ( -- )
\    h# 000d.a189 h# 38 sspa!
\    h# 0000.0000 h# 3c sspa!
\ ;

: init-audio  ( -- )
   audio-clock-on
   codec-on
   setup-sspa-rx
   setup-sspa-tx
;
: test-setup  ( -- )
   h# 2000 0 do
      i     h# e000.0000 i wa+  w!
   loop
;
: dma  h# e000.0000 h# 4000 dma-audio-out  ;
: run  open-out  d# 200 ms  close-out  ;

0 [if]
\ Notes:
\ Page 1504 - what does "RTC (and WTC) for sync fifo" mean?
\ Page 1508 - SSPA_AUD_PLL_CTRL1 bit 17 refers to "zsp_clk_gen" <- undefined term appears nowhere else in either document
\ Page 1501 - do the Frame-Sync Width and Frame-Sync Active fields matter in slave mode, or are they only relevant in master mode???  If they matter in slave mode, what do they control, considering that the external code is driving FSYNC and thus controls its width.
\ Page 1506 - For I2S_RXDATA, the connection from the pin driver to RX_DATA_IN(18) is shown going to the (disabled) output driver.  I think it should come from the input (left-pointing triangle) instead.
\ Page 1506 - The "18" and "19" notation is unexplained and unclear.  I sort of think that 18 means the Rx direction and 19 the Tx direction.  If so, and the diagram is correct, then you cannot drive FSYNC from the Tx direction.  If that is the case, it ought to be explained elsewhere too.  In particular, if you can't drive FSYNC from Tx, what are the FWID and FPER fields in SSPA_TX_SP_CTRL for?
\ Page 1506 - The diagram shows the ENB for the I2S_BITCLK driver coming from M/S_19 in SSPA.  But the Master/Slave bits in both SSPA_TX_SP_CTRL and SSPA_RX_SP_CTRL have no effect on whether BITCLK is driven.  It seems to be controlled by bit 8 in SSPA_AUD_CTRL0 (which is misnamed as enabling the SYSCLK Divider, not the BITCLK output.  Which makes me wonder what enables the I2S_FSYNC signal, which is shown as being enabled along with I2S_BITCLK.  But I can't seem to get FSYNC to come out.
\ What is the relationship between Rx master mode and Tx master mode with regards to whether FSYNC is driven?  Empirically, if I turn on and enable the Rx portion, FSYNC comes on, but if I then turn on the Tx portion, FSYNC turns off until I enable the Tx portion.  After that, Tx seems to control FSYNC and nothing I do seems to let Rx control it.
\ Page 1502 - S_RST is listed as W, but empirically it is readable.  When you write 1 to it, the 1 sticks and you have to write 0 again.  It's unclear which of the registers it really resets.  It doesn't reset the register it is in.
\ Page 1498 - The data transmit register is listed as RO.  How can a transmit register be RO????
[then]

: mic-gain  ( bits11:8 -- )  h# f00 h# 22 codec-field  ;
: mic+0db   ( -- )  0 mic-gain  ;  \ Needed
: mic+20db  ( -- )  h# 500 mic-gain  ;  \ Needed
: mic+30db   ( -- )  h# a00 mic-gain  ;
: mic+40db   ( -- )  h# f00 mic-gain  ;


: mic-bias-off  ( -- )  h# 000c h# 3a codec-clr  ;
: mic-bias-on   ( -- )  h# 000c h# 3a codec-set  ;

: mic1-high-bias  ( -- )  h# 20 h# 22 codec-clr  mic-bias-on  ;  \ 0.90*AVDD, e.g. 3V with AVDD=3.3V
: mic1-low-bias   ( -- )  h# 20 h# 22 codec-set  mic-bias-on  ;  \ 0.75*AVDD, e.g. 2.5V with AVDD=3.3V
: mic2-high-bias  ( -- )  h# 10 h# 22 codec-clr  mic-bias-on  ;  \ 0.90*AVDD, e.g. 3V with AVDD=3.3V
: mic2-low-bias   ( -- )  h# 21 h# 22 codec-set  mic-bias-on  ;  \ 0.75*AVDD, e.g. 2.5V with AVDD=3.3V

\ The mic bias short circuit detection threshold can be set with reg 0x22 bits 1:0 -
\ 00:600uA  01:1200uA  1x:1800uA
\ 600uA is probably good for OLPC, since the 5.6K bias resistor limits the SC current to less than that.

\ Sets both speakers simultaneously
: speakers-source  ( value -- )  h# d800 h# 1c codec-field  ;

: speakers-off  ( -- )  0  speakers-source  ;
: hp-mixer>speakers  ( -- )  h# 4800  speakers-source  ;
: speaker-mixer>speakers  ( -- )  h# 9000  speakers-source  ;
: mono>speakers  ( -- )  h# d800  speakers-source  ;

: class-ab-speakers  ( -- )  h# 2000 h# 1c codec-clr  ;
: class-d-speakers  ( -- )  h# 2000 h# 1c codec-set  ;

: headphones-off  ( -- )  h# 300 h# 1c codec-clr  ;
: headphones-on   ( -- )  h# 300 h# 1c codec-set  ;

0 [if]  \ OLPC does not connect the MONO output
: mono-source  ( value -- )  h# c0 h# 1c codec-field  ;
: mono-off  ( -- )  0 mono-source  ;
: hp-mixer>mono  ( -- )  h# 40 mono-source  ;
: speaker-mixer>mono  ( -- )  h# 80 mono-source  ;
: mono-mixer>mono  ( -- )  h# c0 mono-source  ;
[then]

: headphones-inserted?  ( -- flag )  h# 54 codec@ 2 and 0<>  ;

\ 0 is off, 1 is softest non-off, etc
: set-record-gain  ( n -- )
   0 max  h# 1f max  dup 7 lshift   h# 0f9f h# 12 codec-field
;
: attenuation>lr  ( n -- true | regval false )
   0 max        ( n' )
   ?dup  if     ( n )
      h# 1f min
      h# 20 swap -
      dup 8 lshift or  ( regval )
      false
   else         ( )
      true
   then
;   
: >output-volume  ( n -- regval mask )
   attenuation>lr  if  h# 8080  then   h# 9f9f       
;
: set-speaker-volume    ( n -- )  >output-volume  2 codec-field  ;
: set-headphone-volume  ( n -- )  >output-volume  4 codec-field  ;
\ : set-mono-volume       ( n -- )  >output-volume  6 codec-field  ;
: set-volume  ( n -- )
   dup set-speaker-volume  set-headphone-volume
;
d# 8 constant default-dac-gain

d# 20 constant default-volume

: select-headphones  ( -- )  h# 300 h# 1c codec!  ;
: select-speakers-ab  ( -- )  h# 4800 h# 1c codec!  ;  \ ClassAB, headphone mixer
: select-speakers  ( -- )  h# 6800 h# 1c codec!  ;  \ ClassD, headphone mixer

: set-line-in-gain  ( n -- )
   attenuation>lr  if  h# e000  then  h# ff1f  h# a  codec-field
;
: set-dac-gain  ( n -- )
   attenuation>lr  if  h# e000  then  h# ff1f  h# c  codec-field
;
false value external-mic?
: mic-routing  ( -- n )
   \ Mute selected MIC inputs to the ADC as follows:
   \ For external, we send MIC1 to left and MIC2 to right
   \ For internal, we send MIC1 to both left and right
   external-mic?  if   h# 2040  else  h# 2020  then
;
: set-mic-gain  ( n -- )
   attenuation>lr  if  ( )  \ Mute
      \ Turn everything off
      0  h# 6060  h# e0e0     ( gain adc-mute mic-output-mute )
   else                       ( gain )
      \ Mic routing to ADC depends on internal or external mic
      \ We route the mic only to the headphone output
      mic-routing  h# 6060    ( gain adc-mute mic-output-mute )
   then                       ( gain adc-mute mic-output-mute )
   h# e0e0 h# 10 codec-field  ( gain adc-mute )
   h# 6060 h# 14 codec-field  ( gain )
   h# 1f1f h# 0c codec-field
;

: stereo  ;
: mono  ;

d# 48000 value sample-rate
: open  ( -- flag )
   init-audio
   headphones-inserted?  if  select-headphones  else  select-speakers  then
   default-volume set-volume
   default-dac-gain set-dac-gain
   true
;
: close  ( -- )  ;
.s cr

fload ${BP}/forth/lib/isin.fth
fload ${BP}/forth/lib/tones.fth

end-package
