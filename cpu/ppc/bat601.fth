purpose: Block Address Translation register access for PowerPC 601
\ See license at end of file

hex

\ PPC 601 has a unified cache and a single set of BAT registers, accessed
\ with the SPR numbers used for IBATs

\ The layout of the 601 BAT bits is different from the standard PPC layout

: bat!-601  ( pa va len io? bat# which -- )
   drop >r >r >r                             ( pa va )     ( R: bat# io? len )

   swap mask-bat-adr      \ phys block #     ( va PBN )
   r>  1-  h# 11 >>  or   \ block length     ( va PBN|BL)  ( R: bat# io? )
   h# 40 or               \ valid bit        ( va bat-lo )

   swap mask-bat-adr      \ log. page index  ( bat-lo BLPI )
   \ no cache for I/O, coherent and no protection in both cases
   r>  if  h# 32  else  h# 12  then  or      ( bat-lo bat-hi ) ( R: bat# )

   r>  ibat!
;

: bat@-601  ( bat# which -- false | pa va len flags true )
   drop ibat@                                      ( bat-lo bat-hi )
   over h# 40 and  0=  if  2drop false exit  then  ( bat-lo bat-hi )
   over mask-bat-adr                               ( bat-lo bat-hi pa )
   over mask-bat-adr                               ( bat-lo bat-hi pa va )
   2swap  swap  h# 3f and 1+  h# 11 <<             ( pa va bat-hi len )
   swap h# 7f and true                             ( pa va len flags t )
;

\ On some processors, the BAT registers can become corrupted if
\ two of them happen to map overlapping ranges, even if address
\ translation is turned off, and that said corruption can be prevented
\ by invalidating all the BAT registers before programming any of them.

: clear-bats-601  ( -- )
   4 0  do  0 0 i ibat!  loop  
;

: .bats-601  ( -- )
   base @ >r hex
   ." #   Virtual  Physical  Length  WIMsuPP" cr
   4 0  do
      i .
      i ibat bat@-601  if   ( pa va len flags )
         rot 9 u.r  rot d# 10 u.r  swap 8 u.r   ( flags )
         binary 2 spaces  <# u# u# u# u# u# u# u# u#> type  hex
      else
         ."  --invalid--"
      then
      cr
   loop
   r> base !
;

warning @ warning off
\ Overlay standard PowerPC versions with switchable versions
: bat@  ( pa va len io? bat# which -- )
   601?  if  bat@-601  exit  then
   bat@
;
: bat!  ( pa va len io? bat# which -- )
   601?  if  bat!-601  exit  then
   bat!
;
: clear-bats  ( -- )
   601?  if  clear-bats-601 exit  then
   clear-bats
;
: .bats  ( -- )
   601?  if  .bats-601 exit  then  .bats
;
warning !

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
