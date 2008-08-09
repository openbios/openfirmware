\ See license at end of file
purpose: Linux bzImage program loading

\ Example boot configuration variable settings:

\ Example default values for a system that boots primarily from hard disk:

\ \needs ramdisk  " disk:\boot\initrd.img" d# 128 config-string ramdisk
\ " ro root=LABEL=OLPCRoot rootfstype=ext3 console=ttyS0,115200 console=tty0"
\   ' boot-file set-config-string-default
\ " disk:\boot\vmlinuz"   ' boot-device      set-config-string-default

\ Example default values for a system that boots primarily from JFFS2 on NAND:

\ " nand:\boot\vmlinuz"   ' boot-device      set-config-string-default
\ " ro root=mtd0 rootfstype=jffs2 console=ttyS0,115200 console=tty0"
\   ' boot-file set-config-string-default

0 value ramdisk-adr
0 value /ramdisk

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
h# 10.0000 value linux-base
: code16-size  ( -- #bytes )   load-base h# 1f1 + c@ 1+  d# 512 *   ;
0 value cmdline-offset

\ Find the end of the largest piece of memory
: memory-limit  ( -- limit )
   " /memory" find-package 0= abort" No /memory node"  ( phandle )
   " available" rot get-package-property abort" No memory node available property"  ( $ )
   \ Find the memory piece that starts at 1 Meg
   begin  dup  8 >=  while           ( $ )
      decode-int  h# 10.0000 =  if   ( $ )   \ Found the one we want
         decode-int h# 10.0000 +     ( $ limit )
         nip nip  exit
      then                           ( $ )
      decode-int drop                ( $ )
   repeat                            ( $ )
   2drop true abort" No suitable memory piece"
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
 /ramdisk 0<> h# 210 +lp  c!	\ loader type - set non0 to enable ramdisk info
\  h# 100000  h# 214 +lp  l!	\ kernel start - unused
 ramdisk-adr  h# 218 +lp  l!	\ initrd start
    /ramdisk  h# 21c +lp  l!	\ initrd size

   \ Put Open Firmware signature and IDT pointer in the params area
   " OFW " drop @  h# b0 +lp l!   \ Validator for this area
   1               h# b4 +lp l!   \ Number of additional items (version#)
   cif-handler     h# b8 +lp l!   \ Client interface handler
   idt drop        h# bc +lp l!   \ So Linux can preserve our debug vectors

   \ Command line goes after the 16-bit wad
   ( cmdline$ ) add-root-dev
   ( cmdline$ ) cmdline-offset +lp  swap 1+  move
   h# a33f h# 20 +lp w!		\ Command line validator (magic number)
   cmdline-offset      h#  22 +lp  w!  \ Command line offset
   cmdline-offset +lp  h# 228 +lp  l!  \ New command line address
;

\ If we are running in physical address mode, make a page directory
\ that will map up when the kernel turns on paging.
: v=p-pde  ( adr -- )
   dup h# 83 or  cr3@  rot d# 22 rshift la+  l!
;
: make-ofw-pdir  ( -- )
   cr3@  if  exit  then
   h# 1000  h# 1000  mem-claim cr3!
   cr3@  h# 1000 erase
   fw-map-limit fw-map-base  do  i v=p-pde  h# 40.0000 +loop
   cr4@  h# 10 or  cr4!
;

: linux-fixup  ( -- )
[ifdef] linux-logo  linux-logo  [then]
   args-buf cscount set-parameters          ( )
   h# ff h# 21 pc!	\ Squelch the timer interrupt and others

   linux-base  linux-params  (init-program)
   linux-params to %esi
   make-ofw-pdir
;

d# 256 buffer: ramdisk-buf
' ramdisk-buf  " ramdisk" chosen-string

defer load-ramdisk
: $load-ramdisk  ( name$ -- )
   0 to /ramdisk                                  ( name$ )

   ['] load-path behavior >r                      ( name$ r: xt )
   ['] ramdisk-buf to load-path                   ( name$ r: xt )

   ." Loading ramdisk image from " 2dup type  ."  ..."  ( name$ r: xt )
   ['] boot-read catch                            ( throw-code r: xt )
   cr                                             ( throw-code r: xt )
   r> to load-path                                ( throw-code )
   throw
   loaded to /ramdisk  to ramdisk-adr
;
: cv-load-ramdisk  ( -- )
   " ramdisk" eval  dup 0=  if  2drop exit  then  ( name$ )
   $load-ramdisk
;
' cv-load-ramdisk to load-ramdisk

: claim-params  ( -- )
[ifdef] virtual-mode
   0 0 1meg -1 mmu-map     ( )		\ Make the parameter area accessible
[then]
   0 +lp  h# 1000 0 mem-claim drop      \ Play nice with memory reporting
   0 +lp  h# 1000  erase
;

0 value linux-loaded?

: ?linux-elf-map-in  ( va size -- )
   \ The Linux startup code really wants the physical address to be
   \ virtual_address AND 0x0fff.ffff.  We recognize Linux by the virtual
   \ address range that it uses (0xc0xx.xxxx)
   over h# f000.0000 and  h# c000.0000 =  if
      h# 40.0000 to linux-base
      h# 800 to cmdline-offset
      true to linux-loaded?
      over  h# 0fff.ffff and   ( va size pa )
      -rot -1                  ( pa va size mode )
      mmu-map
      exit
   then
   (elf-map-in)
;
' ?linux-elf-map-in is elf-map-in

: init-bzimage?   ( -- flag )
   loaded                               ( adr len )
   h# 202 /string                       ( adr' len' )
   4 <  if  drop false exit  then       ( adr )
   " HdrS"  comp  if  false exit  then  ( )
   h# 10.0000 to linux-base
   code16-size to cmdline-offset         \ Save in case we clobber load-base
   load-base  0 +lp  code16-size  move   \ Copy the 16-bit stuff
   loaded code16-size /string  linux-base  swap  move  \ Copy the 32-bit stuff
   true to linux-loaded?
   true
;

warning @ warning off
: init-program  ( -- )
   init-bzimage?  if  exit  then
   init-program
;

: sym  ( "name" -- adr )
   parse-word  $sym>  0=  if  err-sym-not-found throw  then
;
warning !

warning @ warning off
: init-program  ( -- )
   false to linux-loaded?
   init-program
   linux-loaded?  if
      claim-params
      ['] load-ramdisk guarded
      linux-fixup
   then
;
warning !

: mcr  ( -- )  cr exit? throw  ;
: help-debug  ( -- )
   red-letters
   ." Debugging the Linux kernel requires a few patches to keep Linux from"  mcr
   ." overwriting the firmware debug vector."  mcr mcr
   black-letters

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
   ." More information: http://firmworks.com/QuickRef.html" cr
;

d# 34 to default-#lines

warning @ warning off
: help  ( -- )
   blue-letters  ." UPDATES:" black-letters  mcr
   ."   flash u:\q2c18.rom              Rewrite the firmware from USB key" mcr
   ."   flash nand:\q2c18.rom           Rewrite the firmware from NAND file" mcr
   ."   copy-nand u:\boot\nand290.img   Rewrite the OS on NAND from USB key" mcr
   mcr
   blue-letters  ." DIRECTORY LISTING:" black-letters  mcr
   ."   dir u:\               List USB key root directory" mcr
   ."   dir u:\boot\          List USB key /boot directory" mcr
   ."   dir nand:\boot\       List NAND FLASH /boot directory" mcr
   ."   dir nand:\boot\*.rom  List .rom files in NAND FLASH /boot directory" mcr
   mcr
   blue-letters  ." BOOTING:" black-letters  mcr
   ."   boot                  Load the OS from list of default locations" mcr
   ."                         'printenv boot-device' shows the list" mcr
   ."   boot <cmdline>        Load the OS, passing <cmdline> to kernel" mcr
   ."   boot u:\boot\vmlinuz  Load the OS from a specific location" mcr
   mcr
   blue-letters  ." CONFIGURATION VARIABLES FOR BOOTING:" black-letters  mcr
   ."   boot-device  Kernel or boot script path.  Example: nand:\boot\olpc.fth" mcr
   ."   boot-file    Default cmdline.    Example: console=ttyS0,115200" mcr
   ."   ramdisk      initrd pathname.    Example: disk:\boot\initrd.imz" mcr
   mcr
   blue-letters  ." MANAGING CONFIGURATION VARIABLES:" black-letters  mcr
   ."   printenv [ <name> ]     Show configuration variables" mcr
   ."   setenv <name> <value>   Set configuration variable" mcr
   ."   editenv <name>          Edit configuration variable" mcr
   mcr
   blue-letters  ." DIAGNOSTICS:" black-letters  mcr
   ."   test <device-name>      Test device.  Example: test mouse" mcr
   ."   test-all                Test all devices that have test routines" mcr
   mcr
   ." More information: "
   green-letters  ." http://wiki.laptop.org/go/OFW_FAQ" black-letters  cr
;
warning !


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
