purpose: SHA-1 message-digest routines
\ See license at end of file

headers
also 386-assembler definitions
: bswap  ( reg -- )
   7  [ also forth ]  and  [ previous ]  h# 0f asm8,  h# c8 +  asm8,
;
previous definitions

headerless

[ifndef] 2tuck  : 2tuck  ( d1 d2 -- d2 d1 d2 )  2swap 2over  ;  [then]

0 value 'sha1-digest
0 value 'sha1-block
0 value 'sha1-icount
0 value 'sha1-abcde

d# 20 dup constant /sha1-digest
      buffer: sha1-digest	\ content is computed as the secure hash
d# 64 dup constant /sha1-block
      buffer: sha1-block	\ buffer for intermediate calculation
2variable sha1-icount		\ intermediate size in bits of the message
2variable sha1-fcount		\ final size in bits of the message
create sha1-byte 0 c,		\ used when padding the msg to a multiple
				\ of 512 bits
create sha1-abcde 0 l, 0 l, 0 l, 0 l, 0 l,
0 /n* constant sha1-a
1 /n* constant sha1-b
2 /n* constant sha1-c
3 /n* constant sha1-d
4 /n* constant sha1-e

\ Convert between big-endian and little-endian cells.
\ Used here to convert to big-endian.  Used in `sha1-final`.
code flip-endian  ( 01020304 -- 04030201 )
   eax pop
   eax bswap
   eax push
c;

\ Convert the first 16 cells of `sha1-block` to `work-block`.
: sha1-blk0  ( eax: i -- edx: x )
   " 2 # al shl" evaluate
   " 'user 'sha1-block eax add" evaluate
   " 0 [eax] edx mov" evaluate
   " edx bswap" evaluate
   " edx 0 [eax] mov" evaluate
;

\ Convert the remaining cells of `sha1-block` to `work-block`.
: sha1-blk  ( ecx: i eax: i -- edx: x )
   " d# 13 # al add  d# 15 # al and  2 # al shl  'user 'sha1-block eax add" evaluate
   " 0 [eax] edx mov  ecx eax mov" evaluate
   " d#  8 # al add  d# 15 # al and  2 # al shl  'user 'sha1-block eax add" evaluate
   " 0 [eax] edx xor  ecx eax mov" evaluate
   " d#  2 # al add  d# 15 # al and  2 # al shl  'user 'sha1-block eax add" evaluate
   " 0 [eax] edx xor  ecx eax mov" evaluate
   "                 d# 15 # al and  2 # al shl  'user 'sha1-block eax add" evaluate
   " 0 [eax] edx xor" evaluate
   " 1 # edx rol" evaluate		\ Operation added for SHA-1
   " edx 0 [eax] mov" evaluate
;

\ `sha1-f  sha1-g  sha1-h`
\       The nonlinear functions for scrambling the
\       data.  The names are taken from A. J. Menezes, _Handbook
\       of Applied Cryptography_, ISBN 0-8493-8523-7.  Used in
\       `transform`.
\ mix
\       The unchanging part of the scrambling.  Used in `transform`.
: sha1-f  ( esi: sha1-abcde -- ebx: [b&[c xor d]] xor d )
   " sha1-d [esi] eax mov " evaluate
   " eax ebx mov" evaluate		\ ebx = d
   " sha1-c [esi] eax xor" evaluate	\ eax = c xor d
   " sha1-b [esi] eax and" evaluate	\ eax = (c xor d) & b
   " eax ebx xor" evaluate		\ ebx = ((c xor d) & b) xor d
;

: sha1-g  ( esi: sha1-abcde -- ebx: [b&c]|[[b|c]&d] )
   " sha1-b [esi] eax mov" evaluate	\ eax = b
   " sha1-c [esi] ebx mov" evaluate	\ ebx = c
   " ebx edx mov" evaluate		\ edx = c
   " eax ebx or" evaluate		\ ebx = b|c
   " sha1-d [esi] ebx and" evaluate	\ ebx = (b|c)&d
   " eax edx and" evaluate		\ edx = b&c
   " edx ebx or" evaluate		\ ebx = (b&c)|((b|c)&d)
;

: sha1-h  ( esi: sha1-abcde -- ebx: b xor c xor d )
   " sha1-b [esi] ebx mov" evaluate	\ ebx = b
   " sha1-c [esi] ebx xor" evaluate	\ ebx = b xor c
   " sha1-d [esi] ebx xor" evaluate	\ ebx = b xor c xor d
;

: sha1-mix  ( esi: sha1-abcde ebx: temp edx: m -- )
   " ebx edx add" evaluate			\ edx = temp = temp + m
   " sha1-a [esi] ebx mov" evaluate		\ ebx = a
   " 5 # ebx rol" evaluate			\ ebx = a rol 5
   " ebx edx add" evaluate			\ edx = temp = temp + (a rol 5)
   " sha1-e [esi] edx add" evaluate		\ edx = temp = temp + e
   " sha1-d [esi] ebx mov		    ebx sha1-e [esi] mov" evaluate
   " sha1-c [esi] ebx mov 		    ebx sha1-d [esi] mov" evaluate
   " sha1-b [esi] ebx mov  d# 30 # ebx rol  ebx sha1-c [esi] mov" evaluate
   " sha1-a [esi] ebx mov		    ebx sha1-b [esi] mov" evaluate
   "					    edx sha1-a [esi] mov" evaluate
;

\ Fetch the values from sha1-digest. Used in `transform`.
: fetch-sha1-digest  ( -- esi: sha1-abcde )
   " 'user 'sha1-digest ebx mov" evaluate
   " 'user 'sha1-abcde  esi mov" evaluate
   " sha1-a [ebx] eax mov   eax sha1-a [esi] mov" evaluate
   " sha1-b [ebx] eax mov   eax sha1-b [esi] mov" evaluate
   " sha1-c [ebx] eax mov   eax sha1-c [esi] mov" evaluate
   " sha1-d [ebx] eax mov   eax sha1-d [esi] mov" evaluate
   " sha1-e [ebx] eax mov   eax sha1-e [esi] mov" evaluate
;

\ Accumulate into sha1-digest.  Used in `transform`.
: add-to-sha1-digest  ( esi: sha1-abcde -- )
   " 'user 'sha1-digest ebx mov" evaluate
   " sha1-a [esi] eax mov   eax sha1-a [ebx] add" evaluate
   " sha1-b [esi] eax mov   eax sha1-b [ebx] add" evaluate
   " sha1-c [esi] eax mov   eax sha1-c [ebx] add" evaluate
   " sha1-d [esi] eax mov   eax sha1-d [ebx] add" evaluate
   " sha1-e [esi] eax mov   eax sha1-e [ebx] add" evaluate
;

\ Hash the 512 bits of `sha1-block` into the
\ cells of `sha1-digest`.  Does 80 rounds of complicated
\ processing for each 512 bits.  Used in `sha1-update`.
label sha1-transform  ( -- )
   fetch-sha1-digest

   \ Do 80 rounds of complicated processing.
   ecx ecx xor
   begin
      sha1-f 				\ ebx = temp
      h# 5a82.7999 # ebx add
      ecx eax mov
      sha1-blk0				\ eax = m
      sha1-mix
      cl inc
      d# 16 # cl cmp
   = until

   begin
      sha1-f 				\ ebx = temp
      h# 5a82.7999 # ebx add
      ecx eax mov
      sha1-blk				\ eax = m
      sha1-mix
      cl inc
      d# 20 # cl cmp
   = until

   begin
      sha1-h 				\ ebx = temp
      h# 6ed9.eba1 # ebx add
      ecx eax mov
      sha1-blk				\ eax = m
      sha1-mix
      cl inc
      d# 40 # cl cmp
   = until

   begin
      sha1-g 				\ ebx = temp
      h# 8f1b.bcdc # ebx add
      ecx eax mov
      sha1-blk				\ eax = m
      sha1-mix
      cl inc
      d# 60 # cl cmp
   = until

   begin
      sha1-h 				\ ebx = temp
      h# ca62.c1d6 # ebx add
      ecx eax mov
      sha1-blk				\ eax = m
      sha1-mix
      cl inc
      d# 80 # cl cmp
   = until

   add-to-sha1-digest
   ret
end-code

: sha1-init  ( -- )
    \ Initialize sha1-digest with starting constants.
    sha1-digest
    h# 6745.2301 over l! la1+
    h# efcd.ab89 over l! la1+
    h# 98ba.dcfe over l! la1+
    h# 1032.5476 over l! la1+
    h# c3d2.e1f0 swap l!
    \ Zero bit count.
    0 0 sha1-icount 2!
;

1 /n* constant sha1-alen
2 /n* constant sha1-astr

code sha1-update  ( str len -- )
   esi push

   \ Transform 512-bit blocks of message.
   begin
      \ Compute the # of bytes to copy to sha1-block for transformation
      'user 'sha1-icount ebx mov
      4 [ebx] eax mov
      d# 511 # eax and
      3 # eax shr			\ eax = byte[ic]
      d# 64 # ebx mov
      eax ebx sub			\ ebx = 64-ic
      sha1-alen [esp] ebx cmp
      u<=  while
         sha1-astr [esp] esi mov	\ esi = str
         edi push
	 'user 'sha1-block edi mov	\ edi = adr(sha1-block)
         eax edi add			\ edi = adr(sha1-block)+ic
         ebx ecx mov			\ ecx = # bytes to copy
         rep movsb
         edi pop
	 ebx sha1-alen [esp] sub	\ len = len - 64-ic
	 ebx sha1-astr [esp] add	\ adr = adr + 64-ic
	 ebx push
	 sha1-transform #) call
         eax pop
         'user 'sha1-icount ebx mov
	 3 # eax shl
	 eax 4 [ebx] add		\ increment ic
	 0 # 0 [ebx] adc
   repeat

   \ Save final fraction of input
   sha1-astr [esp] esi mov
   sha1-alen [esp] ecx mov
   edi push
   'user 'sha1-block edi mov
   eax edi add				\ edi = adr(sha1-block)+ic
   ecx eax mov				\ eax = # bytes to copy
   rep movsb
   edi pop
   'user 'sha1-icount ebx mov
   3 # eax shl
   eax 4 [ebx] add			\ increment ic
   0 # 0 [ebx] adc

   esi pop
   eax pop  eax pop
c;

: sha1-final  ( -- )
   \ Save sha1-icount for final padding.
   sha1-icount 2@
   in-little-endian?  if	\ little-endian to big-endian.
      flip-endian swap flip-endian swap
   then
   sha1-fcount 2!

   \ Pad so sha1-icount is 64 bits less than a multiple of 512.
   sha1-byte h# 80 over c!  1 sha1-update
   begin  sha1-icount la1+ @ d# 511 and d# 448 = not while
      sha1-byte 0 over c!  1 sha1-update
   repeat

   sha1-fcount 8 sha1-update

   in-little-endian?  if	\ little-endian to big-endian
      sha1-digest /sha1-digest bounds  do
         i l@ i be-l!
      /l +loop
   then
;

headers

: .sha1  ( -- )
   sha1-digest /sha1-digest bounds  do
      i be-l@
      (.8) type space
   /l +loop
;

: sha1 ( adr len -- digest len )
   sha1-init
   sha1-update
   sha1-final
   sha1-digest /sha1-digest
;

: init-'sha1  ( -- )
   sha1-digest to 'sha1-digest
   sha1-block  to 'sha1-block
   sha1-icount to 'sha1-icount
   sha1-abcde  to 'sha1-abcde
;

also forth definitions
stand-init: Init SHA-1 variables
   init-'sha1
;
previous definitions

init-'sha1


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

