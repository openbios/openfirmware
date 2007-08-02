\ See license at end of file
purpose:  Internet Control Message Protocol version 6 (ICMPv6) info message handlers

\ ************************* Multicast Group Management *************************
: handle-mc-query  ( adr len -- )  2drop  ;          \ Multicast listener query
: handle-mc-report  ( adr len -- )  2drop  ;         \ Multicast listener report
: handle-mc-report2  ( adr len -- )  2drop  ;        \ Version 2 multicast listener report
: handle-mc-done  ( adr len -- )  2drop  ;           \ Multicast done

\ ****************** Neighbor Discovery and Autoconfiguration ******************
: handle-router-sol  ( adr len -- )  2drop  ;        \ Router solicitation
: handle-router-ad  ( adr len -- )  2drop  ;         \ Router advertisement

: handle-mc-router-ad  ( adr len -- )  2drop  ;      \ Multicast router advertisement
: handle-mc-router-sol  ( adr len -- )  2drop  ;     \ Multicast router solicitation
: handle-mc-router-term  ( adr len -- )  2drop  ;    \ Multicast router termination

: send-neigh-sol  ( -- )
   d# 24 allocate-icmpv6 set-struct                  \ Dest IPv6 + one option
   d# 135 icmp-type xc!
   0 icmp-code xc!
   0 icmp-flags xl!
   his-ipv6-addr icmp-data copy-ipv6-addr
   h# 101 icmp-data /ipv6 + xw!                      \ Option type 1 (source mac addr)
                                                     \ Length (in 8 octels)
   my-en-addr icmp-data /ipv6 + 2 + copy-ipv6-addr
   hop-limit >r h# ff to hop-limit                   \ Save and change hop-limit
   the-struct d# 24 2dup send-mc-icmpv6-packet
   free-icmpv6
   r> to hop-limit                                   \ Restore hop-limit
;

: send-neigh-ad  ( solicited?  -- )
   d# 24 allocate-icmpv6 set-struct                  \ Dest IPv6 + one option

   d# 136 icmp-type xc!
   0 icmp-code xc!
   h# 40 and h# 20 or icmp-flags xl!                 \ Flags = (un)solicited, override
   my-ipv6-addr icmp-data copy-ipv6-addr
   h# 201 icmp-data /ipv6 + xw!                      \ Option type 2 (target mac addr)
                                                     \ Length (in 8 octels)
   my-en-addr icmp-data /ipv6 + 2 + copy-ipv6-addr

   hop-limit >r h# ff to hop-limit                   \ Save and change hop-limit
   the-struct d# 24 2dup send-icmpv6-packet
   free-icmpv6
   r> to hop-limit                                   \ Restore hop-limit
;

: handle-neigh-sol  ( adr len -- )                   \ Neighbor solicitation
   \ XXX Verify hop limit is 255.
   dup d# 24 <  if  2drop exit  then
   bootnet-debug  if
      ." Neighbor solicitation from MAC: " over d# 26 + .enaddr cr
   then
   over /icmp-header + my-ipv6-addr ipv6= not  if  ." Not for me" cr 2drop exit  then
   2drop
   \ XXX Send Neighbor Advertisement
   true send-neigh-ad
;

: handle-neigh-ad  ( adr len -- )  2drop  ;          \ Neighbor advertisement

: handle-inv-neigh-sol  ( adr len -- )  2drop  ;     \ Inverse neighbor discovery solicitation
: handle-inv-neigh-ad  ( adr len -- )  2drop  ;      \ Inverse neighbor discovery advertisement

: handle-redirect-msg  ( adr len -- )  2drop  ;      \ Redirect message

: handle-cert-sol  ( adr len -- )  2drop  ;          \ Certification path solicitation
: handle-cert-ad  ( adr len -- )  2drop  ;           \ Certification path advertisement

: handle-router-renum  ( adr len -- )  2drop  ;      \ Router renumbering

: handle-info-query  ( adr len -- )  2drop  ;        \ ICMP node information query
: handle-info  ( adr len -- )  2drop  ;              \ ICMP node information response

\ ******************************** Mobile IPv6 *********************************
: handle-ha-request  ( adr len -- )  2drop  ;        \ ICMP home agent address discovery request
: handle-ha-reply  ( adr len -- )  2drop  ;          \ ICMP home agent address discovery reply
: handle-mobile-sol  ( adr len -- )  2drop  ;        \ ICMP mobile prefix solicitation
: handle-mobile-ad  ( adr len -- )  2drop  ;         \ ICMP mobile prefix advertisement

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


