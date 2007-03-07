\ See license at end of file
purpose: Load file for NCR53c8x0 driver

hex

" scsi"        device-name     \ Name of device node

" NCRC810" encode-string  " arc-identifier" property

false constant differential?   \ True if board is wired for differential mode

00000000 constant chip-offset

my-address my-space                encode-phys
   0 encode-int encode+      0 encode-int encode+
my-address my-space  h# 100.0010 + encode-phys  encode+
   0 encode-int encode+ h# 100 encode-int encode+
my-address my-space  h# 200.0014 + encode-phys  encode+
   0 encode-int encode+ h# 100 encode-int encode+
\ 875 (device id = f) and 895 (device id = c) has third base reg at h# 18
my-space 2 +  " config-w@" $call-parent  dup  h# f =  swap  h# c =  or  if
   my-address my-space  h# 200.0018 + encode-phys  encode+
      0 encode-int encode+ h# 1000 encode-int encode+
then
   " reg" property

d# 50.000.000 constant clock-frequency
clock-frequency encode-int " clock-frequency" property

" scsi-2"             device-type   \ Device implements SCSI-2 method set


0 constant endian-mask    \ 0 if hardware is little-endian, 3 if big-endian

 2 constant default-burst-len    \ Number of SBus transfers per burst
 0 constant ctest4-val
 9 constant dcntl-val

external

\ These routines may be called by the children of this device.
\ This card has no local buffer memory for the SCSI device, so it
\ depends on its parent to supply DMA memory.  For a device with
\ local buffer memory, these routines would probably allocate from
\ that local memory.

: dma-alloc    ( n -- vaddr )  " dma-alloc" $call-parent  ;
: dma-free     ( vaddr n -- )  " dma-free" $call-parent  ;
: dma-map-in   ( vaddr n cache? -- devaddr )  " dma-map-in" $call-parent  ;
: dma-map-out  ( vaddr devaddr n -- )  " dma-map-out" $call-parent  ;
: max-transfer ( -- n )
   " max-transfer"  ['] $call-parent catch  if  2drop h# 7fff.ffff  then
   h# 100.0000 min		\ Chip is limited to 2^24
;

0 value chip-base	\ Base address of NCR 53C720 chip

\ Map and unmap chip registers
: map    ( -- )
   0 0 my-space h# 200.0014 + h# 60  " map-in" $call-parent  to chip-base
   my-space 4 +
   dup " config-w@"  $call-parent  6 or  swap  " config-w!" $call-parent
;
: unmap  ( -- )
  chip-base  h# 60  " map-out" $call-parent
   my-space 4 +
   dup " config-w@"  $call-parent  6 invert and swap  " config-w!" $call-parent
;

headers

fload ${BP}/dev/ncr53720/ncr53720.fth
fload ${BP}/dev/scsi/hacom.fth

: wideness  ( flag -- )
   dup to wide?  if  0 0 encode-bytes  " wide" property  then
;

" Symbios,53C8??"  my-space 2 +  " config-w@" $call-parent ( def$ model )
   case
      1  of  2drop  false wideness  " Symbios,53C810"  endof
      2  of  2drop  true  wideness  " Symbios,53C820"  endof
      3  of  2drop  true  wideness  " Symbios,53C825"  endof
      f  of  2drop  true  wideness  " Symbios,53C875"  endof
      c  of  2drop  true  wideness  " Symbios,53C895"  endof
     20  of  2drop  true  wideness  " LSILogic,53C1010"  endof
     21  of  2drop  true  wideness  " LSILogic,53C1010R" endof
   endcase   model

0 0 encode-bytes

\ If the subsytem-vendor-id is present, then the controller configured
\ itself by reading an external eeprom (on 895s). We need to encode the
\ values withing the subsytem vendor and device ids for Solaris.

" subsystem-vendor-id" get-my-property  0=  if
   decode-int nip nip		  	( adr len sub-vid )
   ?dup  if
     " subsystem-id" get-my-property drop decode-int nip nip
						( adr len sub-vid sub-did )
     <# u#s drop ascii , hold u#s ascii i hold ascii c hold ascii p hold u#>
     encode-string encode+
   then
then

" vendor-id" get-my-property  drop  decode-int nip nip
" device-id" get-my-property  drop  decode-int nip nip   ( vendor device )
   <# u#s drop ascii , hold u#s ascii i hold ascii c hold ascii p hold u#>
   encode-string encode+

my-space 2 +  " config-w@" $call-parent			( dev-id )
h# f =  if
   " glm" encode-string encode+		\ Solaris expects this for 875 cards
then

\ Solaris wants "pciclass,010000 in the compatible property in 895 case
my-space 2 +  " config-w@" $call-parent	( dev-id )
h# c =  if
   " class-code" get-my-property drop decode-int nip nip
   dup h# f00000 and swap
   <# u#s  0= if ascii 0 hold  then
   ascii , hold  ascii s hold  ascii s hold  ascii a hold  ascii l hold
   ascii c hold  ascii i hold ascii c hold ascii p hold u#>
   encode-string encode+
then

" compatible" property

new-device
" disk"	device-name
fload ${BP}/dev/scsi/scsidisk.fth
finish-device

new-device
" tape" device-name
fload ${BP}/dev/scsi/scsitape.fth
finish-device

[ifndef] suppress-reset  reset  [then]
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
