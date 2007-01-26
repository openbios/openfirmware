\ Audio diags

select /audio

d# 4800 4 * 2 * value sample-len

h# 80000 value record-len

defer measure
: peak  ( adr len -- log-peak )
   stats   ( min max avg )
   tuck -  -rot -               ( max-avg min-avg )
   negate max                   ( peak )
   log2
;
: energy  ( adr len -- log-energy )
   0 -rot  bounds  ?do    ( sum )
      i <w@  dup *  +     ( sum' )
   4 +loop                ( sum )
   h# 7fff.ffff umin      ( sum' )
   log2  d# 8 -
;
' energy is measure

: vu1
   load-base sample-len audio-in drop
   load-base sample-len measure   ( log-value )
   dup  0  ?do  ." ="  loop       ( log-value )
   ." |"   d# 28 swap -  0 max spaces  (cr   ( )
;

0 value mic-boost?
h# 808 value rlevel
: set-rlevel  ( db -- )
   dup d# 20 >=  if  d# 20 -  true  else  false then  ( db' boost? )
   to mic-boost?                                       ( db )
   h# 22 min  1+ 2* 3 /  dup bwjoin  to rlevel
;

: establish-level  ( -- )
   mic-boost?   if  mic+20db  else  mic+0db  then
   rlevel set-record-gain
   d# 250 ms    \ Settling time for DC offset filter
;

: vu
   cr
   open-in  establish-level
   begin  vu1  key? until
   key drop cr
;

: record  ( -- )
   open-in  establish-level
   load-base  record-len  audio-in drop
;

h# 0 value plevel
: set-plevel  ( db -- )
   dup 0>  abort" Playback only does attenuation - use a negative number"
   negate  1+ 2* 3 /  dup bwjoin  to plevel
;

: play  ( -- )
   open-out  plevel set-pcm-gain  0 h# 38 codec!
   load-base  record-len  audio-out drop  write-done
;

: s  ( -- )
   load-base record-len stats
   rot  ." Min: " .d  swap ." Max: " .d  ." Avg: " .d  cr
;

: swdump  ( adr len -- )
   push-decimal
   bounds  ?do
      i d# 40  bounds  do  i <w@ 7 .r  4 +loop  cr
      exit? ?leave
   d# 40 +loop
   pop-base
;
: left-dump   ( -- )  load-base  record-len  swdump  ;
: right-dump  ( -- )  load-base  wa1+ record-len  swdump  ;
