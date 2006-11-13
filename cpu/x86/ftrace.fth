\ Display a Forth stack backtrace
only forth also hidden also  forth definitions
: ftrace  ( -- )   \ Forth stack
   rrp  begin  dup in-return-stack?  0=  while  >saved l@  repeat  ( rp )
   rrp in-return-stack?  if  rip >saved .traceline  then
   >saved  rssave-end swap  (rstrace   
;
only forth also definitions
