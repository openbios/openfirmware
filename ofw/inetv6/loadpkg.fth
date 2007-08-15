purpose: Interior load file for obp-tftp support package

fload ${BP}/ofw/inetv6/config.fth     \ Networking stack configuration

fload ${BP}/ofw/inetv6/support.fth    \ Miscellaneous support function
[ifdef] include-ipv6
fload ${BP}/ofw/inetv6/supportv6.fth
[then]

fload ${BP}/ofw/inetv6/ethernet.fth   \ Ethernet Address
fload ${BP}/ofw/inetv6/occhksum.fth   \ IP checksum

[ifdef] include-ipv4
fload ${BP}/ofw/inetv6/ip.fth         \ Internet Protocol
fload ${BP}/ofw/inetv6/ipfr.fth       \ IP fragmentation/reassembly
[then]
[ifdef] include-ipv6
fload ${BP}/ofw/inetv6/ipv6.fth
fload ${BP}/ofw/inetv6/ipfrv6.fth     \ IP fragmentation/reassembly
fload ${BP}/ofw/inetv6/icmpv6.fth     \ ICMPv6
[then]

[ifdef] include-ipv4
fload ${BP}/ofw/inetv6/arp.fth        \ [Reverse] Addr Resolution Protocol
[then]

[ifdef] include-ipv4
fload ${BP}/ofw/inetv6/udp.fth        \ User Datagram Protocol
[then]
[ifdef] include-ipv6
fload ${BP}/ofw/inetv6/udpv6.fth      \ User Datagram Protocol
[then]

fload ${BP}/ofw/inetv6/random.fth     \ Random number generator
fload ${BP}/ofw/inetv6/adaptime.fth   \ Adaptive timeout

[ifdef] include-ipv4
fload ${BP}/ofw/inetv6/bootp.fth      \ Bootp Protocol
fload ${BP}/ofw/inetv6/dhcp.fth       \ Dynamic Host Config. Protocol
fload ${BP}/ofw/inetv6/tftp.fth       \ Trivial File Transfer Protocol
fload ${BP}/ofw/inetv6/netload.fth    \ Network boot loading package
fload ${BP}/ofw/inetv6/attr-ip.fth    \ Save IP info in /chosen
[then]
[ifdef] include-ipv6
\ fload ${BP}/ofw/inetv6/bootpv6.fth      \ Bootp Protocol
fload ${BP}/ofw/inetv6/dhcpv6.fth     \ Dynamic Host Config. Protocol
fload ${BP}/ofw/inetv6/tftp.fth       \ Trivial File Transfer Protocol
fload ${BP}/ofw/inetv6/netloadv6.fth  \ Network boot loading package
fload ${BP}/ofw/inetv6/neighdis.fth   \ Neighbor discovery
fload ${BP}/ofw/inetv6/attr-ipv6.fth  \ Save IP info in /chosen
[then]

fload ${BP}/ofw/inetv6/encdec.fth     \ Packet encoding/decoding primitives
[ifdef] include-ipv4
fload ${BP}/ofw/inetv6/dns.fth	      \ Domain name resolver (RFC1034/5)
[then]
[ifdef] include-ipv6
fload ${BP}/ofw/inetv6/dnsv6.fth      \ Domain name resolver (RFC3596)
[then]
