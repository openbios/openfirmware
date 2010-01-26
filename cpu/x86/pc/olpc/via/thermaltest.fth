: cool-ms  ( ms -- )
   get-msecs +
   begin  stdin-idle  dup get-msecs -  0<  until
   drop
;      
: hot-ms  ( ms -- )
   get-msecs +
   begin  stdin-idle  dup get-msecs -  0<  until
   drop
;      
0 value cool-temperature
0 value warm-temperature
0 value hot-temperature
0 value final-temperature
: thermal-run  ( -- error? )
   ." Cooling down ... "
   d# 30,000 cool-ms
   cpu-temperature to cool-temperature
   ." Warming up ... "
   d# 1,000 hot-ms
   cpu-temperature to warm-temperature
   d# 30,000 hot-ms
   cpu-temperature to hot-temperature
   ." Final cooldown ... "
   d# 1,000 cool-ms

   cpu-temperature to final-temperature
   hot-temperature warm-temperature -  dup  d# 12 >  if
      ." Bad heat spreader - temperature rose " .d ." degrees" cr
      true exit
   then
   final-temperature warm-temperature -  dup  d# 4 >  if
      ." Bad heat spreader - cooldown spread was " .d ." degrees" cr
      true exit
   then
   false
;

\ cool down for 30 seconds  (good 54, bad 55)
\ hot for 1 second and measure temp - A  (good is 62, bad is 65)
\ hot for 30 seconds and measure temp - B (good 71, bad 85)
\ error if B - A > 12  (good machine is 9, bad is 20)
\ cool for 1 second and measure temp - C
\ error if C-A > 4  (good machine is 1, bad is 10)

