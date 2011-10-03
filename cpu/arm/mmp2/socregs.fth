\ See license at end of file
purpose: Register access words for MMP2 registers used by many functional units

: +io  ( offset -- va )  io-va +  ;
: io!  ( value offset -- )  +io l!  ;
: io@  ( offset -- value )  +io l@  ;

: +apbc  ( offset -- io-offset )  h# 01.5000 +  ;  \ APB Clock Unit
: +pmua  ( offset -- io-offset )  h# 28.2800 +  ;  \ CPU Power Management Unit
: +mpmu  ( offset -- io-offset )  h# 05.0000 +  ;  \ Main Power Management Unit
: +scu   ( offset -- io-offset )  h# 28.2c00 +  ;  \ System Control Unit
: +icu   ( offset -- io-offset )  h# 28.2000 +  ;  \ Interrupt Controller Unit

: io-set  ( mask offset -- )  dup io@  rot or  swap io!  ;
: io-clr  ( mask offset -- )  dup io@  rot invert and  swap io!  ;

: icu@  ( offset -- value )  +icu io@  ;
: icu!  ( value offset -- )  +icu io!  ;

: mpmu@  ( offset -- l )  +mpmu io@  ;
: mpmu!  ( l offset -- )  +mpmu io!  ;

: pmua@  ( offset -- l )  +pmua io@  ;
: pmua!  ( l offset -- )  +pmua io!  ;

: apbc@  ( offset -- l )  +apbc io@  ;
: apbc!  ( l offset -- )  +apbc io!  ;
