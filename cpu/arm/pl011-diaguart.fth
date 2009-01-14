
: inituarts  ( -- )  ;

: ukey?  ( -- flag )  uart-base h# 18 + l@  h# 10 and  0=  ;
: ukey  ( -- char )
   begin  ukey?  until
   uart-base l@  h# ff and
;
: uemit  ( char -- )
   begin  uart-base h# 18 + l@  h# 20 and  0=  until
   uart-base l!
;
