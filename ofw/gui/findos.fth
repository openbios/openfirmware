\ See license at end of file
purpose: Search for an operating system on disk devices

\ Search all disks that are direct children of the primary PCI node,
\ executing a given procedure for each one.  The use for which this
\ facility was originally developed was to locate particular installed
\ operating systems.

d# 128 buffer: disk-name

headerless
0 value controller-ih

: digit>char  ( n -- char )  ascii 0 +  ;
: +char  ( n pstr -- )
   tuck count + c!  dup c@ 1+ swap c!
;

headers
: >disk-name  ( filename$ partition# target# -- adr len )
   controller-ih ihandle>devname  disk-name place
                                             ( filename$ partition# target# )
   " /disk@"  disk-name $cat                 ( filename$ partition# target# )
   digit>char disk-name +char                ( filename$ partition# )
   ascii :    disk-name +char                ( filename$ )
   digit>char disk-name +char                ( filename$ )
   dup  if                                   ( filename$ )
      ascii , disk-name +char                ( filename$ )
      disk-name $cat                         ( )
   else                                      ( filename$ )
      2drop                                  ( )
   then                                      ( )
   disk-name count                           ( adr len )
;
headerless

\ This value mimics the veneer's assignment of logical unit numbers to
\ "scsi" host adapters, in which category it also includes IDE controllers
-1 value controller#

: next-controller#  ( -- )
   controller# 1+ to controller#
;

0 value max#disks

defer is-disk?

defer target-find-os?

: search-devices?  ( phandle -- found? )
   next-controller#
   open-phandle  to controller-ih
   controller-ih  if
      max#disks 0  do
         i is-disk?  if
            i target-find-os?  if  true unloop exit  then
         then
      loop
   then
   false
;

create inquiry-cmd  h# 12 c, 0 c, 0 c, 0 c, 2 c, 0 c,
: is-scsi-disk?  ( target# -- flag )
   0 swap " set-address" controller-ih $call-method
   2 inquiry-cmd 6  " short-data-command" controller-ih $call-method  if
      false
   else       ( buffer )
      \    disk       not removable
      dup  c@ 0=   over 1+ c@ h# 80 and 0=   and      ( buffer flag ) \ disk
      over c@ 5 =  rot  1+ c@ h# 80 and 0<>  and  or  ( flag )        \ cdrom
   then
;

: scsi-setup  ( phandle -- phandle )
   \ XXX need to handle #targets property, or whatever it is called
   d# 8 to max#disks
   ['] is-scsi-disk?  to is-disk?
;

: is-ide-disk?  ( unit# -- flag )  drop true  ;

: ide-setup  ( phandle -- phandle )
   d# 4 to max#disks
   ['] is-ide-disk?  to is-disk?
;

: search-controller?  ( phandle -- found? )
   " device_type" 2 pick  get-package-property  if
      drop false exit
   then                                              ( ph value$ )

   get-encoded-string                                ( ph dev-type$ )

   2dup  " ide" $=  if                               ( ph dev-type$ )
      2drop  ide-setup   search-devices?   exit      ( found? )
   then                                              ( ph dev-type$ )

   2dup  " scsi-2" $=  if                            ( ph dev-type$ )
      2drop  scsi-setup  search-devices?   exit      ( found? )
   then                                              ( ph dev-type$ )

   2dup  " scsi" $=  if	                             ( ph dev-type$ )
      2drop  scsi-setup  search-devices?   exit      ( found? )
   then                                              ( ph dev-type$ )

   3drop false                                       ( false )
;

: (search-disks)  ( parent-ph -- found? )
   child                                                   ( phandle ) 
   begin  ?dup  while                                      ( phandle )
      dup search-controller?  if  drop true exit  then     ( phandle )
      dup recurse  if  drop true exit  then                ( phandle )
      peer                                                 ( phandle' )
   repeat                                                  ( )
   false
;

headers
: search-disks  ( 'os-finder -- found? )
   to target-find-os?
   -1 to controller#

   " /pci" find-package 0= abort" Can't find PCI node"     ( phandle )

   (search-disks)                                          ( phandle )
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
