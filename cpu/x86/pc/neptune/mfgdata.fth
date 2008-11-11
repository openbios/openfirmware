purpose: Save manufacturing data in a separate FLASH sector
\ See license at end of file

\ Create a node below the top-level FLASH node to access the portion
\ containing the manufacturing data.
0 0  mfg-data-offset <# u#s u#>  " flash" begin-package
   " mfgdata" device-name

   h# 1000 constant /device      \ 4K - SST49LF080A sector size
   fload ${BP}/dev/subrange.fth
end-package

false value using-mfg-data?

0 value saved-nvram-node
0 value saved-config-mem
0 value saved-config-size

0 value mfg-config-mem
0 value mfg-config-size
0 value mfg-data-node

: unselect-mfg-data  ( -- )
   using-mfg-data?  if
      saved-nvram-node  to nvram-node   0 to saved-nvram-node
      saved-config-mem  to config-mem   0 to saved-config-mem
      saved-config-size to config-size  0 to saved-config-size
      false to using-mfg-data?
   then
;      
: dangerous-select-mfg-data  ( -- )
   using-mfg-data?  if  exit  then

   mfg-data-node  0=  if
      " /mfgdata" open-dev to mfg-data-node
      mfg-data-node 0= abort" Can't open /mfgdata"
      " size" mfg-data-node $call-method  d>s to mfg-config-size
      mfg-config-size alloc-mem to mfg-config-mem
   then

   nvram-node  to saved-nvram-node
   config-mem  to saved-config-mem
   config-size to saved-config-size

   mfg-data-node to nvram-node
   mfg-config-mem  to config-mem
   mfg-config-size to config-size

   true to using-mfg-data?
;

stand-init: Manufacturing data
   dangerous-select-mfg-data
   read-nvram  0=  if      \ Read the manufacturing data into memory
      read-ge-area         \ Incorporate it into the config variables
   then
   unselect-mfg-data
;

: 2u#:  u# u#  [char] : hold  drop  ;
: encode-enaddr  ( adr len -- adr' len' )  \ binary to ASCII
   6 <>  if  " " exit  then
   6 bounds  do  i c@  loop   ( b0 b1 b2 b3 b4 b5 b6 )
   push-hex
   <# 2u#: 2u#: 2u#: 2u#: 2u#: u# u# u#>
   pop-base
;

: decode-ether-byte  ( $ dst-adr -- $' dst-adr' )
   >r                               ( $         r: dst-adr )
   [char] : left-parse-string       ( $' head$  r: dst-adr )
   $number if  0  then              ( $ n       r: dst-adr )
   0 max  h# ff min                 ( $ n'      r: dst-adr )
   r@ c!                            ( $         r" dst-adr )
   r> 1+                            ( $ dst-adr' )
;

6 buffer: temp-mac-address
: decode-enaddr  ( adr len -- adr' len' )  \ ASCII to binary
   push-hex
   temp-mac-address  6 0  do  decode-ether-byte  loop  drop
   pop-base
   temp-mac-address 6
;

6 actions
action: ( apf -- adr len )  cv-bytes@  ;
action: ( adr len apf -- )  cv-bytes!  ;
action: ( apf -- adr )  cv-adr drop ;
action: ( adr len apf -- adr len )  drop  encode-enaddr  ;
action: ( adr len apf -- adr len )  drop  decode-enaddr  ;
action: ( apf -- adr len )   la1+ dup la1+ swap @  ;

\ e.g. keymap
: config-mac-address  ( "name" default-value-adr len maxlen -- )
   config-create use-actions  drop             ( adr len )
   dup ,
   dup taligned  here swap note-string  allot  ( adr len here )
   swap move
;

" " 6 config-mac-address mfg-mac-address

8 buffer: mac-address-buf
: random-mac-address  ( -- adr len )
   mac-address-buf @  0=  if
      \ Get a pseudo-random number

      \ Seed it with the real time clock and the timestamp counter
      time&date xor xor xor xor xor   ( seed )
      tsc@ xor xor                    ( seed' )

      \ Scramble it a bit with a linear congruence
      d# 1103515245 *  d# 12345 +   h# 7FFFFFFF and  ( rn1 )
      dup mac-address-buf !                          ( rn1 )
      d# 1103515245 *  d# 12345 +   h# 7FFFFFFF and  ( rn2 )
      mac-address-buf 3 + !                          ( )

      \ Turn off the multicast bit and turn on the locally-assigned bit
      mac-address-buf c@  h# fe and  2 or  mac-address-buf c!
   then

   mac-address-buf 6
;

: choose-mac-address  ( -- adr len )
   mfg-mac-address  dup 6 <>  if  ( adr len )
      2drop  random-mac-address   ( adr' len' )
   then                           ( adr len )
;
' choose-mac-address to system-mac-address


\ LICENSE_BEGIN
\ Copyright (c) 2008 FirmWorks
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
