d# 500 value tone-freq

: /cycle  ( -- #bytes )  #cycle /l*  ;

: make-cycle  ( adr -- adr' )
   #cycle/4 1+  0  do                  ( adr )
      i calc-sin                       ( adr isin )
      2dup  swap  i la+ w!             ( adr isin )
      2dup  swap  #cycle/2 i - la+ w!  ( adr isin )
      negate                           ( adr -isin )
      2dup  swap  #cycle/2 i + la+ w!  ( adr -isin )
      over  #cycle i - la+ w!          ( adr )
   loop                                ( adr )
   /cycle +
;

\ This version puts the tone first into the left channel for
\ half the time, then into the right channel for the remainder
: make-tone  ( adr len freq sample-rate -- )
   set-freq        ( adr len )

   \ Start with everything quiet
   2dup erase                         ( adr len )

   over  make-cycle  drop             ( adr len )

   \ Copy the wave template into the left channel
   over /cycle +   over 2/  /cycle -  bounds  ?do  ( adr len )
      over  i  /cycle  move                        ( adr len )
   /cycle +loop                                    ( adr len )

   \ Copy the wave template into the right channel
   2dup 2/ + wa1+  over 2/ /cycle -   bounds  ?do  ( adr len )
      over  i  /cycle  move                        ( adr len )
   /cycle +loop                                    ( adr len )
   2drop                                           ( )
;

\ This version puts the tone into both channels simultaneously
: make-tone2  ( adr len freq sample-rate -- )
   set-freq           ( adr len )

   over  make-cycle  drop      ( adr len )

   \ Duplicate left into right in the template
   over  #cycle /l*  bounds  ?do   ( adr len )
      i w@  i wa1+ w!              ( adr len )
   /l +loop                        ( adr len )

   \ Replicate the template
   over /cycle +   over /cycle -  bounds  ?do  ( adr len )
      over  i  /cycle  move                    ( adr len )
   /cycle +loop                                ( adr len )
   2drop                                       ( )
;
