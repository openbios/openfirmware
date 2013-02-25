
\ h# 00 constant config-reg                  \ 03 for 8688
\ h# 02 constant host-int-mask-reg           \ 04 for 8688
\ h# 03 constant host-intstatus-reg          \ 05 for 8688
\ h# 30 constant card-status-reg             \ 20 for 8688
\ h# 40 constant sq-read-base-addr-a0-reg   \ 10 for 8688
\ h# 41 constant sq-read-base-addr-a1-reg   \ 11 for 8688
\ h# 5c constant card-revision-reg	   \ ?? for 8688
\ h# 60 constant card-fw-status0-reg	   \ 40 for 8688
\ h# 61 constant card-fw-status1-reg	   \ 41 for 8688
\ h# 62 constant card-rx-len-reg		   \ 42 for 8688
\ h# 63 constant card-rx-unit-reg    	   \ 43 for 8688
\ h# 78 constant ioport0-reg		   \ 00 for 8688
\ h# 79 constant ioport1-reg		   \ 01 for 8688
\ h# 7a constant ioport2-reg		   \ 02 for 8688

h# 200 value SDIO_BLOCK_SIZE

\ The data in the result buffer does not include the event code
\ the command code, or the error status byte.
\ /result does not count those either, but only the excess result
\ bytes following the error status byte.

h# 80 buffer: result-buf
0 value /result

: copy-result  ( adr -- )
   \ "4 -" omits the event count, the ocf_ogf field, and the error status byte
   dup 1+ c@  4 - to /result      ( adr )
   \ "6 +" skips the event code, the length byte, and the 4 bytes cited above.
   6 +  result-buf /result move   ( )
;

: .vendor-cmd  ( adr ocf process? -- adr ocf process? )
   ." Vendor command " over .x         ( adr ocf process? )
   2 pick 5 + c@  ?dup  if             ( adr ocf process? error )
      ." failed with error " .x cr     ( adr ocf process? )
   else                                ( adr ocf process? )
      ." succeeded" cr                 ( adr ocf process? )
   then                                ( adr ocf process? )
;

h# 4e constant #events
create events  h# 4e /token * allot

: check-event#  ( event# -- )  #events >= abort" Too many events"   ;
: xt-set-event  ( event# xt -- )  over check-event#  events rot ta+  token!  ;
: set-event ( event# -- )  lastacf xt-set-event  ;
: UNKNOWN  ( -- )  ;
: UNUSED  ( n -- )  ['] UNKNOWN xt-set-event  ;

h# 00 UNUSED

: inquiry-complete     \ b.status
   cdump cr
; h# 01 set-event

: inquiry-result            \ b.nresp { bdaddr b.pscan-rep-mode b.pscan-period-mode b.pscan-mode b.dev-class[3] w.clock-offset }
   cdump cr
; h# 02 set-event

: conn-complete        \ b.status w.handle bdaddr b.link-type b.encr-mode
   cdump cr
; h# 03 set-event

: conn-request         \ bdaddr b.dev-class[3] b.link-type
   cdump cr
; h# 04 set-event

: disconn-complete     \ b.status w.handle b.reason
   cdump cr
; h# 05 set-event

: auth-complete        \ b.status w.handle
   cdump cr
; h# 06 set-event

: remote-name          \ b.status bdaddr b.name[248]
   cdump cr
; h# 07 set-event

: encrypt-change       \ b.status w.handle b.encrypt
   cdump cr
; h# 08 set-event

: change-link-key-complete \ b.status w.handle 
   cdump cr
; h# 09 set-event

: master-link-key-complete \ b.status w.handle b.flag
   cdump cr
; h# 0a set-event

: remote-features      \ b.status w.handle b.features[8]
   cdump cr
; h# 0b set-event

: remote-version       \ b.status w.handle b.lmp-ver w.manufacturer w.lmp-subver
   cdump cr
; h# 0c set-event

: qos-setup-complete   \ b.status w.handle { b.service-type L.token-rate L.peak-bandwidth L.latency L.delay-variation}
   cdump cr
; h# 0d set-event

: cmd-complete         \ b.ncmd w.opcode
   ." Cmd "  over 1+ le-w@ .x space
   3 /string cdump cr
; h# 0e set-event

: cmd-status           \ b.status b.ncmd w.opcode
   cdump cr
; h# 0f set-event

: hardware-error       \ b.errorcode
   cdump cr
; h# 10 set-event

: flush-occurred       \ w.handle
   cdump cr
; h# 11 set-event

: role-change          \ b.status bdaddr b.role
   cdump cr
; h# 12 set-event

: num-comp-pkts        \ b.num-hndl { w.handle w.count }
   cdump cr
; h# 13 set-event

: mode-change          \ b.status w.handle b.mode w.interval
   cdump cr
; h# 14 set-event

: return-link-keys     \ b.num { bdaddr, b.key[16] }
   cdump cr
; h# 15 set-event

: pin-code-req         \ bdaddr
   cdump cr
; h# 16 set-event

: link-key-req         \ bdaddr
   cdump cr
; h# 17 set-event

: link-key-notify      \ bdaddr b.link-key[16] b.key-type
   cdump cr
; h# 18 set-event

: loopback-command     \ [variable]
   cdump cr
; h# 19 set-event

: data-buffer-overflow \ b.link-type
   cdump cr
; h# 1a set-event

: max-slots-change     \ w.handle b.lmp-max-slots
   cdump cr
; h# 1b set-event

: clock-offset         \ b.status w.handle w.clock-offset
   cdump cr
; h# 1c set-event

: pkt-type-change      \ b.status w.handle w.pkt-type
   cdump cr
; h# 1d set-event

: qos-violation        \ w.handle   
   cdump cr
; h# 1e set-event

h# 1f UNUSED

: pscan-rep-mode       \ bdaddr b.pscan-rep-mode
   cdump cr
; h# 20 set-event

: flow-specification-complete \ b.status w.handle b.flags b.direction b.service-type b.token-rate l.token-bucket-size l.bandwidth l.latency
   cdump cr
; h# 21 set-event

: inquiry-result-with-rssi  \ b.nresp {bdaddr b.pscan-rep-mode b.pscan-period-mode b.dev-class[3] w.clock-offset S.rssi}
   cdump cr
; h# 22 set-event
   \ inquiry-info-with-rssi-and-pscan-mode \ b.nresp { bdaddr b.pscan-rep-mode b.pscan-period-mode b.pscan-mode b.dev-class[3] w.clock-offset S.rssi }

: remote-ext-features  \ b.status w.handle b.page b.max-page b.features[8]
   cdump cr
; h# 23 set-event

h# 2c h# 24 do  i UNUSED  loop

: sync-conn-complete   \ b.status w.handle bdaddr b.link-type b.tx-interval b.retrans-w.ndow. w.rx-pkt-len w.tx-pkt-len b.air-mode
   cdump cr
; h# 2c set-event

: sync-conn-changed    \ b.status w.handle b.tx-interval b.retrans-w.ndow. w.rx-pkt-len w.tx-pkt-len
   cdump cr
; h# 2d set-event

: sniff-subrate        \ b.status w.handle w.max-tx-latency w.max-rx-latency w.max-remote-timeout w.max-local-timeout
   cdump cr
; h# 2e set-event

: extended-inquiry-info   \ b.nresp { bdaddr b.pscan-rep-mode b.pscan-period-mode b.dev-class[3] w.clock-offset S.rssi b.data[240] }
   cdump cr
; h# 2f set-event

: key-refresh-complete \ b.status w.handle
   cdump cr
; h# 30 set-event

: io-capa-request      \ bdaddr
   cdump cr
; h# 31 set-event

: io-capa-reply        \ bdaddr b.capability b.oob-data b.authentication
   cdump cr
; h# 32 set-event

: user-confirm-req     \ bdaddr l.passkey
   cdump cr
; h# 33 set-event

: user-passkey-req     \ bdaddr
   cdump cr
; h# 34 set-event

: remote-oob-data-request \ bdaddr
   cdump cr
; h# 35 set-event

: simple-pair-complete \ b.status bdaddr
   cdump cr
; h# 36 set-event

h# 37 UNUSED

: link-supervision-timeout-changed \ w.handle w.timeout
   cdump cr
; h# 38 set-event

: enhanced-flush-complete \ w.handle
   cdump cr
; h# 39 set-event

h# 3a UNUSED

: user-passkey-notification \ bdaddr l.passkey
   cdump cr
; h# 3b set-event

: keypress-notification \ bdaddr b.type
   cdump cr
; h# 3c set-event

: remote-host-features \ bdaddr b.features[8]
   cdump cr
; h# 3d set-event

: le-meta              \ b.subevent
   cdump cr
; h# 3e set-event

\   1 le-connection-complete \ b.status w.handle b.role b.peer-type 6.peer-addr w.interval w.latency w.timeout b.accuracy
\   2 le-advertising-report  \ b.num { b.event-type b.addr-type 6.address b.datalen { b.data } S.rssi }
\   3 le-connection-update-complete \ b.status w.handle w.interval w.latency w.timeout
\   4 le-read-remote-used-features-complete \ b.status w.handle 8.features
\   5 le-long-term-key-request \ w.handle 8.random w.diversifier

h# 3f UNUSED

: physical-link-complete \ b.status b.plink
   cdump cr
; h# 40 set-event

: channel-selected     \ b.plink
   cdump cr
; h# 41 set-event

: disconnection-phys-link-complete \ b.status b.plink b.reason
   cdump cr
; h# 42 set-event

: physical-link-loss-early-warning \ b.plink b.reason
   cdump cr
; h# 43 set-event

: physical-link-recovery \ b.plink
   cdump cr
; h# 44 set-event

: logical-link-complete \ b.status w.llink b.plink b.flow-spec-id
   cdump cr
; h# 45 set-event

: disconnection-log-link-complete \ b.status w.llink b.reason
   cdump cr
; h# 46 set-event

: flow-spec-modify-complete \ b.status w.handle
   cdump cr
; h# 47 set-event

: num-comp-blocks      \ w.num-blocks b.num-hndl { w.handle w.pkts w.blocks }
   cdump cr
; h# 48 set-event

: amp-start-test      \ b.status b.scenario
   cdump cr
; h# 49 set-event

: amp-test-end        \ b.status b.scenario
   cdump cr
; h# 4a set-event

: amp-receiver-report \ b.ctlr-type b.reason l.event-type w.numfr
   cdump cr
; h# 4b set-event

: short-range-mode-change-complete \ b.status b.plink b.state
   cdump cr
; h# 4c set-event

: amp-status-change \ b.status b.amp-status
   cdump cr
; h# 4d set-event

: unwrap-event  ( adr len -- adr' len' event# )
   drop >r                         ( r: adr )
   r@ 2 +  r@ 1+ c@   r> c@        ( eadr elen event# )
;
: .event  ( adr len -- )
   ." Event: "                     ( adr len )
   unwrap-event                    ( adr' len' event# )
   dup #events >=  if              ( adr len event# )
      drop ." UNKNOWN "            ( adr len )
      cdump cr                     ( )
   else                            ( adr len event# )
      events swap ta+ token@       ( adr len xt )
      dup .name                    ( adr len xt )
      execute                      ( )
   then                            ( )
;

\ If it is a vendor event, copy the result into a dedicated buffer
\ instead of returning the data to the caller
: x-check-evtpkt  ( adr len -- process? )
   over c@ >r  2 /string  r>                 ( adr' len' type )
   h# e =   if  \ EV_CMD_COMPLETE            ( adr len )
      drop dup 1 + le-w@   d# 1024 /mod      ( adr ocf ogf )
      \ For now we ignore ocf, but we could check if its value is h# 5b -
      \ BT_CMD_MODULE_CFG_REQ - and do something to indicate completion
      h# 3f <>                               ( adr ocf process? )
      dup 0=  if                             ( adr ocf process? )
         2 pick  copy-result                 ( adr ocf process? )
         .vendor-cmd                         ( adr ocf process? )
      then                                   ( ocf process? )
      nip nip                                ( process? )
   else                                      ( adr len )
      2drop true                             ( process? )
   then
;
: check-evtpkt  ( adr len -- process? )
   .event false
;

0 value psmode
: handle-marvell-event  ( adr len -- process? )
   over c@  h# ff <>  if  2drop true exit  then  \ Check for Marvell event
   drop 2 +                               ( data-adr )
   dup c@   case                          ( data-adr type )

      h# 23 of   \ AUTO_SLEEP_MODE        ( data-adr )
         dup 2+ c@  if                    ( data-adr )
            ." PS Mode command failed" cr ( data-adr )
         else                             ( data-adr )
            dup 1+ c@  2 =  to psmode     ( data-adr )
         then                             ( data-adr )
         false                            ( data-adr process? )
      endof                               ( data-adr )

      h# 59 of   \ SLEEP_CONFIG           ( data-adr )
         dup 3 + c@  if                   ( data-adr )
            ." HSCFG command failed" cr   ( data-adr )
         then                             ( data-adr )
         false                            ( data-adr process? )
      endof                               ( data-adr type )

      h# 5a of   \ SLEEP_ENABLE           ( data-adr )
         dup 1+ c@  if                    ( data-adr )
            ." HS Enable command failed" cr   ( data-adr )
         else
            \ true to sleep-activated?
         then                             ( data-adr )
         false                            ( data-adr process? )
      endof                               ( data-adr type )

      h# 5b of   \ MODULE_CFG_REQ         ( data-adr )
         \ Pass on everything except MODULE_BRINGUP_REQ and MODULE_SHUTDOWN_REQ
         dup 1+ c@ h# f1 h# f2 between 0= ( data-adr process? )
      endof                               ( data-adr type )

      ( default )                         ( data-adr type )
         true swap                        ( data-adr process? type )
   endcase                                ( data-adr process? )

   nip                                    ( process? )
;

true instance value got-data?
0 instance value /data
0 instance value data

: copy-data  ( adr len  buf+ actual  -- actual )
   rot min      ( adr buf+ actual' )
   -rot swap    ( actual buf+ adr )
   2 pick move  ( actual )
;

h# 200 buffer: event-buf

d# 1000 instance value bt-timeout
: normal-timeout  ( -- )  d# 1000 to bt-timeout  ;

: timed-wait   ( -- adr len type )
   get-msecs bt-timeout +             ( time-limit )
   begin                              ( time-limit )
      dup get-msecs - 0< abort" Bluetooth timeout"   ( time-limit )
      " got-bt-packet?" $call-parent  ( time-limit [ dadr dlen type ] flag )
   until                              ( time-limit dadr dlen type )
   3 roll drop                        ( dadr dlen type )
   rot event-buf                      ( dlen type  dadr buf )
   3 pick move                        ( dlen type )
   event-buf -rot                     ( adr len type )
   " recycle-packet" $call-parent     ( adr len type )
;

0 instance value #cmds-allowed
: unwrap-cmd-complete  ( eadr elen -- adr len cmd# )
   over c@ to #cmds-allowed  ( eadr elen )
   3 /string                 ( adr len )
   over 2- le-w@             ( eadr elen cmd# ) 
;
: ?cmd-error  ( adr -- )
   c@  ?dup  if      ( error# )
     ." Command failed with error 0x" .x cr
   then 
;

: unwrap-cmd-status  ( eadr elen -- adr len cmd# )
   over 1+ c@ to #cmds-allowed  ( eadr elen )
   over ?cmd-error              ( eadr elen )
   4 /string                    ( adr len )
   over 2- le-w@                ( eadr elen cmd# ) 
;

: wait-event  ( -- eadr elen event# )
   begin  timed-wait 4 <>  while   ( dadr dlen )
      2drop                        ( )
   repeat                          ( dadr dlen )
   unwrap-event                    ( eadr elen event# )
;

\ adr,len is the unwrapped command response data
: wait-cmd-complete  ( cmd# -- adr len )
   >r                           ( r: cmd# )
   begin                        ( r: cmd# )
      wait-event h# e =  if     ( eadr elen r: cmd# )
         unwrap-cmd-complete    ( cadr clen this-cmd# r: cmd# )
            r@ =  if            ( cadr clen r: cmd# )
            r> drop exit        ( -- adr len )
         then                   ( cadr clen r: cmd# )
      then                      ( adr len r: cmd# )
      2drop                     ( r: cmd# )
   again
;

: wait-cmd-status  ( -- )
   begin                        ( )
      wait-event h# f =  if     ( eadr elen )
         unwrap-cmd-status      ( cadr clen this-cmd# )
         3drop exit             ( -- )
      then                      ( adr len )
      2drop                     ( )
   again
;

: le-3@  ( adr -- n )  le-l@ h# ffffff and  ;
: <c@  ( adr -- )  c@  dup h# 80 and  if  d# 256 -  then  ;
: .dbm  ( adr -- )  <c@  .d ." dBm "  ;
: show-pscan  ( adr -- )  ." Rep: " c@ .  ;
: show-class  ( adr -- )  ." Class: 0x"  le-3@ .x   ;
: show-bdaddr  ( adr -- )  ." BDADDR: " 6 cdump  ;
: show-offset  ( adr -- )  ." Offset: 0x"  le-w@ .x  ;
: show-rssi  ( adr -- )  ." RSSI: " .dbm  ;

: parse-inquiry  ( eadr elen -- )
   over c@ >r  1 /string  r>   ( adr' len' #responses )
   0  ?do                                    ( adr len )
      over show-bdaddr                       ( adr len )
      over 7 + show-pscan                    ( adr len )
      over 9 + show-class                    ( adr len )
      over d# 12 + show-offset               ( adr len )
      cr                                     ( adr len )
      d# 14 /string                          ( adr' len' )
   loop                                      ( adr len )
   2drop
;

: show-inquiry-rssi  ( adr -- )
   dup show-bdaddr          ( adr )
   dup 7 + show-pscan       ( adr len )
   dup 8 + show-class       ( adr )
   dup d# 11 + show-offset  ( adr )
   d# 13 + show-rssi        ( )
;
: parse-inquiry-rssi  ( eadr elen -- )
   over c@ >r  1 /string  r>    ( adr' len' #responses )
   0  ?do                       ( adr len )
      over show-inquiry-rssi cr ( adr len )
      d# 14 /string             ( adr' len' )
   loop                         ( adr len )
   2drop
;

: .tx-power  ( adr len -- adr len )  ." TX_Power: " over 1+ .dbm  ;
: .short-name  ( adr len -- adr len )  ." Short_Name: "  2dup 1 /string type  space  ;
: .long-name  ( adr len -- adr len )  ." Name: "  2dup 1 /string type  space  ;
: show-extended-inquiry  ( adr -- )
   begin  dup c@  dup  while        ( adr len )
      swap 1+ tuck c@               ( adr' len type )
      case                          ( adr len type )
         \ 1 is flags
         \ 2-7 are service UUIDs
            8 of  .short-name endof   ( adr len type )
            9 of  .long-name  endof   ( adr len type )
         h# a of  .tx-power   endof   ( adr len type )
         \ h# d-f are simple pairing OOB tags
         \ h# 10 is security manager TK value
	 \ h# 11 is security manager OOB flags
	 \ h# 12 is slave connection interval range
	 \ h# 14-15 are service solicitation UUIDS
	 \ h# 16 is service data
	 \ h# ff is manufacturer-specific data
      endcase                       ( adr len )
      +                             ( adr' )
   repeat                           ( adr len )
   2drop
;

: parse-extended-inquiry  ( eadr elen -- )
   over c@ >r  1 /string  r>      ( adr' len' #responses )
   0  ?do                         ( adr len )
      over show-inquiry-rssi cr   ( adr len )
      d# 14 /string               ( adr' len' )
      over show-extended-inquiry  ( adr len )
      cr cr                       ( adr len )
      h# f0 /string               ( adr len )
   loop                           ( adr len )
   2drop
;

\ adr,len is the unwrapped command response data
: process-inquiry  ( -- )
   begin                           ( )
      wait-event  case             ( eadr elen event# )
         1  of  \ Inquiry Complete ( eadr elen )
            drop ?cmd-error        ( )
	    exit
         endof

	 2  of  \ Inquiry Result   ( eadr elen )
            parse-inquiry          ( )
         endof                     ( eadr elen event# )

         h# f of \ Command Status  ( eadr elen )
            unwrap-cmd-status      ( eadr elen cmd# )
            drop  ." Inquiry results:" cr
         endof                     ( eadr elen event# )

         h# 22 of \ Inquiry Info w/RSSI  ( eadr elen )
	    parse-inquiry-rssi       ( )
         endof                       ( eadr elen event# )

         h# 2f of \ Extended Inquiry Info  ( eadr elen )
	    parse-extended-inquiry   ( )
         endof                       ( eadr elen event# )

         \ default                   ( eadr elen event# )
         \ nip nip                   ( event# )
         ." Skipping event# " dup .  ( eadr elen event# )
         2 spaces  -rot cdump cr     ( event# )
      endcase                        ( )
   again
;

: read  ( adr len -- actual )
   " got-bt-packet?" $call-parent  0=  if	( adr len )
      2drop  -2  exit
   then                                   ( adr len  dadr dlen type )

   case                                   ( adr len  dadr dlen type )

      h# fe  of     \ VENDOR              ( adr len  dadr dlen ) 
         2dup  handle-marvell-event   if  ( adr len  dadr dlen )
            copy-data                     ( actual )
         else                             ( adr len  dadr dlen )
	    4drop -1                      ( -1 )
         then                             ( actual )
      endof                               ( adr len  dadr dlen type )

      4  of         \ EVENT               ( adr len  dadr dlen )
         2dup check-evtpkt  if            ( adr len  dadr dlen )
            copy-data                     ( actual )
         else                             ( adr len  dadr dlen )
            4drop -1                      ( actual )
         then                             ( )
      endof                               ( adr len  dadr dlen type )

      2  of          \ ACLDATA            ( adr len  dadr dlen )
         copy-data                        ( actual )
      endof                               ( adr len  dadr dlen type )

      3  of          \ SCODATA            ( adr len )
         copy-data                        ( actual )
      endof                               ( adr len  dadr dlen type )

      ( default )                         ( adr len  dadr len  type )
         dup  ." Invalid BT SDIO packet type " .d cr
         nip nip nip nip -1 swap          ( actual type )
   endcase                                ( actual )

   " recycle-packet" $call-parent	  ( actual )
;
0 instance value outbuf
: host-to-card  ( adr len -- )
   SDIO_BLOCK_SIZE round-up    ( adr len' )
   2 0  do                     ( adr len )
      2dup " sdio-blocks!" $call-parent     ( adr len actual )
      over =  if  2drop unloop exit  then   ( adr len )
   loop                                     ( adr len )
   2drop                                    ( )
   true abort" BT SDIO write failed"        ( )
;

\ Command packet:
\  SDIO Type-A Transport header
\    0..2   Length of interface data (after byte 3)
\    3      Service ID: 1=HCI 2=ACL 3=SCO 4=Event FE=Vendor
\  Command header
\    4..5   Command code - OGF<<10 | OCF
\    6      Length of command data (after byte 6)
\  Command data
\    7..    Varies according to command

: 'cmd-data  ( -- adr )  outbuf 7 +  ;

: send-cmd  ( data-len ogf+ocf service-id -- )
   outbuf 3 + c!                    ( ogf+ocf )
   outbuf 4 + le-w!                 ( data-len )
   dup outbuf 6 + c!                ( data-len )
   3 +  dup outbuf le-w!            ( len-wo-transport-hdr )
   outbuf  swap 4 +  host-to-card   ( )
;

0 value x			\ Temporary variables to assist command creation
0 value /x

: 'x   ( -- adr )  x /x +  ;
: +x   ( n -- )  /x + to /x  ;
: +x$  ( $ -- )  'x swap dup +x move  ;
: +x3  ( n -- )  'x le-l!   3 +x  ;
: +xl  ( n -- )  'x le-l!  /l +x  ;
: +xw  ( n -- )  'x le-w!  /w +x  ;
: +xb  ( n -- )  'x c!     /c +x  ;
: +xerase  ( n -- )  'x over erase  +x  ;
: +xbdaddr  ( 'bdaddr -- )  6 +x$  ;

: cmd(  ( -- )  'cmd-data to x  0 to /x  ;
: )cmd  ( cmd# -- )  /x swap 1 send-cmd  ;
: )cmd-wait  ( cmd# -- )  dup )cmd  wait-cmd-complete   ;
: )vendor-cmd  ( cmd# -- )  /x swap h# fe send-cmd  ;
: )vendor-cmd-wait  ( cmd# -- adr len )  /x swap h# fe send-cmd  wait-cmd-complete  ;

: send-vendor-cmd  ( data-len cmd-code -- )
   h# fc00 or  h# fe  send-cmd  ( )  \ fe is Vendor command service ID
;
: send-hci-cmd  ( data-len cmd# -- )
   1 send-cmd   ( )  \ 1 is HCI command service ID
;
: do-hci-cmd  ( data-len cmd# -- adr len )
   tuck  1 send-cmd   ( cmd# )
   wait-cmd-complete  ( adr len )
;

: send-rev-cmd  ( -- )  0 h# f send-vendor-cmd  ;
: send-read-mem-cmd  ( reg# len -- )
   'cmd-data 4 + c!      ( reg# )
   'cmd-data le-l!       ( )
   5 h# 1 send-vendor-cmd
;

: +cmd   ( offset -- adr )  'cmd-data +  ;
: cmd!   ( n offset -- )  +cmd c!  ;

: send-rx-test  ( #reports 'bdaddr tx-am len #packets type rxfreq txfreq scenario -- )
   cmd(
   +xb              \ scenario
   +xb              \ txfreq
   +xb              \ rxfreq
   +xb              \ type
   +xl              \ #packets
   +xw              \ len
   +xb              \ tx-am
   +xbdaddr         \ bdaddr
   +xb              \ #reports
   
   h# fc05 )vendor-cmd-wait 2drop
;
: rx-test  ( -- )
\ #r  bdaddr         am  len   #p DM1 rxf txf  0pat
   0  " abcdef" drop  1  d# 10  1  3    0   1  1  send-rx-test
;
: giac  ( -- adr len )  " "(33 8b 9e)"  ;

: set-scan  ( mask -- )  cmd(  +xb  h# c1a )cmd-wait 2drop  ;
: enable-scanning  ( -- )  3 set-scan  ;
: disable-scanning  ( -- )  0 set-scan  ;

: set-inquiry-mode  ( 0|1|2-- )
   cmd( +xb h# c45 )cmd-wait drop ?cmd-error
;
: cancel-inquiry  ( -- )  cmd( h# 402 )cmd-wait drop ?cmd-error  ;

: x-send-inquiry  ( -- )
   h# 33 0 cmd!  h# 8b 1 cmd!  h# 9e 2 cmd!  \ General Inquiry LAC
   4 3 cmd!                                  \ 4 * 1.28 seconds
   1 4 cmd!                                  \ Return after first response
   5 h# 401 send-hci-cmd
;
: olpc-in-extended-inquiry?  ( adr -- flag )
   begin  dup c@  dup  while        ( adr len )
      swap 1+ tuck c@               ( adr' len type )
      8 9 between  if               ( adr len )
         2dup 1 /string             ( adr len remote-name$ )
         " OLPC-XO" $=  if          ( adr len )
            2drop true exit         ( -- true )
         then
      then                          ( adr len )
      +                             ( adr' )
   repeat                           ( adr len )
   2drop false                      ( false )
;
: olpc-xo-found?  ( eadr elen -- seen? )
   over c@ >r  1 /string  r>      ( adr' len' #responses )
   0  ?do                         ( adr len )
      d# 14 /string               ( adr' len' )
      over olpc-in-extended-inquiry?  if   ( adr len )
         2drop true unloop exit            ( -- true )      
      then                        ( adr len )
      h# f0 /string               ( adr len )
   loop                           ( adr len )
   2drop false                    ( false )
;

: wait-olpc-response  ( -- seen? )
   begin                           ( )
      wait-event  case             ( eadr elen event# )
         1  of  \ Inquiry Complete ( eadr elen )
            drop ?cmd-error        ( )
	    false exit             ( -- false )
         endof

         h# 2f of \ Extended Inquiry Info  ( eadr elen )
	    olpc-xo-found?  if     ( )
               cancel-inquiry      ( )
               true exit           ( -- true )
	    then
         endof                     ( eadr elen event# )

         \ default                 ( eadr elen event# )
         nip nip                   ( event# )
      endcase                      ( )
   again
;
: send-inquiry  ( -- )
   cmd(
   giac +x$          \ General Inquiry LAC
   d# 4 +xb          \ 4 * 1.28 seconds
   d# 16 +xb         \ #responses
   h# 401 )cmd
   wait-cmd-status
;
: inquire  ( -- )
   d# 10000 to bt-timeout
   send-inquiry
   process-inquiry
   normal-timeout
;
: inquire-olpc?  ( -- seen? )
   2 set-inquiry-mode
   d# 7000 to bt-timeout
   send-inquiry
   wait-olpc-response  ( seen? )
   normal-timeout
;

6 instance buffer: his-bdaddr
6 instance buffer: my-bdaddr
: read-bdaddr  ( -- )
   cmd( h# 1009 )cmd-wait   ( adr len )
   over c@  if              ( adr len )
      ." Bluetooth read-bdaddr command failed!" cr
      2drop exit
   then
   drop 1+  my-bdaddr 6 move
;

: .bdaddr  ( 'bdaddr -- )  6 cdump space  ;

0 instance value the-connection
: parse-connection  ( adr -- )
   dup c@  if  drop exit  then   ( adr )
   dup 1+ le-w@ to the-connection
   ." Connected to " dup 3 + .bdaddr  ( adr )
   dup 9 + c@  case
      0 of  ." SOC" endof
      1 of  ." ACL" endof
   endcase
   dup d# 10 + c@  if  ." Encrypted"  then
   cr
   drop
;
: wait-connected  ( -- )
   begin                           ( )
      wait-event  case             ( eadr elen event# )
         3  of  \ Connection Complete ( eadr elen )
            drop dup ?cmd-error    ( eadr )
            parse-connection
	    exit
         endof

         \ default                   ( eadr elen event# )
         \ nip nip                   ( event# )
         ." Skipping event# " dup .  ( eadr elen event# )
         2 spaces  -rot cdump cr     ( event# )
      endcase                        ( )
   again
;

h# cc18 value packet-types
0 value his-clock-offset
: connect  ( 'bdaddr -- )
   cmd(       ( 'bdaddr )
   +xbdaddr   ( )
   packet-types +xw
   0 +xb      \ Page Scan Mode R0
   0 +xb      \ Reserved, must be 0
   his-clock-offset +xw
   0 +xb      \ Disallow Role Switch
   h# 405 )cmd  wait-cmd-status
;
: wait-disconnected  ( -- )
   begin                           ( )
      wait-event  case             ( eadr elen event# )
         5  of  \ Disconnection Complete ( eadr elen )
            drop ?cmd-error        ( eadr )
	    exit
         endof

         \ default                   ( eadr elen event# )
         \ nip nip                   ( event# )
         ." Skipping event# " dup .  ( eadr elen event# )
         2 spaces  -rot cdump cr     ( event# )
      endcase                        ( )
   again
;

: disconnect  ( -- )
   cmd( the-connection +xw h# 13 +xb  h# 406 )cmd
   wait-cmd-status wait-disconnected
;

: set-name  ( name$ -- )
   cmd(  d# 248 over - -rot  +x$  +xerase  h# c13 )cmd-wait
   drop ?cmd-error
;
: get-name  ( -- name$ )
   cmd( h# c14 )cmd-wait
   over ?cmd-error               ( adr len )
   over c@  if  2drop  " " else  ( adr len )
      drop 1+ cscount            ( name$ )
   then                          ( name$ )
;
: wait-remote-name  ( -- name$ )
   begin                           ( )
      wait-event  case             ( eadr elen event# )
         7  of  \ Remote Name Request Complete ( eadr elen )
            drop dup ?cmd-error    ( eadr )
	    7 + cscount  exit      ( -- adr len )
         endof

         \ default                   ( eadr elen event# )
         \ nip nip                   ( event# )
         ." Skipping event# " dup .  ( eadr elen event# )
         2 spaces  -rot cdump cr     ( event# )
      endcase                        ( )
   again
;

: get-remote-name  ( offset rep bdaddr -- name$ )
   cmd( +xbdaddr +xb 0 +xb +xw h# 419 )cmd wait-cmd-status
   wait-remote-name  ( name$ )
;

: set-class  ( class# -- )
   cmd( +x3 h# c24 )cmd-wait drop ?cmd-error
;
: set-my-class  ( -- )  h# 10010c set-class  ;  \ Laptop computer, transfer

: set-extended-response  ( adr len fec? -- )
   cmd( +xb +x$ h# f0 /x 1- - +xerase  h# c52 )cmd-wait drop ?cmd-error
;
: set-olpc-xo-response  ( -- )
   " "(08 09)OLPC-XO"  false set-extended-response
;
: start-server  ( -- )
   " OLPC-XO" set-name  \ Not strictly necessary
   enable-scanning
   set-olpc-xo-response
;

: open   ( -- flag )
   my-space " set-address" $call-parent
   h# 200 " set-block-size" $call-parent
   h# 200 " alloc-buffer" $call-parent to outbuf
   my-args  " scan" $=  if  start-server  then
   true
;
: close  ( -- )
   disable-scanning
   outbuf h# 200 " free-buffer" $call-parent
;
: selftest  ( -- error? )
   open  0=  if
      ." Can't open Bluetooth device" cr
      true exit
   then
   inquire-olpc? 0=
   dup  if  ." No response from Bluetooth scan server" cr  then
;
also forth definitions
: scan-bt  ( -- )
   " /bluetooth:scan" open-dev       ( ihandle )
   ?dup  if                          ( ihandle )
      ." Bluetooth scan server started.  Type a key to exit" cr
      begin  key?  until  key drop   ( ihandle )
      close-dev                      ( )
   else
      ." Can't start Bluetooth scan server." cr
   then
;
previous definitions

\ Classes:
\ Information: 800000
\ Telephony:   400000
\ Audio        200000
\ Object xfer  100000
\ Capturing     80000
\ Rendering     40000
\ Networking    20000
\ Positioning   10000
\ Limited discoverable mode 2000
\ Major: Computer 100, Phone 200, LAN AP 300, AV 400, Peripheral 500, Imaging 600, Wearable 700, Toy 800, Misc 000, Uncategorized 1f00
\ Minor: major-dependent, e.g. 204 is cell phone
\ P2030 phone:  51 04 8c 68 30 2c  Class: 5a0204
