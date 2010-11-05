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

: open-mbr
   " int:0" open-dev  dup 0= abort" Can't open internal storage"  ( ihandle )
   to mbr-ih
;

: get-desired-mbr  ( n -- )
   desired-mbr  swap #switched *  saved-mbrs-base +  get-sectors
;

: is-desired-mbr?  ( -- is-mbr? )
   desired-mbr /mbr is-mbr?
;

: close-mbr
   mbr-ih close-dev
;

: choice-present?  ( -- present? )
   open-mbr
   0 get-desired-mbr is-desired-mbr?
   1 get-desired-mbr is-desired-mbr?
   and
   close-mbr
;

: choose-os  ( n -- )
   open-mbr
   current-mbr  0  get-sectors    ( )
   get-desired-mbr
   is-desired-mbr?  0=  if
      close-mbr
      true abort" The chosen MBR is invalid" cr
   then
   current-mbr desired-mbr /mbr comp  if
      desired-mbr  0  put-sectors
   then
   close-mbr
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
