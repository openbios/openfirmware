purpose: OLPC secure boot
\ See license at end of file

\ Specs at http://wiki.laptop.org/go/Firmware_Security

patch noop suspend-interact suspend

: rm-chain-visible  ( -- )
   [ ' rm-go-hook behavior compile, ]  \ Chain to old behavior
   visible
;
' rm-chain-visible to rm-go-hook


: ?unfreeze  ( -- )
   game-key@ button-check and  if
     frozen?  if  unfreeze  visible banner  then
   then
;

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
   show-sad
   text-on
   ." OS Load Failed" cr
   begin halt again
;

0 value security-off?

: security-failure  ( -- )
   visible banner
   security-off?  if  ." Stopping" cr  quit  then

   button-check game-key?  if
      ." Use power button to power off" cr
      sound-end
      begin halt again
   else
      ." Powering off in 30 seconds" cr
      sound-end
      d# 30000 ms  power-off
   then
;

: .security-failure  ( error$ -- )
   visible  red-letters type black-letters cr
   show-sad
   security-failure
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

0 0 2value pubkey$      \ adr,len of a concatenated sequence of keys 
0 value pubkeylen       \ Length of each key in the list

\ Copy a string to allocated memory
: preserve$  ( $ -- $' )
   >r                ( adr1 r: len )
   r@ alloc-mem      ( adr1 adr2 )
   tuck r@ move  r>  ( $' )
;

\ find-key-tag finds a tag like "s0" or "s8".  The caller sets tagname[0]
\ to 's' and then calls find-key-tag with different "n" arguments.

2 buffer: tagname
: find-key-tag  ( n -- false | value$ true )
   [char] 0 +  tagname 1+ c!
   tagname 2  find-tag  if   ( value$ )
      dup pubkeylen <>  if   ( value$ )
         ." Warning - ignoring key with bad length: " tagname 2 type cr
         2drop false         ( false )
      else                   ( value$ )
         true                ( true )
      then
   else                      ( )
      false                  ( false )
   then
;

\ Count the number of additional keys, so we know how much memory to allocate

: #augment-keys  ( keylen -- n )
   0  d# 10 1  do                 ( len n )
      i find-key-tag  if          ( len n value$ )
         2drop 1+                 ( len n' )
      then                        ( len n )
   loop                           ( len n )
   nip
;

\ Amend the key list string with alternative or additional keys from
\ manufacturing data.

: augment-key$  ( olpc-key$ mfg-data$ -- key$' )
   tagname swap move            ( olpc-key$ )

   \ Determine how much memory to allocate

   dup #augment-keys 1+         ( olpc-key$ #extra )
   over *  dup alloc-mem swap   ( olpc-key$ list$ )

   \ If there is an override key, use it instead of the OLPC key
   0  find-key-tag  0=  if      ( olpc-key$ list$ )
      2over                     ( olpc-key$ list$ first-key$ )
   then                         ( olpc-key$ list$ first-key$ )

   \ Install the first key in the list
   3 pick swap move             ( olpc-key$ list$ )

   \ Free the memory used by olpc-key$ (it came from find-drop-in)
   2swap free-mem               ( list$ )

   \ Add additional keys to the list
   over  pubkeylen tuck +       ( list$ keylen curadr )
   d# 10 1  do                  ( list$ keylen curadr )
      i find-key-tag  if        ( list$ keylen curadr value$ )
         drop over 3 pick move  ( list$ keylen curadr )
         over +                 ( list$ keylen curadr' )
      then                      ( list$ keylen curadr )
   loop                         ( list$ keylen curadr )
   2drop                        ( list$ )
;

\ key: is a defining word whose children return key strings.
\ Each child word has the name of its key stored in the dictionary.
\ The first time that a child word executes, it uses the key name
\ to find the key value and caches the key value in RAM so subsequent
\ uses are faster.

\ The key name includes both the name that is used in the dropin
\ module list (e.g. "fspubkey") and the prefix letter for mfg data
\ tags (e.g. "s").

: key:  ( name$ "name" -- key$ )
   create 0 , 0 ,  ",   \ adr len name
   does>   ( apf -- key$ )
   dup @  if  2@ exit  then   ( apf )
   dup 2 na+ count            ( apf name$ )
   [char] , left-parse-string ( apf mfg-data$ dropin-name$ )
   2dup  find-drop-in  if     ( apf mfg-data$ name$ key$ )
      2nip                    ( apf mfg-data$ key$ )
   else                       ( apf mfg-data$ name$ )
      ." Can't load key " type cr  ( apf mfg-data$ )
      2drop                   ( apf )
      " Missing Key"          ( apf bad-key$ )
      dup to pubkeylen        ( apf bad-key$ )
      rot >r  2dup r> 2!      ( key$ )
      exit
   then                       ( apf mfg-data$ key$ )
   dup to pubkeylen           ( apf mfg-data$ key$ )
   2swap                      ( apf key$ mfg-data$ )
   augment-key$               ( apf key$' )
   rot >r  2dup r> 2!         ( key$ )
;
" fspubkey,s"     key: fskey$
" ospubkey,o"     key: oskey$
" fwpubkey,w"     key: fwkey$
" develpubkey,d"  key: develkey$
" leasepubkey,a"  key: leasekey$

\ thiskey$ is a global variable that points to the currently-selected
\ public key string.  It simplifies the stack manipulations for other
\ words, since the same key string is often used multiple times.
0 0 2value thiskey$

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

\ cut$ splits a string into an initial substring of length n
\ (head$) and the residual substring (tail$).  If the input
\ string is shorter than n, head$ is the input string and tail$ is
\ the null string.

: cut$  ( $ n -- tail$ head$ )
   2dup <  if  drop null$ 2swap exit  then
   dup >r  /string   ( tail$ )
   over r@ -  r>     ( tail$ head$ )
;

: sig$>key$  ( sig0N$ -- true | binary-key$ false )
   bl left-parse-string                ( rem$ signame$ )
   2dup " sig01:" $=  if               ( rem$ signame$ )
      2drop                            ( rem$ )
   else                                ( rem$ signame$ )
      " sig02:" $=  0=  if             ( rem$ )
         2drop true                    ( true )
         exit
      then                             ( rem$ )
   then                                ( rem$ )
   bl left-parse-string 2drop          ( rem$ )  \ Discard hash name
   bl left-parse-string 2nip           ( key$ )  \ Get key signature
   /sig 2* min  hex-decode  if         ( key$ )
      2drop true                       ( true )
      exit
   then                                ( binary-key$ )
   false                               ( binary-key$ false )
;

\ True if short$ matches the end of long$ 
: tail$=  ( short$ long$ -- flag )  2 pick  - +  swap comp 0=  ;

: key-in-list?  ( key$ -- flag )  \ Sets thiskey$ as an important side effect
   2>r                                   ( r: key$ )
   pubkey$  begin  dup  while            ( rem$  r: key$ )
      pubkeylen cut$                     ( rem$' thiskey$  r: key$ )
      2r@ 2over tail$=  if               ( rem$ thiskey$  r: key$ )
         to thiskey$                     ( rem$  r: key$ )
         2r> 4drop  true                 ( true )
         exit
      then                               ( rem$' thiskey$  r: key$ )
      2drop                              ( rem$'  r: key$ )
   repeat                                ( rem$'  r: key$ )
   2r> 4drop false
;

: in-pubkey-list?  ( sig0N$ -- flag )
   sig$>key$  if  false exit  then    ( key$ )
   key-in-list?                       ( flag )
;

\ Look for a line that starts with "sig0N: " whose key signature
\ matches the trailing bytes of a public key in our current list.
: next-sig-in-list$  ( sig$ -- true | rem$ sig0N$ false )
   begin  dup  while                               ( rem$ )
      newline left-parse-string                    ( rem$' line$ )
      2dup in-pubkey-list?  if  false exit  then   ( rem$  line$ )
      2drop                                        ( rem$ )
   repeat                                          ( rem$ )
   " No signature for our key list" ?lease-error-cr
   2drop true
;

\ Look for a line that starts with "sig0N: " whose key signature
\ matches the trailing bytes of our currently-selected public key.
\ This differs from next-sig-in-list$ in that next-sig-in-list$
\ looks for a signature that matches any public key in our list,
\ whereas this looks for a second signature that matches the public
\ key that next-sig-in-list$ already found.
: next-sig$  ( sig$ -- true | rem$ sig0N$ false )
   begin  dup  while                ( rem$ )
      newline left-parse-string     ( rem$' line$ )
      2dup sig$>key$  0=  if        ( rem$  line$ binary-key$ )
         thiskey$ tail$=  if        ( rem$  line$ )
            false                   ( rem$  sig0N$ false )
            exit
         then                       ( rem$  line$ )
      then                          ( rem$  line$ )
      2drop                         ( rem$ )
   repeat                           ( rem$ )
   " No signature for our key" ?lease-error-cr
   2drop true
;

\ numfield is a factor used for parsing 2-digit fields from date/time strings.
: numfield  ( exp$ min max -- exp$' )
   >r >r                      ( exp$ r: max min )
   2 cut$ $number  throw      ( exp$' num  r: max min )
   dup r> < throw             ( exp$  num  r: max )
   dup r> > throw             ( exp$  num  )
;

\ expiration-to-seconds parses an expiration date string like
\ "20070820T130401Z", converting it to (double precision) seconds
\ according to the simplified calculation described above for "get-date"

: (expiration-to-seconds)  ( expiration$ -- d.seconds )
   4 cut$ $number throw >r       ( exp$' r: y )
   1 d# 12 numfield >r           ( exp$' r: y m )
   1 d# 31 numfield >r           ( exp$' r: y m d )
   1 cut$ " T" $=  0=  throw     ( exp$' r: y m d )
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
   \ deployed.  If a laptop has any earlier date, the
   \ date is presumed bogus.

   current-seconds  [ " 20070101T000000Z" expiration-to-seconds drop ] literal - 0<
;


\ expired? determines whether or not the expiration time string is
\ earlier than this machine's current time (from the real time clock).

: expired?  ( expiration$ -- bad? )
   \ Check for non-expiring case
   2dup " 00000000T000000Z" $=  if  2drop false exit  then

   expiration-to-seconds  if  true exit  then  ( seconds )

   \ If the date is bad, leases are deemed to have expired
   date-bad?  if  drop true exit  then         ( seconds )

   current-seconds -  0<
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
   machine-id-buf d# 11 upper

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

: .trying  ( name$ -- name$ )
   " Trying " ?lease-debug  2dup ?lease-debug-cr
;
: bundle-present?  ( fn$ -- flag )
   fn-buf place
   bundle-name$  .trying
   ['] (boot-read) catch  if  2drop false exit  then
   true
;

\ exp-hashname$ remembers the most recently used hashname to guard against
\ attacks based on reuse of the same (presumably compromized) hash.

0 0 2value exp-hashname$
0 0 2value signed-data$

\ sig01: hashname keyid signature
: sig01-good?  ( line$ -- good? )
   \ Check that the hashname is as expected
   bl left-parse-string              ( line$ this-hashname$ )
   exp-hashname$  $=  0=  if         ( line$ )
      2drop false  exit
   then                              ( line$' )

   \ Check that the keyid matches our pubkey
   bl left-parse-string              ( line$' keyid$ )
   /sig 2* min  hex-decode  if       ( line$ )
      2drop false  exit              
   then                              ( line$ binary-key$ )

   key-in-list?  0=  if              ( line$ )
      2drop false  exit
   then                              ( line$ )

   \ Check that the signature occupies the rest of the line
   bl left-parse-string              ( line$' sig$ )
   2swap nip 0<>  if                 ( sig$ )
      \ Trailing junk at the end
      2drop false  exit
   then                              ( sig$ )

   dup /sig 2* <>  if                ( sig$ )
      2drop false exit
   then                              ( sig$ )

   hex-decode  if                    ( )
      false exit
   then                              ( binary-sig$ )

   \ Cryptographically verify the data against the signature
   2>r  0 signed-data$  2r>  thiskey$  exp-hashname$  signature-bad? 0=
;

h# 10e constant /key
/key buffer: keybuf

0 0 2value sig02-key$

0 0 2value expiry$

: sig02-good?  ( line$ -- good? )
   d# 100 0  do
      \ Check that the hashname is as expected
      bl left-parse-string              ( line$' this-hashname$ )
      exp-hashname$  $=  0=  if         ( line$ )
         2drop false  unloop exit
      then                              ( line$' )

      \ Check that the keyid matches our pubkey, but only if it's
      \ the first one
      bl left-parse-string              ( line$' pubkey$ )
      hex-decode  if                    ( line$ )
         2drop false unloop exit
      then                              ( line$ binary-key$ )

      i  if                             ( line$ binary-key$ )
         dup /key <>  if                ( line$ binary-key$ )
            4drop false unloop exit
         then                           ( line$ binary-key$ )
         tuck  keybuf  swap move        ( line$ binary-keylen )
         keybuf swap                    ( line$ binary-key$' )
      else                              ( line$ binary-keyid$ )
         key-in-list? 0=  if            ( line$ )
            2drop false unloop exit
         then                           ( line$ )
         thiskey$                       ( line$ key$ )
      then                              ( line$ key$ )
      to sig02-key$                     ( line$ )

      \ Check the expiration date
      bl left-parse-string  to expiry$  ( line$' )
      expiry$ expired?  if              ( line$ )
         2drop false unloop exit
      then                              ( line$ )

      \ Get the signature
      bl left-parse-string              ( line$ sig$)

      dup /sig 2* <>  if                ( line$ sig$ )
         4drop false unloop exit
      then                              ( line sig$ )

      hex-decode  if                    ( line$ )
         2drop false unloop exit
      then                              ( line$ binary-sig$ )

      2>r                               ( line$' r: binary-sig$ )

      \ If it's the final signature, check the signed data
      dup 0=  if                        ( line$ r: sig$ )
         2drop                          ( r: sig$ )
         0 signed-data$ " :" expiry$ " :" my-sn$  2r>  ( 0 data$ .. sig$ )
         sig02-key$  exp-hashname$  signature-bad? 0=  ( good? )
         unloop exit
      then                              ( line$ r: sig$ )

      \ Otherwise check the next key in the list
      2dup bl left-parse-string 2drop   ( line$ line$' r: sig$ )    \ Discard the hashname
      bl left-parse-string  2nip  2>r   ( line$ r: sig$ key$ )

      0  " "n"  2r>  " :key01: "  expiry$  " :"  my-sn$  2r>  ( 0 data$ .. sig$ )
      sig02-key$  exp-hashname$  signature-bad?  if  ( line$ )
         2drop false unloop exit
      then                              ( line$ )
   loop
   true abort" Delegation too long"
;

: this-sig-line-good?  ( line$ -- good? )
   bl left-parse-string              ( line$' tag$ )
   2dup  " sig01:" $=  if            ( line$' tag$ )
      2drop sig01-good?              ( good? )
      exit
   then                              ( line$' )
   2dup  " sig02:" $=  if            ( line$' tag$ )
      2drop sig02-good?              ( good? )
      exit
   then                              ( line$' tag$ )
   4drop false                       ( good? )
;

: signature-good?  ( data$ sig$ hashname$ -- good? )
   to exp-hashname$                  ( data$ sig$ )
   2swap to signed-data$             ( sig$ )
   begin  dup  while                 ( rem$ )
      newline left-parse-string      ( rem$' line$ )

      this-sig-line-good?  if        ( rem$ )
         "   Signature valid" ?lease-debug-cr
         2drop  true exit
      then                           ( rem$ )

   repeat                            ( rem$ )
   "   Signature invalid" ?lease-error-cr
   2drop  false                      ( good? )
;

\ Find a sig0N: line and check its sha256/rsa signature
: sha-valid?  ( data$ sig$ -- okay? )
   next-sig-in-list$  if  2drop false exit  then  ( data$ rem$ sig$ )
   2nip  " sha256" signature-good?
;

\ Find two sig0N: lines, the first with sha256 and the second with rmd160,
\ and check their signatures
: fw-valid?  ( data$ sig$ -- okay? )
   2swap 2>r                                    ( sig$ r: data$ )
   next-sig-in-list$  if  2r> 2drop false exit  then  ( rem$ sig$ )
   2r@ 2swap sha-valid?  0=  if                 ( rem$ r: data$ )
      2r> 4drop false exit
   then                                         ( rmd-sig$ r: data$ )
   next-sig$  if  2r> 2drop false exit  then    ( rem$ sig$ )
   2nip  2r> 2swap " rmd160" signature-good?
;

d# 8192 constant /sec-line-max
/sec-line-max buffer: sec-line-buf

: check-expiry  ( exp$ -- exp$ -1|0 )
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
   2over  in-pubkey-list?   if                            ( sig$ exp$ )
      machine-id-buf d# 51 +  swap  move                  ( sig$ )
      machine-id-buf d# 67  2swap                         ( id$ sig$ )
      \     " sha256" signature-invalid?  if  -1  else  1  then ( -1|1 )
      " sha256" signature-good?  if  1  else  -1  then    ( -1|1 )
   else                                                   ( sig$ exp$ )
      4drop 0                                             ( 0 )
   then                                                   ( -1|0|1 )
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

: open-failed?  ( $ -- ih error? )
   expand$  .trying  r/o open-file
;

\ open-security looks for a file in the security directory.
\ On the NAND device, it first looks in a special security partition.

: open-security?  ( name$ -- ih error? )
   fn-buf place                                 ( )
   " ${DN}" expand$  " nand:" $=  if            ( )
      " ${DN}security,\${FN}" open-failed?  if  ( ih )
         drop                                   ( )
      else                                      ( ih )
         true exit
      then                                      ( )
   then
   " ${DN}\security\${FN}" open-failed?         ( ih error? )
;

\ lease-valid? tries to read a lease file from the currently-selected
\ device, searches it for a lease record corresponding to this machine,
\ and checks that record for validity.  The return value is true if
\ a valid lease was found.

: lease-valid?  ( -- valid? )
   " lease.sig"  open-security?  if  drop false exit  then   >r   ( r: ih )
   "   Lease " ?lease-debug
   load-started
   leasekey$ to pubkey$
   begin
      sec-line-buf /sec-line-max r@ read-line  if  ( actual -eof? )
         2drop  r> close-file drop  false exit
      then                                         ( actual -eof? )
   while                                           ( actual )
      sec-line-buf swap check-lease  case          ( -1|0|1 )
          1  of  r> close-file drop  show-unlock  true  exit  endof
         -1  of  r> close-file drop  show-lock    false exit  endof
      endcase
   repeat                                          ( actual )
   drop                                            ( )
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

   show-dot
   \ cn-buf is already set as a result of the ?leased that
   \ happened before loading the OS file
   " rd" bundle-present?  if
      r> to load-path

      "   RD found - " ?lease-debug
      img$  sig$  sha-valid?  if
         show-unlock
         img$ place-ramdisk
         exit
      else
         show-unlock
         fail-load
      then
   then
   r> to load-path
;

false value in-factory?

warning @ warning off
: stand-init-io
   stand-init-io
   " wp" find-tag  if  2drop  true to secure?  then
;

dev /client-services
: enter  ( -- )  secure? 0=  security-off?  or  if  visible enter  then  ;
: exit   ( -- )  secure?  if  security-failure  then  exit  ;
dend
warning !

: message-and-off  ( -- )
   aborted? @  if
      aborted? off
      ." Keyboard interrupt" cr
   else
      (.exception)
   then
   ." Powering off ..."
   d# 5000 ms
   power-off
;

: block-exceptions  ( -- )
   secure?  if   ['] message-and-off  to .exception  then
;
: unblock-exceptions  ( -- )  ['] .entry  to .exception  ;

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
   " develop.sig" open-security?  if  drop false exit  then   >r   ( r: ih )
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
   repeat                                          ( actual )
   drop                                            ( )
   "   No matching records" ?lease-error-cr        ( )
   r> close-file drop  false                       ( false )
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

: do-firmware-update  ( img$ -- )

\ Keep .error from printing an input sream position report
\ which makes a buffer@<address> show up in the error message
  ['] noop to show-error

  visible

   tuck flash-buf  swap move   ( len )

   ['] ?image-valid  catch  ?dup  if    ( )
      visible
      red-letters
      ." Bad firmware image file - "  .error
      ." Continuing with old firmware" cr
      black-letters
      exit
   then

   true to file-loaded?

   d# 12,000 wait-until   \ Wait for EC to notice the battery

   ['] ?enough-power  catch  ?dup  if
      visible
      red-letters
      ." Unsafe to update firmware now - " .error
      ."  Continuing with old firmware" cr
      black-letters
      exit
   then

   " Updating firmware" ?lease-debug-cr

   ec-indexed-io-off?  if
      visible
      ." Restarting to enable SPI FLASH writing."  cr
      d# 3000 ms
      ec-ixio-reboot
      security-failure
   then

   \ Latch alternate? flag for next startup
   alternate?  if  [char] A h# 82 cmos!  then

   reflash      \ Should power-off and reboot
   show-x
   " Reflash returned, unexpectedly" .security-failure
;

\ Turn off indexed I/O unless the OS is signed with the firmware
\ key in addition to the OS key.

: ?disable-indexed-io  ( -- )
   debug-security? >r  false to debug-security?
   pubkey$ 2>r  fwkey$ to pubkey$

   img$  sig$  fw-valid?  0=  if  ec-indexed-io-off  then

   2r> to pubkey$
   r> to debug-security?
;

: load-from-device  ( devname$ -- done? )

   show-dot
   null$ cn-buf place
   " bootfw" bundle-present?  if
      "   FW found - " ?lease-debug

      img$  firmware-up-to-date?  if
         show-plus
         " current FW is up-to-date" ?lease-debug-cr
      else
         show-minus
         " new - " ?lease-debug
         fwkey$ to pubkey$
         img$  sig$  fw-valid?  if
            img$  do-firmware-update
         then
         show-lock
      then
   then

   show-dot
   ?leased                \ Sets cn-buf

   show-dot
   " os" bundle-present?  if
      "   OS found - " ?lease-debug
      oskey$ to pubkey$
      img$  sig$  sha-valid?  if
\        ?disable-indexed-io
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

: set-cmdline   ( -- )
   " console=ttyS0,115200 console=tty0 fbcon=font:SUN12x22" args-buf place-cstr drop
;

: load-from-list  ( list$ -- devkey? )
   begin  dup  while                        ( list$ )
      ?unfreeze
      bl left-parse-string                  ( list$ devname$ )
      2dup dn-buf place                     ( list$ devname$ )

      show-dev-icon                         ( list$ )

      filesystem-present?  if               ( list$ )

         show-dot                           ( list$ )
         has-developer-key?  if             ( list$ )
            2drop                           ( )
            true to security-off?
            show-unlock
            true exit
         then                               ( list$ )

         load-from-device  if               ( list$ )
            ec-indexed-io-off               ( list$ )
            2drop                           ( )
            ['] secure-load-ramdisk to load-ramdisk
            " init-program" $find  if
               set-cmdline
               execute
               sound-end
               go
            then
            show-x
            security-failure
         then
      then                                  ( list$ )
   repeat                                   ( list$ )
   2drop false                              ( )
;

: persistent-devkey?  ( -- flag )
  button-x game-key?  if  false exit  then
  " dk" find-tag  dup  if  nip nip  then
;

: all-devices$  ( -- list$ )  " disk: ext-sba: int-sba: ext: int:"  ;

: secure-startup  ( -- )
   in-factory?  if
      button-check button-x or  button-o or  button-square or  button-rotate or  ( mask )
      game-key-mask =  if  0 to game-key-mask  sound-end exit  then
   then

   ['] noop to ?show-device
   ['] noop to load-done
   ['] noop to load-started

   set-alternate

\    button-rotate game-key?  if  show-warnings  then
\   show-child

   button-check game-key?  if
      unfreeze  visible  banner
   else
      freeze  dcon-freeze

[ifdef] jffs2-support
      \ The following is a hack to let the user unfreeze the screen during
      \ the several-second period while JFFS2 is scanning the NAND
      " dev /jffs2-file-system ' ?unfreeze to scan-callout  dend" eval
[then]
   then

   \ The screen may be frozen when we exit, because we want pretty
   \ boot even when not secure.

   ?force-secure
   persistent-devkey?  if  true to security-off?  exit  then
   secure?  0=  if  exit  then

   get-my-sn  if  " No serial number" .security-failure  then

   date-bad?  if
      \ This is not fatal, because we don't want a brick if the RTC battery fails
      visible  red-letters ." Invalid system date" black-letters cr  show-sad
      banner
   then

   load-crypto  if  " Crypto load failed" .security-failure   then       ( )

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
      dup d# 10 days>seconds +        ( begin-seconds end-seconds )
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
