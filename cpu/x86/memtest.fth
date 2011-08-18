purpose: Memory test primitives in assembly language
\ See license at end of file

headers
\needs mask  nuser mask  mask on
headerless

\ Report the progress through low-level tests
0 0 2value test-name
: (quiet-show-status)  ( adr len -- )  to test-name  ;

defer show-status
' type to show-status

: bits-run  ( adr len pattern -- fail? )
   "  "  show-status dup .x  ." pattern    "
   3dup lfill            ( adr len pattern )
   3dup lskip            ( adr len pattern residue )
   dup  if               ( adr len pattern residue )
      ." FAILED - got "  ( adr len pattern residue )
      nip - +            ( adr' )
      dup l@ .x  ." at " .x  cr   ( )
      true
   else                  ( adr len pattern residue )
      ." passed"         ( adr len pattern residue )
      4drop false
   then
;
: mem-bits-test  ( membase memsize -- fail-status )
   2dup h# aaaaaaaa bits-run  if  true exit  then
   h# 55555555 bits-run
;

code inc-fill  ( adr len -- )
   cx pop  2 # cx shr
   ax pop
   begin
      ax  0 [ax]  mov
      4 [ax]  ax  lea
   loopa
c;

code inc-check  ( adr len -- false | adr data true )
   cx pop  2 # cx shr
   ax pop
   begin
      0 [ax]  bx  mov
      bx ax cmp  <>  if
         ax push  bx push  -1 # push
         next
      then
      4 [ax]  ax  lea
   loopa
   ax ax xor  ax push
c;

: address=data-test  ( membase memsize -- fail-status )
   "     Address=data test" show-status
   2dup inc-fill     ( membase memsize )
   inc-check         ( false | adr data true )
   if
      ." FAILED - got " .x ." at " .x cr
      true
   else
      ." passed"
      false
   then
;

\ random-fill uses registers where possible to minimize memory accesses.
\ Stack use by random-fill:                    register usage:
\ 0 /l*          push esi
\ 1 /l*          pop polynomial;  push edi     ebx = polynomial
  2 /l* constant rf-idx                      \ edi = idx/4
  3 /l* constant rf-dta                      \ eax = data
  4 /l* constant rf-len                      \ esi = len/4, ecx = counter
  5 /l* constant rf-adr                      \ edx = adr

code random-fill  ( adr len data index polynomial -- )
   ebx pop                  \ ebx: polynomial
   edi push  esi push       \ Save esi and edi

   rf-len [esp] ecx mov	    \ Convert to 32-bit word count
   2 # ecx shr	    	    \ ecx: remaining count

   0<>  if
      ecx esi mov           \ esi: index upper limit
      ecx dec

      rf-dta [esp] eax mov  \ eax: data
      rf-idx [esp] edi mov  \ edi: index
      rf-adr [esp] edx mov  \ edx: base address

      begin
         \ Compute new data value with an LFSR step
         1 # eax shr
         carry?  if  h# 8020.0003 # eax xor  then

         \ Compute new address index, discarding values >= len
         begin
	    1 # edi shr
	    carry?  if  ebx edi xor  then
            esi edi cmp
         u< until

         \ Write the "random" value to the "random" address (adr[index])
         eax 0 [edx] [edi] *4 mov
      loopa

   then
   esi pop  edi pop
   4 /l* # esp add          \ Remove the remaining arguments on the stack
c;

\ random-check uses registers where possible to minimize memory accesses.
\ Stack use by random-check:                   register usage:
\ 0 /l*          push esi
\ 1 /l*          pop polynomial;  push edi     ebx = polynomial
  2 /l* constant rc-rem                      \ ecx = remain (counter)
  3 /l* constant rc-idx                      \ edi = idx/4
  4 /l* constant rc-dta                      \ eax = data
  5 /l* constant rc-len                      \ esi = len/4
  6 /l* constant rc-adr                      \ edx = adr

code random-check  ( adr len data index remain polynomial -- false | adr len data index remain true )
   1 /l* [esp] ecx mov          \ ecx: remain
   ecx ecx or                   \ Check remain
   0=  if
      \ No more memory to check
      6 /l* # esp add           \ Remove the arguments on the stack
      0 # push                  \ Return false
      next
   then

   \ Check memory
   ebx pop                      \ ebx: polynomial
   edi push  esi push           \ Save esi and edi

   rc-len [esp] esi mov         \ esi: index upper limit
   2 # esi shr	                \ Convert to 32-bit word count
   rc-dta [esp] eax mov         \ eax: data
   rc-idx [esp] edi mov         \ edi: index
   rc-adr [esp] edx mov         \ edx: base address

   begin
      \ Compute new data value with an LFSR step
      1 # eax shr
      carry?  if  h# 8020.0003 # eax xor  then

      \ Compute new address index, discarding values >= len
      begin
         1 # edi shr
         carry?  if  ebx edi xor  then
         esi edi cmp
      u< until

      \ Compare the "random" value to the "random" address (adr[index])
      \ with the calculated data value
      eax 0 [edx] [edi] *4 cmp
      <>  if
         eax rc-dta [esp] mov   \ Calculated data value
         edi rc-idx [esp] mov   \ Index where failure occurred
         ecx dec
         ecx rc-rem [esp] mov   \ Update remain
         esi pop  edi pop
         -1 # push              \ Return true
         next
      then
   loopa

   esi pop  edi pop
   5 /l* # esp add              \ Remove the remaining arguments on the stack
   0 # push                     \ Return false
c;

\ Polynomials for maximal length LFSRs for different bit lengths
\ The values come from the Wikipedia article for Linear Feedback Shift Register and from
\ http://www.xilinx.com/support/documentation/application_notes/xapp052.pdf
create polynomials \ #bits   period
h#        0 ,      \     0        0
h#        1 ,      \     1        1
h#        3 ,      \     2        3
h#        6 ,      \     3        7
h#        c ,      \     4        f
h#       14 ,      \     5       1f
h#       30 ,      \     6       3f
h#       60 ,      \     7       7f
h#       b8 ,      \     8       ff
h#      110 ,      \     9      1ff
h#      240 ,      \    10      3ff
h#      500 ,      \    11      7ff
h#      e08 ,      \    12      fff
h#     1c80 ,      \    13     1fff
h#     3802 ,      \    14     3fff
h#     6000 ,      \    15     7fff
h#     b400 ,      \    16     ffff
h#    12000 ,      \    17    1ffff
h#    20400 ,      \    18    3ffff
h#    72000 ,      \    19    7ffff
h#    90000 ,      \    20    fffff
h#   140000 ,      \    21   1fffff
h#   300000 ,      \    22   3fffff
h#   420000 ,      \    23   7fffff
h#   e10000 ,      \    24   ffffff
h#  1200000 ,      \    25  1ffffff
h#  2000023 ,      \    26  3ffffff
h#  4000013 ,      \    27  7ffffff
h#  9000000 ,      \    28  fffffff
h# 14000000 ,      \    29 1fffffff
h# 20000029 ,      \    30 3fffffff
h# 48000000 ,      \    31 7fffffff
h# 80200003 ,      \    32 ffffffff

: round-up-log2  ( n -- log2 )
   dup log2              ( n log2 )
   tuck  1 swap lshift   ( log2 n 2^log2 )
   > -                   ( log2' )
;

defer .lfsr-mem-error
: (.lfsr-mem-error)  ( adr len data index remain -- adr len data index remain )
   push-hex
   ??cr
   ." Error at address "  4 pick  2 pick la+  dup 8 u.r  ( adr len data index remain err-adr )
   ."  - expected " 3 pick 8 u.r  ( adr len data index remain err-adr )
   ."  got " l@ 8 u.r cr
   pop-base
;
' (.lfsr-mem-error) to .lfsr-mem-error
: throw-lfsr-error  ( adr len data index remain -- <thrown> )
   (.lfsr-mem-error)  -1 throw
;

: (random-test)  ( adr len -- )
   dup /l <=  if  2drop exit  then ( adr len #bits )
   dup /l / round-up-log2          ( adr len #bits )
   polynomials swap la+ l@         ( adr len polynomial )

   3dup 1 1 rot random-fill        ( adr len polynomial )

   >r                              ( adr len  r: polynomial )
   1 1  2 pick /l / 1-             ( adr len data index remain  r: polynomial )
   begin                           ( adr len data index remain  r: polynomial )
      r@ random-check              ( false | adr len data index remain true  r: polynomial )
   while                           ( adr len data index remain  r: polynomial )
      .lfsr-mem-error              ( adr len data index remain  r: polynomial )
   repeat                          ( r: polynomial )
   r> drop
;

\ Not truly random - uses LFSR sequences
: random-test  ( adr len -- error? )
   "     Random address and data test" show-status

   ['] throw-lfsr-error to .lfsr-mem-error
   ['] (random-test) catch  if
      2drop true
   else
      false
   then
;

\ LICENSE_BEGIN
\ Copyright (c) 1997 FirmWorks
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
