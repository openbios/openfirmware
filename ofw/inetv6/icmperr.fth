\ See license at end of file
purpose:  Internet Control Message Protocol version 6 (ICMPv6) error message handlers

: .icmpv6-unknown-err  ( type -- )
   ." Unknown error message type: " u.
;

: .icmpv6-dest-err  ( -- )
   icmp-code c@  case
      0  of  ." No route to destination"                                     endof
      1  of  ." Communication with destination administratively prohibited"  endof
      2  of  ." Beyond scope of source address"                              endof
      3  of  ." Address unreachable"                                         endof
      4  of  ." Port unreachable"                                            endof
      5  of  ." Source address failed ingress/egress policy"                 endof
      6  of  ." Eject route to destination"  endof
      ( default )  ." Unknown destination unreachable code: " dup u.
   endcase
;

: .icmpv6-size-err  ( -- )
   ." Packet too big.  MTU of next hop link is: " icmp-mtu xl@ u.
;

: .icmpv6-time-err  ( -- )
   icmp-code c@  case
      0  of  ." Hop limit exceeded in transit"      endof
      1  of  ." Fragment reassembly time exceeded"  endof
      ( default )  ." Unknown time exceeded code: " dup u.
   endcase
;

: .icmpv6-arg-err  ( -- )
   icmp-code c@  case
      0  of  ." Erroneous header field encountered"         endof
      1  of  ." Unrecognized next header type encountered"  endof
      2  of  ." Unrecognized IPv6 option encountered"       endof
      ( default )  ." Unkown parameter problem code: " dup u.
   endcase
;

: .icmpv6-err  ( -- )
   ." ICMPv6: "
   icmp-type c@
   case
      1  of  .icmpv6-dest-err  endof
      2  of  .icmpv6-size-err  endof
      3  of  .icmpv6-time-err  endof
      4  of  .icmpv6-arg-err   endof
      ( default )  .icmpv6-unknown-err
   endcase
   cr
;

: handle-icmpv6-err  ( adr len -- )
   over set-struct                    ( adr len )
   .icmpv6-err                        ( adr len )
   icmp-code c@ -rot                  ( code adr len )
   icmp-type c@ -rot                  ( code type adr len )
   icmpv6-err-callback-xt execute
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


