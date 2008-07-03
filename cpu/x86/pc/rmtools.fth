purpose: Convert between segment:offset and linear addresses

: >seg:off  ( linear -- offset segment )  lwsplit  d# 12 lshift  ;
: seg:off!  ( linear adr -- )  >r  >seg:off  r@ wa1+ w!  r> w!  ;
: seg:off>  ( offset segment -- linear )  4 lshift +  ;
: seg:off@  ( adr -- linear )  dup w@ swap wa1+ w@  seg:off>  ;
: >off  ( linear -- 16-bit offset )  >seg:off drop  ;
