\ OLPC boot script to set the XO system time from an OATS server
\ This can be signed and booted on secure machines to fix their clocks

\ Set this to the name or IP address of the deployment's OATS server
: server$  " 192.168.200.57"  ;  \ DNS name or IP address

\ Set this to the HTTP/1.1 name-based virtual host name of the OATS server
: host$  " antitheft.laptop.org"  ;

\ Replace this key with a deployment-specific one
create oats-pubkey
 " "(30 82 01 0a 02 82 01 01 00 cf 2c 9a 49 81 a9 dd)" $,
 " "(0e 39 e6 02 dc 9a 77 2e 9e cb 24 0c 1d 94 ec d3)" $,
 " "(e9 0a 86 58 fb c4 a1 f7 dd 06 d4 87 03 c3 04 8f)" $,
 " "(43 25 a9 27 62 9b 58 71 e2 39 f6 d5 55 35 37 d4)" $,
 " "(23 14 2a 10 fa b7 2f ad 4c d1 5c 9f c8 87 10 25)" $,
 " "(28 fd 72 b1 c6 87 8e 55 bd 77 a8 a4 84 d6 4a 41)" $,
 " "(7d 36 f2 7b 8e c3 67 3f d8 78 a5 69 10 86 b8 48)" $,
 " "(08 17 74 f9 7a 17 e3 9e c6 8a 41 bc 21 b8 1f 9d)" $,
 " "(02 e3 82 31 96 28 b8 92 b4 2b c0 10 c6 c5 8d d5)" $,
 " "(1b 2b 4b e1 cd 3d 21 76 1d 83 0a 65 88 ce 49 ad)" $,
 " "(8f 85 40 7a 16 d7 99 24 6b 72 5c f9 eb af b8 f9)" $,
 " "(d5 3d ed 90 5f 95 b0 51 8a b3 ed 16 8a 07 2a 89)" $,
 " "(ae 7f da 04 c8 14 01 86 04 ce 33 a6 3f 39 ce 79)" $,
 " "(bf af d4 81 e3 c6 1f 57 06 25 4f 3f 24 f7 28 38)" $,
 " "(6d 8b 34 5e fe da 86 cd 0f 9a 17 99 a7 c6 b2 57)" $,
 " "(ab 76 47 54 cb 11 a4 47 e0 9c 5e fa f1 2c 59 68)" $,
 " "(26 73 1e 7b 20 e8 9c 89 ab 02 03 01 00 01)" $,
here oats-pubkey - constant oats-pubkey-len

\ Canonical JSON parser

\ Look at the next character in the JSON stream, leaving it in the stream
: json-look  ( rem$ -- rem$ char )
   dup 0<= abort" Unexpected end of CJSON data"
   over c@
;

\ Discard the next character in the JSON stream
: json-skip  ( rem$ -- rem$' )  ( over c@ emit )  1 /string  ;

\ Get the next character from the JSON stream
: json-get  ( rem$ -- rem$' char )  json-look  >r  json-skip  r>  ;

\ Get the next JSON character and abort if is not the expected one
: json-expect  ( rem$ char -- rem$' )
   >r  json-get  r> <>  abort" Unexpected character in CJSON stream"
;

\ True if there is another object element
: json-element?  ( rem$ -- rem$' flag )
   json-look  case
      [char] ]  of  false  endof
      [char] ,  of  json-skip  true   endof
      ( default )  true swap
   endcase
;

: json-[  ( rem$ -- rem$' )  [char] [ json-expect  ;  \ Expect [ - start of array
: json-]  ( rem$ -- rem$' )  [char] ] json-expect  ;  \ Expect ] - end of array
: json-,  ( rem$ -- rem$' )  [char] , json-expect  ;  \ Expect , - another array element

\ Collect digits to form a nonnegative number
: json-digits  ( rem$ -- rem$' n )
   0  begin
      >r
      json-look  dup [char] 0  [char] 9  between  if
         [char] 0 -  r> d# 10 *  +  >r
         json-skip
      else
         drop  r>  exit
      then
      r>
   again
;

\ Collect a (possibly negative) number
: json-number  ( rem$ -- rem$' n )
   json-look  [char] -  =  if
      json-skip  json-digits  negate
   else
      json-digits
   then
;

: cjson-copy-escaped  ( adr len dest-adr -- dest$ )
   0  2swap   bounds ?do         ( dest-adr dest-len )
      i c@  dup [char] \ =  if   ( dest-adr dest-len char )
         drop                    ( dest-adr dest-len )
      else                       ( dest-adr dest-len char )
         2 pick 2 pick +  c!     ( dest-adr dest-len )
         1+                      ( dest-adr dest-len' )
      then                       ( dest-adr dest-len )
   loop                          ( dest-adr dest-len )
;

\ Collect a string.  Escape sequences are left in place - not converted -
\ to avoid the need for memory allocation.  Use cjson-copy-escaped if
\ you need to process escapes.
: json-"  ( rem$ -- rem$' $ )
   [char] " json-expect  ( rem$ )
   over 0                ( rem$ $ )
   begin                 ( rem$ $ )
      2>r
      json-look     ( rem$ char r: $ )
      case
         [char] "  of          ( rem$ )
	    json-skip     ( rem$' )
            2r> exit
         endof
         [char] \  of          ( rem$ )
            json-skip
            json-get
            2r> 1+ 2>r
         endof
         ( default )  >r  json-skip  r>
      endcase
      2r> 1+
   again
;

: json-{  ( rem$ -- rem$' )  [char] { json-expect  ;  \ Expect { - start of object
: json-}  ( rem$ -- rem$' )  [char] } json-expect  ;  \ Expect } - end of object
: json-:  ( rem$ -- rem$' )  [char] : json-expect  ;  \ Expect : - object value

\ True if there is another object pair
: json-pair?  ( rem$ -- rem$ flag )
   json-look  case
      [char] }  of  false   endof
      [char] ,  of  json-skip  true   endof
      ( default )  true swap
   endcase
;

\ Expect a literal string - implementation factor
: json$  ( rem$ $ -- rem$' )  bounds  ?do  i c@ json-expect  loop  ;   

: json-true   ( rem$ -- rem$' )  " true"  json$  ;  \ Expect literal 'true'
: json-false  ( rem$ -- rem$' )  " false" json$  ;  \ Expect literal 'false'
: json-null   ( rem$ -- rem$' )  " null"  json$  ;  \ Expect literal 'null'

\ Parse and discard a value - useful for skipping the value portion of uninteresting pairs
\ Forward referenced because arrays can contain values and values can be arrays
defer discard-json-value

\ Parse and discard an array - factor of discard-json-value
: discard-json-array   ( rem$ -- rem$' )
   json-[                        ( rem$' )
   begin  json-element?  while   ( rem$' )
      discard-json-value         ( rem$' )
   repeat                        ( rem$' )
   json-]                        ( rem$' )
;

\ Parse and discard an object - factor of discard-json-value
: discard-json-object  ( -- )
   json-{                        ( rem$' )
   begin  json-pair?  while       ( rem$' )
      json-" 2drop               ( rem$' )
      json-:                     ( rem$' )
      discard-json-value         ( rem$' )
   repeat                        ( rem$' )
   json-}                        ( rem$' )
;

\ Helper function used with Forth case statement to match a range of values
: range  ( selector low high -- selector n )
   2>r dup 2r> between  if  dup  else  dup invert  then   ( selector n )
;

\ Final implementation of the forward-referenced "discard-json-value"
: (discard-json-value)  ( rem$ -- rem$' )
   json-look  case
      [char] " of  json-"  2drop        endof
      [char] t of  json-true            endof
      [char] f of  json-false           endof
      [char] n of  json-null            endof
      [char] [ of  discard-json-array   endof
      [char] { of  discard-json-object  endof
      [char] - of  json-number drop     endof
      [char] 0 [char] 9 range  of  json-number  endof
      ( default )
      true abort" Invalid first character in JSON value"
   endcase
;
' (discard-json-value) to discard-json-value

\ End of generic canonical JSON code

\ Expect an envelope of the given name and version, leaving the CJSON
\ stream remainder at the enveloped contents
: envelope(  ( rem$ name$ version -- rem$' )
   >r  2>r                               ( rem$ r: version name$ )
   json-[                                ( rem$' r: version name$ )
   json-"                                ( rem$' $ r: version name$ )
   2r> $= 0=  abort" Wrong envelope"     ( rem$' r: version )
   json-,
   json-number                           ( rem$' n r: version )
   r> <> abort" Wrong envelope version"  ( rem$' )
   json-,                                ( rem$ )
   \ remainder starts with the envelope data
;

\ Expect the end of an envelope
: )envelope  ( rem$ -- rem$' )  json-]  ;


d# 256 buffer: nonce-data
: save-nonce  ( rem$ -- rem$' )
   json-"                            ( rem$' value$ )
   d# 255 min  nonce-data 1+  cjson-copy-escaped  ( rem$ $ )
   nonce-data c!  drop               ( rem$ )
;

d# 32 buffer: time-data
: save-time  ( rem$ -- rem$' )
   json-"                            ( rem$' value$ )
   d# 31 min  time-data 1+ cjson-copy-escaped    ( rem$ $ )
   time-data c!  drop                            ( rem$ )
;

: decode-oats-key  ( rem$ name$ -- rem$' )
   json-"                  ( rem$ name$ )
   2dup " nonce" $=  if    ( rem$ name$ )
      2drop                ( rem$ )
      json-:               ( rem$' )
      save-nonce           ( rem$' )
      exit                 ( -- rem$ )
   then                    ( rem$ name$ )
   2dup  " time" $=  if    ( rem$ name$ )
      2drop                ( rem$ )
      json-:               ( rem$' )
      save-time            ( rem$' )
      exit                 ( -- rem$ )
   then                    ( rem$ name$ )
   2drop                   ( rem$ )
   json-:                  ( rem$' )
   discard-json-value      ( rem$' )
;
: decode-oats-data  ( rem$ -- rem$' )
   " oatc-resp" 1 envelope(    ( rem$' )

   \ Enveloped data is an object { "nonce":value, "time":value, ... }
   json-{                      ( rem$' )
   begin  json-pair?  while    ( rem$' )
      decode-oats-key          ( rem$' )
   repeat                      ( rem$ )
   json-}                      ( rem$' )

   )envelope                   ( rem$' )
;

0 0 2value the-signature$
: decode-oats-credential   ( rem$ -- rem$' )
   " sig" 1 envelope(           ( rem$' )

   \ Enveloped data is an array of signatures - [ "sig01 ...", ... ]
   json-[                       ( rem$' )
   begin  json-element?  while  ( rem$' )
      json-"                    ( rem$ sig$ )
      to the-signature$         ( rem$' )
   repeat                       ( rem$ )
   json-]                       ( rem$' )

   )envelope                    ( rem$' )
;

: decode-oats-response  ( rem$ -- rem$' )
   " oatc-signed-resp" 1 envelope(  ( rem$' )
   \ Enveloped data is a 2-element array - [data,credential]

   json-[                           ( rem$' )
   over >r                          ( rem$  r: data-adr )
   decode-oats-data                 ( rem$' r: data-adr )
   r> 2 pick over - to signed-data$ ( rem$' )
   json-,                           ( rem$' )
   decode-oats-credential           ( rem$' )
   json-]                           ( rem$' )

   )envelope                        ( rem$' )
;

0 [if] \ Example request
POST /antitheft/1/ HTTP/1.1
Host: antitheft.laptop.org
Content-Type: application/x-www-form-urlencoded  
Content-Length: 43

serialnum=SHC12900018&version=1&nonce=12345678
[then]

0 [if] \ Example response
["oatc-signed-resp",1,[["oatc-resp",1,{"nonce":"12345678
","time":"20120619T144129Z"}],["sig",1,["sig01: sha256 b257ab764754cb11a447e09c5efaf12c596826731e7b20e89c89ab0203010001 8200ecb1b71df1119fceba00e8cca7b29b6e2870c7ab6224ca49e8a4a57b295edc733646ec5ae36767a403ebd43217185a46bb6d41c32f2d7ce4c33de6c4718a5e87e28349e9f72be719d6fcea35a37a3b68afc3b8a42d58333e7c6e78e1bb6f87dd106dce69dc191e1598514b63645f17a77be36128601950146c87b8702ba3474fc2289a589e38929f532cae683d6094171f7afa2c1765592216bdaa6c975916810b61db83a4a6f0a1b17f3f69559d45aebf64bb1c324fda2e97a044840556bfa688097ae77823447b07cdd5fce2f96bf990b11d7e6c409df2c42272d33805fb6fcdaa0ffd4d1b1ebeef44f458f1201fb484a43b4d10932862a3eba0b021e5
"]]]]
[then]

0 value http-ih
: $call-http http-ih $call-method ;
dev /http
\needs flush-writes  : flush-writes  " flush-writes" $call-parent  ;
\needs connect       : connect       " connect" $call-parent  ;
dend
: http-write  " tcp-write" $call-http  ;
: http-write-line   ( adr len -- )  http-write  " "r"n" http-write  ;
: http-read-line  ( -- adr len )  " get-line" $call-http  ;
   
: oats-send  ( msg$ -- )
   server$ " set-server" $call-http
   d# 80 " connect" $call-http  0=  abort" Can't connect to server"
   " POST /antitheft/1/ HTTP/1.1" http-write-line
   host$ " Host: %s" sprintf http-write-line
   " Content-Type: application/x-www-form-urlencoded" http-write-line
   dup " Content-Length: %d" sprintf http-write-line         ( msg$ )
   " " http-write-line                                       ( msg$ )
   http-write
   " flush-writes" $call-http
;
[ifndef] random-long
variable rn
: random-long  rn @  d# 1103515245 *  d# 12345 +   h# 7FFFFFFF and  dup rn !  ;
time&date >unix-seconds get-msecs xor rn !
[then]
0 value the-nonce
: oats-msg$  ( -- msg$ )
   random-long abs  dup to the-nonce   ( nonce )
   " SN" find-tag 0= abort" Machine has no serial number" ?-null  ( nonce sn$ )
   " serialnum=%s&version=1&nonce=%d" sprintf
;
h# 10000 buffer: oats-buf
: tread  
   oats-buf h# 10000 " wait-read" $call-http  dup  0>  if  oats-buf swap list  else  drop  then
;
: open-http  http-ih 0=  if  " http:" open-dev to http-ih  then  ;
: close-http  http-ih  if  http-ih close-dev  0 to http-ih  then  ;

: decimal-number  ( $ -- n )
   push-decimal  $number abort" Bad number"  pop-base
;

: (parse-time)  ( $ -- s m h d m y )
   d# 20 d# 20 numfield  >r                  ( rem$  r: century )
   d# 12 d# 40 numfield  r> d# 100 * +  >r   ( rem$  r: y )
   d#  1 d# 12 numfield  >r                  ( rem$  r: y m )
   d#  1 d# 31 numfield  >r                  ( rem$  r: y m d )

   1 cut$  " T" $= 0= abort" Expecting T in time"
   d#  0 d# 24 numfield  >r                  ( rem$  r: y m d h )
   d#  0 d# 59 numfield  >r                  ( rem$  r: y m d h m )
   d#  0 d# 59 numfield  >r                  ( rem$  r: y m d h m s )

   1 cut$  " Z" $= 0= abort" Expecting Z in time"  ( rem$  r: y m d h m s )
   0<> abort" Junk after time"  drop             ( r: y m d h m s )
   r> r> r> r> r> r>
;
: parse-time  ( $ -- s m h d m y )
   push-decimal ['] (parse-time) catch pop-base throw
;
: verify-oats  ( rem$ -- )
   dup  if  ." Extra stuff after OATS response: " list cr  else  2drop  then  ( )

   nonce-data count decimal-number the-nonce <> abort" Nonce mismatch"
   
   oats-pubkey-len to pubkeylen
   oats-pubkey oats-pubkey-len to pubkey$
   " sha256" to exp-hashname$
   the-signature$  begin  dup  while    ( rem$ )
      newline left-parse-string         ( rem$ line$ )
      this-sig-line-good? 0= abort" Bad signature"
   repeat                               ( rem$ )
   2drop
;

: time-from-oats
   load-crypto abort" Crypto load failed"
   open-http
   oats-msg$ ?save-string oats-send
   " check-header" ['] $call-http catch  if
      ." Bad HTTP header" cr
      close-http
      abort
   then
   " image-size" $call-http                 ( len )

   oats-buf over " wait-read" $call-http    ( len actual )
   close-http                               ( len actual )

   2dup <> if                               ( len actual )
      ." Wrong HTTP content length - Expected " swap .d ." got " .d cr
      abort
   then                                     ( len actual )

   nip  oats-buf swap decode-oats-response  ( adr len )
   verify-oats

   time-data count  parse-time " set-time" clock-node @ $call-method

   cr  ." Set clock to " .clock
;
time-from-oats
