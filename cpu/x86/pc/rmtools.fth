purpose: Convert between segment:offset and linear addresses

: >seg:off  ( linear -- offset segment )  dup h# f and  swap  4 rshift  ;
: seg:off!  ( linear adr -- )  >r  >seg:off  r@ wa1+ w!  r> w!  ;
: seg:off>  ( offset segment -- linear )  4 lshift +  ;
: seg:off@  ( adr -- linear )  dup w@ swap wa1+ w@  seg:off>  ;
