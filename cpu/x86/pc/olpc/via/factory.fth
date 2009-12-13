\ See license at end of file
purpose: Factory test mode definitions

0 value test-station
: smt-test?    ( -- )  test-station 1 =  ;
: final-test?  ( -- )  test-station 4 5 between  ;
: decode-ts  ( adr len -- station# )
   2dup " SMT"    $=  if  2drop 1 exit  then
   2dup " ASSY"   $=  if  2drop 2 exit  then
   2dup " DL"     $=  if  2drop 3 exit  then
   2dup " RUNIN"  $=  if  2drop 4 exit  then
   2dup " FINAL"  $=  if  2drop 5 exit  then
   2dup " SHIP"   $=  if  2drop 6 exit  then
   2dup " FQA"    $=  if  2drop 7 exit  then
   ." Unknown value in TS tag" cr
   2drop 0
;
: set-test-station  ( -- )
   " TS" find-tag  if         ( adr len )
      ?-null                  ( name$ )
      decode-ts               ( station# )
   else                       ( )
      ." Missing TS tag" cr
      \ Missing TS tag is treated as not factory mode
      0                       ( station# )
   then                       ( station# )
   to test-station
;

: set-boot-device  ( -- )
   " BD" find-tag  if         ( adr len )
      ?-null
      to boot-device
   then
;

0 0 2value factory-server$
: set-factory-server  ( -- )
   " MS" find-tag  if         ( adr len )
      ?-null
      to factory-server$
   then
;

0 value cifs-ih
d# 256 buffer: tempname-buf
: tempname$  ( -- adr len )  tempname-buf count  ;
: $call-cifs  ( ?? -- ?? )  cifs-ih $call-method  ;

: cifs-write  ( adr len -- )  " write" $call-cifs  drop  ;

: cifs-connect  ( -- )
   factory-server$ open-dev to cifs-ih
   cifs-ih 0= abort" Cannot open SMB share"
;
: cifs-disconnect  ( -- )
   cifs-ih  if  cifs-ih close-dev  0 to cifs-ih  then
;

: open-temp-file  ( filename$ -- )
   tempname-buf place
   
   tempname$  " $create" $call-cifs  abort" Cannot open temp file"
   cifs-ih 0= abort" Can't open temp file on manufacturing server"
;

: put-key-line   ( $ -- )  cifs-write  " "r"n" cifs-write  ;
: put-key+value  ( value$ key$ -- )  cifs-write  put-key-line  ;
: submit-file  ( subdir$ -- )
   " flush" $call-cifs abort" CIFS flush failed"
   " close-file" $call-cifs  abort" CIFS close-file failed"
   tempname$  2swap  " %s\\%s" sprintf  ( new-name$ )
   tempname$  2swap  " $rename" $call-cifs abort" CIFS rename failed"   
;
: get-response  ( subdir$ -- adr len )
   tempname$  2swap  " %s\\%s" sprintf  ( response-name$ )
   d# 10 0 do                           ( response-name$ )
      d# 1000 ms                        ( response-name$ )
      2dup  0 " open-file" $call-cifs  0=  if         ( response-name$ )
         2drop                          ( )
         " size" $call-cifs             ( d.size )
         abort" Size is > 4 GB"         ( size )
         dup alloc-mem  swap            ( adr len )
\        0. " seek" $call-cifs drop     ( adr len )
         2dup " read" $call-cifs        ( adr len actual )
         over <> abort" CIFS read of response file filed"
         unloop exit
      then
   loop                                 ( response-name$ )
   2drop                                ( )
   true abort" Server did not respond with 10 seconds"
;

: .instructions  ( adr len -- )
   cr blue-letters  type  black-letters  cr
;
: .problem  ( adr len -- )
   red-letters type  black-letters cr
;

: scanner?  ( -- flag )
   " usb-keyboard" expand-alias  if  2drop true  else  false  then
;   
: wait-scanner  ( -- )
   scanner?  0=  if
      " Connect USB barcode scanner"  .instructions
      begin  d# 1000 ms  silent-probe-usb  scanner?  until
   then
 ;
: wired-lan?  ( -- flag )
   " /usb/ethernet" locate-device  if  false  else  drop true  then
;
: wait-lan  ( -- )
   wired-lan?  0=  if
      " Connect USB Ethernet Adapter" .instructions
      begin  d# 1000 ms  silent-probe-usb  wired-lan?  until
   then
;
: usb-key?  ( -- flag )
   " /usb/disk" locate-device  if  false  else  drop true  then
;
: wait-usb-key  ( -- )
   usb-key?  0=  if
      " Connect USB memory stick" .instructions
      begin  d# 1000 ms  silent-probe-usb  usb-key?  until
   then
;
: stall  ( -- )  begin  halt  again  ;

: accept-to-buf  ( buf len -- actual )
   over 1+ swap accept  ( buf actual )
   tuck swap c!         ( actual )
;

: clear-mfg-buf  ( -- )  mfg-data-buf  /flash-block  h# ff fill  ;

\ Remove possible trailing carriage return from the line
: ?remove-cr  ( adr len -- adr len' )
   dup  if                        ( adr len )
      2dup + 1- c@ carret =  if   ( adr len )
         1-
      then
   then
;

: put-ascii-tag  ( value$ name$ -- )
   2swap  dup  if  add-null  then  2swap  ( value$' key$ )
   ($add-tag)                             ( )
;

: nocase-$=  ( $1 $2 -- flag )
   rot tuck <>  if       ( adr1 adr2 len2 )
      3drop false exit   ( -- false )
   then                  ( adr1 adr2 len2 )
   caps-comp 0=          ( flag )
;



stand-init:
   set-boot-device
   set-test-station
   set-factory-server
;

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
