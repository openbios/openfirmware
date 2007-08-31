purpose: Timing using wrapper calls

: get-usecs  ( -- d.usec )
   d# 348 syscall retval 2@  ( usec sec )
   d# 1,000,000 um*  rot 0  d+
;

\ We really should call usleep, but that wrapper doesn't have that
: (us)  ( d.microseconds -- )
   get-usecs d+                         ( d.target-time )
   begin  2dup get-usecs d- d0<  until  ( d.target-time )
   2drop
;
: us  ( microseconds -- )  0 (us)  ;
: ms  ( milliseconds -- )  d# 1000 um* (us)  ;
