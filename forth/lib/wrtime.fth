purpose: Timing using wrapper calls

\ We may need to pass a static buffer to the wrapper to hold the
\ results of gettimeofday().
0 value timeval

: get-usecs  ( -- d.usec )
   timeval d# 348 syscall               ( timeval )
   ?dup 0=  if  retval  then  2@        ( usec sec )
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
