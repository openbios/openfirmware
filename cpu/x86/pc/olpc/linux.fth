\ See license at end of file
purpose: Linux bzImage program loading
[ifdef] olpc

\needs ramdisk  " disk:\boot\initrd.img" d# 128 config-string ramdisk

" disk:\boot\vmlinuz"   ' boot-device      set-config-string-default

" ro root=LABEL=OLPCRoot rootfstype=ext3 console=ttyS0,115200 console=tty0 fbcon=font:SUN12x22 pci=nobios video=gxfb:1024x768-16"  ' boot-file set-config-string-default

[else]

\needs ramdisk  " disk:\boot\initrd" d# 128 config-string ramdisk
" disk:\boot\vmlinuz"   ' boot-device      set-config-string-default
" console=ttyS0,115200 console=tty0 pci=nobios" ' boot-file set-config-string-default

[then]

0 value ramdisk-adr
0 value /ramdisk

0 [if]  \ From include/asm-i386/setup.h
#define PARAM	(boot_params)
#define SCREEN_INFO (*(struct screen_info *) (PARAM+0))
#define EXT_MEM_K (*(unsigned short *) (PARAM+2))
#define ALT_MEM_K (*(unsigned long *) (PARAM+0x1e0))
#define E820_MAP_NR (*(char*) (PARAM+E820NR))
#define E820_MAP    ((struct e820entry *) (PARAM+E820MAP))
#define APM_BIOS_INFO (*(struct apm_bios_info *) (PARAM+0x40))
#define IST_INFO   (*(struct ist_info *) (PARAM+0x60))
#define DRIVE_INFO (*(struct drive_info_struct *) (PARAM+0x80))
#define SYS_DESC_TABLE (*(struct sys_desc_table_struct*)(PARAM+0xa0))
#define EFI_SYSTAB ((efi_system_table_t *) *((unsigned long *)(PARAM+0x1c4)))
#define EFI_MEMDESC_SIZE (*((unsigned long *) (PARAM+0x1c8)))
#define EFI_MEMDESC_VERSION (*((unsigned long *) (PARAM+0x1cc)))
#define EFI_MEMMAP ((void *) *((unsigned long *)(PARAM+0x1d0)))
#define EFI_MEMMAP_SIZE (*((unsigned long *) (PARAM+0x1d4)))
#define MOUNT_ROOT_RDONLY (*(unsigned short *) (PARAM+0x1F2))
#define RAMDISK_FLAGS (*(unsigned short *) (PARAM+0x1F8))
#define VIDEO_MODE (*(unsigned short *) (PARAM+0x1FA))
#define ORIG_ROOT_DEV (*(unsigned short *) (PARAM+0x1FC))
#define AUX_DEVICE_INFO (*(unsigned char *) (PARAM+0x1FF))
#define LOADER_TYPE (*(unsigned char *) (PARAM+0x210))
#define KERNEL_START (*(unsigned long *) (PARAM+0x214))
#define INITRD_START (*(unsigned long *) (PARAM+0x218))
#define INITRD_SIZE (*(unsigned long *) (PARAM+0x21c))
#define EDID_INFO   (*(struct edid_info *) (PARAM+0x140))
#define EDD_NR     (*(unsigned char *) (PARAM+EDDNR))
#define EDD_MBR_SIG_NR (*(unsigned char *) (PARAM+EDD_MBR_SIG_NR_BUF))
#define EDD_MBR_SIGNATURE ((unsigned int *) (PARAM+EDD_MBR_SIG_BUF))
#define EDD_BUF     ((struct edd_info *) (PARAM+EDDBUF))

#define PARAM_SIZE 4096
#define COMMAND_LINE_SIZE 256

#define OLD_CL_MAGIC_ADDR	0x90020
#define OLD_CL_MAGIC		0xA33F
#define OLD_CL_BASE_ADDR	0x90000
#define OLD_CL_OFFSET		0x90022
#define NEW_CL_POINTER		0x228	/* Relative to real mode data */

\ From arch/i386/kernel/setup.c
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
h# 10.0000 constant linux-base
: code16-size  ( -- #bytes )   load-base h# 1f1 + c@ 1+  d# 512 *   ;
0 value cmdline-offset

\ Find the end of the largest piece of memory
: memory-limit  ( -- limit )
   " /memory" find-package 0= abort" No /memory node"  ( phandle )
   " reg" rot get-package-property abort" No available property"  ( $ )
   decode-int drop  decode-int  nip nip   ( n )
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
 /ramdisk 0<> h# 210 +lp  w!	\ loader type - set non0 to enable ramdisk info
\  h# 100000  h# 214 +lp  l!	\ kernel start - unused
 ramdisk-adr  h# 218 +lp  l!	\ initrd start
    /ramdisk  h# 21c +lp  l!	\ initrd size

[ifdef] notnow
   \ Put Open Firmware signature and IDT pointer in the params area
   " OFW " drop @  h# 7fc +lp l!   \ Validator for this area
   1               h# 7f8 +lp l!   \ Number of additional items (version#)
   idt drop        h# 7f4 +lp l!   \ So Linux can preserve our debug vectors
[then]

   \ Command line goes after the 16-bit wad
   ( cmdline$ ) add-root-dev
   ( cmdline$ ) cmdline-offset +lp  swap 1+  move
   h# a33f h# 20 +lp w!		\ Command line validator (magic number)
   cmdline-offset      h#  22 +lp  w!  \ Command line offset
   cmdline-offset +lp  h# 228 +lp  l!  \ New command line address
;

\ Add some entries to the GDT for Linux
: amend-gdt   ( -- )
   gdtr@ drop                        ( va )
   h# 0000.ffff over h# 20 + l!      ( va ) \ user 4 GB code at 0
   h# 00cf.fa00 over h# 24 + l!      ( va )
   h# 0000.ffff over h# 28 + l!      ( va ) \ user 4 GB data at 0
   h# 00cf.f200 over h# 2c + l!      ( va )

   \ For 2.5.x kernel
   h# 0000.ffff over h# 60 + l!      ( va ) \ user 4 GB code at 0
   h# 00cf.fa00 over h# 64 + l!      ( va )
   h# 0000.ffff over h# 68 + l!      ( va ) \ user 4 GB data at 0
   h# 00cf.f200 over h# 6c + l!      ( va )
   drop
;

: linux-fixup  ( -- )
[ifdef] linux-logo  linux-logo  [then]
   args-buf cscount set-parameters          ( )
   amend-gdt
   h# ff h# 21 pc!	\ Squelch the timer interrupt and others

   linux-base  linux-params  (init-program)
   linux-params to %esi

[ifdef] virtual-mode
\   h# c010.0000 to %eip  \ This is for ELF loading in virtual mode

   \ Incorporate a mapping for Open Firmware into Linux's page
   \ tables by copying our page table pointer into his page directory.
   fw-virt-base d# 20 rshift h# ffc and   ( ptp-offset )
   dup cr3@ + l@  swap %eip h# 1000 + +  !
[then]
;

: load-ramdisk  ( -- )
   " ramdisk" eval  dup 0=  if  2drop exit  then
   0 to /ramdisk
   ." Loading ramdisk image from " 2dup type  ."  ..."
   boot-read
   loaded to /ramdisk  to ramdisk-adr
   cr   
;

: claim-params  ( -- )
[ifdef] virtual-mode
   0 0 1meg -1 mmu-map     ( )		\ Make the parameter area accessible
[then]
   0 +lp  h# 1000 0 mem-claim drop      \ Play nice with memory reporting
   0 +lp  h# 1000  erase
;

[ifdef] elf-format-linux
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

warning @ warning off
: init-program  ( -- )
   false to linux-loaded?
   init-program
   linux-loaded?  if
      claim-params
      code16-size to cmdline-offset         \ Save in case we clobber load-base
      linux-fixup
   then
;
warning !
[then]

: init-bzimage?   ( -- flag )
   load-base h# 202 +  " HdrS"  comp  if  false exit  then

   claim-params
   code16-size to cmdline-offset         \ Save in case we clobber load-base

   load-base  0 +lp  code16-size  move   \ Copy the 16-bit stuff
   loaded code16-size /string  linux-base  swap  move  \ Copy the 32-bit stuff
   
   ['] load-ramdisk guarded

   linux-fixup
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

warning @ warning off
: help  ( -- )
   ." help-linux      Information about loading Linux." cr
   ." help-debug      Information about the debugger." cr
   cr
   ." More information: http://firmworks.com/QuickRef.html" cr
;
warning !
: help-linux  ( -- )
   ." BOOTING LINUX:" cr
   ."   boot <cmdline>          Load the OS, passing <cmdline> to kernel" mcr
   ."   boot                    Load the OS with <cmdline> from 'boot-file'" mcr
   ."   help-debug              Learn about the debugger" mcr
   ."   nvalias <name> <value>  Set a device alias.  Example: nvalias disk a" mcr
   mcr
   ." CONFIGURATION VARIABLES FOR LINUX:" mcr
   ."   boot-device    Kernel pathname.      Example: disk:\vmlinuz" mcr
   ."   boot-file      Default command line. Example: console=ttyS0,115200" mcr
   ."   ramdisk        initrd pathname.      Example: disk:\initrd.imz" mcr
   mcr
   ." MANAGING CONFIGURATION VARIABLES:" mcr
   ."   printenv [ <name> ]     Show configuration variables" mcr
   ."   setenv <name> <value>   Set configuration variable" mcr
   ."   editenv <name>          Edit configuration variable" mcr
   mcr
   ." MORE INFORMATION: http://www.firmworks.com/QuickRef.html" mcr
;

0 [if]

: linux  ( "cmdline" -- )
   load-ramdisk
   load
   ." Linux start address at " %eip u. cr
   ." Type 'go' to start it or 'help-debug' to see debugger commands." cr
;

\ " load_ramdisk=1 root=/dev/ram0 console=/dev/ttyS0,9600 console=/dev/tty0"


: uint8_t  ( offset -- offset' )
   create dup , /c +  does> @ the-struct + c@  ( b )
;
: uint16_t  ( offset -- offset' )
   create dup , /w +  does> @ the-struct + w@  ( w )
;
: uint32_t  ( offset -- offset' )
   create dup , /l +  does> @ the-struct + l@  ( l )
;
: uint8s   ( offset size -- offset' )  sfield  ;

: reserved  + ;
: ends-at  ( offset n -- )  nip  ;
struct \ x86_linux_header
        h# 1f1   reserved			\ 0x000
	uint8_t  setup_sects		        \ 0x1f1
	uint16_t root_flags			\ 0x1f2
	uint16_t syssize			\ 0x1f4
	uint16_t swapdev			\ 0x1f6
	uint16_t ramdisk_flags			\ 0x1f8
	uint16_t vid_mode			\ 0x1fa
	uint16_t root_dev			\ 0x1fc
	uint16_t boot_sector_magic		\ 0x1fe
	\ 2.00+
	2        reserved			\ 0x200
	4 uint8s header_magic			\ 0x202
	uint16_t protocol_version		\ 0x206
	uint32_t realmode_swtch			\ 0x208
	uint16_t start_sys			\ 0x20c
	uint16_t kver_addr			\ 0x20e
	uint8_t  type_of_loader			\ 0x210
	uint8_t  loadflags			\ 0x211
	uint16_t setup_move_size		\ 0x212
	uint32_t code32_start			\ 0x214
	uint32_t ramdisk_image			\ 0x218
	uint32_t ramdisk_size			\ 0x21c
	4        reserved      			\ 0x220
	\ 2.01+
	uint16_t heap_end_ptr			\ 0x224
	2        reserved			\ 0x226
	\ 2.02+
	uint32_t cmd_line_ptr			\ 0x228
	\ 2.03+
	uint32_t initrd_addr_max		\ 0x22c
[ifdef] TENATIVE
	\ 2.04+
	uint16_t entry32_off			\ 0x230
	uint16_t internal_cmdline_off		\ 0x232
	uint32_t low_base			\ 0x234
	uint32_t low_memsz			\ 0x238
	uint32_t low_filesz			\ 0x23c
	uint32_t real_base			\ 0x240
	uint32_t real_memsz			\ 0x244
	uint32_t real_filesz			\ 0x248
	uint32_t high_base			\ 0x24C
	uint32_t high_memsz			\ 0x250
	uint32_t high_filesz			\ 0x254
        0 field  tail				\ 0x258
[else]
        0 field  tail				\ 0x230
[then]
	d# 32  d# 1024 *  ends-at

constant /x86-linux-header

\ Not used, but possibly interesting to know
: kernel-version  ( -- cstr )  load-base d# 512 +  kver_addr +  ;

Where stuff wants to load:

16-bit segment at h#  9.0000
32-bit segment at h# 10.0000
ramdisk        at h# 80.0000

command line goes in 16-bit segment at command_line_off (first location after kern16_size)
start16 code goes in 16-bit segment at setup16_off
start32 code goes in 16-bit segment at setup32_off

h# 90000 constant rm-seg
h# 10.0000 constant seg32
: +rm  ( n -- adr )  rm-seg +  ;

: setup-linux  ( -- )
   XXX need descriptors at GDT 60 and 68

   load-base rm-seg  kern16-size move  \ Copy real-mode code

   cmdline  kern16-size +rm  swap 1+  move  \ Copy command line
   h# a33f  h# 20 +rm  w!    \ CL_MAGIC_VALUE -> cl_magic
   kern16-size  h# 22  w!    \ cl_offset

   protocol_version h# 0202 >=   if
      kern16-size +rm  h# 228 +rm l!
   then

   h# ff  h# 210 +rm  c!  \ LOADER_TYPE_UNKNOWN

   \ XXX ramdisk must have been copied to h# 800000 already
   ramdisk  h# 21c +rm l!  h# 218 l!   \ address and length

   0 to %eax      0 to %ebx  0 to %ecx      0 to %edx
   0 +rm to %esi  0 to %edi  0 +rm to %esp  seg32 to %eip

   loaded kern16-size /string  seg32  swap  move

   set-fb-info
   set-mem-info
;


What x86-setup-32.S does:

finds the actual address of its data structures because
it has been loaded at somewhere other than its link address

calls x86_setup_state  (might be unnecessary)

Load a GDT with
  0 - pointer to GDT
  0x10  4GB flat code segment
  0x18  4GB flat data segment
  0x60  4GB flat code segment
  0x68  4GB flat data segment
  .. other descriptors empty

  sets CS to 0x10
  sets DS,ES,SS,FS,GS to 0x18

  loads the general registers with values from the array
  jumps to the eip from the array

[then]
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
