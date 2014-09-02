purpose: Macintosh partition map decoder
\ See license at end of file

\ MacOS HFS
struct  ( mac-partition )
   /w field >part-magic
   2 +				\ Reserved
   /l field >mp-#pm-blks	\ # of blocks in the partition map
   /l field >mp-blk0		\ first logical block number for partition
   /l field >mp-#blks		\ # of blocks in the partition
   d# 32 field >mp-part-name
   d# 32 field >mp-part-type
   /l field >mp-dblk0		\ Offset in blocks to first data block
   /l field >mp-#dblks		\ Number of data blocks
   /l field >mp-status		\ Flags
   /l field >mp-bblk0		\ Offset in blocks to first boot block
   /l field >mp-/boot		\ Size in bytes of boot area
   /l field >mp-boot-load	\ Load address of boot code
   /l +				\ Reserved
   /l field >mp-boot-entry	\ Entry address of boot code
   /l +				\ Reserved
   /l field >mp-boot-sum	\ Checksum of boot code
   \ d# 16 field >mp-proctype   \ Processor type
drop

0 value /mac-block
0 value mac-partition-sector
: get-mac-partition-info  ( -- )
   \ XXX we need to think about the boot area
   sector-buf >mp-blk0 be-l@  sector-buf >mp-dblk0 be-l@  +  to sector-offset
   sector-buf >mp-#dblks be-l@      ( #sectors )
   /mac-block um*  to size-high  to size-low
;

: default-mac?  ( -- flag )
   \ If a file name (or directory name) is supplied, and it
   \ is not "%BOOT", we don't want to select the first bootable
   \ partition, because bootable partitions often contain nothing
   \ but SCSI device drivers.  Instead, we look for a partition
   \ with a file system on it.
   filename nip 0=  filename " %BOOT" $=  or  if
      \ Find the first bootable partition
      \ Readable(10), bootable(8), allocated(2), valid(1)
      sector-buf >mp-status be-l@  h# 1b and  h# 1b =  if  true exit  then
   else
      \ Find the first readable, allocated, valid partition
      \ of type "Apple_HFS"
      sector-buf >mp-status be-l@  h# 13 and  h# 13 =  if
         sector-buf >mp-part-type  " Apple_HFS" comp  0=  if  true exit  then
      then
   then
   false
;

: find-mac-partition  ( criterion-xt -- error? )
   to suitable?

   \ XXX search for a Mac partition whose "valid" flag is set.
   \ The 0x01 status bit is "valid?"  The 0x08 status bit is "bootable?"
   \ If one is found, set partition-type, size-high, size-low, and
   \ sector-offset and return false.

   \ Get the partition entry that describes the partition map as a whole
   1 read-sector
   sector-buf >part-magic be-w@ h# 504d  <>  if  true exit  then

   1  sector-buf >mp-#pm-blks be-l@    ( first-block #partition-map-blocks )
   bounds  ?do                         ( )
      i to mac-partition-sector
      i 1 <>  if  i read-sector  then   \ Already read sector 1
      sector-buf >mp-status be-l@  1 and  if               \ Valid?
         suitable?  if  get-mac-partition-info  false  unloop  exit  then
      then
   loop                                            ( )
   true
;

: mac-map  ( -- )
   #part  -1 =  if		\ Find the default bootable partition
      ['] default-mac?  find-mac-partition  0=  if  exit  then
      \ Failing to find a suitable default partition, use the first valid one
      1 to #part
   then
   ['] nth? find-mac-partition abort" No such MAC partition"
;

2 buffer: hfs-magic
: hfs-partition?  ( -- flag )
   h# 400 0  offset  " seek" $call-parent drop  ( )
   hfs-magic 2  " read" $call-parent            ( #read )
   \ Re-establish initial position
   0 0 offset  " seek" $call-parent drop        ( #read )

   2 <>  if  false  exit  then
   hfs-magic be-w@  h# 4244 =
;

\ In addition to returning the flag, if it is a mac disk, this
\ routine has the side effect of setting /mac-block and size-low,high
: mac-disk?  ( -- flag )
   sector-buf be-w@  h# 4552  =  dup  if
      sector-buf wa1+ be-w@  to /mac-block
      /sector /mac-block <>
      abort" The partition map code cannot handle non-512-byte sector sizes"
      sector-buf la1+ be-l@  /mac-block um*  to size-high  to size-low
   then
;
\ LICENSE_BEGIN
\ Copyright (c) 1997 FirmWorks
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
