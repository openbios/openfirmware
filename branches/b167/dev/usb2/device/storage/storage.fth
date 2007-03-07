purpose: USB Mass Storage device driver loader
\ See license at end of file

headers
hex

" usb-storage" device-type
0 encode-int " #size-cells"    property
1 encode-int " #address-cells" property


external

: decode-unit  ( addr len -- lun )  push-hex  $number  if  0  then  pop-base  ;
: encode-unit  ( lun -- adr len )   push-hex (u.) pop-base  ;

\ These routines may be called by the children of this device.
\ This card has no local buffer memory for the ATAPI device, so it
\ depends on its parent to supply DMA memory.  For a device with
\ local buffer memory, these routines would probably allocate from
\ that local memory.

h#  800 constant low-speed-max
h# 2000 constant full-speed-max
h# 4000 constant high-speed-max
: my-max  ( -- n )
   " low-speed"  get-my-property 0=  if  2drop low-speed-max  exit  then
   " full-speed" get-my-property 0=  if  2drop full-speed-max exit  then
   high-speed-max
;
: max-transfer ( -- n )
   " max-transfer" ['] $call-parent catch if
      2drop my-max
   then
   my-max min
;

headers

fload ${BP}/dev/usb2/device/common.fth		\ USB device driver common routines
fload ${BP}/dev/usb2/device/storage/scsi.fth	\ High level SCSI routines
fload ${BP}/dev/usb2/device/storage/atapi.fth	\ ATAPI interface support
fload ${BP}/dev/usb2/device/storage/hacom.fth	\ Basic SCSI routines

new-device
   " disk" device-name
   fload ${BP}/dev/usb2/device/storage/scsidisk.fth
finish-device

init


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
