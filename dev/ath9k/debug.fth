purpose: ATH9K driver test words
\ See license at end of file

headers
hex

: ll  ( idx -- )  dup f and 0=  if  cr 4 u.r ."   "  else  drop  then  ;
: dump-reg  ( reg len -- )  bounds do i ll i reg@ 8 u.r space 4  +loop  ;
: .regs  ( -- )
     0    100 dump-reg    \ General, DMA
     800   50 dump-reg    \ QCU
     900  100 dump-reg
     a00   50 dump-reg
    1000  130 dump-reg    \ DCU
    1270   10 dump-reg
    12f0   10 dump-reg
    4000   e0 dump-reg    \ Host Interface
    7000   60 dump-reg    \ RTC
    8000  400 dump-reg    \ PCU
    8800  800 dump-reg    \ Key
    9000  800 dump-reg
   \ Undocumented PHY
    9800  400 dump-reg    \ CHAN_BASE
    a800  400 dump-reg    \ CHAN1_BASE
    b800  400 dump-reg    \ CHAN2_BASE
    9c00   40 dump-reg    \ MRC_BASE
    9d00   20 dump-reg    \ BBB_BASE
    9e00  200 dump-reg    \ AGC_BASE
    ae00  200 dump-reg    \ AGC_BASE1
    be00  200 dump-reg    \ AGC_BASE2
    a200  600 dump-reg    \ SMB_BASE
    b200  600 dump-reg    \ SM_BASE1
    c200  600 dump-reg    \ SM_BASE2
;
: .uregs  ( -- )
   \ Unknown, non-zero, not badc0ffe, not deadbeef
    1430   10 dump-reg
    1470   10 dump-reg
    1f00  100 dump-reg
    8400  100 dump-reg
    d800  440 dump-reg
    dd00   20 dump-reg
    de00  200 dump-reg
    e000 2000 dump-reg
   10000   40 dump-reg
   11000 1e00 dump-reg
   15f00   40 dump-reg
   16000  c00 dump-reg
   17c00  400 dump-reg
;

d# 80 /n* buffer: tx-stat-buf   \ tx statistics buffer
      	  	 		\ It is indexed with #tx-retry.  Each word
				\ is # of time that said #tx-retry happened.
: init-debug  ( -- )  tx-stat-buf d# 80 /n* erase  ;
: sd  ( -- )
   true to force-open?
   a to defch
   " load-base" evaluate 80.0000 + to debug-base
   open .
   " TP-LINK" set-ssid   
   " "(f4 ec 38 a4 87 2f)" target-mac swap move
   init-debug
;

: tx-stat-buf@  ( i -- n )  tx-stat-buf swap na+ @  ;
: tx-stat-buf++  ( i -- )   tx-stat-buf swap na+ dup @ 1+ swap !  ;
: log-tx-stat  ( -- )  #tx-retry tx-stat-buf++  ;

0 value testi                   \ test iteration #
0 value #test                   \ # iteration of test
0 value #testf                  \ # of test failure
: testi++   ( -- )  testi  1+ to testi   ;
: #test++   ( -- )  #test  1+ to #test   ;
: #testf++  ( -- )  #testf 1+ to #testf  ;

0 value #tx-reset-save
: save-#tx-reset  ( -- )  #tx-reset to #tx-reset-save  ;

0 value #test-tx-retry          \ Success count
0 value #test-tx-retry-fail     \ Failure count
: ?#test-tx-retry++  ( -- )
   #tx-reset #tx-reset-save >  if  #test-tx-retry 1+ to #test-tx-retry  then  
;
: ?#test-tx-retry-fail++  ( -- )
   #tx-reset #tx-reset-save >  if  #test-tx-retry-fail 1+ to #test-tx-retry-fail  then  
;

0 value test-start-ms
0 value test-end-ms
: 2u.r  ( n -- )  <# u# u# u#> type  ;
: 3u.r  ( n -- )  <# u# u# u# u#> type  ;
: .time  ( ms -- )
   base @ >r decimal         ( ms )  ( R: base )
   d# 1000 /mod              ( ms' sec )  ( R: base )
   d# 60 /mod                ( ms sec' min )  ( R: base )
   d# 60 /mod                ( ms sec min' hr )  ( R: base )
   2u.r ascii : emit 2u.r ascii : emit 2u.r ascii . emit 3u.r
   r> base !                 ( )
;
: .stat  ( -- )
   ." elapse time = " test-end-ms test-start-ms - .time cr
   .rx-stat  .tx-stat 
   ." #test             = " #test .d cr
   ." #test failure     = " #testf .d cr 
   ." #tx-reset success = " #test-tx-retry .d cr
   ." #tx-reset failure = " #test-tx-retry-fail .d cr
   ." #tx-reset-max     = " #tx-reset-max .d cr
   ." tx-stat-buf dump:" cr
   tx-stat-buf tx-retry-cnt /n* " ldump" evaluate
;
: .graph  ( -- )
   \ Publish test parameters
   ." tx desc retry cnt        = " rseries @ .d cr
   ." tx-retry-delay-time (ms) = " tx-retry-delay-time .d cr
   \ Determine the largest count
   0 tx-retry-cnt 1+ 1  do  i tx-stat-buf@ max  loop
   \ Determine the scale for the graph, at least 1
   d# 100 /mod swap if 1+ then 1 max
   \ Graph it
   tx-retry-cnt 1+ 1  do
      i 2 u.r space space
      i tx-stat-buf@ over /mod swap if 1+ then
      ?dup  if  0  do  ascii * emit  loop  then
      cr
   loop drop
;

\ ********************************************************************************
\ TX, no ACK test
\
\ Reminder: set-ssid before testp

: proc-queued-resp  ( -- )
   begin  deque-rx  while
      process-rx
      free-rx
      got-response?  if  ascii R  else  ascii .  then  emit
   repeat
;

: my-probe-ssid  ( adr len -- found? )
   start-scan-response
   (probe-ssid)
;
: testp  ( -- )
   ." ---- probe-ssid ----" cr
   0 to testi
   get-msecs to test-start-ms
   begin
      debug? 0=  if  (cr testi .  then  testi++
      #test++  save-#tx-reset
      debug-base 40.0000 + 800 my-probe-ssid 0=  if
         debug? 0=  if  ."  failed" cr  then
         log-tx-stat
         ?#test-tx-retry-fail++
         #testf++
      else
         log-tx-stat
         ?#test-tx-retry++
      then
      400 ms key?
   until
   get-msecs to test-end-ms
;

\ ********************************************************************************
\ TX, ACK test

: testa  ( -- )
   ." ---- athenticate ----" cr
   0 to testi
   get-msecs to test-start-ms
   begin  
      debug? 0=  if  (cr testi .  then  testi++
      #test++  save-#tx-reset
      target-mac$ authenticate 0=  if 
         log-tx-stat
         ?#test-tx-retry-fail++
         #testf++
      else
         log-tx-stat
         ?#test-tx-retry++
      then
      400 ms key? 
   until  
   get-msecs to test-end-ms
;

\ ********************************************************************************
\ Associate test

d# 2,000 constant read-timeout-limit
0 value read-ms
: read-loop  ( -- )
   get-msecs read-timeout-limit + to read-ms
   begin
      debug-base 10.0000 + 800 read-force drop
   get-msecs read-ms >= until
;
: testd  ( -- )
   " reset-rcnt" $call-supplicant
   do-associate 0=  if  ." Fail to associate" cr exit  then
   ['] 2drop to ?process-eapol
   read-loop
   target-mac$ deauthenticate
;

\ LICENSE_BEGIN
\ Copyright (c) 2011 FirmWorks
\ 
\ Permission is hereby granted, free of charge, to any person obtaining

\ a copy of this software and associated documentation files (the
\ "Software"), to deal in the Software without restriction, including
\ without limitation the rights to use, copy, modify, merge, publish,
\ distribute, sublicense, and/or sell copies of the Software, and to
\ permit persons to whom the Software is furnished to do so, subject to
\ the following conditions:
\ 
\ The above copyright notice and this permission notice shall be
\ included in all copies or substantial portions of the Software.
\ 
\ THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
\ EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
\ MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
\ NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
\ LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
\ OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
\ WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
\
\ LICENSE_END
