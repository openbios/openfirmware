\ See license at end of file
purpose: Intermediate IDE node definitions.

hex
external

" ide" device-name
" ide" device-type
" chrp,ide" encode-string " compatible" property

1 encode-int " #address-cells" property
0 encode-int " #size-cells" property

: write-blocks  " write-blocks"  $call-parent ;
: read-blocks   " read-blocks"   $call-parent ;
: max-transfer  " max-transfer"  $call-parent ;
: #blocks       " #blocks"       $call-parent ;
: block-size    " block-size"    $call-parent ;
: dma-free      " dma-free"      $call-parent ;
: dma-alloc     " dma-alloc"     $call-parent ;
: ide-inquiry   " ide-inquiry"   $call-parent ;

: any-blocks?   " any-blocks?"   $call-parent ;
: cdrom?        " cdrom?"        $call-parent ;

: set-address   ( unit -- dummy unit )

   \ Heres the trick, the reg property for the hierarchical IDE driver
   \ is set to either 0 or 1 indicating priamry or secondary IDE. We have
   \ to translate into the number that the driver up above needs to see
   \ according to the following table:
   \
   \  Device              Reg property       Address Parent Needs
   \    Primary Master         0                      0
   \    Primary Slave          1                      1
   \    Secondary Master       0                      2
   \    Secondary Slave        1                      3
   \
   \ So we look to see if we are passing up for the secondary bus, if
   \ we are, we just add 2 to the address.

   " reg" get-my-property drop decode-int nip nip   ( 0 | 1 )	\ It better be!
   if  2+  then
   0 swap " set-address"  $call-parent
;

: open true ;
: close ;

: encode-unit  ( phys -- unit-str len )  base @ >r hex  (u.)  r> base !  ;

: decode-unit  ( unit-str len -- phys )
   base @ >r hex
   $number  if  0  then
   r> base !
;

headers
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
