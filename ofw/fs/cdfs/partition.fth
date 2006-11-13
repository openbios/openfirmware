\ See license at end of file
purpose: Recognizer for ISO-9660 file system type

\ Returns true if the disk or partition is an ISO 9660 file
\ system volume, as determined by reading the primary volume descriptor.
: iso-9660?  ( -- flag )
   \ CD-ROM logical sectors are 2K bytes, but this package works
   \ in terms of 512 byte sectors, so we ask for sector 64 to
   \ get the first part of CD-ROM logical sector 16.
   d# 64  ['] read-sector catch  if  drop false exit  then
   sector-buf c@ 1 =  sector-buf 1+ 5 " CD001"  $=  and  dup  if   ( flag )
      iso-type to partition-type

      \ Include the following lines to limit the apparent size of a CD-ROM
      \ to its logical volume size.  Also see the Note in select-partition
[ifdef] notdef
      sector-buf  d#  80 +  le-l@  ( #blocks )
      sector-buf  d# 128 +  le-w@  ( #blocks /block )
      um*  to size-high  to size-low
[then]

   then
   0 read-sector
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
