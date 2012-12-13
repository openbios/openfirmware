purpose: SDIO interface
\ See license at end of file

hex
headers

: sdio-reg@  ( reg# function# -- value )  " sdio-reg@" $call-parent  ;
: sdio-reg!  ( value reg# function# -- )  " sdio-reg!" $call-parent  ;
: sdio-reg-w@  ( reg# function# -- w.value )
   2dup sdio-reg@  -rot      ( low  reg# function# )
   swap 1+ swap  sdio-reg@   ( low high )
   bwjoin                    ( w.value )
;
: sdio-w@  ( reg# -- w.value )  1 sdio-reg-w@  ;

false instance value multifunction?
false instance value helper?
false instance value mv8787?
instance defer rx-ready?  ( -- len )
instance defer get-ctrl-port  ( -- port# )
instance defer get-write-port  ( -- port# )

\ FCode doesn't have 2value so we do it this way
0 value fw-name-adr
0 value fw-name-len
: default-fw$  ( -- adr len )  fw-name-adr fw-name-len  ;
: set-default-fw$  ( adr len -- )  to fw-name-len  to fw-name-adr  ;

0 value ioport
d# 256 constant blksz			\ Block size for data tx/rx
d# 256 constant fw-blksz

h#  0 constant config-reg
h#  1 constant host-int-rsr-reg
h#  2 constant host-int-mask-reg
h#  3 constant host-intstatus-reg

h#  4 constant rd-bitmap-reg
h#  6 constant wr-bitmap-reg
h#  8 constant rd-len-reg

\ h# 20 constant host-f1-card-rdy-reg
\ h# 28 constant host-int-status-reg
h# 30 constant card-status-reg
h# 34 constant interrupt-mask-reg
\ h# 38 constant interrupt-status-reg
\ h# 3c constant interrupt-rsr-reg
h# 40 constant host-f1-rd-base-0-reg
\ h# 41 constant host-f1-rd-base-1-reg
h# 6c constant card-misc-cfg-reg
h# 60 constant card-fw-status0-reg
\ h# 61 constant card-fw-status1-reg
\ h# 62 constant card-rx-len-reg
\ h# 63 constant card-rx-unit-reg
h# 78 constant ioport-reg

: ?set-module-property  ( adr len -- )
   " module-type" get-my-property  if  ( adr len )
      encode-string  " module-type" property  ( )
   else                ( adr len prop$ )
      2drop 2drop
   then
;

: sdio-fw-status@  ( -- n )
   card-fw-status0-reg sdio-w@
;

: mv8686-rx-ready?  ( -- len )
   host-intstatus-reg 1 sdio-reg@
   dup 0=  if  exit  then
   dup invert 3 and host-intstatus-reg 1 sdio-reg!  \ Clear UP_LD bit
   1 and  if
      sdio-fw-status@
   else
      0
   then
;

: use-mv8686  ( -- )
    h#  3 to config-reg
    h#  4 to host-int-mask-reg
    h#  5 to host-intstatus-reg
    h# 20 to card-status-reg
    h# 10 to host-f1-rd-base-0-reg
    h# 34 to card-fw-status0-reg
    h# 00 to ioport-reg
    d# 320 to blksz
    d#  32 to fw-blksz
    false to mv8787?
    false to multifunction?
    true  to helper?
    ['] mv8686-rx-ready? to rx-ready?
    ['] 0 to get-ctrl-port
    ['] 0 to get-write-port

    " rom:sd8686.bin" set-default-fw$
    " mv8686" ?set-module-property

    \ This really depends on the firmware that we load, but we don't want
    \ to load the firmware in advance, so we hardcode this, assuming that
    \ the firmware we include with OFW has both thin and fullmac capability.
    " thin" get-my-property  if
       0 0 encode-bytes  " thin" property
    else
       2drop
    then
;
0 instance value rx-port#
0 instance value wr-bitmap
0 instance value rd-bitmap
: update-bitmaps  ( -- )
   host-intstatus-reg 1 sdio-reg@
   dup 2 and  if  wr-bitmap-reg sdio-w@ to wr-bitmap  then
   1 and  if  rd-bitmap-reg sdio-w@ to rd-bitmap  then
;
: mv8787-rx-ready?  ( -- len )
   rd-bitmap  dup  if          ( bitmap )
      d# 16 0  do              ( bitmap )
	 dup 1 and  if         ( bitmap )
	    drop i  leave      ( port# )
	 then                  ( bitmap )
         2/                    ( bitmap' )
      loop                     ( port# )
      1 over lshift invert  rd-bitmap and  to rd-bitmap  ( port# )
      dup  to rx-port#         ( port# )
      2* rd-len-reg + sdio-w@  ( len )
   else                        ( 0 )
      update-bitmaps           ( 0 )
   then
;

: mv8787-get-ctrl-port  ( -- n )
   0
;
: next-wr-port  ( -- n )
   wr-bitmap  2/            ( bits )
   dup  0=  if  exit  then  ( bits )
   d# 16 1  do              ( bits )
      dup  1 and  if        ( bits )
         drop               ( )
         wr-bitmap  1 i lshift  invert and  to wr-bitmap
	 i leave            ( n )
      then                  ( bits )
      2/                    ( bits' )
   loop                     ( n )
;

: mv8787-get-write-port  ( -- n )
   begin  next-wr-port  ?dup 0=  while   ( )
      update-bitmaps                     ( )  
   repeat                                ( n )
;

: use-mv8787  ( -- )
    h#  0 to config-reg
    h#  1 to host-int-rsr-reg
    h#  2 to host-int-mask-reg
    h#  3 to host-intstatus-reg
\   h# 20 to host-f1-card-rdy-reg
\   h# 28 to host-restart-reg
    h# 30 to card-status-reg
    h# 34 to interrupt-mask-reg
\   h# 38 to interrupt-status-reg
\   h# 3c to interrupt-rsr-reg
    h# 40 to host-f1-rd-base-0-reg
\   h# 41 to host-f1-rd-base-1-reg
    h# 6c to card-misc-cfg-reg
    h# 60 to card-fw-status0-reg
\   h# 61 to card-fw-status1-reg
\   h# 62 to card-rx-len-reg
\   h# 63 to card-rx-unit-reg
    h# 78 to ioport-reg
    d# 256 to blksz
    d# 256 to fw-blksz
    true to mv8787?
    ['] mv8787-rx-ready? to rx-ready?
    ['] mv8787-get-ctrl-port  to get-ctrl-port
    ['] mv8787-get-write-port  to get-write-port
    " rom:mv8787.bin" set-default-fw$
    " mv8787" ?set-module-property
    false to helper?
    true to multifunction?
;

: set-version  ( -- error? )
   " sdio-card-id" $call-parent  case
      h# 02df9103  of  use-mv8686 false  endof
      h# 02df9118  of  use-mv8787 false  endof
      ( default )
      ." Unsupported SDIO card ID " dup . cr
      true  swap
   endcase
;

: roundup-blksz  ( n -- n' )  blksz 1- + blksz / blksz *  ;

: set-address  ( rca slot -- )  " set-address" $call-parent  ;
: get-address  ( -- rca )       " get-address" $call-parent  ;
: attach-card  ( -- ok?  )  " attach-sdio-card" $call-parent  ;
: detach-card  ( -- )       " detach-sdio-card" $call-parent  ;

: sdio-poll-dl-ready  ( -- ready? )
   false d# 100 0  do
      card-status-reg 1 sdio-reg@
      h# 9 tuck and =  if  drop true leave  then
      d# 100 usec
   loop
   dup 0=  if  ." sdio-poll-dl-ready failed" cr  then
;

: sdio-fw!  ( adr len -- actual )
   >r >r ioport 1 true r> r> fw-blksz false " r/w-ioblocks" $call-parent
;

: init-device  ( -- )
   ioport-reg 3 bounds  do  i 1 sdio-reg@  loop		\ Read the IO port
   0 bljoin to ioport

   7 0 sdio-reg@  h# 20 or  7 0 sdio-reg!	\ Enable async interrupt mode

   2 2 0 sdio-reg!	\ Enable IO function 1 (2 = 1 << 1)
   3 4 0 sdio-reg!	\ Enable interrupts (1) for function 1 (1 << 1)

   mv8787?  if
      \ Set host interrupt reset to "read to clear"
      host-int-rsr-reg 1 sdio-reg@  h# 3f or  host-int-rsr-reg 1 sdio-reg!

      \ Set Dnld/upld to "auto reset"
      card-misc-cfg-reg 1 sdio-reg@   h# 10 or  card-misc-cfg-reg 1 sdio-reg!
   then
   \ Newer revisions of the 8787 firmware empirically require that this
   \ be enabled early, before firmware download.  Older versions, and
   \ 8686 firmware, appear to be content with it either here or after
   \ firmware startup.
   3  host-int-mask-reg 1 sdio-reg!  \ Enable upload (1) and download (2)
;

: sdio-blocks@  ( adr len -- actual )
   >r >r
   rx-port# ioport +  1 true  r> r>  blksz true  " r/w-ioblocks" $call-parent  ( actual )
;

\ : sdio-blocks!  ( adr len -- actual )
\    >r >r x-get-write-port ioport + 1 true r> r> blksz false " r/w-ioblocks" $call-parent
\ ;

\ 1 is the function number
: (sdio-blocks!)  ( adr len port# -- actual )
   ioport +  -rot    ( port#  adr len )
   1 true  2swap     ( port#  function# inc?  adr len )
   blksz false " r/w-ioblocks" $call-parent
;

\ 0 is the control port number
: packet-out  ( adr len -- error? )  tuck  get-ctrl-port  (sdio-blocks!)  <>  ;

: packet-out-async  ( adr len -- )  get-write-port  (sdio-blocks!) drop  ;

: read-poll  ( -- )
   begin  rx-ready? ?dup  while         ( len )
      new-buffer			( handle adr len )
      sdio-blocks@ drop                 ( handle )
      enque-buffer                      ( )
   repeat
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
