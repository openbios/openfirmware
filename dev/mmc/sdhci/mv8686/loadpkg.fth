" sdio" name
fload ${BP}/dev/mmc/sdhci/mv8686/common.fth	\ Ethernet common variables and routines
fload ${BP}/dev/mmc/sdhci/mv8686/ring.fth	\ Receive ring management
fload ${BP}/dev/mmc/sdhci/mv8686/sdio.fth	\ SDIO interface routines
fload ${BP}/dev/mmc/sdhci/mv8686/mv8686.fth	\ SDIO I/O interface for Marvell 8686
fload ${BP}/dev/mmc/sdhci/mv8686/fw8686.fth	\ Marvell firmware download for SDIO

1 " #size-cells" integer-property
1 " #address-cells" integer-property
: decode-unit  ( adr len -- phys )  push-hex $number if  0  then  pop-base  ;
: encode-unit  ( phys -- adr len )  push-hex (u.) pop-base  ;

new-device
1 to my-space
my-space 1 reg
fload ${BP}/dev/mmc/sdhci/mv8686/libertas-interface.fth		\ Marvell "Libertas" common code
fload ${BP}/dev/libertas.fth			\ Marvell "Libertas" common code
finish-device
