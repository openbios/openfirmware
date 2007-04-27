\ See license at end of file

hex

alias (s (

: >user#  ( acf -- user# )   >body @user#  ;
: 'user#  \ name  ( -- user# )
   '  ( acf-of-user-variable )   >user#
;
headers
: tr  ( token-bits -- adr )      \ Token relocate
\t16   tshift <<
   origin+
;
: x  ( adr -- )  execute  ;             \ Convenience word
: .cstr  ( adr -- )             \ Display C string
   begin  dup c@ dup  while
      dup newline =  if  drop cr  else  emit  then
      1+
   repeat
   2drop
;

: .h  ( n -- )   push-hex     .  pop-base  ;
: .x  ( u -- )   push-hex    u.  pop-base  ;
: .d  ( n -- )   push-decimal .  pop-base  ;

headerless
defer lo-segment-base	' origin  is  lo-segment-base
defer lo-segment-limit	' origin  is  lo-segment-limit
defer hi-segment-base	' origin  is  hi-segment-base
defer hi-segment-limit	' here    is  hi-segment-limit

: dictionary-size  ( -- n )  here origin-  ;

headerless

: #!  ( -- )  [compile] \  ; immediate  \ For use with script files
alias >is >data		\ Backwards compatibility

: strip-blanks ( adr,len -- adr',len' )  -leading -trailing  ;
: optional-arg$  ( -- adr len )  0 parse  strip-blanks  ;

headers

alias not invert
alias eval evaluate

: c?  ( adr -- )  c@  u.  ;
: w?  ( adr -- )  w@  u.  ;
: l?  ( adr -- )  l@  u.  ;
64\ : x?  ( adr -- )  x@  u.  ;
: d?  ( adr -- )  d@ swap u. u.  ;

\ : behavior  ( xt1 -- xt2 )  >body >user token@  ;

: showstack    ( -- )  ['] (.s  is status  ;
: noshowstack  ( -- )  ['] noop is status  ;

: (confirmed?)  ( adr len -- char )
   type  ."  [y/n]? "  key dup emit cr  upc
;
\ Default value is yes
: confirmed?  ( adr len -- yes? )  (confirmed?) [char] N  <>  ;
\ Default value is no
: confirmedn?  ( adr len -- yes? )  (confirmed?) [char] Y  =  ;

/n 8 * constant bits/cell
: lowmask  ( #bits -- mask )  1 swap lshift 1-  ;
: lowbits  ( n #bits -- bits )  lowmask and  ;
: bits  ( n bit# #bits -- bits )  -rot rshift  swap lowbits  ;
: bit  ( n bit# -- )  1 bits  ;

: log2  ( n -- log2-of-n )
   0  begin        ( n log )
      swap  2/     ( log n' )
   ?dup  while     ( log n' )
      swap 1+      ( n' log' )
   repeat          ( log )
;

: many   ( -- )   key? 0=  if  0 >in !  then  ;

\ Display the bits in the number "x" according to the format string adr,len
\ The characters in the format string correspond to the bits in "x".
\ The last character in the string corresponds to the least-significant
\ bit in "x" (i.e. the bit whose binary weight is "1", the second-from-
\ last character corresponds to the "x" bit whose binary weight is "2",
\ and so on.  If there are fewer characters in the string than the number
\ of bits in a cell, the excess high-order bits in "x" are ignored.
\
\ The characters in the string are processed from left to right (i.e.
\ starting at the beginning of the string).  Each character in the string
\ is interpreted as follows:

\ If the character is "~":
\	The corresponding bit in "x" is ignored and nothing is displayed
\
\ If the character is alphabetic:
\	If the corresponding bit in "x" is clear (i.e. 0), the character is
\	displayed as-is.  If the bit is set (i.e. 1), the character is
\	displayed with its case inverted (upper-case changed to lower case,
\	and vice versa).
\
\ Otherwise:
\	The character is displayed as-is.

: show-bits  ( x adr len -- )
   1-  0  swap  do             ( mask adr )
      2dup c@                  ( mask adr mask char )
      dup [char] ~  =  if      ( mask adr mask char )
         2drop                 ( mask adr )
      else                     ( mask adr mask char )
         swap  1 i lshift and  ( mask adr char bit-set? )
         if  dup [char] a <  if  lcc  else  upc  then  then
	 emit   ( mask adr )
      then                     ( mask adr )
      1+                       ( mask adr' )
   -1 +loop                    ( mask adr )
   2drop
;
: .buffers ( -- )
   buffer-link                    ( next-buffer-word )
   begin  another-link?  while    ( acf )
      dup .name                   ( acf )
      dup >body dup >user @       ( acf apf addr )
      .x  /user# + @ .x  cr       ( acf )
      exit?  if  drop exit  then  ( acf )
      >buffer-link                ( prev-buffer:-acf )
   repeat                         (  )
;
defer showaddr  ( adr -- )	\ For disassemblers
' u. is showaddr
\ : ux.  ( adr -- )  base @ >r  hex  (u.) type  r> base !  ;
\ ' ux. is showaddr

\ Integer division which rounds to nearest instead of truncating
: rounded-/  ( dividend divisor -- rounded-result )
   swap 2*  swap /  ( result*2 )
   dup 1 and +      \ add 1 to the result if it is odd
   2/               ( rounded-result )
;

\ LICENSE_BEGIN
\ Copyright (c) 2006 FirmWorks
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
