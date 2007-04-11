purpose: Put message codes out on port 80

h# 40 value the-debug-code
: next-debug-code  ( -- n )  the-debug-code  dup 1+ to the-debug-code  ;

: port80  ( b -- )  h# 80 pc!  ;     \ Debug port callout

: show-debug-code  ( adr len code# -- )
   ." Port80: " push-hex <# u# u# u#> type pop-base  space type  cr
;
: put-port80  ( msg$ -- )
   next-debug-code dup >r show-debug-code  r> ( adr len b )
   postpone literal  postpone port80      ( adr len )
;

\ Automatically insert port80 codes in named stand-init: words
: msg-port80  ( msg$ -- msg$ )  2dup put-port80  ;
' msg-port80 to check-message
