\ This section introduces a new set of words:
\  $case  $of  $endof  $endcase
\ The semantics are very similar to the standard
\ Forth case statement.

\ Example of use:
\ : foo ( $ -- )
\   ( $ ) $case
\      " abc" $of  ." The string starts with abc" $endof
\      " xyz" $of  ." Oh, it's an xyz string"     $endof
\      ( $ ) ." **** It was " 2dup type
\   $endcase

\ The default clause is optional.
\ When an $of clause is executed, the remaining selector string (past
\ the matched string) remains on the string.  It is the user's
\ responsibility to dispose of the string.
\ When a default clause is executed, the entire selector string is
\ on the stack.  The default clause must drop the selector, e.g., 2drop.

\ At run time, ($of) tests the top of the stack against the selector.

\ If the first N characters of the string supplied to $case are
\ the same, the selector string is shortened and the following
\ forth code is executed.  If the first characters are not the
\ same, execution continues at the point just following the
\ the matching $endof

\needs substring? fload ${BP}/forth/lib/substrin.fth

\ Copying standard words here so they can be case insensitive:
: u$=  (s adr1 len1 adr2 len2 -- same? )
   rot tuck  <>  if  3drop false exit  then   ( adr1 adr2 len1 )
   caps-comp 0=
;

: usubstring?   ( adr1 len1  adr2 len2 -- flag )
   rot tuck     ( adr1 adr2 len1  len2 len1 )
   <  if  3drop false  else  tuck u$=  then
;

: ($of)  ( $selector $test -- [$selector] )
   2over $= if
      2drop
      r> /token + >r      \ Return to next word in $of clause
   else
      r>  dup branch@ +  >r  \ Skip to matching $endof
   then
;
: ($sub)  ( $selector $test -- $selector | $rest )
   4dup 2swap usubstring?  if   ( $selector $test )
      nip /string               ( $rest )
      r> /token + >r      \ Return to next word in $sub clause
   else                         ( $selector $test )
      2drop
      r>  dup branch@ +  >r  \ Skip to matching $endof
   then
;
: $sub     ( -- >m )  ['] ($sub)    +>mark                  ; immediate
: $endsub  ( >m -- )  ['] ($endof)  +>mark  but  ->resolve  ; immediate

: $case   ( -- 0 )   +level  0                             ; immediate
: $of     ( -- >m )  ['] ($of)     +>mark                  ; immediate
: $endof  ( >m -- )  ['] ($endof)  +>mark  but  ->resolve  ; immediate

: $endcase  ( 0 [ >m ... ] -- )
   compile ($endcase)
   begin  ?dup  while  ->resolve  repeat
   -level
; immediate

