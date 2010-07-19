\ See license at end of file
purpose: Non-blocking writes to fsdisk for NANDblaster

support-package: block-fifo
d# 10000 constant #queue
h# 4000 value /chunk
0 instance value chunks
0 instance value block#s
0 instance value this-#blocks
0 instance value read-index
0 instance value write-index
0 instance value max-depth
false instance value synchronous?
0 value debug?

: #queued  ( -- n )
   write-index read-index -
   dup 0<  if  #queue +  then
;
: update-max  ( -- )
   #queued  max-depth  max  to max-depth
;

: blocks/chunk  ( -- n )  /chunk 9 rshift  ;

: >chunk  ( i -- adr )  /chunk * chunks +  ;
: +index  ( i -- i' )  1+  dup #queue =  if  drop 0  then  ;

: full?  ( -- flag )
   write-index read-index =  this-#blocks 0<>  and
;
: empty?  ( -- flag )
   write-index read-index =  this-#blocks 0=  and
;

: ?write-error  ( -- )
   if                                          ( )
      ." disk-fifo: Write error at block "     ( )
      block#s read-index na+ @ . cr            ( )
      abort                                    ( )
   then                                        ( )
;

: ?start-write  ( -- )
   empty?  if  exit  then        ( )

   \ Start a new write
   read-index >chunk             ( adr )
   block#s read-index na+ @      ( adr block# )
   blocks/chunk                  ( adr block# #blocks )
   " write-blocks-start" $call-parent  ?write-error  ( )
   blocks/chunk to this-#blocks  ( )
;

: open  ( -- flag )
\  #queue /chunk * alloc-mem to chunks
   h# 200.0000 to chunks  \ 32 M
   #queue /n* alloc-mem to block#s
   0 to read-index
   0 to write-index
   0 to this-#blocks
   true
;

: size  ( -- d.size )  " size" $call-parent  ;

: poll  ( -- )
   this-#blocks  if                               ( )
      " write-blocks-end?" $call-parent  0=  if   ( )
         exit   \ Write still in progress         ( -- )
      then                                        ( error? )
      ?write-error                                ( )
      read-index +index to read-index             ( )
      0 to this-#blocks                           ( )
   then                                           ( )

   ?start-write
;

: wait-available  ( -- )
   full?  if
      ." WARNING: disk-fifo queue full" cr
      begin  poll  full? 0=  until
   then
;

: write-blocks  ( adr block# #blocks -- actual )
   synchronous?  if
      " write-blocks" $call-parent
      exit
   then

   dup  blocks/chunk <>  if           ( adr block# #blocks )
      ." disk-fifo: bad write length " dup .  cr
      2drop
      0 exit
   then                               ( adr block# #blocks )
   drop                               ( adr block# )
   wait-available                     ( adr block# )
   block#s write-index na+ !          ( adr )
   write-index >chunk  /chunk move    ( ) 
   write-index +index to write-index  ( )
   update-max                         ( )
   poll                               ( )
   blocks/chunk                       ( actual )
;

: drain-queue  ( -- )
   synchronous?  0=  if
      debug?  if
         ." Max queue depth was " max-depth .d  ." , current is " #queued .d cr
      then
      true to synchronous?
   then
   begin  empty?  0=  while  poll  repeat
;
   
: close  ( -- )
   drain-queue
   block#s  #queue /l*  free-mem
;

: read-blocks  ( adr block# #blocks -- actual )
   drain-queue
   " read-blocks" $call-parent
;
end-support-package

\ LICENSE_BEGIN
\ Copyright (c) 2010 FirmWorks
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
