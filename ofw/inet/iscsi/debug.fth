purpose: iSCSI buffer dumps
\ See license at end of file

\ show field values
: .op        ( buf -- )  ." opcode " >opcode c@ .h  ;
: .flags     ( buf -- )  ." flags "  >flags  c@ .h  ;
: .status    ( buf -- )  ." status " >status c@ .h  ;
: .dsl       ( buf -- )  ." DSlength " >AHSlen be-l@ h# 00ffffff and .d  ;
: .lun8      ( buf -- )  ." lun " >lun dup be-l@ 8u.h ." ." 4 + be-l@ 8u.h space ;
: .isid      ( buf -- )  ." isid " >isid dup 2+ be-l@ swap be-w@ (.12) type space ;
: .tsih      ( buf -- )  ." tsih " >tsih be-w@ .h  ;
: .itt       ( buf -- )  ." itt " >itt be-l@ .h  ;
: .ttt       ( buf -- )  ." ttt " >ttt be-l@ .h  ;
: .rtt       ( buf -- )  ." rtt " >rtt be-l@ .h  ;
: .cid       ( buf -- )  ." cid " >cid be-l@ .h  ;
: .edl       ( buf -- )  ." Exp Data Length " >expdatalen be-l@ .h  ;
: .snack     ( buf -- )  ." SNACK " >snack be-l@ .h  ;
: .cmdsn     ( buf -- )  ." CmdSN " >cmdsn be-l@ .h  ;
: .statsn    ( buf -- )  ." StatSN " >statsn be-l@ .h  ;
: .xcmdsn    ( buf -- )  ." ExpCmdSN " >expcmdsn be-l@ .h  ;
: .xstatsn   ( buf -- )  ." ExpStatSN " >expstatsn be-l@ .h  ;
: .refcmdsn  ( buf -- )  ." RefCmdSN " >refcmdsn be-l@ .h  ;
: .maxcmdsn  ( buf -- )  ." maxCmdSN " >maxcmdsn be-l@ .h  ;
: .r2tsn     ( buf -- )  ." R2TSN " >r2tsn be-l@ .h  ;
: .xdatasn   ( buf -- )  ." ExpDataSN " >expdatasn be-l@ .h  ;
: .datasn    ( buf -- )  ." DataSN " >datasn be-l@ .h  ;
: .brrc      ( buf -- )  ." BRRC " >brrc be-l@ .h  ;
: .rc        ( buf -- )  ." RC " >rc be-l@ .h  ;
: .offset    ( buf -- )  ." Buffer Offset " >bufferoffset be-l@ .h  ;
: .ddtl      ( buf -- )  ." Desired Data Transfer Length " >DDTlen be-l@ .h  ;

: .ahsl  ( buf -- )
   >AHSlen c@ dup if
      ." AHSlength " .h
   else
      drop
   then
;
: .cdb    ( buf -- )  cr ." CDB " >CDB h# 10 dump  ;
: .login-status   ( buf -- )
   ." login status " >loginstat dup be-w@ .h
   c@ 
   case
      0 of  ." success" endof
      1 of  ." target moved error"  endof
      2 of  ." initiator error"  endof
      3 of  ." target error"  endof
      ." unknown"
    endcase
    cr
;

\ display packets

\ basic header segment
: .bhs   ( buf -- )
   dup .op  dup .flags
   dup >opcode c@ h# 40 and if  ." immediate "  then
   dup >flags  c@ h# 80 and if  ." final "  then
   dup .ahsl  dup .dsl  .itt  cr
;

\ command pdu
: .cmd   ( -- buf )
   outbuf dup .bhs  dup .cmdsn  dup .xstatsn  cr
;

\ response pdu
: .resp   ( -- buf )
   inbuf dup .bhs  dup .statsn  dup .xcmdsn  dup .maxcmdsn  cr
;

: .scsicmd   ( -- )
   ." SCSI Command "   .cmd 			( buf )
   dup .lun8  dup .edl  .cdb cr
;
: .scsiresp   ( -- )
   ." SCSI Response "  .resp 			( buf )
   dup .snack  dup .xdatasn  dup .brrc  .rc cr
;
: .tmfrq   ( -- )
   ." Task Request "   .cmd 			( buf )
   dup .lun8  dup .rtt  .refcmdsn  cr
;
: .tmfr   ( -- )
   ." Task Response "  .resp drop cr
;
: .scsidout   ( -- )
   ." SCSI Data Out "  .cmd 			( buf )
   dup .lun8  dup .ttt  dup .datasn
   .offset cr
;
: .scsidin   ( -- )
   ." SCSI Data In "   .resp 			( buf )
   dup .lun8  dup .ttt  dup .datasn
   dup .offset  .rc cr
;
: .r2t   ( -- )
   ." Ready To Transfer "  .resp 		( buf )
   dup .lun8  dup .ttt  dup .r2tsn  dup .offset  .ddtl  cr
;
: .async   ( -- )
   ." Async Event "   .resp 			( buf )
   dup .lun8  ." type " >async c@ .h  cr
;
: .textrq   ( -- )
   ." Text Request "  .cmd 			( buf )
   dup .lun8  .ttt  cr
;
: .textr   ( -- )
   ." Text Response "  .resp 			( buf )
   dup .lun8  .ttt  cr
;
: .loginrq   ( -- )
   ." Login Request "  .cmd 			( buf )
   dup .isid  dup .tsih  .cid  cr
;
: .login-response   ( -- )
   ." Login Response "  .resp 			( buf )
   dup .isid  dup .tsih  cr 			( buf )
   .login-status 				( )
   flags@ dup 2 >> 3 and ." stage " .		( flags )
   h# 80 and 0= if ." no " then ." transition " cr
;
: .logoutrq   ( -- )
   ." Logout Request " .cmd 			( buf )
   .cid  cr
;
: .logoutr   ( -- )
   ." Logout Response " .resp			( buf )
   dup >response c@ 0= if  ." logout successful" cr then
   >waittime	     	       	      		( wt )
   ." time to wait " dup be-w@ .
   ." time to retain " 2+ be-w@ .  cr
;
: .snackrq   ( -- )
   ." SNACK Request "   .cmd			( buf )
   dup .lun8  dup .ttt
   ." Begin Run " dup >begrun be-l@ .h
   ." Run Length " >runlen be-l@ .h  cr
;
: .reject   ( -- )
   ." Reject "   .resp				( buf )
   dup .datasn
   ." reason " >response c@ .h  cr
;
: .nopout   ( -- )
   ." NOP Out "    .cmd				( buf )
   dup .lun8  .ttt  cr
;
: .nopin   ( -- )
   ." NOP In "   .resp				( buf )
   dup .lun8  .ttt  cr
;

\ display the data segment, assuming it consists of null terminated strings
: showbufdata   ( a -- ) 
   dup >AHSlen be-l@ h# 00ff.ffff and      ( a dslen )
   dup 0= if  2drop exit then
    
   d# 1024 min	\ safety
    
   swap >Data swap bounds ?do
      i c@ dup if  emit  else  drop cr  then
   loop
;

\ dump the buffers
: dump-got   ( actual -- )
   verbose? 0= if  drop exit  then  	( actual )
    
   dup /bhs < if
      ." received " .d ." bytes partial header " cr  inbuf /bhs dump cr
      exit
   then
    
   ." received header " cr  inbuf /bhs dump cr		( actual )
   ." plus " dup /bhs - .d ." bytes of data" cr	( actual )
   inbuf swap /bhs /string dump cr cr
;
: dump-sent   ( a n -- )
   verbose? 0= if  2drop exit   then

   ." sent header "  cr  outbuf /bhs dump cr			( a n )
   dup if
      ." plus " 4 round-up dup .d ." bytes of data" cr	( a n )
      2dup  d# 512 min dump  cr
   then
   cr
   2drop
;

\ display a packet
: show-in-pdu   ( -- )
   debug? 0= if  exit  then

   inbuf >opcode c@  h# 3f and
   case
      h# 20 of   .nopin            endof
      h# 21 of   .scsiresp         endof
      h# 22 of   .tmfr             endof
      h# 23 of   .login-response   endof
      h# 24 of   .textr            endof
      h# 25 of   .scsidin          endof
      h# 26 of   .logoutr          endof
      h# 31 of   .r2t              endof
      h# 32 of   .async            endof
      h# 3f of   .reject           endof
      ( default )
      .resp
      true abort" invalid target packet"
   endcase
   cr
;
: separator   ( $tag -- )
   debug? 0= if  2drop exit  then

   type  ."  -----------------------------------------" cr
;
: get-show-pdu   ( -- actual )
\    " get" separator  
   (get-pdu)	 ( actual )
   dup dump-got  show-in-pdu
\    " got" separator
;
' get-show-pdu to get-pdu

: show-out-pdu   ( -- )
   debug? 0= if  exit  then
    
   outbuf >opcode c@  h# 3f and
   case
      h# 00 of   .nopout      endof
      h# 01 of   .scsicmd     endof
      h# 02 of   .tmfrq       endof
      h# 03 of   .loginrq  outbuf showbufdata   endof
      h# 04 of   .textrq   outbuf showbufdata   endof
      h# 05 of   .scsidout    endof
      h# 06 of   .logoutrq    endof
      h# 10 of   .snackrq     endof
      ( default )
      .cmd cr
      true abort" invalid initiator packet"
    endcase
    cr
;
: send-show-pdu	  ( -- )
\   " send"  separator
   (send-pdu)
   outbuf >data dslen dump-sent
   show-out-pdu
\    " sent"  separator
;
' send-show-pdu to send-pdu

: send-show-pdu+data   ( a n -- )
\  " send"  separator
   2dup (send-pdu+data)
   dump-sent
   show-out-pdu
\  " sent"  separator
;
' send-show-pdu+data to send-pdu+data

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
