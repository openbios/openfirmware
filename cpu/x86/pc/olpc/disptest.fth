dev /display

d# 100 constant bar-int
h# 7 constant test-colors16-mask
create test-colors16
\  white  magenta   yellow  red     green    blue    cyan    black
   ffff w, f81f w,  ffe0 w, f800 w, 07e0 w,  001f w, 07ff w, 0000 w,

: test-color16  ( n -- color )
   test-colors16 swap bar-int / test-colors16-mask and wa+ w@
;
: .horizontal-bars16  ( -- )
   dimensions				( width height )
   0  ?do				( width )
      i test-color16 0 i 3 pick bar-int " fill-rectangle" $call-screen
   bar-int +loop  drop
;
: .vertical-bars16  ( -- )
   dimensions				( width height )
   swap 0  ?do				( height )
      i test-color16 i 0 bar-int 4 pick " fill-rectangle" $call-screen
   bar-int +loop  drop
;
: selftest  ( -- error? )
   bytes/pixel 2 <>  if  false exit  then
   .horizontal-bars16
   d# 2000 ms
   .vertical-bars16
   d# 2000 ms
   false
;

device-end

