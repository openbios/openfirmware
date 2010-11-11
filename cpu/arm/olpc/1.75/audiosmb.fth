: smb-dly  4 us  ;

: smb-data-hi  ( -- )  d# 163 gpio-set  smb-dly  ;
: smb-data-lo  ( -- )  d# 163 gpio-clr  smb-dly  ;
: smb-clk-hi  ( -- )  d# 162 gpio-set  smb-dly  ;
: smb-clk-lo  ( -- )  d# 162 gpio-clr  smb-dly  ;
: smb-data@  ( -- flag )  d# 163 gpio-pin@  ;
: smb-clk@  ( -- flag )  d# 162 gpio-pin@  ;
: smb-off  ( -- )  d# 163 gpio-dir-in  ;
: smb-on  ( -- )  d# 163 gpio-dir-out  ;
: smb-data-dir-out  ( -- )  d# 163 gpio-dir-out  ;
: smb-data-dir-in  ( -- )  d# 163 gpio-dir-in  ;

h# 3500 constant smb-clk-timeout-us
\ Slave can flow control by holding CLK low temporarily
: smb-wait-clk-hi  ( -- )
   smb-clk-timeout-us 0  do
      smb-clk@  if  smb-dly  unloop exit  then  1 us
   loop
   true abort" I2C clock stuck low"
;
: smb-data-hi-w  ( -- )  smb-data-hi  smb-wait-clk-hi  ;

h# 3500 constant smb-data-timeout-us
: smb-wait-data-hi  ( -- )
   smb-data-timeout-us 0  do
      smb-data@  if  unloop exit  then  1 us
   loop
   true abort" I2C data stuck low"
;

: smb-restart  ( -- )
   smb-clk-hi  smb-data-lo  smb-clk-lo
;

: smb-start ( -- )  smb-clk-hi  smb-data-hi  smb-data-lo smb-clk-lo  ;
: smb-stop  ( -- )  smb-clk-lo  smb-data-lo  smb-clk-hi  smb-data-hi  ;

: smb-get-ack  ( -- )
   smb-data-dir-in
   smb-data-hi
   smb-clk-hi smb-wait-clk-hi  
   smb-data@  \ drop		\ SCCB generates an don't care bit
   if  smb-stop  true abort" I2c NAK" then
   smb-clk-lo
\   smb-wait-data-hi
   smb-data-dir-out
;
: smb-bit  ( flag -- )
   if  smb-data-hi  else  smb-data-lo  then
   smb-clk-hi smb-wait-clk-hi  smb-clk-lo
;

: smb-byte  ( b -- )
   8 0  do                     ( b )
      dup h# 80 and  smb-bit   ( b )
      2*                       ( b' )
   loop                        ( b )
   drop                        ( )
   smb-get-ack
;
: smb-byte-in  ( ack=0/nak=1 -- b )
   smb-data-dir-in
   0
   8 0  do             ( n )
      smb-clk-hi       ( n )
      2*  smb-data@  if  1 or  then  ( n' )
      smb-clk-lo
   loop
   smb-data-dir-out
   swap smb-bit  smb-data-hi  \ Send ACK or NAK
;

0 value smb-slave
: smb-addr  ( lowbit -- )  smb-slave or  smb-byte  ;

: smb-byte!  ( byte reg# -- )
   smb-start
   0 smb-addr          ( byte reg# )
   smb-byte            ( byte )
   smb-byte            ( )
   smb-stop
;

: smb-byte@  ( reg# -- byte )
   smb-start
   0 smb-addr          ( reg# )
   smb-byte            ( )
   smb-stop smb-start	\ SCCB bus needs a stop and a start for the second phase
   1 smb-addr
   1 smb-byte-in       ( byte )
   smb-stop
;

: smb-word!  ( word reg# -- )
   smb-start
   0 smb-addr          ( word reg# )
   smb-byte            ( word )
   wbsplit swap smb-byte smb-byte  ( )
   smb-stop
;

: smb-word@  ( reg# -- word )
   smb-start
   0 smb-addr          ( reg# )
   smb-byte            ( )
   smb-restart
   1 smb-addr          ( )
   0 smb-byte-in   1 smb-byte-in  bwjoin  ( word )
   smb-stop
;

\ This can useful for clearing out DCON SMB internal state
: smb-pulses  ( -- )
   d# 32 0  do  smb-clk-lo smb-clk-hi  loop
;

: set-dcon-slave  ( -- )  h# 1a to smb-slave  ;
: smb-init    ( -- )  set-dcon-slave  smb-on  smb-pulses  ;

: dcon@  ( reg# -- word )  set-dcon-slave  smb-word@  ;
: dcon!  ( word reg# -- )  set-dcon-slave  smb-word!  ;
