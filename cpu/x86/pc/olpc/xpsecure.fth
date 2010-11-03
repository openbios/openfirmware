h# b00.0000 constant ramdisk-base

\ Create a new device node implementing a ramdisk device,
\ supporting the usual block device interface methods.

fload ${BP}/dev/ramdisk.fth
fload ${BP}/cpu/x86/pc/olpc/sba.fth

devalias ext-sba ext:0//secure-boot-area//zip-file-system
devalias int-sba int:0//secure-boot-area//zip-file-system

0 value ramdisk-ih  \ Instance handle for accessing ramdisk device

\ Setup the ramdisk driver as the INT 13 data source, from the data at adr,len
: xpsecure-place-ramdisk  ( adr len -- )
   " /ramdisk" open-dev to ramdisk-ih             ( adr len )

   \ Tell the ramdisk driver its actual size
   dup u>d  " set-size" ramdisk-ih $call-method   ( adr len )

   \ Copy in the data
   ramdisk-base swap move                         ( )

   \ Tell the BIOS INT 13 emulator code to use the ramdisk instead of the SD
[ifdef] two-bios-disks
   ramdisk-ih to bios-disk-ih0
[else]
   ramdisk-ih to bios-disk-ih
[then]
   h# 80 to bios-boot-dev#
;

h# 20000 constant ntldr-base  \ The address where NTLDR expects to be loaded

false value ntldr-prepped?
: is-ntldr?  ( adr len -- flag )
   h# 5000 <  if  drop false exit  then
   " NTLDR is corrupt" rot h# 5000 sindex -1 <>
;

warning @ warning off
: execute-buffer  ( -- )
   ntldr-prepped?  if
      \ set-mode3  \ Probably unnecessary as NTLDR does it internally
      visible
      init-regs ntldr-base rm-run          \ Start NTLDR in real mode
   then
   execute-buffer
;

: init-program  ( -- )
   loaded is-ntldr?  if
      prep-rm                                      \ Turn on BIOS emulation
      loaded ntldr-base swap move                  \ Move NTLDR to its execution address
      init-regs /rm-regs erase                     \ Setup the initial register values
      bios-boot-dev#  init-regs >rm-edx c!         \ DL must contain the boot device ID
      true to ntldr-prepped?                       \ Tell execute-buffer to execute NTLDR
      ['] xpsecure-place-ramdisk to place-ramdisk  \ Setup ramdisk preparation hook
      ['] load-ramdisk guarded                     \ Run ramdisk loader
      exit
   then
   init-program
;
warning !
