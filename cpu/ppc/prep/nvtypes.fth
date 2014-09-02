purpose: Configuration option data types that are PR*P but not CHRP specific
\ See license at end of file

: [']actions  ( -- )  compile (') action-adr token,  ; immediate

6 actions
action: drop 9 nvram-c@ ascii L =  ;
action: drop  if  ascii L  else  ascii B  then config-rw 9 nvram-c! config-ro ;
action: drop  config-mem 9 +  ;
action: drop flag>$  ;
action: drop $>flag  ;
action: la1+ @ 0<>  ;

\ Modify the code field of the little-endian? flag to make it use
\ the PR*P storage location and encodings.
: set-prep-le  ( -- )  [']actions  ['] little-endian?  uses  ;

[ifdef] notdef
: pack-prep-env  ( adr len apf -- adr' len' )  \ Binary to ASCII text
   >r
   push-hex
   >r r@ 2*  alloc-mem             ( adr adr' )
   r@  0  do                       ( adr adr' )
      over i ca+ c@  <# u# u# u#>  ( adr adr' n-adr 2 )
      drop over i wa+ 2 move       ( adr adr' )
   loop
   nip r> 2*
   pop-base
   2dup r> false put-env$          ( adr' len' )
   free-mem                        ( )
;

\ The maximum size required for this buffer is limited to the size of
\ the global environment area divided by two.  The size of the global
\ environment area is established by set-mfg-defaults
h# 908 2/ constant /decode-buf
/decode-buf buffer: decode-buf

0 value pntr
: unpack-prep-env  ( cstr -- adr' len' )  \ ASCII text to binary
   push-hex
   0 to pntr
   decode-buf				( adr adr' )
   begin                                ( adr adr' )
      over pntr wa+ 2 $number  if  
         0 true				( adr adr' 0 true )
      else
         pntr /decode-buf =		( adr adr' n flag )
      then
      >r				( adr adr' 0|n ) ( r: flag )
      over pntr ca+ c!			( adr adr' ) ( r: flag )
      pntr 1+ to pntr			( adr adr' ) ( r: flag )
      r>				( adr adr' flag )
   until
   nip  pntr 1-				( adr' len' )
   pop-base
;
[then]

headerless

h# 20 constant boot-pw
h# 30 constant config-pw
max-password buffer: password-buf
: password@  ( offset -- byte )  " rtc@" clock-node @ $call-method  ;
: password!  ( byte offset -- )  " rtc!" clock-node @ $call-method  ;
: pw-crc!  ( crc offset -- )  >r wbsplit  r@ password!  r> 1+ password!  ;
: pw-crc@  ( offset -- crc )  dup 1+ password@  swap password@  bwjoin  ;
: retrieve-password  ( offset -- )
   max-password 0  ?do  dup i + password@  password-buf i + c!  loop
   drop
;
: password-string  ( -- adr len )
   max-password  dup 0  ?do
      password-buf i ca+ c@ 0=  if  drop i  leave  then
   loop   ( #chars )
   password-buf swap
;
: compute-pw-crc  ( offset -- crc offset' )
   dup max-password +  >r
   retrieve-password   
   h# ffff  password-buf max-password bounds  ?do  i c@ crcgen  loop  ( crc )
   r>
;
: make-invalid  ( offset -- )  compute-pw-crc swap invert swap  pw-crc!  ;
: make-valid  ( offset -- )  compute-pw-crc  pw-crc!  ;
: pw-off  ( -- )  1  h# 19 password!  1  h# 1f password!  ;
: pw-on   ( -- )  0  h# 19 password!  0  h# 1f password!  ;
: pw-on?  ( -- flag )
   h# 19 password@ 0=     h# 1f password@ 0=  or
;
: pw-valid?  ( offset -- flag )  compute-pw-crc pw-crc@ =  ;
: set-password  ( adr len offset -- )
   d# 14 0  do  0 over i + password!  loop	\ Erase old value
   swap   0  ?do  ( adr offset )  over i + c@  over i + password!  loop
   2drop
;

: prep-secmode@  ( apf -- n )
   drop
   pw-on?  0=  if  0  exit  then
   boot-pw pw-valid?  if
      2
   else
      config-pw pw-valid?  if  1  else  0  then
   then
;
: prep-secmode!  ( n apf -- )
   drop
   case
      1  of  config-pw make-valid   boot-pw make-invalid  pw-on  endof
      2  of  config-pw make-valid   boot-pw make-valid    pw-on  endof
             config-pw make-invalid boot-pw make-invalid  pw-off
   endcase
;
: prep-password@  ( apf -- adr len )
   drop  config-pw retrieve-password  password-string
;
: prep-password!  ( adr len apf -- )
   drop            ( adr len )
   max-password min  2dup config-pw set-password  boot-pw set-password
;

5 actions
action: drop  h# 2c nvram-l@  h# 30 nvram-l@ +  ;
action: drop  config-rw  0 h# 2c nvram-l!  h# 30 nvram-l!  config-ro  ;
action:  ;
action: drop (.d)  ;
action: drop $>number  ;

\ Modify the code field of the little-endian? flag to make it use
\ the PR*P storage location and encodings.
: set-prep-#badlogins  ( -- )
   [']actions  ['] security-#badlogins  uses
;

headers
warning @ warning off
: set-defaults  ( -- )
   security-on?  if
      ." Note: set-defaults does not change the security fields." cr
   then
   set-defaults
;
warning !

d#  20 value /fixed-nv
h# 7ec value fixed-nv-base	\ Override as needed for the platform

true value fixed-nv-ok?

: fixed-nv@  ( offset -- byte )  fixed-nv-base +  nv-c@  ;
: fixed-nv!  ( byte offset -- )  fixed-nv-base +  nv-c!  ;

: fixed-nv-checksum  ( -- checksum )
   0  /fixed-nv  0  ?do  i fixed-nv@ xor  loop  ( checksum )
;

: set-fixed-nv-checksum  ( -- )
   fixed-nv-checksum  0 fixed-nv@ xor  h# 5a xor  0 fixed-nv!
;

6 actions
action: fixed-nv-ok?  if  l@ fixed-nv@ 0<>  else  la1+ @  then  ;
action: l@ fixed-nv! set-fixed-nv-checksum  ;
action: l@  ;
action: drop flag>$  ;
action: drop $>flag  ;
action: la1+ @ 0<>  ;

: is-fixed-nv-flag  ( offset xt -- )
   [']actions over uses  ( offset xt )
   >body l!              ( )
;

6 actions
action:
   fixed-nv-ok?  if
      l@  4 bounds  do  i fixed-nv@  loop  swap 2swap swap bljoin
   else
      la1+ @
   then
;
action:
   l@ >r  lbsplit  r> 4 bounds  do  i fixed-nv!  loop
   set-fixed-nv-checksum
;
action: l@  ;
action: drop
   push-hex <# 0 hold u#s [char] x hold  [char] 0 hold u#>  pop-base
;
action: drop $>number  ;
action: la1+ @  ;

: is-fixed-nv-int  ( offset xt -- )
   [']actions over uses  ( offset xt )
   >body l!              ( )
;

' diag-switch? is (diagnostic-mode?)

: init-fixed-nv  ( -- )
   fixed-nv-checksum h# 5a = ?dup  if  to fixed-nv-ok? exit  then
   ['] diag-switch? do-set-default
   ['] real-mode?   do-set-default
   ['] real-base    do-set-default
   ['] real-size    do-set-default
   ['] virt-base    do-set-default
   ['] virt-size    do-set-default
   ['] hrp-memmap?  do-set-default
   fixed-nv-checksum h# 5a =  to fixed-nv-ok?
;

headerless
: install-prep-nv  ( -- )
   set-prep-le
   set-prep-#badlogins

       1 ['] diag-switch? is-fixed-nv-flag
       2 ['] real-mode?   is-fixed-nv-flag
       3 ['] real-base    is-fixed-nv-int
       7 ['] real-size    is-fixed-nv-int
   d# 11 ['] virt-base    is-fixed-nv-int
   d# 15 ['] virt-size    is-fixed-nv-int
   d# 19 ['] hrp-memmap?  is-fixed-nv-flag

   ['] drop                  to grow-cv-area
   ['] prep-env-area         to cv-area
   ['] prep-config-checksum? to config-checksum?
   ['] prep-layout-config    to layout-config
   ['] set-prep-env-checksum to set-env-checksum
;
headers

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

