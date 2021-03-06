: >hex  ( n -- n' )  d# 10 /mod h# 10 * +  ;

0 value tim-version
: tim-v4?  ( -- flag )  tim-version h# 00ffff00 and h# 00030400 =  ;

: today>hex  ( -- n )
   today        ( day month year )
   d# 100 /mod  ( day month yr century )
   rot >hex >r  ( day yr century r: hex-month )
   rot >hex >r  ( yr century r: hex-month hex-day )
   >hex >r      ( yr r: hex-month hex-day hex-century )
   >hex r> r> r> 
   tim-v4?  if  2swap  then
   bljoin  ( n )
;

0 value image-size
0 value image-adr
: tim$  ( -- adr len )  image-adr image-size  ;

0 value new-image-size
: ?realloc-image  ( new-size -- )
   dup image-size >  if             ( new-size )
      to new-image-size             ( )
      image-adr  if                 ( )
         image-adr new-image-size resize  abort" resize failed"  ( adr )
      else                          ( )
         new-image-size alloc-mem   ( adr )
      then                          ( adr )
      to image-adr                  ( )
      image-adr new-image-size  image-size /string  h# ff  fill
      new-image-size to image-size
   else                             ( new-size )
      drop                          ( )
   then                             ( )
;

: get-hex  ( -- )  safe-parse-word  $hnumber abort" Bad hex number"  ;
: hex,  ( -- )  get-hex  l,  ;
: get-word  ( -- adr len )  safe-parse-word  ;
: get-filename  ( -- adr len )  0 parse  ;

: ?4bytes  ( adr len -- adr )  4 <> abort" Tag must be 4 characters"  ;
: 4c,  ( adr len -- )
   ?4bytes   ( adr )
   3 +  4 0  do  dup i - c@ c,  loop  drop  ( )
;
: -4c,  ( adr len -- )
   ?4bytes
   4 bounds  do  i c@ c,  loop              ( )
;
: 4c!  ( adr len dst -- )
   >r ?4bytes 4 + r>   ( adr' dst )
   4 0  do             ( adr dst )
      swap 1- tuck c@  ( adr' dst src-byte )
      over c!  1+      ( adr dst' )
   loop                ( adr dst )
   2drop               ( )
;

0 value tim-adr
0 value last-image-adr
0 value #images-adr
0 value res-size-adr
0 value #keys-adr
0 value res-adr
: save-tim:  \ filename  ( -- )
   writing
   tim-adr  here over -  ofd @ fputs
   ofd @ fclose
;
0 value my-timh-adr

: save-image:  \ filename  ( -- )
   writing
   image-adr image-size  ofd @ fputs
   ofd @ fclose
   image-adr image-size free-mem
;
: id,  ( -- )
   get-word                                     ( adr len )
   \ The ID can either be a 4 bytes of ASCII, e.g. OLPC,
   \ or 3 ASCII plus a decimal number, e.g. SPI'10
   2dup [char] ' left-parse-string              ( adr len tail$ head$ )
   nip  4 =  if                                 ( adr len tail$ )
      \ No ' character in string; use verbatim
      2drop
   else                                         ( adr len tail$ )
      \ Convert trailing number to binary byte value - e.g. NAN'6 -> NAN(06)
      push-decimal $number pop-base  abort" Bad number"  ( adr len n )
      nip  over 3 + c!  4                                ( adr 4 )
   then
   4c,
;
: tim:  \ version trusted ID Processor 
   0 to last-image-adr
   here to tim-adr
   get-hex dup l,  to tim-version
   " TIMH" 4c,
   hex,        \ Trusted
\  hex,        \ Date
   today>hex l,
   id,            \ OEM ID
   get-word 2drop \ Processor
;
: flash:  \ id (e.g. NAN6)
   5 0  do  -1 l,  loop

   id,

   here to #images-adr   0 l,
   here to #keys-adr     0 l,
   here to res-size-adr  0 l,
;
: set-last-image  ( adr len -- )
   last-image-adr  if  last-image-adr 4c!  else  2drop  then
   here to last-image-adr  -1 l,
;
: $file-size  ( adr len -- size )
   $read-open  ifd @ fsize  ifd @ fclose
;
0 value image-offset
: place-image  ( adr len -- size )
   $read-open  ifd @ fsize     ( size )
   image-offset                ( size offset )
   2dup + ?realloc-image       ( size offset )
   image-adr +  over           ( size adr size )
   ifd @ fgets                 ( size read-size )
   over <> abort" Read failed" ( size )
   ifd @ fclose                ( size )
   \ Older BOOTROMs seem to want the size to be strongly aligned
   tim-v4?  if  4  else  h# 800  then  round-up  ( size' )
;
: place-hash  \ XXX need to implement non-null hash info
   tim-v4?  if
      0 l,  \ Size to hash  (should be -1 but 0 is in the examples)
      d# 20 l,  \ HashAlgorithmID - SHA-160
      d# 16 0  do  0 l,  loop  \ Hash
      0 l,   \ Partition number      
   else
      d# 10 0  do  0 l,  loop  \ Hash
   then
;
: +#images  ( -- )  #images-adr l@ 1+ #images-adr l!  ;
: start-image  ( adr len -- )
   +#images
   get-word  2dup 4c,  set-last-image
   get-hex  dup to image-offset  l,  \ Flash offset
   hex,            \ Load address
;
: anonymous: \ flash-offset filename
   get-hex to image-offset
   get-filename place-image drop
;
   
: image:  \ name flash-offset mem-load-addr filename
   start-image
   get-filename place-image l,
   place-hash
;
: timh:  \ name flash-offset mem-load-addr
   here to my-timh-adr
   start-image
   0 l,        \ This will be overwritten later
   place-hash   
;
0 value #res-pkgs-adr

: reserved:
   here to res-adr
   " OPTH" 4c,
   here to #res-pkgs-adr  0 l,
;
: end-reserved
   here res-adr -  res-size-adr l!
   ['] (do-literal) to do-literal
;
0 value pkg-start-adr
: start-package  ( adr len -- )
   #res-pkgs-adr l@ 1+ #res-pkgs-adr l!
   here to pkg-start-adr
   4c,  
   0 l,  \ Package size
;
: end-package  ( -- )
   here pkg-start-adr -  pkg-start-adr la1+ l!
;   
: end-tim  ( -- )
   \ If we have used a timh: specifier, set its length and copy the constructed TIM into the image
   my-timh-adr  if
      here tim-adr -  my-timh-adr 4 la+ l!
      tim-adr  image-adr my-timh-adr 2 la+ l@ +   here tim-adr -  move
   else
      tim-adr  image-adr   here tim-adr -  move
   then
;
: tbrx:   \ xferloc
   " TBRX" start-package
   hex,
   0 l,    \ #pairs
;
: transfer: \ NAME address
   pkg-start-adr 3 la+ dup l@ 1+ swap l!  \ Increment #pairs
   get-word 4c,
   hex,
;
: pair:  \ tag value
   hex,
   hex,
;
: gpios:
   " GPIO" start-package
   0 l,    \ #pairs
;
: gpio:  \ address value
   pkg-start-adr 2 la+ dup l@ 1+ swap l!  \ Increment #pairs
   pair:
;
: ddrc:  \
   " DDRC" start-package
;
: cmcc:  \
   " CMCC" start-package
;
: usb:   \ Port# Enabled?
   " "(00)USB" start-package hex, hex, end-package
;
: uart:   \ Port# Enabled?
   " "UART" start-package hex, hex, end-package
;
: cmon:  \
   " CMON" start-package end-package
;
: core:  \ number mapping
   " CORE" start-package hex, hex, end-package
;
: term:  " Term" start-package end-package  ;
