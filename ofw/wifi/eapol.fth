purpose: WPA and WPA2 key handshake
\ See license at end of file

headers
hex

: vdump  ( adr len -- )  debug?  if  ??cr dump     else  2drop  then  ;
: vldump ( adr len -- )  debug?  if  ??cr ldump    else  2drop  then  ;
: vtype  ( adr len -- )  debug?  if  ??cr type cr  else  2drop  then  ;

\ =======================================================================
\ EAPOL data definitions

d# 10,000 constant eapol-wait

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
: compute-snonce  ( -- )  snonce 8 + dup @ over 4 + @ 1 0 d+ 2 pick 4 + ! swap !  ;

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
   >r 1 ptk >kck d# 16
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

false value done-group-key?

d# 32 dup constant /gtk  buffer: gtk
0 value gtk-idx				\ Active GTK idx

d# 32 buffer: ek			\ Temporary rc4 key

: install-group-key  ( -- )  gtk ctype-g ct>klen  set-gtk  ;

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
\ WPA/WPA2 pairwise keys four-way handshake

false value pairwise-rekey?
false value group-rekey?

/buf buffer: data

: kt>dtype    ( -- dtype )  ktype kt-wpa =  if  d# 254  else  2  then  ;
: pct>kinfo   ( -- kinfo )  ki-pairwise  ctype-p ct-aes =  if  ki-sha1-aes  else  ki-md5-rc4  then  or  ;
: pct>kinfo1  ( -- kinfo )  pct>kinfo ki-ack or  ;
: pct>kinfo2  ( -- kinfo )  pct>kinfo ki-mic or  ;
: pct>kinfo3  ( -- kinfo )  pct>kinfo2 ki-ack or ki-install or
                            ktype kt-wpa2 =  if  ki-encr-key or ki-secure or  then  ;
: pct>kinfo4  ( -- kinfo )  pct>kinfo2  ktype kt-wpa2 =  if  ki-secure or  then  ;

: wait-for-eapol-key  ( -- flag )
   false  eapol-wait 0  do
      data /buf read-force 0>  if
         data >etype be-w@ eapol-type =		\ EAPOL frame
         data >ptype c@ eapol-key =  and	\ EAPOL-key
         data >rcnt last-rcnt /rcnt comp and  if	\ A new eapol-key record
            data >rcnt last-rcnt!		\ Update last replay counter
            drop true
            leave
         then
      then
      1 ms
   loop
;

: process-1-of-4  ( -- ok? )
   " Process EAPOL-key message 1 of 4" vtype
   data >ver      c@ to eapol-ver
   data >dtype    c@ kt>dtype        <>  if  false exit  then	\ Descriptor type mismatch
   data >kinfo be-w@ pct>kinfo1      <>  if  false exit  then	\ Bad key info
   data >klen  be-w@ ctype-p ct>klen <>  if  false exit  then	\ Bad key len
   data >knonce anonce$ move					\ Save authenticator nonce
   true
;

: wait-for-1-of-4  ( -- ok? )
   " Waiting for EAPOL-key message 1 of 4..." vtype
   wait-for-eapol-key  if  process-1-of-4  else  false  then
;

: set-eapolbuf-common  ( -- )
   eapolbuf /eapol-key erase
   target-mac$ eapolbuf >dmac swap move		\ Destination MAC
   my-mac$     eapolbuf >smac swap move		\ Source MAC
   eapol-type  eapolbuf >etype be-w!		\ Ethernet packet type: 888e
   eapol-ver   eapolbuf >ver   c!		\ Version
   eapol-key   eapolbuf >ptype c!		\ EAPOL-key
   kt>dtype    eapolbuf >dtype c!		\ Descriptor type
   ctype-p ct>klen eapolbuf >klen be-w!		\ Key length
   last-rcnt   eapolbuf >rcnt /rcnt move	\ Replay counter
;
: send-2-of-4  ( -- error? )
   " Send EAPOL-key message 2 of 4" vtype
   compute-snonce
   compute-ptk-supplicant
   set-eapolbuf-common
   /eapol-body wpa-ie$ nip + eapolbuf >plen be-w!	\ Packet length
   pct>kinfo2  eapolbuf >kinfo be-w!		\ Key info
   snonce      eapolbuf >knonce /nonce move	\ Supplicant nonce
   wpa-ie$ nip eapolbuf >kdlen be-w!		\ Key data length
   wpa-ie$     eapolbuf >kdata swap move	\ Key data is WPA IE (or RSN IE)
   eapolbuf >ver eapolbuf >plen be-w@ 4 + ctype-p compute-mic
   mic         eapolbuf >kmic /mic move		\ Key mic
   eapolbuf /eapol-key wpa-ie$ nip + tuck write-force <>
;

: process-3-of-4  ( -- ok? )
   " Process EAPOL-key message 3 of 4" vtype
   data >dtype    c@ kt>dtype        <>  if  false exit  then	\ Descriptor type mismatch
   data >kinfo be-w@ pct>kinfo3      <>  if  false exit  then	\ Bad key info
   data >klen  be-w@ ctype-p ct>klen <>  if  false exit  then	\ Bad key len
   data >knonce anonce /nonce comp       if  false exit  then	\ Nonce differ
   data ctype-p mic-ok?              0=  if  true to pairwise-rekey? false exit  then	\ Bad mic
   data >kinfo be-w@ ki-encr-key and  if  data decrypt-parse-ie  else  true  then
;
: wait-for-3-of-4  ( -- ok? )
   " Waiting for EAPOL-key message 3 of 4..." vtype
   wait-for-eapol-key  if  process-3-of-4  else  false  then
;

: send-4-of-4  ( -- error? )
   " Send EAPOL-key message 4 of 4" vtype
   set-eapolbuf-common
   /eapol-body eapolbuf >plen  be-w!		\ Packet length
   pct>kinfo4  eapolbuf >kinfo be-w!		\ Key info
   eapolbuf >ver eapolbuf >plen be-w@ 4 + ctype-p compute-mic
   mic         eapolbuf >kmic /mic move		\ Key mic
   eapolbuf /eapol-key tuck write-force <>
;

: do-pairwise-key-handshake  ( -- ok? )
   false
   wait-for-1-of-4 0=  if  ." Failed to get the first pairwise key" cr exit  then
   send-2-of-4         if  ." Failed to send the second pairwise key" cr exit  then
   wait-for-3-of-4 0=  if  ." Failed to get the third pairwise key" cr exit  then 
   send-4-of-4         if  ." Failed to send the fourth pairwise key" cr exit  then
   install-pairwise-key
   done-group-key?  if  install-group-key  then
   drop true
;

\ =======================================================================
\ WPA group keys 2-way handshake

: gct>kinfo   ( -- kinfo )  ctype-g ct-aes =  if  ki-sha1-aes  else  ki-md5-rc4  then  ;
: gct>kinfo1  ( -- kinfo )  gct>kinfo ki-mic or ki-secure or ki-ack or  ;
: gct>kinfo2  ( -- kinfo )  gct>kinfo ki-mic or ki-secure or  ;

: process-1-of-2  ( --  ok? )
   " Process EAPOL-key message 1 of 2" vtype
   data >dtype    c@ kt>dtype        <>  if  false exit  then	\ Descriptor type mismatch data >kinfo be-w@ ki-idx-mask invert and gct>kinfo1 <>  if  false exit  then	\ Bad key info
   data >klen  be-w@ ctype-g ct>klen <>  if  false exit  then	\ Bad key len
   data ctype-p mic-ok?              0=  if  true to group-rekey? false exit  then	\ Bad mic
   data decrypt-gtk
;
: wait-for-1-of-2  ( -- ok? )
   " Waiting for EAPOL-key message 1 of 2..." vtype
   wait-for-eapol-key  if  process-1-of-2  else  false  then
;

: send-2-of-2  ( -- error? )
   " Send EAPOL-key message 2 of 2" vtype
   set-eapolbuf-common
   /eapol-body   eapolbuf >plen  be-w!		\ Packet length
   gct>kinfo2    eapolbuf >kinfo be-w!		\ Key info
   eapolbuf >ver eapolbuf >plen  be-w@ 4 + ctype-g compute-mic
   mic           eapolbuf >kmic  /mic move		\ Key mic
   eapolbuf /eapol-key tuck write-force <>
;

: do-group-key-handshake  ( -- )
   wait-for-1-of-2 0=  if  ." Failed to get the first group key" cr exit  then
   send-2-of-2         if  ." Failed to send the second group key" cr exit  then
   install-group-key
;

\ =======================================================================
\ WPA/WPA2 keys handshake

: request-rekey  ( ki-pairwise -- )
   " Send rekey message" vtype
   last-rcnt++
   set-eapolbuf-common
   0 eapolbuf >klen be-w!			\ Key length
   /eapol-body eapolbuf >plen  be-w!		\ Packet length
   ( ki-pairwise ) dup gct>kinfo or ki-request or ki-error or ki-mic or
   eapolbuf >kinfo be-w!			\ Key info
   eapolbuf >ver eapolbuf >plen be-w@ 4 +
   rot ( ki-pairwise )  if  ctype-p  else  ctype-g  then  compute-mic
   mic         eapolbuf >kmic /mic move		\ Key mic
   eapolbuf /eapol-key tuck write-force <>
;

: resync-gtk  ( -- )  0 request-rekey  ;

: (do-key-handshakes)  ( -- )
   false to done-group-key?
   false to pairwise-rekey?
   do-pairwise-key-handshake  if
      done-group-key? 0=  if
         2 0  do
            false to group-rekey?
            do-group-key-handshake
            group-rekey?  if  resync-gtk  else  leave  then
         loop
      then
   then
;

: do-key-handshakes  ( -- )
   2 0  do
      (do-key-handshakes)
      pairwise-rekey?  if  ki-pairwise request-rekey  else  leave  then
   loop
;


\ =======================================================================
\ Scan dump

: .on/off  ( flag -- )  if  ." on"  else  ." off"  then  cr  ;

: .rates  ( adr -- )
   dup 1+ c@  swap 2 + swap bounds  do
      i c@ h# 7f and 1 >> .d
   loop  cr
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
      d# 221  of  ." Wi-Fi Protected Access: " dup 2 + swap 1+ c@ cdump cr  endof
      ( default )  ." Unknown IE type: " swap dup 1+ c@ 2 +  cdump  cr
   endcase
;

: .bss-type  ( n -- )  1 =  if  ." Infrastructure"  else  ." Adhoc"  then  ;
: .cap  ( cap -- )
   ."     Type: " dup 3 and  .bss-type cr
   ."     WEP: " dup h# 10 and  .on/off
   ."     Short preamble: " dup h# 20 and  .on/off
   ."     Packet binary convolution coding: " dup h# 40 and  .on/off
   ."     Channel agility: " dup h# 80 and  .on/off
   ."     Short slot time: " dup h# 400 and  .on/off
   ."     DSSS-OFDM: " dup h# 2000 and and  .on/off
;

: .ap  ( adr -- )
   ."   Address: " dup 2 + .enaddr cr
   ."   RSSI: " dup 8 + c@ u. cr
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
: find-ie2  ( ie-adr,len adr ie-type -- adr len true | false )
   >r		   			( ie-adr,len adr )  ( R: ie-type )
   dup le-w@ swap 2 + swap d# 19 /string
					( ie-adr,len adr len )  ( R: ie-type )
   3 pick rot - -			( ie-adr,len len' )  ( R: ie-type )
   swap /string				( adr' len' )  ( R: ie-type )
   r> (find-ie)				( adr' len' true | false )
;
: find-ssid  ( ssid$ adr -- adr' true | false )
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
      kt-wep   of  am-shared set-auth-mode
                   wifi-wep4$ wifi-wep3$ wifi-wep2$ wifi-wep1$ wifi-wep-idx set-wep
		   disable-rsn
                   endof
      ( kt-wpa or kt-wpa2 )
                   am-open set-auth-mode
                   enable-rsn
                   disable-wep
   endcase
;

: set-bss-type  ( bss-type -- )  dup to bss-type  set-bss-type  ;

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
   wifi-pmk$ nip d# 32 =  
   atype at-preshared =  and
;

: key-ok?  ( -- ok? )
   ktype  case
      kt-none  of  true  endof
      kt-wep   of  wep-ok?  endof
      ( default )  pmk-ok? swap
   endcase
   dup  if  ." found"  else  ." Keys in wifi-cfg are not valid"  then  cr
;

h# 0050.f201 constant wpa-tag
: process-wpa-ie  ( ie-adr,len adr -- )
   \ Some AP such as Linksys has a bogus WPA IE in addition to the real thing.
   \ Skip over the bad one and see if there's another WPA IE
   2 pick be-l@ wpa-tag =  if  drop set-wpa-ktype exit  then
   d# 221 find-ie2  if
      over be-l@ wpa-tag =  if  set-wpa-ktype  else  2drop  then
   then
;

: ssid-valid?  ( adr -- flag )
   kt-none ktype!
   dup 2 + target-mac!				\ AP's mac address
   dup 8 + c@ rssi-ok? 0=  if  ." Signal too weak" cr drop false exit  then
   dup d# 19 + le-w@ 				\ Capabilities
   dup h# 10 and  if  kt-wep ktype!  then	\ Privacy
   dup  3 and  set-bss-type			\ BSS type: managed/adhoc
   dup 20 and  if  2 set-preamble  then		\ Short preamble
   h# 433 and set-cap				\ Set our own capabilities
   dup 1 find-ie  if  add-common-rates  then	\ Supported rates
   dup d# 50 find-ie  if  add-common-rates  then	\ Extended supported rates
   dup 3 find-ie 0=  if  ." Cannot locate the channel #" cr drop false exit  then
   drop c@ channel!				\ Channel number
   dup 6 find-ie  if  drop 2 + le-w@ set-atim-window  then	\ ATIM window
   dup 7 find-ie 0=  if  null$  then  do-set-country-info	\ Country channel/power info
   dup d# 48 find-ie  if  set-wpa2-ktype drop key-ok? exit  then	\ Favor RSN(WPA2) over WPA
   dup d# 221 find-ie  if  2 pick process-wpa-ie  then
   drop key-ok?
;

: (do-associate)  ( -- ok? )
   ??cr ." Associate with: " ssid$ type space
   channel ssid$ target-mac$ associate 0=  if  false exit  then
   cr
   ktype=wpa?  if
      do-key-handshakes
      done-group-key?
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

: scan-ssid?  ( ssid$ -- found? )
   dup 0=  if  2drop false exit  then 
   ssid!
   ssid$  " set-ssid" $call-parent
   ??cr ." Scan for: " ssid$ type space
   scanbuf /buf scan 0=  if  ." not found" cr false exit  then
   debug?  if  scanbuf .scan  then
   ssid$ scanbuf find-ssid 0=  if  ." not found" cr false exit  then
   init-common-rates
   ssid-valid? 0=  if  exit  then
   true valid!
   report-associate-info
   true
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
   data >ptype c@ eapol-key =  and  if		\ EAPOL-key
      data >rcnt last-rcnt /rcnt comp  if	\ A new eapol-key record
         " Got EAPOL-key message 1 of 2" vtype
         data >rcnt last-rcnt!			\ Update last replay counter
         process-1-of-2  if
            send-2-of-2 0=  if  install-group-key  then
         then
      then
   then
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
