" sdhci" name

0 " #address-cells" integer-property
0 " #size-cells" integer-property
: open  
   [ifdef] my-clock-on  my-clock-on  [then]
   true
;
: close
   [ifdef] my-clock-off  my-clock-off  [then]
;

: r/w-blocks " r/w-blocks" $call-parent  ;
: erase-blocks  " erase-blocks" $call-parent  ;
: fresh-write-blocks-start  " fresh-write-blocks-start" $call-parent  ;
: r/w-blocks-end " r/w-blocks-end" $call-parent  ;
: dma-alloc  " dma-alloc" $call-parent  ;
: dma-free  " dma-free" $call-parent  ;
: set-address  ( rca -- )  my-unit  " set-address" $call-parent  ;
: get-address  " get-address" $call-parent  ;
: attach-card  " attach-card" $call-parent  ;
: detach-card  " detach-card" $call-parent  ;
: size  " size" $call-parent  ;
: show-cid  " show-cid" $call-parent  ;
: /block  " /block" $call-parent  ;
: write-protected?  " write-protected?" $call-parent  ;
: card-inserted?  " card-inserted?" $call-parent  ;

: attach-sdio-card  " attach-sdio-card" $call-parent  ;
: detach-sdio-card  " detach-sdio-card" $call-parent  ;
: r/w-ioblocks  " r/w-ioblocks" $call-parent  ;
: io-b@  " io-b@" $call-parent  ;
: io-b!  " io-b!" $call-parent  ;
: io-b!@  " io-b!@" $call-parent  ;
: sdio-reg@  " sdio-reg@" $call-parent  ;
: sdio-reg!  " sdio-reg!" $call-parent  ;
: sdio-card-id  " sdio-card-id" $call-parent  ;
: sdio-card-blocksize  " sdio-card-blocksize" $call-parent  ;
