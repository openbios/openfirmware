purpose: Operator confirmation of selftest results

: confirm-selftest?  ( -- error? )
   diagnostic-mode?  if
      ." Did the test pass (n or ESC for FAIL) ? "
      key dup emit cr  upc  dup [char] N  =  swap h# 1b =  or
   else
      false
   then
;

: has-direct-child?  ( name@unit$ -- found? )
   also  current @ >r           ( name@unit$  r: current )
   [char] @  left-parse-string  ( unit$ name$ r: current )
   ['] (find-node) catch        ( unit$ name$ found? r: current )
   >r 4drop r> 0<>              ( found? r: current )
   r> set-current  previous     ( found? )
;
