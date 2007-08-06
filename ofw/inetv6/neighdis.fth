\ See license at end of file
purpose: Neighbor Discovery

headerless

" "                d# 40 config-string ipv6-dns-server
" "                d# 64 config-string ipv6-domain
" "                d# 40 config-string ipv6-router
" stateless"       d# 40 config-string ipv6-address	\ leave room
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

: do-neighbor-discovery  ( -- )
   bootnet-debug  if
      ." ICMPv6 ND protocol: Getting MAC address for IP address: "
      his-ipv6-addr .ipv6 cr
   then

   set-his-mc-en                              \ Set his multicast link address
   send-neigh-sol                             \ Neighbor solicitation

   current-timeout >r
   timeout-msecs @ set-timeout
   begin
      IP_HDR_ICMPV6 receive-ip-packet ?dup 0=  if  got-nd-ad?  then
   until
   r> restore-timeout

   bootnet-debug  if  ." Got MAC address: " his-en-addr .enaddr cr  then
;

: do-discovery  ( -- )
   \ XXX need to do DHCPv6 discovery
   his-ipv6-addr be-w@ h# fe80 =  if  do-neighbor-discovery  then
;

: (resolve-en-addrv6)  ( 'dest-adr type -- 'en-adr type )
   dup IP_TYPE  =  if                                ( 'ip-adr ip-type )
[ifdef] include-ipv4
      swap  dup broadcast-ip-addr?  if               ( ip-type 'ip-adr )
         drop                                        ( ip-type )
         broadcast-en-addr his-en-addr copy-en-addr  ( ip-type )
      else                                           ( ip-type 'ip-adr )
         his-ip-addr copy-ip-addr                    ( ip-type )
         his-en-addr broadcast-en-addr en=  if  do-arp  then  ( ip-type )
      then
      his-en-addr  swap
[then]
      exit
   else                                              ( 'dest-adr type )
      dup IPV6_TYPE  =  if
         swap his-ipv6-addr copy-ipv6-addr
         his-en-addr broadcast-en-addr en=  if  do-discovery  then
         his-en-addr swap exit
      then
   then
   
   nip his-en-addr swap
;

: s-all-ipv6 ( -- )           \ See discovery info
   bootnet-debug  if
      ." Initial configuration: (fixed) " cr
      indent .my-ipv6-addr  cr
      indent .my-link-addr  cr
   then
;

create default-ipv6-addr  h# fe c, h# 80 c, 0 c, 0 c, 0 c, 0 c, 0 c, 0 c,
			  0 c, 0 c, 0 c, h# ff c, h# fe c, 0 c, 0 c, 0 c,
: set-my-ipv6-addr  ( -- )
   default-ipv6-addr my-ipv6-addr copy-ipv6-addr
   my-en-addr     c@ 2 xor my-ipv6-addr     8 +   c!
   my-en-addr 1+           my-ipv6-addr     9 + 2 move
   my-en-addr 3 +          my-ipv6-addr d# 13 + 3 move
;

: configure-ipv6  ( -- )      \ Get discovery info
   ['] 4drop to icmpv6-err-callback-xt
   ['] 2drop to icmpv6-info-callback-xt

   d# 64 to prefix
   set-my-ipv6-addr
   set-my-mc-ipv6-addr

   \ XXX Duplicate address discovery; Router discovery
   \ ::0 => ff02::1:ffb4:0061 hop-by-hop, multicast listener report
   \ ::0 => ff02::2 router solicitation
   \ ::0 => ff02::1:ffb4:0061 DAD, neighbor solicitation with target addr
   \ Wait for router advertisement, if gotten, continue
   \ For each prefix in router advertisement, combine prefix with interface id
   \ Add address to the list of assigned addresses for the interface
   \ All addresses must be verified with DAD
   \ fe80::259:08ff:feb4:0061 => ff02::1:ffb4:0061 hop-by-hop, multicast listener report
;

: configure  ( -- )
   use-ipv6?			\ Save IPv6 flag
   false to use-ipv6?  configure
   to use-ipv6?			\ Restore IPv6 flag
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
   open 0=  if  false exit  then		\ IPv4 open
[else]
   open-link
   parse-args
   mac-address drop  my-en-addr  copy-en-addr
   my-self to obp-tftp-ih
[then]
   true to use-ipv6?
   ['] (resolve-en-addrv6)  to resolve-en-addr
   configure-ipv6
   set-mc-hash  if  close false exit  then
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
