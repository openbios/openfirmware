\ See license at end of file
purpose: Neighbor Discovery

headerless

d# 200 constant ND_TIMEOUT              \ Neighbor discovery timeout (ms)
d# 200 constant DAD_TIMEOUT             \ Duplicate Address Detection timeout (ms)
d# 500 constant RD_TIMEOUT              \ Router Discovery timeout (ms)

" stateless"       d# 40 config-string ipv6-address            \ leave room
\ " dhcp" ' ipv6-address  set-config-string-default

[ifndef] include-ipv4
: configure  ( -- )  ;
[then]

: got-nd-ad?  ( adr len -- flag )
   drop
   dup c@ d# 136 <>  if  drop false exit  then                 \ Neighbor advertisement?
   dup 8 + his-ipv6-addr ipv6= not  if  drop false exit  then  \ Check IP address
   dup 4 + c@ h# 60 and h# 60 <>  if  drop false exit  then    \ Solicited, override
   dup d# 24 + c@ 2 <>  if  drop false exit  then              \ Target link address
   d# 26 + his-en-addr copy-en-addr                            \ Set his-en-addr
   true
;

/ipv6 buffer: his-ipv6-addr-temp
: do-neighbor-discovery  ( -- )
   bootnet-debug  if
      ." ICMPv6 ND protocol: Getting MAC address for IPv6 address: " cr
      indent his-ipv6-addr .ipv6 cr
   then

   his-ipv6-addr his-ipv6-addr-temp copy-ipv6-addr
   set-his-en-addr-mc                         \ Set his multicast link address
   set-his-ipv6-addr-mc
   his-ipv6-addr-mc-sol-node his-ipv6-addr copy-ipv6-addr
   his-ipv6-addr-temp send-neigh-sol               \ Neighbor solicitation
   his-ipv6-addr-temp his-ipv6-addr copy-ipv6-addr

   current-timeout >r
   ND_TIMEOUT set-timeout
   begin
      IP_HDR_ICMPV6 receive-ip-packet ?dup 0=  if  got-nd-ad?  then
   until
   r> restore-timeout

   bootnet-debug  if  ." Got MAC address: " his-en-addr .enaddr cr  then
;

: (resolve-en-addrv6)  ( 'dest-adr type -- 'en-adr type )
   dup IP_TYPE  =  if                                ( 'ip-adr ip-type )
[ifdef] include-ipv4
      swap  dup broadcast-ip-addr?  if               ( ip-type 'ip-adr )
         drop                                        ( ip-type )
         broadcast-en-addr his-en-addr copy-en-addr  ( ip-type )
      else                                           ( ip-type 'ip-adr )
         his-ip-addr copy-ip-addr                    ( ip-type )
         his-ip-addr my-ip-addr ip-prefix=?  if
            his-en-addr known-en-addr? not  if  unlock-link-addr do-arp  then  ( ip-type )
         else
            router-en-addr his-en-addr copy-en-addr
         then
      then
      his-en-addr  swap
[then]
      exit
   else                                              ( 'dest-adr type )
      dup IPV6_TYPE  =  if
         swap his-ipv6-addr copy-ipv6-addr
         his-en-addr broadcast-en-addr en=  if  do-neighbor-discovery  then
         his-en-addr swap exit
      then
   then
   
   nip his-en-addr swap
;

: s-all-ipv6 ( -- )           \ See discovery info
   bootnet-debug  if
      ." My IPv6 configuration (stateless autoconfiguration): " cr
      indent .my-ipv6-addr-link-local  cr
      my-ipv6-addr-global knownv6?  if
         indent .my-ipv6-addr-global   cr
         indent .my-prefix             cr
      then
      indent .my-link-addr  cr
      use-routerv6?  if  indent .routerv6-en-addr  cr  then
   then
;

: detect-dad  ( -- )
   DAD_TIMEOUT set-timeout
   begin
      IP_HDR_ICMPV6 receive-ip-packet
      dup 0=  if  got-nd-ad?  abort" Duplicate IPv6 address detected"  then
   until
;
: set-my-ipv6-addr-link-local  ( -- )
   \ Duplicate Address Discovery
   unknown-ipv6-addr my-ipv6-addr copy-ipv6-addr

   default-ipv6-addr my-ipv6-addr-link-local copy-ipv6-addr
   my-en-addr     c@ 2 xor my-ipv6-addr-link-local     8 +   c!
   my-en-addr 1+           my-ipv6-addr-link-local     9 + 2 move
   my-en-addr 3 +          my-ipv6-addr-link-local d# 13 + 3 move

   set-my-ipv6-addr-mc

   ipv6-addr-mc-all-nodes his-ipv6-addr copy-ipv6-addr
   set-his-en-addr-mc
   my-ipv6-addr-link-local send-neigh-sol
   detect-dad

   my-ipv6-addr-link-local my-ipv6-addr copy-ipv6-addr
;

: process-rd-options  ( adr len -- )
   begin  dup 0>  while
      over c@ case
         1  of  over 2 + routerv6-en-addr copy-en-addr  endof  \ Source link-layer address option
         3  of  over 2 + c@ to /prefix                       \ Prefix option
                over 3 + c@ to prefix-flag
                over 8 + be-l@ to prefix-lifetime            \ XXX lifetime
                over d# 16 + my-prefix copy-ipv6-addr        \ Prefix
                endof
         5  of  over 4 + be-l@ to (link-mtu)  endof          \ MTU option
      endcase
      over 1+ c@ 8 * /string
   repeat  2drop
;
: process-rd?  ( adr len -- router-ad? )
   over c@ d# 134 <>  if  2drop false exit  then  \ Router advertisement?
   over 4 + c@ to router-hop-limit
   over 5 + c@ to router-flags                    \ XXX What to do with stateful config?
   over 6 + be-w@ to router-lifetime
   over 8 + be-l@ to router-reachable-time
   over d# 12 + be-l@ to router-retrans-time
   d# 16 /string                                  ( opt-adr,len )
   process-rd-options                             ( )
   true
;
: auto-cfg-global?  ( -- flag )
   my-prefix unknown-ipv6-addr?  if  false exit  then
   prefix-flag h# 40 and 0=  if  false exit  then
   /prefix d# 64 =                              \ XXX What to do with /prefix other than 64?
;
: discover-router  ( -- )
   unknown-ipv6-addr        my-ipv6-addr-global       copy-ipv6-addr
   ipv6-addr-mc-all-routers his-ipv6-addr             copy-ipv6-addr
   set-his-en-addr-mc
   send-router-sol

   RD_TIMEOUT set-timeout
   begin
      IP_HDR_ICMPV6 receive-ip-packet  ?dup 0=  if  process-rd?  then
   until
   auto-cfg-global? not  if  exit  then

   \ DAD on the global IPv6 address
   my-ipv6-addr-link-local my-ipv6-addr-global copy-ipv6-addr
   my-prefix my-ipv6-addr-global /prefix 8 / move   \ XXX assume prefix multiple of 8 bits

   ipv6-addr-mc-all-nodes his-ipv6-addr copy-ipv6-addr
   set-his-en-addr-mc
   my-ipv6-addr-global send-neigh-sol
   detect-dad
;

: configure-ipv6  ( -- )       \ Get discovery info
   use-ipv6?                   \ Save IPv6 flag
   true to use-ipv6?

   ['] 4drop to icmpv6-err-callback-xt
   ['] 2drop to icmpv6-info-callback-xt

   d# 64 to /prefix
   set-my-ipv6-addr-link-local

   discover-router
   to use-ipv6?                 \ Restore IPv6 flag
;

: configure  ( -- )
   use-ipv6?                    \ Save IPv6 flag
   false to use-ipv6?  configure
   to use-ipv6?                 \ Restore IPv6 flag
   configure-ipv6
;

: parse-args  ( -- )
   false to use-bootp?
   true to use-last?
;

: close  ( -- )
[ifdef] include-ipv4
   close
[else]
   close-link
   0 to obp-tftp-ih
[then]
;

\ complete syntax:
\    net:[bootp]server-ip,filename,client-ip,router-ip, ...
\         ... #bootp-retries,#tftp-retries
\ syntax for booting - net[:sipaddr[,[file-name][,[tipaddr][,gipaddr]]]]
\ syntax for booting over a router (1 hop):  net:sipaddr,[file-name],[tipaddr],gipaddr
\ Note: if user provides gipaddr, user must provide sipaddr
\ Once use-server? is set, never broadcast tftp.

: open  ( -- ok? )
[ifdef] include-ipv4
   false to use-ipv6?
   open 0=  if  false exit  then               \ IPv4 open
[else]
   open-link
   parse-args
   mac-address drop  my-en-addr  copy-en-addr
   my-self to obp-tftp-ih
[then]
   true to use-ipv6?
   set-mc-hash  if  close false exit  then
   ['] (resolve-en-addrv6) to resolve-en-addr
   configure-ipv6
   s-all-ipv6
   setup-ip-attr
   true
;


headers
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
