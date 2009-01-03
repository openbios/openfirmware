purpose: iSCSI buffers
\ See license at end of file

hex

\ structures for iscsi Protocol Data Units
\ formats vary with request or response

struct \ iscsi Basic Header Segment
  \ 0
  1 field >opcode
  1 field >flags
  1 field >response
  1 field >status
  \ 4
  1 field >AHSlen
  3 field >DSlen
  \ 8
  0 field >LUN
  6 field >ISID
  2 field >TSIH
  \ 16
  4 field >ITT
  \ 20
  0 field >SNACK
  0 field >ExpDataLen
  0 field >CID
  0 field >RTT
  4 field >TTT
  \ 24
  0 field >CmdSN
  4 field >StatSN
  \ 28
  0 field >ExpCmdSN
  4 field >ExpStatSN
  \ 32
  0 field >CDB
  0 field >RefCmdSN
  4 field >MaxCmdSN
  \ 36
  0 field >Async
  0 field >LoginStat
  0 field >R2TSN
  0 field >ExpDataSN
  4 field >DataSN
  \ 40
  0 field >BRRC
  0 field >Waittime
  0 field >BegRun
  4 field >BufferOffset
  \ 44
  0 field >RunLen
  0 field >DDTlen
  4 field >RC
  \ 48 
  0 field >Data
constant /bhs

    
\ buffers for iscsi messages

\ large data will be sent directly from the source address
d# 1024 constant /max-pdu
/max-pdu buffer: outbuf  

\ all incoming data goes to inbuf, so it must be large
h# 4.0000 constant /max-transfer
/max-transfer /bhs + buffer: inbuf 


0 value stage	( T C CSG NSG )
: flags@   ( -- flags )   inbuf  >flags c@  ;
: flags!   ( flags -- )   outbuf >flags c!  ;

0 [if]
: update-stage   ( -- )
   flags@ h# 80 and 0= if  exit  then
   \ transition
   flags@ 3 and 1 =  if
      h# 87 to stage
   then
;
[then]

0 value dslen

: !dslen   ( -- )
   dslen lwsplit    ( lo hi )
   outbuf >DSlen tuck  c!  1+ be-w!
;
: @dslen   ( -- dslen )
   inbuf >AHSlen be-l@ h# 00ff.ffff and
;


\ get and set some fields

\ XXX verify that this is the value that Solaris uses
h# 4000.002A value isidh
0 value isid
: !isid  ( -- )   
   outbuf >ISID  isidh over be-l!  isid swap 4 + be-w!
;
: ++isid   ( -- )   isid 1+ to isid  !isid  ;

0 value itt
0 value ttt
0 value cmdsn
0 value expstatsn
2variable lun

: @ttt   ( -- )   inbuf >TTT be-l@ to ttt ;
: !ttt   ( -- )   ttt outbuf >TTT be-l!  ;
: !itt   ( -- )   itt outbuf >ITT be-l!  ;
: ++itt   ( -- )   itt 1+ to itt  !itt  ;
: !lun   ( -- )   
   lun 2@  outbuf >LUN be-l! 
   outbuf >LUN 4 + be-l!
;
: @lun   ( -- )   
    inbuf >LUN 4 + be-l@
    inbuf >LUN be-l@
    lun 2!
;
: .lun   ( -- )   lun 2@ 8u.h ." ." 8u.h space ;

: set-sn       ( -- )   
   cmdsn      outbuf >CmdSN      be-l!
   expstatsn  outbuf >ExpStatSN  be-l!  
;

\ false value target-ready?
: update-sn       ( -- )   
   inbuf >ExpCmdSN be-l@ to cmdsn
   inbuf >StatSN be-l@ 1+ to expstatsn

   \ XXX use target-ready?, do nops if false
   \    inbuf >maxcmdsn be-l@ cmdsn 1- <> to target-ready?
;

: init-pdu  ( opcode -- )
   0 inbuf c!
   outbuf /max-pdu erase
   outbuf >opcode c!
   set-sn
   0 to dslen   !dslen
;

: read-more   ( adr len -- actual )
   wait-read dup 0< abort" read failed"	( sum actual )
;
: read-all   ( adr total -- )
   dup 0=  if  2drop exit  then
    
   over +  ( adr end )  >r  ( adr )
   begin  dup r@ <  while
      dup r@ over - ( adr adr len ) read-more	( adr actual ) +
   repeat
   r> 2drop
;

defer get-pdu  ( -- actual )
: (get-pdu)  ( -- actual )
   inbuf /max-pdu erase	\ helps debugging
   inbuf /bhs read-all		\ get the header
   inbuf >data @dslen tuck 4 round-up read-all ( actual' )
   /bhs + 			( actual )
   update-sn
;
' (get-pdu) to get-pdu

defer send-pdu   ( -- )
: (send-pdu)   ( -- )
   !dslen
   outbuf /bhs dslen + 4 round-up tcp-write
   " flush-writes" $call-parent
;
' (send-pdu) to send-pdu

\ send large data as if contiguous with BHS
defer send-pdu+data   ( a n -- )
: (send-pdu+data)   ( a n -- )
   dup to dslen  !dslen
   outbuf /bhs tcp-write	( a n )
   4 round-up tcp-write
   " flush-writes" $call-parent
;
' (send-pdu+data) to send-pdu+data

\ append strings to the data segment
: addnull  ( -- )
   /bhs dslen + 1+ /max-pdu > abort" Data Segment overrun"

   0  outbuf >Data dslen + c!	\ append a null
   dslen 1+ to dslen
;
: append  ( a n -- )
   dup /bhs + dslen + /max-pdu > abort" Data Segment overrun"

   >r  outbuf >Data dslen + r@ cmove
   r> dslen + to dslen
;
: append0  ( a n -- )
   dup /bhs + dslen + 1+ /max-pdu > abort" Data Segment overrun"

   >r  outbuf >Data dslen + r@ cmove
   0  outbuf >Data dslen + r@ + c!	\ append a null
   r> dslen + 1+ to dslen
;

\ LICENSE_BEGIN
\ Copyright (c) 2009 FirmWorks
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
