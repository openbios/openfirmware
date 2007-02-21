purpose: Device tree node that accesses a host system file
\ See license at end of file

\ Creates a device node named "/osfile", of device-type "block", which
\ accesses an operating system file named by its first argument.
\ Backslash (\) characters in the file name are translated to
\ the underlying operating system's directory delimiter.
\  Example:   " /osfile:\dev\rfd0"

dev /
\ : open true ; : close ;

new-device
" osfile" device-name
also
0 instance value file#

\ The deblocker converts a block/record-oriented interface to a byte-oriented
\ interface, using internal buffering.  Disk and tape devices are usually
\ block or record oriented, but the Open Firmware external interface is
\ byte-oriented, in order to be independent of particular device block sizes.

0 instance value deblocker
: init-deblocker  ( -- okay? )
   " "  " deblocker"  $open-package  is deblocker
   deblocker if
      true
   else
      ." Can't open deblocker package"  cr  false
   then
;

0 instance value label-package
0 instance value offset-low
0 instance value offset-high
: close  ( -- )
   label-package close-package
   deblocker close-package
   file# d# 16 syscall  drop
;
: init-label-package  ( adr len -- okay? )
   0 is offset-high  0 is offset-low
\ iso9660-file-system
   " disk-label"  $open-package is label-package
   label-package  if
      0 0  " offset" label-package $call-method is offset-high is offset-low
      true
   else
      ." Can't open disk label package"  cr  false
   then
;
: convert/  ( filename$ -- )
   bounds  ?do
      i c@ [char] \ =  if  [char] / i c!  then
   loop
;
: $fopen  ( adr len -- fd )  $cstr  0 swap 8 syscall 2drop retval  ;
: open  ( -- flag )
   my-args ascii , left-parse-string            ( rem-str filename-str )
   2dup  convert/                               ( rem-str )
   $fopen to file#                              ( rem-str )
   file# 0<  if  2drop false  exit  then        ( rem-str )

   init-deblocker  0=  if  false exit  then     ( rem-str )

   init-label-package  dup 0=  if               ( flag )
      deblocker close-package                   ( false )
      file# d# 16 syscall  drop                 ( false )
   then                                         ( flag )
;
h# 200 constant block-size
: #blocks  ( -- n )  file# _fsize  block-size /  ;
: r/w-blocks  ( addr block# #blocks syscall# -- actual#blocks )
   >r
   swap block-size * file# _fseek    ( addr #blocks )
   block-size * swap  file# r> syscall  3drop retval
   block-size /
;

: dma-alloc  ( size -- adr )  alloc-mem  ;
: dma-free   ( adr size -- )  free-mem  ;
: max-transfer  ( -- n )   h# 4000  ;
: read-blocks   ( addr block# #blocks -- actual )  d# 20 r/w-blocks  ;
: write-blocks  ( addr block# #blocks -- actual )  d# 24 r/w-blocks  ;
\ : write-blocks  ( addr block# #blocks -- #written )  false d# 10 r/w-blocks  ;

: seek  ( offset.low offset.high -- okay? )
   offset-low offset-high  d+  " seek"   deblocker $call-method
;
: read  ( addr len -- actual-len )  " read"  deblocker $call-method  ;
: write ( addr len -- actual-len )  " write" deblocker $call-method  ;
\ : read   ( adr len -- actual )  swap file# d# 20 syscall 3drop retval  ;
\ : write  ( adr len -- actual )  swap file# d# 24 syscall 3drop retval  ;
\ : seek  ( offset.lo offset.hi -- flag )
\    offset-low offset-high d+  file# _dfseek 0
\ ;
finish-device
device-end

\ LICENSE_BEGIN
\ Copyright (c) 2007 FirmWorks
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
