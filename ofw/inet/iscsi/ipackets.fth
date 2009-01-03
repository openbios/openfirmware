purpose: incoming iSCSI packets
\ See license at end of file

hex

\ particular responses

defer nop-out
: nop-in   ( -- )
   @ttt  ttt -1 <>  if	\ this is not a replay
      nop-out	    	\ so we need to respond
   then
;

0 value status
0 value status-valid?
: scsi-response   ( -- )
   inbuf >response c@ 0= to status-valid?
   inbuf >status c@ to status
;

defer get-response
0 instance value read-address
0 instance value read-length
: scsi-data-in   ( -- )
   read-address 0= abort" read-address is not set"
   inbuf >data  read-address  read-length 
   inbuf >bufferoffset be-l@  /string   ( src dst len )
   @dslen min cmove
    
   flags@ h# 81 and h# 81 = 	\ F and S set?
   dup to status-valid?  if
      inbuf >status c@ to status
   else
      get-response	\ not final, get more
   then
;

: scsi-task-response   ( -- )
;
: login-response   ( -- )
   inbuf >loginstat c@ abort" login failed"

   inbuf >data @dslen parse-keys
;
: text-response   ( -- )
   inbuf >data @dslen parse-keys
;

: logout-response   ( -- )
;
: ready2transfer   ( -- )
;
: async-message   ( -- )
;
: reject   ( -- )
;
: (get-response)   ( -- )
   get-pdu	 ( actual )
   drop

   false to status-valid?
   inbuf >opcode c@  h# 3f and
   case
      h# 20 of  nop-in              endof
      h# 21 of  scsi-response       endof
      h# 22 of  scsi-task-response  endof
      h# 23 of  login-response      endof
      h# 24 of  text-response       endof
      h# 25 of  scsi-data-in        endof
      h# 26 of  logout-response     endof
      h# 31 of  ready2transfer      endof
      h# 32 of  async-message       endof
      h# 3f of  reject              endof
      ( default )
      true abort" invalid command packet"
   endcase
;
' (get-response) to get-response

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
