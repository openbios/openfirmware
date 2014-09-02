purpose: Tools to create device-tree properties to drive residual-data creation
\ See license at end of file

: aix-id  ( type id -- )
   encode-int rot encode-int encode+  " aix-id&type" property
;
: aix-flags  ( flags -- )  encode-int " aix-flags" property  ;
: chip-id  ( id -- )  encode-int  " aix-chip-id" property  ;
: in-82378  ( -- )  h# 24.4d.00.81 chip-id  ;
: pnp-data  ( adr len -- )  encode-bytes  " pnp-data" property  ;

\ Encode primitive data types in PnP format
: start-encode  ( -- adr len )  0 0 encode-bytes  ;
: +byte   ( adr len b -- adr' len' )  here >r  c,  r> 1  encode+  ;
: +le16   ( adr len w -- adr' len' )  wbsplit >r +byte  r> +byte  ;
: +le32   ( adr len l -- adr' len' )  lbflip encode-int encode+  ;
: +le64   ( adr len l -- adr' len' )  +le32  0 encode-int encode+  ;
: +bytes  ( adr len adr1 len1 -- adr' len' )  encode-bytes encode+  ;

\ Encode address ranges using the IBM vendor-unique PnP format
: +regn  ( base size #bits -- )
   -rot >r >r >r
   " "(84 15 00 09 01)" +bytes   ( r: size base #bits )
   r> +le16  0 +byte     r> +le64  r> +le64
;
: +reg32  ( adr len base size -- adr' len' )  d# 32 +regn  ;
: +reg16  ( adr len base size -- adr' len' )  d# 16 +regn  ;
: +reg11  ( adr len base size -- adr' len' )  d# 11 +regn  ;

: +isa-mem32  ( adr len base size -- adr' len' )
   >r >r
   " "(84 15 00 09 02 20 00 00)" +bytes
   r> ( base ) +le64  r> ( size ) +le64
;
: +isa-reg  ( adr len base size -- adr' len' )
   >r >r
   " "(47 01)" +bytes  r@ ( base ) +le16  r> +le16   1 +byte  r> ( size ) +byte
;

: +fixed-isa-reg  ( adr len base size -- adr' len' )
   >r >r
   h# 4b +byte  r> ( base ) +le16  r> ( size ) +byte
;

\ Encode an IRQ number in PnP format
: +irq  ( adr len irq# -- adr' len' )  >r h# 22 +byte  1 r> lshift +le16  ;

\ Encode IBM bus-bridge-attributes PnP item
: +bus-attributes  ( adr len speed #slots -- adr' len' )
   >r >r  " "(84 06 00 06)" +bytes  r> +le32  r> +byte
;

\ Encode IBM bus-bridge-address-translation PnP item
: +bus-range  ( adr len decode type parent child size -- adr' len' )
   >r >r >r >r >r
   " "(84 1D 00 05)" +bytes  r> +byte  1 +byte  r> +byte  0 +byte
   r> +le64  r> +le64  r> +le64
;

\ Encode IBM PCI-bridge-descriptor PnP item
: start-pci-descriptor  ( adr len #devices -- adr' len' )
   >r  h# 84 +byte  r> d# 12 *  d# 21 +  +le16  3 +byte
;

\ Encode Device/slot entry in PCI-bridge-descriptor
: +slot  ( adr len slot# dev&func# int-type inta intb intc intd -- adr' len' )
   >r >r >r >r >r >r >r
   r> +byte  r> +byte  r> +le16  r> +le16  r> +le16  r> +le16  r> +le16
;

\ LICENSE_BEGIN
\ Copyright (c) 1997 FirmWorks
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

