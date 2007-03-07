\ See license at end of file
purpose: 

hex
\ SCSI tape package implementing a "byte" device-type interface.
\ Supports both fixed-length-record and variable-length-record tape devices.

" byte"      device-type
" st"  encode-string  " compatible" property

fload ${BP}/dev/scsi/scsicom.fth  \ Utility routines for SCSI commands

hex

external

false instance value at-eof?      \ Turned on when read-blocks hits file mark

headers

false instance value fixed-len?   \ True if the device has fixed-length blocks
false instance value written?     \ True if the tape has been written

0 instance value /tapeblock       \ Max length for variable-length records,
                                  \ actual length for fixed length records.


create write-eof-cmd   h# 10 c, 1 c, 0 c, 0 c, 1 c, 0 c,

external

\ Writes a file mark

: write-eof  ( -- error? )  write-eof-cmd no-data-command  ;

headers


\ Writes a file mark it the tape has been written since the last seek
\ or rewind or write-eof.

: ?write-eof  ( -- )
   written?  if
      false to written?
      write-eof  if  ." Can't write file mark." cr  then
   then
;

create rewind-cmd  1 c, 1 c, 0 c, 0 c, 0 c, 0 c,

: rewind   ( -- error? )        \ Rewinds the tape
   ?write-eof
   false to at-eof?
   rewind-cmd no-data-command
;

create skip-files-cmd  h# 11 c, 1 c, 0 c, 0 c, 0 c, 0 c,

: skip-files  ( n -- error? )           \ Skips n file marks
   ?write-eof
   false to at-eof?                ( n )
   skip-files-cmd 2 + 3c!          ( )
   skip-files-cmd no-data-command  ( error? )
;

\ Asks the device its record length
\ Also determines fixed or variable length

create block-limit-cmd  5 c, 0 c, 0 c, 0 c, 0 c, 0 c,

: 2c@  ( addr -- n )  1 +  -c@  c@              bwjoin  ;

: get-record-length  ( -- )
   6  block-limit-cmd 6  short-data-command  if
      d# 512   true                 ( blocksize fixed-len )
   else                             ( buffer )
      dup 1 + 3c@  swap 4 + 2c@     ( max-len min-len )
      over =                        ( blocksize fixed-len? )
   then                             ( blocksize fixed-len? )
   to fixed-len?                    ( blocksize )

   dup parent-max-transfer u>  if   ( blocksize )
      drop parent-max-transfer      ( blocksize' )
   then                             ( blocksize )

   to /tapeblock                    ( )
;

true instance value first-install?      \ Used for rewind-on-first-open

\ Words to decode various interesting fields in the extended status buffer
\ Used by actual-#blocks

\ Incorrect length

: ili?  ( statbuf -- flag )  2 + c@ h# 20 and  0<>  ;


\ End of Media, End of File, or Blank Check

: eof?  ( statbuf -- flag )
   dup 2 + c@ h# c0 and  0<>   swap 3 + c@ h# f and  8 =  or
;


\ Difference between requested count and actual count

: residue  ( statbuf -- residue )  3 + 4c@  ;


0 instance value #requested  \ Local variable for r/w-some and actual-#blocks


\ Decodes the status information returned by the SCSI command to
\ determine the number of blocks actually tranferred.

: actual-#blocks  ( [[xstatbuf] hw-err? ] status -- #xfered flag )
   if         \ Error                           ( true  |  xstatbuf false )
      if      \ Hardware error; none tranferred ( )
         0 false                                ( 0 false )
      else    \ Decode status buffer            ( xstatbuf )
         >r  #requested                         ( #requested ) ( r: xstatbuf )
         r@ ili?  r@ eof? or  if                ( #requested ) ( r: xstatbuf )
            r@ residue -                        ( #xfered )    ( r: xstatbuf )
         then                                   ( #xfered )    ( r: xstatbuf )
         r> eof?                                ( #xfered flag )
      then
   else       \ no error, #request = #xfered    ( )
      #requested false                          ( #xfered flag )
   then
   to at-eof?
;


\ Reads or writes at most "#blks" blocks, returning the actual number
\ of blocks transferred, and an error indicator that is true if either a
\ fatal error occurs or the end of a tape file is reached.

: r/w-some  ( addr #blks input? cmd -- actual# error? )

   cmdbuf /cmdbuf erase
 
   0 cb!  swap                     ( addr dir #blks )
   fixed-len?  if                  ( addr dir #blks )

      \ If the tape has fixed length records, we multiply the
      \ requested number of blocks by the record size.

      dup to #requested            ( addr dir #blks )
      dup /tapeblock *  swap  1    ( addr dir #bytes cmd-cnt 1=fixed-len )

   else        \ variable length   ( addr dir #bytes )

      \ If the tape has variable length records, we transfer one record.

      /tapeblock min               ( addr dir #bytes )
      dup to #requested            ( addr dir #bytes )
      dup 0                        ( addr dir #bytes cmd-cnt 0=variable-len )

   then                            ( addr dir #bytes cmd-cnt byte1 )

   1 cb!  cmdbuf 2 + 3c!           ( addr dir #bytes )
   swap  cmdbuf 6  -1              ( dma-addr,len dir cmd-addr,len #retries)
   retry-command  actual-#blocks   ( actual# )
;

\ Discards (for read) or flushes (for write) any bytes that are buffered by
\ the deblocker

: flush-deblocker   ( -- )
   deblocker close-package  init-deblocker drop
;

0 instance value load-arg-adr
0 instance value load-arg-len
: set-load-args  ( adr len -- )  to load-arg-len  to load-arg-adr  ;
: $=  ( $1 $2 -- flag )
   rot tuck <>  if  3drop false exit  then
   comp 0= 
;
: handle-options  ( -- )
   my-args  dup  if                   ( adr len )
      ascii , left-parse-string       ( r$ l$ )
      2dup  " fixed"  $=  if          ( r$ l$ )
         2drop  set-load-args         ( )
         d# 512 to /tapeblock
         true to fixed-len?
         exit
      then                            ( r$ l$ )
      2drop 2drop my-args             ( adr len )
   then                               ( adr len )
   set-load-args
;

external


\ The deblocker package calls max-transfer to determine an appropriate
\ internal buffer size.

: max-transfer  ( -- n )
   fixed-len?  if
      \ Use the largest multiple of /tapeblock that is <= parent-max-transfer
      parent-max-transfer  /tapeblock /   /tapeblock *
   else
      /tapeblock
   then
;

\ The deblocker package calls block-size to determine an appropriate
\ granularity for accesses.

: block-size ( -- n )
   fixed-len?  if  /tapeblock  else  1  then
;

\ The deblocker uses read-blocks and write-blocks to access tape records.
\ The assumption of sequential access is guaranteed because this is only
\ called from the deblocker.  Since the SCSI tape package implements its
\ own "seek" method, the deblocker seek method is never called, and the
\ deblocker's internal position only changes sequentially.

: read-blocks  ( addr block# #blocks -- #read )
   nip                                    ( addr #blocks )  \ Sequential access

   \ Don't read past a file mark
   at-eof?  if  2drop 0  exit  then       ( addr #blocks )

   true 8 r/w-some                        ( #read )
;

: write-blocks  ( addr block# #blocks -- #read )
   nip                                    ( addr #blocks )  \ Sequential access
   true to written?                       ( addr #blocks )
   false h# a r/w-some                    ( #written )
;


\ Methods used by external clients

: read  ( addr len -- actual-len )  " read"  deblocker $call-method  ;

: write  ( addr len -- actual-len )
   " write"  deblocker $call-method       ( actual-len )
   flush-deblocker        \ Make the tape structure reflect the write pattern
;

: open  ( -- okay? )
   my-unit " set-address" $call-parent

   \ It might be a good idea to do an inquiry here to determine the
   \ device configuration, checking the result to see if the device
   \ really is a tape.

   first-install?  if
      rewind  if
         ." Can't rewind tape" cr
         false exit
      then
      false to first-install?
   then

   get-record-length
   handle-options

   init-deblocker       ( okay? )
;

: close  ( -- )
   deblocker close-package
   ?write-eof
;


0 value buf
h# 200 constant /buf

\ It would be better to keep track of the current file number and
\ just seek forward if the requested file number/position is greater
\ than the current file number/position.  Taking care of end-of-file
\ conditions would be tricky though.

: seek  ( byte# file# -- error? )

   flush-deblocker                            ( byte# file# )

   rewind      if  2drop true  exit  then     ( byte# file# )

   ?dup  if                                   ( byte# file# )
      skip-files  if   drop true  exit  then  ( byte# )
   then                                       ( byte# )

   ?dup  if                                   ( byte# )
      /buf alloc-mem  to buf
      begin  dup 0>  while                    ( #remaining )
         buf  over /buf min  read             ( #remaining #read )
         dup 0=  if  2drop  true exit  then   ( #remaining #read )
         -                                    ( #remaining' )
      repeat                                  ( 0 )
      drop                                    ( )
      buf /buf free-mem                       ( )
   then                                       ( )

   false                                      ( no-error )
;

: load  ( loadaddr -- size )
   load-arg-len  if                           ( loadaddr )
      load-arg-adr load-arg-len $number  if   ( loadaddr )
         ." Invalid tape file number" cr      ( loadaddr )
         drop 0 exit                          ( 0 )
      then                                    ( loadaddr n )
   else                                       ( loadaddr )
      0                                       ( loadaddr 0 )
   then                                       ( loadaddr file# )

   0 swap  seek  if                           ( loadaddr )
       ." Can't select the requested tape file" cr
       0 exit
   then                                       ( loadaddr )

   \ Try to read the entire tape file.  We ask for a huge size
   \ (almost 2 G Bytes), and let the deblocker take care of
   \ breaking it up into manageable chunks.  The operation
   \ will cease when a file mark is reached.

   h# 70000000 read                           ( size )
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
