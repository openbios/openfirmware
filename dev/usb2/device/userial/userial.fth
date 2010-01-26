\ See license at end of file
purpose: userial driver - see http://www.tty1.net/userial/

0 instance value inbuf
0 instance value outbuf
0 instance value inbuf2

: alloc-buffers  ( -- )
   h# 10 dma-alloc to inbuf
   h# 10 alloc-mem to inbuf2
   h# 10 dma-alloc to outbuf
;
: free-buffers  ( -- )
   inbuf h# 10 dma-free
   inbuf2 h# 10 free-mem
   outbuf h# 10 dma-free
;

: open  ( -- flag )
   set-device
   device set-target
   reset?  if
      configuration set-config  if
         ." userial: set-config failed" cr
         false exit
      then
      bulk-in-pipe bulk-out-pipe reset-bulk-toggles
   then
   alloc-buffers
   inbuf h# 10 bulk-in-pipe begin-bulk-in
   true
;
: received?  ( -- false | adr len true )
   bulk-in?  if  drop restart-bulk-in  false  exit  then  ( actual )
   \ Workaround for a deficiency, since fixed, in UHCI get-actual
   dup h# 800 =  if                          ( null-data-code )
      drop restart-bulk-in                   ( )
      inbuf2 0 true                          ( adr 0 true )
      exit
   then                                      ( actual )
   dup  if                                   ( actual )
      >r                                     ( r: actual )
      inbuf inbuf2 r@ move                   ( r: actual )
      restart-bulk-in                        ( r: actual )
      inbuf2 r> true                         ( adr len true )
   then                              ( false | adr len true )
;
: write  ( adr len -- actual )
   tuck  begin  dup  while                ( len adr rem )
      2dup h# 10 min  tuck                ( len adr rem  this  adr this )
      outbuf swap move                    ( len adr rem  this )
      outbuf over                         ( len adr rem  this  outbuf this )
      bulk-out-pipe bulk-out  if          ( len adr rem  this )
         drop nip                         ( len rem )
         -                                ( actual )
         exit
      then                                ( len adr rem  this )
      /string                             ( len adr' rem' )
   repeat                                 ( len adr' rem' )
   nip -                                  ( actual )
;
: cmd  ( adr len -- )
   write  drop  " "n" write drop
;
: res  ( -- )
   begin  received?  while  type  repeat
;
