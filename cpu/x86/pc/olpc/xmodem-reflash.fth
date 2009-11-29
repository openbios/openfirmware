\ See license at end of file
purpose: Reflash OLPC Open Firmware using XMODEM serial download for the image

\ Interface definitions to splice xmodem into Open Firmware

true value serial-on?
: serial-off  ( -- )
   serial-on?  if
      fallback-in-ih remove-input
      fallback-out-ih remove-output
      false to serial-on?
   then
;
: serial-on  ( -- )
   serial-on?  0=  if
      fallback-in-ih add-input
      fallback-out-ih add-output
      true to serial-on?
   then
;

\ alias m-key? ukey?
alias m-key  ukey
alias m-emit uemit

: m-init  ( -- )
   h# 07  h# 3fa  pc!   \ Clear and enable FIFOs
   h# 80  h# 3fb  pc!   \ Select baud divisor port
   h# 00  h# 3f9  pc!   \ High divisor for 115200 baud
   h# 01  h# 3f8  pc!   \ Low divisor for 115200 baud
   h#  3  h# 3fb  pc!   \ 8n1
;

\ : panel-button?  ( -- flag )  key?  ;
: panel-button?  ( -- flag )  false  ;  \ We don't want to abort
: panel-d.  ( n -- )
   #out @ >r
   push-decimal
   <#  u# u# u#  ( bs hold bs hold bs hold ) u#> type
   pop-base
   r> #out !
;

: panel-msg:  create ",  does> count type  ;

" Abort"   panel-msg: abrt-msg     \ Abrt
" Cancel"  panel-msg: can-msg      \ CAn
: crc-msg ;  \ " Xmodem-CRC" panel-msg: crc-msg      \ crc
: done-msg ; \ " Done"    panel-msg: done-msg     \ donE
" Timeout" panel-msg: timeout-msg  \ tout
" "rr " panel-msg: r0-msg    \ Start of packet
" "rR " panel-msg: r1-msg    \ Start of packet big
" "     panel-msg: r2-msg    \ Inside try-receive

" Error"  panel-msg: giveup-msg   \ Err
" Loading diags    " panel-msg: upld-msg    \ UPLd
" OF"   panel-msg: of-msg         \ OF

: bogus-char  ( c -- )  ." Bogus: " .x  ;
: ignore-char  ( c -- )  ." Ignoring: " .x  ;

: ms>ticks  ( ms -- ticks )   ;

variable timer-init

: timed-in  ( -- true | char false ) \ get a character unless timeout
   get-msecs  timer-init @  +   ( time-limit )
   begin                        ( time-limit )
      ukey?  if  drop ukey false  exit   then  ( time-limit )
   dup get-msecs - 0<  until
   drop true
;


\ ---

\ CRC-16 table
base @ hex
create crc16tab
    0000 w,  1021 w,  2042 w,  3063 w,  4084 w,  50a5 w,  60c6 w,  70e7 w,
    8108 w,  9129 w,  a14a w,  b16b w,  c18c w,  d1ad w,  e1ce w,  f1ef w,
    1231 w,  0210 w,  3273 w,  2252 w,  52b5 w,  4294 w,  72f7 w,  62d6 w,
    9339 w,  8318 w,  b37b w,  a35a w,  d3bd w,  c39c w,  f3ff w,  e3de w,
    2462 w,  3443 w,  0420 w,  1401 w,  64e6 w,  74c7 w,  44a4 w,  5485 w,
    a56a w,  b54b w,  8528 w,  9509 w,  e5ee w,  f5cf w,  c5ac w,  d58d w,
    3653 w,  2672 w,  1611 w,  0630 w,  76d7 w,  66f6 w,  5695 w,  46b4 w,
    b75b w,  a77a w,  9719 w,  8738 w,  f7df w,  e7fe w,  d79d w,  c7bc w,
    48c4 w,  58e5 w,  6886 w,  78a7 w,  0840 w,  1861 w,  2802 w,  3823 w,
    c9cc w,  d9ed w,  e98e w,  f9af w,  8948 w,  9969 w,  a90a w,  b92b w,
    5af5 w,  4ad4 w,  7ab7 w,  6a96 w,  1a71 w,  0a50 w,  3a33 w,  2a12 w,
    dbfd w,  cbdc w,  fbbf w,  eb9e w,  9b79 w,  8b58 w,  bb3b w,  ab1a w,
    6ca6 w,  7c87 w,  4ce4 w,  5cc5 w,  2c22 w,  3c03 w,  0c60 w,  1c41 w,
    edae w,  fd8f w,  cdec w,  ddcd w,  ad2a w,  bd0b w,  8d68 w,  9d49 w,
    7e97 w,  6eb6 w,  5ed5 w,  4ef4 w,  3e13 w,  2e32 w,  1e51 w,  0e70 w,
    ff9f w,  efbe w,  dfdd w,  cffc w,  bf1b w,  af3a w,  9f59 w,  8f78 w,
    9188 w,  81a9 w,  b1ca w,  a1eb w,  d10c w,  c12d w,  f14e w,  e16f w,
    1080 w,  00a1 w,  30c2 w,  20e3 w,  5004 w,  4025 w,  7046 w,  6067 w,
    83b9 w,  9398 w,  a3fb w,  b3da w,  c33d w,  d31c w,  e37f w,  f35e w,
    02b1 w,  1290 w,  22f3 w,  32d2 w,  4235 w,  5214 w,  6277 w,  7256 w,
    b5ea w,  a5cb w,  95a8 w,  8589 w,  f56e w,  e54f w,  d52c w,  c50d w,
    34e2 w,  24c3 w,  14a0 w,  0481 w,  7466 w,  6447 w,  5424 w,  4405 w,
    a7db w,  b7fa w,  8799 w,  97b8 w,  e75f w,  f77e w,  c71d w,  d73c w,
    26d3 w,  36f2 w,  0691 w,  16b0 w,  6657 w,  7676 w,  4615 w,  5634 w,
    d94c w,  c96d w,  f90e w,  e92f w,  99c8 w,  89e9 w,  b98a w,  a9ab w,
    5844 w,  4865 w,  7806 w,  6827 w,  18c0 w,  08e1 w,  3882 w,  28a3 w,
    cb7d w,  db5c w,  eb3f w,  fb1e w,  8bf9 w,  9bd8 w,  abbb w,  bb9a w,
    4a75 w,  5a54 w,  6a37 w,  7a16 w,  0af1 w,  1ad0 w,  2ab3 w,  3a92 w,
    fd2e w,  ed0f w,  dd6c w,  cd4d w,  bdaa w,  ad8b w,  9de8 w,  8dc9 w,
    7c26 w,  6c07 w,  5c64 w,  4c45 w,  3ca2 w,  2c83 w,  1ce0 w,  0cc1 w,
    ef1f w,  ff3e w,  cf5d w,  df7c w,  af9b w,  bfba w,  8fd9 w,  9ff8 w,
    6e17 w,  7e36 w,  4e55 w,  5e74 w,  2e93 w,  3eb2 w,  0ed1 w,  1ef0 w,
base !

: updcrc  ( crc c -- crc' c )
   dup rot              ( c c crc )
   wbsplit  >r          ( c c low r: high )
   bwjoin               ( c low|c r: high )
   crc16tab  r> wa+ w@  ( c low|c table-entry )
   xor swap             ( crc' c )
;

: crc-send  ( crc adr len -- crc' )
   bounds  ?do  i c@ updcrc m-emit  loop
;

\ Assumes 0<len<64K
: crc-receive  ( crc adr len timeout -- true | crc' false )
   timer-init !
   bounds  ?do  timed-in  if  drop true unloop  exit  then  i c!  loop
;

: checksum-send  ( sum adr len -- sum' )
   bounds ?do  i c@ dup m-emit  +  loop
;



\ ---

purpose: X/YMODEM protocol for serial uploads and downloads

\ Xmodem protocol file transfer to and from memory
\ Commands:
\   send  ( adr len -- )
\   receive  ( adr maxlen -- adr len )

\ Interface to the serial line:
\
\ m-key?     -- flag
\       Flag is true if a character is available on the serial line
\ m-key      -- char
\       Gets a character from the serial line
\ m-emit        char --
\       Puts the character out on the serial line.

variable buf-start
variable buf-end
variable mem-start
variable mem-end

: putc  ( char -- )  buf-start @ c!  1 buf-start +!  ;

: end-delay  ( -- )  d# 200 ms  ;


vocabulary modem
only forth also modem also   modem definitions
base @ decimal

\ Common to both sending and receiving
0 value crc?   0 value big?   \ 0 value streaming?
variable #control-z's
d# 128 constant 128by
d# 1024 constant 1k
variable sector#
variable checksum
variable #errors    4 constant max#errors  variable #naks
: /sector  ( -- n )  big?  if  1k  else  128by  then  ;

\ ASCII control characters
    0 constant nul
    1 constant soh  \ Start of header; 128-byte packets
    2 constant stx  \ Start of header; 1024-byte packets
    4 constant eot
    6 constant ack
d# 21 constant nak
d# 24 constant can

: timeout!  ( ms -- )  ms>ticks   timer-init !  ;
: timeout:  \ name  ( milliseconds -- )
   create ,
   does>  @ timeout!
;
d# 3000 timeout: short-timeout  d# 6000 timeout: long-timeout
d# 60,000 timeout: initial-timeout
short-timeout

: gobble  ( -- ) \ eat characters until they stop coming
   d# 100 timeout!   begin  timed-in  0=  while  drop  repeat   long-timeout
;

variable done?
: rx-abort  ( -- )  end-delay  2 done? !  ;
: tx-abort  ( -- )  end-delay  2 done? !  true abort" aborted"  ;

\ It would be nice to use control C, but some operating systems don't pass it
: ?interrupt  ( -- )  \ aborts if user types control Z
   panel-button? if  can m-emit  abrt-msg tx-abort   then
;

\ Receiving

: receive-setup  ( adr maxlen -- )
   1 sector# !   #naks off   #control-z's off
;
: receive-error ( -- ) \ eat rest of packet and send a nak
   gobble
   1 #naks +!   #naks @ max#errors >  if
      can m-emit   giveup-msg rx-abort
   then
   nak m-emit
;

: receive-data  ( adr len -- error? )
   0 -rot bounds                               ( chk endadr startadr )
   crc?  if                                    ( crc endadr startadr )
      ?do  timed-in throw  updcrc  i c!  loop  ( crc )
      timed-in throw  timed-in throw           ( crc high low )
      swap bwjoin  <>                          ( error? )
   else                                        ( sum endadr startadr )
      ?do  timed-in throw  dup i c!  +  loop   ( sum )
      h# ff and  timed-in throw  <>            ( error? )
   then                                        ( error? )
;
variable got-sector#
: try-receive  ( adr maxlen -- adr maxlen actual-len )
   ( packet OK return:  none )
   ( retry return: throws -1 )
   ( done  return: throws 1 )
   ( abort return: throws 2 )
\   begin
      timed-in  throw
      case
         soh of  false to big?     r0-msg       endof  \ expected...
         stx of  true to big?      r1-msg       endof  \ expected...
         -1  of  timeout-msg -1 throw           endof
         nul of  1 throw                        endof  \ XXX check this
         can of  can-msg 2 throw                endof
         eot of  done-msg ack m-emit  1 throw   endof
        ( default) bogus-char -1 throw
      endcase                        ( adr maxlen )
\   again

   /sector <  if  2 throw  then      ( adr )
   timed-in                throw     ( adr sec# )
   timed-in                throw     ( adr sec# ~sec# )
   h# ff xor over <>       throw     ( adr sec# )
   got-sector# !                     ( adr )
   /sector  receive-data   throw     ( )

   ack m-emit
   sector# @ panel-d.
   1 sector# +!   \ Expected sector#

   #naks off
   /sector                           ( actual )
;
: !receive-packet  ( adr maxlen -- adr maxlen actual-len )
   r2-msg
   begin        ( adr maxlen )
      2dup ['] try-receive catch  case   ( adr maxlen [ actual 0 | x x n ] )
         \ The usual case: successful packet reception
         0  of  ( adr maxlen actual-len ) exit  endof

         ?interrupt

         \ Retryable error
         -1 of  ( adr maxlen x x ) 2drop receive-error             endof

         \ Handle termination conditions at a higher level
         ( default: adr maxlen x x n ) throw
      endcase   ( adr maxlen )
   again
;
: (receive)  ( adr0 maxlen -- adr0 len )
   receive-setup                      ( adr0 maxlen )
   gobble  nak m-emit                 ( adr0 maxlen )
   2dup                               ( adr0 maxlen adr0 maxlen )
   begin  dup 0>  while               ( adr0 maxlen adr remlen )
      ['] !receive-packet catch  case
         0 of            ( adr0 maxlen adr remlen actual-len )   \ Packet ok
            /string      ( adr0 maxlen adr' remlen' )
         endof
         1 of            ( adr0 maxlen adr remlen )   \ Normal end of transmission
            nip - exit   ( adr0 len )
         endof
         ( default ) can m-emit abrt-msg   throw
      endcase
   repeat                              ( adr0 maxlen adr remlen )
   can m-emit  of-msg  end-delay       ( adr0 maxlen adr remlen )
   nip -                               ( adr0 len )
;

\ Sending
modem definitions

: bail-out  ( -- )  can m-emit  giveup-msg tx-abort  ;
: wait-ack  ( -- proceed? )  \ wait for ack or can
[ifdef] streaming?  \ YMODEM-g
   streaming?  if
      m-key?  if  m-key can =  if  bail-out  then  then
      true exit
   then
[then]
   
   #errors off
   begin
      ?interrupt
      timed-in  if
         1 #errors +!  #errors @  max#errors >  if  bail-out  then
         timeout-msg false  exit
      then
      case
         ack of   #naks off  true exit  endof
         can of   can-msg tx-abort       endof
         nak of
            1 #naks +!  #naks @  max#errors >  if  bail-out  then
            false exit
         endof

         \ If we get a C, restart
         [char] C  of  sector# @ 1 <>  if  [char] C bogus-char  then  endof

         ( default) dup bogus-char
      endcase
   again
;
: start-receiver  ( -- )  \ wait for nak
   gobble
   upld-msg
   sector# off
   #naks off  false to crc?
   initial-timeout
   begin
      timed-in  if  timeout-msg tx-abort exit  then
      case
         can of   can-msg  tx-abort      endof
         nak of   true          endof
         [char] C  of  true to crc?  crc-msg  true  endof
[ifdef] streaming?
         [char] G  of  true to streaming?  true to crc?  true  endof
[then]
         nul of   false   endof   \ Startup transients generate nulls
         ( default)  dup ignore-char  false swap
      endcase
   until
   gobble long-timeout
;

: pad  ( -- b )  control Z  sector# @  0<>  and  ;
\ Send without confirmation
: send-packet  ( adr len big? -- )
   if  1k  stx  else  128by soh  then  ( adr len /sec start ) 
   m-emit                                       ( adr len /sec ) 

   \ Sector number
   sector# @  dup m-emit  h# ff xor m-emit      ( adr len /sec )

   over - 0  2swap                              ( #pad 0 adr len )
   crc?  if                                     ( #pad 0 adr len )
      crc-send                                  ( #pad crc )
      swap 0  ?do  pad updcrc m-emit  loop      ( crc' )
      0 updcrc updcrc drop                      ( crc' )
      wbsplit m-emit m-emit                     ( )
   else                                         ( #pad 0 adr len )
      checksum-send                             ( #pad sum )
      swap 0  ?do  pad  dup m-emit  +  loop     ( sum' )
      m-emit                                    ( )
   then                                         ( )
; 

\ Send until delivery confirmed
: deliver-packet  ( adr len big? -- )
   sector# @ panel-d.
   begin  3dup send-packet  wait-ack until
   3drop
;

: end-data  ( -- )
   begin  eot m-emit  wait-ack  until  \ End the protocol
   done-msg  end-delay
;

: sx  ( adr len -- )
   m-init
   start-receiver                    ( adr len )
   begin  dup 0>  while              ( adr len )
      1 sector# +!                   ( adr len )
      2dup  /sector min              ( adr len adr /this )
      tuck  big?  deliver-packet     ( adr len /this )
      /string                        ( adr' len' )
   repeat                            ( adr len )
   2drop                             ( )

   end-data
;

\ Info format:
\ <filename>NUL<decimal_size>[[ <decimal_modtime>] <octal_permsissions.]NUL...
: send-file  ( adr len name$ -- )
   m-init
   start-receiver
   here place                     ( adr len )
   " "(00)" here $cat             ( adr len )
   push-decimal dup (.) pop-base  ( adr len len$ )
   here $cat  here count          ( adr len batch$ )
   false deliver-packet           ( adr len )
   sx
;

: sb-end  ( -- )  start-receiver  " "(00)" false deliver-packet  end-delay  ;

: sb  ( adr len name$ -- )  send-file sb-end  ;

forth definitions

alias sx sx
: xmodem-receive  ( adr maxlen -- adr len )
   serial-off  cursor-off
   ['] (receive) catch    ( adr maxlen throw-code )
   serial-on   cursor-on  ( adr maxlen throw-code )
   abort" XMODEM reception aborted"
;

: xmodem-reflash  ( -- )
   ?enough-power
   ." Send the firmware image using the XMODEM (Checksum) protocol" cr
   flash-buf /flash xmodem-receive  nip   ( actual-len )
   ?image-valid  true to file-loaded?
   reflash
;
.( Type 'xmodem-reflash' to begin XMODEM reception) cr

only forth also definitions

base !

\ LICENSE_BEGIN
\ Copyright (c) 2009 FirmWorks
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
