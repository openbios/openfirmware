\ See license at end of file
purpose: VESA framebuffer driver

0 0  " d0000000"  " /" begin-package

" display" device-name
" vesa" " compatible" string-property
h# 40000 constant /fb

my-address my-space encode-phys  /fb encode-int encode+  " reg" property

\ Assume mode 117 - 1024x768x16 - for now
d#   16 value depth
d# 1280 value width  \ Mode 11a
d# 1024 value height

: setmode  ( -- )   ;

\ : bytes/line  ( -- n )  width  depth 8 /  *  ;
: /scanline  ( -- n )  width  depth 8 /  *  ;

: erase-frame-buffer  ( -- )
   frame-buffer-adr /fb    ( adr len )
   depth case
      8      of  h# 0f           fill  endof
      d# 16  of  h# ffff         " wfill" evaluate  endof
      d# 32  of  h# ffff.ffff    " lfill" evaluate  endof
      ( default )  nip nip
   endcase
   h# f to background-color
;
: map-frame-buffer  ( -- )
   my-space  /fb  " map-in" $call-parent to frame-buffer-adr
;
: declare-props  ( -- )		\ Instantiate screen properties
   " width" get-my-property  if  
      width   encode-int " width"     property
      height  encode-int " height"    property
      depth   encode-int " depth"     property
      /scanline  encode-int " linebytes" property
   else
      2drop
   then
;
: set-terminal  ( -- )
   width  height                              ( width height )
   over char-width / over char-height /       ( width height rows cols )
   /scanline depth " fb-install" evaluate ( gp-install )  ( )
;

0 value open-count

: display-remove  ( -- )
   open-count 1 =  if
   then
   open-count 1- 0 max to open-count
;

: display-install  ( -- )
   open-count 0=  if
      setmode
      declare-props		\ Setup properites
      map-frame-buffer
      erase-frame-buffer
   else
      map-frame-buffer
   then
   default-font set-font
   set-terminal
   open-count 1+ to open-count
;

: display-selftest  ( -- failed? )  false  ;

' display-install  is-install
' display-remove   is-remove
' display-selftest is-selftest

" display"                      device-type
" ISO8859-1" encode-string    " character-set" property
0 0  encode-bytes  " iso6429-1983-colors"  property

fload ${BP}/dev/video/common/rectangle16.fth
alias color! 4drop

end-package

\ LICENSE_BEGIN
\ Copyright (c) 2011 FirmWorks
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
