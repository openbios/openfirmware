purpose: WPA and WPA2 key handshake
\ See license at end of file

headers
hex

: vdump  ( adr len -- )  debug?  if  ??cr dump     else  2drop  then  ;
: vldump ( adr len -- )  debug?  if  ??cr ldump    else  2drop  then  ;
: vtype  ( adr len -- )  debug?  if  ??cr type cr  else  2drop  then  ;

\ =======================================================================
\ Handshake variables and helper words

false value send-error?
2 constant send-retry-cnt

d# 30,000 constant timeout-eapol-limit
d#  5,000 constant timeout-msg-limit

0 value timeout-eapol         \ Global timeout value in ms
0 value timeout-msg           \ Timeout waiting for msg from AP in ms

: set-eapol-timeout  ( -- )  get-msecs timeout-eapol-limit + to timeout-eapol  ;
: set-msg-timeout    ( -- )  get-msecs timeout-msg-limit   + to timeout-msg    ;
: eapol-timeout?  ( -- timeout? )  get-msecs timeout-eapol >=  ;
: msg-timeout?    ( -- timeout? )  get-msecs timeout-msg   >=  ;
: timeout?        ( -- timeout? )  eapol-timeout? msg-timeout? or  ;

false value done-pairwise-key?
false value done-group-key?

: done?  ( -- done? )  done-group-key? done-pairwise-key? and  ;

: send-eapol-msg  ( adr len -- ok? )
   send-retry-cnt 0  do
      2dup tuck write-force =  if  2drop true unloop exit  then
   loop  2drop
   false  " Fail to send message" vtype
   true to send-error?
;

\ =======================================================================
\ EAPOL data definitions

1 value    eapol-ver
3 constant eapol-key
h# 888e constant eapol-type

d# 2048 constant /buf
/buf buffer: eapolbuf		\ EAPOL-key messages to send

\ bss-type values
1 constant bss-type-managed
2 constant bss-type-adhoc
0 value bss-type

d# 32 constant /tkip
d# 16 constant /aes

\ Definition of an EAPOL-key descriptor
struct				\ Big endian
  d#  6 field >dmac		\ Destination MAC
  d#  6 field >smac		\ Source MAC
  d#  2 field >etype		\ Ethernet packet type: 888e
  d#  1 field >ver		\ Version; 1: 802.1X-2001; 2: 802.1X-2004
  d#  1 field >ptype		\ Packet type; 3: EAPOL-key
  d#  2 field >plen		\ Packet body len
dup constant /eapol-hdr
  d#  1 field >dtype		\ Descriptor type: 1:RC4; 2:RSN; 254:WPA)
  d#  2 field >kinfo		\ Key info
  d#  2 field >klen		\ Target key len
  d#  8 field >rcnt		\ Replay counter
  d# 32 field >knonce		\ Key nonce
  d# 16 field >kiv		\ EAPOL-key IV
  d#  8 field >krsc		\ Key receive sequence counter
  d#  8 field >kid		\ Key identifier; not used in WPA
  d# 16 field >kmic		\ Key MIC
  d#  2 field >kdlen		\ Key data len
  0 field >kdata		\ Key data
dup constant /eapol-key
/eapol-hdr - constant /eapol-body

\ >kinfo bit definitions
0001 constant ki-md5-rc4	\ EAPOL MIC is calculated using HMAC-MD5;
				\ EAPOL key encryption is done using RC4
0002 constant ki-sha1-aes	\ EAPOL MIC is calculated using HMAC-SHA1;
				\ EAPOL key encryption is done using AES
0008 constant ki-pairwise	\ 0: group; 1: pairwise EAPOL key message
0030 constant ki-idx-mask	\ Key index for group keys
0040 constant ki-install	\ New key should be installed for pairwise keys
0080 constant ki-ack		\ Authenticator expects a response from the supplicant
0100 constant ki-mic		\ >kmic field is valid
0200 constant ki-secure		\ 4-way key exchange is complete (WPA2)
0400 constant ki-error		\ TKIP: mic failure detected by the supplicant,
				\ ki-request is also set to request a rekey operation
0800 constant ki-request	\ The supplicant requests a rekey operation
1000 constant ki-encr-key	\ >kdata encrypted (WPA2)
2000 constant ki-smk-msg	\ STSL master key

\ Vendor IE's OUI
h# 0050f2.01 constant oui-wpa         \ Microsoft OUI's
h# 0050f2.02 constant oui-wmm
h# 0050f2.04 constant oui-wps
h# 00904c.33 constant oui-ht          \ Broadcom OUI's
h# 00904c.34 constant oui-ht+

\ =======================================================================
\ Nonce

variable rn			\ Random number
/mac-adr /n + dup buffer: mac-time  value /mac-time

d# 32 constant /nonce
/nonce buffer: anonce		\ Authenticator nonce
/nonce buffer: snonce		\ Supplicant nonce

: init-cnt$  ( -- $ )  " Init Counter"  ;
: mac-time$  ( -- $ )  mac-time /mac-time  ;

: anonce$  ( -- adr len )  anonce /nonce  ;
: snonce$  ( -- adr len )  snonce /nonce  ;

\ inonce = prf-256 (Random Number, "Init Counter", MAC||time)
: random  ( -- )  rn @  h# 107465 *  h# 234567 +  rn !  ;
: randomize  ( -- )
   mac-adr$ mac-time swap move
   random
   rn @ mac-time /mac-adr + !
;
: init-nonce  ( -- )
   randomize
   rn /n init-cnt$ mac-time$ snonce$ sha1-prf  
;
: compute-snonce  ( -- )
   snonce 8 +  ( adr )
   dup d@      ( adr d )
   1.  d+      ( adr d' )
   rot d!      ( )
;

\ =======================================================================
\ Pairwise temporal keys (PTK)
\
\ Pairwise master keys (PMK) can be derived with:
\ passphrase$ ssid$ pmk$ pbkdf2-sha1

d# 16 dup constant /mic   buffer: mic
                   /mic   buffer: mic2

\ Temporary buffer for mic computation
/mac-adr 2* /nonce 2* + dup constant /tmic   buffer:  tmic

: ktype=wpa?  ( -- flag )  ktype kt-wpa =  ktype kt-wpa2 =  or  ;

: pair-exp$  ( -- $ )  " Pairwise key expansion"  ;
: peer-exp$  ( -- $ )  " Peer key expansion"  ;

: $<  ( $1 $2 -- $1<$2 )
   rot drop				( adr1 adr2 len )
   >r true -rot r>			( flag adr1 adr2 len )
   0  ?do				( flag adr1 adr2 )
      over i ca+ c@			( flag adr1 adr2 c1 )
      over i ca+ c@			( flag adr1 adr2 c1 c2 )
      2dup =  if			( flag adr1 adr2 c1 c2 )
         2drop				( flag adr1 adr2 )
      else				( flag adr1 adr2 c1 c2 )
         >  if  rot drop false -rot  then	( flag adr1 adr2 )
         leave				( flag adr1 adr2 )
      then				( flag adr1 adr2 )
   loop  2drop				( flag )
;

: compute-ptk  ( -- )
   \ Concatenate target-mac$ mac-adr$ snonce$ anonce$
   \ such that the lesser $ comes first
   target-mac$ my-mac$ 2over 2over $<  if  2swap  then
   tmic swap move  tmic /mac-adr + swap move
   anonce$ snonce$ 2over 2over $<  if  2swap  then
   tmic /mac-adr 2* + swap move  tmic /mac-adr 2* + /nonce + swap move

   wifi-pmk$
   bss-type bss-type-managed =  if  pair-exp$  else  peer-exp$  then
   tmic /tmic ptk /ptk sha1-prf
;

: compute-ptk-supplicant  ( -- )
   compute-ptk

   \ Supplicant: swap tx/rx keys
   ptk >tx-mic-key tmic 8 move
   ptk >rx-mic-key ptk >tx-mic-key 8 move
   tmic ptk >rx-mic-key 8 move
;

: ct>klen     ( ct -- klen )  ct-tkip =  if  /tkip  else  /aes  then  ;

: install-pairwise-key  ( -- )
   ptk >tk1 ctype-p ct>klen  set-ptk
   enforce-protection
;

\ =======================================================================
\ MIC
\ For TKIP,  mic = hmac-md5  (adr len)
\ For AES,   mic = hmac-sha1 (adr len)
: compute-mic  ( adr len ct -- )
   >r                                   ( adr len r: ct )
   1 ptk >kck d# 16                     ( adr len 1 'ptk-kck 16  r: ct )
   r> ct-tkip =  if  hmac-md5  else  hmac-sha1  then	( madr mlen )
   /mic min mic swap  move
;

: mic-ok?  ( adr ct -- ok? )
   >r					( adr )  ( R: ct )
   dup >kmic mic2 /mic move		( adr )  ( R: ct )	\ Save mic
   dup >kmic /mic erase			( adr )  ( R: ct )	\ Erase mic
   dup >ver swap >plen be-w@ 4 + r> compute-mic	( )	\ Compute mic
   mic mic2 /mic comp 0=		\ Compare computed mic with saved mic
;

\ =======================================================================
\ Group temporal keys (GTK)

d# 32 dup constant /gtk  buffer: gtk
0 value gtk-idx				\ Active GTK idx

d# 32 buffer: ek			\ Temporary rc4 key

: install-group-key  ( -- )  gtk ctype-g ct>klen  set-gtk  ;
: install-gtk-idx    ( -- )  ktype kt-wpa2 =  if  gtk-idx set-gtk-idx  then  ;

: set-gtk-supplicant  ( adr -- )
   dup gtk d# 16 move
   ctype-g ct-aes =  if  drop exit  then
   dup d# 24 + gtk d# 16 + 8 move	\ tx = rx
       d# 16 + gtk d# 24 + 8 move	\ rx = tx
;

: decrypt-rc4  ( adr -- ok? )
   dup >kiv ek d# 16 move
   ptk >kek ek d# 16 + d# 16 move
   dup >kdata swap >kdlen be-w@ ek d# 32 /s rc4-skip
   true
;

: decrypt-aes  ( adr -- ok? )
   dup >kdlen be-w@ 8 -			( adr len )
   dup >r alloc-mem 			( adr buf )  ( R: len )
   ptk >kek 2 pick >kdata r@ 3 pick aes-unwrap  if	( adr buf )  ( R: len )
      tuck over >kdata r@ move		( buf adr )  ( R: len )
      r@ swap >kdlen be-w!		( buf )  ( R: len )
      true 				( buf true )  ( R: len )
   else
      nip false				( buf false )  ( R: len )
   then
   swap r> free-mem			( flag )  ( R: len )
;

: decrypt-key-data  ( adr -- ok? )
   dup >kinfo be-w@ 7 and  ki-md5-rc4
   =  if  decrypt-rc4  else  decrypt-aes  then
;

: parse-generic  ( adr len -- )
   \ XXX Process other kinds of generic IE
   over be-l@ h# 000fac01 =  if
      over 4 + c@ 3 and  to gtk-idx
      drop 6 + set-gtk-supplicant
      true to done-group-key?
   else
      2drop
   then
;

: decrypt-parse-ie  ( adr -- ok? )
   dup decrypt-key-data

   \ Parse IEs
   swap dup >kdata swap >kdlen be-w@  begin  dup 0>  while	( ok? adr len )
      \ over c@ h# 30 =  if  ( XXX validate RSN IE )  then
      over c@ h# dd =  if  over dup 2 + swap 1+ c@ parse-generic  then
      over 1+ c@ 2 + /string		( ok? adr' len' )
   repeat  2drop			( ok? )
;

: decrypt-gtk  ( adr -- ok? )
   ktype kt-wpa2 =  if
      decrypt-parse-ie
   else
      dup decrypt-key-data dup to done-group-key? 
      if  >kdata set-gtk-supplicant  else  drop  then
      done-group-key?
   then
;

\ =======================================================================
\ WPA/WPA2 handshake states
\ State   Comment             Process
\  s1/4   initial state       Reset wait for 1/4 timeout
\         authenticate done   pairwise key received? = false
\         associate done      group key received? = false
\                             Wait for 1/4 msg from AP
\                             1/4 timeout -> exit fail
\  s3/4   got 1/4 msg         Send 2/4 msg to AP
\                             Reset 3/4 timeout
\                             Wait for 3/4 msg from AP
\                             3/4 timeout -> s2
\                             got 3/4 msg -> send 4/4 msg to AP
\                             If we got group key, exit ok
\                             Reset 1/2 timeout
\  s1/2   pairwise key done   Wait for 1/2 msg from AP
\                             1/2 timeout -> s2
\                             got 1/2 msg -> send 2/2 msg to AP
\                             exit ok
\  exit ok                    Install keys
\
\ Anytime a 1/4 msg is received, goto s3/4
\ Anytime deauthenticate is received, exit fail
\ Global timeout, exit fail

0 value eapol-state
0 constant s0/4          \ Initial state; also invalid msg
1 constant s1/4          \ Waiting for 1/4 from AP; also msg#
2 constant s3/4          \ Waiting for 3/4 from AP; also msg#
3 constant s1/2          \ Waiting for 1/2 from AP; also msg#

: set-s/4  ( -- )
   false to done-group-key?
   false to done-pairwise-key?
   set-msg-timeout
;
: set-s0/4  ( -- )  s0/4 to eapol-state  set-s/4  ;
: set-s1/4  ( -- )  s1/4 to eapol-state  set-s/4  ;
: set-s3/4  ( -- )  s3/4 to eapol-state  set-s/4  ;
: set-s1/2  ( -- )
   false to done-group-key?
   s1/2 to eapol-state
   set-msg-timeout
;

\ =======================================================================
\ WPA/WPA2 pairwise keys four-way handshake
\ WPA group key 2-way handshake

/buf buffer: data

: kt>dtype    ( -- dtype )  ktype kt-wpa =  if  d# 254  else  2  then  ;
: pct>kinfo   ( -- kinfo )  ki-pairwise  ctype-p ct-aes =  if  ki-sha1-aes  else  ki-md5-rc4  then  or  ;
: pct>kinfo1  ( -- kinfo )  pct>kinfo ki-ack or  ;
: pct>kinfo2  ( -- kinfo )  pct>kinfo ki-mic or  ;
: pct>kinfo3  ( -- kinfo )  pct>kinfo2 ki-ack or ki-install or
                            ktype kt-wpa2 =  if  ki-encr-key or ki-secure or  then  ;
: pct>kinfo4  ( -- kinfo )  pct>kinfo2  ktype kt-wpa2 =  if  ki-secure or  then  ;

: gct>kinfo   ( -- kinfo )  ctype-p ct-aes =  if  ki-sha1-aes  else  ki-md5-rc4  then  ;
: gct>kinfo1  ( -- kinfo )  gct>kinfo ki-mic or ki-secure or ki-ack or  ;
: gct>kinfo2  ( -- kinfo )  gct>kinfo ki-mic or ki-secure or  ;

: set-eapolbuf-common  ( -- )
   eapolbuf /eapol-key erase
   target-mac$ eapolbuf >dmac swap move		\ Destination MAC
   my-mac$     eapolbuf >smac swap move		\ Source MAC
   eapol-type  eapolbuf >etype be-w!		\ Ethernet packet type: 888e
   eapol-ver   eapolbuf >ver   c!		\ Version
   eapol-key   eapolbuf >ptype c!		\ EAPOL-key
   kt>dtype    eapolbuf >dtype c!		\ Descriptor type
   ctype-p ct>klen eapolbuf >klen be-w!		\ Key length
   last-rcnt@  eapolbuf >rcnt be-x!		\ Replay counter
;

: resync-gtk  ( -- )
   last-rcnt++
   set-eapolbuf-common
   0 eapolbuf >klen be-w!                         \ Key length
   /eapol-body eapolbuf >plen  be-w!              \ Packet length
   ctype-g ct>klen eapolbuf >klen  be-w!          \ Key length
   gct>kinfo ki-request or eapolbuf >kinfo be-w!  \ Key info
   eapolbuf /eapol-key send-eapol-msg
;

: send-2/4  ( -- ok? )
   " Send EAPOL-key message 2 of 4" vtype
   compute-snonce
   compute-ptk-supplicant
   set-eapolbuf-common
   /eapol-body wpa-ie$ nip + eapolbuf >plen be-w!       \ Packet length
   pct>kinfo2  eapolbuf >kinfo be-w!            \ Key info
   snonce      eapolbuf >knonce /nonce move     \ Supplicant nonce
   wpa-ie$ nip eapolbuf >kdlen be-w!            \ Key data length
   wpa-ie$     eapolbuf >kdata swap move        \ Key data is WPA IE (or RSN IE)
   eapolbuf >ver eapolbuf >plen be-w@ 4 + ctype-p compute-mic
   mic         eapolbuf >kmic /mic move         \ Key mic
   eapolbuf /eapol-key wpa-ie$ nip + send-eapol-msg 
;
: send-4/4  ( -- ok? )
   " Send EAPOL-key message 4 of 4" vtype
   set-eapolbuf-common
   /eapol-body eapolbuf >plen  be-w!            \ Packet length
   pct>kinfo4  eapolbuf >kinfo be-w!            \ Key info
   eapolbuf >ver eapolbuf >plen be-w@ 4 + ctype-p compute-mic
   mic         eapolbuf >kmic /mic move         \ Key mic
   eapolbuf /eapol-key send-eapol-msg 
;
: send-2/2  ( -- ok? )
   " Send EAPOL-key message 2 of 2" vtype
   set-eapolbuf-common
   /eapol-body     eapolbuf >plen  be-w!          \ Packet length
   gct>kinfo2      eapolbuf >kinfo be-w!          \ Key info
   ctype-g ct>klen eapolbuf >klen  be-w!          \ Key length
   eapolbuf >ver   eapolbuf >plen  be-w@ 4 + ctype-p compute-mic
   mic             eapolbuf >kmic  /mic move      \ Key mic
   eapolbuf /eapol-key send-eapol-msg 
;
: 1/4-valid?  ( -- ok? )
   data >dtype    c@ kt>dtype        <>  if  " 1d" vtype false exit  then  \ Descriptor type mismatch
   data >klen  be-w@ ctype-p ct>klen <>  if  " 1k" vtype false exit  then  \ Bad key len
   true
;
: process-1/4  ( -- )
   " Process EAPOL-key message 1 of 4" vtype
   data /eapol-key vdump
   eapol-state s1/4 <>  if
      " Unexpected pairwise key message 1 of 4" vtype
\      ." Possible bad WPA password" cr  abort
   then
   1/4-valid?  if
      data >ver c@ to eapol-ver
      data >knonce anonce$ move
      send-2/4  if  set-s3/4  then
   then
;
: 3/4-valid?  ( -- ok? )
   data >dtype    c@ kt>dtype        <>  if  " 3d" vtype false exit  then   \ Descriptor type mismatch
   data >klen  be-w@ ctype-p ct>klen <>  if  " 3k" vtype false exit  then   \ Bad key len
   data >knonce anonce /nonce comp       if  " 3n" vtype false exit  then   \ Nonce differ
   data ctype-p mic-ok?              0=  if  " 3m" vtype false exit  then   \ Bad mic
   data >kinfo be-w@ ki-encr-key and  if  data decrypt-parse-ie  else  true  then
;
: process-3/4  ( -- )
   " Process EAPOL-key message 3 of 4" vtype
   eapol-state s3/4 =  if
      3/4-valid?  if
         send-4/4  if
            install-pairwise-key
            true to done-pairwise-key?
            " Install pairwise key" vtype
            done-group-key?  if
               \ WPA2 3/4 contains the group key
               " Install group key" vtype
               install-gtk-idx
               install-group-key
            else
               " Wait for group key message 1 of 2" vtype
               set-s1/2
            then
         then
      then
   else
      " Unexpected pairwise key message 3 of 4" vtype
   then
;
: 1/2-valid?  ( -- ok? )
   data >dtype    c@ kt>dtype        <>  if  " 2d" vtype false exit  then  \ Descriptor type mismatch
   data >klen  be-w@ ctype-g ct>klen <>  if  " 2k" vtype false exit  then  \ Bad key len
   data ctype-p mic-ok?              0=  if  " 2m" vtype false exit  then  \ Bad MIC
   data decrypt-gtk
;
: process-1/2  ( -- )
   eapol-state s1/2 =  if
      1/2-valid?  if
         send-2/2  if
            " Install group key" vtype
            install-gtk-idx
            install-group-key
            true to done-group-key?
         then
      then
   else
      " Unexpected group key message 1 of 2" vtype
   then
;
: get-eapol-msg#  ( -- state )
   data >kinfo be-w@
   dup ki-pairwise and  if       \ Pairwise key info
      dup pct>kinfo1 =  if  drop s1/4 exit  then
          pct>kinfo3 =  if       s3/4 exit  then
   else
      ki-idx-mask invert and gct>kinfo1  =  if  s1/2 exit  then
   then
   s0/4
;
: process-eapol-key  ( -- )
   get-eapol-msg#  case
      s1/4  of  process-1/4  endof
      s3/4  of  process-3/4  endof
      s1/2  of  process-1/2  endof
   endcase
;
: (process-eapol)  ( -- )
   data >etype be-w@ eapol-type =         \ EAPOL frame
   data >ptype c@ eapol-key =  and  if    \ EAPOL-key
      data >ver c@ to eapol-ver
      data >rcnt be-x@  last-rcnt@ d>  if  \ A new eapol-key record
         data >rcnt be-x@  last-rcnt!      \ Update last replay counter
         process-eapol-key
      else
         " Same replay count; packet discarded" vtype
      then
   else
      " Non EAPOL frame received" vtype
   then
;
: (do-key-handshakes)  ( -- )
   begin
      data /buf read-force 0>  if  (process-eapol)  then
   timeout? disconnected? or done? or send-error? or  until
;
: do-key-handshakes  ( -- )
   false to send-error?
   set-eapol-timeout
   set-s1/4
   (do-key-handshakes)
   done? disconnected? or send-error? or  if  exit  then
   done-pairwise-key?  if
      " Timeout waiting for group key; request group key" vtype
      resync-gtk
      set-eapol-timeout
      set-s1/2
      (do-key-handshakes)
   else
      " Timeout waiting for 4-way handshake" vtype
   then
;

\ =======================================================================
\ Scan dump

: .on/off  ( flag -- )  if  ." on"  else  ." off"  then  cr  ;

: .rates  ( adr -- )
   dup 1+ c@  swap 2 + swap bounds  do
      i c@ h# 7f and 1 >> .d
   loop  cr
;

: .vendor  ( adr -- )
   dup 2 + swap 1+ c@              ( adr' len )
   ?dup 0=  if  drop exit  then
   dup 4 <  if  ." Vendor Specific: " cdump cr exit  then
   over be-l@  case                ( adr len )
      oui-wpa  of  ." WPA: "      endof
      oui-wmm  of  ." WMM: "      endof
      oui-wps  of  ." WPS: "      endof
      oui-ht   of  ." HT: "       endof
      oui-ht+  of  ." More HT: "  endof
      ( otherwise )  ." Vendor Specific: " 
   endcase
   cdump cr
;

: .ie  ( adr -- )
   dup c@   ."   "
   case 
      0  of  ." SSID: " dup 2 + swap 1+ c@ type cr  endof
      1  of  ." Supported rates (Mbit/s): " .rates  endof
      2  of  ." Frequency-hopping (FH) param set:" cr
             ."   Dwell time:  " dup 2 + le-w@ u. cr
             ."   Hop set:     " dup 4 + c@ u. cr
             ."   Hop pattern: " dup 5 + c@ u. cr
             ."   Hop index:   "     6 + c@ u. cr  endof
      3  of  ." Channel: " 2 + c@ .d cr  endof
      4  of  ." Contention-free (CF) param set:" cr
             ."   CFP count:        " dup 2 + c@ u. cr
             ."   CFP period:       " dup 3 + c@ u. cr
             ."   CFP max duration: " dup 4 + le-w@ u. cr
             ."   CFP rem duration: "     6 + le-w@ u. cr  endof
      5  of  ." Traffic Indicator Map (TIM): " cr
             ."   DTIM count:     " dup 2 + c@ u. cr
             ."   DTIM period:    " dup 3 + c@ u. cr
             ."   Bitmap control: " dup 4 + c@ u. cr
             ."   Bitmap:         " dup 5 + swap c@ 3 - cdump cr  endof
      6  of  ." ATIM window: " 2 + le-w@ u. cr  endof
      7  of  ." Country: " 2 + 3 type cr  endof		\ May have ch/pwr info also
      8  of  ." Hopping pattern params" drop cr  endof
      9  of  ." Hopping pattern table" drop cr  endof
      d# 10  of  ." Request" drop cr  endof
      d# 16  of  ." Challenge text: " dup 2 + swap 1+ c@ type cr  endof
      \ d# 32-41 are 802.11h IEs
      d# 42  of  ." ERP info:"
                 2 + c@ dup 1 and  if  ."  non-802.11g present;"  then
                        dup 2 and  if  ."  use protection;"  then
                            4 and  if  ."  Barker preamble mode"  then
                 cr endof
      d# 48  of  ." Robust security network: " dup 2 + swap 1+ c@ cdump cr  endof
      d# 50  of  ." Extended supported rates (Mbit/s): " .rates  endof
      d# 221  of  .vendor  endof
      ( default )  ." Unknown IE type: " swap dup 1+ c@ 2 +  cdump  cr
   endcase
;

: .bss-type  ( n -- )  1 =  if  ." Infrastructure"  else  ." Adhoc"  then  ;
: .cap  ( cap -- )
   ."     Type: " dup 3 and  .bss-type cr
   ."     Security: " dup h# 10 and  .on/off
   ."     Short preamble: " dup h# 20 and  .on/off
   ."     Packet binary convolution coding: " dup h# 40 and  .on/off
   ."     Channel agility: " dup h# 80 and  .on/off
   ."     Short slot time: " dup h# 400 and  .on/off
   ."     DSSS-OFDM: " dup h# 2000 and and  .on/off
;

: .ap  ( adr -- )
   ."   Address: " dup 2 + .enaddr cr
   ."   RSSI: " dup 8 + c@ .d cr
   ."   Beacon interval: " dup d# 17 + le-w@ .d cr
   ."   Capabilities: " dup d# 19 + le-w@ cr .cap
   dup le-w@ swap 2 + swap d# 19 /string	( adr' len' )
   begin  dup 0>  while			( adr len )
      over .ie				( adr len )
      over 1+ c@ 2 + /string		( adr' len' )
   repeat  2drop			( )
;

: .scan  ( adr -- )
   dup 3 +				( 'ap )
   swap 2 + c@				( 'ap #ap )
   0  ?do				( 'ap )
      cr
      ." Cell " i 1+ .d cr		( 'ap )
      dup .ap				( 'ap )
      dup le-w@ + 2 +			( 'ap' )
   loop  drop				( )
;

: .ie-short  ( adr -- )
   dup c@    ( adr ie )
   case 
      0  of  ." SSID: " dup 2 + swap 1+ c@ type  2 spaces  endof
      3  of  ." Channel: " 2 + c@ .d   endof
      ( default )  nip
   endcase
;

0 value scanbuf-end

: .ap-ssid  ( adr -- )
   dup le-w@ over + 2 + scanbuf-end >=  if  drop exit  then

   ." RSSI: " dup 8 + c@ .d 
   dup le-w@ swap 2 + swap d# 19 /string	( adr' len' )
   begin  dup 0>  while			( adr len )
      over .ie-short			( adr len )
      over 1+ c@ 2 + /string		( adr' len' )
   repeat  2drop			( )
;

: .ssids  ( adr len -- )
   over + to scanbuf-end		( adr )

   dup le-w@				( adr size )
   over + scanbuf-end >=  if
      ." scan truncated" cr
   then					( adr )

   dup 3 +				( adr 'ap )
   swap 2 + c@				( 'ap #ap )
   0  ?do				( 'ap )
      dup .ap-ssid  cr			( 'ap )
      dup le-w@ + 2 +			( 'ap' )
      dup scanbuf-end >=  if  drop unloop exit  then
   loop  drop				( )
;

: #ssids  ( adr -- n )  2 + c@	;

\ =======================================================================
\ Associate

/buf buffer: scanbuf

: (find-ie)  ( adr len ie-type -- adr len true | false )
   >r
   false -rot				( flag adr len )  ( R: ie-type )
   begin  2 pick 0= over 0> and  while	( flag adr len )  ( R: ie-type )
      over c@ r@ =  if			( flag adr len )  ( R: ie-type )
         rot drop true -rot		\ Found it
      else
         over 1+ c@ 2 + /string		( flag adr' len' )  ( R: ie-type )
      then
   repeat  r> drop			( flag adr len )
   rot  if  drop dup 1+ c@ swap 2 + swap true  else  2drop false  then
					( adr' len' true | false )
;
: find-ie  ( adr ie-type -- adr len true | false )
   >r					( adr )  ( R: ie-type )
   dup le-w@ swap 2 + swap d# 19 /string	( adr' len' )
   r> (find-ie)				( adr' len' true | false )
;
: find-ssid  ( ssid$ scanbuf-adr -- ap-adr' true | false )
   false swap				( ssid$ flag adr )
   dup 3 +				( ssid$ flag 'ap )
   swap 2 + c@				( ssid$ flag 'ap #ap )
   0  ?do				( ssid$ flag 'ap )
      dup 0 find-ie  if			( ssid$ flag 'ap $ )
         5 pick 5 pick $=  if  nip true swap leave  then
      then				( ssid$ flag 'ap )
      dup le-w@ + 2 +			( ssid$ flag 'ap' )
   loop  2swap 2drop			( flag 'ap )
   swap dup 0=  if  nip  then		( 'ap true | false )
;

: rssi-ok?  ( rssi -- flag )  drop true  ;	\ XXX

\ Authentication mode
0 constant am-open
1 constant am-shared
2 constant am-eap


0 value supported-rates
0 value #rates
0 value common-rates

0 value cr-idx					\ Index into common-rates
: supported-rate?  ( r -- true | false )
   h# 7f and false swap #rates 0  ?do
      supported-rates i + c@ h# 7f and over =  if  nip true swap leave  then
   loop  drop
;
: add-common-rates  ( adr len -- )
   bounds  ?do
      i c@ ?dup  if
         dup supported-rate?  if
            common-rates cr-idx + c!
            cr-idx 1+ to cr-idx
         else
            drop
         then
      then
   loop
;
: init-common-rates  ( -- )
   supported-rates$ to #rates to supported-rates
   #rates alloc-mem to common-rates
   common-rates #rates erase
   0 to cr-idx
;
: report-common-rates  ( -- )
   common-rates #rates set-common-rates
   common-rates #rates free-mem
;
: report-associate-info  ( -- )
   report-common-rates
   ctype-p ctype-g ktype set-key-type
   ktype  case
      kt-none  of  am-open set-auth-mode
                   disable-rsn
                   disable-wep
                   endof
      kt-wep   of  am-open set-auth-mode
                   \ Open authentication is best for WEP because it prevents attacks
                   \ on the authentication challenge that can lead to key recovery.
	           \ If open authentication fails, the driver can retry the association
	           \ attempt with shared key mode.
                   wifi-wep4$ wifi-wep3$ wifi-wep2$ wifi-wep1$ wifi-wep-idx set-wep
		   disable-rsn
                   endof
      ( kt-wpa or kt-wpa2 )
                   am-open set-auth-mode
                   enable-rsn
                   disable-wep
   endcase
;

: remember-bss-type  ( bss-type -- )  dup to bss-type  set-bss-type  ;

: do-set-country-info  ( adr len -- )
   country-ie-len  if  2drop country-ie-buf country-ie-len  then  \ Override the country IE
   3 / 3 *				\ Remove pad byte
   ?dup 0=  if  drop exit  then		\ Nothing to set
   set-country-info
;

: set-wpa-atype  ( adr -- )
   at-none atype!
   dup le-w@ swap 2 + swap		( adr' cnt )
   0  ?do
     dup i 4 * + 3 + c@  dup  atype >  if  atype!  else  drop  then
   loop  drop
;
: set-wpa-ctype-p  ( adr -- )
   ct-none ctype-p!
   dup le-w@ swap 2 + swap		( adr' cnt )
   0  ?do
     dup i 4 * + 3 + c@  4 =  if  ct-aes  else  ct-tkip  then
     dup ctype-p >  if  ctype-p!  else  drop  then
   loop  drop
;
: set-wpa-ctype  ( adr len -- )
   drop dup 5 + c@  4 =  if  ct-aes  else  ct-tkip  then
   ctype-g!				\ Group cipher type
   6 + dup set-wpa-ctype-p		\ Pairwise cipher type
   dup le-w@ 4 * + 2 +
   set-wpa-atype
;

: set-wpa-ktype  ( adr len -- )  kt-wpa  ktype! 4 /string set-wpa-ctype  ;	\ Skip the WPA tag
: set-wpa2-ktype ( adr len -- )  kt-wpa2 ktype! set-wpa-ctype  ;

\ WEP is not ok if the configured indexed key is null or invalid lengths
: wep-ok?  ( -- flag )
   wifi-wep-idx  case
      0  of  wifi-wep1$  endof
      1  of  wifi-wep2$  endof
      2  of  wifi-wep3$  endof
      3  of  wifi-wep4$  endof
   endcase  nip dup 5 = swap d# 13 = or
;

: pmk-ok?  ( -- flag )
   atype at-preshared <>  if  false exit  then

   \ If necessary, compute the PMK (pairwise master key) from the PSK (pre-shared key)
   \ The PSK is the user-visible password, whereas the PMK is a hash of the PSK and
   \ the SSID which is used in the key exchange.
   wifi-pmk$ nip  case  ( length )
      0  of                                           ( )
         wifi-psk$ wifi-ssid$ pad d# 32 pbkdf2-sha1   ( )
         pad d# 32 $pmk                               ( )
         true                                         ( okay? )
      endof

      d# 32  of
	 true                                         ( okay? )
      endof

      ( default )  false swap
   endcase                                            ( okay? )
;

: key-ok?  ( -- ok? )
   ktype  case
      kt-none  of  true  endof
      kt-wep   of  wep-ok?  endof
      ( default )  pmk-ok? swap
   endcase
   dup  0=  if  ." Keys in wifi-cfg are not valid - "  then
;

: (process-vendor-ie)  ( adr -- )
   dup 2 + swap 1+ c@              ( adr' len )
   dup 4 >  if
      over be-l@ oui-wpa =  if  set-wpa-ktype exit  then
   then  2drop
;

: process-vendor-ie  ( adr -- )
   dup le-w@ swap 2 + swap d# 19 /string   ( adr' len )
   begin  dup 0>  while                    ( adr len )
      over c@ h# dd =  if  over (process-vendor-ie)  then
      over 1+ c@ 2 + /string               ( adr' len' )
   repeat  2drop
;

: ssid-valid?  ( adr -- flag )
   kt-none ktype!
   dup 2 + target-mac!				\ AP's mac address
   dup 8 + c@ rssi-ok? 0=  if  ." Signal too weak" cr drop false exit  then
   dup d# 19 + le-w@ 				\ Capabilities
   dup h# 10 and  if  kt-wep ktype!  then	\ Privacy
   dup  3 and  remember-bss-type		\ BSS type: managed/adhoc
   dup 20 and  if  2 set-preamble  then		\ Short preamble
   h# 433 and set-cap				\ Set our own capabilities
   dup 1 find-ie  if  add-common-rates  then	\ Supported rates
   dup d# 50 find-ie  if  add-common-rates  then	\ Extended supported rates
   dup 3 find-ie 0=  if  ." Cannot locate the channel #" cr drop false exit  then
   drop c@ channel!				\ Channel number
   dup 6 find-ie  if  drop 2 + le-w@ set-atim-window  then	\ ATIM window
   dup 7 find-ie 0=  if  null$  then  do-set-country-info	\ Country channel/power info
   dup d# 48 find-ie  if  set-wpa2-ktype drop key-ok? exit  then	\ Favor RSN(WPA2) over WPA
   dup process-vendor-ie                        \ E.g. WPA
   drop key-ok?
;

: (do-associate)  ( -- ok? )
   ??cr ." Associate with: " ssid$ type space
   channel ssid$ target-mac$ associate 0=  if  false exit  then
   cr
   ktype=wpa?  if
      ['] do-key-handshakes catch  if
         false
      else
         done?
      then
   else
      true
   then
;

\ Don't rescan the second time unless forced to
: must-scan?  ( -- flag )
   ssid-reset?   false to ssid-reset?    ( flag )
   scan? or  false to scan?              ( flag' )
   valid? 0= or
;

: (select-ssid?)  ( ssid$ -- found? )
   scanbuf find-ssid 0=  if  false exit  then    ( ap-adr )
   init-common-rates                     ( ap-adr )
   ssid-valid? 0=  if  false exit  then  ( )
   true valid!                           ( )
   report-associate-info                 ( )
   true                                  ( found? )
;
: select-ssid?  ( volatile-scanbuf-adr,len ssid$ -- found? )
   ssid!                                 ( volatile-scanbuf$ )
   dup /buf >  if                        ( volatile-scanbuf$ )
      ." Scan buffer too long" cr        ( volatile-scanbuf$ )
      2drop false exit                   ( -- found? )
   then                                  ( volatile-scanbuf$ )
   scanbuf swap move                     ( )
   ssid$ (select-ssid?)                  ( found? )
;

create scan-order
   d#  6 c, d#  1 c, d# 11 c,

   d#  2 c, d#  3 c, d#  4 c, d#  5 c, d#  7 c, d#  8 c,
   d#  9 c, d# 10 c, d# 12 c, d# 13 c, d# 14 c,

   d# 36 c, d# 40 c, d# 44 c, d# 48 c,
   d# 52 c, d# 56 c, d# 60 c, d# 64 c,

   d# 100 c, d# 104 c, d# 108 c,
   d# 112 c, d# 116 c, d# 132 c, d# 136 c,

   d# 140 c, d# 149 c, d# 153 c,
   d# 157 c, d# 161 c, d# 165 c,
here scan-order - constant /scan-order

: test-association  ( adr len -- error? )
   " OLPCOFW" select-ssid?  if
      (do-associate)  if
         target-mac$ " disassociate" $call-parent
         true to ssid-reset?
      then
   then
;

: scan-all  ( -- error? )
   scan-order /scan-order bounds do           ( )
      scanbuf /buf  i c@                      ( adr len chan )
      scan  if                                ( actual )
         ?dup  if                             ( actual )
            scanbuf swap                      ( adr actual )
            2dup .ssids                       ( adr actual )
            test-association
         then
      else                                    ( )
         unloop true exit
      then
   loop
   false
;

: scan-ssid?  ( ssid$ -- found? )
   dup 0=  if  2drop false exit  then         ( ssid$ )
   ssid!                                      ( )
   ssid$  " set-ssid" $call-parent            ( )
   ??cr ." Scan for: " ssid$ type space       ( )

   scan-order /scan-order bounds do           ( )
      scanbuf /buf  i c@                      ( adr len chan )
      scan  if                                ( actual )
         if                                   ( )
            debug?  if  scanbuf .scan  then   ( )
            ssid$ (select-ssid?)              ( found? )
            if
               ." found"  cr unloop true exit
            then                              ( )
         then
      then
   loop
   ." not found"  cr  false                   ( found? )
;

: try-scan  ( -- okay? )
   wifi-ssid$  scan-ssid?  if  true exit  then
   default-ssids  begin  dup  while   ( rem$ )
      newline left-parse-string       ( rem$' ssid$ )
      scan-ssid?  if  2drop true exit  then  ( rem$ )
   repeat                             ( rem$ )
   2drop false
;

: do-associate  ( -- ok? )
   disable-protection
   must-scan?  if  try-scan  0= if  false exit  then  then
   (do-associate)  dup 0=  if  true to scan?  then
;


\ =======================================================================
\ Intercept and process dynamic GTK changes

: process-eapol  ( adr len -- )
   " Process EAPOL message" vtype
   2dup vdump
   data swap move
   set-s1/2
   (process-eapol)
;


\ =======================================================================
\ Standard methods

: parse-args  ( $ -- )
   begin  ?dup  while
      ascii , left-parse-string
      2dup " debug" $=  if  true to debug?  then
      2dup " scan"  $=  if  true to scan?   then	\ Force scan even if ssid$ is same
      2dup drop " country" comp 0=  if		        \ Force different country IE
         2dup [char] = left-parse-string  2drop
         2dup upper  set-country-ie
      then
      2drop
   repeat drop
;

: open  ( -- ok? )
   my-args parse-args
   mac-adr$ init-wifi-data
   first-open?  if
      false to first-open?
      get-msecs rn !
      init-nonce
   then
   true
;

: close  ( -- )  ;


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
