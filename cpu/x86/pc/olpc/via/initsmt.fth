\ Inject some tag values to get the manufacturing process started
: no-restart  ( -- )  no-kbc-reboot  kbc-on  d# 300 ms  ;
patch no-restart io-spi-reprogrammed io-spi-start

h# 202 msr@  swap h# ff invert and swap  h# 202 msr!  \ Uncache flash

add-tag TS SMT
add-tag MS cifs:\\bekins:bekind2@10.60.0.2\nb2_fvs
add-tag BD u:\boot\olpc.fth cifs:\\bekins:bekind2@10.60.0.2\nb2_fvs\olpc.fth
add-tag NT 10.60.0.2" evaluate

.( Wrote TS, MS, BD, and NT) cr
