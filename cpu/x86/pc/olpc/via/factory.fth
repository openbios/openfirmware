\ See license at end of file
purpose: Factory test mode definitions

0 value test-station
: smt-test?    ( -- )  test-station 1 =  ;
: final-test?  ( -- )  test-station 5 =  ;
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
