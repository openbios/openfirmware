\ See license at end of file
purpose: BPB management

hex

d# 4096 constant /sector-max

: /sector  ( -- n )  bps w@  ;
: /cluster  ( -- n )  spc c@ /sector *  ;
: bytes>clusters  ( #bytes -- #clusters )  /cluster /mod  swap  if  1+  then  ;
: uncache-device  ( -- )  0 bps w!  ;

: bytes>cl-entries  ( #bytes -- #cl-entries )
   fat-type c@  case
      fat12  of  2 * 3 /  endof
      fat16  of  2/       endof
      fat32  of  2/ 2/    endof
   endcase
;

0 instance value dir-buf

\ 3 sectors contains an integral number of FAT entries for either the
\ 12-bit or 16-bit or 32-bit FAT format, thus avoiding fragments of entries.

: init-fat-cache  ( -- )
   \ We really should verify that the sector size is the same as it
   \ used to be, in case a different floppy was inserted.
   fat-cache @ 0=  if
      3 dup  sectors/fat-cache w!        ( #cache-sectors ) 
      /sector *                          ( cache-size )
      dup alloc-mem  fat-cache !         ( cache-size )
      bytes>cl-entries cl#/fat-cache w!

      /cluster alloc-mem  to dir-buf
   then
   -1 fat-sector !  false fat-dirty w! 
;
: ?free-fat-cache  ( -- )
   fat-cache @  if
      dir-buf /cluster free-mem
      fat-cache @  sectors/fat-cache w@ /sector *  free-mem
      0 fat-cache !
   then
;

: (set-device)  ( device# -- )  current-device !  ;

\ XXX There must be a better way to do this.  Right now, we just zap
\ the BPB cache for both removable devices.  This really ought to be
\ device interface procedure.
: media-changed?  ( -- flag )
[ifdef] notdef
   current-device @
   3"floppy (set-device)  uncache-device
   5"floppy (set-device)  uncache-device
   (set-device)
   true
[else]
   false
[then]
;

: free-bpb  ( -- )
   bpb @  ?dup  if  /sector-max  free-mem  0 bpb !  then
;
: ?read-error  ( error? -- )
   if          ( )
      free-bpb
      "CaR ". ." BIOS Parameter Block"
      abort
   then         ( )
;
: not-bpb?  ( -- error? )
   bp_bps lew@                         ( bps )
   dup  dup 1- and 0=                  ( bps power-of-2? )
   swap  d# 256  d# 4096 between  and  ( bps-ok? )
   bp_nfats c@ 1 2 between and  0=     ( error? )
;
: find-bpb  ( -- )
   ?init-device   \ Call the device's init routine

   /sector-max alloc-mem  bpb !
   0 1 bpb @  read-sectors  ?read-error
   not-bpb?  if
      free-bpb
      true abort" Not an MS-DOS formatted drive"
   then   
;

: alloc-fssector  ( -- )
   fssector @ 0=  if  /sector-max alloc-mem  fssector !  then
;
: free-fssector  ( -- )
   fssector @ ?dup  if  /sector-max  free-mem  0 fsinfo !  0 fssector ! then
;
: not-fsinfo?  ( -- error? )
   0 fsinfo !
   fssector @ /sector bounds  do
      i lel@ fssignature lel@ =  if
         i fsinfo !  leave
      then
   4 +loop
   fsinfo @ 0=
;
: read-fsinfo  ( sector# -- )
   false fsinfos-dirty c!
   alloc-fssector
   1 fssector @  read-sectors  if
      free-fssector
      "CaR ". ." File system inforation sector"
      abort
   then
   not-fsinfo?  if  free-fssector  then
;
: write-fsinfo  ( -- )
   fsinfos w@ 0<>  fsinfos-dirty c@ and  if
      false fsinfos-dirty c!
      fsinfos w@ 1 fssector @ write-sectors
      if  "CaW ". ." File info sector"  abort  then
   then
;

: ?read-bpb  ( -- )
   /sector 0=  if      \ Read bpb if necessary
      init-sector-size
      find-bpb

      bp_media c@  media c!
      bp_bps lew@  bps w@ <>  if
         ." WARNING: BPB sector size differs from device sector size" cr
      then
      bp_bps lew@  bps w!
      bp_spc c@    spc c!
      bp_spf lew@  ?dup  if
         media c@  h# f8 =  if
            dup d# 12 <  if  fat12  else  fat16  then
         else
            fat12
         then 0 0
         0 fsinfo ! 0 fssector ! false fsinfos-dirty c!
      else
         bp_bspf lel@  fat32
         bp_rdirclus  lel@
         bp_fsinfos lew@ dup read-fsinfo
      then
      fsinfos w!
      rdirclus l!
      fat-type c!
      spf l!

      init-fat-cache

      \ Sector number where the FAT starts.
      \ bp_nhid is the number of sectors before the BPB sector.
      \ bp_res is the number of sectors from the BPT sector to the
      \ first FAT sector.

      \ If the underlying disk driver handles partition offsets,
      \ we don't need to handle bp_nhid here.
      bp_res lew@   ( bp_nhid lel@ + )              fat-sector0  w!

      rdirclus @ ?dup  if
         dv_cwd-cl l!
         0 dir-sector0 w!
         0 #dir-sectors w!
         spf l@  bp_nfats c@ *  fat-sector0 w@ +    cl-sector0   l!
      else
         spf l@  bp_nfats c@ *  fat-sector0 w@ +    dir-sector0  w!
         bp_ndirs lew@  /dirent *  /sector /        #dir-sectors w!
         dir-sector0 w@  #dir-sectors w@ +          cl-sector0   l!
      then

      \ The number of clusters is limited both by space for clusters numbers
      \ in the FAT and by disk space for storage of the actual clusters.
      \ It would be silly to waste disk space by making the FAT too small,
      \ but I am paranoid so I check both limits.

      \ Calculate the number of clusters the FAT can represent
      spf l@  /sector *    bytes>cl-entries   ( #clusters )

      \ Compare it with the number of clusters for which there is disk space
      bp_nsects lew@ ?dup 0=  if  bp_xnsects lel@  then
      cl-sector0 l@ -  spc c@ /  2 +   min  1-
      max-cl# l!
      free-bpb
   then
;

: set-device  ( device# -- )  (set-device)  ?read-bpb  ;

\ : stand-init  ( -- )  stand-init  clear-device-records  ;
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
