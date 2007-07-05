purpose: Block Address Translation register access
\ See license at end of file

hex

headerless
code ibat!  ( bat-lo bat-hi ibat# -- )
	lwz	t0,0(sp)
	lwz	t1,1cell(sp)

	cmpi	0,0,tos,0
	=  if
           sync  isync
	   mtspr  ibat0u,t0
	   mtspr  ibat0l,t1
           sync  isync
	else

	cmpi	0,0,tos,1
	=  if
           sync  isync
	   mtspr  ibat1u,t0
	   mtspr  ibat1l,t1
           sync  isync
	else

	cmpi	0,0,tos,2
	=  if
           sync  isync
	   mtspr  ibat2u,t0
	   mtspr  ibat2l,t1
           sync  isync
	else

	cmpi	0,0,tos,3
	=  if
           sync  isync
	   mtspr  ibat3u,t0
	   mtspr  ibat3l,t1
           sync  isync
	then then then then

	lwz	tos,2cells(sp)
	addi	sp,sp,3cells
c;

code dbat!  ( bat-lo bat-hi dbat# -- )
	lwz	t0,0(sp)
	lwz	t1,1cell(sp)

	cmpi	0,0,tos,0
	=  if
           sync  isync
	   mtspr  dbat0u,t0
	   mtspr  dbat0l,t1
           sync  isync
	else

	cmpi	0,0,tos,1
	=  if
           sync  isync
	   mtspr  dbat1u,t0
	   mtspr  dbat1l,t1
           sync  isync
	else

	cmpi	0,0,tos,2
	=  if
           sync  isync
	   mtspr  dbat2u,t0
	   mtspr  dbat2l,t1
           sync  isync
	else

	cmpi	0,0,tos,3
	=  if
           sync  isync
	   mtspr  dbat3u,t0
	   mtspr  dbat3l,t1
           sync  isync
	then then then then

	lwz	tos,2cells(sp)
	addi	sp,sp,3cells
c;

code ibat@  ( ibat# -- bat-lo bat-hi )
	cmpi	0,0,tos,0
	=  if
	   mfspr  tos,ibat0u
	   mfspr  t1,ibat0l
	else

	cmpi	0,0,tos,1
	=  if
	   mfspr  tos,ibat1u
	   mfspr  t1,ibat1l
	else

	cmpi	0,0,tos,2
	=  if
	   mfspr  tos,ibat2u
	   mfspr  t1,ibat2l
	else

	cmpi	0,0,tos,3
	=  if
	   mfspr  tos,ibat3u
	   mfspr  t1,ibat3l
	then then then then

	stwu	t1,-1cell(sp)
c;

code dbat@  ( dbat# -- bat-lo bat-hi )
	cmpi	0,0,tos,0
	=  if
	   mfspr  tos,dbat0u
	   mfspr  t1,dbat0l
	else

	cmpi	0,0,tos,1
	=  if
	   mfspr  tos,dbat1u
	   mfspr  t1,dbat1l
	else

	cmpi	0,0,tos,2
	=  if
	   mfspr  tos,dbat2u
	   mfspr  t1,dbat2l
	else

	cmpi	0,0,tos,3
	=  if
	   mfspr  tos,dbat3u
	   mfspr  t1,dbat3l
	then then then then

	stwu	t1,-1cell(sp)
c;

headers
0 constant ibat
1 constant dbat
2 constant i&dbats

headerless
false value l1-writethru?

: cache-mode  ( io? -- mode )
   if  38  else  10  l1-writethru?  if  40 or  then  then
;
: mask-bat-adr  ( adr -- hi-bits  )  1.ffff invert and  ;

headers
: bat!  ( pa va len io? bat# which -- )
   >r >r >r >r                              ( pa va ) ( R: which bat# io? len )
   mask-bat-adr r>                          ( pa BEPI len ) ( R: which bat# io)
   1- h# 11 >> 2 << or  2 or ( supervisor ) ( pa bat-hi )
   swap mask-bat-adr                        ( bat-hi BRPN )
   \ Coherent in both cases, no cache for I/O
   r>  cache-mode  or                       ( bat-hi BRPN|WIMG ) ( R: wh bat# )
   2 or ( r/w )  swap                       ( bat-lo bat-hi ) ( R: which bat# )
   r> r>  case
      dbat     of  dbat!  endof
      ibat     of  ibat!  endof
      i&dbats  of  3dup  dbat! ibat!  endof
   endcase
;

: bat@  ( bat# which -- false | pa va len flags true )
   dbat =  if  dbat@  else  ibat@  then         ( bat-lo bat-hi )
   dup 3 and  0=  if  2drop false exit  then    ( bat-lo bat-hi )
   over h# 7f and >r                            ( bat-lo bat-hi r: flags )
   swap mask-bat-adr swap                       ( pa bat-hi )
   dup mask-bat-adr swap                        ( pa va bat-hi )
   2 >> 7ff and 1+ h# 11 <<                     ( pa va len )
   r> true
;
headerless

\ Motorola says that the BAT registers can become corrupted if
\ two of them happen to map overlapping ranges, even if address
\ translation is turned off, and that said corruption can be prevented
\ by invalidating all the BAT registers before programming any of them.

: clear-bats  ( -- )  4 0  do  0 0 i ibat!  0 0 i dbat!  loop  ;
: clear-srs   ( -- )  10 0 do  0 i sr!  loop  ;

: .xbats  ( ibat|dbat -- )
   4 0  do
      dup ibat =  if  ." I"  else  ." D"  then
      i .
      i over bat@  if   ( pa va len flags )
         rot 9 u.r  rot d# 10 u.r  swap 9 u.r   ( flags )
         binary 2 spaces  <# u# u# 2/ ascii . hold u# u# u# u# u#> type  hex
      else
         ."  --invalid--"
      then
      cr
   loop
   drop
;
headers
: .bats  ( -- )
   base @ >r hex
   ."  #   Virtual  Physical   Length  WIMG.PP" cr
   ibat .xbats
   dbat .xbats
   r> base !
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
