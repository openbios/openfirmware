\ This program creates a bootable 1.44 MB floppy disk image with an
\ initially-empty FAT12 filesystem.
\ The FATs begin at sector 2.  Sectors 0 and 1 contain a simple
\ FAT filesystem reader that uses INT 13 to load the file "\OFW.IMG"
\ into memory, then jumps to it.

hex

d# 512 constant /sector
/sector buffer: sector-buf

create ofw-boot-sectors
  " ${BP}/cpu/x86/pc/biosload/build/bootsec.img" $file,
here ofw-boot-sectors - constant /ofw-boot-sectors

: make-floppy-image  ( -- )
   " floppy.img" $new-file

   \ Write boot sectors
   ofw-boot-sectors /ofw-boot-sectors ofd @ fputs

   \ Init FATs
   sector-buf /sector erase

   \ BPB offset h#10.b is NumFATCopies
   ofw-boot-sectors h# 10 + c@  0  ?do  \ Loop over number of FATs
      h# 00fffff0 sector-buf le-l!      \ First FAT12 entry
      sector-buf /sector ofd @ fputs
      0 sector-buf le-l!

      \ BPB offset h#16.w is SectorsPerFAT
      ofw-boot-sectors h# 16 + le-w@  1-  0  ?do  \ Remainder of FAT
         sector-buf /sector ofd @ fputs
      loop
   loop

   \ Init root directory
   \ BPB offset h#11.w is RootDirEntries.  Each entry is h#20 bytes.
   ofw-boot-sectors h# 11 + le-w@      ( #root-dir-entries )
   h# 20 *                             ( root-dir-bytes )
   /sector /  0  ?do                  \ Loop over root dir sectors
      sector-buf /sector ofd @ fputs
   loop

   \ Zero the rest of the floppy image
   ofw-boot-sectors h# 13 + le-w@      ( total#sectors )
   /sector *  ofd @ fsize  ?do
      sector-buf /sector ofd @ fputs
   /sector +loop

   ofd @ fclose
   ." Open Firmware bootable floppy image created as floppy.img ." cr
   ." Loopback-mount it and copy OFW.IMG to it." cr
;
make-floppy-image
