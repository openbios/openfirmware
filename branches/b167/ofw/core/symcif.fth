\ ========== Copyright Header Begin ==========================================
\ 
\ Hypervisor Software File: symcif.fth
\ 
\ Copyright (c) 2006 Sun Microsystems, Inc. All Rights Reserved.
\ 
\  - Do no alter or remove copyright notices
\ 
\  - Redistribution and use of this software in source and binary forms, with 
\    or without modification, are permitted provided that the following 
\    conditions are met: 
\ 
\  - Redistribution of source code must retain the above copyright notice, 
\    this list of conditions and the following disclaimer.
\ 
\  - Redistribution in binary form must reproduce the above copyright notice,
\    this list of conditions and the following disclaimer in the
\    documentation and/or other materials provided with the distribution. 
\ 
\    Neither the name of Sun Microsystems, Inc. or the names of contributors 
\ may be used to endorse or promote products derived from this software 
\ without specific prior written permission. 
\ 
\     This software is provided "AS IS," without a warranty of any kind. 
\ ALL EXPRESS OR IMPLIED CONDITIONS, REPRESENTATIONS AND WARRANTIES, 
\ INCLUDING ANY IMPLIED WARRANTY OF MERCHANTABILITY, FITNESS FOR A 
\ PARTICULAR PURPOSE OR NON-INFRINGEMENT, ARE HEREBY EXCLUDED. SUN 
\ MICROSYSTEMS, INC. ("SUN") AND ITS LICENSORS SHALL NOT BE LIABLE FOR 
\ ANY DAMAGES SUFFERED BY LICENSEE AS A RESULT OF USING, MODIFYING OR 
\ DISTRIBUTING THIS SOFTWARE OR ITS DERIVATIVES. IN NO EVENT WILL SUN 
\ OR ITS LICENSORS BE LIABLE FOR ANY LOST REVENUE, PROFIT OR DATA, OR 
\ FOR DIRECT, INDIRECT, SPECIAL, CONSEQUENTIAL, INCIDENTAL OR PUNITIVE 
\ DAMAGES, HOWEVER CAUSED AND REGARDLESS OF THE THEORY OF LIABILITY, 
\ ARISING OUT OF THE USE OF OR INABILITY TO USE THIS SOFTWARE, EVEN IF 
\ SUN HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGES.
\ 
\ You acknowledge that this software is not designed, licensed or
\ intended for use in the design, construction, operation or maintenance of
\ any nuclear facility. 
\ 
\ ========== Copyright Header End ============================================
purpose: sym-to-name and name-to-sym callbacks into client program.
copyright: Copyright 1995 Sun Microsystems, Inc.  All Rights Reserved

headerless
0 value sym-to-value
0 value value-to-sym

0 value prev-s2v
0 value prev-v2s

: sym-to-value-str ( -- adr,len ) " sym-to-value" drop  ;
: value-to-sym-str ( -- adr,len ) " value-to-sym" drop  ;

h# 80 constant /symname-buf
/symname-buf buffer: symname-buf
6 /n* buffer: cif-symbol-array

: do-sym-to-value ( adr,len -- n true  | adr,len false )
   sym-to-value  if
      2dup 2>r
      sym-to-value-str  cif-symbol-array 0 na+ !
      1                 cif-symbol-array 1 na+ !
      2                 cif-symbol-array 2 na+ !
      symname-buf /symname-buf erase
      symname-buf swap /symname-buf min cmove
      symname-buf       cif-symbol-array 3 na+ !
      -1                cif-symbol-array 4 na+ !
      0                 cif-symbol-array 5 na+ !
      cif-symbol-array  sym-to-value  call 2drop
      2r>
      cif-symbol-array 4 na+ @  if  false  exit  then
      2drop  cif-symbol-array 5 na+ @  true  exit
   then  false
;

: do-value-to-sym  ( n -- offset adr,len true  |  n false )
   value-to-sym  if
      dup >r
      value-to-sym-str  cif-symbol-array 0 na+ !
      1                 cif-symbol-array 1 na+ !
      2                 cif-symbol-array 2 na+ !
      ( n )             cif-symbol-array 3 na+ !
      -1                cif-symbol-array 4 na+ !
      0                 cif-symbol-array 5 na+ !
      cif-symbol-array  value-to-sym  call  2drop
      r>
      cif-symbol-array 4 na+ @ l->n  -1  =  if  false  exit  then
      drop
      cif-symbol-array 4 na+ @
      cif-symbol-array 5 na+ @ cscount  true  exit
   then  false
;

headers
: symbol-lookup-off ( -- )
   sym-to-value ?dup  if  to prev-s2v  then
   value-to-sym ?dup  if  to prev-v2s  then
   0 to sym-to-value  0 to value-to-sym
;
: symbol-lookup-on ( -- )
   prev-s2v ?dup  if  to sym-to-value  then
   prev-v2s ?dup  if  to value-to-sym  then
;

headerless
create err-sym-not-found ," symbol not found "
headers
defer sym>value ( adr,len -- adr,len false | n true )
defer value>sym ( n -- offset adr,len true  |  n false )

: sym ( "name " -- n )
   parse-word sym>value  0=  if
      err-sym-not-found throw
   then
;

' do-sym-to-value is sym>value
' do-value-to-sym is value>sym

headers
also client-services definitions
: set-symbol-lookup  (  value-to-sym sym-to-value -- old-v2s  old-s2v )
   value-to-sym  sym-to-value  2swap    ( old-v2s old-s2v  v2s s2v )
   is sym-to-value  is value-to-sym     ( old-v2s old-s2v )
   0 to prev-s2v  0 to prev-v2s         ( old-v2s old-s2v )
;
previous definitions
