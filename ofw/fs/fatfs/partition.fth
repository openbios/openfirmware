\ See license at end of file
purpose: FDisk partition map decoder

\ Returns true if the sector buffer appears to contain a BIOS Parameter Block,
\ which signifies the beginning of a DOS "FAT" file system.
: fat?  ( -- flag )
   sector-buf d# 11 +  le-w@              ( bps )
   dup d# 256 = over  d# 512 = or  swap d# 1024 = or    \ bps ok?
   sector-buf d# 16 + c@ 1 2 between and  ( flag )  \ #FATS ok?
;

: ptable-bounds  ( -- end start )  sector-buf  h# 1be +  h# 40  bounds  ;
: ptable-sum  ( -- n )   0  ptable-bounds  do  i c@ +  loop  ;
: fdisk?  ( -- flag )
   sector-buf h# 1fe + le-w@  h# aa55  <>  if  false exit  then

   \ If the partition table area is all zero, then it's not a partition table
   ptable-sum     ( sum )
   0=  if  false exit  then

   \ Look for at least one recognizable partition type code
   ptable-bounds  do
      i 4 + c@                                        ( type )
      dup 1 =
      over 4 6 between or
      over h#  b =     or	\ FAT-32
      over h#  c =     or	\ FAT-32
      over h#  e =     or	\ FAT-16 LBA
      over h#  f =     or	\ Extended LBA
      over h# 41 =     or
      over iso-type =  or
      over ufs-type =  or
      swap ext2fs-type =  or                             ( recognized? )
      if  i 4 + c@ to partition-type true unloop exit  then
   h# 10 +loop
   false
;

\ ??? i b s n apparently means #sectors start-sector boot-indicator system-indicator
\ system-indicator: 0 no FAT, 1 12-bit FAT, 4 16-bit FAT, 5 extended, 6 over 32M
\               ... b FAT 32, c FAT 32 LBA, e FAT-16 LBA, f extended LBA
\ boot-indicator: 80 bootable

: process-ptable  ( -- true | i1 b1 s1 n1 i2 b2 s2 n2 i3 b3 s3 n3 i4 b4 s4 n4 false )
   sector-buf h# 1fe + le-w@  h# aa55  <>  if  true exit  then

   \ Process a real partition table
   sector-buf h# 1ee +  h# -30  bounds  do
      i d# 12 + le-l@  i 8 + le-l@  i c@  i 4 + c@
   h# -10 +loop
   false
;

\ (find-partition) scans ordinary and extended partitions looking for one that
\ matches a given criterion.

0 instance value extended-offset
false value found?
defer suitable?  ( s n -- s n flag )

: (find-partition  ( sector-offset -- not-found? )
   >r process-ptable  if  r> drop false exit  then  r>

   4 0 do			( i,b,s,nN ... i,b,s,n1 sector-offset )
      >r						( ... i,b,s,n )
      found?  if		\ partition was found	( ... i,b,s,n )
         2drop 2drop					( ... )
      else						( ... i,b,s,n )
         ?dup 0=  if					( ... i,b,s )
	    \ no FAT, skip it.
	    3drop					( ... )
         else						( ... i,b,s,n )
            dup 5 = over h# f = or  if   \ extended partition          ( ... i,b,s,n )
               2drop nip                                ( ... b )
               extended-offset dup 0=  if  over to extended-offset  then
               + dup read-sector recurse drop           ( ... )
            else		\ Ordinary partition	( ... i,b,s,n )
               suitable?  if                		( ... i,b,s,n )
                  to partition-type drop		( ... i,b )
                  r@ + to sector-offset			( ... i )
                  /sector um* to size-high to size-low	( ... )
                  true to found?			( ... )
               else					( ... i,b,s,n )
                  4drop					( ... )
               then					( ... )
            then					( ... )
         then						( ... )
      then						( ... )
      r>						( ... sector-offset )
   loop
   drop found? 0=
;
: (find-partition)  ( sector-offset criterion-xt -- not-found? )
   to suitable?  false to found?  (find-partition
;

\ These are some criteria used for finding specific partitions

\ Matches UFS partitions
: is-ufs?  ( type -- type flag )  dup ufs-type =  ;

\ Matches partitions with the bootable flag set
\ : bootable?  ( boot? type -- boot? type flag )  over h# 80 =  ;
\ XXX kludge for Linux: bootable flag is not always set, accept ext2fs-type
: bootable?  ( boot? type -- boot? type flag )
   over h# 80 =  over h# 83 = or
;

\ Matches the Nth partition, where N is initially stored in the value #part
: nth?  ( -- flag )  #part 1- dup to #part  0=  ;

: find-partition  ( sector-offset -- )
   0  ['] nth? (find-partition) abort" No such partition"
;
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
