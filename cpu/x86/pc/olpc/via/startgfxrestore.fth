\ Restore PCI config registers

d000.0000 810 config-wl  \ Frame buffer base address
f000.0000 814 config-wl  \ Graphics engine base address
     0007 804 config-ww  \ Enables
       20 80d config-wb  \ Latency timer

\ Clock DCON SMBUS in case it is stuck in the middle of an address
\ recognition sequence.

long-offsets @  long-offsets off
31 26 seq-set
4 wait-us
d# 32 # cx mov
begin
   20 26 seq-clr
   4 wait-us
   20 26 seq-set
   4 wait-us
loopa
long-offsets !

\ DCON GPIO pin muxing
d# 17 0 devfunc
   e3 04 04 mreg \ Use multifunction pin as GPIO8
   e4 48 48 mreg \ Use multifunction pins as GPO10 and GPI10/11
end-table

long-offsets @ long-offsets on
native-mode# #  video-mode-adr #)  cmp  =  if

\ olpc-lcd-mode

c0 1b seq-set  \ Secondary engine clock (LCK) can be gated on or off

80 17 crt-clr  \ Assert reset while programming geometry

crtc-table
   30 36 ireg  \ Turn off primary DAC to save power

   d7 50 ireg  \ Htotal low
   af 51 ireg  \ Hdisplay low
   af 52 ireg  \ Hblank low
   d7 53 ireg  \ Hblankend
   24 54 ireg  \ Hblank, Hblankend overflow
   44 55 ireg  \ Htotal and hdisplay overflow
   \   b7 56 ireg  \ Hsync low
   b5 56 ireg  \ Hsync low
   bd 57 ireg  \ Hsyncend low
   8f 58 ireg  \ Vtotal low
   83 59 ireg  \ Vdisplay low
   83 5a ireg  \ Vblank low
   8f 5b ireg  \ Vblankend low
   9b 5c ireg  \ Hsync,Hsyncend,Vblank,Vblankend overflow
   1b 5d ireg  \ Hblankend, Hsync, Vtotal, Vdisplay overflow
   88 5e ireg  \ Vsync low
   6a 5f ireg  \ Vsyncend all and Vsync overflow
      
   00 62 ireg  \ Starting address
   00 63 ireg  \ Starting address
   00 64 ireg  \ Starting address

   96 65 ireg  \ Fetch count (67 overflow already set above)
   2c 66 ireg  \ Offset (frame buffer pitch) low (67 overflow already set above)
   51 67 ireg  \ Color depth - 16bpp ([7:6] = 10) - no interlace ([5] = 0), various overflow bits
   f0 68 ireg  \ Display queue depth
   c8 6a ireg  \ Enable secondary display
   00 6b ireg  \ Disable simultaneous display, IGA2 on, IGA2 screen enable not slaved to IGA1

   00 6c ireg  \ VCK source from PLL output clock, LCKCK PLL source from X1 pin

   00 71 ireg  \ Offset overflow
   00 79 ireg  \ LCD scaling off
  
   60 88 ireg  \ LVDS sequential
   01 8a ireg  \ LCD adjust LP
   08 94 ireg  \ Expire number
   11 95 ireg  \ extension bits
   10 97 ireg  \ LVDS channel 2 - secondary display
   1b 9b ireg  \ DVP mode - alpha:80, VSYNC:40, HSYNC:20, secondary:10, clk polarity:8, clk adjust:7
   00 a3 ireg  \ IGA2 frame buffer is system local memory, address bits [28:26] are 0
   8b a7 ireg  \ expected vertical display low
   01 a8 ireg  \ expected vertical display high

   80 f3 ireg  \ 18-bit TTL LCD
   0a f9 ireg  \ V1 power mode exit delay
   0d fb ireg  \ IGA2 Interlace VSYNC timing
end-table

\ general-init
01 1e seq-set  \ ROC ECK
seq-table
   00 20 ireg  \ max queuing number (but manual recommends 4)
   14 22 ireg  \ (display queue request expire number)
   40 34 ireg  \ not documented
   01 3b ireg  \ not documented
   38 40 ireg  \ ECK freq
   30 4d ireg  \ preempt arbiter
end-table

crtc-table
   08 30 ireg  \ DAC speed enhancement
   01 3b ireg  \ Scratch 2
   08 3c ireg  \ Scratch 3
   c0 f7 ireg  \ Spread spectrum
   01 32 ireg  \ real time flipping (I think we can ignore this)
end-table

\ legacy-settings
seq-table
   00 00 ireg  \ Reset sequencer
   01 01 ireg  \ 8/9 timing
   0f 02 ireg  \ Enable map planes
   00 03 ireg  \ Character map select
   06 04 ireg  \ Extended memory present
   03 00 ireg  \ Release reset bits
   00 0a ireg  \ Cursor start
   00 0b ireg  \ Cursor end
   00 0e ireg  \ Cursor loc
   00 0f ireg  \ Cursor loc
end-table

crtc-table
   00 11 ireg  \ Refreshes per line, disable vert intr
   23 17 ireg  \ address wrap, sequential access, not CGA compat mode
end-table

\ tune-fifos
seq-table
   60 16 ireg  \ FIFO threshold
   1f 17 ireg  \ FIFO depth (VX855 value)
   4e 18 ireg  \ Display Arbiter (VX855 value)

   18 21 ireg  \ (typical request track FIFO number channel 0
   1f 50 ireg  \ FIFO
   81 51 ireg  \ FIFO - 81 enable Northbridge FIFO
   00 57 ireg  \ FIFO
   08 58 ireg  \ Display FIFO low threshold select
   20 66 ireg  \ request kill
   20 67 ireg  \ request kill
   20 69 ireg  \ request kill
   20 70 ireg  \ request kill
   0f 72 ireg  \ FIFO
   08 79 ireg  \ request kill
   10 7a ireg  \ request kill
   c8 7c ireg  \ request kill
end-table

\ lower-power
seq-table
   7f 19 ireg  \ clock gating
   f0 1b ireg  \ clock gating
   ff 2d ireg  \ Power control enables
   ff 2e ireg  \ clock gating
   ff 3f ireg  \ clock gating
   5f 4f ireg  \ clock gating threshold
   df 59 ireg  \ clock gating
   00 a8 ireg  \ leave on ROC ECK in C0
   00 a9 ireg  \ leave on ROC ECK in C1
   80 aa ireg  \ gate off ROC ECK in C4
   80 ab ireg  \ gate off ROC ECK in C3
   00 ac ireg  \ leave on ROC ECK in S3
   00 ad ireg  \ leave on ROC ECK in S1 Snapshot
   00 ae ireg  \ leave on ROC ECK in C4P
   00 af ireg  \ leave on ROC ECK in reserved state
end-table

crtc-table
   01 36 ireg  \ Enable PCI power management control
   34 37 ireg  \ DAC power savings
end-table

\ end of lower-power

seq-table
   9f 4a ireg  \ 2nd PLL value 0
   0c 4b ireg  \ 2nd PLL value 1
   05 4c ireg  \ 2nd PLL value 2
   04 40 ireg  \ Pulse LCDCK PLL reset
   00 40 ireg  \ Release LCDCK PLL reset
end-table

3cc port-rb  0c bitset  3c2 # dx mov  al dx out  \ use external clock (MISC register reads at 3cc, writes at 3c2)

80 17 crt-set  \ Release reset

60 78 seq-set  \ Inverse HSYNC and VSYNC on IGA2 for LVDS
30 1e seq-set  \ Power up DVP1 pads
0c 2a seq-set  \ Power up LVDS pads
30 1b seq-set  \ Turn off primary engine clock to save power
   
d# 32000 wait-us
\ Wait for DCON_BLNK to be low
d# 100 # cx mov
begin
   acpi-io-base 4a + port-rb
   4 # al and
0<> while
   d# 1000 wait-us
   cx dec
0= until  then  \ "then" resolves "while"

\ This is a cheesy way to set the DCON LOAD bit --
ff acpi-io-base 4d + port-wb  \ B1 and B2 - DCON LOAD is the 0x04 bit (bit number 2) of PMIO+4d
ff acpi-io-base 4f + port-wb  \ A1 and A2 - DCON LOAD is the 0x10 bit (bit number 4) of PMIO+4f
d# 19000 wait-us

then
long-offsets !
