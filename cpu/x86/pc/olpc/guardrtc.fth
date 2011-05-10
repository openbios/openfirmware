\ See license at end of file
purpose: Real-Time Clock Anti-rollback for security

\ The entry points are:
\ rtcar-enabled?  ( -- flag )
\   True if an "rt" tag is present in manufacturing data, thus enabling anti-rollback
\ rtc-rollback?  ( -- flag )
\   True if either a rollback attach is detected or the timestamp area is corrupt
\ fix-rtc-timestamps  ( data$ -- )  \ "count old-timestamp new-timestamp"
\   Restores valid data in the timestamp area according to data$

\ Layout of timestamp area:
\   Bytes 0-3  - 4-byte rewrite count - little-endian
\   Bytes 4-8  - Timestamp 0
\   Bytes 9-13 - Timestamp 1
\   ...
\   Bytes 32759-32763 - Timestamp 6552
\ Each timestamp is a 4-byte little-endian "unixtime" (seconds since
\ epoch), followed by a 1-byte xor checksum of the preceding 4 bytes ^ 0x55

5 constant /timestamp

\ First 4 bytes are the write counter base value
/l constant timestamp-start
d# 32768 timestamp-start -  /timestamp / constant #timestamps/rewrite
#timestamps/rewrite /timestamp * constant /timestamps

0 value timestamp-offset
0 value rtc-timestamp
0 value new-timestamp
: +tsbuf  ( offset -- adr )  mfg-data-buf +  ;
: timestamp-adr  ( -- adr )  timestamp-offset +tsbuf timestamp-start +  ;
: compute-check-byte  ( timestamp -- check )
   lbsplit xor xor xor  h# 55 xor
;
: count-base@  ( -- n )  0 +tsbuf le-l@  ;
: count-base!  ( n -- )  0 +tsbuf le-l!  ;
: #timestamps  ( timestamp-offset -- n )
   timestamp-offset /timestamp /     ( #buffered-timestamps )
   count-base@ +                     ( n )
;
: timestamp-bad?  ( -- timestamp error? )
   timestamp-adr le-l@            ( timestamp )
   dup compute-check-byte         ( timestamp computed-check )
   timestamp-adr la1+ c@  <>      ( timestamp error )
;
: set-timestamp-offset  ( -- error? )
   0 to timestamp-offset                                  ( )
   0 to rtc-timestamp
   begin  timestamp-offset /timestamps <>  while          ( )
      timestamp-adr le-l@ h# ffffffff =  if               ( )
         \ Verify that the rest of the area is all ff too
         timestamp-adr  /timestamps timestamp-offset -    ( adr len )
         h# ff  bskip  0<>                                ( error? )
	 exit                                             ( -- error? )
      then                                                ( )
      timestamp-bad?  if                                  ( timestamp )
	 drop                                             ( )
         true exit  \ Bad checksum                        ( -- error? )
      else                                                ( timestamp )
	 to rtc-timestamp                                 ( )
      then                                                ( )

      timestamp-offset /timestamp +  to timestamp-offset  ( )
   repeat                                                 ( )
   false                                                  ( )
;

: commit-timestamp-area  ( -- )
   flash-open           ( )
   (put-mfg-data)       ( )
   flash-close          ( )
;
: flash-write-some  ( adr len offset -- )
   flash-open           ( adr len offset )
   flash-write          ( )
   flash-close          ( )
;
: init-timestamp-area  ( base -- )
   count-base!                                            ( )

   timestamp-start +tsbuf  /timestamps  h# ff  bskip  if  ( )
      \ There is junk in the timestamp area so we must erase and rewrite
      timestamp-start +tsbuf  /timestamps  h# ff fill  ( )
      commit-timestamp-area
   else
      \ The timestamp area is already erased, so we can write without erasing
      mfg-data-buf /l  mfg-data-offset  flash-write-some
   then

   0 to timestamp-offset
;
: rewrite-timestamp-area  ( -- )
   \ Fill the timestamp area with ff's
   timestamp-start +tsbuf  /timestamps  /timestamp /string  h# ff fill

   \ Update the rewrite count
   count-base@ #timestamps/rewrite + count-base!

   \ Perform an erase and rewrite on the mfg data area
   commit-timestamp-area
;
: update-timestamp  ( -- )
   timestamp-offset /timestamps =  if      ( )
      rewrite-timestamp-area               ( )
      0 to timestamp-offset                ( )
   then

   new-timestamp  dup timestamp-adr le-l!         ( unixtime )
   compute-check-byte  timestamp-adr la1+ c!      ( )
   timestamp-adr /timestamp   timestamp-offset timestamp-start + mfg-data-offset +  flash-write-some  ( )
;

: find-timestamp  ( -- status )
   get-mfg-data                            ( )

   count-base@ h# ffffffff =  if           ( )
      0 init-timestamp-area                ( )
   then                                    ( )

   set-timestamp-offset  if                ( )
      \ There is bad data after the last timestamp, if any
      2 exit                               ( -- 1 )
   then                                    ( )

   timestamp-offset 0=  if                 ( )
      \ There is no data in the timestamp area
      1 exit                               ( -- 2 )
   then                                    ( )
   0                                       ( -- 0 )
;
: ?update-timestamp  ( status -- status' )
   dup  1 >  if  exit  then                 ( status )

   time&date >unix-seconds to new-timestamp ( status )

   new-timestamp rtc-timestamp <=  if       ( status )
      \ Time went backwards
      drop 3 exit                           ( -- status' )
   then                                     ( status )

   update-timestamp                         ( status )
;

1 buffer: byte-buf
: encode-byte  ( b -- )  byte-buf c! byte-buf 1 encode-bytes  ;
: +encode-bytes  ( prop$ $ -- prop$' )  encode-bytes encode+  ;

: make-timestamp-property  ( -- )
   rtc-timestamp 0=  if  exit  then
   " /chosen" find-package drop push-package  ( )
   rtc-timestamp unix-seconds>                ( s m h d m y )
   push-decimal                               ( s m h d m y )
   #timestamps (.) encode-bytes               ( s m h d m y prop$ )
   " ," +encode-bytes  rot (.4) +encode-bytes ( s m h d m prop$ )
   " -" +encode-bytes  rot (.2) +encode-bytes ( s m h d prop$' )
   " -" +encode-bytes  rot (.2) +encode-bytes ( s m h prop$' )
   " @" +encode-bytes  rot (.2) +encode-bytes ( s m prop$' )
   " :" +encode-bytes  rot (.2) +encode-bytes ( s prop$' )
   " :" +encode-bytes  rot (.2) +encode-bytes ( prop$' )
   " "(00)" +encode-bytes                     ( prop$' )
   pop-base                                   ( )
   
   " rtc-timestamp" (property)                ( )
   pop-package
;
: make-status-property  ( value$ -- )
   " /chosen" find-package drop push-package  ( value$ )
   encode-string  " rtc-status"  (property)   ( )
   pop-package
;

: rtcar-enabled?  ( -- flag )
   " rt" find-tag  if      ( data$ )
      2drop true           ( flag )
   else                    ( )
      false                ( flag )
   then                    ( flag )
;

: rtc-rollback?  ( -- flag )
   rtcar-enabled?  0=  if  exit  then

   find-timestamp            ( status )
   ?update-timestamp         ( status' )
   make-timestamp-property   ( status )
   case
      0  of  " ok"        make-status-property  false  endof
      1  of  " empty"     make-status-property  false  endof
      2  of  " residue"   make-status-property  true   endof
      3  of  " rollback"  make-status-property  true   endof
      ( default )  true swap
   endcase
;

: parse-field  ( val$ delimiter expected-length -- val$' field$ )
   >r  left-parse-string   ( val$' field$ )
   dup r> <>  throw
;
\ Throws an error if either a number is unparsable or out of range
: decode-number  ( field$ min max -- n )
   2>r                             ( field$ r: min max )
   push-decimal $number pop-base   ( n error? r: min max )
   throw                           ( n r: min max )
   dup  2r> between 0=  throw      ( n )
;

: decode-timestamp  ( val$ -- s m h d m y )
   [char] - 4 parse-field   d# 2000 d# 2099 decode-number >r   ( val$' r: y )
   [char] - 2 parse-field  1 d# 12 decode-number >r   ( val$' r: y m )
   [char] @ 2 parse-field  1 d# 31 decode-number >r   ( val$' r: y m d )
   [char] : 2 parse-field  0 d# 23 decode-number >r   ( val$' r: y m d h )
   [char] : 2 parse-field  0 d# 59 decode-number >r   ( val$' r: y m d h m )
   dup 2 <> throw          0 d# 59 decode-number >r   ( r: y m d h m s )
   r> r> r> r> r> r>                                  ( s m h d m y )
;
: fix-rtc-timestamps  ( data$ -- )  \ "count old-ts new-ts"  e.g. 2011-10-12,00:23:45
   bl left-parse-string                       ( rem$ count$ )

   0 h# 7fffffff ['] decode-number catch  if  ( rem$ x x x x )
      4drop 2drop  ." Bad count format" cr    ( )
      exit                                    ( -- )
   then                                       ( rem$ count )
   -rot                                       ( count rem$ )

   find-timestamp                             ( count rem$ )

   bl left-parse-string                       ( count rem$ old-timestamp$ )
   2dup " no-timestamp" $=  if                ( count rem$ old-timestamp$ )
      2drop                                   ( count rem$ )
      rtc-timestamp  if                       ( count rem$ )
	 3drop                                ( )
	 ." Old timestamp mismatch" cr        ( )
	 exit                                 ( -- )
      then
   else                                       ( count rem$ old-timestamp$ )
      ['] decode-timestamp catch  if          ( count rem$ x x )
	 5drop                                ( )
	 ." Bad timestamp format" cr          ( )
	 exit                                 ( -- )
      then                                    ( count rem$ s m h d m y )
   then                                       ( count rem$ s m h d m y )

   >unix-seconds                              ( count rem$ old-timestamp )
   rtc-timestamp <>  if                       ( count rem$ )
      3drop                                   ( )
      ." Old timestamp mismatch" cr           ( ) 
      exit                                    ( -- )
   then                                       ( count rem$ )
   rot init-timestamp-area                    ( rem$ )
   
   ['] decode-timestamp catch  if             ( x x )
      2drop  ." Bad timestamp format" cr      ( )
      exit                                    ( -- )
   then                                       ( s m h d m y )
   >unix-seconds to new-timestamp             ( )
   update-timestamp                           ( )
;

\ LICENSE_BEGIN
\ Copyright (c) 2011 FirmWorks
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
