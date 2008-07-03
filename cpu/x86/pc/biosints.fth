
[ifdef] syslinux-loaded   : disk-name  ( -- $ )  " /pci/ide@0"  ;  [then]
[ifdef] preof-loaded      : disk-name  ( -- $ )  " /pci/ide@0"  ;  [then]
[ifdef] rom-loaded        : disk-name  ( -- $ )  " sd:0"  ;        [then]

struct
  2 field >rm-gs
  2 field >rm-fs
  2 field >rm-es
  2 field >rm-ds
  4 field >rm-edi
  4 field >rm-esi
  4 field >rm-ebp
  4 field >rm-exx
  4 field >rm-ebx
  4 field >rm-edx
  4 field >rm-ecx
  4 field >rm-eax
  4 field >rm-retaddr
  2 field >rm-flags
drop

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

: rm-retaddr@  caller-regs >rm-retaddr seg:off@  ;

: rm-flags@  caller-regs >rm-flags w@  ;
: rm-flags!  caller-regs >rm-flags w!  ;

: rm-set-cf  rm-flags@  1 or  rm-flags!  ;
: rm-clr-cf  rm-flags@  1 invert and  rm-flags!  ;

true value show-rm-int?
: noshow  false to show-rm-int?  ;
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
   stdout @  if
      " text-mode3" stdout @ $call-method
      stdout off
   then
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

create mode-115-info
   h# fb w,    \ Linear, NotVGA, Graphics, Color, no TTY Output, D1=1, hardware-supported
   0 c,  0 c,  0 w,  d# 64 w,  0 w,  0 w,  0 l,  \ Not windowed
   0 w,        \ BytesPerScanLine irrelevant in linear mode
   d#  800 w,  d# 600 w,  \ X, Y res
   d#   15 c,  d#  18 w,  \ Char width, height (sort of irrelevant)
   1 c,        \ NumPlanes (irrelevant for linear?)
   d# 24 c,    \ Bits/pixel
   1 c,        \ NumBanks
   6 c,        \ MemModel - DirectColor (?)
   0 c,        \ Bank size (not banked)
   0 c,        \ NumImagePages
   1 c,        \ Reserved

   \ Banked Color info
   8 c, d# 16 c,    8 c, 8 c,   8 c,  0 c,   0 c,  0 c,  \ {RGBX}{Bits,Pos}
   0 c,        \ Gamma fixed (change if we implement function 9)

   fb-pci-base l,  0 l,  0 w,   \ Framebuffer address

   \ Linear info
   d# 4096 /w*  w,    \ Bytes per scan line
   0 c,               \ No banks
   
\  fbsize  d# 1200 /  d# 900 /  2/  c,
   3 c,               \ Number of images that will fit in framebuffer

   8 c, d# 16 c,   8 c, 8 c,   8 c,  0 c,   0 c,  0 c,  \ {RGBX}{Bits,Pos}

   d# 56,200,000 l,  \ Max pixel clock
here mode-115-info -  constant /mode-115-info

create mode-118-info
   h# fb w,    \ Linear, NotVGA, Graphics, Color, no TTY Output, D1=1, hardware-supported
   0 c,  0 c,  0 w,  d# 64 w,  0 w,  0 w,  0 l,  \ Not windowed
   0 w,        \ BytesPerScanLine irrelevant in linear mode
   d# 1024 w,  d# 768 w,  \ X, Y res
   d#   15 c,  d#  18 w,  \ Char width, height (sort of irrelevant)
   1 c,        \ NumPlanes (irrelevant for linear?)
   d# 24 c,    \ Bits/pixel
   1 c,        \ NumBanks
   6 c,        \ MemModel - DirectColor (?)
   0 c,        \ Bank size (not banked)
   0 c,        \ NumImagePages
   1 c,        \ Reserved

   \ Banked Color info
   8 c, d# 16 c,    8 c, 8 c,   8 c,  0 c,   0 c,  0 c,  \ {RGBX}{Bits,Pos}
   0 c,        \ Gamma fixed (change if we implement function 9)

   fb-pci-base l,  0 l,  0 w,   \ Framebuffer address

   \ Linear info
   d# 4096 /w*  w,    \ Bytes per scan line
   0 c,               \ No banks
   
\  fbsize  d# 1200 /  d# 900 /  2/  c,
   3 c,               \ Number of images that will fit in framebuffer

   8 c, d# 16 c,   8 c, 8 c,   8 c,  0 c,   0 c,  0 c,  \ {RGBX}{Bits,Pos}

   d# 56,200,000 l,  \ Max pixel clock
here mode-118-info -  constant /mode-118-info

create mode-120-info
   h# fb w,    \ Linear, NotVGA, Graphics, Color, no TTY Output, D1=1, hardware-supported
   0 c,  0 c,  0 w,  d# 64 w,  0 w,  0 w,  0 l,  \ Not windowed
   0 w,        \ BytesPerScanLine irrelevant in linear mode
   d# 1200 w,  d# 900 w,  \ X, Y res
   d#   15 c,  d#  18 w,  \ Char width, height (sort of irrelevant)
   1 c,        \ NumPlanes (irrelevant for linear?)
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
   7 c,               \ Number of images that will fit in framebuffer

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
   ?vbe2
   h# 41534556              0 >vbe-pa l!   \ VbeSignature
   h# 0300                  4 >vbe-pa w!   \ VbeVersion
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
   h# 115 w!++  \ 800x600x24
   h# 118 w!++  \ 1024x768x24
   h# 120 w!++  \ OLPC native mode
   -1 swap w!   \ End of list

   vbe-ok
;
: vbe-get-mode  ( -- )
    rm-cx@  case
       h# 115 of  mode-115-info /mode-115-info  endof
       h# 118 of  mode-118-info /mode-118-info  endof
       h# 120 of  mode-120-info /mode-120-info  endof
       ( default )  ." Bad VBE mode number " dup . cr  0 0 rot  
    endcase   ( adr len )

   0 >vbe-pa h# 100 erase
   0 >vbe-pa swap move
;
: vbe-set-mode  ( -- )
   ." VBE set mode " rm-cx@ .  cr
   debug-me
;
: vesa-bios  ( -- )
   rm-al@  case
      h# 00  of  vbe-modes      endof
      h# 01  of  vbe-get-mode   endof
      h# 02  of  vbe-set-mode   endof
      ( default )  ." Unsupported VBE function" dup .x  cr
   endcase
;

: set-mode12  ( -- )
   " graphics-mode12" " screen-ih" eval $call-method
   stdout off
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

0 value disk-ih
false value show-reads?
-1 value read-match

: disk-read-sectors  ( adr sector# #sectors -- #read )
   noshow
   over read-match = if  ." Reading block " read-match .  debug-me  then

   show-reads?  if  ." Read " 2 pick . over . dup .  ." -- "  then
   " read-blocks" disk-ih $call-method
   show-reads?  if  dup .  cr  then

;

0 value entry-count
: ?hack
   entry-count dup 1+ to entry-count  1 =  if
      hack-fix-mode
   then
;

: disk-write-sectors  ( adr sector# #sectors -- #read )
\   ?hack
   noshow

\ ." Write " 2 pick . over . dup .  ." -- "
\ over h# 8b74aaa =  if  debug-me  then
   " write-blocks" disk-ih $call-method
\ dup .  cr
;

: check-drive  ( -- error? )
   rm-dl@  h# 80 <>  if  rm-set-cf  7 rm-ah!  true exit  then
   disk-ih  0=  dup  if  rm-set-cf  h# aa rm-ah!   then
;
: read-sectors  ( -- )
   check-drive  if  exit  then
   disk-ih  0=  if  rm-set-cf  h# aa rm-ah! exit  then
   rm-ch@  rm-cl@ 6 rshift  bwjoin  ( cylinder# )
   h# ff *   rm-dh@ +               ( trk# )     \ 255 heads
   h# 3f *  rm-cl@ h# 3f and 1-  +  ( sector# )  \ 63 is max sector#

   rm-bx@  rm-es@  seg:off>  ( sector# adr )
   swap  rm-al@                             ( adr sector# #sectors )
   disk-read-sectors  rm-al!
;
: write-sectors  ( -- )
   check-drive  if  exit  then
   disk-ih  0=  if  rm-set-cf  h# aa rm-ah! exit  then
   rm-ch@  rm-cl@ 6 rshift  bwjoin  ( cylinder# )
   h# ff *   rm-dh@ +               ( trk# )     \ 255 heads
   h# 3f *  rm-cl@ h# 3f and 1-  +  ( sector# )  \ 63 is max sector#

   rm-bx@  rm-es@  seg:off>  ( sector# adr )
   swap  rm-al@                             ( adr sector# #sectors )
   disk-write-sectors  rm-al!
;
: drive-sectors  ( -- n )  " #blocks" disk-ih $call-method  ;
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

: ds:si  ( -- adr )  rm-esi@  rm-ds@  seg:off>  ;
: lba-read  ( -- )
   check-drive  if  exit  then
   ds:si  ( packet-adr )
   >r  r@ 4 + seg:off@  r@ 8 + l@   r@ 2+ w@     ( adr sector# #sectors )
\ ." LBA "
   disk-read-sectors  r> 2+ w!
;
: lba-write  ( -- )
   check-drive  if  exit  then
   ds:si  ( packet-adr )
   >r  r@ 4 + seg:off@  r@ 8 + l@   r@ 2+ w@     ( adr sector# #sectors )
\ ." LBA "
   disk-write-sectors  r> 2+ w!
;

: check-disk-extensions  ( -- )
   noshow
   check-drive  if  0 rm-bx! exit  then
   rm-bx@  h# 55aa <>  if  exit  then
   h# aa55 rm-bx!
   h# 20 rm-ah!  1 rm-cx!
;
: ext-get-drive-params  ( -- )
   noshow
   check-drive  if  exit  then
   0 rm-ah!
   ds:si  >r    ( adr )
   r@ 2 +  h# 0e  erase   \ CHS info not valid
   drive-sectors r@ h# 10 + l!  0 r@ h# 14 + l!  \ Total #sectors
   h# 200 r@ h# 18 + w!   \ Sector len
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

: disk-int  ( -- )  \ INT 13 handler
   rm-ah@ case
      h# 00  of  reset-disks            endof  \ Reset disk system
      h# 02  of  read-sectors           endof
      h# 03  of  write-sectors          endof
      h# 08  of  drive-params           endof
      h# 15  of  get-disk-type          endof
      h# 41  of  check-disk-extensions  endof
      h# 42  of  lba-read   endof
      h# 43  of  lba-write  endof
      h# 48  of  ext-get-drive-params  endof
      ( default )  ." Unsupported disk INT 13 - AH = " dup . cr
   endcase
;

: /1k  d# 10 rshift  ;
: bigmem-16bit  ( -- )
   memory-limit
   dup h# 100.0000  min  h# 10.0000 -  0 max  /1k  dup rm-ax!  rm-cx!
   h# 100.0000 -  0 max  d# 16 rshift  dup rm-bx!  rm-dx!
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

   h#      e0000. d,                h# 20000. d,  2 l,  \ 3c reserved
   h#     100000. d,                       0. d,  1 l,  \ 50 available
               0. d,                       0. d,  4 l,  \ 64 don't reclaim (yet)
   h#   fff00000. d,               h# 100000. d,  2 l,  \ 78 reserved (ROM)
here memdescs - constant /memdescs

: populate-memory-map  ( -- )
   memory-limit  h# 100000 -  memdescs h# 58 + l!  \ Size of memory above 1M
   memory-limit               memdescs h# 64 + l!  \ Base of firmware memory
   allmem memory-limit -      memdescs h# 6c + l!  \ Size of firmware memory
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
   rm-buf >seg:off  0 rm-es!  rm-bx! 
   0 rm-ax!
;

: handle-mouse  ( -- )
   rm-al@ case
      1 of  rm-clr-cf  endof   \ Reset mouse
      ( default )  ." Unsupported mouse INT 15 AH c2 AL " dup . cr   rm-set-cf
   endcase
;

: system-int  ( -- )  \ INT 15 handler
   noshow
   rm-clr-cf
   rm-ah@ case
      h# 91 of  noshow 0 rm-ah!  endof   \ "pause" while waiting for I/O
noop
      h# 53 of  apm  endof
      h# 86 of  rm-dx@  rm-cx@ wljoin us  endof  \ Delay microseconds
      h# 8a of  memory-limit h# 400.0000 - 0 max  /1k  lwsplit rm-dx! rm-ax!  endof
      h# 88 of  h# fffc rm-ax!  endof  \ Extended memory - at least 64 MB
      h# c0 of  get-conf  endof
      \ We use the extended BIOS data area as our workspace when loaded from another BIOS
\      h# c1 of  rm-set-cf h# 86 rm-ah!  endof  \ No extended BIOS data area
      h# c1 of  'ebda 4 rshift rm-es!  endof  \ Segment address of extended BIOS data area
      h# c2 of  handle-mouse  endof
      h# e8 of  bigmem-int  endof
\     h# e9 of  endof   \ Don't know what this is.  Ralf Brown's interrupt list says
\                       \ PhysTechSoft PTS ROM-DOS, but I doubt that is right
      ( default )  rm-set-cf
         ." Unsupported INT 15 AH=" dup . cr
   endcase
;

0 value the-key
0 value kbd-ih

: poll-key  ( -- false | scan,ascii true )
   the-key  ?dup  if  true exit  then
   d# 50 ms   \ I don't know why this is necessary, but without it, you don't see the key
   0 " get-scancode" kbd-ih $call-method  if    ( scancode )
      dup h# 80 and  if                         ( scancode )
         \ Discard release events and escapes (e0)
         drop false                             ( false )
      else
         dup " scancode->char" kbd-ih $call-method  0=  if  0  then  ( scancode ascii )
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
   polled?  0=  if  ." ? "  then
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

   rm-al@ [char] q =  if  debug-me  then
   false to polled?
;

: keyboard-int  ( -- )  \ INT 16 handler
   rm-ah@ case
      0 of  get-keystroke  endof
      1 of  poll-keystroke  endof
      2 of  noshow  0 rm-al!  endof  \ Claim that no shift keys are active
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
      h# 12  of  'ebda /1k rm-ax!  endof  \ Low memory size
      h# 1a  of  int-1a        endof
      h# 18  of  ." Entering Open Firmware" cr  interact    endof
      h# 19  of  ." Rebooting" cr  bye    endof
      h# 17  of  printer-int  endof
      h# 1c  of  noshow  0 dispatch-interrupt    endof  \ Timer bounce vector
      ( default )  ." Interrupt " dup . cr  interact
   endcase
   ?showint
;
' (handle-bios-call) to handle-bios-call

h# 7c00 constant mbr-base
: get-mbr  ( -- )
\   mbr-base h# 3f 1  disk-read-sectors 1 <> abort" Didn't read MBR"
   mbr-base 0 1  disk-read-sectors 1 <> abort" Didn't read MBR"
;

: make-bda  ( -- )
   h# 400 h# 200 erase
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
   d# 25 1- h# 484 c! \ Screen max row #
   d# 16   h# 485 w!  \ Character height
   h# 100.0000 h# 487 l!  \ Video RAM size

   1 'ebda w!         \ Size of EBDA in KiB
   \ 'ebda h# 3d +   ..  HD0 parameter table
   \ 'ebda h# 4d +   ..  HD1 parameter table
   1 'ebda h# 70 + c!   \ Number of hard disks
;

label bounce-timer  \ Redirect the timer interrupt through INT 1c
   16-bit
   ax   push
   h# 20 # ax mov
   al   h# 20 #  out
   ax   pop
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
   0 h# 82 w!  h# c0 h# 80 w!  \ CS = 0, IP = h# c0 = INT 30
;

: open-bios-disk  ( -- )
   disk-ih  if  exit  then
   disk-name open-dev to disk-ih
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

   " keyboard"   open-dev to kbd-ih
   populate-memory-map
;
: close-bios-disk  ( -- )  disk-ih close-dev   0 to disk-ih  ;
' close-bios-disk to quiesce-devices

: rm-go   ( -- )
   prep-rm
   rm-platform-fixup
   open-bios-disk
   get-mbr   \ Load boot image at 7c00
   usb-quiet
   mbr-base rm-run
;

: is-mbr?  ( adr len -- flag )
   h# 200 <>  if  drop false exit  then
   h# 1fe + w@  h# aa55 = 
;
: init-program  ( -- )
   loaded is-mbr?  if
      prep-rm
      load-base mbr-base h# 200 move
      exit
   then
   init-program
;

\ " rm-go"  ' boot-command  set-config-string-default
: execute-buffer  ( adr len -- )
   rm-prepped?  if      ( adr len )
      2drop             ( )
      usb-quiet         ( )
      mbr-base rm-run   ( )
      exit  \ Precautionary; rm-run shouldn't return
   then
   execute-buffer
;

0 0 " " " /" begin-package
   " xp" device-name
   : open
      " sd:1" open-dev  ?dup  0=  if  false exit  then  ( ih )
      >r
      load-base h# 200 " read" r@ $call-method          ( #read )
      r> close-dev
      h# 200 <>  if  false exit  then
      load-base 3 +  " NTFS    "  comp  if  false exit  then
      true
   ;
   : close ;
   \ Possible change: load at adr, then have init-program do all
   \ the other fixups (prep-rm) and move the MBR to mbr-base
   : load  ( adr -- 0 )
      open-bios-disk
      0 1  disk-read-sectors h# 200 *
   ;      
end-package

label xx  h# 99 # al mov  al h# 80 # out  begin again  end-code
here xx - constant /xx
: put-xx  ( adr -- )  xx swap /xx move  ;
: .lreg  ( adr -- adr' )  4 -  dup l@ 9 u.r   ;
: .wreg  ( adr -- adr' )  2 -  dup w@ 5 u.r   ;
: .caller-regs  ( -- )
   ."        AX       CX       DX       BX       SP       BP       SI       DI" cr
   caller-regs >rm-eax 4 +  8 0 do  .lreg  loop  cr
   cr
   ."    DS   ES   FS   GS       PC  FLAGS" cr
   4 0 do  .wreg  loop  
   drop
   rm-retaddr@ 9 u.r  2 spaces
   rm-flags@ 5 u.r cr
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
