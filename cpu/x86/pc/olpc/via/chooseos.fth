\ See license at end of file
purpose: OS chooser for dual boot (Windows and Linux) from a single SD card

0 value mbr-ih

d# 512 constant /mbr   \ Size of a Master Boot Record sector

d# 16 constant #switched  \ Number of contiguous sectors to switch
\ 16 sectors is the size of the MBR plus the following code that Windows uses
\ for booting.  The real-mode code in the MBR reads sectors 1-15, which
\ contains a simple NTFS reader that is subsequently used to read additional files.

/mbr #switched * constant /switched

\ Byte offset h# 80000 hopefully puts the saved MBRs in a different erase
\ block on the NAND FLASH inside the device, thus giving it some measure
\ of extra protection against corruption.
h# 80000 /mbr /  constant saved-mbrs-base

/switched buffer: desired-mbr
/switched buffer: current-mbr

\ We use read-blocks and (especially) write-blocks so we don't cause extra
\ wear on the device by writing more data than necessary.  The deblocking
\ used by read and write might use a large buffer size thus causing data
\ to be written 

: get-sectors  ( adr sector# -- )
   #switched " read-blocks" mbr-ih $call-method   ( nread )
   #switched <> abort" Read failed"
;
: put-sectors  ( adr sector# -- )
   #switched  " write-blocks" mbr-ih $call-method   ( nread )
   #switched <> abort" Write failed"
;
: choose-os  ( n -- )
   " int:0" open-dev dup  to mbr-ih  0= abort" Can't open internal storage"  ( n )
   current-mbr  0  get-sectors    ( )
   desired-mbr  swap #switched *  saved-mbrs-base +  get-sectors
   desired-mbr /mbr is-mbr?  0=  if
      mbr-ih close-dev
      true abort" The chosen MBR is invalid" cr
   then
   current-mbr desired-mbr /mbr comp  if
      desired-mbr  0  put-sectors
   then
   mbr-ih close-dev
;

\ LICENSE_BEGIN
\ Copyright (c) 2010 FirmWorks
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
