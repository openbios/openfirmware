\ See license at end of file
purpose: Read your mail from the firmware

\ Connect to a POP3 server and read your mail.

0 value #messages

: open-pop3-connection  ( pop-server$ -- ok? )
   \ The TCP port # for POP3 is d# 110
   " $set-host" call-tcp
   d# 110  " connect" call-tcp			( ok? )
;

: close-pop3-connection  ( -- )
   " disconnect" call-tcp
;

: close-pop3  ( -- )
   close-pop3-connection		( )
   tcp-ih close-dev			( )
   0 to tcp-ih				( )
   free-mail-buffer			( )
;


: verify-pop3  ( -- ok? )
   get-reply 0=  if			( )
      false exit			( bad )
   then					( bad )
   " +OK" reply-good?			( ok? )
;

: send-one  ( $ -- ok? )  >mail-buffer  " +OK" send  ( ok? )  ;
: send-two  ( $2 $1 -- ok? )  >mail-buffer  mail-append  " +OK" send  ( ok? )  ;

: get-password  ( -- adr len )
   pad 0
   begin            ( adr len )
      key  case
         carret of  exit  then
         bs     of  1- 0 max  2dup +  0 swap c!  then

         \ default   ( adr len char )
         over d# 32 >=  abort" Password too long"  ( adr len char )
         3dup -rot + c!                            ( adr len char )
         swap 1+ swap                              ( adr len' char )
      endcase       ( adr len )
   again
;
: send-password   ( -- ok? )
   ." Password: "  get-password         ( adr len )
   2dup  " PASS "  send-two		( adr len ok? )
   -rot  erase   \ Don't leak password  ( ok? )      
;

: number?  ( b -- ascii? )
   h# 30 h# 39 between  if
      true
   else
      false
   then
;   

h# 8 buffer: pop3-buf
0 value tbuf-ptr

: +tbuf  ( -- )  tbuf-ptr 1+ to tbuf-ptr ;

: >tbuf  ( n -- )
   dup number?  0=  if
      drop
      0 pop3-buf tbuf-ptr + c!
      exit
   then
   pop3-buf tbuf-ptr + c!
   +tbuf
;

: convert#  ( -- # )
   0 to tbuf-ptr
   0				\ Starting value
   begin
      pop3-buf tbuf-ptr + c@  h# 30 h# 39 between
   while
      d# 10 *
      pop3-buf tbuf-ptr + c@  h# 0f and +
      +tbuf
   repeat			( # )
;
   
: get-num  ( -- )  
   0 to tbuf-ptr
   begin   
      begin  key?  until
      key dup emit		( key )
      dup >tbuf			( key )
      number? 0=		( flag )
   until
;

: quit-mail   ( -- ok? )  " QUIT"  send-one  ( ok? )  ;
: get-status  ( -- ok? )  " STAT"  send-one  ( ok? )  ;
: flush  ( -- )  begin  key?  while  key drop  repeat  ;

: num>ascii  ( n -- $ )
   (u.)
;

: (get-msg)  ( n$ cmd$ -- count )
   >mail-buffer
   mail-append
   " +OK" send				( ok )
   0=  if false exit  then

   \ Get message text...
   get-reply				( count )
;
: get-msg  ( i -- ok? )
   num>ascii	       ( n$ )
   " RETR "	       ( n$ cmd$ )
   (get-msg)	       ( len )
;

: get-list  ( -- )
   cr
   #messages 0=  if  ." You have no messages." cr  exit  then

   #messages 1+ 1 do
      i . ."  "  i get-msg drop  set-ptr  mail-buffer mail-ptr type cr
   loop
   cr
;

: read-msg  ( -- )
   cr
   #messages 0=  if  ." You have no messages." cr  exit  then

   flush
   begin
      ." Enter message number: "
      get-num  cr		       ( )
      convert#			       ( # )
      dup #messages > if	       ( #' )
          drop false		       ( false )
         ." Invalid message number.  Try again" cr
      else
         true			       ( #' true )
      then
   until			       ( #' )

   #line off

   get-msg			       ( actual )
   cr
   mail-buffer swap list
   cr
;   

: get-com  ( -- b )  begin  key?  until  key dup emit  ;

: dialog  ( -- )
   flush
   begin
      ." Enter Command (List Read Quit): "
      get-com		     ( char )
      upc dup		     ( char char )
      ascii Q <>
   while		     ( char )
      case
         ascii L of  get-list  endof
         ascii R of  read-msg   endof
         ascii I of  abort     endof		\ Path to debugging...
         ( default )  ." Bad input, try again..." cr
      endcase
   repeat
   drop
   quit-mail drop
;

: open-rmail-connection  ( server$ -- )
   debug-mail?  if  ." Opening TCP stack..." cr  then  ( server$ )

   " tcp" open-dev to tcp-ih                           ( server$ )
   tcp-ih 0=  abort" Failed to open tcp stack!"        ( server$ )

   allocate-mail-buffer                                ( server$ )
   
   open-pop3-connection 0=  if                         ( )
      ." Can't connect to POP3 server"
      close-pop3  abort
   then

   debug-mail?  if  ." Connection established" cr  then
   
   verify-pop3 0=  if
      debug-mail?  if  ." Connection did not verify" cr  then
      close-pop3  abort
   then
;

: authenticate-rmail  ( user$ -- )
   debug-mail?  if  ." Sending USER name..." cr  then

   " USER "  send-two  if
      debug-mail?  if  ." USER accepted" cr  then
   else
      debug-mail?  if  ." Bad USER" cr  then
      close-pop3
      abort
   then

   debug-mail?  if  ." Sending password..." cr  then
   send-password  if
      debug-mail?  if  ." Password accepted" cr  then
   else
      debug-mail?  if  ." Bad Password" cr  then
      close-pop3
      abort
   then
;

: (rmail)  ( user$ server$ -- )
   open-rmail-connection                ( user$ )
   authenticate-rmail                   ( )

   debug-mail?  if  ." Getting status..." cr  then
   0 to #messages
   get-status  if
      1 get-number		( #msgs )
      to #messages		( )
      ." You have " #messages .d ." messages." cr
   else
      debug-mail?  if  ." Get status failed" cr  then
   then

   dialog

   close-pop3
;

: rmail  ( "server" "user" -- )
   safe-parse-word  safe-parse-word  2swap  (rmail)
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
