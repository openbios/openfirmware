purpose: OLPC secure boot
\ See license at end of file

\ Specs at http://wiki.laptop.org/go/Firmware_Security

: boot-device-list  " disk sd nand"   ;

true value debug-security?
: ?lease-debug   ( msg$ -- )
   debug-security?  if  type  else  2drop  then
;
: ?lease-debug-cr  ( msg$2 -- )
   debug-security?  if  type cr  else  2drop  then
;

: fail-load  ( -- )
   screen-ih stdout !
   ." OS Load Failed" cr
   quit
   begin again
;

h#  20 buffer: cn-buf  \ filename prefix - either "act" or "run"
h#  20 buffer: fn-buf  \ filename tail - either "os" or "rd"
h# 100 buffer: pn-buf  \ pathname - either "\boot" or "\boot-alt"
h# 100 buffer: dn-buf  \ device name

\ These macro definitions make it easy to compose device specifier strings
\ from the above name components.
also macros definitions
: FN  fn-buf count  ;
: CN  cn-buf count  ;
: DN  dn-buf count  ;
: PN  pn-buf count  ;
previous definitions

d# 256 constant /sig
/sig buffer: sig-buf

: hex-decode  ( hex$ -- true | sig$ false )
   dup /sig 2* <>  if
      ( ." Bad signature length" cr  )
      2drop true  exit
   then                         ( hex$ )
   sig-buf -rot                 ( adr hex$ )
   bounds ?do                   ( adr )
      i 2 push-hex $number pop-base  if  ( adr )
         2drop true unloop exit
      then                      ( adr n )
      over c!  1+               ( adr' )
   2 +loop                      ( adr )
   sig-buf tuck -   false       ( sig$ false )
;

: parse-sig  ( sig01$ -- true | hashname$ sig$ false )
   dup d# 89 <  if  2drop true exit  then
   bl left-parse-string  " sig01:" $=  0=  if  2drop true exit  then    ( rem$ )
   bl left-parse-string  dup d#  6 <>  if  4drop true exit  then  2swap ( hash$ rem$ )
   bl left-parse-string  nip d# 64 <>  if  4drop true exit  then        ( hash$ rem$ )
   newline left-parse-string  2swap nip  0<>  if  4drop true exit  then ( hash$ data$ )
   hex-decode  if  2drop true  else  false  then
;

: zip-extent  ( name$ -- adr len )
   expand$  open-dev  ?dup 0=  if  " "  exit  then
   >r
   " offset" r@ $call-method load-base +
   " size" r@ $call-method drop
   r> close-dev
;
: sig$  ( -- adr len )  " /lzip:\data.sig" zip-extent  ;
: img$  ( -- adr len )  " /lzip:\data.img" zip-extent  ;
: bundle-name$  ( -- $ )  " ${DN}:${PN}\${CN}${FN}.zip" expand$  ;

: bundle-present?  ( -- flag )
   bundle-name$
   " Trying " ?lease-debug  2dup ?lease-debug-cr
   ['] (boot-read) catch  if  2drop false exit  then
   true
;

d# 32 buffer: hashname
\ fn-buf and pn-buf must contain the base file name and path
: valid?  ( data$ sig$ -- okay? )
   parse-sig  if
      ." Bad signature format in "  bundle-name$ type  cr
      false exit
   then                                     ( data$ hashname$ sig$ )

   \ Check for duplicate hashname attacks
   2swap  2dup hashname count $=  if        ( data$ sig$ hashname$ )
      ." Duplicate hash name in "  bundle-name$ type  cr
      4drop false exit
   then

   d# 31 min hashname place                 ( data$ sig$ )

   hashname count  signature-bad? 0=
;

d# 2007 d# 12 *  8 1- +  d# 31 *  d# 27 +  constant earliest
0. 2value current-seconds

\ This isn't an accurate calculation of seconds, but it
\ is sufficient for comparison purposes so long as we
\ use the same calculation in all cases.  It is not good
\ if we need to do arithmetic on dates.
: get-date  ( -- error? )
   time&date           ( s m h d m y )
   d# 12 *  swap 1- +  ( s m h d m' )  \ Months start at 1
   d# 31 *  swap 1- +  ( s m h d' )    \ Days start at 1
   dup earliest  <  if  ( s m h d' )
      screen-ih stdout !
      ." The clock is not set properly" cr
      4drop true exit
   then        ( s m h d' )
   d# 24 * +   ( s m h' )
   d# 60 * +   ( s m' )   \ Can't overflow so far
   d# 60 um*   ( s d.s' )
   swap 0 d+   to current-seconds
   false
;

: break$  ( $ n -- tail$ head$ )
   dup >r  /string   ( tail$ )
   over r@ -  r>     ( tail$ head$ )
;

0. 2value exp-seconds  \ Accumulator for parsing data/time strings

\ This is a factor used for parsing 2-digit fields from date/time strings.
\ Radix is the number to scale the result by, i.e. one more than the maximum
\ value of the field.  Adjust is 0 for fields whose first valid value is 0
\ (hours, minutes, seconds) or 1 for fields that start at 1 (month,day).
: numfield  ( exp$ adjust radix -- exp$' )
   >r >r                      ( exp$ r: radix adjust )
   2 break$ $number  throw    ( exp$' num  r: radix adjust )
   r> -                       ( exp$  num' r: radix )
   dup r@ u>= throw           ( exp$  num  r: radix )

   \ No need to multiply the top half because it can only become nonzero
   \ on the last call to scale-time
   exp-seconds drop  r>  um*  ( exp$  num  d.seconds )
   rot 0  d+  to exp-seconds  ( exp$ )
;

: (expiration-to-seconds)  ( expiration$ -- true | d.seconds false )
   4 break$ $number throw          ( exp$' year )
   dup d# 2999 u> throw            ( exp$' year )
   0 to exp-seconds                ( exp$' )

   1 d# 12 numfield                ( exp$' )  \ Month
   1 d# 31 numfield                ( exp$' )  \ Day

   1 break$ " T" $=  0=  throw     ( exp$' )

   0 d# 24 numfield                ( exp$' )  \ Hour
   0 d# 60 numfield                ( exp$' )  \ Minute
   0 d# 60 numfield                ( exp$' )  \ Second

   " Z" $=  0=  throw              ( )
   exp-seconds
;

: expiration-to-seconds  ( expiration$ -- true | d.seconds false )
   push-decimal
   ['] (expiration-to-seconds)  catch  ( x x true  |  d.seconds false )
   pop-base
   dup  if  nip nip  then
;

: expired?  ( expiration$ -- bad? )
   expiration-to-seconds  if  true exit  then
   current-seconds  d<
;

d# 1024 constant /sec-line-max
/sec-line-max buffer: sec-line-buf

\ Remove bogus null characters from the end of tags on old machines
: ?-null  ( adr len -- adr' len' )
   dup  if
      2dup + 1- c@  0=  if  1-  then        ( adr len' )
   then
;

d# 65 buffer: machine-id-buf

: get-my-sn  ( -- error? )

   " SN" find-tag  0=  if  true exit  then          ( adr len )
   ?-null  dup d# 11 <>  if  2drop true exit  then  ( adr len )
   machine-id-buf  swap  move

   [char] : machine-id-buf d# 11 + c!

   " U#" find-tag  0=  if  true exit  then          ( adr len )
   ?-null  dup d# 36 <>  if  2drop true exit  then  ( adr len )
   machine-id-buf d# 12 +  swap  move

   [char] : machine-id-buf d# 48 + c!

   false
;
: my-sn$  ( -- adr len )  machine-id-buf d# 11  ;

: check-machine-signature  ( sig$ expiration$ -- -1|1 )
   0 hashname c!
   machine-id-buf d# 49 +  swap  move  ( sig$ )
   machine-id-buf d# 65  2swap  valid?  if  1  else  -1  then
;

\ -1 means lease is for this machine and is invalid
\  1 means lease is for this machine and is valid
\  0 means lease is not for this machine
: check-lease  ( lease$ -- -1|0|1 )
   bl left-parse-string  " act01:"  $=  0=  if
      "   Not act01:" ?lease-debug-cr
      2drop -1 exit
   then
   bl left-parse-string                    ( rem$ serial$ )
   my-sn$ $=  0=  if                       ( rem$ )
      " is for a different system" ?lease-debug-cr
      2drop 0 exit
   then                                    ( rem$ )
   bl left-parse-string                    ( sig$ expiration$ )
   dup d# 16 <>  if                        ( sig$ expiration$ )
      " has bad expiration format" ?lease-debug-cr
      4drop -1 exit
   then                                    ( sig$ expiration$ )
   2dup expired?  if
      " expired" ?lease-debug-cr
      4drop -1 exit
   then                                    ( sig$ expiration$ )
   check-machine-signature                 ( -1|1 )

   dup 0<  if
      " has bad signature" ?lease-debug-cr
   else
      " valid" ?lease-debug-cr
   then
;

: lease-valid?  ( -- flag )
   " ${DN}:\security\lease.sig" expand$            ( name$ )
   " Trying " ?lease-debug  2dup ?lease-debug-cr
   r/o open-file  if  drop false exit  then        ( ih )
   >r                                              ( r: ih )
   "   Lease " ?lease-debug                        ( r: ih )
   begin
      sec-line-buf /sec-line-max r@ read-line  if  ( actual -eof? )
         2drop  r> close-file drop  false exit
      then                                         ( actual -eof? )
   while                                           ( actual )
      sec-line-buf swap check-lease  case          ( -1|0|1 )
          1  of  r> close-file drop  true exit   endof
         -1  of  r> close-file drop  false exit  endof
      endcase
   repeat         
   r> close-file drop  false
;

: ?leased  ( -- )
   lease-valid?  if  " run"  else " act"  then  cn-buf place
;

: olpc-load-image  ( list$ pathname$ -- okay? )
   pn-buf place                             ( list$ )
   begin  dup  while                        ( list$ )
      bl left-parse-string                  ( list$ devname$ )
      dn-buf place                          ( list$' )
      ?leased                               ( list$ )
      bundle-present?  if                   ( list$ )
         "   OS found - " ?lease-debug
         0 hashname c!
         img$  sig$  valid?  if
            "   Signature valid" ?lease-debug-cr
            img$ tuck load-base swap move  !load-size
            2drop true exit
         else
            "   Signature invalid" ?lease-debug-cr
         then
      then                                  ( list$ )
   repeat                                   ( list$ )
   2drop false
;

: secure-load  ( -- okay? )
   load-crypto  if                          ( )
      ." Can't get crypt code" cr           ( )
      false exit
   then                                     ( )

   get-my-sn if  false exit  then
   get-date  if  false exit  then

   " oskey" load-key  if                    ( )
      ." Can't find OS public key" cr       ( )
      false exit
   then                                     ( )

   " os"  fn-buf place

   boot-device-list " \boot"      olpc-load-image  if  true exit  then
   " nand"          " \boot-alt"  olpc-load-image  if  true exit  then
   false
;

\ Call this after the kernel has already been moved away from load-base
\ We assume that pn-buf already has the path prefix string
: secure-load-ramdisk  ( -- )
\ Bad idea, because the cmdline would need to be signed too
\  " /lzip:\cmdline" zip-extent  to cmdline

   " rd" fn-buf place
   bundle-present?  if
      "   RD found - " ?lease-debug
      0 hashname c!
      img$  sig$  valid?  if
         "   Signature valid" ?lease-debug-cr
         " /lzip:\data.img" $load-ramdisk exit
      else
         "   Signature invalid" ?lease-debug-cr
         fail-load
      then
   then
;

: check-devel-key  ( adr len -- -1|0|1 )
   bl left-parse-string  " dev01:"  $=  0=  if  2drop -1 exit  then  ( rem$ )
   bl left-parse-string                        ( rem$ serial$ )
   my-sn$ $=  0=  if  2drop 0 exit  then        ( rem$ )

   " 00000000T000000Z"  check-machine-signature
;

: has-developer-key?  ( -- flag )
   " ${DN}:\security\develop.sig" expand$    ( name$ )
   r/o open-file  if  drop false exit  then  ( ih )
   >r
   begin
      sec-line-buf /sec-line-max r@ read-line  if  ( actual -eof? )
         2drop  r> close-file drop  false exit
      then                                         ( actual -eof? )
   while                                           ( actual )
      sec-line-buf swap check-devel-key  case      ( -1|0|1 )
          1  of  r> close-file drop  true exit   endof
         -1  of  r> close-file drop  false exit  endof
      endcase
   repeat         
   r> close-file drop  false
;

: developer-device-list  " disk sd nand"   ;

: developer?  ( -- flag )
   get-my-sn if  false exit  then

   load-crypto  if                          ( )
      ." Can't get crypt code" cr           ( )
      false exit
   then                                     ( )

   " fwkey" load-key  if                          ( )
      ." Can't find firmware public key" cr       ( )
      false exit
   then                                           ( )

   developer-device-list
   begin  dup  while                        ( list$ )
      bl left-parse-string dn-buf place     ( list$' )
      has-developer-key?  if                ( list$' )
         2drop true  exit
      then                                  ( list$ )
   repeat                                   ( list$ )
   2drop false
;

: secure-boot  ( -- )
   debug-security?  if  screen-ih stdout !  then
   ['] secure-load-ramdisk to load-ramdisk
   secure-load  0=  if  fail-load  then
   loaded sync-cache  " init-program" $find  if  execute  else  2drop  then
   go
;

: wp?  ( -- flag )  " wp" find-tag  dup  if  nip nip  then  ;

: ?secure-boot  ( -- )  wp?  if  secure-boot  else  boot  then  ;
" ?secure-boot" ' boot-command set-config-string-default

\ For dn in boot-device-list
\   if 

fexit

Firmware security use cases:

a) load image signing:

Package: {run,act}{os,rd}.zip
Expiration: none
Signed object: OS or RD image file in .zip file
Signature: sha256_rsa256.sig in .zip file
Verification Algorithm: sha256 -> rsa256
Verification Key: OLPC-run-public-key

Rule: Don't run the image if the signature fails

b) Firmware update key

Package: /boot/bootfw.zip
Expiration: none (but should be versioned to avoid repeated updates)
Signed object: image in .zip file
Signature1: sha255.rsa in .zip file
Signature2: whirl.rsa in .zip file
Verification Algorithm: sha256 -> rsa256, whirlpool -> rsa256
Verification Key: OLPC-fw-public-key

Rule: If the developer key is valid, enter unlocked firmware state

c) Developer key

Package: /security/develop.key
Expiration: none
Signed object: <serial#>:<uuid>:00000000T000000Z (representing the machine)
Signature: rsa256 data in sig01 line
Verification Algorithm: rsa256
Verification Key: OLPC-devel-public-key

Rule: If the developer key is valid, enter unlocked firmware state

d) Activation lease

Package: /security/lease
Expiration: Yes - time on signature line
Signed object: <serial#>:<uuid>:<expiration time> (representing the machine)
Signature: rsa256 data in sig01 line
Verification Algorithm: rsa256
Verification Key: OLPC-act-public-key

Rule: If the lease is invalid, invoke act{os,rd}.zip instead of run{os,rd}.zip

