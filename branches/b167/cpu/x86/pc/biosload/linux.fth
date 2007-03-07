\ See license at end of file
\ Linux startup hacks

h# 80.0000 value ramdisk-adr  0 value /ramdisk

[ifdef] use-vga
\ Get an ihandle for the screen device, if possible.

\needs screen-ih  0 value screen-ih
: ?open-screen  ( -- )
   screen-ih  0=  if
     " device_type"  stdout @ ihandle>phandle  get-package-property  if
        false
     else                                   ( prop-adr,len )
        get-encoded-string  " display" $=   ( flag )
     then                                   ( flag )
     if  stdout @  else  " screen" open-dev  then  to screen-ih
   then
   screen-ih 0=  abort" Can't open display"
;

\ Put the display, if any, in VGA text mode because the Linux startup
\ code writes debugging messages to it, assuming it's already in text mode.
: vga-text  ( -- )
   ['] ?open-screen  catch  if  exit  then
   screen-ih stdout @ =  if  install-uart-io   then  ['] cancel is light
   " text-mode3" screen-ih  $call-method
;
[then]

0 [if]  \ From arch/i386/kernel/setup.c
#define PARAM	((unsigned char *)empty_zero_page)
#define SCREEN_INFO (*(struct screen_info *) (PARAM+0))
#define EXT_MEM_K (*(unsigned short *) (PARAM+2))
#define ALT_MEM_K (*(unsigned long *) (PARAM+0x1e0))
#define E820_MAP_NR (*(char*) (PARAM+E820NR))
#define E820_MAP    ((struct e820entry *) (PARAM+E820MAP))
#define APM_BIOS_INFO (*(struct apm_bios_info *) (PARAM+0x40))
#define DRIVE_INFO (*(struct drive_info_struct *) (PARAM+0x80))
#define SYS_DESC_TABLE (*(struct sys_desc_table_struct*)(PARAM+0xa0))
#define MOUNT_ROOT_RDONLY (*(unsigned short *) (PARAM+0x1F2))
#define RAMDISK_FLAGS (*(unsigned short *) (PARAM+0x1F8))
#define ORIG_ROOT_DEV (*(unsigned short *) (PARAM+0x1FC))
#define AUX_DEVICE_INFO (*(unsigned char *) (PARAM+0x1FF))
#define LOADER_TYPE (*(unsigned char *) (PARAM+0x210))
#define KERNEL_START (*(unsigned long *) (PARAM+0x214))
#define INITRD_START (*(unsigned long *) (PARAM+0x218))
#define INITRD_SIZE (*(unsigned long *) (PARAM+0x21c))
#define COMMAND_LINE ((char *) (PARAM+2048))
#define COMMAND_LINE_SIZE 256

#define RAMDISK_IMAGE_START_MASK  	0x07FF
#define RAMDISK_PROMPT_FLAG		0x8000
#define RAMDISK_LOAD_FLAG		0x4000	
[then]

create screen-info   \ See struct screen_info in include/linux/tty.h
   0 c,     \  0 x position
   0 c,     \  1 y position
   0 w,     \  2 plug in memory size here
   0 w,     \  4 video page
   0 c,     \  6 video mode - 7 means monochrome, anything else is color
   d# 80 c, \  7 columns
   0 w,     \  8 unused
   0 w,     \  a ega_bx - anything but 0x10
   0 w,     \  c unused
   d# 25 c, \  e lines
   0 c,     \  f isVGA?
   d# 16 w, \ 10 font height
here screen-info - constant /screen-info

h# 9.0000 constant linux-params
: memory-limit  ( -- limit )
   " /memory" find-package 0= abort" No /memory node"  ( phandle )
   " available" rot get-package-property abort" No available property"  ( $ )
   -1 >r                              ( $ )  ( r: limit )
   begin  dup 0>  while               ( $ )
      decode-int >r decode-int  r> +  ( $ piece-end )
      dup 1meg u<=  if  drop   else   ( $ piece-end )
         r> umin >r                   ( $ )  ( r: limit' )
      then                            ( $ )
   repeat                             ( $ )
   2drop  r>                          ( limit )
;

d# 20 constant /root-dev-buf
/root-dev-buf buffer: root-dev-buf

: make-root-dev$    ( idx -- root-dev$ )
   root-dev-buf /root-dev-buf 0 fill
   "  root=/dev/hda" rot
   1+ base @ >r d# 10 base ! (.) r> base !
   $cat2
   2dup 2>r root-dev-buf swap move
   2r> free-mem
   root-dev-buf /root-dev-buf
;
: +lp  ( offset -- adr )  linux-params +  ;
0 [if]
: add-root-dev ( cmdline$ -- cmdline$' )
   2>r " root=" 2r@ sindex -1 =  if
      2r>
      " disk:root,\" $partition-idx dup -1 <>  if
         make-root-dev$ $cat2
      else
         drop
      then
   else
      2r>
   then
;
[else]
: add-root-dev  ( cmdline$ -- cmdline$' )
;
[then]

: set-parameters  ( cmdline$ -- )
   linux-params h# 1000 0 mem-claim drop

   linux-params  d# 2048 d# 256 +   erase

   screen-info  linux-params  /screen-info  move  \ Ostensibly screen info

   memory-limit ( #bytes )
   d# 1023 invert and  d# 1024 /  ( #kbytes )
   d# 1024 -  h# 002 +lp  w!	\ Kbytes of extended (not the 1st meg) memory

   memory-limit ( #bytes )
   d# 1023 invert and  d# 1024 /  ( #kbytes )
   d# 1024 -  h# 1e0 +lp  l!    \ Alternate amount of extended memory

           0  h# 1f2 +lp  w!	\ root flags - non0 to mount root read-only
           0  h# 1f8 +lp  w!	\ Ramdisk flags

\ 301 for /dev/hda,  100 for /dev/ram0,  0 for nothing (set it from cmdline)
\      h# 301  h# 1fc +lp  w!	\ root_dev - see init/main.c:parse_root_dev
\      h# 100  h# 1fc +lp  w!	\ root_dev - see init/main.c:parse_root_dev
       h#   0  h# 1fc +lp  w!	\ root_dev - see init/main.c:parse_root_dev

           0  h# 1ff +lp  c!	\ Aux device - set to AA if PS2 mouse present
 /ramdisk 0<> h# 210 +lp  w!	\ loader type - set non0 to enable ramdisk info
\  h# 100000  h# 214 +lp  l!	\ kernel start - unused
 ramdisk-adr  h# 218 +lp  l!	\ initrd start
    /ramdisk  h# 21c +lp  l!	\ initrd size

   \ Put Open Firmware signature and IDT pointer in the params area
   " OFW " drop @  h# 7fc +lp l!   \ Validator for this area
   1               h# 7f8 +lp l!   \ Number of additional items (version#)
   idt drop        h# 7f4 +lp l!   \ So Linux can preserve our debug vectors

   \ Command line goes at h# 9.0800 for 0x100 bytes
   ( cmdline$ ) add-root-dev
   ( cmdline$ )  h# 800 +lp  swap  move
   h# a33f h# 20 +lp w!		\ Command line validator (magic number)
   h#  800 h# 22 +lp w!		\ Command line offset
;

\ Add some entries to the GDT for Linux
: amend-gdt   ( -- )
   gdtr@ drop                        ( va )
   h# 0000.ffff over h# 20 + l!      ( va ) \ user 4 GB code at 0
   h# 00cf.fa00 over h# 24 + l!      ( va )
   h# 0000.ffff over h# 28 + l!      ( va ) \ user 4 GB data at 0
   h# 00cf.f200 over h# 2c + l!      ( va )
   drop
;

: linux-fixup  ( -- )
[ifdef] linux-logo  linux-logo  [then]
[ifdef] use-vga
   vga-text                ( )
[then]
   0 0 1meg -1 mmu-map     ( )		\ Make the parameter area accessible
   args-buf cscount set-parameters          ( )
   amend-gdt
   h# ff h# 21 pc!	\ Squelch the timer interrupt and others
   linux-params to %esi
   h# c010.0000 to %eip

   \ Incorporate a mapping for Open Firmware into Linux's page
   \ tables by copying our page table pointer into his page directory.
   fw-virt-base d# 20 rshift h# ffc and   ( ptp-offset )
   dup cr3@ + l@  swap %eip h# 1000 + +  !
;

0 value linux-loaded?
: ?linux-elf-map-in  ( va size -- )
   \ The Linux startup code really wants the physical address to be
   \ virtual_address AND 0x0fff.ffff.  We recognize Linux by the virtual
   \ address range that it uses (0xc0xx.xxxx)
   over h# f000.0000 and  h# c000.0000 =  if
      true to linux-loaded?
      over  h# 0fff.ffff and   ( va size pa )
      -rot -1                  ( pa va size mode )
      mmu-map
      exit
   then
   (elf-map-in)
;
' ?linux-elf-map-in is elf-map-in

: init-program  ( -- )
   false to linux-loaded?
   init-program
   linux-loaded?  if  linux-fixup  then
;

\ When debugging the Linux startup code using the screen for both
\ the firmware console device and the Linux startup messages, Linux
\ eventually scrolls the firmware interaction area completely out
\ of view.  Typing ^r at the ok prompt restores the firmware area
\ to the viewscreen, and typing it again toggles back and forth between
\ the scrolled (Linux) and unscrolled (firmware) views.

: crt@  ( index -- byte )  h# 3d4 pc!  h# 3d5 pc@  ;
: crt!  ( byte index -- )  h# 3d4 pc!  h# 3d5 pc!  ;
: scroll@  ( -- n )  h# d crt@  h# c crt@  bwjoin  ;
: scroll!  ( n -- )  wbsplit h# c crt!  h# d crt!  ;

also keys-forth definitions
: ^r scroll@  if  0 scroll!  else  h# 7d0 scroll!  then  ;
previous definitions

: sym  ( "name" -- adr )
   parse-word  $sym>  0=  if  err-sym-not-found throw  then
;

\needs ramdisk  " " d# 128 config-string ramdisk

: load-ramdisk  ( -- )
   ramdisk  dup 0=  if  2drop exit  then
   ." Loading ramdisk image from " 2dup type  ."  ..."
   boot-read
   loaded to /ramdisk  ramdisk-adr /ramdisk move
   cr   
;

: mcr  ( -- )  cr exit? throw  ;
: help-debug  ( -- )
   ." COMMAND   STACK EFFECT   DESCRIPTION" mcr
   ." .registers  ( -- )       Display registers" mcr
   ." go          ( -- )       Resume execution" mcr
   ." step        ( -- )       Single-step" mcr
   ." ^T          ( -- )       (Control-T) Keystroke shortcut for 'step'" mcr
   ." steps       ( n -- )     Single-step n times" mcr
   ." hop         ( -- )       Step over subroutine calls" mcr
   ." hops        ( n -- )     Hop n times" mcr
   ." dis         ( addr -- )  Disassemble starting at given address" mcr
   ." +dis        ( -- )       Continue disassembling" mcr
   ." bp          ( addr -- )  Set breakpoint at given address" mcr
   ." till        ( addr -- )  Set breakpoint at given address and go" mcr 
   ." -bp         ( addr -- )  Delete breakpoint at given address" mcr 
   ." --bp        ( -- )       Delete last breakpoint" mcr
   ." .bp         ( -- )       Show breakpoints" mcr
   ." return      ( -- )       Finish execution of current subroutine"  mcr
   ." finish-loop ( -- )       Finish execution of current loop"  mcr
   ." %eax        ( -- n )     Push EAX (etc.) register value on stack" mcr
   ." %eip        ( -- n )     Push EIP register value on stack" mcr
   ." %pc         ( -- n )     Same as %eip" mcr
   ." to %eax     ( n -- )     Set EAX (etc.) register value from stack" mcr
   ." to %eip     ( n -- )     Set EIP register value from stack" mcr
   ." sym <name>  ( -- n )     Push value of named kernel symbol on stack" mcr
   ." .adr        ( n -- )     Display symbol name closest to n" mcr
   ." Examples: " mcr
   ."    %pc dis            Disassemble starting at program counter" mcr
   ."    %ebx u.            Display saved value of EBX register" mcr
   ."    step               Single step once" mcr
   ."    10 hops            Step 10 times, don't go down into subroutines" mcr
   ."    1234 to %ebp       Set EBP register to (hex) 1234" mcr
   ."    sym kbd_init dis   Disassemble starting at kbd_init" mcr
   ."    sym kbd_init till  Set breakpoint at kbd_init and go" mcr
   ."    %pc 5 +  to %pc    Add 5 to the program counter register" mcr

   mcr
   ." More information: http://www.firmworks.com/QuickRef.html" cr
;

: help  ( -- )
   ." help-linux      Information about loading Linux." cr
   ." help-debug      Information about the debugger." cr
   cr
   ." More information: http://www.firmworks.com/QuickRef.html" cr
;
: help-linux  ( -- )
   ." BOOTING LINUX:" cr
   ."   linux <cmdline>         Load Linux, passing <cmdline> to kernel" mcr
   ."   linux                   Load Linux with <cmdline> from 'boot-file'" mcr
   ."   go                      Execute loaded kernel" mcr
   ."   help-debug              Learn about the debugger" mcr
   ."   nvalias <name> <value>  Set a device alias.  Example: nvalias disk a" mcr
   mcr
   ." CONFIGURATION VARIABLES FOR LINUX:" mcr
   ."   boot-device    Kernel pathname.      Example: disk:\vmlinuz" mcr
   ."   boot-file      Default command line. Example: console=ttyS0,9600" mcr
   ."   ramdisk        initrd pathname.      Example: disk:\initrd.imz" mcr
   mcr
   ." MANAGING CONFIGURATION VARIABLES:" mcr
   ."   printenv [ <name> ]     Show configuration variables" mcr
   ."   setenv <name> <value>   Set configuration variable" mcr
   ."   editenv <name>          Edit configuration variable" mcr
   mcr
   ." MORE INFORMATION: http://www.firmworks.com/QuickRef.html" mcr
;

: linux  ( "cmdline" -- )
   load-ramdisk
   load
   ." Linux start address at " %eip u. cr
   ." Type 'go' to start it or 'help-debug' to see debugger commands." cr
;

\ " load_ramdisk=1 root=/dev/ram0 console=/dev/ttyS0,9600 console=/dev/tty0"
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
