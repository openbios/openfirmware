\ See license at end of file
purpose:  Internet Control Message Protocol version 6 (ICMPv6) 

' 4drop instance value icmpv6-err-callback-xt  ( code type adr len -- )
' 2drop instance value icmpv6-info-callback-xt  ( adr len -- )
: set-icmpv6-err-callback   ( xt -- )  to icmpv6-err-callback-xt   ;
: set-icmpv6-info-callback  ( xt -- )  to icmpv6-info-callback-xt  ;

struct  ( ICMP )
   /c sfield icmp-type
   /c sfield icmp-code
   /w sfield icmp-checksum
    0 sfield icmp-flags
    0 sfield icmp-mtu
   /w sfield icmp-id
   /w sfield icmp-seq
    0 sfield icmp-data
constant /icmp-header

0 instance value icmpv6-packet
0 instance value /icmpv6-packet

: allocate-icmpv6  ( len -- adr )  /icmp-header + allocate-ipv6  ;
: free-icmpv6      ( adr len -- )  /icmp-header + free-ipv6  ;

variable icmp-temp
: pseudo-hdr-checksum  ( len ipv6-1 ipv6-2 -- chksum )
   0 swap /ipv6 (oc-checksum)     ( len ipv6-1 chksum )
     swap /ipv6 (oc-checksum)     ( len chksum' )
   swap icmp-temp be-l!           ( chksum )
   icmp-temp /l (oc-checksum)     ( chksum' )
   IP_HDR_ICMPV6 icmp-temp be-l!  ( chksum )
   icmp-temp /l (oc-checksum)     ( chksum' )
;

: compute-icmpv6-checksum  ( adr len ipv6-1 ipv6-2 -- )
   2>r dup 2r>                    ( adr len len ipv6-1 ipv6-2 )
   pseudo-hdr-checksum >r         ( adr len )  ( R: chksum )
   over set-struct                ( adr len )  ( R: chksum )
   0  icmp-checksum be-w!         ( adr len )  ( R: chksum )  \ Zap ICMP checksum
   r> -rot oc-checksum            ( sum )
   icmp-checksum be-w!            ( )
;

: send-icmpv6-packet  ( adr len -- )   \ len = length of ICMP data (does not include header)
   /icmp-header + 2dup his-ipv6-addr my-ipv6-addr compute-icmpv6-checksum
   IP_HDR_ICMPV6 send-ipv6-packet
;

/ipv6 buffer: his-ipv6-temp
: send-mc-icmpv6-packet  ( adr len -- )  \ Send to his multicast IPv6 address
   his-ipv6-addr his-ipv6-temp copy-ipv6-addr
   his-ipv6-addr-mc-sol-node his-ipv6-addr copy-ipv6-addr
   send-icmpv6-packet
   his-ipv6-temp his-ipv6-addr copy-ipv6-addr
;

\ ICMPv6 error handlers (icmp-type: 0-127)
fload ${BP}/ofw/inetv6/icmperr.fth     \ Error handling routines

\ ICMPv6 info handlers (icmp-type: 128-255)
fload ${BP}/ofw/inetv6/icmpecho.fth    \ Echo handling routines
fload ${BP}/ofw/inetv6/icmpinfo.fth    \ Other info message handling routines

decimal
: handle-icmpv6-info  ( adr len -- )
   over c@  case
      128  of  handle-echo-req        endof     \ Echo request
      129  of  handle-echo-reply      endof     \ Echo reply
      130  of  handle-mc-query        endof     \ Multicast listener query
      131  of  handle-mc-report       endof     \ Multicast listener report
      132  of  handle-mc-done         endof     \ Multicast done
      133  of  handle-router-sol      endof     \ Router solicitation
      134  of  handle-router-ad       endof     \ Router advertisement
      135  of  handle-neigh-sol       endof     \ Neighbor solicitation
      136  of  handle-neigh-ad        endof     \ Neighbor advertisement
      137  of  handle-redirect-msg    endof     \ Redirect message
      138  of  handle-router-renum    endof     \ Router renumbering
      139  of  handle-info-query      endof     \ ICMP node information query
      140  of  handle-info            endof     \ ICMP node information response
      141  of  handle-inv-neigh-sol   endof     \ Inverse neighbor discovery solicitation
      142  of  handle-inv-neigh-ad    endof     \ Inverse neighbor discovery advertisement
      143  of  handle-mc-report2      endof     \ Version 2 multicast listener report
      144  of  handle-ha-request      endof     \ ICMP home agent address discovery request
      145  of  handle-ha-reply        endof     \ ICMP home agent address discovery reply
      146  of  handle-mobile-sol      endof     \ ICMP mobile prefix solicitation
      147  of  handle-mobile-ad       endof     \ ICMP mobile prefix advertisement
      148  of  handle-cert-sol        endof     \ Certification path solicitation
      149  of  handle-cert-ad         endof     \ Certification path advertisement
      151  of  handle-mc-router-ad    endof     \ Multicast router advertisement
      152  of  handle-mc-router-sol   endof     \ Multicast router solicitation
      153  of  handle-mc-router-term  endof     \ Multicast router termination
      ( default )  nip nip
   endcase
;

hex

: (handle-icmpv6)  ( adr len protocol -- )
   IP_HDR_ICMPV6 <>  if  2drop exit  then   \ Not an ICMPv6 packet
   dup  if                                  \ Nonzero length
      \ XXX verify checksum
      the-struct >r                         \ Save the-struct
      over c@ h# 80 and  if  handle-icmpv6-info  else  handle-icmpv6-err  then
      r> set-struct                         \ Restore the-struct
   else
      2drop
   then
;
' (handle-icmpv6) to handle-icmpv6

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
