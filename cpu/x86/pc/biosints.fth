purpose: Emulate legacy PC BIOS real-mode INTs
\ See license at end of file

/rm-regs buffer: init-regs
h# 80 value bios-boot-dev#

: rm-es@  caller-regs >rm-es w@  ;
: rm-es!  caller-regs >rm-es w!  ;

: rm-ds@  caller-regs >rm-ds w@  ;
: rm-ds!  caller-regs >rm-ds w!  ;

: rm-ah@  caller-regs >rm-eax 1+ c@  ;
: rm-ah!  caller-regs >rm-eax 1+ c!  ;
: rm-al@  caller-regs >rm-eax c@  ;
: rm-al!  caller-regs >rm-eax c!  ;
: rm-ax@  caller-regs >rm-eax w@  ;
: rm-ax!  caller-regs >rm-eax w!  ;
: rm-eax@  caller-regs >rm-eax l@  ;
: rm-eax!  caller-regs >rm-eax l!  ;

: rm-bh@  caller-regs >rm-ebx 1+ c@  ;
: rm-bh!  caller-regs >rm-ebx 1+ c!  ;
: rm-bl@  caller-regs >rm-ebx c@  ;
: rm-bl!  caller-regs >rm-ebx c!  ;
: rm-bx@  caller-regs >rm-ebx w@  ;
: rm-bx!  caller-regs >rm-ebx w!  ;

: rm-ch@  caller-regs >rm-ecx 1+ c@  ;
: rm-ch!  caller-regs >rm-ecx 1+ c!  ;
: rm-cl@  caller-regs >rm-ecx c@  ;
: rm-cl!  caller-regs >rm-ecx c!  ;
: rm-cx@  caller-regs >rm-ecx w@  ;
: rm-cx!  caller-regs >rm-ecx w!  ;

: rm-dh@  caller-regs >rm-edx 1+ c@  ;
: rm-dh!  caller-regs >rm-edx 1+ c!  ;
: rm-dl@  caller-regs >rm-edx c@  ;
: rm-dl!  caller-regs >rm-edx c!  ;
: rm-dx@  caller-regs >rm-edx w@  ;
: rm-dx!  caller-regs >rm-edx w!  ;

: rm-edx@  caller-regs >rm-edx l@  ;
: rm-edx!  caller-regs >rm-edx l!  ;

: rm-ebx@  caller-regs >rm-ebx l@  ;
: rm-ebx!  caller-regs >rm-ebx l!  ;

: rm-ebp@  caller-regs >rm-ebp l@  ;
: rm-ebp!  caller-regs >rm-ebp l!  ;

: rm-ecx@  caller-regs >rm-ecx l@  ;
: rm-ecx!  caller-regs >rm-ecx l!  ;

: rm-edi@  caller-regs >rm-edi l@  ;
: rm-edi!  caller-regs >rm-edi l!  ;

: rm-esi@  caller-regs >rm-esi l@  ;
: rm-esi!  caller-regs >rm-esi l!  ;

: rm-si@  caller-regs >rm-esi w@  ;

[ifdef] >rm-retaddr
: rm-retaddr@  caller-regs >rm-retaddr seg:off@  ;
[then]
[ifdef] >rm-eip
\ : rm-retaddr@  caller-regs >rm-eip @  ;
: rm-caller-sp  caller-regs >rm-esp @  caller-regs >rm-ss w@  seg:off>  ;
: rm-retaddr@  rm-caller-sp seg:off@  ;
: .rm-stack  rm-caller-sp h# 40 wdump  ;
[then]

[ifdef] >rm-flags
: rm-flags@  caller-regs >rm-flags w@  ;
: rm-flags!  caller-regs >rm-flags w!  ;
[then]
[ifdef] >rm-eflags
: rm-flags@  caller-regs >rm-eflags @  ;
: rm-flags!  caller-regs >rm-eflags !  ;
[then]

: rm-set-cf  rm-flags@  1 or  rm-flags!  ;
: rm-clr-cf  rm-flags@  1 invert and  rm-flags!  ;

true value show-rm-int?
: noshow  false to show-rm-int?  ;
: noshow!  false to show-rm-int?  ;
variable save-eax
: snap-int
   true to show-rm-int?  rm-eax@ save-eax !
;
: showint
  ." INT " rm-int@ .  save-eax @ wbsplit ." AH " .  ." AL " .
  ." from " rm-retaddr@ . cr
;
: ?showint  show-rm-int?  if  showint  then  ;

: !font  ( adr -- )
   >seg:off  rm-es!  rm-ebp!
   h# 10 rm-cx!  h# 18 rm-dx!     
;
: get-font  ( -- )
   noshow
   rm-al@ h# 30 =  if
\      ." Int 10 get-font called - BH = " rm-bh@ .  cr
      rm-bh@ case
\ These numbers are cheats, pointing into the VIA BIOS
         2 of  h# c69e0 !font   endof
         3 of  h# c6138 !font   endof
         4 of  h# c6538 !font   endof
         5 of  h# c69e0 !font   endof
         6 of  h# c77e0 !font   endof
         7 of  h# c77e0 !font   
\ Not sure why I did the ungrab thing
\ h# 10 ungrab-rm-vector
\ h# 15 ungrab-rm-vector
         endof
         ( default )  ." Unsupported get font - BH = " dup . cr  rm-set-cf
      endcase
   else
      ." Int 10 set-font called"  cr
   then
;

: set-mode3  ( -- )
   text-off  \ Stop using OFW screen output
[ifdef] smi-access-fb  smi-access-fb  [then]
   " text-mode3" screen-ih $call-method
[ifdef] smi-unaccess-fb  smi-unaccess-fb  [then]
;
\ VBE status: AL = 4f -> function supported  else not supported
\ AH = 0: success  1: fail  2: not supported in this config  3: invalid in this mode
\ Mode: D[0:8] mode - bit 8=1 for VESA modes
\   D11 -  (800) 0: BIOS default refresh rate  1: User CRTC values for refresh
\   D14 - (4000) 0: Banked frame buffer        1: Linear frame buffer
\   D15 - (8000) 0: Clear display memory       1: Don't clear

create vbe-info
   " VESA" here swap move  4 allot
   h# 0300 w,
   1 l,
here vbe-info - constant /vbe-info

\ This returns a 32-bit logical (virtual) address.  It needs
\ to be converted to physical before accessing data, but the
\ virtual version is also needed for things like relocating
\ pointers embedded within the data.

: vbebuf  ( -- ladr )  caller-regs >rm-edi w@  rm-es@ seg:off>  ;
: >vbe-pa  ( offset -- padr )  vbebuf + >caller-physical  ;
: vbedata  ( -- ladr )  vbebuf h# 100 +  ;

: ?vbe2  ( -- )
   0 >vbe-pa l@ h# 32454256 <>  if
      ." Old-style VESA BIOS call not supported" cr
      interact
   then
;

\ oem-adr is the logical address in the OEM buffer area
\ $ is the data to move into the OEM buffer
\ vbe-offset is the location within the VESA struct for the far pointer
\ Mode.w
\ WinAAttrs.b  WinBAttrs.b  WinGranularity.w  WinSize.w
\ WinASegment.w  WinBSegment.w  WinFunctPtr.l
\ BytesPerScanLine.w

\ Xres.w (pix or chr)
\ Yres.w (pix or chr)
\ Xcharsize.b (pixels)
\ Ycharsize.b (pixels)
\ NumPlanes.b
\ BPP.b
\ NumBanks.b
\ MemModel.b
\ BankSize.b (KiB)
\ NumImagePages.b
\ Res.b  1

\ RedMaskSize.b   RedFieldPos.b   GrnMaskSize.b   GrnFieldPos.b
\ BlueMaskSize.b  BlueFieldPos.b  RsvdMaskSize.b  RsvdFieldPos.b
\ DirectColorModeInfo.b

\ PhysBasePtr.l   Res.l 0   Res.w 0

\ LinBytesPerScanLine.w
\ BnkNumImagePages.b
\ LinNumImagePages.b
\ LinRedMaskSize.b   LinRedFieldPos.b   LinGrnMaskSize.b   LinGrnFieldPos.b
\ LinBlueMaskSize.b  LinBlueFieldPos.b  LinRsvdMaskSize.b  LinRsvdFieldPos.b
\ MaxPixelClock.d
\ 189 reserved

create mode3-info \ w b b w w w w d w   w w b b b b b b b b b 
   h#  b w,  \ Windowed, (VGA), (Text), Color, no TTY Output, D1=1, hardware-supported
     
create mode12-info \ w b b w w w w d w   w w b b b b b b b b b 
   h# db w,  \ Linear, (VGA), Graphics, Color, no TTY Output, D1=1, hardware-supported

create mode-112-info
\   h# bf w,    \ Linear, VGA, Graphics, Color, TTY Output, D1=1, hardware-supported
\   7 c,  0 c,  d# 64 w,  d# 64 w,  h# a000 w,  0 w,  0 l,  \ Not windowed
   h# fb w,    \ Linear, noVGA, Graphics, Color, noTTY Output, D1=1, hardware-supported
   0 c,  0 c,  d# 0 w,  d# 0 w,  0 w,  0 w,  0 l,  \ Not windowed
   d#  640 /l* w,         \ BytesPerScanLine
   d#  640 w,  d# 480 w,  \ X, Y res
   d#    8 c,  d#  16 c,  \ Char width, height
   1 c,        \ NumPlanes
   d# 32 c,    \ Bits/pixel
   1 c,        \ NumBanks
   6 c,        \ MemModel - DirectColor
   0 c,        \ Bank size (not banked)
   2 c,        \ NumImagePages
   1 c,        \ Reserved

   \ Banked Color info
   8 c, d# 16 c,    8 c, 8 c,   8 c,  0 c,   0 c,  0 c,  \ {RGBX}{Bits,Pos}
   0 c,        \ Gamma fixed (change if we implement function 9)

   fb-pci-base l,  0 l,  0 w,   \ Framebuffer address

   \ Linear info
   d# 640 /l* w,     \ Bytes per scan line
   0 c,              \ No banks
   
\  fbsize  d# 640 /  d# 480 /  4 /  c,  ( need to account for cmd buffer )
   d# 11 c,          \ Number of images that will fit in framebuffer

   8 c, d# 16 c,   8 c, 8 c,   8 c,  0 c,   0 c,  0 c,  \ {RGBX}{Bits,Pos}

   d# 56,200,000 l,  \ Max pixel clock
here mode-112-info -  constant /mode-112-info

create mode-115-info
   h# fb w,    \ Linear, VGA, Graphics, Color, TTY Output, D1=1, hardware-supported
   0 c,  0 c,  d# 0 w,  d# 0 w,  h# 0 w,  0 w,  0 l,  \ Not windowed
   d#  800 /l* w,         \ BytesPerScanLine
   d#  800 w,  d# 600 w,  \ X, Y res
   d#    8 c,  d#  16 c,  \ Char width, height
   1 c,        \ NumPlanes
   d# 32 c,    \ Bits/pixel
   1 c,        \ NumBanks
   6 c,        \ MemModel - DirectColor
   0 c,        \ Bank size (not banked)
   2 c,        \ NumImagePages
   1 c,        \ Reserved

   \ Banked Color info
   8 c, d# 16 c,    8 c, 8 c,   8 c,  0 c,   0 c,  0 c,  \ {RGBX}{Bits,Pos}
   0 c,        \ Gamma fixed (change if we implement function 9)

   fb-pci-base l,  0 l,  0 w,   \ Framebuffer address

   \ Linear info
   d# 800 /l* w,     \ Bytes per scan line
   0 c,               \ No banks
   
\  fbsize  d# 800 /  d# 600 /  4/  c,
   7 c,               \ Number of images that will fit in framebuffer

   8 c, d# 16 c,   8 c, 8 c,   8 c,  0 c,   0 c,  0 c,  \ {RGBX}{Bits,Pos}

   d# 56,200,000 l,  \ Max pixel clock
here mode-115-info -  constant /mode-115-info

create mode-118-info
   h# fb w,    \ Linear, VGA, Graphics, Color, TTY Output, D1=1, hardware-supported
   0 c,  0 c,  d# 0 w,  d# 0 w,  h# 0 w,  0 w,  0 l,  \ Not windowed
   d# 1024 /l* w,         \ BytesPerScanLine
   d# 1024 w,  d# 768 w,  \ X, Y res
\   d#   12 c,  d#  15 c,  \ Char width, height
   d#    8 c,  d#  16 c,  \ Char width, height (sort of irrelevant)
   1 c,        \ NumPlanes
   d# 32 c,    \ Bits/pixel
   1 c,        \ NumBanks
   6 c,        \ MemModel - DirectColor
   0 c,        \ Bank size (not banked)
   2 c,        \ NumImagePages
   1 c,        \ Reserved

   \ Banked Color info
   8 c, d# 16 c,    8 c, 8 c,   8 c,  0 c,   0 c,  0 c,  \ {RGBX}{Bits,Pos}
   0 c,        \ Gamma fixed (change if we implement function 9)

   fb-pci-base l,  0 l,  0 w,   \ Framebuffer address

   \ Linear info
   d# 1024 /l* w,     \ Bytes per scan line
   0 c,               \ No banks
   
\  fbsize  d# 1024 /  d# 768 /  4 /  c,
   4 c,               \ Number of images that will fit in framebuffer

   8 c, d# 16 c,   8 c, 8 c,   8 c,  0 c,   0 c,  0 c,  \ {RGBX}{Bits,Pos}

   d# 56,200,000 l,  \ Max pixel clock
here mode-118-info -  constant /mode-118-info

create mode-120-info
   h# fb w,    \ Linear, NotVGA, Graphics, Color, no TTY Output, D1=1, hardware-supported
   0 c,  0 c,  d# 0 w,  d# 0 w,  h# 0 w,  0 w,  0 l,  \ Not windowed
   d# 1200 /w* w,  \ BytesPerScanLine
   d# 1200 w,  d# 900 w,  \ X, Y res
   d#   15 c,  d#  18 c,  \ Char width, height (sort of irrelevant)
   1 c,        \ NumPlanes
   d# 16 c,    \ Bits/pixel
   1 c,        \ NumBanks
   6 c,        \ MemModel - DirectColor (?)
   0 c,        \ Bank size (not banked)
   0 c,        \ NumImagePages
   1 c,        \ Reserved

   \ Banked Color info
   5 c, d# 11 c,   6 c, 5 c,   5 c,  0 c,   0 c,  0 c,  \ {RGBX}{Bits,Pos}
   0 c,        \ Gamma fixed (change if we implement function 9)

   fb-pci-base l,  0 l,  0 w,   \ Framebuffer address

   \ Linear info
   d# 1200 /w*  w,    \ Bytes per scan line
   0 c,               \ No banks
   
\  fbsize  d# 1200 /  d# 900 /  2/  c,
   6 c,               \ Number of images that will fit in framebuffer

   5 c, d# 11 c,   6 c, 5 c,   5 c,  0 c,   0 c,  0 c,  \ {RGBX}{Bits,Pos}

   d# 56,200,000 l,  \ Max pixel clock
here mode-120-info -  constant /mode-120-info


: vbe-farptr!  ( oem-adr  $  vbe-offset -- oem-adr' )
   >r rot                    ( adr len oem-adr  r: vbe-offset )
   dup  r> >vbe-pa seg:off!  ( adr len oem-adr )  \ Set VbeFarPtr
   2>r                       ( adr r: len oem-adr )
   2r@  >caller-physical place-cstr drop  ( r: len oem-adr )
   2r> + 1+
;



: vbe-ok  ( -- )  h# 4f rm-ax!  ;
: vbe-modes  ( -- )
\ ." vbe-modes" cr
   ?vbe2
   h# 41534556              0 >vbe-pa l!   \ VbeSignature
\   h# 0300                  4 >vbe-pa w!   \ VbeVersion
   h# 0200                  4 >vbe-pa w!   \ VbeVersion
   1                    d# 10 >vbe-pa l!   \ Capabilities - 8-bit DACs
   vbebuf d# 34 +       d# 14 >vbe-pa seg:off!   \ VbeFarPtr to mode list
   fbsize d# 16 rshift  d# 18 >vbe-pa w!   \ TotalMemory
   h# 0200              d# 20 >vbe-pa w!   \ OemSoftwareRev

   vbedata                    ( oem-adr )
   " OLPC"     6 vbe-farptr!  ( oem-adr' ) \ OEMString
   " OLPC" d# 22 vbe-farptr!  ( oem-adr' ) \ OEMVendorName
   " XO"   d# 26 vbe-farptr!  ( oem-adr' ) \ OEMProductName
   " 1a"   d# 30 vbe-farptr!  ( oem-adr' ) \ OEMProductRev
   drop

   \ Mode list
   d# 34 >vbe-pa
\        3 w!++  \ Text mode 3
\   h#  12 w!++  \ Graphics mode 12
    h# 112 w!++  \ 640x480x32
    h# 115 w!++  \ 800x600x32
    h# 118 w!++  \ 1024x768x32
\   h# 120 w!++  \ OLPC native mode
   -1 swap w!   \ End of list

   vbe-ok
;
: vbe-get-mode  ( -- )

    rm-cx@  
\ ." vbe-get-mode " dup . cr
h# 1ff and  case
        h# 112 of  mode-112-info /mode-112-info  endof
        h# 115 of  mode-115-info /mode-115-info  endof
        h# 118 of  mode-118-info /mode-118-info  endof
\       h# 120 of  mode-120-info /mode-120-info  endof
       ( default )  ." Bad VBE mode number " dup . cr  0 0 rot  
    endcase   ( adr len )

   0 >vbe-pa h# 100 erase
   0 >vbe-pa swap move
   vbe-ok
;
: vbe-error  ( -- )  h# 014f rm-ax!  ;
0 value vbe-this-mode
: vbe-set-mode  ( -- )
   rm-bx@ case
      h# 4112 of  " 640x480x32"   endof
      h# 4115 of  " 800x600x32"   endof
      h# 4118 of  " 1024x768x32"  endof
      ( default )  drop  vbe-error  exit
   endcase

   " screen-ih" eval ['] $call-method catch  if
      3drop  vbe-error exit
   then
   rm-bx@ to vbe-this-mode
   vbe-ok
;
: vbe-current-mode  ( -- )
   vbe-this-mode rm-bx!
   vbe-ok
;
: vesa-bios  ( -- )
   rm-al@  case
      h# 00  of  vbe-modes      endof
      h# 01  of  vbe-get-mode   endof
      h# 02  of  vbe-set-mode   endof
      h# 03  of  vbe-current-mode   endof
      ( default )  ." Unsupported VBE function" dup .x  cr
   endcase
;

: set-mode12  ( -- )
   text-off  \ Stop using OFW output to screen
[ifdef] smi-access-fb  smi-access-fb  [then]
   " graphics-mode12" " screen-ih" eval $call-method
[ifdef] smi-unaccess-fb  smi-unaccess-fb  [then]
;
: set-video-mode  ( mode -- )
   case
           3 of  set-mode3   endof
       h# 12 of  set-mode12  endof
       ( default )  ." Unsupported video mode " dup .x  cr  rm-set-cf
   endcase
;

: set-cursor  ( -- )  rm-dh@  rm-dl@  ( row column ) 2drop  ;
: get-ega-info  ( -- )
   0 rm-bh!  3 rm-bl!   \ Color, 256K memory
   0 rm-ch!  7 rm-cl!   \ Feature Bits, Primary EGA+ 80x25
;

: video-int  ( -- )  \ INT 10
   noshow
   rm-ah@  case
      h#  0  of  rm-al@ set-video-mode  endof  \ Set mode - Should blank the screen
      h#  2  of  set-cursor    endof
      h#  a  of  rm-al@ emit   endof   \ Write character
      h#  e  of  rm-al@ emit   endof   \ Write character
      h# 11  of  get-font      endof   \ get or set font
      h# 12  of  get-ega-info  endof   \ Get EGA Info (Alternate Select)
      h# 20  of  endof
      h# 4f  of  vesa-bios     endof

      ( default )  ." Unimplemented video int - AH = " dup . cr  rm-set-cf
   endcase
;

[ifdef] use-bios
: bios-video-int  debug-me use-bios  ;
[then]

: sysinfo-int  ( -- )  \ INT 11
   noshow
   \ h# 4226 rm-eax!   \ to report 1 parallel and 1 serial port
   h# 26 rm-eax!   \ 32 bits
;

0 value bios-ih
0 value bios-cdrom-ih
[ifdef] two-bios-disks
0 value bios-disk-ih0
0 value bios-disk-ih1
[else]
0 value bios-disk-ih
[then]

false value show-reads?
-1 value read-match

: drive-sectors  ( -- n )  " #blocks" bios-ih $call-method  ;
: drive-/sector  ( -- n )  " block-size" bios-ih $call-method  ;
d# 256 buffer: bios-devname
\ Replace the filename with "0"
\ For example, /pci/sd@c/disk@3:\boot\olpc.fth//nt-file-system:\boot\olpc.fth
\ becomes      /pci/sd@c/disk@3:0
: bios-dev$  ( -- adr len )
   load-path cscount [char] \ left-parse-string  2nip  ( head$ )
   bios-devname place
   " 0" bios-devname $cat
   bios-devname count
;
: ?open-bios-disk  ( -- )
   bios-disk-ih  0=  if
      bios-dev$ open-dev to bios-disk-ih
      bios-disk-ih 0= abort" Can't open BIOS disk device"
   then
;
[ifndef] notdef
: (bios-read-sectors)  ( adr sector# #sectors -- #sectors-read )
   drive-/sector  >r                      ( adr #sectors d.byte# r: /sector )
   swap r@ um*                            ( adr #sectors d.byte# r: /sector )
   " seek" bios-ih $call-method  if       ( adr #sectors r: /sector )
      r> 3drop  0  exit
   then                                   ( adr #sectors r: /sector )
   r@ *  " read" bios-ih $call-method     ( actual#bytes r: /sector )
   r> /                                   ( #sectors-read )
;
[else]
: (bios-read-sectors)  ( adr sector# #sectors -- #sectors-read )
   " read-blocks" bios-ih $call-method
;
[then]

: bios-read-sectors  ( adr sector# #sectors -- #sectors-read )
   noshow
   over read-match = if  ." Reading block " read-match .  debug-me  then

   show-reads?  if  ." Read " 2 pick . over . dup .  ." -- "  then  ( adr sec# #sec )

   (bios-read-sectors)                     ( #sectors-read )
\   " read-blocks" bios-ih $call-method

   show-reads?  if  dup .  cr  then
;

: bios-write-sectors  ( adr sector# #sectors -- #read )
   noshow

\ ." Write " 2 pick . over . dup .  ." -- "
\ over h# 8b74aaa =  if  debug-me  then
   " write-blocks" bios-ih $call-method
\ dup .  cr
;

: select-bios-disk  ( drive# -- )
[ifdef] two-bios-disks
   case
      h# 80  of  bios-disk-ih0  endof
      h# 81  of  bios-disk-ih1  endof
      h# 82  of  bios-cdrom-ih  endof
      ( default ) bios-ih swap
   endcase
   to bios-ih
[else]
   h# 82 =  if  bios-cdrom-ih  else  bios-disk-ih  then  to bios-ih
[then]
;
: check-drive  ( -- error? )
   show-reads?  if  ." Drive " rm-dl@ .x  then
   rm-dl@  h# 80 h# 81 between 0=  if  rm-set-cf  7 rm-ah!  true exit  then
[ifdef] two-bios-disks
   rm-dl@  select-bios-disk
[else]
   bios-disk-ih to bios-ih
[then]
   bios-ih  0=  dup  if  rm-set-cf  h# aa rm-ah!   then
;
: lba-check-drive  ( -- error? )
   show-reads?  if  ." Drive " rm-dl@ .x  then
   rm-dl@  h# 80 h# 82 between 0=  if  rm-set-cf  7 rm-ah!  true exit  then
   rm-dl@  select-bios-disk
   bios-ih  0=  dup  if  rm-set-cf  h# aa rm-ah!   then
;
: chs-read-sectors  ( -- )
   check-drive  if  exit  then
   bios-ih  0=  if  rm-set-cf  h# aa rm-ah! exit  then
   rm-ch@  rm-cl@ 6 rshift  bwjoin  ( cylinder# )
   h# ff *   rm-dh@ +               ( trk# )     \ 255 heads
   h# 3f *  rm-cl@ h# 3f and 1-  +  ( sector# )  \ 63 is max sector#

   rm-bx@  rm-es@  seg:off>  ( sector# adr )
   swap  rm-al@                             ( adr sector# #sectors )
   bios-read-sectors  rm-al!
;
: chs-write-sectors  ( -- )
   check-drive  if  exit  then
   bios-ih  0=  if  rm-set-cf  h# aa rm-ah! exit  then
   rm-ch@  rm-cl@ 6 rshift  bwjoin  ( cylinder# )
   h# ff *   rm-dh@ +               ( trk# )     \ 255 heads
   h# 3f *  rm-cl@ h# 3f and 1-  +  ( sector# )  \ 63 is max sector#

   rm-bx@  rm-es@  seg:off>  ( sector# adr )
   swap  rm-al@                             ( adr sector# #sectors )
   bios-write-sectors  rm-al!
;
: drive-params  ( -- )
   noshow
   check-drive  if  exit  then
   drive-sectors                      ( #sectors )
   h# 3f /                            ( #tracks )
   h# ff / 1-                         ( maxcyl )  \ Max 255 heads is traditional
\ dup ." MAXCYL " .  cr
   wbsplit                            ( maxcyl.lo maxcyl.hi )
   3 min  6 lshift  h# 3f or  rm-cl!  ( maxcyl.lo )  \ High cyl, max sector
   rm-ch!                             ( ) \ Low byte of max cylinder
   h# fe rm-dh!                       ( ) \ Max head number
   h# 01 rm-dl!                       ( ) \ Number of drives
   rm-clr-cf
;

: ds:si  ( -- adr )  rm-si@  rm-ds@  seg:off>  ;
: lba-read  ( -- )
   lba-check-drive  if  exit  then
   ds:si  ( packet-adr )
   >r  r@ 4 + seg:off@  r@ 8 + l@   r@ 2+ w@     ( adr sector# #sectors )
\ ." LBA "
   bios-read-sectors  r> 2+ w!
;
: lba-write  ( -- )
   lba-check-drive  if  exit  then
   ds:si  ( packet-adr )
   >r  r@ 4 + seg:off@  r@ 8 + l@   r@ 2+ w@     ( adr sector# #sectors )
\ ." LBA "
   bios-write-sectors  r> 2+ w!
;

: check-disk-extensions  ( -- )
   noshow
   lba-check-drive  if  0 rm-bx! exit  then
   rm-bx@  h# 55aa <>  if  exit  then
   h# aa55 rm-bx!
   h# 20 rm-ah!  1 rm-cx!
;
: ext-get-drive-params  ( -- )
   noshow
   lba-check-drive  if  exit  then
   0 rm-ah!
   ds:si  >r    ( adr )
   r@ 2 +  h# 0e  erase   \ CHS info not valid

   \ h# 70 is ATAPI, removable, LBA
   \ h# 10 is LBA
\   rm-dl@ h# 81 =  if  h# 70 else  h# 10  then r@ h# a + w!
\ XXX this might be a problem
   rm-dl@ h# 82 =  if  ( 4 ) h# 34  else  0  then  r@ 2 + w!

   drive-sectors r@ h# 10 + l!  0 r@ h# 14 + l!  \ Total #sectors

   drive-/sector r@ h# 18 + w!   \ Sector len
   h# 1a                  ( written-length )
   r@ w@  h# 1e >=  if
      -1  r@ h# 1a + l!      \ No EDD
      4 +                 ( written-length' )
   then                   ( written-length )
   r@ w@  h# 20 >=  if    ( written-length )
      0 r@ h# 1e + w!        \ Ensure that device path info not interpreted
      \ Don't claim these bytes
   then                   ( written-length )
   r> w!                  \ Number of bytes written
   rm-clr-cf
;

: get-disk-type  ( -- )
   noshow
   check-drive  if  exit  then
   3 rm-ah!
   drive-sectors lwsplit rm-cx!  rm-dx!
   rm-clr-cf
;
: reset-disks  ( -- )  noshow  ;

\ c.f. El Torito CD booting spec
\ We construct a valid status packet, even though NT doesn't look at its
\ contents.  It only looks at the return value in AX.  Most of the fields
\ herein are irrelevant for the "get status" function anyway.
create cd-stat
\      len   type   drive#  ctlr#    LBA  devspec(master/slave, SCSI LUN, etc)
   h# 13 c,  0 c,  h# 82 c,  0 c,   0 l,     0 w,
\   userbuf  loadseg  #sectors  #cyls  sec,cyl  #heads
       0 w,    0 w,       0 w,   0 c,     0 c,    0 c,

: cdrom-status  ( -- )
   \ We don't distinguish between AL=00 and AL=01; both return the same
   \ status.  AL=00 also terminates hard disk emulation, but we don't
   \ do emulation, so that is effectively a no-op.  The NT SETUPLDR
   \ only uses AL=01 anyway.
   \ DL should be the drive number (82); we don't check that
   cd-stat ds:si h# 13 move
   \ This is the return code.  The El Torito spec doesn't say what
   \ the return codes are supposed to be. NT SETUPLDR fails if anything
   \ other than 0 is returned.
   0 rm-ax!
   rm-set-cf  \ CF set means that the system is not in emulation mode
;

: disk-int  ( -- )  \ INT 13 handler
   ?open-bios-disk
   rm-ah@ case
      h# 00  of  reset-disks            endof  \ Reset disk system
      h# 02  of  chs-read-sectors       endof
      h# 03  of  chs-write-sectors      endof
      h# 08  of  drive-params           endof
      h# 15  of  get-disk-type          endof
      h# 41  of  check-disk-extensions  endof
      h# 42  of  lba-read   endof
      h# 43  of  lba-write  endof
      h# 48  of  ext-get-drive-params  endof
      h# 4b  of  cdrom-status  endof
      ( default )  ." Unsupported disk INT 13 - AH = " dup . cr
   endcase
;

false value debug-mem?

: /1k  d# 10 rshift  ;
: bigmem-16bit  ( -- )
   memory-limit
   dup h# 100.0000  min  h# 10.0000 -  0 max  /1k  dup rm-ax!  rm-cx!
   h# 100.0000 -  0 max  d# 16 rshift  dup rm-bx!  rm-dx!
   debug-mem?  if
      ." Bigmem 16: " rm-ax@ .  rm-cx@ .  rm-bx@ .  rm-dx@ .  cr
   then
;
: allmem  ( -- n )
   " /memory" find-package 0= abort" No /memory node"  ( phandle )
   " reg" rot get-package-property abort" No available property"  ( $ )
   decode-int drop  get-encoded-int  h# 10.0000 round-up
;

\ E820 Address range descriptor format:
\ 0: baseaddress.64b  8: length.64b  h#10: type.32b as below
\    1 = AddressRangeMemory, available to OS
\    2 = AddressRangeReserved, not available
\    3 = AddressRangeACPI, available to OS
\    4 = AddressRangeNVS, not available to OS
\    Other = Not defined, not available

create memdescs
\  h#          0. d,                 'ebda 0  d,  1 l,  \  0 available
\  'ebda       0  d,   h# a0000   'ebda  - 0  d,  3 l,  \ 14 reclaimable

\ Test version
   h#          0. d,              h# 80000 0  d,  1 l,  \  0 available
\      h# 80000 0  d,   h# 9fc00 h# 80000 - 0  d,  3 l,  \ 14 reclaimable
      h# 80000 0  d,   h# 9fc00 h# 80000 - 0  d,  1 l,  \ 14 available
      h# 9fc00 0  d,   h# a0000 h# 9fc00 - 0  d,  2 l,  \ 28 reserved
\ End test

\  h#      e0000. d,                h# 20000. d,  2 l,  \ 3c reserved
   h#      e8000. d,                h# 08000. d,  2 l,  \ 3c reserved
   h#     100000. d,                       0. d,  1 l,  \ 50 available
\              0. d,                       0. d,  4 l,  \ 64 don't reclaim (yet)
               0. d,                       0. d,  2 l,  \ 64 reserved fw memory
   h#   fff00000. d,               h# 100000. d,  2 l,  \ 78 reserved (ROM)
here memdescs - constant /memdescs

: populate-memory-map  ( -- )
   memory-limit  h# 100000 -  memdescs h# 58 + l!  \ Size of memory above 1M
   memory-limit               memdescs h# 64 + l!  \ Base of firmware memory
   allmem fbsize - memory-limit -      memdescs h# 6c + l!  \ Size of firmware memory
;

: system-memory-map  ( -- )  \ E820
   rm-clr-cf              \ Possibly superfluous
   rm-edx@  rm-eax!       \ Propagate "SMAP" signature to return register

   \ Continue from address in EBX; if is is 0, start at the beginning
   rm-ebx@  ?dup 0=  if  memdescs  then                ( adr )

   \ At the end of the table, return 0 in ECX
   dup  memdescs /memdescs +  =  if  drop  0 rm-ecx!  exit  then
 
   \ Otherwise copy out the next table entry, return length in ECX and next address in EBX
   dup  rm-edi@ h# ffff and rm-es@  seg:off>  ( adr dst )
   rm-ecx@  move                              ( adr )
   debug-mem?  if
      ." E820 Mem: " dup rm-ecx@ ldump cr
   then
   rm-ecx@ +  rm-ebx!                         ( )  \ Continuation
;

: bigmem-int  ( -- )
   rm-clr-cf
   rm-al@ case
      h# 01 of  bigmem-16bit   endof
      h# 20 of  system-memory-map  endof
\     h# 81 of  pm-system-memory-map  endof
      ( default )  rm-set-cf
         ." Unsupported Bigmem int 15 AH=e8 AL=" dup . cr
   endcase
;

: apm-power-status  ( -- )
   1 rm-bh!  \ AC adapter on-line
   0 rm-bl!  \ Battery high
   1 rm-ch!  \ Battery high
   d# 99 rm-cl!  \ Battery percentage
   h# 8100 rm-dx!  \ Remaining battery life
   1 rm-esi!  \ Number of batteries installed (only needed if bh is 80 on entry)
;
: apm-get-event  ( -- )
   h# 80 rm-bx!  \ No events (3 for normal resume)
;
0 value apm-driver-version
0 [if]
: apm  ( -- )
   rm-clr-cf
\  ." APM - " rm-al@ . cr
   rm-al@  case
      h# 00 of  h# 101 rm-ax!  [char] P rm-bh!  [char] M rm-bl!  0 rm-cx!  endof  \ Query
      h# 01 of  endof                       \ Connect real mode
      h# 02 of  6 rm-ah!  rm-set-cf  endof  \ Connect PM16 (not supported)
      h# 03 of  8 rm-ah!  rm-set-cf  endof  \ Connect PM32 (not supported)
      h# 04 of  endof                       \ Disconnect
      h# 05 of  noop  endof                 \ CPU is Idle
      h# 06 of  noop  endof                 \ CPU is Busy
      h# 07 of  ." Set power state " rm-bx@ . rm-cx@ . cr  interact  endof
      h# 08 of  noop  endof                 \ Enable/Disable PM
      h# 09 of  noop  endof                 \ Restore Power-On Defaults
      h# 0a of  apm-power-status  endof
      h# 0b of  apm-get-event   endof
      h# 0c of  0 rm-cx!    endof    \ Power state APM enabled
      h# 0d of  noop  endof                 \ Enable/Disable PM for a device
      h# 0e of  rm-cx@ to apm-driver-version  h# 101 rm-ah!  endof        \ Reports APM driver version, returns APM BIOS version
      h# 0f of  noop  endof                 \ Engage/disengage PM for devices
      h# 10 of  1 rm-bl!  3 rm-cx!  endof   \ 1.2 Capabilities - 1 battery, standby and suspend, no resume timers
      h# 11 of  h# c rm-ah!  rm-set-cf  endof  \ 1.2 Set resume timer
      h# 12 of  h# c rm-ah!  rm-set-cf  endof  \ 1.2 Set resume on ring
      h# 13 of  noop   endof                   \ 1.2 Enable/disable timer-based requests
      h# 80 of  0 rm-ah!     rm-set-cf  endof  \ OEM installation check
   endcase
;
[else]
: apm  ( -- )  rm-set-cf  ;   \ Not supported; superseded by ACPI
[then]

\ System configure
create sysconf
  8 w,       \ 8 bytes following
  h# fc c,   \ model
  1 c,       \ Submodel
  0 c,       \ BIOS rev
  h# 74 c,   \ Feature - second 8259, RTC, INT 9 calls INT 15/4F, extended BIOS area
  0 c,
  0 c,
  0 c,
  0 c,

: get-conf  ( -- )
   sysconf rm-buf 8 move
   rm-buf >seg:off  rm-es!  rm-bx! 
   0 rm-ax!
;

: handle-mouse  ( -- )
   rm-al@ case
      1 of  rm-clr-cf  endof   \ Reset mouse
      ( default )  ." Unsupported mouse INT 15 AH c2 AL " dup . cr   rm-set-cf
   endcase
;

: gate-a20  ( -- )
   rm-al@ case
      h# 00 of  rm-set-cf          endof  \ Disable - We don't support disabling A20
      h# 01 of  0 rm-ah!           endof  \ Enable  - We always leave it enabled, so return OK (00) status
      h# 02 of  1 rm-ax!           endof  \ Status  - Enabled (01) in AL , OK (00) in AH
      h# 03 of  1 rm-bx! 0 rm-ah!  endof  \ Which   - Port92 (01) in BX, OK (00) in AH
   endcase
;
: system-int  ( -- )  \ INT 15 handler
   noshow
   rm-clr-cf
   rm-ah@ case
      h# 24 of  gate-a20   endof
      h# 91 of  noshow 0 rm-ah!  endof   \ "pause" while waiting for I/O
noop
      h# 53 of  apm  endof
      h# 86 of  rm-dx@  rm-cx@ wljoin us  endof  \ Delay microseconds
      h# 8a of  memory-limit h# 400.0000 - 0 max  /1k  lwsplit rm-dx! rm-ax!
         debug-mem?  if  ." Mem 15/8a: " rm-dx@ .  rm-ax@ .  cr  then
      endof
      h# 88 of  h# fffc rm-ax!  
         debug-mem?  if  ." Mem 15/88: " rm-ax@ .  cr  then
      endof  \ Extended memory - at least 64 MB
      h# c0 of  get-conf  endof
      \ We use the extended BIOS data area as our workspace when loaded from another BIOS
\      h# c1 of  rm-set-cf h# 86 rm-ah!  endof  \ No extended BIOS data area
      h# c1 of  'ebda 4 rshift rm-es!  endof  \ Segment address of extended BIOS data area
      h# c2 of  handle-mouse  endof
      h# e8 of  bigmem-int  endof
      h# e9 of  rm-set-cf   endof   \ Don't know what this is.  Ralf Brown's interrupt list says
                        \ PhysTechSoft PTS ROM-DOS, but I doubt that is right
                        \ Windows invokes it but seems to be okay with it failing
      ( default )  rm-set-cf
         ." Unsupported INT 15 AH=" dup . cr
   endcase
;

0 value the-key

: $call-keyboard  ( ?? method-name$ -- ?? )  keyboard-ih $call-method  ;
: poll-key  ( -- false | scan,ascii true )
   the-key  ?dup  if  true exit  then
   d# 50 ms   \ I don't know why this is necessary, but without it, you don't see the key
   0 " get-scancode" $call-keyboard  if         ( scancode )
      dup h# 80 and  if                         ( scancode )
         \ Discard release events and escapes (e0)
         drop false                             ( false )
      else
         dup " scancode->char" $call-keyboard  0=  if  0  then  ( scancode ascii )
         dup h# 80 and  if  drop 0  then        \ Don't return e.g. 9B for arrows
         swap bwjoin to the-key
         the-key true
      then
   else
      false
   then
;

0 value polled?
: poll-keystroke  ( -- )
   noshow
\   polled?  0=  if  ." ? "  then
   true to polled?
   poll-key  if  ( scancode,ascii )
      rm-ax!
      rm-flags@ h# 40 invert and rm-flags!
   else
      rm-flags@ h# 40 or rm-flags!
   then
;
: get-keystroke  ( -- )
   noshow

   begin  poll-key  until   ( scancode,ascii )
   0 to the-key
   rm-ax!

\   rm-al@ [char] d =  if  debug-me  then
   false to polled?
;

: keyboard-int  ( -- )  \ INT 16 handler
   noshow!
   rm-ah@ case
      0 of  get-keystroke  endof
      1 of  poll-keystroke  endof
      2 of  0 rm-al!  endof  \ Claim that no shift keys are active
      5 of  rm-cx@ to the-key  endof  \ Put keystroke in buffer
      ( bit 7:sysrq  6:capslock  5:numlock 4:scrlock 3:ralt 2:rctrl 1:lalt 0:lctrl )
      ( default )  ." Keyboard INT called with AH = " dup . cr
   endcase
;

: cfgadr  ( -- adr )
   rm-edi@  h# ff and   rm-bx@  8 lshift  or
;
: pcibios-installed  ( -- )
   noshow
   h# 20494350 rm-edx!   \ "PCI " in little-endian
   0 rm-ah!              \ must be 0 to indicate PCI BIOS present
   1 rm-al!              \ Config method 1
   h# 201 rm-bx!         \ Version 2.1
   0 rm-cl!              \ Number of last PCI bus - XXX get this from PCI node
;
: pcibios  ( -- )  \ INT 1a
   noshow
   rm-clr-cf
   rm-al@ case
      h# 01 of  pcibios-installed  endof
\     h# 02 of  find-pci-device ( cx:devid dx:vendid si:index -> bh:bus# bl:devfn )   endof  
\     h# 03 of  find-pci-class-code ( ecx:0,classcode si:index -> bh:bus# bl:devfn )  endof
\     h# 06 of  pci-special-cycle  ( bh:bus# edx:special_cycle_data )  endof
      h# 08 of  cfgadr config-b@ rm-cl!  endof
      h# 09 of  cfgadr config-w@ rm-cx!  endof
      h# 0a of  cfgadr config-l@ rm-ecx!  endof
      h# 0b of  rm-cl@  cfgadr config-b!  endof
      h# 0c of  rm-cx@  cfgadr config-w!  endof
      h# 0d of  rm-ecx@ cfgadr config-l!  endof

      h# 0e of  h# 81 rm-ah!  rm-set-cf  endof  \ Fail PCI interrupt routing for now
 \    h# 0e of  pci-int-rout  endof

 \    h# 0f of  set-pci-int   endof

      ( default )     h# 81 rm-ah!     rm-set-cf
         ." Unimplemented PCI BIOS INT 1a AH b1 - AL = " dup . cr
   endcase
;

: get-timer-ticks  ( -- )
   noshow
   get-msecs d# 55 /  lwsplit  rm-cx!  rm-dx!
   0 rm-al!  \ Should be nonzero if midnight happened since last call
;

: int-1a  ( -- )
   rm-ah@  case
      h#  0  of  get-timer-ticks  noshow  endof
\      h#  4  of  rm-clr-cf  get-rtc-date  endof  \ ch century   cl year  dh month  dl day
      h# b1  of  pcibios          endof
      ( default )  ." Unimplemented INT 1a - AH = " dup .  cr  rm-set-cf
   endcase
;

: printer-int  ( -- )
   rm-ah@  1 2 between  if
      noshow  h# 30 rm-ah!
   else
      ." Printer INT AH = " rm-ah@ .  cr
   then
;

: (handle-bios-call)  ( -- )
   snap-int

   rm-int@ irq-vector-base -  dup  0  h# 10 within  if
      dispatch-interrupt
      ukey?  if  debug-me  then
      exit
   then
   drop

   rm-int@  case
      h# 10  of  video-int     endof
      h# 11  of  sysinfo-int   endof
      h# 13  of  disk-int      endof
      h# 16  of  keyboard-int  endof
      h# 15  of  system-int    endof
      h# 12  of  'ebda /1k rm-ax!
            debug-mem?  if  ." Lowmem: " rm-ax@ .  cr  then
      endof  \ Low memory size
      h# 1a  of  int-1a        endof
      h# 18  of  ." Entering Open Firmware" cr  interact    endof
      h# 19  of  ." Rebooting" cr  bye    endof
      h# 17  of  printer-int  endof
      h# 1c  of  noshow!  0 dispatch-interrupt    endof  \ Timer bounce vector
      ( default )  ." Interrupt " dup . cr  interact
   endcase
   ?showint
;
' (handle-bios-call) to handle-bios-call

h# 7c00 constant mbr-base
: get-mbr  ( -- )
\   mbr-base h# 3f 1  bios-read-sectors 1 <> abort" Didn't read MBR"
   mbr-base 0 1  bios-read-sectors 1 <> abort" Didn't read MBR"
;

\ : #hard-drives  ( -- n )  bios-boot-dev# h# 82 =  if  2  else  1  then  ;
: #hard-drives  ( -- n )  1  ;

: make-bda  ( -- )
   h# 400 h# 101 erase
   'ebda h# 400 erase
   h# 3f8 h# 400 w!
   'ebda 4 rshift h# 40e w!
   h# 26 h# 410 w!   \ Equipment list reported by INT 11
   d# 640 h# 413 w!  \ Low memory size in KiB
   3 h# 449 c!       \ Current video mode
   d# 80 h# 44a w!   \ Characters per text row
   d# 80 d# 25 * h# 44c w!  \ Characters per screen
   0 h# 44e w!       \ display page offset
   \ Some more VGA stuff in 450 .. 466
   \ 46c.l is tick count, 470.b is midnight flag
   \ 4701.b bit 0x80 is ctrl-break flag
   h# 1234 h# 472 w!  \ Skip memory test
   #hard-drives  h# 475 c!  \ Number of hard drives
   d# 25 1- h# 484 c! \ Screen max row #
   d# 16   h# 485 w!  \ Character height
   h# 100.0000 h# 487 l!  \ Video RAM size

   1 'ebda w!         \ Size of EBDA in KiB
   \ 'ebda h# 3d +   ..  HD0 parameter table
   \ 'ebda h# 4d +   ..  HD1 parameter table
   #hard-drives 'ebda h# 70 + c!   \ Number of hard disks
;

label bounce-timer  \ Redirect the timer interrupt through INT 1c
   16-bit
   ax   push
   h# 20 # ax mov
   al   h# 20 #  out  \ Writing h# 20 to IO port 20 is interrupt ack
   ax   pop
   \ After acking the hardware interrupt, we call the INT 1c vector,
   \ which NTLDR hooks when it wants to receive timer ticks.  That
   \ vector will perform the IRET to return from the hardware interrupt.
   cs:  h# 72 #)  push
   cs:  h# 70 #)  push
   far ret
end-code
here bounce-timer - constant /bounce-timer

: setup-timer-vector  ( -- )
   \ Put the ISA timer bounce vector at INT 30  (h# c0).  It overlays
   \ INTs 30-32, which aren't used by anything interesting.
   bounce-timer h# c0  /bounce-timer  move

   \ Change INT 20 (the timer tick) to point to the bounce vector with CS=0
   \ INT 20 is called by the timer hardware via IRQ 0, which vectors to INT 20
   \ (vector-base0 = 0x20).  The following causes it to execute the "bounce-timer"
   \ code which has been placed at location 0xc0.
   0 h# 82 w!  h# c0 h# 80 w!  \ CS = 0, IP = h# c0 = INT 30
;

0 value rm-prepped?
: prep-rm  ( -- )
   rm-prepped?  if  exit  then   true to rm-prepped?
   setup-smi
   make-bda
   setup-acpi
   setup-smbios
   setup-rm-gateway
   setup-timer-vector

   'ebda 4 rshift  h# 40e w!   \ Extended BIOS data area segment address

   populate-memory-map
   rm-platform-fixup
;
: close-bios-disk  ( -- )
[ifdef] two-bios-disks
   bios-disk-ih0 ?dup  if  close-dev   0 to bios-disk-ih0  then
   bios-disk-ih0 ?dup  if  close-dev   0 to bios-disk-ih1  then
[else]
   bios-disk-ih ?dup  if  close-dev   0 to bios-disk-ih  then
[then]
;
: close-bios-cdrom  ( -- )  bios-cdrom-ih ?dup  if  close-dev   0 to bios-cdrom-ih  then  ;
: close-bios-devices  ( -- )  close-bios-disk  close-bios-cdrom  ;
' close-bios-devices to quiesce-devices

[ifdef] notdef  \ Doesn't work with CD-ROM
: rm-go   ( -- )
   prep-rm
   open-bios-disk
   get-mbr   \ Load boot image at 7c00
\   usb-quiet
   init-regs mbr-base rm-run
;
[then]

: is-mbr?  ( adr len -- flag )
   + 2 - le-w@  h# aa55 = 
;
warning @ warning off
: init-program  ( -- )
   loaded is-mbr?  if
      prep-rm
      loaded mbr-base swap move
      init-regs /rm-regs erase
      bios-boot-dev#  init-regs >rm-edx c!   \ DL
      exit
   then
   init-program
;
defer rm-go-hook ' noop to rm-go-hook
\ " rm-go"  ' boot-command  set-config-string-default
: execute-buffer  ( adr len -- )
   rm-prepped?  if      ( adr len )
      2drop             ( )
      rm-go-hook
\     usb-quiet         ( )
      init-regs mbr-base rm-run   ( )
      exit  \ Precautionary; rm-run shouldn't return
   then
   execute-buffer
;
warning !

0 value boot-sector#
1 value boot-#sectors
: get-cdrom-sector  ( sector# -- error? )
   load-base swap 1  (bios-read-sectors) 1 <>
;
: close-bios-ih  ( -- )  bios-ih  ?dup  if  close-dev  0 to bios-ih  then  ;
: bootable-cdrom?  ( -- flag )
   drive-/sector h# 800 <>  if  false exit  then

   \ Check Boot Record
   h# 11 get-cdrom-sector  if  false exit  then
   load-base " "(00)CD001"(01)EL TORITO SPECIFICATION" comp  if  false exit  then

   \ Check Boot Catalog and Section Entry
   load-base h# 47 + le-l@   get-cdrom-sector  if  false exit  then
   load-base le-l@ 1 <>  if  false exit  then
   0  load-base h# 20 bounds  do  i le-w@ +  /w +loop
   h# ffff and  if  false exit  then
   load-base 1+ c@  if  false exit  then   \ Must be for x86 platform

   \ Record pointer to boot code
   load-base h# 20 + c@  h# 88 <>  if  false exit  then  \ Must be bootable
   load-base h# 28 + le-l@ to boot-sector#
   load-base h# 26 + le-w@ 4 / 1 max  to boot-#sectors

   true
;
: set-hd-boot  ( dev$ -- )
[ifdef] two-bios-disks
   open-dev to bios-disk-ih0
[else]
   open-dev to bios-disk-ih
[then]
   0 to boot-sector#  1 to boot-#sectors
   h# 80 to bios-boot-dev#
[ifdef] two-bios-disks
   bios-disk-ih0 to bios-ih
[else]
   bios-disk-ih to bios-ih
[then]
;
: get-one-sector  ( dev$ -- error? )
   open-dev to bios-ih
   bios-ih 0=  if  true exit  then
   load-base 0 1 (bios-read-sectors)   ( #read )
   close-bios-ih                       ( #read )
   1 <>                                ( error? )
;
: first-partition-bootable?  ( -- flag )
   load-base h# 1be + c@  h# 80 =
;
: mbr-bootable?  ( dev$ -- flag )
   get-one-sector  if  false exit  then
   first-partition-bootable?
;

: ntfs?  ( dev$ -- flag )
   get-one-sector  if  false exit  then
   load-base 3 +  " NTFS    "  comp  0=                   ( flag )
;

: mbr-load  ( adr -- #bytes )
   bios-boot-dev#  select-bios-disk
   boot-sector# boot-#sectors bios-read-sectors
   bios-boot-dev#  h# 82 =  if  h# 800  else  h# 200  then  *
;

[ifdef] notdef
0 0 " " " /" begin-package
   " xp" device-name
   : open
      bypass-bios-boot?  if  false exit  then
      " ext:1" ntfs?  if
         " ext:0" set-hd-boot
         " sound-end" evaluate
         true exit
      then
      false
   ;
   : close ;
   : load  ( adr -- nbytes )  mbr-load  ;      
end-package
[then]

0 0 " " " /" begin-package
   " xpinstall" device-name
   : open
      " /usb/disk:0" open-dev  ?dup  if      ( ih )
         to bios-ih
         bootable-cdrom?  if
            bios-ih to bios-cdrom-ih
[ifdef] two-bios-disks
            " ext:0" open-dev ?dup  if
               to bios-disk-ih1
[else]
            " int:0" open-dev ?dup  if
               to bios-disk-ih
[then]
            else
[ifdef] two-bios-disks
               " int:0" open-dev ?dup  if
                  to bios-disk-ih1
[else]
               " ext:0" open-dev ?dup  if
                  to bios-disk-ih
[then]
               else
                  ." Can't open SD device.  Install from CD-ROM probably won't work."  cr
               then
            then
            h# 82 to bios-boot-dev#
            true exit
         then
[ifdef] two-bios-disks
         \ Check for bootable USB FLASH drive and set the SD drive number if possible
         load-base 0 1 (bios-read-sectors)  1 =  if
            first-partition-bootable?  if
               bios-ih to bios-disk-ih0
               " ext:0" open-dev ?dup  if
                  to bios-disk-ih1
               else
                  " int:0" open-dev ?dup  if
                     to bios-disk-ih1
                  else
                     ." Can't open SD device.  Install from UFD probably won't work."  cr
                  then
               then
               h# 80 to bios-boot-dev#
               true exit
            then
         then
[then]
         close-bios-ih
      then

      \ The device was not a bootable CDROM, but it might be a USB memory stick

      " /usb/disk:0" mbr-bootable?  if  " /usb/disk:0" set-hd-boot  true exit  then

      " int:0" mbr-bootable?  if  " int:0" set-hd-boot  true exit  then
      " ext:0" mbr-bootable?  if  " ext:0" set-hd-boot  true exit  then

      false
   ;
   : close ;
   : load  ( adr -- nbytes )  mbr-load  ;      
end-package

: install-xp  ( -- )  " /xpinstall" $boot  ;

\ This is a debugging hack that lets you inject a dead-end port80 callout into code
\ label xx  h# 99 # al mov  al h# 80 # out  begin again  end-code
\ here xx - constant /xx
\ : put-xx  ( adr -- )  xx swap /xx move  ;
: @.w  ( -- )  w@ 5 u.r  ;
: @.l  ( -- )  @ 9 u.r  ;
: .lreg  ( adr -- adr' )  4 -  dup l@ 9 u.r   ;
: .wreg  ( adr -- adr' )  2 -  dup w@ 5 u.r   ;
: .caller-regs  ( -- )
[ifdef] >rm-retaddr
   ."        AX       CX       DX       BX       SP       BP       SI       DI" cr
   caller-regs >rm-eax 4 +  8 0 do  .lreg  loop  cr
   cr
   ."    DS   ES   FS   GS       PC  FLAGS" cr
   4 0 do  .wreg  loop  
   drop
   rm-retaddr@ 9 u.r  2 spaces
   rm-flags@ 5 u.r cr
[else]
   ."        AX       BX       CX       DX       BP       SI       DI       SP" cr
   caller-regs >rm-eax @.l
   caller-regs >rm-ebx @.l
   caller-regs >rm-ecx @.l
   caller-regs >rm-edx @.l
   caller-regs >rm-ebp @.l
   caller-regs >rm-esi @.l
   caller-regs >rm-edi @.l
   caller-regs >rm-esp @.l
   cr cr
   ."    CS   DS   ES   FS   GS   SS       PC  FLAGS" cr
   caller-regs >rm-cs @.w
   caller-regs >rm-ds @.w
   caller-regs >rm-es @.w
   caller-regs >rm-fs @.w
   caller-regs >rm-gs @.w
   caller-regs >rm-ss @.w
   rm-retaddr@ 9 u.r  2 spaces
   rm-flags@ 5 u.r cr
[then]
;

: egadump  ( -- )
   d# 25  0  do
      d# 80 0  do
         j d# 80 *  i + 2*  h# b8000 + c@  emit
      loop
      cr
   loop
;

0 [if]
\   h# 3fd #  dx  mov  begin  dx al in   h# 20 # al test  0<> until
\   h# 3f8 #  dx  mov  h# 41 #  al mov   al  dx out

stdout off stdin off
label cifxxx  ( -- )
   h# 55555555 # ax mov   h# fd00.0000 # edi mov  h# 40000 # cx  mov  rep ax stos
   begin  again
end-code
patch cifxxx cif-handler set-parameters
\ patch 0 cif-handler set-parameters

\ here foo -  constant /foo    h# ff000 constant cifxxx  : set-foo  foo  cifxxx  /foo move  ;
\ set-foo  .( CIF )
\ patch 0 cif-handler set-parameters
\ patch cifxxx cif-handler (init-program)

stdout off stdin off

h# 100 alloc-mem  gdtr@ 1+  2 pick swap move   h# ff gdtr!

1000 1000 mem-claim cr3!  cr3@ 1000 erase  ff80.0083 cr3@ ff8 + !  cr4@ 10 or cr4!

\ verbose-cif
load u:\tvmlinuz ro console=tty0 fbcon=font:SUN12x22




stdout off stdin off
h# 100 h# 10 mem-claim   gdtr@ 1+  2 pick swap move   h# ff gdtr!

h# 40.0000 constant 4m  h# 1000 constant 4k
: (set-pdes)   do  dup 3 +  cr3@ i d# 22 rshift la+ l!  4k +  4m +loop  drop  ;
: set-pdes-uc
   3dup  do  i h# 13 or  over l!  la1+  4k +loop  drop  ( base high low ) (set-pdes)
;
: set-pdes  ( pte-base  high low -- )
   3dup  do  i h# 3 or  over l!  la1+  4k +loop  drop  ( base high low )  (set-pdes)
;
: set-pt  ( -- )
 ( G )  4k  4k  mem-claim cr3!  cr3@ 4k erase
   h# 40000  4k mem-claim  h# f00.0000  0  set-pdes  \ All of memory
\   h# 2000  4k mem-claim  h# f00.0000  h# e80.0000  set-pdes  \ OFW RAM area + some DMA
\ ( G )  4k  4k mem-claim  h# f00.0000  h# ec0.0000  set-pdes  \ OFW RAM area
   4k0  4k mem-claim  h# 0  h# fc00.0000  set-pdes-uc        \ IO
\   cr0@ h# 8000.0000 or  cr0!    ( cr4@ h# 10 or  cr4!  )
;
set-pt .( PTES )
verbose-cif
load u:\tvmlinuz ro console=tty0 fbcon=font:SUN12x22
100011 3 90 fill  \ Nop-out lea that puts ESP in a bad place for the debugger
100061 till
--bp  71638c till
--bp

\ 716394 till
\ 400074 till
6e4000 till
6 steps
\ 6e401a till
cr3@ @ ff invert and 400 + c00 erase
c040c5af till  \ after return from _mmx_memcpy in zap_low_mappings

c06eef8e till  \ mem_init
c06eeff7 till
\ c06e4944 till  \ call trap_init
\ 714dcb till
c040c5af till   \ in zap_low_mappings

code switch-seg
  op: h# 18 # ax mov   ax ds mov  ax es mov  ax fs mov ax gs mov  ax ss mov
  h# 10 #  push
  here 6 + #  push
  far ret
c;

[then]

\ LICENSE_BEGIN
\ Copyright (c) 2008 FirmWorks
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
