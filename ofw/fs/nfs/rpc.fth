\ See license at end of file
purpose: Sun RPC (Remote Procedure Call) primitives

false value debug?
headerless
\ msg-type(0=call, 1=reply)
: rpc-send-call  (  -- ?? )

;

\ message:
\  xid, 0:call_body | 1:reply_body)
\ call_body: rpcvers, prog, vers, proc, (auth)cred, (auth)verf, ...
\ reply_body:
\ reply-stat(0=accepted,1=denied),
\    [0:verifier, accept-stat(0=success, 1=program-unavailable, 2=mismatch,
\                   3=procedure-unavailable, 4=bad-args)]
\        [0:...]
\        [2:low,high]
\        [else:<void>]
\    [1:reject-stat(0=version-mismatch, 1=authentication-error)]
\        [0:low,high]
\        [1:auth-stat(1=bad-credentials, 2=rejected-credential,
\                     3=bad-verifier, 4=rejected-verifier, 5=too-weak)]
\ auth(0=null,1=unix,2=short,3=des)
\    [0:<void>]
\    [1:stamp, (string255)machinename, uid, gid, (ints16)gids]
\	{call-verifier is auth_null, reply-verifier is auth_null or auth_short}
\    [2:(opaque)stuff]
\    [3:<later>]
: rpc-get-reply
   
;

\ portmapper:  Fixed Port#111, prog# 100000
\ portmapper-mapping: prog#, vers#, protocol(6=tcp,17=udp), port#
\   [0:<end-of-list>|1:mapping, ...]

\ To call the portmapper:
\ 
\ ethernet/ip/udp(111)/rpc-call
\ 		     d#100000, 2, 0(noop), auth-null, auth-null
\ 
\ 	udp src port ???
: auth-null  ( -- )  0 +xu  0 +xu  ;
defer stamp  ' 0 to stamp
defer machine-name  ' null$ to machine-name
0 instance value uid
0 instance value gid
0 instance value gids-adr
0 instance value gids-len
: auth-unix  ( -- )
   1 +xu

   \ Length of opaque authorizer
   machine-name nip 4 round-up  gids-len /n / la+  5 la+ +xu

   stamp +xu  machine-name +x$  uid +xu  gid +xu
   gids-adr  gids-len dup /n / +xu  bounds  ?do  i @ +xu  /n +loop
;

0 0 2value short-credential
: auth-short  ( -- )  2 +xu  short-credential +x$  ;

: debug-type  ( adr len -- )  debug?  if  type cr  else  2drop  then  ;

6 /l* ( xid, msg-type, rpcvers, prog, vers, proc )
d# 408 2* +  ( credintials, verfifier )
constant /rpc-header

0 instance value rpc-xid
0 instance value rpc-port#
0 instance value rpc-sid
0 instance value rpc-buf
defer unexpected-rpc  ' 2drop to unexpected-rpc
defer unexpected-xid  ' noop  to unexpected-xid
: .bad-xid  ( -- )  " Wrong transaction ID" debug-type  ;
' .bad-xid to unexpected-xid

: .rpc-reject  ( -- )
   -xu  if  \ Authorization problem
      -xu case
         1 of  " Bad credentials"        debug-type  endof

         \ Client must restart session
         2 of  " Rejected credentials"   debug-type  endof

         3 of  " Bad verifier"           debug-type  endof
         4 of  " Rejected verifier"      debug-type  endof  \ Verifier expired
         5 of  " Authorization too weak" debug-type  endof
      endcase
   else     \ Version mismatch
      debug?  if
         ." Version mismatch: low "  -xu .d  ." high " -xu .d  cr
      then
   then
;
: .rpc-accept  ( error# -- )
   case
      0 of  exit  endof		\ Success
      1 of  " Program unavailable"   debug-type  endof
      2 of  debug?  if
               ." Version mismatch: low "  -xu .d  ." high " -xu .d  cr
            then
      endof
      3 of  " Procedure unavailable" debug-type  endof
      4 of  " Invalid arguments"     debug-type  endof
      4 of  " System error"          debug-type  endof
      ( default )
         debug?  if  ." Bogus accept-status value " dup .d cr  then
   endcase
;

: (handle-rpc-call)  " Oops - received an RPC call!" debug-type  ;
defer handle-rpc-call  ' (handle-rpc-call) to handle-rpc-call

: decode-verifier  ( -- error? )
   \ We just ignore the verifier for now; drop the type and opaque buffer
   -xu drop  -x$ 2drop  false
;
: receive-rpc-reply  ( xid his-port# my-port# -- false | error? true )
   begin
      begin
         \ Filter out other destination ports
         dup  " receive-udp-packet" $call-parent  if  ( xid his mine )
            " Timeout waiting for RPC reply" debug-type
            3drop false exit
         then                           ( xid his mine adr len actual-port# )
      \ Filter out other source ports
      4 pick <>  while                  ( xid his mine adr len )
         2drop                          ( xid his mine )
      repeat                            ( xid his mine adr len )

      start-decode                      ( xid his mine )

      \ Filter out other transaction IDs
      2 pick  -xu  <>  if               ( xid his mine )
         unexpected-xid  false          ( xid his mine flag )
      else                              ( xid his mine )
         \ Filter out RPC calls
         -xu  1 <>  if                  ( xid his mine )
            handle-rpc-call  false      ( xid his mine false )
         else                           ( xid his mine )
            true                        ( xid his mine true )
         then                           ( xid his mine done? )
      then                              ( xid his mine done? )
   until                                ( xid his mine )

   3drop                                ( )

   \ Check accept/denied flag
   -xu  if  .rpc-reject  true true exit  then

   \ Check verifier
   decode-verifier  if  " Incorrect verifier" debug-type  true true exit  then

   -xu  ?dup  if  .rpc-accept true true exit  then
   false true
;

0 instance value /rpc-buffer
\ The port # must be < 1024 so that mount will work.  We need to mount root
\ partitions, and the NFS server only lets "trusted" ports (<1024) mount
\ things as root.
d# 1022 instance value fw-port#

: alloc-rpc  ( extra-size -- )
   /rpc-header + to /rpc-buffer

   " next-xid" $call-parent  to rpc-xid
   fw-port# to rpc-sid

   /rpc-buffer " allocate-udp" $call-parent to rpc-buf

   rpc-buf  start-encode
;
: do-rpc  ( -- error? )
   x$  begin                                          ( adr len )
      " update-timeout" $call-parent                  ( adr len )
      2dup  rpc-sid  rpc-port#  " send-udp-packet" $call-parent  ( adr len )
      rpc-xid rpc-port# rpc-sid receive-rpc-reply     ( adr len [e] flag )
   until                                              ( adr len error? )
   nip nip                                            ( error? )
   " compute-srtt" $call-parent                       ( error? )
   rpc-buf /rpc-buffer " free-udp" $call-parent       ( error? )
;
headers
: ping-program  ( program# version# port# -- )
   0 alloc-rpc

   ( prog# ver# port# )
   to rpc-port#

   \       xid   call  RPCv2  program#  version#   noop
   rpc-xid +xu  0 +xu  2 +xu  swap +xu       +xu  0 +xu
   auth-null auth-null

   do-rpc  0=  if  ." The program responded" cr  then
;
: map-port  ( program# version# -- true | port# false )
   4 /n*  alloc-rpc

   ( prog# ver# )
   d# 111 to rpc-port#

   \       xid   call  RPCv2  program#        version#   PMAPPROC_GETPORT
   rpc-xid +xu  0 +xu  2 +xu  d# 100000 +xu   2 +xu      3 +xu
   auth-null auth-null

   \ prog#   ver#      UDP     port#
   swap +xu   +xu   d# 17 +xu  0 +xu

   do-rpc  if  true  else  -xu false  then
;

: ping-portmapper  ( -- )  d# 100000 2  d# 111  ping-program  ;
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
