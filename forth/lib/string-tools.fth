\ string tools
\ make it easy to include numbers in strings
\ avoid $cat2 $cat3 which leak memory

\ These words work with a pre-allocated string buffer.
\ Each buffer begins with its current count and ends with a null byte.
\ Unless we need larger strings, those will be 1 byte each.
\ The buddy allocator gives us 2^n bytes, so we will limit string size to 256-2=254 bytes.

d# 254 constant maxstring
\ buf: len data
: string:   ( -- )   create 256 allot  ;
string: string1

\ name$ means an address/length pair on the stack
\ $name is a word that takes a string and maybe more arguments
: $room    ( buffer -- room )      maxstring swap c@ -  ;
: string$  ( buffer -- string$ )   count  ;
: $add     ( string$ buffer -- )
   >r
   r@ $room over < abort" string will not fit "   ( string$ )
   r> $cat
;
: $addch    ( ch buffer -- )  >r r@ c@ r@ + 1+ c!  1 r@ c@ + r> c! ;
: $empty    ( buffer -- )  0 swap c!  ;
: $place    ( string$ buffer -- )   dup  $empty  $add  ;
: $prepend  ( string$ buffer -- )  \ $len == string$ length,  blen == buffer length
   >r dup r@ 1+ r@ 1+ rot + r@ c@  ( $ buf+1 buf+1+$len blen ) cmove>
   r@ 1+ swap   ( ready to do a cmove )
   ( $len )  dup r@ c@ + r> c!
   ( adr buf+1 $len )  cmove
;
: $add_     ( buffer -- )     "  " rot $add  ;
: $add#_    ( n buffer -- )   >r (.) r@ $add  r> $add_ ;
: $addd#_   ( n buffer -- )   >r  push-decimal (.) pop-base  r@ $add  r> $add_ ;
: $addh#_   ( n buffer -- )   >r  push-hex  (u.) pop-base  r@ $add  r> $add_ ;
: $add8h#   ( n buffer -- )   >r  push-hex  (.8) pop-base  r> $add  ;
: $add0x#_  ( n buffer -- )   >r " 0x" r@ $add r> $addh#_  ;

