\ dump XO-1 frame buffer in BMP24 format

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

0 value fb-va

: put-plane  ( -- )
   " fb-va" screen-ih $call-method to fb-va
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
