purpose: SCSI routines for iSCSI
\ See license at end of file

hex
 
\ XXX is this what we need?
: max-transfer ( -- n )
   " MaxRecvDataSegmentLength" get-num		( n )
   /max-transfer min
   dup 0= if  drop /max-transfer then
;


\ stubs

\ error code
fd constant bus-reset

0 value his-id
0 value his-lun
: set-address  ( unit target -- )
   to his-id  to his-lun
;

: set-timeout  ( msecs -- )  drop  ;


0 [if]
\ debug
: showkey   ( $name -- )
   2dup type space get-key type cr
;
: showkeys   ( -- )
   " MaxRecvDataSegmentLength" showkey
   " FirstBurstLength" showkey
   " MaxBurstLength" showkey
   ." max-transfer             " max-transfer .d
;	
[then]

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
