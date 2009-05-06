\ See license at end of file
purpose: TCPv6 package

hex

true instance value use-ipv6?

[ifndef] show"
also forth definitions
: show"  [char] " parse 2drop  ; immediate
previous definitions
[then]
\ : xh 2dup type space ($header) ; ' xh is $header

[ifndef] include-ipv4
false instance value debug?
false instance value abort-on-reconnect?

\ : (  postpone .(  cr ; immediate
: l+!  +!  ;

\ : debug" postpone ." postpone cr ; immediate
: (drop$) skipstr 2drop ;                
: drop$ +level postpone (drop$) ," -level ; immediate
: debug" debug? if postpone ." postpone cr else postpone drop$ then ; immediate

alias l>n noop
: ?exit  if  r> drop  then  ;
[then]

d# 16 constant /ipv6
: copy-ipv6-addr  /ipv6 move  ;

[ifndef] include-ipv4
: oc-checksum  ( n adr len -- n' )  " oc-checksum" $call-parent  ;

2 constant pr_slowhz

false instance value alive?
0 instance value the-struct

: sfield  ( offset size -- new-offset )
   create over , +
   does> @ the-struct +
;

: set-struct  ( adr -- )  to the-struct  ;
: +struct  ( offset -- )  the-struct + set-struct  ;


\ Check:
\   unsigned comparison
\   segment wraparound

0 constant closed		\ closed
1 constant listen		\ listening for connection
2 constant syn_sent		\ active, have sent syn
3 constant syn_received		\ have send and received syn
\ states < ESTABLISHED are those where connections not established
4 constant established		\ established
5 constant close_wait		\ rcvd fin, waiting for close
\ states > CLOSE_WAIT are those where user has closed
6 constant fin_wait_1		\ have closed, sent fin
7 constant closing		\ closed xchd FIN; await FIN ACK
8 constant last_ack		\ had fin and close; await FIN ACK
\ states > CLOSE_WAIT && < FIN_WAIT_2 await ACK of FIN
9 constant fin_wait_2		\ have closed, fin is acked
d# 10 constant time_wait	\ in 2*msl quiet wait after close

[then]

struct \ ipv6-pseudoheader
     2 sfield ihv6_len
     2 sfield ihv6_pr
 /ipv6 sfield ihv6_src
 /ipv6 sfield ihv6_dst
constant /pipv6

[ifndef] include-ipv4
struct \ tcphdr
 /w sfield th_sport		\ source port
 /w sfield th_dport		\ destination port
 /l sfield th_seq		\ sequence number
 /l sfield th_ack		\ acknowledgement number
 /c sfield th_off4		\ Data offset in high nibble
 /c sfield th_flags
h# 01 constant fin	
h# 02 constant syn	
h# 04 constant rst	
h# 08 constant th_push	
h# 10 constant ack	
h# 20 constant urg	
 /w sfield th_win		\ window
 /w sfield th_sum		\ checksum
 /w sfield th_urp		\ urgent pointer
constant /tcphdr
[then]

: ipv6-struct   ( -- )  /pipv6 negate +struct  ;
: tcpv6-struct  ( -- )  /pipv6 +struct  ;

[ifndef] include-ipv4
listnode
   /n field >offset	\ Offset into buf of the still-useful data
   /n field >len	\ Length, including out-of-band data
   /n field >dlen	\ Length, excluding out-of-band data
   /n field >bufadr	\ Buffer address
   /n field >bufsize	\ Total length of buffer
   /l field >seq	\ Sequence number
   /c field >flags	\ Flags
nodetype: tcpqnode

instance variable tcpq		\ Linked list of packets to be reassembled
0 tcpq !

3 constant tcprexmtthresh	\ Retransmission threshold

d# 512 constant mssdflt		\ Default value for maximum segment size
3 constant rttdflt
pr_slowhz rttdflt * constant srttdflt	\ assumed RTT if no info

pr_slowhz d# 30 * constant tcptv_msl	\ max seg lifetime (hah!)


d# 4096 constant mssmax		\ Our (arbitrary) maximum value for
				\ Maximum segment size, to conserve memory

0 value rbuf-adr
0 value rbuf-len
0 value rbuf-actual
: rbuf-space  ( -- n )  rbuf-len rbuf-actual -  ;

\ State of this TCP
0 instance value t_flags
h# 01 constant acknow		\ ack peer immediately
h# 02 constant delack		\ ack, but try to delay it
h# 04 constant nodelay		\ don't delay packets to coalesce
h# 08 constant noopt		\ don't use tcp options
h# 10 constant sentfin		\ have sent FIN
0 [if]
h# 20 constant req_scale	\ have/will request window scaling
h# 40 constant rcvd_scale	\ other side has requested scaling
[then]

string-array state-names
   ," CLOSED"
   ," LISTEN"
   ," SYN_SENT"
   ," SYN_RECEIVED"
   ," ESTABLISHED"
   ," CLOSE_WAIT"
   ," FIN_WAIT_1"
   ," CLOSING"
   ," LAST_ACK"
   ," FIN_WAIT_2"
   ," TIME_WAIT"
end-string-array

d# 512 instance value t_maxseg	\ maximum segment size
0 instance value ts		\ state of this connection
: set-state  ( state -- )
   to ts
   debug?  if  ts state-names count type cr  then
;

\ Timers
instance variable tcpt_rexmt	tcpt_rexmt   off
instance variable tcpt_persist  tcpt_persist off 
instance variable tcpt_keep     tcpt_keep    off
instance variable tcpt_2msl     tcpt_2msl    off

: canceltimers  ( -- )
   tcpt_rexmt   off
   tcpt_persist off
   tcpt_keep    off
   tcpt_2msl    off
;
0 instance value t_dupacks	\ consecutive dup acks recd
0 instance value t_force	\ true if forcing out a byte

\ receive sequence variables
0 instance value rcv_wnd	\ receive window
0 instance value rcv_nxt	\ receive next
0 instance value rcv_up		\ receive urgent pointer
0 instance value irs		\ initial receive sequence number

0 instance value rcv_adv	\ advertised window

: .flags  ( flags -- )
   dup fin and  if  ." FIN "  then
   dup syn and  if  ." SYN "  then
   dup rst and  if  ." RST "  then
   dup th_push and  if  ." PUSH "  then
   dup ack and  if  ." ACK "  then
   dup urg and  if  ." URG "  then
   drop
;
: .pkt  ( flags win ack seq -- )  4drop  ;
[then]

: .pktv6  ( flags win ack seq -- )
   push-hex
   ." Seq: " th_seq be-l@ 8 u.r
   ."   Ack: " th_ack be-l@ 8 u.r
   ."   Win: " th_win be-w@ 4 u.r
   ."   Len: " ipv6-struct ihv6_len be-w@  /tcphdr - 4 u.r  tcpv6-struct
   ."   Flags: " th_flags c@ .flags
   cr
   pop-base
;
: .pkt  ( flags win ack seq -- )  use-ipv6?  if  .pktv6  else  .pkt  then  ;

[ifndef] include-ipv4
: +rcv_nxt  ( n -- )  rcv_nxt + to rcv_nxt  ;
[then]

0 value wbufv6-start
0 value wbufv6-adr
0 value wbufv6-top
0 value wbufv6-end
0 value wbufv6-threshold

d# 1024 d# 16 * constant /wbufv6
: wbufv6-clear  ( -- )
   wbufv6-start /wbufv6 + to wbufv6-end
   wbufv6-start dup to wbufv6-adr  to wbufv6-top
   wbufv6-start /wbufv6 2/ + to wbufv6-threshold
;
: wbufv6-allocate  ( -- )
   /wbufv6 alloc-mem to wbufv6-start
   wbufv6-clear
;

: wbufv6-actual  ( -- n )  wbufv6-top wbufv6-adr -  ;
: wbufv6-avail  ( -- n )  wbufv6-end wbufv6-top -  ;

\ Remove n bytes of data from the beginning of the write buffer
: wbufv6-drop  ( n -- )
   wbufv6-adr +  to wbufv6-adr
   \ If there are enough empty bytes at the beginning to make
   \ it worthwhile to do so, copy the data down to make more
   \ space at the end.
   wbufv6-adr wbufv6-threshold >=  if
      wbufv6-adr wbufv6-start wbufv6-actual move     \ Copy bytes down
      wbufv6-actual wbufv6-start + to wbufv6-top     \ Fix pointers
      wbufv6-start to wbufv6-adr
   then
;

[ifndef] include-ipv4
h# 555 value next-tcp-local-port

: alloc-next-tcp-local-port  ( -- port )
   next-tcp-local-port 1+                ( port )
   h# ffff and  h# 555 max               ( port )
   dup to next-tcp-local-port            ( port )
;

\ send sequence variables
0 instance value snd_una		\ send unacknowledged
0 instance value snd_nxt		\ send next
0 instance value snd_up			\ send urgent pointer
0 instance value snd_wl1		\ window update seg seq number
0 instance value snd_wl2		\ window update seg ack number
0 instance value snd_wnd		\ send window
1 value iss				\ initial send sequence number
true value first-time?			\ Used to prime iss.
1 value tcp_iss				\ initial send sequence number

0 instance value snd_max		\ highest sequence number send
					\ used to recognize retransmits

d# 65535 constant maxwin		\ largest value for unscaled window
d#    12 constant maxrxtshift		\ maximum retransmits

d# 120 d# 60 * pr_slowhz *
 constant keepidle			\ time before keepalive probes begin

d# 75 pr_slowhz *
 constant keepintvl			\ time between keepalive probes

d# 75 pr_slowhz *
 constant keep_init			\ initial connect keep alive

0 instance value maxidle

\ congestion control (for slow start, source quench, retransmit after loss)
maxwin instance value snd_cwnd		\ congestion-controlled window
maxwin instance value snd_ssthresh	\ snd_cwnd size threshhold for slow
					\ start exponential to linear switch

\ transmit timing stuff.  See below for scale of srtt and rttvar.
\ "Variance" is actually smoothed difference.
	\ Init srtt to 0, so we can tell that we have no
	\ rtt estimate.  Set rttvar so that srtt + 2 * rttvar gives
	\ reasonable initial retransmit time.

0 instance value t_idle			\ inactivity time
0 instance value t_rtt			\ round trip time
0 instance value t_rtseq		\ sequence number being timed
0 instance value t_srtt			\ smoothed round-trip time
3 pr_slowhz *   2 2+ 1- lshift
 instance value t_rttvar		\ variance in round-trip time
pr_slowhz instance value t_rttmin	\ minimum rtt allowed
0 instance value max_sndwnd		\ largest window peer has offered

\ out-of-band data
0 instance value t_oobflags		\ have some
    1 constant havedata
    2 constant haddata
0 instance value t_iobc			\ input character
[then]

0 instance value xmit_bufv6

[ifndef] include-ipv4
\ Information about the current packet

0 value iflags		\ Copy of input packet flags
0 value iseq		\ Copy of input packet sequence number
0 value iack		\ Copy of input packet sequence number
0 value iwin		\ Copy of input packet sequence window pointer
0 value iurp		\ Copy of input packet urgent pointer
0 value ilen		\ Copy of input packet length (from IP header)
0 value ilen-save	\ Copy of input packet length (from IP header), unmolested

0 value doff		\ Offset to data (after options)
0 value #oob		\ # of urgent data bytes elided
: idata  ( -- adr )  the-struct doff +  ;
: idlen  ( -- len )  ilen #oob -  ;
: -ilen  ( n -- )  negate ilen + to ilen  ;

d# 64 pr_slowhz *  constant rexmtmax
: rexmtval  ( -- n )  t_srtt 3 rshift  t_rttvar 2 rshift  +  ;

0 instance value t_rxtshift	\ log(2) of rexmt exp. backoff
rexmtval pr_slowhz max  pr_slowhz d# 64 * min
  instance value t_rxtcur	\ current retransmit value

: set-snd_nxt  ( n -- )  to snd_nxt  ;
: set-cwnd  ( n -- )  to snd_cwnd  debug?  if  ." snd_cwnd set to " snd_cwnd u. cr  then  ;

: +snd_nxt  ( n -- )  snd_nxt +  set-snd_nxt  ;

alias seq@ be-l@
alias len@ be-w@

\ Sequence numbers are 32-bit integers that use circular arithmetic
: s<   ( s1 s2 -- flag )  -  l>n  0<   ;
: s>   ( s1 s2 -- flag )  -  l>n  0>   ;
: s<=  ( s1 s2 -- flag )  -  l>n  0<=  ;
: s>=  ( s1 s2 -- flag )  -  l>n  0>=  ;

: rcvseqinit  ( -- )  irs 1+  dup to rcv_adv  to rcv_nxt  ;

: sendseqinit  ( -- )
   iss   dup to snd_up  dup to snd_max  dup set-snd_nxt  to snd_una
;
d# 125  d# 1024 *  constant issincr	\ Increments for iss each second

[then]

: his-ipv6-addr  ( -- 'ip )  " his-ipv6-addr" $call-parent  ;
: my-ipv6-addr   ( -- 'ip )  " my-ipv6-addr"  $call-parent  ;
: $set-host      ( $ -- )    " $set-host"     $call-parent  ;
: set-dest-ipv6  ( 'ip -- )  " set-dest-ipv6" $call-parent  ;
: local-ipv6?  ( -- flag )
   my-ipv6-addr his-ipv6-addr " prefix-match?" $call-parent
;

[ifndef] include-ipv4
0 instance value my-tcp-port
0 instance value his-tcp-port
[then]

/tcphdr /pipv6 +  instance buffer: tv6_template
: make-templatev6  ( -- )
   tv6_template set-struct
   the-struct /tcphdr /pipv6 +  erase

   6 ihv6_pr be-w!		\ IPPROTO_TCP
   my-ipv6-addr   ihv6_src copy-ipv6-addr
   his-ipv6-addr  ihv6_dst copy-ipv6-addr

   tcpv6-struct

   my-tcp-port  th_sport be-w!
   his-tcp-port th_dport be-w!

   5 4 lshift  th_off4 c!
;

[ifndef] include-ipv4
: copy-to-rbuf  ( adr len -- )
   tuck  rbuf-adr rbuf-actual +  swap move          ( len )
   rbuf-actual +  to rbuf-actual                    ( )
;
: copy-from-rbuf  ( adr len -- len' )
   rbuf-actual min   tuck                           ( len' adr len' )
   rbuf-adr -rot move                               ( len' )
   dup rbuf-actual =  if                            ( len' )
      0 to rbuf-actual                              ( len' )
   else                                             ( len' )
      \ Shuffle the remaining data down in the buffer
      rbuf-actual over -  to rbuf-actual            ( len' )
      rbuf-adr over +  rbuf-adr  rbuf-actual move   ( len' )
   then                                             ( len' )
;

\ Reassembly queue management

: release-tcpnode  ( prev this -- )
   \ Release the packet buffer
   dup >bufsize @  ?dup  if                      ( prev this len )
      over >bufadr @  swap  free-mem             ( prev this )
   then                                          ( prev this )
   drop delete-after  tcpqnode free-node         ( )
;

\ Present data to caller, advancing rcv_nxt through
\ completed sequence space.
: present-data  ( -- flags )
   \ Exit if we have no buffer space in which to return data
   rbuf-len 0=  if  0 exit  then

   \ Exit if the connection is not up
   ts established <  if  0 exit  then

   \ Exit if the queue is empty (i.e. there's no data to present)
   tcpq >next-node  ?dup  0=  if  0 exit  then      ( first-node )

   \ Exit if the data to be returned next has not yet arrived
   dup >seq l@  rcv_nxt <>  if  drop 0 exit  then   ( first-node )

   \ Exit if we're not quite connected
   \ This can't happen because of the earlier check for ts=established
\   dup >dlen @ 0<>  ts syn_received =  and  if  drop 0 exit  then  ( node )

   begin                                            ( node )
      dup >flags c@ fin and swap                    ( flags node )

      \ Compute the copy length
      dup >dlen @  rbuf-len min                     ( flags node len )

      \ Update rcv_nxt in sequence space, which include out-of-band data.
      \ If len > dlen, the difference represents removed out-of-band data.
      2dup  over >len @  rot >dlen @ -  +  +rcv_nxt ( flags node len )

      \ Copy the data into the user buffer
      over dup >bufadr @ swap >offset @ +           ( flags node len adr )
      over copy-to-rbuf                             ( flags node len )

      \ "remove" the data from the list node
      2dup negate swap 2dup  >dlen +!  >len +!      ( flags node len )

      \ If we haven't consumed all the data in this node, update
      \ its variables and exit.
      over >dlen @  if                              ( flags node len )
         2dup swap >seq l+!                         ( flags node len )
         2dup swap >offset +!                       ( flags node len )

         \ There is no point in continuing, as the user buffer must be
         \ full (otherwise we would have consumed all the node data).
         2drop exit
      then                                          ( flags node len )

      \ We have used all the node's data, so we can release the node.
      drop                                          ( flags node )

      \ Release the node and its buffer
      tcpq swap release-tcpnode                     ( flags )

      \ If the user buffer is full, we can exit now
      rbuf-len 0=  ?exit                            ( flags )

      \ Otherwise advance to the next node
      tcpq >next-node                               ( flags node )
   ?dup while                                       ( flags node )
      nip                                           ( node )
   repeat                                           ( flags )
;


0 value trim-offset  \ "local" variable used for reassembly queue insertion

\ If there is a preceding segment, it may provide some of
\ our data already.  If so, drop the data from the incoming
\ segment.  If it provides all of our data, drop us.
: ?trim-prev  ( prev -- enclosed? )
   0 to trim-offset
   dup tcpq =  if  drop false exit  then                    ( prev )
   dup >seq l@  swap >len l@ +  iseq -  l>n  \ Wraparound   ( n )

   \ Exit if the segments don't overlap
   dup 0<=  if  drop false exit  then                       ( n )

   \ Return true if the new packet is enclosed by the old segment
   dup ilen >=  if  drop true exit  then                    ( n )

   \ Otherwise trim the packet.
   dup to trim-offset					    ( n )
   dup  iseq + l>n to iseq                                  ( n )
   -ilen
;
: ?trim-nexts  ( prev this -- prev this' )
   begin  dup  while                         ( prev node )
      iseq ilen +  over >seq l@ -  l>n       ( prev node n )

      \ Exit if no overlap
      dup 0<=  if  3drop exit  then          ( prev node n )

      2dup swap >len @  <  if                ( prev node n )
         \ Partial overlap - trim node and exit
         2dup negate swap >len +!            ( prev node n )
         2dup swap >seq l+!                  ( prev node n )
         2dup swap >offset l+!               ( prev node )
         exit
      then                                   ( prev node n )
      \ Complete overlap - discard node      ( prev node n )
      drop                                   ( prev node )
      2dup >next-node  2swap                 ( prev next prev node )
      release-tcpnode                        ( prev next )
   repeat                                    ( prev next )
;
: new-node  ( -- )
   tcpqnode allocate-node                    ( new )
   0 over >offset !                          ( new )
   ilen over >len !                          ( new )
   idlen over >dlen !                        ( new )
   iseq over >seq l!                         ( new )
   \ XXX this is what BSD does, but it seems to me that it
   \ should be "iflags" instead of "th_flags c@", because
   \ it would seem that you want the FIN flag to be trimmed
   \ if it is outside the receive window.
   th_flags c@ over >flags c!                ( new )
   idlen over >bufsize !                     ( new )
   idlen  if                                 ( new )
      idlen alloc-mem                        ( new buf )
      2dup swap >bufadr !                    ( new buf )
      idata trim-offset +  swap  ilen  move  ( new )
   then                                      ( new )
;
: next-seg  ( node-data-adr -- flag )  >seq l@  iseq -  0>  ;
: reassemble  ( -- flags )
   tcpq  ['] next-seg   find-node            ( prev-node this-node|0 )
   over ?trim-prev  if  2drop 0 exit  then   ( prev this )
   ?trim-nexts                               ( prev this )   

   \ Create a new fragment queue entry and insert it into place
   drop new-node                             ( prev new )
   swap insert-after                         ( )

   present-data
;

[then]

\ End of reassembly queue management

\ Assumes active struct is set to the TCP header

\ For now we assume no IP options; the IP layer should probably
\ strip them for us anyway

: sumv6-bad?  ( adr len -- flag )
   swap /pipv6 - set-struct        ( len )
   dup ihv6_len be-w!              ( len )  \ Put length field back
   6 ihv6_pr be-w!                 ( len )  \ TCP protocol
   0 the-struct  rot /pipv6 +  oc-checksum  h# ffff <>
;

[ifndef] include-ipv4
0 value optp  0 value optlen
0 value acked
0 value needoutput
0 value cantrcvmore?

: set-flag  ( bitmask -- )  t_flags or  to t_flags  ;
: set-acknow  ( -- )  acknow set-flag  ;
: clear-iflag  ( flag -- )  iflags swap invert and  to iflags  ;
: iflag?  ( bitmask -- )  iflags and  0<>  ;
: t_flag?  ( bitmask -- )  t_flags and  0<>  ;
: take-data  ( -- )
   ilen +rcv_nxt

   \ Set DELACK for segments received in order, but ack immediately
   \ when segments are out of order (so fast retransmit can work).
   idata  idlen  copy-to-rbuf
   iflags th_push  and  if  acknow  else  delack  then  set-flag
;

: set-rxtcur  ( val limit -- )  max  rexmtmax min to t_rxtcur  ;

\ Collect new round-trip time estimate
\ and update averages and current timeout
: xmit_timer  ( rtt -- )
   1-                                             ( rtt )
   t_srtt  if                                     ( rtt )
      \ srtt is stored as fixed point with 3 bits after the
      \ binary point (i.e., scaled by 8).  The following magic
      \ is equivalent to the smoothing algorithm in rfc793 with
      \ an alpha of .875 (srtt = rtt/8 + srtt*7/8 in fixed
      \ point).  Adjust rtt to origin 0.
      dup 2 lshift  t_srtt 3 rshift -             ( rtt delta )
      dup t_srtt +  1 max  to t_srtt              ( rtt delta )

      \ We accumulate a smoothed rtt variance (actually, a
      \ smoothed mean difference), then set the retransmit
      \ timer to smoothed rtt + 4 times the smoothed variance.
      \ rttvar is stored as fixed point with 2 bits after the
      \ binary point (scaled by 4).  The following is
      \ equivalent to rfc793 smoothing with an alpha of .75
      \ (rttvar = rttvar*3/4 + |delta| / 4).  This replaces
      \ rfc793's wired-in beta.
      abs  t_rttvar 2 rshift  -                   ( rtt delta' )
      1 max  to t_rttvar                          ( rtt )
   else
      \ No rtt measurement yet - use the unsmoothed rtt.
      \ Set the variance to half the rtt (so our first
      \ retransmit happens at 3*rtt).
      dup  5 lshift  to t_srtt                    ( rtt ) ( 5 is 3 + 2 )
      dup 3 lshift  to t_rttvar                   ( rtt )
   then                                           ( rtt )
   0 to t_rtt                                     ( rtt )
   0 to t_rxtshift                                ( rtt )

   \ the retransmit should happen at rtt + 4 * rttvar.
   \ Because of the way we do the smoothing, srtt and rttvar
   \ will each average +1/2 tick of bias.  When we compute
   \ the retransmit timer, we want 1/2 tick of rounding and
   \ 1 extra tick because of +-1/2 tick uncertainty in the
   \ firing of the timer.  The bias will give us exactly the
   \ 1.5 tick we need.  But, because the bias is
   \ statistical, we have to test that we don't drop below
   \ the minimum feasible timer (which is 2 ticks).

   2+  rexmtval  set-rxtcur
;

: ack-una  ( -- )
   iack to snd_una
   snd_nxt snd_una s<  if  snd_una set-snd_nxt  then
;
[then]

\ Determine a reasonable value for maxseg size.
\ If the route is known, check route for mtu.
\ If none, use an mss that can be handled on the outgoing
\ interface without forcing IP to fragment; if bigger than
\ an mbuf cluster (MCLBYTES), round down to nearest multiple of MCLBYTES
\ to utilize large mbufs.  If no route is found, route has no mtu,
\ or the destination isn't local, use a default, hopefully conservative
\ size (usually 512 or the default IP max size, but no more than the mtu
\ of the interface), as we can't discover anything about intervening
\ gateways or networks.  We also initialize the congestion/slow start
\ window to be a single segment if the destination isn't local.
\ While looking at the routing entry, we also initialize other path-dependent
\ parameters from pre-set or cached values in the routing entry.

: tcp_mssv6  ( offer -- chosen )
   \ XXX we probably should try to first determine whether or not we
   \ know anything about the route, and if not, just return mssdflt

   \ Use link MTU on a LAN, otherwise use a conservative default
   \ not larger than the link MTU

   " max-ipv6-payload" $call-parent /tcphdr -          ( offer limit )
   mssmax min                                          ( offer limit )
   local-ipv6?  0=  if  mssdflt min  then              ( offer limit )

   \ If offer is nonzero, use the computed value, otherwise use the
   \ smaller of the offer and the computed value.
   over  if  over min  then                            ( offer chosen )

   \ But in all cases, use at least 32 bytes
   d# 32 max                                           ( offer chosen' )

   \ If this results in a smaller segment size than we're currently
   \ using, or if offer is nonzero, then reduce the current size.
   dup t_maxseg <  rot 0<>  or  if                     ( chosen )
      dup to t_maxseg                                  ( chosen )
      debug?  if  ." Maxseg set to " t_maxseg u. cr  then
   then                                                ( chosen )

   \ Set the slow-open window size
   dup set-cwnd                                        ( chosen )
;

[ifndef] include-ipv4

\ Output code

0 value len
0 value ourfinisacked?

0 value idle?
0 value sendalot?

\ Flags used when sending segments in tcp_output.
\ Basic flags (TH_RST,TH_ACK,TH_SYN,TH_FIN) are totally
\ determined by state, with the proviso that TH_FIN is sent only
\ if all data queued for output is included in the segment.
create outflags
    rst ack or c,	\ 0 closed
    0 c,		\ 1 listen
    syn c,		\ 2 syn_sent
    syn ack or c,	\ 3 syn_received
    ack c,		\ 4 established
    ack c,		\ 5 close_wait
    fin ack or c,	\ 6 fin_wait_1
    fin ack or c,	\ 7 closing
    fin ack or c,	\ 8 last_ack
    ack c,		\ 9 fin_wait_2
    ack c,		\ 10 time_wait

0 value oflags
: oflag?  ( bitmask -- flag )  oflags and 0<>  ;
: fin-off  ( -- )  oflags  fin invert and  to oflags  ;

create backoff
base @  decimal
   1 , 2 , 4 , 8 , 16 , 32 , 64 , 64 , 64 , 64 , 64 , 64 , 64 ,
base !

pr_slowhz     5 *  constant persmin
pr_slowhz d# 60 *  constant persmax

: setpersist  ( -- )
   t_srtt 2 rshift   t_rttvar +  1 rshift         ( t )

   \ Start/restart persistance timer.
   backoff t_rxtshift na+ @  *                    ( t*backoff )

   persmin max  persmax min  tcpt_persist !
   
   t_rxtshift 1+  maxrxtshift min  to t_rxtshift
;

0 value win
0 value offs
[then]

: dont-sendv6?   ( -- exit? )
   false

   \ Sender silly window avoidance.  If connection is idle and can send
   \ all data, a maximum segment, at least a maximum default-size segment
   \ do it, or are forced, do it; otherwise don't bother.
   \ If peer's buffer is tiny, then send when window is at least half open.
   \ If retransmitting (possibly after persist timer forced us
   \ to send into a small window), then must resend.

   len  if
      len t_maxseg =  ?exit

      idle?  nodelay t_flag?  or   len offs +  wbufv6-actual  >=  and  ?exit
     
      t_force  ?exit

      len  max_sndwnd 2/  >=  ?exit

      snd_nxt snd_max s<  ?exit
   then

   \ Compare available window to amount of window known to peer (as
   \ advertised window less next expected input).  If the difference
   \ is at least two max size segments, or at least 50% of the maximum
   \ possible window, then want to send a window update to peer.

   win 0>  if
      \ "adv" is the amount we can increase the window,
      \ taking into account that we are limited by MAXWIN

      maxwin win min  rcv_adv rcv_nxt -  -               ( adv )
      dup  t_maxseg 2*  >=  if  drop exit  then          ( adv )

      2*  rbuf-len  >=  ?exit                            ( )
   then

   \ Send if we owe peer an ACK.

   acknow t_flag?  ?exit
   syn rst or  oflag?  ?exit
   snd_up snd_una s>  ?exit

   \ If our state indicates that FIN should be sent
   \ and we have not yet done so, or we're retransmitting the FIN,
   \ then we need to send.

   fin oflag?
   sentfin t_flag? 0=  snd_nxt snd_una =  or  and  ?exit

   \ TCP window updates are not reliable, rather a polling protocol
   \ using ``persist'' packets is used to insure receipt of window
   \ updates.  The three ``states'' for the output side are:
   \ idle               not doing retransmits or persists
   \ persisting         to move a small or zero window
   \ (re)transmitting   and thereby not persisting
   \
   \ TCPT_PERSIST is set when we are in persist state.
   \ t_force is set when we are called to send a persist packet.
   \ TCPT_REXMT is set when we are retransmitting
   \
   \ The output side is idle when both timers are zero.
   \
   \ If send window is too small, there is data to transmit, and no
   \ retransmit or persist is pending, then go to persist state.
   \ If nothing happens soon, send when timer expires:
   \ if window is nonzero, transmit what we can, otherwise force out a byte.

   wbufv6-actual 0<>  tcpt_rexmt @ 0=  and  tcpt_persist @ 0=  and  if
      0 to t_rxtshift
      setpersist
   then

   drop true
;

[ifndef] include-ipv4
\ TCP output routine: figure out what should be sent and send it.
d# 32 buffer: opt
0 value hdrlen
[then]

: make-optionsv6  ( -- )
   \ Before ESTABLISHED, force sending of initial options
   \ unless TCP set not to do any options.
   \ NOTE: we assume that we have space for the IP/TCP header plus TCP
   \ options, leaving room for a maximum link header, i.e.
   \    max_linkhdr + sizeof (struct tcpiphdr) + optlen <= buflen

   0 to optlen
   /tcphdr to hdrlen
   syn oflag?  if
      iss set-snd_nxt
      noopt t_flag?  0=  if
         2 opt c!                       \ tcpopt_maxseg
         4 opt 1+ c!                    \ option length
         debug?  if  ." Sending "  then
         0 tcp_mssv6  opt 2+ be-w!      \ option value
         4 to optlen
      then
   then
 
   optlen  hdrlen +  to hdrlen
 
   \ Adjust data length if insertion of options will
   \ bump the packet length beyond the t_maxseg length.

   len  t_maxseg optlen -  >  if
      t_maxseg optlen -  to len
      fin-off
      true to sendalot?
   then
;

: insert-datav6  ( -- )
   \ Grab a transmit buffer, attaching a copy of data to
   \ be transmitted, and initialize the header from
   \ the template for sends on this connection.

   xmit_bufv6 set-struct

   len  if
      wbufv6-adr offs +   xmit_bufv6 hdrlen +  len  move

      \ If we're sending everything we've got, set PUSH.
      \ (This will keep happy those implementations which only
      \ give data to the user when a buffer fills or
      \ a PUSH comes in.)

      offs len +  wbufv6-actual  =  
      len snd_cwnd =  or	\ Also PUSH when we have a lot
      if
         oflags th_push or  to oflags
      then
   then
;

[ifndef] include-ipv4
: set-window  ( -- )
   \ Calculate receive window.  Don't shrink window,
   \ but avoid silly window syndrome.

   win  rbuf-len 4 /  <   win t_maxseg <  and  if  0 to win  then

   win  maxwin  min   rcv_adv rcv_nxt -  max  th_win be-w!

   snd_up snd_nxt s>  if
      snd_up snd_nxt -  th_urp be-w!
      th_flags c@  urg or  th_flags c!
   else
      \ If no urgent pointer to send, then we pull
      \ the urgent pointer to the left edge of the send window
      \ so that it doesn't drift into the send window on sequence
      \ number wraparound.
      snd_una to snd_up
   then
;
: set-timers  ( -- )
   \ In transmit state, time the transmission and arrange for
   \ the retransmit.  In persist state, just set snd_max.

   t_force 0=   tcpt_persist @ 0=  or  if
      snd_nxt                            ( startseq )

      \ Advance snd_nxt over sequence space of this segment.

      syn oflag?  if  1 +snd_nxt  then
      fin oflag?  if  1 +snd_nxt  sentfin set-flag  then

      len  +snd_nxt

      snd_nxt snd_max s>  if
         snd_nxt to snd_max

         \ Time this transmission if not a retransmission and
         \ not currently timing anything.
         t_rtt 0=  if  1 to t_rtt  dup to t_rtseq  then  ( startseq )
      then

      \ We're done with startseq
      drop                                               ( )

      \ Set retransmit timer if not currently set,
      \ and not doing an ack or a keep-alive probe.
      \ Initial value for retransmit timer is smoothed
      \ round-trip time + 2 * round-trip time variance.
      \ Initialize shift counter which is used for backoff
      \ of retransmit time.

      tcpt_rexmt @ 0=   snd_nxt snd_una <>  and  if
         t_rxtcur  tcpt_rexmt !
         tcpt_persist @  if  tcpt_persist off  0 to t_rxtshift  then
      then
   else
      snd_nxt len +  snd_max  s>  if  snd_nxt len +  to snd_max  then
   then
;
: send  ( -- )  ;
[then]

\ Called only from tcp_output
: sendv6  ( -- )
   make-optionsv6

   insert-datav6

   tv6_template  xmit_bufv6 /pipv6 -  /tcphdr /pipv6 +  move       \ Copy in header

   \ Fill in fields, remembering maximum advertised
   \ window for use in delaying messages about window sizes.
   \ If resending a FIN, be sure not to use a new sequence number.

   fin oflag?  sentfin t_flag?  and
   snd_nxt snd_max =  and  if  -1 +snd_nxt  then

   \ If we are doing retransmissions, then snd_nxt will not reflect the first
   \ unsent octet.  For ACK only packets, we do not want the sequence number
   \ of the retransmitted packet, we want the sequence number of the next
   \ unsent octet.  So, if there is no data (and no SYN or FIN), use snd_max
   \ instead of snd_nxt when filling in iseq.  But if we are in persist
   \ state, snd_max might reflect one byte beyond the right edge of the
   \ window, so use snd_nxt in that case, since we know we aren't doing a
   \ retransmission. (retransmit and persist are mutually exclusive...)

   len 0<>  syn fin or oflag?  or  tcpt_persist @ 0<>  or  if
      snd_nxt
   else
      snd_max
   then
   th_seq be-l!

   rcv_nxt  th_ack be-l!
   optlen  if
      opt  the-struct /tcphdr +  optlen  move
      /tcphdr optlen +  2 rshift  4 lshift  th_off4 c!
   then

   oflags  th_flags c!

   set-window

   \ Put TCP length in extended header, and then
   \ checksum extended header and data.

   ipv6-struct
   6 ihv6_pr be-w!
   /tcphdr optlen + len +  ihv6_len be-w!              ( )
   0  the-struct  hdrlen len + /pipv6 +  oc-checksum   ( sum )
   tcpv6-struct                                        ( sum )
   th_sum be-w!                                        ( )

   set-timers

   debug?  if  ." XMT "  .pkt  then

   \ Send to IP level.

   the-struct  hdrlen len +  6  " send-ipv6-packet" $call-parent  \ 6 is IPPROTO_TCP

   \ Data sent (as far as we can tell).
   \ If this advertises a larger window than any other segment,
   \ then remember the size of the advertised window.
   \ Any pending ACK has now been sent.

   win 0>   rcv_nxt win +  rcv_adv  s>  and  if
      rcv_nxt win +  to rcv_adv
   then
   t_flags  acknow delack or  invert and  to t_flags
;

: tcp_outputv6  ( -- )
   \ Determine length of data that should be transmitted,
   \ and flags that will be used.
   \ If there is some data or critical controls (SYN, RST)
   \ to send, then transmit; otherwise, investigate further.

   snd_max snd_una =  to idle?
   idle?  t_idle t_rxtcur >=  and  if
      \ We have been idle for "a while" and no acks are expected to clock out
      \ any data we send -- slow start to get ack "clock" running again.
      t_maxseg set-cwnd
   then
   begin
      false to sendalot?
      snd_nxt snd_una - to offs
      snd_wnd snd_cwnd min  to win
      outflags ts ca+ c@  to oflags

      \ If in persist timeout with window of 0, send 1 byte.
      \ Otherwise, if window is small but nonzero and timer expired,
      \ we will send what we can and go to transmit state.

      t_force  if
         win  if
            tcpt_persist off
            0 to t_rxtshift
         else
            \ If we still have some data to send, then clear the FIN bit.
            \ Usually this would happen below when it realizes that we
            \ aren't sending all the data.  However, if we have exactly
            \ 1 byte of unset data, then it won't clear the FIN bit below,
            \ and if we are in persist state, we wind up sending the packet
            \ without recording that we sent the FIN bit.
            \
            \ We can't just blindly clear the FIN bit, because if we don't
            \ have any more data to send then the probe will be the FIN itself.
            off wbufv6-actual <  if  fin-off  then
            1 to win
         then
      then

      win wbufv6-actual <  if  fin-off  win  else  wbufv6-actual  then  ( n )
      offs -  to len

      len 0<  if
         \ If FIN has been sent but not acked, but we haven't been called
         \ to retransmit, len will be -1.  Otherwise, window shrank
         \ after we sent into it.  If window shrank to 0, cancel pending
         \ retransmit and pull snd_nxt back to (closed) window.  We will
         \ enter persist state below.  If the window didn't close completely,
         \ just wait for an ACK.
         0 to len
         win 0=  if  tcpt_rexmt off  snd_una set-snd_nxt  then
      then

      len t_maxseg >  if  t_maxseg to len  fin-off  true to sendalot?  then

      rbuf-space to win

      dont-sendv6?  ?exit
        
      sendv6
   sendalot? 0=  until
;

: fast-pathv6?  ( -- flag )
   \ Header prediction: check for the two common cases
   \ of a uni-directional data xfer.  If the packet has
   \ no control flags, is in-sequence, the window didn't
   \ change and we're not retransmitting, it's a
   \ candidate.  If the length is zero and the ack moved
   \ forward, we're the sender side of the xfer.  Just
   \ free the data acked & wake any higher level process
   \ that was blocked waiting for space.  If the length
   \ is non-zero and the ack didn't move, we're the
   \ receiver side.  If we're getting packets in-order
   \ (the reassembly queue is empty), add the data to
   \ the socket buffer and note that we need a delayed ack.

   ts established =			\ Connection up?
   iflags h# 37 and ack =  and		\ No control flags?
   iseq rcv_nxt =          and		\ In sequence?
   iwin 0<>                and		\ Window didn't change?
   iwin snd_wnd =          and		\ Window didn't change?
   snd_nxt snd_max =       and  if	\ Not retransmitting?
      ilen  if
         \ Incoming data

         iack snd_una =			\ in sequence data packet?
         tcpq >next-node 0=  and	\ reassembly queue empty?
         ilen rbuf-space <=  and  if	\ enough space to take it?
            take-data
            true exit
         then
         false exit
      then

      \ ACK for outgoing data

      iack snd_una - 0>
      iack snd_max - 0<=  and
      snd_cwnd snd_wnd >=   and
      t_dupacks tcprexmtthresh <  and  if
         \ This is a pure ack for outstanding data
         t_rtt 0<>  iack t_rtseq - 0>  and  if
             t_rtt xmit_timer
         then
         iack snd_una -  to acked
				\ XXX drop-snd needs to "wakeup" the sender
         acked wbufv6-drop
         iack to snd_una				
         \ We are now finished with the packet data

         \ If all outstanding data are acked, stop
         \ retransmit timer, otherwise restart timer
         \ using current (possibly backed-off) value.
         \ If process is waiting for space,
         \ wakeup/selwakeup/signal.  If data
         \ are ready to send, let output
         \ decide between more output or persist.

         snd_una snd_max =  if  tcpt_rexmt off  else
         tcpt_persist @ 0=  if  t_rxtcur tcpt_rexmt !  then then

         wbufv6-actual  if  tcp_outputv6  then
         true exit
      then
      false exit
   then

   false
;

[ifndef] include-ipv4
: get-info  ( -- )
   th_flags c@     to iflags
   th_seq   be-l@  to iseq
   th_ack   be-l@  to iack
   th_win   be-w@  to iwin
   th_urp   be-w@  to iurp
;

: pull-options  ( -- error )
   \ Handle options
   th_off4 c@ 4 rshift  /l*  to doff   ( )
   doff /tcphdr <  doff ilen >  or   if  true exit  then

   doff -ilen
   doff /tcphdr - dup to optlen   if  the-struct /tcphdr +  to optp  then
   false
;
: update-window  ( -- )
   \ Update window information.
   \ Don't look at window if no ACK: TAC's send garbage on first SYN.
   ack iflag?      snd_wl1 iseq s<  and
   snd_wl1 iseq =  snd_wl2 iack s<  and    or
   snd_wl2 iack =  iwin snd_wnd >   and    or  if
      \ keep track of pure window updates
      \ ilen 0=  snd_wl2 iack =  and  iwin snd_wnd >  and  if  ( +stats )  then
      iwin to snd_wnd
      iseq to snd_wl1
      iack to snd_wl2

      snd_wnd max_sndwnd >  if  snd_wnd to max_sndwnd  then
      true to needoutput
   then
;

\ Move the byte of urgent data out of the in-band data stream,
\ placing it in t_iobc.

: pulloutofband  ( -- )
   iurp 1-                                 ( off )     \ Offset to OOB byte
   idata over +                            ( off adr ) \ Address of OOB byte
   dup c@ to t_iobc                        ( off adr ) \ Get OOB byte
   t_oobflags  havedata or  to t_oobflags  ( off adr ) \ Note its existence
   dup ca1+ swap  rot                      ( adr+1 adr off ) \ Setup to remove
   ilen swap - 1-  move                    ( )         \ byte from in-band data
   #oob 1+  to #oob                                    \ Note elided byte
;

: do-urgent  ( -- )
   \ Process segments with URG.
   urg iflag?  iurp 0<>  and   ts time_wait <  and  if
      \ This is a kludge, but if we receive and accept
      \ random urgent pointers, we'll crash in
      \ soreceive.  It's hard to imagine someone
      \ actually wanting to send this much urgent data.

      iurp rbuf-actual +  rbuf-len >  if
         0 to iurp
         urg clear-iflag
         exit
      then

      \ If this segment advances the known urgent pointer,
      \ then mark the data stream.  This should not happen
      \ in CLOSE_WAIT, CLOSING, LAST_ACK or TIME_WAIT STATES since
      \ a FIN has been received from the remote side. 
      \ In these states we ignore the URG.
      \
      \ According to RFC961 (Assigned Protocols),
      \ the urgent pointer points to the last octet
      \ of urgent data.  We continue, however,
      \ to consider it to indicate the first octet
      \ of data past the urgent section as the original 
      \ spec states (in one of two places).

      iseq iurp +  rcv_up  s>  if
         iseq iurp +  to rcv_up
\        rbuf-actual  rcv_up rcv_nxt - +  1-  to so_oobmark
         \  XXX if (so_oobmark == 0)  so_state |= SS_RCVATMARK;
         \  XXX sohasoutofband(so);
         t_oobflags  havedata haddata or  invert and  to t_oobflags
      then

      \ Remove out of band data so doesn't get presented to user.
      \ This can happen independent of advancing the URG pointer,
      \ but if two URG's are pending at once, some out-of-band
      \ data may creep in... ick.

      iurp ilen u<=  if  pulloutofband  then
   else
      \ If no out of band data is expected, pull receive
      \ urgent pointer along with the receive window.
      rcv_nxt rcv_up s>  if  rcv_nxt to rcv_up  then
   then
;
[then]

: do-datav6  ( -- )
   \ Process the segment text, merging it into the TCP sequencing queue,
   \ and arranging for acknowledgment of receipt if necessary.
   \ This process logically involves adjusting rcv_wnd as data
   \ is presented to the user (this happens in tcp_usrreq
   \ case PRU_RCVD).  If a FIN has already been received on this
   \ connection then we just ignore the text.

   ilen 0<>  fin iflag?  or   ts time_wait <  and  if
      iseq rcv_nxt =
      tcpq >next-node 0<>  and
      ts established =     and   if
         \ The segment need not be queued for reassembly, because
         \ this is the next segment and the queue is empty.
         take-data
         \ XXX this is what BSD does, but it seems to me that it
         \ should be "iflags" instead of "th_flags c@", because
         \ it would seem that you want the FIN flag to be trimmed
         \ if it is outside the receive window.
         th_flags c@ fin and  to iflags
      else
         \ Insert the segment into the reassembly queue
         reassemble to iflags
         set-acknow
      then

      \ Note the amount of data that peer has sent into our
      \ window, in order to estimate the sender's buffer size.

      \ XXX NetBSD sets this, but then doesn't use the value
      \ rbuf-len  rcv_adv rcv_nxt -  -  to len
   else
      fin clear-iflag
   then

   \ If FIN is received ACK the FIN and let the user know
   \ that the connection is closing.  Ignore a FIN received before
   \ the connection is fully established.

   fin iflag?  ts established >=  and   if
      ts time_wait <  if
         true to cantrcvmore?
         set-acknow
         1 +rcv_nxt	\ Advance sequence number past FIN
      then
      ts case

         \ In ESTABLISHED STATE enter the CLOSE_WAIT state.
         established  of   close_wait set-state  endof

         \ If still in FIN_WAIT_1 STATE FIN has not been acked so
         \ enter the CLOSING state.
         fin_wait_1  of   closing set-state  endof

         \ In FIN_WAIT_2 state enter the TIME_WAIT state,
         \ starting the time-wait timer, turning off the other 
         \ standard timers.

         fin_wait_2  of
            time_wait set-state
            canceltimers
            tcptv_msl 2* tcpt_2msl !
            \ soisdisconnected
         endof

         \ In TIME_WAIT state restart the 2 MSL time_wait timer.
         time_wait  of   tcptv_msl 2* tcpt_2msl !  endof
      endcase
   then

   \ Return any desired output.
   needoutput  acknow t_flag?  or  if  tcp_outputv6  then
;
: dropafterackv6  ( -- )
   \ Generate an ACK dropping incoming segment if it occupies
   \ sequence space, where the ACK reflects our state.
   rst iflag?  ?exit
   set-acknow
   tcp_outputv6
;

\ Called with the-struct set to a TCP header
: respondv6  ( ack seq flags -- )
   \ Copy to the transmit area so we can modify it
   ipv6-struct
   the-struct  xmit_bufv6 /pipv6 -  /tcphdr /pipv6 +  move
   xmit_bufv6 set-struct

   \ Now the-struct points to the copy

                              ( ack seq flags )
   th_flags c!                ( ack seq )
   th_seq   be-l!             ( ack )
   th_ack   be-l!             ( )
   /tcphdr 2 rshift  4 lshift  th_off4 c!
   rbuf-space th_win be-w!
   0  th_urp be-w!
   0  th_sum be-w!

   \ Prepare the pseudo-header for checksumming
   ipv6-struct
   6 ihv6_pr be-w!
   /tcphdr ihv6_len be-w!
   0  the-struct  /tcphdr /pipv6 +  oc-checksum   ( sum )
   tcpv6-struct
   th_sum be-w!

   debug?  if  ." Xrs "  .pkt  then

   \ XXX this will always send to our server; it should
   \ be able to send to anybody.
   the-struct  /tcphdr  6  " send-ip-packet" $call-parent
\   the-struct  /tcphdr  6  dst-ip  (send-ip-packet)
;

: swap-addressesv6  ( -- )
   ipv6-struct
   ihv6_src unaligned-l@  ihv6_dst unaligned-l@
   ihv6_src unaligned-l!  ihv6_dst unaligned-l!

   tcpv6-struct
   th_sport w@  th_dport w@  th_sport w!  th_dport w!
;
: multicast-dstv6?  ( -- flag )
   ipv6-struct  ihv6_dst  tcpv6-struct   ( adr )  " his-ipv6-addr-mc?" $call-parent
;
/ipv6 buffer: tmp-ipv6
: dropwithresetv6  ( -- )
   \ Generate a RST, dropping incoming segment.
   \ Make ACK acceptable to originator of segment.
   \ Don't bother to respond if destination was broadcast/multicast.

   rst iflag?  ?exit

   \ XXX we also need to reject broadcast source addresses
\   m_flags  bcast mcast or  and   ?exit
   multicast-dstv6?  ?exit

   swap-addressesv6
   ack iflag?  if
      0 iack rst
   else
      syn iflag?  if  -1 -ilen  then
      iseq ilen +  0  rst ack or
   then                     ( ack seq flags )

   his-ipv6-addr tmp-ipv6 copy-ipv6-addr
   ipv6-struct ihv6_dst set-dest-ipv6 tcpv6-struct
   respondv6                ( )
   tmp-ipv6 set-dest-ipv6
;

: step6v6  ( -- )
   update-window
   do-urgent
   do-datav6
;

: trimthenstep6v6  ( -- )
   \ Advance iseq to correspond to first data byte.
   \ If data, trim to stay within window,
   \ dropping FIN if necessary.
   iseq 1+ to iseq
   ilen rcv_wnd  >  if
      rcv_wnd to ilen
      iflags  fin invert and  to iflags
   then
   iseq 1-  to snd_wl1
   iseq to rcv_up
   step6v6
;

\ Close a TCP control block, freeing all space
: tcp_close  ( -- )
   \ Release reassmbly queue nodes
   begin  tcpq >next-node  while  tcpq dup >next-node release-tcpnode  repeat

   closed set-state
   false to alive?
   false to abort-on-reconnect?
;
[then]

\ Drop a TCP connection, reporting the specified error.
\ If connection is synchronized, then send a RST to peer.
: tcp_drop  ( -- )
   ts syn_received >=  if   closed set-state  tcp_outputv6  then
   tcp_close
;

[ifndef] include-ipv4
: next-iss  ( -- )
   tcp_iss to iss
   issincr 2/  tcp_iss +  to tcp_iss
;
[then]

: do-syn-sentv6?  ( -- done? )
   ts syn_sent <>  if  false exit  then

   \ If the state is SYN_SENT:
   \	if seg contains an ACK, but not for our SYN, drop the input.
   \	if seg contains a RST, then drop the connection.
   \	if seg does not contain SYN, then drop it.
   \ Otherwise this is an acceptable SYN segment
   \	initialize rcv_nxt and irs
   \	if seg contains ack then advance snd_una
   \	if SYN has been acked change to ESTABLISHED else SYN_RCVD state
   \	arrange for segment to be acked (eventually)
   \	continue processing rest of data/controls, beginning with URG

   ack iflag?   iack iss s<=  iack snd_max s>  or  and  if
      dropwithresetv6 true exit
   then

   rst iflag?  if
      ack iflag?  if
         debug" Connection refused"
         tcp_drop
      then   \ Connection refused
      true exit
   then

   syn iflag?  0=  if  true exit  then

   ack iflag?  if  ack-una  then

   tcpt_rexmt off
   iseq to irs
   rcvseqinit
   set-acknow
   ack iflag?  snd_una iss s>  and  if
      established set-state
      present-data drop
      \ if we didn't have to retransmit the SYN,
      \ use its rtt as our initial srtt & rtt var.
      t_rtt  if  t_rtt  xmit_timer  then
   else
      syn_received set-state
   then

   trimthenstep6v6 true
;

[ifndef] include-ipv4
: ?drop-some  ( -- )
   rcv_nxt iseq -  dup 0<=  if  drop exit  then   ( #todrop )
   syn iflag?  if
      syn clear-iflag
      iseq 1+ to iseq
      iurp 1 >  if
          iurp 1- to iurp
      else
          urg clear-iflag
      then
      1-                                            ( #todrop' )
   then                                             ( #todrop )

   dup ilen >=  if                                  ( #todrop )
      \ Any valid FIN must be to the left of the
      \ window.  At this point, FIN must be a
      \ duplicate or out-of-sequence, so drop it.
      fin clear-iflag

      \ Send ACK to resynchronize, and drop any data,
      \ but keep on processing for RST or ACK.
      set-acknow                 ( #todrop )
      drop ilen                  ( #todrop' )
   then                          ( #todrop )

   dup doff + to doff            ( #todrop )
   dup iseq + to iseq            ( #todrop )
   dup -ilen                     ( #todrop )
   iurp over >  if               ( #todrop )
      iurp over - to iurp        ( #todrop )
   else                          ( #todrop )
      urg clear-iflag            ( #todrop )
      0 to iurp                  ( #todrop )
   then                          ( #todrop )
   drop                          ( )
;
[then]

: seg-after-winv6?  ( -- done? )
   \ If segment ends after window, drop trailing data
   \ (and PUSH and FIN); if nothing left, just ACK.

   iseq ilen +   rcv_nxt rcv_wnd +  -      ( #todrop )
   dup 0<=  if  drop false exit  then      ( #todrop )

   dup ilen >=  if                         ( #todrop )
      \ If a new connection request is received
      \ while in TIME_WAIT, drop the old connection
      \ and start over if the sequence numbers
      \ are above the previous ones.  Otherwise, queue it
      \ for later processing.
      syn iflag?  if
         ts time_wait =  iseq rcv_nxt s>  and  if  ( #todrop )
            rcv_nxt issincr +  to iss
            tcp_close
            \ XXX we need to find some way to get back to findpcb:
            \ goto findpcb
            \ XXX this is moot since a new instance of this TCP
            \ package must be created in order to accept a new
            \ connection.
            drop  true exit
         else
            drop  false exit
         then
      then                                   ( #todrop )

      \ If window is closed can only take segments at
      \ window edge, and have to drop data and PUSH from
      \ incoming segments.  Continue processing, but
      \ remember to ack.  Otherwise, drop segment and ack.

      rcv_wnd 0=  iseq rcv_nxt =  and  if    ( #todrop )
         set-acknow
      else                                   ( #todrop )
         drop  dropafterackv6 true exit
      then                                   ( #todrop )
   then                                      ( #todrop )

   \ Drop the extra data from the end of the packet
   -ilen                                     ( )      
   th_push fin or  clear-iflag               ( )
   false
;

[ifndef] include-ipv4
: do-rst  ( -- )
   \ If the RST bit is set examine the state:
   \    SYN_RECEIVED STATE:
   \	If passive open, return to LISTEN state.
   \	If active open, inform user that connection was refused.
   \    ESTABLISHED, FIN_WAIT_1, FIN_WAIT2, CLOSE_WAIT STATES:
   \	Inform user that connection was reset, and close tcb.
   \    CLOSING, LAST_ACK, TIME_WAIT STATES
   \	Close the tcb.

   ts syn_received =  if  debug" Connection refused"  closed set-state  then

   ts established =
   ts fin_wait_1 =  or
   ts fin_wait_2 =  or
   ts close_wait =  or  if  debug" Connection reset"  closed set-state  then

   tcp_close
;
[then]

\ Discard from the buffer the transmitted data that was acked 
: release-datav6  ( -- flag )
   acked wbufv6-actual >  dup  if                ( flag )
      snd_wnd wbufv6-actual -  to snd_wnd        ( flag )
      wbufv6-actual wbufv6-drop                    ( flag )
   else                                        ( flag )
      acked wbufv6-drop                          ( flag )
      snd_wnd acked -  to snd_wnd              ( flag )
   then                                        ( flag )
;

: do-ackv6  ( -- done? )
   ts syn_received =  if
      \ In SYN_RECEIVED state if the ack ACKs our SYN then enter
      \ ESTABLISHED state and continue processing, otherwise
      \ send an RST.
      snd_una iack s>  iack snd_max s>  or  if
         dropwithresetv6 true  exit
      then
      established set-state
      present-data drop
      iseq 1-  to snd_wl1
   then

   \ In ESTABLISHED and subsequent states: drop duplicate ACKs; ACK out
   \ of range ACKs.  If the ack is in the range
   \	snd_una < iack <= snd_max
   \ then advance snd_una to iack and drop
   \ data from the retransmission queue.  If this ACK reflects
   \ more up to date window information we update our window information.

   iack snd_una s<=  if
      ilen 0=  iwin snd_wnd =  and  if
         \ If we have outstanding data (other than a window probe),
         \ this is a completely duplicate ack (i.e., window info didn't
         \ change), the ack is the biggest we've seen, and we've seen
         \ exactly our rexmt threshhold of them, assume a packet
         \ has been dropped and retransmit it.  Kludge snd_nxt & the
         \ congestion window so we send only this one packet.
         \
         \ We know we're losing at the current window size so do
         \ congestion avoidance (set ssthresh to half the current window
         \ and pull our congestion window back to the new ssthresh).
         \
         \ Dup acks mean that packets have left the network (they're now
         \ cached at the receiver) so bump cwnd by the amount in the receiver
         \ to keep a constant cwnd packets in the network.

         tcpt_rexmt @ 0=  iack snd_una <>  or  if
            0 to t_dupacks
         else  t_dupacks 1+ dup to t_dupacks  tcprexmtthresh =  if
            snd_nxt                                        ( onxt )
            snd_wnd snd_cwnd min  2/  t_maxseg /  2 umax   ( onxt win )
            t_maxseg u*  to snd_ssthresh                   ( onxt )
            tcpt_rexmt off                                 ( onxt )
            0 to t_rtt                                     ( onxt )
            iack set-snd_nxt                               ( onxt )
            t_maxseg set-cwnd                              ( onxt )
            tcp_outputv6                                   ( onxt )
            t_maxseg t_dupacks *  snd_ssthresh +  set-cwnd ( onxt )
            dup  snd_nxt s>  if  set-snd_nxt  else  drop  then  ( )
            true exit
         else  t_dupacks tcprexmtthresh >  if
            snd_cwnd t_maxseg +  set-cwnd
            tcp_outputv6
            true exit
         then then then
      else
         0 to t_dupacks
      then

      false exit
   then

   \ If the congestion window was inflated to account
   \ for the other side's cached packets, retract it.

   t_dupacks tcprexmtthresh >=
   snd_cwnd snd_ssthresh >  and  if  snd_ssthresh set-cwnd  then
   0 to t_dupacks

   iack snd_max s>  if  dropafterackv6 true exit  then

   iack snd_una -  to acked

   \ If transmit timer is running and timed sequence
   \ number was acked, update smoothed round trip time.
   \ Since we now have an rtt measurement, cancel the
   \ timer backoff (cf., Phil Karn's retransmit alg.).
   \ Recompute the initial retransmit timer.

   t_rtt 0<>  iack t_rtseq s>  and  if  t_rtt xmit_timer  then

   \ If all outstanding data is acked, stop retransmit
   \ timer and remember to restart (more output or persist).
   \ If there is more data to be acked, restart retransmit
   \ timer, using current (possibly backed-off) value.

   iack snd_max =  if
      tcpt_rexmt off
      1 to needoutput
   else
      tcpt_persist @ 0=  if  t_rxtcur  tcpt_rexmt !  then
   then

   \ When new data is acked, open the congestion window.   If the window
   \ gives us less than ssthresh packets in flight, open exponentially
   \ (maxseg per packet).   Otherwise open linearly: maxseg per window
   \ (maxseg^2 / cwnd per packet), plus a constant fraction of a packet
   \ (maxseg/8) to help larger windows open quickly enough.
   t_maxseg
   snd_cwnd snd_ssthresh u>  if  dup u*  snd_cwnd /  then  ( cwnd-increment )
   snd_cwnd +  maxwin min  set-cwnd
   
   release-datav6 to ourfinisacked?

   \ wakeup-sender

   ack-una

   ts case

      \ In FIN_WAIT_1 STATE in addition to the processing
      \ for the ESTABLISHED state if our FIN is now acknowledged
      \ then enter FIN_WAIT_2.

      fin_wait_1 of
         ourfinisacked?  if
            \ If we can't receive any more data, then closing user can proceed.
            \ Starting the timer is contrary to the specification, but if we
            \ don't get a FIN we'll hang forever.

            cantrcvmore?  if
               \ XXX false to soisconnected
               maxidle tcpt_2msl !
            then
            fin_wait_2 set-state
         then
      endof

      \ In CLOSING STATE in addition to the processing for
      \ the ESTABLISHED state if the ACK acknowledges our FIN
      \ then enter the TIME-WAIT state, otherwise ignore
      \ the segment.

      closing of
         ourfinisacked?  if
            time_wait set-state
            canceltimers
            tcptv_msl 2*  tcpt_2msl !
         then
      endof

      \ In LAST_ACK, we may still be waiting for data to drain
      \ and/or to be acked, as well as for the ack of our FIN.
      \ If our FIN is now acknowledged, delete the TCB,
      \ enter the closed state and return.

      last_ack of
         ourfinisacked?  if  tcp_close  true exit  then
      endof          

      \ In TIME_WAIT state the only thing that should arrive
      \ is a retransmission of the remote FIN.  Acknowledge
      \ it and restart the finack timer.

      time_wait of
         tcptv_msl 2* tcpt_2msl !
         dropafterackv6  true exit
      endof
   endcase
   false
;

[ifndef] include-ipv4
: optbyte  ( adr len -- adr' len' b )  1-  swap dup c@  swap 1+  -rot  ;
[then]

: dooptionsv6  ( adr len -- )
   begin  dup  while                         ( adr len )
      optbyte  case                          ( adr' len' option )
         0  of  2drop exit  endof            ( adr len option )  \ EOL
         1  of  0           endof            ( adr len option )  \ NOP
         2  of                               ( adr len )         \ MAXSEG
                optbyte 2-                   ( adr len optlen )
                iflags syn and  if           ( adr len optlen )
                   debug?  if  ." Received "  then
                   2 pick be-w@ tcp_mssv6 drop ( adr len optlen )
                then                         ( adr len optlen )
         endof
[ifdef] notdef
         3  of                               ( adr len )         \ WINDOW
                optbyte 2-                   ( adr len optlen )
                iflags syn and  if           ( adr len optlen )
                   rcvd_scale set-flag       ( adr len optlen )
                then                         ( adr len optlen )
         endof
[then]
         ( default )  >r  optbyte 2-  r>     ( adr len optlen option )
      endcase                                ( adr len optlen )
      /string                                ( adr' len' )
   repeat                                    ( adr len )
   2drop
;

: do-listenv6  ( -- )
   th_dport be-w@  my-tcp-port  <>  ?exit
   rst iflag?  ?exit
   ack iflag?  if  dropwithresetv6 exit  then
   syn iflag? 0=  ?exit

   \ XXX we also need to reject broadcast source addresses
\   m_flags  bcast mcast or  and   ?exit
   multicast-dstv6?  ?exit

   \ It is tempting to call "lock-ip-address", but that doesn't
   \ work if the DHCP server has specified a router.
   ipv6-struct  ihv6_src set-dest-ipv6  tcpv6-struct

   th_sport be-w@ to his-tcp-port	\ Lock onto his source port

   make-templatev6

   optp optlen dooptionsv6
   next-iss
   iseq to irs
   sendseqinit
   rcvseqinit
   set-acknow
   syn_received set-state
   keep_init tcpt_keep !
   trimthenstep6v6
;

[ifndef] include-ipv4
\ TCP SYN queue methods

list: tcplist
listnode
   /n field >tcp-adr
   /n field >tcp-len
   1  field >tcp-deq?
nodetype: tcpnode

0 tcplist !
0 tcpnode !

: free-tcpnode  ( prev -- )
   delete-after
   dup tcpnode free-node
   dup >tcp-adr @ swap >tcp-len free-mem
;

: tcp-deq?  ( node-adr -- tcp-deq? )  >tcp-deq? c@  ;

: purge-que  ( -- )
   tcplist ['] tcp-deq?  find-node  if  free-tcpnode  else  drop  then
;

: tcp-any?  ( node-adr -- true )  drop true  ;

: find-first-node  ( -- first-node )  tcplist ['] tcp-any?  find-node  nip  ;

: enque  ( adr len -- )
   dup alloc-mem swap 2dup 2>r move 2r>		( adr' len )
   tcpnode allocate-node			( adr len node )
   dup tcplist last-node insert-after		( adr len node )
   tuck >tcp-len !				( adr node )
   tuck >tcp-adr !				( node )
   0 swap >tcp-deq? c!				( )
;

\ Determines whether a node in the queue matches the packet that
\ is about to be enqued by comparing their pseudo-IP and TCP headers.
0 value test-adr
[then]

: duplicate-synv6?  ( node-adr -- flag )
   dup tcp-deq?  if  drop  false  exit  then    ( node-adr )
   >tcp-adr @   test-adr  /pipv6 /tcphdr +  comp 0=  ( flag )
;

\ Enque an incoming SYN packet unless it is a duplicate of one that
\ is already in the queue.
: ?enquev6  ( adr len -- )
   over to test-adr
   tcplist ['] duplicate-synv6? find-node nip  if  2drop  else  enque  then
;

: dequeue?  ( -- 0 | adr len true )
   purge-que
   find-first-node dup 0=  if  exit  then	\ nothing in queue

   						( node )
   true over >tcp-deq? c!			( node )
   dup >tcp-adr @ swap >tcp-len @ true		( adr len true )
;

: queue-synv6  ( -- )
   the-struct /pipv6 - ilen-save /pipv6 +  ?enquev6

   \ If the current connection has been declared to be abortable,
   \ kill it upon receipt of a new connection request.  This is
   \ a special hack that is used by the Swing Solutions application,
   \ which has some HTTP requests that do not complete until an
   \ external event occurs.  The requester can abort the request
   \ by dropping the TCP connection, but there are some cases where
   \ the TCP drop does not appear to be propagated to the responder.

   abort-on-reconnect?  if  tcp_drop  then
;

: inputv6  ( adr len -- )
   2dup sumv6-bad?  if
      show" TCHKSUM"
      debug" Bad TCP checksum" 2drop  exit
   then  ( adr len )
   dup to ilen-save to ilen  set-struct                           ( )
   0 to #oob

   pull-options  ?exit

   get-info

   debug?  if  ." RCV "  .pkt  then

\ findpcb:

   \ Here we should do something to ensure that the source port
   \ matches this one.  Perhaps that is handled by the IP layer.

   \ XXX If we get at TCP packet that doesn't match, we should do a
   \ dropwithreset and exit ...

   \ When we get a packet from a port other than the one we are currently
   \ talking to, we either queue it for later (if it contains a SYN),
   \ or discard it.
   his-tcp-port  th_sport be-w@  <>  if
      \ If we are waiting for an incoming connection, we just fall through
      \ and handle the new connection request farther down.
      ts listen <>  if
         \ If a SYN is in the window, then we queue it and handle it
         \ later, after the current transaction finishes.
         syn iflag?  if  queue-synv6  then
         exit
      then
   then

   alive? 0=  if  dropwithresetv6 exit  then
   ts closed =  ?exit

   0 to t_idle
   keepidle tcpt_keep !

   ts listen <>  if  optp optlen dooptionsv6  then

   fast-pathv6?  ?exit

   \ At this point, we have handled the most common cases;
   \ It gets complicated from here on out

   \ Calculate amount of space in receive window,
   \ and then do TCP input processing.
   \ Receive window is amount of space in rcv queue,
   \ but not less than advertised window.
   rcv_adv rcv_nxt -   rbuf-space  max  to rcv_wnd

   ts listen =  if  do-listenv6 exit  then

   do-syn-sentv6?  ?exit
   ?drop-some

   \ If data is received after closing, RST the other end
   ts close_wait >  ilen 0<> and  if  tcp_close dropwithresetv6  exit  then

   seg-after-winv6?  ?exit

   rst iflag?  if  do-rst exit  then

   \ If a SYN is in the window, then it is queued until the current
   \ transaction finishes cleanly.
   syn iflag?  if  queue-synv6  then

   \ If the ACK bit is off we drop the segment and return.
   ack iflag? 0=  ?exit

   \ ACK processing
   do-ackv6  ?exit
   step6v6
;

: ?receivev6  ( -- )
   \ If the state is listen, check the queue
   ts listen =  if
      dequeue?  if  ( adr len ) /pipv6 - swap /pipv6 + swap  input exit  then
   then    
   \ Check for a new packet
   6 " receive-ip-packet" $call-parent 0=  if  inputv6  then
;

[ifndef] include-ipv4
\ We accomplish the creation of a TCP control block by instantiating
\ this package
: newtcpcb  ( -- )  ;

\ d# 32 is the maximum TCP options size
/tcphdr d# 32 +  mssmax +  constant /xmit-max

: alloc-buffers  ( -- )
   d# 1024 d# 16 *  to rbuf-len
   rbuf-len alloc-mem to rbuf-adr
   0 to rbuf-actual
;
: free-buffers  ( -- )
   rbuf-adr rbuf-len free-mem
;
[then]

\ This is basically attach
: alloc-buffersv6  ( -- )
   wbufv6-allocate
   /xmit-max " allocate-ipv6" $call-parent  to xmit_bufv6
;

: free-buffersv6  ( -- )
   wbufv6-start /wbufv6 free-mem
   xmit_bufv6 /xmit-max " free-ipv6" $call-parent
;

[ifndef] include-ipv4
\ User issued close, and wish to trail through shutdown states:
\ if never received SYN, just forget it.  If got a SYN from peer,
\ but haven't sent FIN, then go to FIN_WAIT_1 state to send peer a FIN.
\ If already got a FIN from peer, then almost done; go to LAST_ACK
\ state.  In all other cases, have already sent FIN to peer (e.g.
\ after PRU_SHUTDOWN), and just have to play tedious game waiting
\ for peer to send FIN or not respond to keep-alives, etc.
\ We can let the user exit from the close as soon as the FIN is acked.
: usrclosed  ( -- )
   ts case          \ action     next-state
      closed       of  tcp_close              endof
      listen       of  tcp_close              endof
      syn_sent     of  tcp_close              endof
      syn_received of  fin_wait_1  set-state  endof
      established  of  fin_wait_1  set-state  endof
      close_wait   of  last_ack    set-state  endof
      ( default )  \ Do nothing
   endcase


   alive?  ts fin_wait_2 >=  and  if
      \ soisdisconnected

      \ If we are in FIN_WAIT_2, we arrived here because the
      \ application did a shutdown of the send side.  Like the
      \ case of a transition from FIN_WAIT_1 to FIN_WAIT_2 after
      \ a full close, we start a timer to make sure sockets are
      \ not left in FIN_WAIT_2 forever.
      ts fin_wait_2 =  if  maxidle tcpt_2msl !  then
   then
;

\ When a source quench is received, close congestion window
\ to one segment.  We will gradually open it again as we proceed.
\ XXX we probably have no way to invoke this.
\ : quench  ( -- )  alive?  if  t_maxseg set-cwnd  then  ;

\ Fast timeout routine for processing delayed acks
false instance value do-delack?
[then]

: do-delackv6  ( -- )
   do-delack?  if
      t_flags  delack invert and  acknow or  to t_flags
      tcp_outputv6
      false to do-delack?
   then
;

[ifndef] include-ipv4
: delack-tick  ( -- )  t_flags delack and 0<>  to do-delack?  ; \ alarm handler

\ 2 MSL timeout in shutdown went off.  If we're closed but
\ still waiting for peer to close and connection has been idle
\ too long, or if 2MSL time is up from TIME_WAIT, delete connection
\ control block.  Otherwise, check again in a bit.
: do-2msl  ( -- )
   debug?  if  ." 2msl" cr  then
   ts time_wait <>  t_idle maxidle <=  and  if
      keepintvl tcpt_2msl !
   else
      tcp_close
   then
;
[then]

\ Retransmission timer went off.  Message has not
\ been acked within retransmit interval.  Back off
\ to a longer retransmit interval and retransmit one segment.
: do-rexmtv6  ( -- )
   debug?  if  ." Retransmit" cr  then
   t_rxtshift 1+ dup to t_rxtshift  maxrxtshift >  if
      maxrxtshift to t_rxtshift
      tcp_drop
      exit
   then
   rexmtval  backoff t_rxtshift na+ @  *  t_rttmin  set-rxtcur
   t_rxtcur tcpt_rexmt !

[ifdef] notdef  \ We have no way to try for a better route

   \ If losing, let the lower level know and try for
   \ a better route.  Also, if we backed off this far,
   \ our srtt estimate is probably bogus.  Clobber it
   \ so we'll take the next rtt measurement as our srtt;
   \ move the current srtt into rttvar to keep the current
   \ retransmit times until then.

		if (t_rxtshift > TCP_MAXRXTSHIFT / 4) {
			in_losing(t_inpcb);
			t_rttvar += (t_srtt >> TCP_RTT_SHIFT);
			t_srtt = 0;
		}
[then]
   snd_una set-snd_nxt

   \ If timing a segment in this window, stop the timer.
   0 to t_rtt

   \ Close the congestion window down to one segment
   \ (we'll open it by one segment for each ack we get).
   \ Since we probably have a window's worth of unacked
   \ data accumulated, this "slow start" keeps us from
   \ dumping all that data as back-to-back packets (which
   \ might overwhelm an intermediate gateway).
   \
   \ There are two phases to the opening: Initially we
   \ open by one mss on each ack.  This makes the window
   \ size increase exponentially with time.  If the
   \ window is larger than the path can handle, this
   \ exponential growth results in dropped packet(s)
   \ almost immediately.  To get more time between 
   \ drops but still "push" the network to take advantage
   \ of improving conditions, we switch from exponential
   \ to linear window opening at some threshhold size.
   \ For a threshhold, we use half the current window
   \ size, truncated to a multiple of the mss.
   \
   \ (the minimum cwnd that will give us exponential
   \ growth is 2 mss.  We don't allow the threshhold
   \ to go below this.)

   snd_wnd snd_cwnd min  2/  t_maxseg /  2 max    ( win )
   t_maxseg set-cwnd                              ( win )
   t_maxseg *  to snd_ssthresh                    ( )
   0 to t_dupacks

   tcp_outputv6
;

\ Persistance timer into zero window.
\ Force a byte to be output, if possible.
: do-persistv6  ( -- )
   debug?  if  ." Persist" cr  then
   setpersist
   true to t_force
   tcp_outputv6
   false to t_force
;

[ifndef] include-ipv4
0 instance value keepalive?	\ A configuration flag we can set
[then]

\ Keep-alive timer went off; send something
\ or drop connection if idle for too long.
: do-keepv6  ( -- )
   debug?  if  ." Keep" cr  then
   ts established <  if  tcp_drop exit  then
   keepalive?  ts close_wait <=  and  if
      t_idle  keepidle maxidle +  >=  if  tcp_drop exit  then

      \ Send a packet designed to force a response if the peer is up
      \ and reachable: either an ACK if the connection is still alive,
      \ or an RST if the peer has closed the connection due to timeout or
      \ reboot.  Using sequence number snd_una-1 causes the transmitted
      \ zero-length segment to lie outside the receive window;  by the
      \ protocol spec, this requires the correspondent TCP to respond.

      tv6_template to the-struct  rcv_nxt  snd_una 1-  ack  respondv6
      keepintvl tcpt_keep !
   else
      keepidle tcpt_keep !
   then
;

[ifndef] include-ipv4
: countdown?  ( adr -- expired? )
   dup @  if                ( adr )
      dup @ 1-              ( adr count' )
      tuck swap !  0=
   else
      drop  false
   then
;

\ Tcp protocol timeout routine called every 500 ms.
\ Updates the timers, causing finite state machine actions when they expire.

0 instance value protocol-timer?
[then]

: do-protocolv6  ( -- )
   protocol-timer?  0=  ?exit
   false to protocol-timer?

   8  d# 75 *  pr_slowhz *  to maxidle  \ 8 probes at 75-second intervals

   tcpt_rexmt    countdown?  if  do-rexmtv6    then
   tcpt_persist  countdown?  if  do-persistv6  then
   tcpt_keep     countdown?  if  do-keepv6     then
   tcpt_2msl     countdown?  if  do-2msl       then

   t_idle 1+ to t_idle
   t_rtt  if  t_rtt 1+  to t_rtt  then
;

[ifndef] include-ipv4
: protocol-tick  ( -- )
   alive? to protocol-timer?

   \ XXX If we have multiple simultaneous TCPs, we only want to
   \ do this in one of them.  How?
   tcp_iss issincr pr_slowhz /  +  to tcp_iss
;
[then]

\ Initiate connection to peer.
\ Create a template for use in transmissions on this connection.
\ Enter SYN_SENT state, and mark socket as connecting.
\ Start keep-alive timer, and seed output sequence space.
\ Send initial segment on connection.

: start-connectv6  ( port# -- )
   to his-tcp-port
   \ XXX how do we get our local port number???
   
   make-templatev6
   syn_sent set-state
   keep_init tcpt_keep !
   next-iss
   sendseqinit
   tcp_outputv6
;

[ifndef] include-ipv4
\ After a receive, possibly send window update to peer.
\ XXX - we need to call output after taking the receive data
\ See: case PRU_RCVD

: tcp-abort  ( -- )  tcp_drop  ;

\ Get the out-of-band data without consuming it
: peek-oob  ( adr len -- actual )
   \ XXX check this; there may be some data waiting during a later state
   ts established <>  if  2drop -1 exit  then

   t_oobflags havedata and  0=  if  2drop -2 exit  then
   0=  if  drop 0 exit  then
   t_iobc swap c! 1
;

\ Get the out-of-band data
: read-oob  ( adr len -- actual )
   peek-oob   ( actual )
   dup 0>  if
      t_oobflags  havedata haddata or  xor  to t_oobflags
   then
;
[then]

: pollv6  ( -- )
   do-delackv6  do-protocolv6
   ?receivev6
;

: wbufv6-set  ( adr len -- )  over to wbufv6-adr  + to wbufv6-top  ;
: wbufv6-add  ( adr len -- #added )
   wbufv6-avail min                    ( adr #added )
   dup  if                           ( adr #added )
      tuck  wbufv6-top swap move       ( #added )
      dup wbufv6-top +  to wbufv6-top    ( #added )
   else                              ( adr 0 )
      nip                            ( 0 )
   then                              ( #added )
;

[ifndef] include-ipv4
: read       ( adr len -- actual )  2drop 0  ;
: write      ( adr len -- actual )  2drop 0  ;
: write-oob  ( adr len -- actual )  2drop 0  ;
: connect    ( port# -- okay? )  drop false  ;
[then]

: writev6  ( adr len -- actual )
   tuck  begin                   ( len adr remaining )
      alive? 0=  if  3drop -1 exit  then
      2dup wbufv6-add /string      ( len adr' remaining' )
   dup  while                    ( len adr' remaining' )
      tcp_outputv6  pollv6       ( len adr' remaining' )
   repeat                        ( len adr 0 )
   2drop                         ( len )
;

: write  ( adr len -- actual )
   use-ipv6?  if  writev6  else  write  then
;

\ Do a send by putting data in output queue and updating urgent
\ marker if URG set.  Possibly send more data.
: write-oobv6  ( adr len -- actual )
   \ According to RFC961 (Assigned Protocols), the urgent pointer points
   \ to the last octet of urgent data.  BSD makes it point to the
   \ the first octet of data past the urgent section.  We follow the RFC.
   dup 0=  if  nip exit  then
   dup snd_una + 1- to snd_up          ( adr len )
   true to t_force                     ( adr len )
   writev6                             ( len|-1 )
   false to t_force                    ( len|-1 )
;
: write-oob  ( adr len -- actual )
   use-ipv6?  if  write-oobv6  else  write-oob  then
;

: connectv6  ( port# -- okay? )
   true to alive?
   start-connectv6
   begin  pollv6  ts established <  while
      debug?  if key? if key drop interact then  then
      alive? 0=  if  false exit  then
   repeat
   true
;
: connect  ( port# -- okay? )
   " use-ipv6?" $call-parent dup to use-ipv6?
   if  connectv6  else  connect  then
;

\ Other things we may need to do:
\ in_setsockaddr
\ in_setpeeraddr

: readv6  ( adr len -- actual )
   pollv6                                 ( adr len )

   rbuf-actual  if                        ( adr len )
      copy-from-rbuf tcp_outputv6  exit   ( actual )
   then                                   ( adr len )

   2drop
   ts established <>  if  -1  else  -2  tcp_outputv6  then
;
: read  ( adr len -- actual )
   use-ipv6?  if  readv6  else  read  then
;

[ifndef] include-ipv4
: init-variables  ( -- )
   0 tcpq !
   listen set-state
   0 to t_flags
   d# 512 to t_maxseg
   canceltimers
   0 to t_dupacks
   0 to t_force
   0 to rcv_wnd
   0 to rcv_nxt
   0 to rcv_up
   0 to irs

   0 to snd_una
   0 to snd_nxt
   0 to snd_up
   0 to snd_wl1
   0 to snd_wl2
   0 to snd_wnd
   0 to iss

   0 to rcv_adv
   0 to snd_max
   maxwin to snd_cwnd
   maxwin to snd_ssthresh

   0 to t_idle
   0 to t_rtt
   0 to t_rtseq
   0 to t_srtt
   3 pr_slowhz *   2 2+ 1- lshift to t_rttvar
   pr_slowhz to t_rttmin
   0 to max_sndwnd

   0 to t_oobflags
   0 to t_iobc

   0 to t_rxtshift
   rexmtval pr_slowhz set-rxtcur

   false to do-delack?
   false to keepalive?
   false to protocol-timer?
;
: accept  ( port# -- connected? )  drop false  ;
[then]

: acceptv6  ( port# -- connected? )
   to my-tcp-port
   ts closed =  if
      init-variables
      \ Tell the IP stack to accept packets from anybody
      " unlock-ipv6-address" $call-parent
   then
   true to alive?
   pollv6
   \ XXX if state is now "closed", we need to return an error code
   ts established =
;
: accept  ( port# -- connected? )
   use-ipv6?  if  acceptv6  else  accept  then
;

[ifndef] include-ipv4
: parse-args  ( -- )
   my-args
   begin  dup  while                                   ( rem$ )
      ascii , left-parse-string                        ( rem$' head$ )
      2dup " debug" $=  if  true to debug?  else       ( rem$' head$ )
      2dup $set-host                        then       ( rem$' head$ )
      2drop
   repeat
   2drop
;
[then]

: open  ( -- )
   alloc-buffersv6
   parse-args
   alloc-buffers

   first-time?  if
      false to first-time?
      " next-xid" $call-parent to tcp_iss
   then

   0 " set-timeout" $call-parent

   ['] delack-tick    d# 200  alarm

   ['] protocol-tick  d# 500  alarm

   alloc-next-tcp-local-port to my-tcp-port
   true to alive?

   true
;

[ifndef] include-ipv4
d# 5000 constant close-wait-ms
: drain  ( -- )  ;
: flush-writes  ( -- )  ;
[then]

: drainv6  ( -- )
   get-msecs close-wait-ms +                 ( msecs )
   begin  ts time_wait <  alive? and  while  ( msecs )
      pollv6                                 ( msecs )
      get-msecs over - 0>=  if  drop exit  then
   repeat                                    ( msecs )
   drop
;

: flush-writesv6  ( -- )
   \ If the connection is already down, just blow away any pending data
   ts closed  =  if  wbufv6-clear exit  then

   get-msecs
   begin  
      wbufv6-actual 0<>			( start-time flag )
      get-msecs 2 pick - d# 10000 <	( start-time flag flag )
      and 				( start-time flag' )
   while                		( start-time )
      tcp_outputv6 pollv6               ( start-time )
   repeat				( start-time )
   drop					( )

   wbufv6-actual 0<>  if
      show" TDROP"
      debug" TCP Timeout!"
      wbufv6-clear
   then
;

\ Close the current TCP connection and wait for the state machine
\ to make its way through the sequence of termination states.
: disconnectv6  ( -- )
   usrclosed
   flush-writesv6
   alive?  if  tcp_outputv6  then
   drainv6
   alive?  if  tcp_close   then
;

[ifndef] include-ipv4
\ external
: set-nodelay  ( -- )  nodelay set-flag  ;
: abort-on-reconnect  ( -- )  true to abort-on-reconnect?  ;
: disconnect  ( -- )  ;
[then]

: close  ( -- )
   use-ipv6?  if  disconnectv6  else  disconnect  then
   ['] delack-tick    0  alarm
   ['] protocol-tick  0  alarm
   free-buffers
   free-buffersv6
;

\ LICENSE_BEGIN
\ Copyright (c) 2006 FirmWorks
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
