\ We don't need this because OFW already does it
0 [if]
: setup-i8259  ( -- )
   h# 11 h# 20 pc!		\ initialization sequence to 8259A-1*/
   h# 11 h# A0 pc!		\ and to 8259A-2
   h# 20 h# 21 pc!		\ start of hardware int's (0x20)
   h# 28 h# A1 pc!		\ start of hardware int's 2 (0x28)
   h# 04 h# 21 pc!		\ 8259-1 is master
   h# 02 h# A1 pc!		\ 8259-2 is slave
   h# 01 h# 21 pc!		\ 8086 mode for both
   h# 01 h# A1 pc!		
   h# FF h# A1 pc!		\ mask off all interrupts for now
   h# FB h# 21 pc!		\ mask all irq's but irq2 which is cascaded
;
[then]

: irq-init
   h# 20 h# 4d0 pc!   \ IRQ5 (AC-97) level triggered
   h# 0c h# 4d1 pc!   \ IRQA (USB) and IRQB (GXFB) level triggered
;

: msr:  ( -- )
   push-hex
   safe-parse-word $dnumber? 1 <> abort" MSR number must be single precision"
   ,
   safe-parse-word $dnumber? 2 <> abort" MSR value must be double precision"
   , ,
   pop-base
;

fload ${BP}/cpu/x86/pc/olpc/gxmsrs.fth
fload ${BP}/cpu/x86/pc/olpc/lxmsrs.fth

: msr-init-range  ( -- adr len )
   lx?  if
      lx-msr-init /lx-msr-init
   else
      gx-msr-init /gx-msr-init
   then
;
: find-msr-entry  ( msr# -- 'data )
   msr-init-range  bounds  ?do      ( msr# )
      dup i l@ =  if                ( msr# )
         drop  i la1+  unloop exit
      then                          ( msr# )
   3 /l* +loop                      ( msr# )
   drop true abort" No MSR entry"
;

: init-msr  ( adr -- )  dup la1+ 2@  rot @  wrmsr  ;

: set-msrs  ( -- )
   msr-init-range bounds  ?do  i init-msr  d# 12 +loop
;

code msr-slam  ( adr len -- )
   bx pop
   dx pop
   dx bx add  \ endaddr
   bp push    \ save
   dx bp mov  \ Use BP as pointer

   begin
      0 [bp]  cx  mov   \ msr#
      4 [bp]  dx  mov   \ msr.hi
      8 [bp]  ax  mov   \ msr.lo
      h# 0f asm8,  h# 30 asm8,   \ wrmsr
      d# 12 #  bp  add
      bp bx cmp
   = until

   bp pop
c;

: map-v=p  ( phys size -- )
   2dup 0  mmu-claim drop   ( phys size )
   over swap  -1  mmu-map   ( )
;

: video-map
[ifdef] virtual-mode
   \ Map GP+DC+VP all at once with a large size
   gp-pci-base h# c000 map-v=p
[then]

   \ Unlock the display controller registers
\ write_vg_32(DC_UNLOCK, DC_UNLOCK_VALUE);
   h# 4758 dc-pci-base 0 + l!

\ Set up the DV Address offset in the DC_DV_CTL register to the offset from frame 
\ buffer descriptor.  First, get the frame buffer descriptor so we can set the 
\ DV Address Offset in the DV_CTL register.  Because this is a pointer to real
\ silicon memory, we don't need to do this whenever we change the framebuffer BAR,
\ so it isn't included in the hw_fb_map_init routine.
\ SYS_MBUS_DESCRIPTOR((unsigned short)(vga_config_addr+BAR0),(void *)&mVal);
\ mVal.high &= DESC_OFFSET_MASK;
\ mVal.high <<= 4;
\ mVal.high += framebuffer_base;	// Watch for overflow issues here...
\ write_vg_32(DC_DV_CTL, mVal.high);

   \ The base address of the frame buffer in physical memory
   fb-offset  h# 88 dc-pci-base + l!   \ DV_CTL register, undocumented

\ hw_fb_map_init(PCI_FB_BASE);
\ Initialize the frame buffer base related stuff.

   fb-pci-base h#  84 dc-pci-base + l!   \ GLIU0 Memory offset
   fb-pci-base h#  4c gp-pci-base + l!   \ GP base
   fb-pci-base h# 80.0000 + h# 460 vp-pci-base + l!   \ Flat panel base (reserved on LX)

   \ VGdata.hw_vga_base = h# fd7.c000
   \ VGdata.hw_cursor_base = h# fd7.bc00
   \ VGdata.hw_icon_base = h# fd7.bc00 - MAX_ICON;
[ifdef] virtual-mode
   gp-pci-base h# c000  mmu-unmap
[then]
;

: acpi-init
\ !!! 16-bit writes to these registers don't work - 5536 erratum
   0 h# 1840 pl!   \ Disable power button during early startup
;
: setup  
   set-msrs
\   fix-sirq
   gpio-init
   acpi-init
   irq-init
;
