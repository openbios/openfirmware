\ dump XO-4 frame buffer in BMP24 format

dev /display
: fb-va  ( -- fb )  frame-buffer-adr  ;
dend

: ts$  ( -- adr len )
   time&date >unix-seconds push-decimal 0 <# #s #> pop-base
;

0 value bmp-width
0 value bmp-height

h# 36 constant /bmp-hdr
/bmp-hdr buffer: bmp-hdr

0 value fb-va-orig
0 value fb-va

: put-plane  ( -- )
   fb-va-orig to fb-va
   bmp-height 0   do
      bmp-width
      0  ?do
         fb-va w@ ( rgb565 )
         565>rgb ( r g b )
         ofd @ fputc
         ofd @ fputc
         ofd @ fputc
         fb-va wa1+ to fb-va
      loop
   loop
;

: put-header  ( -- )
   " BM"  bmp-hdr swap  move           \ Signature
   bmp-width 3 *  4 round-up  bmp-height *
   dup  bmp-hdr h# 22 + le-l!          \ Image size
   /bmp-hdr +   bmp-hdr 2 + le-l!      \ File size

   0  bmp-hdr 6 + le-l!                \ Reserved
   /bmp-hdr     bmp-hdr h# 0a + le-l!  \ Image data pixel array offset
   h# 28        bmp-hdr h# 0e + le-l!  \ Some variant of header size
   bmp-width  bmp-hdr h# 12 + le-l!
   bmp-height negate bmp-hdr h# 16 + le-l!  \ Pixel array order top to bottom
   1            bmp-hdr h# 1a + le-w!  \ Planes
   d# 24        bmp-hdr h# 1c + le-w!  \ Bits per pixel
   0            bmp-hdr h# 1e + le-l!  \ Compression

   d# 2835      bmp-hdr h# 26 + le-l!  \ X pixels/meter
   d# 2835      bmp-hdr h# 2a + le-l!  \ Y pixels/meter
   0            bmp-hdr h# 2e + le-l!  \ Colors used
   0            bmp-hdr h# 32 + le-l!  \ Colors important

   bmp-hdr /bmp-hdr  ofd @ fputs
;

: fb-save
   writing
   screen-wh to bmp-height to bmp-width

   " fb-va" screen-ih $call-method to fb-va-orig
   put-header
   put-plane
   ofd @ fclose
;

: fb  ( -- )
   ts$
   " u:\"
   " fb-save %s%s.bmp" sprintf
   screen-ih remove-output
   2dup type cr
   ['] evaluate catch ?dup if nip nip .error then
   screen-ih add-output
;

\ special screenshots to cache, then later save

: red-on  ols-led-on  ;
: red-off  ols-led-off ols-led-ec-control  ;
: red-blinks  ( n -- )  0 do  red-on d# 50 ms  red-off d# 200 ms  loop  ;
: orange-on  led-storage-gpio# gpio-set ols-led-on ols-assy-mode-on  ;
: orange-off  led-storage-gpio# gpio-clr ols-led-off ols-assy-mode-off  ;

0 value cb-va   \ base of cache
0 value /cb-va  \ size of image
0 value #cb     \ number of images in cache

: .cb  ( -- )  ." you have " #cb .d ." images in cache" cr  ;

: cb-wipe  ( -- )
   screen-wh to bmp-height to bmp-width
   " fb-va" screen-ih $call-method to fb-va-orig
   bmp-height bmp-width * 2* to /cb-va
   load-base to cb-va
   0 to #cb
   .cb
;

: >cb  ( #cb -- cb-va' )
   cb-va swap /cb-va * +
;

: cb-show  ( -- )
   fb-va-orig #cb >cb /cb-va move       \ save screen beyond cache
   #cb 0 ?do
      i >cb  fb-va-orig  /cb-va  move   \ show an image
      key drop                          \ wait for a key
   loop
   #cb >cb fb-va-orig /cb-va move       \ restore screen
   .cb
;

: saving  ( #cb fn$ -- )
   writing                      ( #cb )
   >cb to fb-va-orig            ( )
   put-header
   put-plane
   ofd @ fclose
;

: cb-save  ( -- )
   #cb 0 ?do
      i
      ts$
      " u:\"
      " saving %s%s.bmp" sprintf
      2dup type cr
      orange-on
      ['] evaluate catch ?dup if nip nip .error then
      orange-off
      d# 1000 ms                        \ hack to enforce unique file name
   loop
   .cb
;

: ?cb-wait-key-up
   red-on
   begin  gpio-rotate-button?  0=  until
   red-off d# 200 ms
;

: cb-key-down  ( -- )
   ?cb-wait-key-up                      \ wait for key release
   #cb 1+  red-blinks                   \ blink red led to show cache size
   fb-va-orig  #cb >cb  /cb-va  move    \ save image to cache
   #cb 1+ to #cb                        \ increment image counter
   red-off                              \ turn off the led
;

: cb-help
   cr
   ." XO-4 screenshot to cache utility 2015-06-19" cr
   "      commands" cr
   cr
   ."     .cb          show how many images are in cache" cr
   ."     cb-wipe      empty the cache" cr
   ."     cb-show      show the cache, one by one" cr
   ."     cb-save      save the cache to USB drive" cr
   cr
;
cb-help
cb-wipe

: cb-alarm  ( -- )  gpio-rotate-button?  if  cb-key-down  then  ;
' cb-alarm d# 100 alarm                 \ schedule regular asynchronous task
