h# 2000.0000 constant sdram-size

: (memory?)  ( phys -- flag )  sdram-size u<  ;
' (memory?) to memory?
