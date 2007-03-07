purpose: Interior load file for obp-tftp support package

fload ${BP}/ofw/inet/support.fth    \ Miscellaneous support function
fload ${BP}/ofw/inet/ethernet.fth   \ Ethernet Address
fload ${BP}/ofw/inet/occhksum.fth   \ IP checksum
fload ${BP}/ofw/inet/ip.fth         \ Internet Protocol
fload ${BP}/ofw/inet/ipfr.fth	    \ IP fragmentation/reassembly
fload ${BP}/ofw/inet/arp.fth        \ [Reverse] Addr Resolution Protocol
fload ${BP}/ofw/inet/udp.fth        \ User Datagram Protocol
fload ${BP}/ofw/inet/random.fth     \ Random number generator
fload ${BP}/ofw/inet/adaptime.fth   \ Adaptive timeout
fload ${BP}/ofw/inet/bootp.fth      \ Bootp Protocol
fload ${BP}/ofw/inet/dhcp.fth       \ Dynamic Host Config. Protocol
fload ${BP}/ofw/inet/tftp.fth       \ Trivial File Transfer Protocol
fload ${BP}/ofw/inet/netload.fth    \ Network boot loading package
fload ${BP}/ofw/inet/attr-ip.fth    \ Save IP info in /chosen
fload ${BP}/ofw/inet/encdec.fth     \ Packet encoding/decoding primitives
fload ${BP}/ofw/inet/dns.fth	    \ Domain name resolver (RFC1034/5)
