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
\   $endcase ( $ )

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

: ($of)  ( arg$ sel$ -- arg$' )
   4dup 2swap substring?  if
      nip /string
      r> cell+ >r      \ Return to next word in $of clause
   else
      2drop
      r>  dup @ +  >r  \ Skip to matching $endof
   then
;

: $case   ( -- 0 )   +level  0                             ; immediate
: $of     ( -- >m )  ['] ($of)     +>mark                  ; immediate
: $endof  ( >m -- )  ['] ($endof)  +>mark  but  ->resolve  ; immediate

: $endcase  ( 0 [ >m ... ] -- )
   compile ($endcase)
   begin  ?dup  while  ->resolve  repeat
   -level
; immediate

