purpose: iSCSI packets
\ See license at end of file

hex

: send-cmd   ( -- )
    send-pdu
    get-response
;

: init-login  ( -- )
   h# 43 init-pdu  
   !isid
   stage  flags!  
;
: init-text  ( -- )
    h# 04 init-pdu
    h# 80  flags!
    -1 to ttt  !ttt
;

: login-d   ( -- )
    set-iname
    1 to cmdsn
    0 to expstatsn
    0 to itt
    random to isid
    !isid
    init-login
    " InitiatorName" append-key
    " InitiatorAlias" append-key
    " SessionType=Discovery" append0
    " AuthMethod=CHAP,None" append0
    send-cmd
;
: login-n   ( -- )
    0 to cmdsn
    0 to expstatsn
    ++isid
    init-login
    h# 000a0000 to itt   !itt
    " InitiatorName" append-key
    " InitiatorAlias" append-key
    " TargetName" append-key
    " SessionType=Normal" append0
    " AuthMethod=CHAP,None" append0
    send-cmd
;
: login-dp   ( -- )
    h# 87 to stage
    init-login
    " HeaderDigest=None" append0
    " DataDigest=None" append0
\    " DefaultTime2Wait" append-key
\    " DefaultTime2Retain" append-key
    " IFMarker" append-key
    " OFMarker" append-key
    " ErrorRecoveryLevel" append-key
    " MaxRecvDataSegmentLength=32768" append0
    send-cmd
;
: login-np   ( -- )
    h# 87 to stage
    init-login
    !itt
    " HeaderDigest=None" append0
    " DataDigest=None" append0
\    " DefaultTime2Wait" append-key
\    " DefaultTime2Retain" append-key
    " IFMarker" append-key
    " OFMarker" append-key
    " ErrorRecoveryLevel" append-key
    " InitialR2T" append-key
    " ImmediateData" append-key
    " MaxBurstLength" append-key
    " FirstBurstLength" append-key
    " MaxOutstandingR2T" append-key
    " MaxConnections" append-key
    " DataPDUInOrder" append-key
    " DataSequenceInOrder" append-key
    " MaxRecvDataSegmentLength" append-key
    send-cmd
;
: login-st   ( -- )
    init-text
    ++itt
    " SendTargets=All" append0
    send-cmd
;
: login-none   ( -- )
    flags@ h# 81 = if  exit  then
    
    h# 81 to stage
    init-login
    !itt
    send-cmd
;
: login-chapa   ( -- )
    0 to stage
    init-login
    !itt
    " CHAP_A=5" append0
    send-cmd
;

\ use this version for production systems
: get-user   ( -- )
   " iscsi-user" $getenv if  0 0  then
   " CHAP_N" set-text
   " iscsi-password" $getenv if  0 0  then
   " CHAP_S" set-text
;

: calculate-chap-response   ( -- )
    " CHAP_I" get-addr 1	( $I )
    " CHAP_S" get-text		( $I $N )
    " CHAP_C" get-hex  		( $I $N $C )
    $cat3
    $md5digest1 		( $R )
    " CHAP_R" put-hex
;

: login-chapn   ( -- )
    h# 81 to stage
    init-login
    get-user
    calculate-chap-response
    " CHAP_N" append-key
    " CHAP_R" append-key
    send-cmd
;
: logout   ( -- )
    h# 46 init-pdu
    h# 80 flags!
    !itt
    send-cmd
;

: (nop-out)   ( -- )
    h# 40 init-pdu
    !ttt
    -1 outbuf >ITT be-l!
    send-cmd
;
' (nop-out) is nop-out

: auth-login   ( -- )
   " AuthMethod" get-text " CHAP" $= if
      login-chapa
      login-chapn
   else
      login-none
   then
;

d# 1000 value outtime
: delay   ( -- )
   debug?  if  ." delaying " outtime d# 1000 / .d ." seconds " cr  then
   outtime ms
;
: verify-target   ( -- )
   " TargetName" get-text nip 0= abort" No target devices found"
;
: login-discovery   ( -- )
   default-keys
   h# 81 to stage
   login-d
   auth-login
   login-dp
   login-st
   logout
   disconnect
   verify-target
   delay
;
: login-normal   ( -- )
   use_port connect 0= abort" reconnect failed"
   h# 81 to stage
   login-n
   auth-login
   login-np
;

: login   ( -- )
   login-discovery
   login-normal
;

\
\ SCSI commands
\

\ statbyte values come asynchronously in the response packet
: result   ( -- hwresult | statbyte 0 )
   status-valid?  if
      status
      debug?  if  dup if  ." statbyte is " dup .h cr  then  then
      false
   else
      debug?  if  ." no status" cr  then
      true
   then
;
: nodata-cmd   ( -- hwresult | statbyte 0 )
   h# 80 flags!
   send-cmd
   result
;
: write-cmd   ( data-adr,len  -- hwresult | statbyte 0 )
   h# a0 flags!
   dup outbuf >ExpDataLen be-l!
   send-pdu+data
   get-response
   result
;
: read-cmd   ( data-adr,len  -- hwresult | statbyte 0 )
   to read-length
   to read-address
   h# c0 flags!
   read-length outbuf >ExpDataLen be-l!
   send-cmd	
   result
;
: execute-command  ( data-adr,len dir cmd-adr,len -- hwresult | statbyte 0 )
   dup d# 16 >  if  ." CDB is too large"  -1 exit  then

   h# 01 init-pdu	\ make it non-immediate
   ++itt 		\ and change itt
   outbuf >CDB swap move		( data-adr,len dir )
   !lun 	     			\ set LUN
   over outbuf >ExpDataLen be-l!
   over  if			( data-adr,len dir )	\ moving data
      if  read-cmd  else  write-cmd  then
   else
      3drop  nodata-cmd
   then
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
