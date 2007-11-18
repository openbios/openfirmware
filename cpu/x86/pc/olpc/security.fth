purpose: OLPC secure boot
\ See license at end of file

\ Specs at http://wiki.laptop.org/go/Firmware_Security

: text-on  screen-ih stdout !  ;

: visible  dcon-unfreeze text-on   ;

: ?unfreeze  ( -- )
   game-key@ button-check and  if  visible unfreeze  then
;

0 0 2value base-xy
0 0 2value next-xy
d# 463 d# 540 2constant progress-xy
d# 552 d# 283 2constant sad-xy

true value debug-security?
: ?lease-debug   ( msg$ -- )
   debug-security?  if  type  else  2drop  then
;
: ?lease-debug-cr  ( msg$2 -- )
   debug-security?  if  type cr  else  2drop  then
;
: ?lease-error-cr  ( msg$2 -- )
   debug-security?  if  red-letters type black-letters cr  else  2drop  then
;

: fail-load  ( -- )
   text-on
   ." OS Load Failed" cr
   quit
   begin again
;

code halt  hlt  c;  \ To save power

0 value security-off?

: security-failure  ( -- )
   visible
   security-off?  if  ." Stopping" cr  quit  then

   button-check game-key?  if
      ." Use power button to power off" cr
      begin halt again
   else
      ." Powering off in 10 seconds" cr
      d# 10000 ms  power-off
   then
;

: +icon-xy  ( delta-x,y -- )  icon-xy d+ to icon-xy  ;


: show-going  ( -- )
   h# c0 h# c0 h# c0  rgb>565  progress-xy  d# 500 d# 100  " fill-rectangle" $call-screen
   d# 585 d# 613 to icon-xy  " bigdot" show-icon
   dcon-unfreeze
;
: show-x  ( -- )  " x" show-icon  ;
: show-sad  ( -- )
   icon-xy
   sad-xy to icon-xy  " sad" show-icon
   to icon-xy
;
: .security-failure  ( error$ -- )
   visible  red-letters type black-letters cr
   show-sad
   security-failure
;

: show-lock    ( -- )  " lock" show-icon  ;
: show-unlock  ( -- )  " unlock" show-icon  ;
: show-child  ( -- )
   " erase-screen" $call-screen
   d# 552 d# 383 to icon-xy  " rom:xogray.565" $show-opaque
   progress-xy to icon-xy  \ For boot progress reports
;

0 [if]
: show-warnings  ( -- )
   " erase-screen" $call-screen
   d# 48 d# 32 to icon-xy  " rom:warnings.565" $show-opaque
   dcon-freeze
;
[then]


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

\ key: is a defining word whose children return key strings.
\ Each child word has the name of its key stored in the dictionary.
\ The first time that a child word executes, it uses the key name
\ to find the key value and caches the key value in RAM so subsequent
\ uses are faster.

: key:  ( name$ "name" -- key$ )
   create 0 , 0 ,  ",   \ adr len name
   does>   ( apf -- key$ )
   dup @  if  2@ exit  then   ( apf )
   dup 2 na+ count            ( apf name$ )
   2dup  find-drop-in  if     ( apf name$ key$ )
      2nip
   else                       ( apf name$ )
      ." Can't load key " type cr
      " Missing Key"          ( apf bad-key$ )
   then
   rot >r  2dup r> 2!         ( key$ )
;
" fspubkey"     key: fskey$
" ospubkey"     key: oskey$
" fwpubkey"     key: fwkey$
" develpubkey"  key: develkey$
" leasepubkey"  key: leasekey$

\ pubkey$ is a global variable that points to the currently-selected
\ public key string.  It simplifies the stack manipulations for other
\ words, since the same key string is often used multiple times.
0 0 2value pubkey$

\ sig-buf is used for storing the binary version of signature strings
\ that have been decoded from the hex representation.

d# 256 constant /sig
/sig buffer: sig-buf

\ hex-decode decodes a hexadecimal signature string, storing it in
\ binary form at sig-buf.  It returns the adr,len of the binary string.

: hex-decode  ( hex$ -- true | sig$ false )
   sig-buf -rot                 ( adr hex$ )
   bounds ?do                   ( adr )
      i 2 push-hex $number pop-base  if  ( adr )
         2drop true unloop exit
      then                      ( adr n )
      over c!  1+               ( adr' )
   2 +loop                      ( adr )
   sig-buf tuck -   false       ( sig$ false )
;

\ parse-sig parses a "sig01:" format signature string, returning its
\ hashname and signature substrings.  It converts the signature
\ substring from ASCII hex to binary bytes.

: parse-sig  ( sig01$ -- true | hashname$ sig$ false )
   dup d# 89 <  if  2drop true exit  then
   bl left-parse-string  " sig01:" $=  0=  if  2drop true exit  then    ( rem$ )
   bl left-parse-string  dup d#  6 <>  if  4drop true exit  then  2swap ( hash$ rem$ )
   bl left-parse-string  nip d# 64 <>  if  4drop true exit  then        ( hash$ rem$ )
   newline left-parse-string  2swap nip  0<>  if  4drop true exit  then ( hash$ data$ )
   dup /sig 2* <>  if  ( ." Bad signature length" cr  )  2drop true  exit  then ( hash$ data$ )

   hex-decode  if  2drop true  else  false  then
;

\ zip-extent looks inside a memory-resident ZIP archive and returns
\ the address,length of a given component of that archive.  This
\ assumes that the components are "stored", not "deflated".  It
\ depends on the existence of a support package named "/lzip" to
\ do the work.

: zip-extent  ( name$ -- adr len )
   expand$  open-dev  ?dup 0=  if  " "  exit  then
   >r
   " offset" r@ $call-method load-base +
   " size" r@ $call-method drop
   r> close-dev
;

\ sig$ and img$ find the signature and signed-image components of
\ a ZIP bundle image that is already in memory.

: sig$  ( -- adr len )  " /lzip:\data.sig" zip-extent  ;
: img$  ( -- adr len )  " /lzip:\data.img" zip-extent  ;

\ bundle-name$ returns the full OFW pathname of a signed image
\ bundle, piecing it together from the device (DN), path (PN),
\ filename head (CN), and filename body (FN) macros.

: bundle-name$  ( -- $ )  " ${DN}${PN}\${CN}${FN}.zip" expand$  ;

\ bundle-present? determines the existence (or not) of a signed image
\ bundle whose name is constructed from the current settings of the
\ device (DN), path (PN), filename head (CN), and filename body (FN).

: bundle-present?  ( fn$ -- flag )
   fn-buf place
   bundle-name$
   " Trying " ?lease-debug  2dup ?lease-debug-cr
   ['] (boot-read) catch  if  2drop false exit  then
   true
;

\ hashname remembers the most recently used hashname to guard against
\ attacks based on reuse of the same (presumably compromized) hash.

\ invalid? checks the validity of data$ against the ASCII signature
\ record sig01$, using the public key that pubkey$ points to.
\ It also verifies that the hashname contained in sig01$ is the
\ expected one.

: invalid?  ( data$ sig01$ exp-hashname$ -- error? )
   2>r
   parse-sig  if
      ." Bad signature format"  cr
      2r> 2drop  true exit
   then                                     ( data$ hashname$ sig$ r: exp$ )

   \ Check for duplicate hashname attacks
   2swap 2dup 2r>  $=  0=  if               ( data$ sig$ hashname$ )
      ." Wrong hash name" cr
      4drop 2drop true exit
   then                                     ( data$ sig$ hashname$ )

   pubkey$  2swap  signature-bad?  ( error? )
   dup  if
      "   Signature invalid" ?lease-error-cr
   else
      "   Signature valid" ?lease-debug-cr
   then
;

: our-pubkey?  ( sig01$ -- flag )
   bl left-parse-string  " sig01:" $=  0=  if  2drop false exit  then  ( rem$ )
   bl left-parse-string 2drop    \ Discard hash name            ( rem$ )
   bl left-parse-string 2nip     \ Get key signature            ( key$ )
   /sig 2* min  hex-decode  if  2drop false exit  then          ( binary-key$ )
   pubkey$  dup 3 pick -  0 max /string   $=                    ( flag )
;

\ Look for a line that starts with "sig01: " and whose key signature
\ matches the trailing bytes of our currently-selected public key.
: next-sig01$  ( sig$ -- true | rem$ sig01$ false )
   begin  dup  while                          ( rem$ )
      newline left-parse-string               ( rem$' line$ )
      2dup our-pubkey?  if  false exit  then  ( rem$  line$ )
      2drop                                   ( rem$ )
   repeat                                     ( rem$ )
   " No signature for our key" ?lease-error-cr
   2drop true
;

\ Find a sig01: line and check its sha256/rsa signature
: sha-valid?  ( data$ sig01$ -- okay? )
   next-sig01$  if  2drop false exit  then  ( data$ rem$ sig01$ )
   2nip  " sha256" invalid? 0=
;

\ Find two sig01: lines, the first with sha256 and the second with rmd160,
\ and check their signatures
: fw-valid?  ( data$ sig$ -- okay? )
   2swap 2>r                                    ( sig$ r: data$ )
   next-sig01$  if  2r> 2drop false exit  then  ( rem$ sig01$ )
   2r@ 2swap sha-valid?  0=  if                 ( rem$ r: data$ )
      2r> 4drop false exit
   then                                         ( rmd-sig$ r: data$ )
   next-sig01$  if  2r> 2drop false exit  then  ( rem$ sig01$ )
   2nip  2r> 2swap " rmd160" invalid? 0=
;

\ break$ splits a string into an initial substring of length n
\ (head$) and the residual substring (tail$).  If the input
\ string is shorter than n, head$ is the input string and tail$ is
\ the null string.

: break$  ( $ n -- tail$ head$ )
   2dup <  if  drop null$ 2swap exit  then
   dup >r  /string   ( tail$ )
   over r@ -  r>     ( tail$ head$ )
;

\ numfield is a factor used for parsing 2-digit fields from date/time strings.
: numfield  ( exp$ min max -- exp$' )
   >r >r                      ( exp$ r: max min )
   2 break$ $number  throw    ( exp$' num  r: max min )
   dup r> < throw             ( exp$  num  r: max )
   dup r> > throw             ( exp$  num  )
;

\ expiration-to-seconds parses an expiration date string like
\ "20070820T130401Z", converting it to (double precision) seconds
\ according to the simplified calculation described above for "get-date"

: (expiration-to-seconds)  ( expiration$ -- d.seconds )
   4 break$ $number throw >r     ( exp$' r: y )
   1 d# 12 numfield >r           ( exp$' r: y m )
   1 d# 31 numfield >r           ( exp$' r: y m d )
   1 break$ " T" $=  0=  throw   ( exp$' r: y m d )
   0 d# 23 numfield >r           ( exp$' r: y m d h )
   0 d# 59 numfield >r           ( exp$' r: y m d h m )
   0 d# 59 numfield >r           ( exp$' r: y m d h m s )
   " Z" $= 0= throw              ( r: y m d h m s )
   r> r> r> r> r> r>             ( s m h m d y )
   >unix-seconds
;

: expiration-to-seconds  ( expiration$ -- true | seconds false )
   push-decimal
   ['] (expiration-to-seconds)  catch  ( x x true  |  seconds false )
   pop-base
   dup  if  nip nip  then
;

0 value current-seconds

: date-bad?  ( -- flag )
   current-seconds  0=  if
      time&date >unix-seconds to current-seconds
   then

   \ earliest is the earliest acceptable date value (in seconds).
   \ It is the date that the first test version of this code was
   \ deployed.  If a laptop has any earlier date that than, that
   \ date is presumed bogus.

   current-seconds  [ " 20070101T000000Z" expiration-to-seconds drop ] literal - 0<
;


\ expired? determines whether or not the expiration time string is
\ earlier than this machine's current time (from the real time clock).

: expired?  ( expiration$ -- bad? )
   expiration-to-seconds  if  true exit  then  ( seconds )

   \ If the date is bad, leases are deemed to have expired
   date-bad?  if  drop true exit  then         ( seconds )

   current-seconds -  0<
;

d# 1024 constant /sec-line-max
/sec-line-max buffer: sec-line-buf

\ Remove bogus null characters from the end of mfg data tags (old machines
\ have malformed tags)
: ?-null  ( adr len -- adr' len' )
   dup  if
      2dup + 1- c@  0=  if  1-  then        ( adr len' )
   then
;

\ machine-id-buf is a buffer into which the machine signature string,
\ including serial number, UUID, and expiration time, is place.
\ That string is the signed object for lease and developer key verification.

d# 67 buffer: machine-id-buf

\ get-my-sn get the machine identification info including serial number
\ and UUID from the manufacturing data, placing it into machine-id-buf
\ for later use.  The expiration time is added later.

: get-my-sn  ( -- error? )

   " SN" find-tag  0=  if
      " No serial number in mfg data" ?lease-error-cr
      true exit
   then                                             ( adr len )
   ?-null  dup d# 11 <>  if
      " Invalid serial number" ?lease-error-cr
      2drop true exit
   then                                             ( adr len )
   machine-id-buf  swap  move

   [char] : machine-id-buf d# 11 + c!

   " U#" find-tag  0=  if
      " No UUID in mfg data" ?lease-error-cr
      true exit
   then                                             ( adr len )
   ?-null  dup d# 36 <>  if
      " Invalid UUID" ?lease-error-cr
      2drop true exit
   then                                             ( adr len )
   machine-id-buf d# 12 +  swap  move

   [char] : machine-id-buf d# 48 + c!

   [char] : machine-id-buf d# 50 + c!

   false
;

\ my-sn$ returns the serial number portion of the machine identification.
\ get-my-sn must be called before my-sn$ will be valid.

: my-sn$  ( -- adr len )  machine-id-buf d# 11  ;


: check-expiry  ( exp$ -- exp$ -1|0 )
   \ Check for non-expiring case
   2dup " 00000000T000000Z" $=  if  0 exit  then

   dup d# 16 <>  if                        ( expiration$ )
      " has bad expiration format" ?lease-error-cr
      -1 exit
   then                                    ( expiration$ )

   2dup expired?  if
      " expired" ?lease-error-cr
      -1 exit
   then                                    ( expiration$ )
   0
;

\ check-machine-signature verifies the signed object consisting
\ of the machine identification info (SN + UUID) plus the expiration
\ time "expiration$" against the crypto signature string sig$,
\ returning 1 if valid, -1 if invalid, 0 if the key signature
\ doesn't match our pubkey.

: check-machine-signature  ( sig$ expiration$ -- -1|1 )
   2over  our-pubkey?   if                              ( sig$ exp$ )
      machine-id-buf d# 51 +  swap  move                ( sig$ )
      machine-id-buf d# 67  2swap                       ( id$ sig$ )
      " sha256" invalid?  if  -1  else  1  then         ( -1|1 )
   else                                                 ( sig$ exp$ )
      4drop 0                                           ( 0 )
   then                                                 ( -1|0|1 )
;

: set-disposition  ( adr -- )  c@  machine-id-buf d# 49 + c!  ;

\ Checks the tail of a timed signature - lease or developer key
: check-timed-signature  ( rem$ -- -1|0|1 )
   bl left-parse-string                    ( rem$ serial$ )
   my-sn$ $=  0=  if  2drop 0 exit  then   ( rem$ )

   \ Disposition code
   bl left-parse-string  1 <>  if
      "   No disposition code" ?lease-error-cr
      3drop -1 exit
   then                                    ( rem$ disp-adr )
   set-disposition                         ( rem$ )

   bl left-parse-string  check-expiry  if  4drop -1 exit  then   ( sig$ exp$ )

   check-machine-signature                 ( -1|0|1 )
;

\ check-lease checks a lease signature record in act01: format

\ -1 means lease is for this machine and is invalid
\  1 means lease is for this machine and is valid
\  0 means lease is not for this machine

: check-lease  ( act01-lease$ -- -1|0|1 )
   bl left-parse-string  " act01:"  $=  0=  if
      "   Not act01:" ?lease-error-cr
      2drop -1 exit
   then                                    ( rem$ )
   check-timed-signature                   ( -1|0|1 )
;

\ lease-valid? tries to read a lease file from the currently-selected
\ device, searches it for a lease record corresponding to this machine,
\ and checks that record for validity.  The return value is true if
\ a valid lease was found.

: lease-valid?  ( -- valid? )
   " ${DN}\security\lease.sig" expand$             ( name$ )
   " Trying " ?lease-debug  2dup ?lease-debug-cr
   r/o open-file  if  drop false exit  then   >r   ( r: ih )
   "   Lease " ?lease-debug
   load-started
   leasekey$ to pubkey$
   begin
      sec-line-buf /sec-line-max r@ read-line  if  ( actual -eof? )
         2drop  r> close-file drop  false exit
      then                                         ( actual -eof? )
   while                                           ( actual )
      sec-line-buf swap check-lease  case          ( -1|0|1 )
          1  of  r> close-file drop  " unlock" show-icon  true  exit  endof
         -1  of  r> close-file drop  " lock"   show-icon  false exit  endof
      endcase
   repeat         
   "   No matching records" ?lease-error-cr
   r> close-file drop  false
;

\ ?leased checks the currently-selected device for a valid lease
\ (see lease-valid?), setting the CN macro to "run" if one was
\ found or to "act" otherwise.  CN is used to construct a filename
\ like "runos.zip" (the normal OS, used when an valid lease is
\ present) or "actos.zip" (the activation version of the OS).

: ?leased  ( -- )
   " ak" find-tag  if
      2drop  " run"
   else
      lease-valid?  if  " run"  else  " act"  then
   then
   cn-buf place
;

0 value alternate?
: show-dot  ( -- )
   alternate?  if  " yellowdot"  else  " lightdot"  then  show-icon
;

: set-alternate  ( -- )
   button-o game-key?  if  true to alternate? exit  then
   h# 82 cmos@  [char] A =  if
      [char] N h# 82 cmos!
      true to alternate?  exit
   then
   false to alternate?
;

\ secure-load-ramdisk is called during the process of preparing an
\ OS image for execution.  It looks for an initrd bundle file on
\ the same device where the OS image was found, in a file named
\ either "runrd.zip" or "actrd.zip" depending on the presence of
\ a valid lease.

\ If no such bundle is found, the OS is booted without a ramdisk.
\ If a valid bundle is found, the OS is booted with that ramdisk.
\ If a bundle is found but it is not valid, the booting process aborts.

\ Call this after the kernel has already been moved away from load-base
\ We assume that pn-buf already has the path prefix string

: secure-load-ramdisk  ( -- )
\ Bad idea, because the cmdline would need to be signed too
\  " /lzip:\cmdline" zip-extent  to cmdline

   0 to /ramdisk

   ['] load-path behavior >r                      ( r: xt )
   ['] ramdisk-buf to load-path                   ( r: xt )

   d# 16 0  +icon-xy  show-dot
   \ cn-buf is already set as a result of the ?leased that
   \ happened before loading the OS file
   " rd" bundle-present?  if
      r> to load-path

      "   RD found - " ?lease-debug
      img$  sig$  sha-valid?  if
         show-unlock
         load-base to ramdisk-adr
         img$ dup to /ramdisk     ( adr len )
         load-base swap move      ( )
         exit
      else
         show-unlock
         fail-load
      then
   then
   r> to load-path
;

false value secure?
false value in-factory?

stand-init: wp
   " wp" find-tag  if  2drop  true to secure?  then
;

\ check-devel-key tests the developer signature string "dev01$".

\ -1 means the signature is for this machine and is invalid
\  1 means the signature is for this machine and is valid
\  0 means the signature is not for this machine

: check-devel-key  ( dev01$ -- -1|0|1 )
   bl left-parse-string  " dev01:"  $=  0=  if  2drop -1 exit  then  ( rem$ )
   check-timed-signature
;

\ has-developer-key? searches for a valid developer key on the
\ device given by the DN macro.

: has-developer-key?  ( -- flag )
   button-x game-key?  if  false exit  then
   " ${DN}\security\develop.sig" expand$    ( name$ )
   " Trying " ?lease-debug  2dup ?lease-debug-cr
   r/o open-file  if  drop false exit  then   >r   ( r: ih )
   "   Devel key " ?lease-debug
   load-started
   develkey$ to pubkey$
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
   "   No matching records" ?lease-error-cr
   r> close-file drop  false
;

: ?force-secure  ( -- )  button-x game-key?  if  true to secure?  then  ;

6 buffer: fw#buf
: (fw-version)  ( base-adr -- n )
   h# f.ffc7 + fw#buf 5 move
   fw#buf 4 + c@  bl  =  if  [char] 0 fw#buf 4 + c!  then
   base @ >r  d# 36 base !
   fw#buf 5 $number  if
      show-x
      " Invalid firmware version number"  .security-failure
   then
   pop-base
;

: firmware-up-to-date?  ( img$ -- )
   /flash <>  if  show-x  " Invalid Firmware image" .security-failure  then  ( adr )
   (fw-version)          ( file-version# )
   rom-pa (fw-version)   ( file-version# rom-version# )
   u<=
;

\ Wait until the time-stamp counter indicates a certain time after startup.
: wait-until  ( ms -- )
   begin   ( ms )
      dup  tsc@ ms-factor um/mod nip  ( ms ms time-ms )
   u<= until  ( ms )
   drop
;

: load-from-device  ( devname$ -- done? )

   d# 16 0  +icon-xy  show-dot
   null$ cn-buf place
   " bootfw" bundle-present?  if
      "   FW found - " ?lease-debug

      img$  firmware-up-to-date?  if
         " plus" show-icon
         " current FW is up-to-date" ?lease-debug-cr
      else
         " minus" show-icon
         " new - " ?lease-debug
         fwkey$ to pubkey$
         img$  sig$  fw-valid?  if
            visible

            img$ tuck flash-buf  swap move   ( len )

            ?image-valid                     ( )
            true to file-loaded?
            " Updating firmware" ?lease-debug-cr

            ec-indexed-io-off?  if
               visible
               ." Restarting to enable SPI FLASH writing."  cr
               d# 3000 ms
               ec-ixio-reboot
               security-failure
            then

            d# 12,000 wait-until   \ Wait for EC to notice the battery

            ['] ?enough-power  catch  ?dup  if
               visible
               red-letters .error black-letters
               security-failure
            then

            \ Latch alternate? flag for next startup
            alternate?  if  [char] A h# 82 cmos!  then

            reflash      \ Should power-off and reboot
            show-x
            " Reflash returned, unexpectedly" .security-failure
         then
         show-lock
      then
   then

   d# 16 0  +icon-xy  show-dot
   ?leased                \ Sets cn-buf

   d# 16 0  +icon-xy  show-dot
   " os" bundle-present?  if
      "   OS found - " ?lease-debug
      oskey$ to pubkey$
      img$  sig$  sha-valid?  if
         img$ tuck load-base swap move  !load-size
         show-unlock
         true  exit
      then
      show-lock
   then
   false   ( done? )
;

: filesystem-present?  ( -- flag )
   " ${DN}\" expand$    ( name$ )   
   open-dev  dup  if  dup close-dev  then
   0<>
;

: load-from-list  ( list$ -- devkey? )
   " dev /jffs2-file-system ' ?unfreeze to scan-callout  dend" eval

   begin  dup  while                        ( list$ )
      ?unfreeze
      bl left-parse-string                  ( list$ devname$ )
      2dup dn-buf place                     ( list$ devname$ )

      show-icon                             ( list$ xy )
      icon-xy to base-xy
      icon-xy image-width 0 d+ to next-xy   ( list$ )

      filesystem-present?  if               ( list$ )

         d# 5 d# 77  +icon-xy  show-dot     ( list$ )
         has-developer-key?  if             ( list$ )
            2drop                           ( )
            true to security-off?
            visible
            show-unlock
            true exit
         then                               ( list$ )

         load-from-device  if               ( list$ )
            ec-indexed-io-off               ( list$ )
            2drop                           ( )
            ['] secure-load-ramdisk to load-ramdisk
            " init-program" $find  if
               execute  show-going  go
            then
            show-x
            security-failure
         then
      then                                  ( list$ )

      next-xy to icon-xy                    ( list$ )
   repeat                                   ( list$ )
   2drop false                              ( )
;

: persistent-devkey?  ( -- flag )  " dk" find-tag  dup  if  nip nip  then  ;

: all-devices$  ( -- list$ )  " disk: sd: nand:"  ;

: secure-startup  ( -- )
   in-factory?  if
      button-check button-x or  button-o or  button-square or  button-rotate or  ( mask )
      game-key-mask =  if  exit  then
   then

   ['] noop to ?show-device
   ['] noop to load-done
   ['] noop to load-started

   set-alternate

\    button-rotate game-key?  if  show-warnings  then
   show-child

   ?force-secure

   secure?  0=  if  unfreeze visible  exit  then

   button-check game-key?  if
      unfreeze  visible
   else
      freeze  dcon-freeze
   then

   persistent-devkey?  if  true to security-off?  visible  exit  then

   get-my-sn  if  " No serial number" .security-failure  then

   date-bad?  if
      \ This is not fatal, because we don't want a brick if the RTC battery fails
      visible  red-letters ." Invalid system date" black-letters cr  show-sad
   then

   load-crypto  if  " Crytpo load failed" .security-failure   then       ( )

   alternate?  if  " \boot-alt"  else  " \boot"  then  pn-buf place

   all-devices$ load-from-list  if  exit  then   \ Returns only if no images found

   " Boot failed" .security-failure
;

: efface-md  ( -- )
   " md" find-tag  0=  if exit then  ( data$ )
   + 2 +  flash-base -               ( flash-offset )
   spi-start spi-identify            ( flash-offset )
   " MD" rot write-spi-flash         ( )
   spi-reprogrammed                  ( )
;

: days>seconds  ( n -- seconds )  [ d# 60 d# 60 * d# 24 * ] literal  *  ;
: ?factory-mode  ( -- )
   date-bad?  if  efface-md exit  then
   " md" find-tag  if             ( data$ )
      0 left-parse-string  2nip   ( time$ )
      \ Erase the tag if it is invalid
      expiration-to-seconds   if  efface-md exit  then  ( begin-seconds )
      dup 3 days>seconds +        ( begin-seconds end-seconds )
      \ Erase the tag if its time is up
      current-seconds  -rot within 0=  if  efface-md exit  then  ( )
      true to in-factory?
   then
;

\ iso8601 date construction for activation key
: .2digits ( .. roll# -- .. ) roll u# u# drop ;
: >iso8601$ ( s m h d m y -- adr len )
  push-decimal
  <#
  [char] Z hold 5 .2digits 4 .2digits 3 .2digits
  [char] T hold 2 .2digits 1 .2digits u# u# u# u#
  u#>
  pop-base
;

: factory-mode  ( -- )
   " md" find-tag  if  ." md tag already exists" cr  2drop exit  then
   " MD" find-tag  if  ." MD tag already exists" cr  2drop exit  then
   date-bad?  if  ." The RTC is not set correctly" cr  exit  then
   time&date >iso8601$  " md" $add-tag
;
