purpose: ATH9K key cache manipulation
\ See license at end of file

headers
hex

0 value keymax
0 value crypt-caps
1 constant CRYPT_CAP_CIPHER_AESCCM
2 constant CRYPT_CAP_MIC_COMBINED

/mac-adr buffer: keymac
0 value keyptr
0 value rxmicptr
0 value txmicptr
: set-key-mac  ( idx -- )
   5 << 8800 +                                ( reg-base )
   keymac le-l@ 1 >>  keymac 4 + le-w@ 1 and d# 31 << or  ( reg-base macL )
   over d# 24 + reg!                          ( reg-base )
   keymac c@ 1 and  if  0  else  8000  then   ( reg-base unicast )
   keymac 4 + le-w@ 1 >> or                   ( reg-base macH )
   swap d# 28 + reg!                          ( )
;

: set-key-entry  ( type idx -- )
   tuck 5 << 8800 +                           ( idx type reg-base )
   keyptr         le-l@  over         reg!
   keyptr     4 + le-w@  over     4 + reg!
   keyptr     6 + le-l@  over     8 + reg!
   keyptr d# 10 + le-w@  over d# 12 + reg!
   keyptr d# 12 + le-l@  over d# 16 + reg!
                              d# 20 + reg!
   ( idx )  set-key-mac
;
: set-key-wep  ( -- )
   wep1 to keyptr
   /wep1     5 =  if  KEYTABLE_TYPE_40   0 set-key-entry  then
   /wep1 d# 13 =  if  KEYTABLE_TYPE_104  0 set-key-entry  then
   wep2 to keyptr
   /wep2     5 =  if  KEYTABLE_TYPE_40   1 set-key-entry  then
   /wep2 d# 13 =  if  KEYTABLE_TYPE_104  1 set-key-entry  then
   wep3 to keyptr
   /wep3     5 =  if  KEYTABLE_TYPE_40   2 set-key-entry  then
   /wep3 d# 13 =  if  KEYTABLE_TYPE_104  2 set-key-entry  then
   wep4 to keyptr
   /wep4     5 =  if  KEYTABLE_TYPE_40   3 set-key-entry  then
   /wep4 d# 13 =  if  KEYTABLE_TYPE_104  3 set-key-entry  then
;
: set-key-aes  ( -- )
   p-aes to keyptr
   KEYTABLE_TYPE_CCM pair-idx set-key-entry
;
: set-key-aes-group  ( -- )
   g-aes to keyptr
   KEYTABLE_TYPE_CCM grp-idx set-key-entry
;
: set-tkip-entry  ( type idx -- )
   tuck 5 << 8800 +                           ( idx type reg-base )
   keyptr         le-l@ invert over         reg!
   keyptr     4 + le-w@ invert over     4 + reg!
   keyptr     6 + le-l@        over     8 + reg!
   keyptr d# 10 + le-w@        over d# 12 + reg!
   keyptr d# 12 + le-l@        over d# 16 + reg!
   ( type )                    tuck d# 20 + reg!
   swap set-key-mac                           ( reg-base )

   rxmicptr     le-l@  over  800 + reg!
   txmicptr 2 + le-w@  over  804 + reg!
   rxmicptr 4 + le-l@  over  808 + reg!
   txmicptr     le-w@  over  80c + reg!
   txmicptr 4 + le-l@  over  810 + reg!
   KEYTABLE_TYPE_CLR   over  814 + reg!
   0                   over  818 + reg!
   0                   over  81c + reg!

   keyptr     le-l@ over     reg!
   keyptr 4 + le-w@ swap 4 + reg!
;
: set-key-tkip  ( -- )
   p-tkip to keyptr
   p-tkip d# 24 + to rxmicptr
   p-tkip d# 16 + to txmicptr
   KEYTABLE_TYPE_TKIP pair-idx set-tkip-entry
;
: set-key-tkip-group  ( -- )
   keymac /mac-adr erase  1 keymac c!
   g-tkip to keyptr
   ap-mode?  if
      g-tkip d# 16 + to rxmicptr
      g-tkip d# 16 + to txmicptr
   else
      g-tkip d# 24 + to rxmicptr
      g-tkip d# 24 + to txmicptr
   then
   KEYTABLE_TYPE_TKIP grp-idx set-tkip-entry
;

: set-key-cache  ( -- )
   target-mac keymac /mac-adr  move
   key-wep?  if  set-key-wep exit  then
   pkey-tkip?  if  set-key-tkip  then
   pkey-aes?   if  set-key-aes   then
\   keymac c@ 1 or keymac c!        \ Multicast key for AP or adhoc
   gkey-tkip?  if  set-key-tkip-group  then
   gkey-aes?   if  set-key-aes-group  then
;

: reset-key  ( i -- )
   dup 5 << 8800 +                 ( i reg-base )
   dup d# 20 + reg@ swap           ( i type reg-base )
   0 over         reg!  0 over     4 + reg!
   0 over     8 + reg!  0 over d# 12 + reg!
   0 over d# 16 + reg!  7 over d# 20 + reg!   \ CLR
   0 over d# 24 + reg!  0 swap d# 28 + reg!  ( i type )
   4 =  if      \ TKIP             ( i )
      d# 64 + 5 << 8800 +          ( reg-base )
      0 over         reg!  0 over     4 + reg!
      0 over     8 + reg!  0 over d# 12 + reg!
      0 over d# 16 + reg!  7 over d# 20 + reg!   \ CLR if MIC_COMBINED
   then  drop
;

: reset-key-cache  ( -- )
   keymax 0  do  i reset-key  loop
;

\ LICENSE_BEGIN
\ Copyright (c) 2011 FirmWorks
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
