\ See license at end of file
purpose: SMTP, Send mail from the firmware.

\ Connect to an SMTP server, send some mail.

: open-smtp-connection  ( smtp-server$ -- ok? )
   \ The TCP port # for SMTP is d# 25
   " $set-host" call-tcp
   d# 25  " connect" call-tcp			( ok? )
;

: close-smtp-connection  ( -- )
   " disconnect" call-tcp
;

: close-smtp  ( -- )
   close-smtp-connection		( )
   tcp-ih close-dev			( )
   0 to tcp-ih				( )
   mail-buffer /mail-buffer free-mem	( )
;

: verify-smtp  ( -- ok? )
   get-reply 0=  if			( )
      false exit			( bad )
   then					( bad )
   " 220" reply-good?			( ok? )
;

: smtp-quit   ( -- ok? )
   " QUIT" >mail-buffer			( )
   " 221" send				( ok? )
;

: smtp-rset   ( -- ok? )
   " RSET" >mail-buffer			( )
   " 250" send				( ok? )
;

: smtp-hello  ( -- ok? )
   " HELO " >mail-buffer
   " smtp-my-hostname" $getenv drop mail-append
   " 250" send				( ok? )
;

: add-terminator  ( -- )	\ Send "crlf . crlf"
   add-crlf				( )
   " ." mail-append			( )
;

: smtp-mail  ( -- ok? )
   " MAIL " >mail-buffer
   " FROM:" mail-append
   " smtp-from-path" $getenv drop mail-append
   " 250" send				( ok? )
;

: smtp-rcpt  ( -- ok? )
   " RCPT " >mail-buffer
   " TO:" mail-append
   " smtp-to-path" $getenv drop mail-append
   " 250" send				( ok? )
;

: smtp-data  ( adr len -- ok? )
   " DATA " >mail-buffer		( adr len )
   " 354" send				( adr len ok? )
   0=  if				( adr len )
      debug-mail?  if			( adr len )
         ." Data send failure" cr	( adr len )
      then				( adr len )
      2drop 0				( 0 )
      exit				( 0 )
   then					( 0 )

   >mail-buffer				( )
   add-terminator			( )

   " 250" send				( ok? )
;

: sendmail  ( adr len -- ok? )

   ?dup 0=  if drop false exit  then		\ no data, no send

   false

   " smtp-server" $getenv  if
      cr
      ." Missing smtp-server environment variable" cr
      ." Use ""$setenv"" to set the smtp-server name:" cr
      ."  "" <servername>"" "" smtp-server"" $setenv" cr
      drop true
   else  2drop  then

   " smtp-from-path" $getenv  if
      cr
      ." Missing smtp-from-path environment variable" cr
      ." Use ""$setenv"" to set the smtp-from-path name:" cr
      ."  "" <return-address>"" "" smtp-from-path"" $setenv" cr
      drop true
   else  2drop  then

   " smtp-to-path" $getenv  if
      cr
      ." Missing smtp-to-path environment variable" cr
      ." Use ""$setenv"" to set the smtp-to-path name:" cr
      ."  "" <address>"" "" smtp-to-path"" $setenv" cr
      drop true
   else  2drop  then

   " smtp-my-hostname" $getenv  if
      cr
      ." Missing smtp-my-hostname environment variable" cr
      ." Use ""$setenv"" to set the smtp-my-hostname name:" cr
      ."  "" <hostname>"" "" smtp-my-hostname"" $setenv" cr
      drop true
   else  2drop  then

   if  false exit  then			( false )	\ Error out

   debug-mail?  if  ." Opening TCP stack..." cr  then

   " tcp" open-dev to tcp-ih
   tcp-ih 0=  if  ." Failed to open tcp stack!" exit  then

   allocate-mail-buffer
   
   " smtp-server" $getenv drop open-smtp-connection 0=  if
      close-smtp  exit
   then

   debug-mail?  if  ." Connection established" cr  then
   
   verify-smtp  0= if
      debug-mail?  if  ." Connection did not verify" cr  then
      close-smtp  exit
   then

   smtp-hello drop						( adr len )

   ( adr len ) smtp-rset 0=  if  close-smtp false exit  then    ( 0 )
   ( adr len ) smtp-mail 0=  if  close-smtp false exit  then	( 0 )
   ( adr len ) smtp-rcpt 0=  if  close-smtp false exit  then	( 0 )
   ( adr len ) smtp-data 0=  if  close-smtp false exit  then	( 0 )

   smtp-quit  drop						( )

   close-smtp							( )
   true								( ok )
;

: test-msg  ( -- adr len )
   " "n"nThis message was brought to you by FirmWorks' SMTP package"r"n"
;

: (show-smtp)  ( adr len -- )
   2dup  $getenv  if  missing-var  else
      2swap type ." : "  type cr
   then
;

: show-smtp  ( -- )
   " smtp-server"      (show-smtp)
   " smtp-from-path"   (show-smtp)
   " smtp-to-path"     (show-smtp)
   " smtp-my-hostname" (show-smtp)
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
