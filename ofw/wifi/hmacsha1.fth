purpose: HMAC-SHA1 used for WPA-PSK
\ See license at end of file

\ ----------------------------------------------------------------------------
\ HMAC-SHA1 over data vector (RFC 2104)

d# 64 constant /keypad
/keypad buffer: keypad

: xor-keypad  ( adr c -- )
   swap /keypad bounds  do  i c@ over xor i c!  loop  drop
;
: xor-digest  ( src dst -- )
   /sha1-digest bounds  do		( src )
      dup c@ i c@ xor i c! 1+		( src' )
   loop  drop
;

: key>keypad  ( key$ -- )
   keypad /keypad erase
   keypad swap move
;

\ sha1-digest = SHA1 (K XOR opad, SHA1(K XOR ipad, text))
\   where K is an n byte key
\         ipad is 64 0x36
\         opad is 64 0x5c
\         text is the data being protected
\
/sha1-digest buffer: sha1-idigest	\ sha1-idigest = SHA1(K XOR ipad, text))
/sha1-digest buffer: sha1-tkey
: ?sha1-reset-key  ( passphrase$ -- key$ )
   dup d# 64 >  if			\ if len>64, key = SHA1(key)
      sha1
      sha1-tkey swap move		\ Save new key
      sha1-tkey /sha1-digest		( key$ )
   then
;
: hmac-sha1  ( datan$..data1$ n key$ -- digest$ )
   ?sha1-reset-key			( datan$..data1$ n key$' )
   2dup key>keypad >r >r		( datan$..data1$ n )  ( R: key$ )

   \ sha1-idigest = SHA1(K XOR ipad, text)
   keypad h# 36 xor-keypad		( datan$..data1$ n )  ( R: key$ )
   sha1-init				( datan$..data1$ n )  ( R: key$ )
   keypad /keypad sha1-update		( datan$..data1$ n )  ( R: key$ )
   0  ?do  sha1-update  loop		( )  ( R: key$ )
   sha1-final				( )  ( R: key$ )
   sha1-digest sha1-idigest /sha1-digest move	( )  ( R: key$ )

   \ sha1-digest = SHA1(K XOR opad, sha1-idigest)
   r> r> key>keypad			( )
   keypad h# 5c xor-keypad
   sha1-init
   keypad /keypad sha1-update
   sha1-idigest /sha1-digest sha1-update
   sha1-final

   sha1-digest /sha1-digest		( digest$ )
;

\ ----------------------------------------------------------------------------
\ SHA1-based key derivation function (PBKDF2) for IEEE 802.11i.
\ This function is used to derive PSK for WPA-PSK, described in IEEE
\ Std 802.11-2004, clause H.4.  The main contruction is from PKCS#5 v 2.0.

0 value pbkdf2-cnt
4 buffer: pbkdf2-cnt-buf
: pbkdf2-cnt++  ( -- )
   pbkdf2-cnt 1+ dup to pbkdf2-cnt
   pbkdf2-cnt-buf be-l!
;

/sha1-digest buffer: temp			\ Last digest
/sha1-digest buffer: temp2			\ Current digest
: (pbkdf2-sha1)  ( passphrase$ ssid$ -- )
   2over >r >r					( passphrase$ ssid$ )  ( R: passphrase$ )
   pbkdf2-cnt-buf 4 2swap 2 r> r> hmac-sha1	( passphrase$ digest$ )
   temp2 swap move				( passphrase$ )
   d# 4096 1  do
      sha1-digest temp /sha1-digest move	( passphrase$ )
      temp /sha1-digest 1 4 pick 4 pick hmac-sha1	( passphrase$ digest$ )
      drop temp2 xor-digest			( passphrase$ )
   loop	 2drop					( )
   temp2 sha1-digest /sha1-digest move
;

: pbkdf2-sha1  ( passphrase$ ssid$ psk$ -- )
   0 to pbkdf2-cnt
   begin  dup 0>  while			( passphrase$ ssid$ psk$ )
      pbkdf2-cnt++		 	( passphrase$ ssid$ psk$ )
      >r >r 2over 2over (pbkdf2-sha1)	( passphrase$ ssid$ )  ( R: psk$ )
      r> r> 2dup /sha1-digest min sha1-digest -rot move	( passphrase$ ssid$ psk$ )
      /sha1-digest /string		( passphrase$ ssid$ psk$' )
   repeat  2drop 2drop 2drop		( )
;

create zero 0 c,
create prf-cnt 0 c,
: zero$  ( -- adr len )  zero 1  ;
: sha1-prf  ( key$ label$ data$ result$ -- )
   0 prf-cnt c!
   begin  dup 0>  while			( key$ label$ data$ result$ )
      >r >r 		 		( key$ label$ data$ )  ( R: result$ )
      prf-cnt 1 2over zero$		( key$ label$ data$ cnt$ data$ zero$ )  ( R: result$ )
      9 pick 9 pick 4			( key$ label$ data$ cnt$ data$ zero$ label$ n )  ( R: result$ )
      d# 14 pick d# 14 pick hmac-sha1	( key$ label$ data$ digest$ )  ( R: result$ )
      r> r> 2swap 2over rot min move	( key$ label$ data$ result$ )
      /sha1-digest /string		( key$ label$ data$ result$' )
      prf-cnt c@ 1+ prf-cnt c!		( key$ label$ data$ result$ )
   repeat  2drop 2drop 2drop 2drop	( )
  
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
