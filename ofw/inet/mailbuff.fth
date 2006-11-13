\ See license at end of file
purpose: Common code for POP3 and SMTP buffer management

false value debug-mail?

: debug-mail  ( -- )  true to debug-mail?  ;
: no-debug-mail  ( -- ) false to debug-mail?  ;

0 value mail-buffer
h# 1000 constant /mail-buffer
0 value mail-ptr

: >mail-buffer  ( adr len -- )
   dup to mail-ptr
   mail-buffer swap move
;

: mail-append  ( $ -- )
   dup mail-ptr + mail-ptr swap  to mail-ptr  ( $ insert ) \ Set final length
   mail-buffer + swap			      ( adr dest len )
   move					      ( )
;

: add-crlf  ( -- )	\ Append a CRLF pir into the message buffer
   h# 0d mail-buffer mail-ptr + c!
   h# 0a mail-buffer mail-ptr + 1+ c!
   mail-ptr 2+ to mail-ptr
;

: ptr+  ( -- )  mail-ptr 1+ to mail-ptr  ;
: buf@  ( index -- b )  mail-buffer + c@  ;

: skip-forward  ( -- )
   begin
      mail-ptr buf@
      h# 20 <>
   while
      ptr+
   repeat
;

: skip-to-non-blank  ( -- )
   begin
      mail-ptr buf@
      h# 20 =
   while
      ptr+
   repeat
;

: set-ptr  ( -- )		\ Sets buffer pointer to end of first line
   0 to mail-ptr
   begin
      mail-ptr buf@		( t1 )
      mail-ptr 1+ buf@		( t1 t2 )
      h# 0a = swap		( flag t1 )
      h# 0d = and 0=		( flag' )
   while
      ptr+	             
   repeat
;

: get-number  ( field -- # )		\ Extract a number from a response
   \ Responses come back as ascii.  This method extracts a number from
   \ a specified field within the returned data.  The response data always
   \ starts with "+OK" followed by a space, then ascii, then a space, and
   \ more ascii.  When calling this method, do not count the "+OK" as a
   \ field

   0 to mail-ptr		( field )
   0 do				( )
      skip-forward			\ Move to blank spot
      skip-to-non-blank			\ move to non-blank spot
   loop

   \ mail-ptr is now pointing at first ascii digit of the number we want.
   \ The numbers are in decimal format.

   0				\ Starting value
   begin
      mail-buffer mail-ptr + c@  h# 30 h# 39 between
   while
      d# 10 *
      mail-buffer mail-ptr + c@  h# 0f and +
      mail-ptr 1+ to mail-ptr
   repeat			( # )
;

: reply-good?  ( expected$ -- ok? )
   mail-buffer over $=
;

: allocate-mail-buffer  ( -- )
   /mail-buffer alloc-mem to mail-buffer
;
: free-mail-buffer  ( -- )
   mail-buffer /mail-buffer free-mem
;

d# 50 value #retries
d# 500 value wait-time

: call-tcp   ( ... -- ... )         tcp-ih $call-method  ;
: read-tcp   ( adr len -- actual )  " read"  call-tcp  ;
: write-tcp  ( adr len -- actual )  " write" call-tcp  ;

: get-reply  ( -- actual )  
   #retries 0 do
      mail-buffer /mail-buffer read-tcp dup -2 <>  if		( read )
         debug-mail?  if  mail-buffer over type cr  then	( read )
         unloop exit						( read )
      else							( read )
         drop							( )
         wait-time ms						( )
      then							( )
   loop
   0								( 0 )
;

: send-request  ( -- actual )  mail-buffer mail-ptr  write-tcp  ;

: send  ( expected$  -- ok? )  
   add-crlf				( expected$ )

   send-request  0=  if			( )
      2drop				( )
      ." Send Failure" cr		( )
      false				( false )
      exit				( false )
   then					( false )

   ( expected$ )

   get-reply  0=  if
      2drop
      ." No reply to message" cr
      false
      exit
   then

   ( expected$ ) reply-good?		( ok? )
;

: missing-var  ( adr len -- )
   ." Missing environment variable: " type cr
;
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
