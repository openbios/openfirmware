h# 100 value /regs   \ Standard size of SDHCI register block
1 value #slots

0 instance value slot
0 instance value chip

: phys+ encode-phys encode+  ;
: i+  encode-int encode+  ;

: make-reg  ( -- )
   0 0 encode-bytes
   0 0 h# 0000.0000  my-space +  phys+   0 i+  h# 0000.0100 i+   \ Config registers

   my-space " config-l@" $call-parent h# 410111ab =  if  \ Marvell CaFe chip
      h# 4000 to /regs
   then

   h# 40 my-space + " config-b@" $call-parent  ( slot_info )
   4 rshift 7 and  1+ dup to #slots            ( #slots )
   0  ?do
      0 0 h# 0100.0010  i 4 * +  my-space +  phys+   0 i+   /regs i+   \ Operational regs for slot N
   loop
   " reg" property
;
make-reg

: my-w@  ( offset -- w )  my-space + " config-w@" $call-parent  ;
: my-w!  ( w offset -- )  my-space + " config-w!" $call-parent  ;

: map-regs  ( -- )
   chip  if  exit  then
   0 0 h# 0200.0010 slot 1- 4 * + my-space +  /regs " map-in" $call-parent
   to chip
   h# 16 4 my-w!  \ Memory write and invalidate, bus mastering, memory
;
: unmap-regs  ( -- )
   chip  0=  if  exit  then
\  0 4 my-w!
   chip  /regs  " map-out" $call-parent
   0 to chip
;

: marvell?  ( -- flag )  0 my-w@ h# 11ab =  ;
: vendor-modes  ( -- )
   marvell?  if  \ Marvel CaFe chip
      \ One-time initialization of Marvell CaFe SD interface.
      \ Marvell told us to do this once after reset.
      \ The sw-reset command resets the registers, so you have
      \ to do it after that, in addition to after power-up.
      h# 0004 h# 6a chip + rw!  \ Enable data CRC check
      h# 7fff h# 60 chip + rw!  \ Disable internal pull-up/down on DATA3
   then
;

\ Some Marvell-specific stuff
: enable-sd-int  ( -- )
   h# 300c chip + rl@  h# 8000.0002 or  h# 300c chip + rl!
;
: disable-sd-int  ( -- )
   h# 300c chip + rl@  2 invert and  h# 300c chip + rl!
;
: enable-sd-clk  ( -- )
   h# 3004 chip + rw@  h# 2000 or  h# 3004 chip + rw!
;
: disable-sd-clk  ( -- )
   h# 3004 chip + rw@  h# 2000 invert and  h# 3004 chip + rw!
;

: ?cafe-fpga-quirk  ( -- )
   marvell?  if
      \ OLPC-specific hack: fast clock doesn't work on the FPGA CaFe chip
      " board-revision" evaluate h# b20 <  if  drop h# 103  then
   then
;

: ?via-quirk  ( -- )
   \ This is a workaround for an odd problem with the Via Vx855 chip.
   \ You have to tell it to use 1.8 V, otherwise when you tell it
   \ it to use 3.3V, it will use 1.8 V instead!  You only have to
   \ do this 1.8V thing once after power-up to fix it until the
   \ next power cycle.  The "fix" survives resets; it takes a power
   \ cycle to break it again.

   my-space " config-l@" $call-parent h# 95d01106 =  if  h# 0a h# 29 chip + rb!  then
;
