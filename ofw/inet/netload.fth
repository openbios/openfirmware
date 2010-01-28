\ See license at end of file
purpose: Network loading using TFTP.

\ Network loading using TFTP.  Loads either a named file using the "dload"
\ command, or the default tftpboot file whose name is constructed from
\ the Internet address (derived from the Ethernet address with RARP)
\ and the CPU architecture type.

headerless
: ?ip-error  ( flag -- )  abort" Invalid number in IP address"  ;
: decimal-byte  ( adr,len -- n )
   push-decimal  ['] safe->number catch  pop-base   ( n 0 | x x error )
   ?ip-error                                        ( n )
   dup d# 255 u> ?ip-error                          ( n )
;

\ Parse the text string "ip-str" as a decimal IP address (e.g. 129.144.12.4),
\ storing it as binary bytes at "buf"
: $ip#  ( ip-str buf -- )
   dup /i erase                  ( ip-str buf )
   /i bounds  do                 ( ip-str )
      ascii . left-parse-string  ( r-str l-str )
      decimal-byte i c!          ( r-str )
   loop                          ( r-str )
   2drop
;

: show-router-addr  ( -- )
   bootnet-debug  if  ." Router IP: = " router-ip-addr .ipaddr  cr  then 
; 

: show-all-en-ip-address  (  --  ) 
   bootnet-debug  if
      ." Using addresses: " cr
      indent .my-link-addr  .my-ip-addr  cr
      indent .his-link-addr .his-ip-addr cr
      use-router?  if  indent show-router-addr  then
   then
; 

d# 32 buffer: tmpname

partial-headers
\ Construct the file name for the second-stage boot program from
\ the IP address and the architecture.
: boot-filename  ( -- adr len )
   file-name-buf cscount dup  if  exit  then   ( adr len )
   2drop
   push-hex
   my-ip-addr be-l@  (.8)  2dup upper  ( adr len )
   pop-base
   tmpname place
   cpu-arch dup  if  " ."  tmpname $cat  tmpname $cat  else  2drop  then
   tmpname count file-name-buf place-cstr  drop
   file-name-buf  cscount
;

headerless
: parse-field  ( adr len -- rem-adr,len first-adr,len )
   ascii , left-parse-string
;
: un-field  ( rem$ field$ -- rem$' )  drop -rot  + over -  ;
: next-field  ( adr len -- rem-adr,len first-adr,len true | rem-adr,len false )
   dup 0=  if  false exit  then
   parse-field  dup  if  true  else  2drop false  then
;
: get-into-tftp-buf  ( adr len -- ) 
   file-name-buf place-cstr       ( cstr )
   \ process file-name to be passed onto tftpread
   cscount bounds ?do
      i c@ ascii | =  i c@ ascii \ =  or if  ascii / i c!  then
   loop
; 

: .t/f  ( n -- )  if  ." true "  else  ." false "  then  ;

headers

true instance value use-bootp?
false instance value use-last?
false instance value use-nfs?

headerless

: s-all ( -- )		\ see ip-addr/bootp info.
   bootnet-debug  if 
      ." Initial configuration: "
      use-last?  if
         ." Using the previous configuration" cr
         exit
      then
      use-bootp?  if
         ." Use DHCP/BOOTP to get configuration" cr
      else
         cr
         my-ip-addr known?  if
            indent ." My IP address: " my-ip-addr .ipaddr cr
         else
            indent ." Use RARP to get my IP address" cr
         then
         use-server?  if
            indent ." Boot server: " server-ip-addr .ipaddr cr
         then
         use-router?  if
            indent ." Router: " router-ip-addr .ipaddr cr
         then
      then
      file-name-buf c@  if
         indent ." Boot filename: " file-name-buf cscount type cr
      then
   then 
;

\ When router ip addr is supplied, server's ip addr 
\ must also be supplied by user. So confirm "server" is non-broadcast?
: init-router  ( -- ) 
;

: init-ip-addr  ( -- ) 
   unknown-ip-addr  server-ip-addr    copy-ip-addr
   unknown-ip-addr  router-ip-addr    copy-ip-addr
   def-broadcast-ip broadcast-ip-addr copy-ip-addr
   0 file-name-buf c!  0 server-name c!  0 bootp-name-buf c!
   clear-net-addresses
;

\ handle diskless/client's ip address 
: get-client-ip  ( rem-str -- rem'-str )
   next-field  if     ( rem-str my-ip# )
      \ move user supplied client ip addr in my-ip-addr
      my-ip-addr $ip#  ( rem-str )
      false to use-bootp?
   then               ( rem-str )
;
: get-router-ip  ( rem-str -- rem'-str )
   next-field  if          ( rem-str router-ip# )
      router-ip-addr $ip#  ( rem-str )
      use-router?  if
         use-server? 0=  if 
            collect(
." obp-tftp argument error:" cr
." If the router is specified, the server must also be specified." cr  
." e.g. boot net:<server-ipaddr>,<file>,<client-ipaddr>,<router-ipaddr>" cr
            )collect $abort
         then 
      then 
   then
;

: get-number  ( rem-str -- rem'-str n )
   next-field  if                ( rem-str field$ )
      push-decimal
      $number  if                ( rem-str )
         ." Bad number in network arguments" cr
         ." Network argument syntax:" cr
." server-ip,filename,client-ip,router-ip,#bootp-retries,#tftp-retries" cr
         \ Discard the rest of the arguments because we're probably
         \ out of sync.
         drop 0                  ( rem-str' )
         -1                      ( rem-str' n )
      then                       ( rem-str' n )
      pop-base                   ( rem-str' n )
   else                          ( rem-str )
      -1                         ( rem-str' n )
   then                          ( rem-str'  n )
;

: get-bootp-retries  ( rem-str -- rem'-str )  get-number to bootp-retries  ;
: get-tftp-retries  ( rem-str -- rem'-str )  get-number to tftp-retries  ;

\ The NVRAM variable boot-file's value is passed to first level booter.
\ It is not the file prom boots first. The name of first level boot file
\ comes from either command lin, or as a part of "devalias net" or 
\ as part of NVRAM variable boot-device.
: get-boot-filename  ( rem-str -- rem'-str )
   next-field  if                   ( rem-str file-name-str )
   \ getting file name from command line
       get-into-tftp-buf 
   then
;

: get-server-ip  ( rem$ -- rem$' )
   next-field  if                                    ( rem$ field$ )
      2dup server-ip-addr ['] $ip# catch  if         ( rem$ field$ x x x )
         3drop un-field                              ( rem$ )
         \ Erase possible partial IP address
         unknown-ip-addr server-ip-addr copy-ip-addr ( rem$ )
      else                                           ( rem$ field$ )
         2drop                                       ( rem$ )
      then                                           ( rem$ )
   then                                              ( rem$ )
;

: tftp-args  ( rem$ -- )
   get-server-ip       ( rem$ )
   get-boot-filename   ( rem$' )
   get-client-ip       ( rem$' )
   get-router-ip       ( rem$' )
   get-bootp-retries   ( rem$' )
   get-tftp-retries    ( rem$' )
   2drop

   \ If we got our IP address, we don't need BOOTP
   my-ip-addr known?  if  false to use-bootp?  then
;

" "                d# 15 config-string ip-dns-server
" 255.255.255.0"   d# 15 config-string ip-netmask
" "                d# 64 config-string ip-domain
" "                d# 15 config-string ip-router
" 255.255.255.255" d# 15 config-string ip-address	\ leave room
\ " dhcp" ' ip-address  set-config-string-default

\ OBP-TFTP recommended practice says that bootp is the preferred
\ protocol. The first field, if present, represents serverip-addr.
\ Extend the RP to optionally recognize "bootp" or "rarp" to override
\ the default protocol. If the first field is null, protocol is bootp
\ and all parameters are retrieved from the server.
: arg-fields  ( arg$ -- )
   true to use-bootp?			( rem$ )	\ Default

   parse-field                          ( rem$ field$ )

   \ If the first field is "last" and we already know our IP address, ignore
   \ all other fields and don't re-initialize all the internal variables
   2dup " last" $=  if  2drop		( rem$ )
      my-ip-addr unknown-ip-addr?  if   ( rem$ )
         \ If we are supposed to use the last good configuration, but
         \ there is none, ignore the "last" and handle the rest as if
         \ "last" were absent.
         parse-field                    ( rem$ field$ )
      else                              ( rem$ )
         2drop                		( )
         true to use-last?		( )
         false to use-bootp?		( )
         exit
      then
   then					( rem$ field$ )

   \ Otherwise, re-initialize the internal variables
   init-ip-addr                         ( rem$ field$ )

   \ If the first field is "nfs", arrange to use NFS for booting and
   \ restart the parsing for the rest of the fields
   2dup " nfs" $=  if   2drop           ( rem$ )
      true to use-nfs?                  ( rem$ )
      parse-field                       ( rem$ field$ )
   then                                 ( rem$ field$ )

   2dup " rarp" $=  if  2drop		( rem$ )
      false to use-bootp?		( rem$ )
   else					( rem$ field$ )

   2dup " bootp" $= >r 2dup " dhcp" $= r> or  if  ( rem$ field$ )
      2drop                             ( rem$ )
   else					( rem$ field$' )
      \ The first field is not one of the special values listed
      \ above, so restore it to the argument string
      un-field 				( rem$ )
   then  then				( rem$ )

   tftp-args				( )
;

: parse-args  ( -- )
   my-args  dup  if       ( adr len )
      bootnet-debug  if  ." my-args = " 2dup type  cr   then
      arg-fields	  ( )
   else                   ( adr len )
      2drop               ( )
      init-ip-addr        ( )
   then
;

headerless

partial-headers
defer modify-boot-file
: bootp-modify-file  ( -- )
   bootp-name-buf count nip  if 	\ Override if bootp modified the name
      bootp-name-buf count  file-name-buf place-cstr drop
   then 
;
' bootp-modify-file  to modify-boot-file

: dhcp-modify-file  ( -- )
   file-name-buf c@  0=  if  bootp-modify-file  then
;

headerless
\ bootp syntax is - boot net:bootp[,[server-ip-addr][,file-name]].
\              or - boot net:[[server-ip-addr][,file-name]].
\ Open routine has taken file-name from command line in file-name-buf.
\ If there was none, bootp will use default 
\ file coming from bootp server (mentioned in bootptab)
\ Currently the one specified on cmd line overwrites that from bootp reply.

: process-bootp ( -- )  \ handle bootp request 
[ifdef] use-dhcp  do-dhcp  [else]  do-bootp  [then]
   modify-boot-file
; 

: delim?  ( char -- flag )  dup [char] / =  swap [char] \ =  or  ;
d# 128 buffer: nfs-filename
: nfs-read  ( adr filename$ -- len )
   dup  if                                              ( adr filename$ )
      \ If the name is relative; construct a full pathname
      over c@  delim?  0=  if                           ( adr filename$ )
         \ Prepend root path (if present) or "/"
         'root-path cscount  dup  0=  if                ( adr filename$ root$ )
            2drop  " /"                                 ( adr filename$ root$ )
         then                                           ( adr filename$ )
         nfs-filename pack                              ( adr filename$ 'buf )

         \ Insert a "/" after the root path if necessary
         count + 1- c@  delim?  0=  if                  ( adr filename$ )
            " /" nfs-filename $cat                      ( adr filename$ )
         then                                           ( adr filename$ )

         \ Append the filename
         nfs-filename $cat  nfs-filename count          ( adr filename$' )
      then
   then
   bootnet-debug  if  ." NFS protocol: Reading file: " 2dup type cr  then
   " nfs" $open-package >r r@ 0=  if
      collect(
         ." NFS open failed." cr
         [ifdef] .dhcp-server .dhcp-server  [then]
         ." NFS Server: "  his-ip-addr .ipaddr  cr
         ." Filename: "  nfs-filename count type  cr
      )collect $abort
   then                           ( adr r: ih )
   " load" r@ $call-method        ( len )
   r> close-package
;

: url?  ( filename$ -- flag )
   " /\" lex  if                            ( rem$ head$ delim )
      drop 2swap 2drop                      ( head$ )
   then                                     ( head$ | filename$ )
   " :" lex  if  5drop true exit  then      ( head$ )
   2drop false                              ( false )
;
char / constant delim

d# 255 instance buffer: pathbuf
: fix-delims  ( adr len -- adr' len' )
   pathbuf pack count 2dup
   bounds  ?do  ( adr len )
      i c@  [char] / =  if  [char] \ i c!  then
   loop
;

: load-url  ( adr filename$ -- len )
   fix-delims
   2dup open-dev >r r@ 0=  if   ( adr filename$ )
      collect(
         ." Can't open " type cr
         [ifdef] .dhcp-server .dhcp-server  [then]
      )collect $abort
   then                            ( adr filename$ r: ih )
   2drop " load" r@ $call-method   ( len )
   r> close-dev
;

: read-file  ( adr filename$ -- len )
   2dup  url?  if  load-url exit  then     ( adr filename$ )

[ifdef] use-dhcp
   use-bootp?  use-server? 0=  and  bootp-only? 0=  and
   abort" The DHCP server did not specify a boot server"
[then]

   use-nfs?  if  nfs-read  else  tftpread  then
;

h# c123 value next-udp-local-port
true value first-time?
: ?init-udp-local-port  ( -- )
   first-time?  if
[ifdef] random-long
      random-long h# 3fff and h# c000 + to next-udp-local-port
[then]
      false to first-time?
   then
;

headers
: alloc-udp-port  ( -- port )
   next-udp-local-port 1+                  ( port )
   \ Stay within the IANA-recommended dynamic port range
   dup h# 10000 =  if  drop h# c000  then  ( port' )
   dup to next-udp-local-port              ( port )
;
: next-xid  ( -- id )  rpc-xid 1+ dup to rpc-xid  ;
: allocate-packet  ( len -- adr )  allocate-udp  ;
: free-packet  ( len -- adr )  free-udp  ;
: send  ( adr len src-port dst-port -- )  send-udp-packet  ;
: receive  ( dst-port -- true | adr len false )  receive-udp-packet  ;

: nvram-ip?  ( -- flag )
   ip-address   dup      if                               ( adr len )
   2dup " dhcp"  $=  0=  if                               ( adr len )
   2dup " bootp" $=  0=  if                               ( adr len )
      my-ip-addr ['] $ip# catch  0=  if                   ( )
         ip-netmask subnetmask     ['] $ip# catch  if  3drop  then
         \ XXX in the absence of a netmask value, we should determine
         \ it from my-ip-addr
         ip-dns-server name-server-ip ['] $ip# catch  if  3drop  then
         ip-router router-ip-addr ['] $ip# catch  if  3drop  then
         ip-domain dup  if  'domain-name place-cstr drop  else  2drop  then
         true exit
      then                                                ( x x x )
      drop                                                ( x x )
      unknown-ip-addr my-ip-addr copy-ip-addr             ( x x )
   then then then                                         ( adr len )
   2drop false
;

: try-promiscuous  ( -- )
   " enable-promiscuous" my-parent ihandle>phandle find-method  if   ( acf )
      my-parent call-package
      exit
   then
   " promiscuous-mode" my-parent ihandle>phandle find-method  if   ( acf )
      my-parent call-package
      exit
   then
   " promiscuous" my-parent ihandle>phandle find-method  if   ( acf )
      my-parent call-package
      exit
   then
   \ Try setting the unicast address to the multicast address?
   ." Can't enable multicast reception in network driver" cr
;

: set-multicast-en-addr  ( 'ip -- )
   " "(01 00 5e)" his-en-addr swap move              ( 'ip )
   1+  his-en-addr 3 +  3 move                       ( )
   his-en-addr 3 + c@ h# 7f and his-en-addr 3 + c!   ( )
;

: send-multicast  ( -- )
   server-ip-addr his-ip-addr copy-ip-addr
   his-ip-addr set-multicast-en-addr
;

0 value igmp-packet
: send-igmp-v1-report  ( 'ip -- )
   8 allocate-ip  to igmp-packet         ( 'ip )
   0 igmp-packet l!                      ( 'ip )
   h# 12 igmp-packet c!                  ( 'ip )
   dup  igmp-packet 4 +  copy-ip-addr    ( 'ip )
   0  igmp-packet 8  oc-checksum  igmp-packet 2+ be-w!  ( 'ip )

   his-ip-addr copy-ip-addr  \ Send to the group we are registering for
   1 ttl !   
   igmp-packet 8  2  send-ip-packet
   igmp-packet 8  free-ip
   broadcast-ip-addr his-ip-addr copy-ip-addr  \ Don't filter on the server IP address
;

: join-multicast-group  ( 'ip -- )
   dup set-multicast-en-addr    ( 'ip )
   send-igmp-v1-report          ( )
   true to multicast-rx?        ( )
   " set-multicast" my-parent ihandle>phandle find-method  if   ( acf )
      his-en-addr /e  rot my-parent call-package                ( )
      exit
   then
   try-promiscuous
;
: receive-multicast  ( 'ip -- )
   my-ip-addr join-multicast-group
;

defer configured  ' noop to configured
: configure  ( -- )
   use-last?  if  configured exit  then

   my-ip-addr multicast?  if  receive-multicast exit  then
   server-ip-addr multicast?  if  send-multicast exit  then

   use-bootp?  if
      nvram-ip?  0=  if  process-bootp  then
   else
      \ Use RARP to find the client's IP address if it was not specified
      \ in the arguments.
      my-ip-addr unknown-ip-addr?  if
         \ RARP gives my-ip-addr, his-ip-addr, his-en-addr, 
         \ The default boot file name is derived from my-ip-addr
         do-rarp                  
      else
         use-server?  if
             bootnet-debug  if
                ." Using the server IP address specified in the arguments." cr 
             then 
         then
      then

      \ At this point, we know my-ip-addr, and we might know his-ip-addr
      \ from RARP.  However, if a server was specified in the arguments,
      \ the his-ip-addr value from RARP is not necessarily the same as
      \ the IP address for the user-specified server, so we override
      \ his-ip-addr below.  (If a server was not specified and we don't know
      \ his-ip-addr from RARP, then we will broadcast the TFTP request.)
      use-server?  if
         server-ip-addr set-dest-ip
      then
   then
   show-all-en-ip-address
   configured
;

\ complete syntax:
\    net:[bootp|rarp,]server-ip,filename,client-ip,router-ip, ...
\         ... #bootp-retries,#tftp-retries
\ syntax for booting - net[:sipaddr[,[file-name][,[tipaddr][,gipaddr]]]]
\ syntax for booting over a router (1 hop):  net:sipaddr,[file-name],[tipaddr],gipaddr
\ Note: if user provides gipaddr, user must provide sipaddr
\ Once use-server? is set, never broadcast tftp.

: open   ( -- okay? )
   open-link
   parse-args
   mac-address drop   my-en-addr  copy-en-addr
   configure
   s-all 
   my-self to obp-tftp-ih   \ Publish so IP redirector can attach to us
   ?init-udp-local-port
   true
;

: close  ( -- )
[ifdef] process-done-ip
   process-done-ip
[then]
   close-link
   0 to obp-tftp-ih
;

: load   ( adr -- len )  boot-filename read-file  ;
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
