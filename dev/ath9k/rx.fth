purpose: ATH9K RX code
\ See license at end of file

headers
hex

false instance value use-promiscuous?

\ rx data structures:
\   - an array of rx-buf
\   - a link list of free rx-buf starting at frx-head,
\     add and remove from frx-head
\   - a link list of completed high priority rx-buf,
\     read from hrx-head (oldest packet), add to hrx-end (newest packet)
\   - a link list of completed low priority rx-buf,
\     read from lrx-head, add to lrx-end
\   - lrx-cur points to the current rx-buf in reg 78
\   - hrx-cur points to the current rx-buf in reg 74

d# 512 constant #rx-bufs

struct
   /n field >rx-next
   /n field >rx-buf
   /n field >rx-buf-phy
constant /rx-list
/rx-list #rx-bufs * buffer: rx-list
: 'rx-list  ( idx -- adr )
   dup #rx-bufs >=  if  drop 0  else  /rx-list * rx-list +  then
;

struct
   4 field >rxs-info
   4 field >rxs-stat1
   4 field >rxs-stat2
   4 field >rxs-stat3
   4 field >rxs-stat4
   4 field >rxs-stat5
   4 field >rxs-stat6
   4 field >rxs-stat7
   4 field >rxs-stat8
   4 field >rxs-stat9
   4 field >rxs-stat10
   4 field >rxs-stat11
   0 field >rxs-data            \ Start of received data
constant /rx-stat

rx-bufsize 400 round-up constant /rx-buf
#rx-bufs /rx-buf * constant /rx-bufs
/rx-stat buffer: rx-stat-save

: (rx-rssi)  ( -- rssi )  rx-stat-save >rxs-stat5 le-l@ d# 24 >>  ;
' (rx-rssi) to rx-rssi
\ After rx buffer is filled, queue it for later read operations.
\ However, we should take care of antenna issue now, theoretically.
\ But empirically a bad idea.
: ?change-ant  ( node -- )
   >rx-buf @ >rxs-stat4 le-l@ 8 >> dup rx-defant <>  if
      rs-otherant-cnt 1+ dup 3 >  if  drop set-defant 0  else  nip  then
   else
      drop 0
   then  to rs-otherant-cnt
;

0 value rx-bufs
0 value rx-bufs-phy
0 value frx-head
0 value hrx-head   0 value hrx-end
0 value lrx-head   0 value lrx-end
0 value lrx-cur    0 value hrx-cur

\ Statistics:  #hrx + #lrx + #frx should equal #rx-buf
0 value #hrx  0 value #lrx  0 value #frx
0 value rxs-stat11       \ OR all the >rxs-stat11 values
: rxs-stat11!  ( n -- )  rxs-stat11 or to rxs-stat11  ;
: #hrx++  ( -- )  #hrx 1+ to #hrx  ;
: #hrx--  ( -- )  #hrx 1- to #hrx  ;
: #lrx++  ( -- )  #lrx 1+ to #lrx  ;
: #lrx--  ( -- )  #lrx 1- to #lrx  ;
: #frx++  ( -- )  #frx 1+ to #frx  ;
: #frx--  ( -- )  #frx 1- to #frx  ;

\ Statistics for lrx:
\ #rx  = total rx received  (#rx = #rxq + #rxe)
\ #rxq = total rx deemed ok to queue
\ #rxe = total rx deemed not ok to queue
\ #rxd = total rx dequeued  (#rxd <= #rxq)
\ #rxf = total rx freed (#rxd+#rxe <= #rxf <= #rx)
0 value #rx   0 value #rxq  0 value #rxe  0 value #rxd  0 value #rxf
: #rx++   ( -- )  #rx  1+ to #rx   ;
: #rxq++  ( -- )  #rxq 1+ to #rxq  ;
: #rxe++  ( -- )  #rxe 1+ to #rxe  ;
: #rxd++  ( -- )  #rxd 1+ to #rxd  ;
: #rxf++  ( -- )  #rxf 1+ to #rxf  ;
: init-rx-stat  ( -- )  0 to #rx   0 to #rxq  0 to #rxe  0 to #rxd  0 to #rxf  ;
: .rx-stat  ( -- )
   ." #rx = " #rx .d
   ." #rxq = " #rxq .d
   ." #rxe = " #rxe .d
   ." #rxd = " #rxd .d
   ." #rxf = " #rxf .d cr
;

: 'rx-buf      ( idx -- adr )  /rx-buf * rx-bufs +  ;
: 'rx-buf-phy  ( idx -- adr )  /rx-buf * rx-bufs-phy +  ;

: free-rx-bufs  ( -- )
   rx-bufs 0=  if  exit  then
   rx-bufs rx-bufs-phy /rx-bufs dma-map-out
   rx-bufs /rx-bufs dma-free
   0 to rx-bufs
;
: alloc-rx-bufs  ( -- )
   rx-bufs  if  exit  then
   /rx-bufs dma-alloc to rx-bufs
   rx-bufs  /rx-bufs  false dma-map-in to rx-bufs-phy
;
: init-rx-lists  ( -- )
   rx-list to frx-head
   #rx-bufs 0  do
      i 'rx-list                        ( 'list[i] )
      i 1+ 'rx-list over >rx-next !     ( 'list[i] )
      i 'rx-buf     over >rx-buf  !     ( 'list[i] )
      i 'rx-buf-phy swap >rx-buf-phy !  ( )
   loop
   0 to lrx-head  0 to lrx-end
   0 to hrx-head  0 to hrx-end
   0 to lrx-cur   0 to hrx-cur
\   0 to #hrx  0 to #lrx  #rx-bufs to #frx
;
: init-rx-bufs  ( -- )
   alloc-rx-bufs
   init-rx-lists
;

\ After rx buffer is read, put it back into the free rx-list
: free-rx  ( rx-list -- )  #rxf++  frx-head over >rx-next !  to frx-head  #frx++  ;

\ Use to get the next free rx buffer in the rx-list
: next-frx  ( -- rx-list )
   frx-head 0=  if  debug-me abort" Run out of free rx buffers"  then
   frx-head dup >rx-next @ to frx-head
   0 over >rx-next !
   #frx--
;
: node>pbuf  ( rx-list -- padr )
   dup 0=  if  debug-me abort" rx-list address is 0"  then
   dup >rx-buf-phy @
   swap >rx-buf @  /rx-stat erase   \ Clear rx status
;
: next-hrx  ( -- rx-list )  next-frx dup to hrx-cur  ;
: next-lrx  ( -- rx-list )  next-frx dup to lrx-cur  ;

: (queue-hrx)  ( -- )
   #hrx++
   ascii ` vemit
   hrx-end 0=  if
      hrx-cur dup  to hrx-end  to hrx-head
   else
      hrx-cur dup  hrx-end >rx-next !  to hrx-end
   then
;
: (queue-lrx)  ( -- )
   #lrx++
   ascii . vemit
   lrx-end 0=  if
      lrx-cur dup  to lrx-end  to lrx-head
   else
      lrx-cur dup  lrx-end >rx-next !  to lrx-end
   then
;
: (restart-hrx)  ( rx-list -- )  node>pbuf 74 reg!  ;
: (restart-lrx)  ( rx-list -- )  node>pbuf 78 reg!  ;
: restart-hrx  ( -- )  next-hrx  (restart-hrx)  ;
: restart-lrx  ( -- )  next-lrx  (restart-lrx)  ;
: done-rx?  ( adr -- done? )  wa1+ le-w@ ATHEROS_ID =  ;
: ok-rx?  ( adr -- ok? )  >rxs-stat11 c@ dup rxs-stat11! 3 and 3 =  ;
: queue-hrx  ( -- )
   hrx-cur 0=  if  exit  then
   hrx-cur >rx-buf @ 
   dup done-rx?  if
      ok-rx?  if
         (queue-hrx)  restart-hrx
      else
         ascii ? vemit
         hrx-cur (restart-hrx)
      then
   else  drop  then
;
: queue-lrx  ( -- )
   lrx-cur 0=  if  exit  then
   lrx-cur >rx-buf @
   dup done-rx?  if
      #rx++
      ok-rx?  if
         (queue-lrx)  restart-lrx
         #rxq++ 
      else
         #rxe++ ascii ? vemit
         lrx-cur (restart-lrx)
      then
   else  drop  then
;
: queue-rx   ( -- )  queue-hrx  queue-lrx  ;

\ Retrieve rx buffer for read operations
\ The descriptor is not freed here.  When the caller is done with the buffer
\ it needs to call free-rx to return the descriptor/buffer pair to the free list.

: (deque-hrx)  ( -- node adr len )
   #hrx--
   hrx-head dup >rx-buf @                      ( node buf )
   dup rx-stat-save /rx-stat move              \ Save the rx status descriptor
   dup >rxs-data                               ( node buf adr )
   swap >rxs-stat2 le-l@ fff and               ( node adr len )
   4 -
   hrx-head >rx-next @  dup to hrx-head
   0=  if  0 to hrx-end  then
;
: (deque-lrx)  ( -- node adr len )
   #lrx--  #rxd++
   lrx-head dup >rx-buf @                      ( node buf )
   dup rx-stat-save /rx-stat move              \ Save the rx status descriptor
   dup >rxs-data                               ( node buf adr )
   swap >rxs-stat2 le-l@ fff and               ( node adr len )
   4 -
   lrx-head >rx-next @  dup to lrx-head
   0=  if  0 to lrx-end  then
;
: deque-rx  ( -- false | node adr len true )
   hrx-head  if  (deque-hrx) true  else  false  then
   ?dup 0=  if
      lrx-head  if  (deque-lrx) true  else  false  then
   then
;
: flush-rxq  ( -- )
   begin  queue-rx deque-rx  while  2drop free-rx  repeat  
   0 to rs-otherant-cnt
;

: calc-rxfilter  ( -- filter )
   get-rxfilter RX_FILTER_PHYERR RX_FILTER_PHYRADAR or and
   RX_FILTER_UCAST or RX_FILTER_BCAST or ( RX_FILTER_MCAST or )
   RX_FILTER_BEACON or
   use-promiscuous?  if  RX_FILTER_PROM or  then
;

: init-opmode  ( -- )
   calc-rxfilter
   set-rxfilter
   set-bssidmask
   set-opmode
   -1 -1 set-mcastfilter
;

: start-pcu-receive  ( scanning? -- )
   enable-mib-counters
   reset-ani
   0 200.0020 8048 reg@!
;

true value first-start-rx?
: start-rx  ( -- )
\   init-rx-stat
   0 to rs-otherant-cnt
   0 8 reg!
   hrx-cur ?dup  if  (restart-hrx)  else  restart-hrx  then
   lrx-cur ?dup  if  (restart-lrx)  else  restart-lrx  then
   init-opmode
   first-start-rx? start-pcu-receive
   false to first-start-rx?
;
' start-rx to start-receive

: stop-rx-dma  ( -- )
   8100 58 reg!
   20    8 reg!
   20 20 8 wait-hw drop
;

: (stop-rx)  ( -- )
   200.0020 dup 8048 reg@!
   disable-mib-counters
   0 set-rxfilter
   stop-rx-dma
   flush-rxq
;
' (stop-rx) to stop-rx

\ =================================================================================
d# 2000 constant scan-time
d#    1 constant scan-time-interval  ( ms )

d# 32 constant max-cmac
/mac-adr max-cmac * constant /cmac
/cmac buffer: cmac
0 value #cmac

: mac-cached?  ( adr -- found? )
   #cmac 0=  if  drop false exit  then
   false swap  #cmac 0  do
      dup cmac i /mac-adr * + /mac-adr comp  0=  if  nip true swap leave  then
   loop  drop
;
: ?cache-mac  ( adr -- new? )
   dup mac-cached?  if  drop false exit  then
   #cmac max-cmac >=  if
      ." Run out of space to cache unique source addresses" cr
      drop true exit              \ Assume it's new
   then
   /mac-adr #cmac * cmac + /mac-adr move
   #cmac 1+ to #cmac
   true
;
: ?add-scan-response  ( -- )
   respbuf d# 10 +  ?cache-mac  if  add-scan-response  then
;

d# 500 constant scan-threshold
0 value scan-start-ms
: (scan-ch)  ( -- )
   get-msecs to scan-start-ms
   scan-time 0  do
      queue-rx
      deque-rx  if                 ( node adr len )
         process-rx                ( node )
         free-rx
         got-response?  if  ?add-scan-response  then
         get-msecs to scan-start-ms
      else
         get-msecs scan-start-ms - scan-threshold >=  if  leave  then
      then
      scan-time-interval ms
   loop
;

: scan-ch  ( ch# -- )
   restart-scan-response
   ." Scanning channel: " dup idx>ch .d ." ..." cr
   re-set-channel (scan-ch)
   scanbuf /tsbuf .ssids
;
: scan-ch-2GHz  ( -- )  d# 11 0  do  i scan-ch  loop  ;
: scan-ch-5GHz-1  ( -- )  d# 18 d# 14  do  i scan-ch  loop  ;
: scan-ch-5GHz-2  ( -- )  d# 22 d# 18  do  i scan-ch  loop  ;
: scan-ch-5GHz-M  ( -- )  d# 33 d# 22  do  i scan-ch  loop  ;
: scan-ch-5GHz-3  ( -- )  d# 38 d# 33  do  i scan-ch  loop  ;
: scan-ch-5GHz  ( -- )
   scan-ch-5GHz-1
   scan-ch-5GHz-2
\   scan-ch-5GHz-M
   scan-ch-5GHz-3
;
: scan-ch-all  ( -- )
   scan-ch-2GHz
   scan-ch-5GHz
;

: scan-passive  ( adr len -- )
   0 to #cmac
   80 to resp-type
   start-scan-response
   scan-ch-all
;

: scan-passive-quick  ( adr len -- )
   0 to #cmac
   80 to resp-type
   start-scan-response
   (scan-ch)
   scanbuf .ssids
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
