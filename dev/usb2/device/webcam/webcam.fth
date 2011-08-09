purpose: USB webcam driver
\ See license at end of file

hex
headers

" camera" device-name
" camera" device-type

defer selftest-hook             ['] noop to selftest-hook
true value verbose?

0 value ctrl-buf
h# 400 value /ctrl-buf
0 value intr-buf

h# c00 value /data-buf		\ Buffer to store one microframe of data
/data-buf buffer: data-buf

: alloc-bufs  ( -- )
   ctrl-buf  if  exit  then
   /ctrl-buf dma-alloc to ctrl-buf
   /intr-in-pipe dma-alloc to intr-buf
;
: free-bufs  ( -- )
   ctrl-buf 0=  if  exit  then
   ctrl-buf /ctrl-buf dma-free  0 to ctrl-buf
;

: init-iso-in     ( #payload pipe interval -- )  " init-iso-in" $call-parent  ;
: begin-iso-in    ( -- )  " begin-iso-in"   $call-parent  ;
: restart-iso-in  ( -- )  " restart-iso-in" $call-parent  ;
: end-iso-in      ( -- )  " end-iso-in"     $call-parent  ;
: get-iso-in      ( adr len -- false | actual error? true )  " get-iso-in"  $call-parent  ;

: begin-intr  ( -- )
   intr-buf /intr-in-pipe intr-in-pipe intr-in-interval  begin-intr-in
;
: end-intr  ( -- )  end-intr-in  ;

: get-intr?  ( adr len -- actual )
   intr-in?  if  nip nip restart-intr-in exit  then     \ USB error; restart
   ?dup  if                             ( adr len actual )
      min tuck intr-buf -rot move       ( actual )
      verbose?  if  ." Interrupt: " intr-buf over " cdump" evaluate cr  then
      restart-intr-in                   ( actual )
   else
      2drop 0                           ( actual )
   then
;

0 value hint
5 value frame-idx
h# 160 value width
h# 120 value height
width height * 2* value /frame      \ 16-bit per pixel

d#    5 value alt-interface
h#  320 value /payload
d#  256 value #payload
/payload dup h# 7ff and swap d# 11 >> 1+ * value /xlen

external
: set-frame  ( idx -- )
   dup to frame-idx
   frame-array@ 2dup  to height  to width
   * bytes/pixel * to /frame
;

: set-alt  ( idx -- )
   dup to alt-interface
   alt-array@ dup to /payload
   dup h# 7ff and swap d# 11 >> 1+ * to /xlen
;

: init-dev
   configuration set-config  if  abort" Failed to set-config"  then
   vs-interface 0 set-interface  if  abort" Failed to set-interface to 0"  then
   ctrl-buf d# 26 vs-interface 100 a1 87 control-get  nip if  abort" Failed to VS_PROBE_CONTROL GET_DEF"  then
   hint       ctrl-buf le-w!   \ bmHint
   format-idx ctrl-buf 2 + c!  \ bFormatIndex
   frame-idx  ctrl-buf 3 + c!  \ bFrameIndex
   /frame     ctrl-buf d# 18 + le-l!   \ dwMaxVideoFrameSize
   ctrl-buf d# 26 vs-interface 100 21 01 control-set  if  abort" Failed to VS_PROBE_CONTROL SET_CUR"  then
   ctrl-buf d# 26 vs-interface 100 a1 81 control-get  nip if  abort" Failed to VS_PROBE_CONTROL GET_CUR"  then
   begin-intr
   ctrl-buf d# 26 vs-interface 200 21 01 control-set  if  abort" Failed to VS_COMMIT_CONTROL SET_CUR"  then
;

: init-stream
   \ Make sure the alt interface's endpoint and maxpayload matches
   /payload iso-in-pipe set-pipe-maxpayload
   #payload iso-in-pipe iso-in-interval init-iso-in
   vs-interface alt-interface set-interface  if  abort" Failed to set alternate interface"  then
   d# 10 ms
   begin-iso-in
;
headers

\ Algorithm for selecting a particular alternate interface and
\ the corresponding uncompressed resolution:
\
\ Empirically, when the webcam sends a video line of data out at
\ a time, ofw can process the video data reasonably well.
\
\ Thus, choose a video highest resolution that satisfy:
\   width*byte/pixel+c < h# 400
\ Then, choose a best match alternate interface

h# 400 constant MAX_PAYLOAD
0 value twidth
0 value tidx
: select-alt  ( -- idx )
   0 to tidx
   MAX_PAYLOAD to twidth
   #alt 1+ 1  do
      i alt-array@ dup h# 7ff and swap d# 11 >> 1+ *
      dup width bytes/pixel * h# c + twidth between
      if  to twidth  i to tidx  else  drop  then
   loop  tidx
;
: select-frame  ( -- idx )
   0 to twidth
   0 to tidx
   #fdesc 1+ 1  do
      i frame-array@ drop
      dup bytes/pixel * h# c +  MAX_PAYLOAD <  if
         dup twidth >  if  to twidth  i to tidx  else  drop  then
      else
         drop
      then
   loop  tidx
;

: set-params  ( -- )
   select-frame set-frame
   select-alt   set-alt
;

: int-property  ( n name$ -- )  rot encode-int  2swap property  ;
: make-properties  ( -- )
   iso-in-pipe     " iso-in-pipe"     int-property
   iso-in-interval " iso-in-interval" int-property
   /payload        " iso-in-size"     int-property
;

: get-next-payload  ( -- len )
   data-buf /xlen get-iso-in  if
      drop
      debug?  if
         dup if  data-buf ca1+ c@ u. dup u.  then
      then
   else
      0
   then
;

0 value dptr     \ Current address of data buffer to read and read-frame
0 value rlen     \ Remaining # of bytes to read into the data buffer
: copy-payload  ( len -- )
   ?dup 0=  if  exit  then
   h# c -  data-buf h# c +                ( len' src )
   dptr rot rlen min dup >r move          ( )  ( R: len )
   dptr r@ + to dptr
   rlen r> - to rlen
;

4 constant MAX_RESTART_READ_FRAME
4 constant MAX_RESTART_ISO_IN
0 value #restart-read-frame
0 value #restart-iso-in
0 value dadr   \ Original adress argument to read-frame
0 value dlen   \ Original len argument to read-frame
: restart-read-frame  ( -- )
   dadr to dptr dlen to rlen  
   #restart-read-frame 1+ dup to #restart-read-frame
   MAX_RESTART_READ_FRAME =  if
      0 to #restart-read-frame
      #restart-iso-in 1+ dup to #restart-iso-in
      MAX_RESTART_ISO_IN =  if  abort" Too many retries"  else  restart-iso-in  then
   then
;
: ?copy-payload  ( len -- )
   ?dup 0=  if  exit  then
   data-buf ca1+ c@ 2 and 2 =  if
      rlen over h# c -  <=  if  copy-payload  else  drop restart-read-frame  then
   else
      copy-payload
   then
;

external
: read  ( adr len -- actual )
   tuck to rlen  to dptr         ( actual )
   begin  rlen  while
      get-next-payload		 ( actual len )
      copy-payload               ( actual )
   repeat                        ( actual )
;

: read-frame  ( adr len -- actual )
   /frame min                    \ Read no more than one frame worth of data
   dup to dlen to dptr dup to dadr to rlen
   0 to #restart-iso-in  0 to #restart-read-frame
   begin  rlen  while
      get-next-payload           ( len )
      ?copy-payload              ( )
   repeat  dlen
;

: open   ( -- flag )
   alloc-bufs
   set-device?  if  false exit  then
   device set-target
   true  
;
: close  ( -- )  free-bufs  ;

: init   ( -- )
   init device set-target
   init-params
   set-params
   make-properties
;

0 value selftest-adr
: selftest  ( -- error? )
   open  if
      " cfg-vs-test" $find  if
         >r guid width height /frame r> execute
         to selftest-adr  to selftest-hook
      else
         ." Warning: need " type cr
      then

      init-dev init-stream
      begin
         selftest-adr /frame read-frame drop
         selftest-hook
      key?  until

      close
      false
   else
      true
   then
;

headers

init

[ifndef] notdef
\ Debug aids
: .restart  ( -- )  ." read-frame restart # = " #restart-read-frame .d cr
                    ." iso-in restart #     = " #restart-iso-in .d cr  ;

: (.buf)  ( i -- )  /xlen *  data-buf +  h# c " cdump" evaluate cr  ;
: .buf    ( -- )  /data-buf /xlen /mod swap if 1+ then 0  do  i (.buf)  loop  ;

: test  ( -- )
   " load-base /frame read-frame drop" evaluate
   " load-base dup /frame + /frame yuv2>rgb" evaluate
   " load-base /frame + 0 0 width height" evaluate " draw-rectangle" " screen-ih $call-method" evaluate
;

: testa  ( -- )
   begin  test key?  until
;
: testb  ( -- )
   begin  restart-iso-in test key?  until
;
[then]

\ open u. init-dev init-stream testa

\ LICENSE_BEGIN
\ Copyright (c) 20011 FirmWorks
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
