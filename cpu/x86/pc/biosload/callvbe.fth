\ Call VESA BIOS from a syslinux-loaded ".c32" image
\ COM32 arguments are at 0 @ 4 +

code vesa-mode  ( mode# -- )
   cx pop

   si push  di push  bp push
   0 #)  ax mov  \ Pointer to COM32 args
   d# 16 [ax]  bx  mov  \ COM32 intcall helper function
   d# 20 [ax]  dx  mov  \ bounce buffer address

   h# 4f02 #  d# 36 [dx]  mov  \ AX
   cx      d# 24 [dx]  mov  \ BX

   dx push
\   0 # push
   dx push
   h# 10 # push

   bx call
   ax pop  ax pop  ax pop

   bp pop  di pop  si pop
c;

: +c32-regs  ( offset -- adr )  0 @  d# 20 + @  +  ;
: 'c32-gs  ( -- adr )  0 +c32-regs  ;
: 'c32-fs  ( -- adr )  2 +c32-regs  ;
: 'c32-es  ( -- adr )  4 +c32-regs  ;
: 'c32-ds  ( -- adr )  6 +c32-regs  ;

: 'c32-di  ( -- adr )  d#  8 +c32-regs  ;
: 'c32-si  ( -- adr )  d# 12 +c32-regs  ;
: 'c32-bp  ( -- adr )  d# 16 +c32-regs  ;
: 'c32-bx  ( -- adr )  d# 24 +c32-regs  ;
: 'c32-dx  ( -- adr )  d# 28 +c32-regs  ;
: 'c32-cx  ( -- adr )  d# 32 +c32-regs  ;
: 'c32-ax  ( -- adr )  d# 36 +c32-regs  ;
: 'c32-eflags  ( -- adr )  d# 40 +c32-regs  ;

code c32-intcall  ( int# -- )
   cx pop

   si push  di push  bp push
   0 #)  ax mov  \ Pointer to COM32 args
   d# 16 [ax]  bx  mov  \ COM32 intcall helper function
   d# 20 [ax]  dx  mov  \ bounce buffer address

   dx push
\   0 # push
   dx push
   cx push   \ Int#

   bx call
   ax pop  ax pop  ax pop

   bp pop  di pop  si pop
c;

: vbe-call  ( function# -- )
  'c32-ax l!  h# 10 c32-intcall
  'c32-ax l@  h# 4f <>  abort" VESA BIOS call failed"
;

: c32-es:di!  ( adr -- )  >seg:off  'c32-es w!  'c32-di w!  ;
: vbe-info  ( -- adr )
   h# 200 +c32-regs    ( adr )
   h# 32454256 over l! ( adr )
   c32-es:di!
   h# 4f00 vbe-call
   h# 200 +c32-regs      ( adr )
;   
: vesa-mode-info  ( mode# -- adr )
   'c32-cx l!                   ( )
   h# 200 +c32-regs c32-es:di!  ( )
   h# 4f01 vbe-call             ( )
   h# 200 +c32-regs             ( adr )
;
: .vesa-mode-info  ( mode# -- )
   push-hex  dup 3 u.r space
   vesa-mode-info >r  ( r: adr )
   decimal
   r@ h# 12 + w@ (.) type
   ." x" r@ h# 14 + w@ (.) type
   ." x" r@ h# 19 + c@ (.) type cr
   r> drop
   pop-base
;
: .vesa-mode-list  ( -- )
   vbe-info                     ( adr )
   dup l@  h# 41534556 <>  if   ( adr )
      ." VBE info call failed" cr
      drop exit
   then                         ( adr )
   dup 6 + seg:off@  .cstr cr   ( adr )
   d# 14 + seg:off@             ( 'mode-list )
   begin  dup w@ dup h# ffff <>  while  .  wa1+  repeat  cr  2drop
;

: #vesa-modes  ( 'mode-list -- n )
   0   begin   over w@ dup h# ffff <>  while     ( 'mode-list n mode# )
      drop  swap wa1+ swap  1+                   ( 'mode-list n' )
   repeat                                        ( 'mode-list n mode# )
   drop nip                                      ( n )
;
: .vesa-modes  ( -- )
   vbe-info                     ( adr )
   dup l@  h# 41534556 <>  if   ( adr )
      ." VBE info call failed" cr
      drop exit
   then                         ( adr )
   dup 6 + seg:off@  .cstr cr   ( adr )
   d# 14 + seg:off@             ( 'mode-list )
   dup #vesa-modes 1+           ( 'mode-list #modes )
   /w* dup alloc-mem            ( 'mode-list modes-len adr )
   dup >r swap move r>          ( adr )
   begin  dup w@ dup h# ffff <>  while  .vesa-mode-info  wa1+  repeat  cr  2drop
;

[ifdef] Commentary
00.w mode attributes
02.b wina attributes
03.b winb attributes
04.w winGranularity
06.w WinSize
08.w WinASegment
0a.w WinBSegment
0c.l WinFuncPtr
10.w BytesPerScanLine
12.w XResolution
14.w YResolution
16.b XCharSize
17.b YCharSize
18.b NumberOfPlanes
19.b BitsPerPixel
1a.b NumberOfBanks
1b.b MemoryModel
1c.b BankSize
1d.b NumberOfImagePlanes
1e.b Reserved
1f.b RedMaskSize
20.b RedFieldPosition
21.b GreenMaskSize
22.b GreenFieldPosition
23.b BlueMaskSize
24.b BlueFieldPosition
25.b RsvdMaskSize
26.b RsvdFieldPosition
27.b DirectColorModeInfo
\ Following are VBE 2.0 and above
28.l PhysBasePtr
2c.l Reserved
30.w Reserved
\ Following are VBE 3.0 and above
32.w LinBytesPerScanLine
34.b BnkNumberOfImagePages
35.b LinNumberOfImagePages
36.b LinRedMaskSize
37.b LinRedFieldPosition
38.b LinGreenMaskSize
39.b LinGreenFieldPosition
3a.b LinBlueMaskSize
3b.b LinBlueFieldPosition
3c.b LinRsvdMaskSize
3d.b LinRsvdFieldPosition
3e.l MaxPixelClock 
[then]

: current-vesa-mode  ( -- mode# )  h# 4f03 vbe-call  'c32-bx l@  ;
: set-vesa-mode  ( mode# -- )   'c32-bx w!  h# 4f02 vbe-call  ;
: set-linear-mode  ( mode# -- )  h# 4000 or  set-vesa-mode  ;
: vesa-lfb-adr  ( mode# -- padr )  h# 4000 or vesa-mode-info h# 28 + l@  ;
