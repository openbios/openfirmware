\ See license at end of file
purpose: Telnet server - allows external systems to telnet to the firmware

\ To use this feature, execute "telnetd" on the firmware system, then
\ use telnet on the remote host to connect to the firmware system.
\ When done, execute "exit-telnet" or just close the connection.

support-package: telnet
false value debug-options?

: (read)  ( adr len -- actual )  " read" $call-parent  ;
: (write)  ( adr len -- actual )  " write" $call-parent  ;

\ Discard the first byte in the array by copying the rest down
: swallow  ( rem$ -- rem$' )
   1-  2dup over 1+ -rot move
;
1 instance buffer: the-byte
: getbyte  ( -- byte )
   begin
      the-byte 1 (read)  case
         1  of  the-byte c@ exit  endof
         -1 of  abort  endof
      endcase
   again
;
: putbyte  ( byte -- )  the-byte c!  the-byte 1 (write) drop  ;
: next-cmd-byte  ( rem$ -- rem$' char )
   \ If there is more data in the buffer, return the next byte
   dup  if  over c@ >r swallow r> exit  then     ( rem$ )

   \ Otherwise, get a character from the TCP connection
   getbyte                                       ( rem$ char )
;

: show-option  ( option command$ dir$ -- option )
   debug-options?  if
      [ifndef] install-uart-io  " install-uart-io" evaluate  [then]
      type space type space dup .d cr
      console-io
   else
      2drop 2drop
   then
;
: .got   ( option command$ -- )  " RCVD" show-option  ;
: .sent  ( option command$ -- )  " SENT" show-option  ;


: send-option  ( option request -- )  #iac putbyte  putbyte  putbyte  ;
: send-will    ( option -- )   " WILL" .sent  d# 251 send-option  ;
: send-wont    ( option -- )   " WONT" .sent  d# 252 send-option  ;
: send-do      ( option -- )   " DO"   .sent  d# 253 send-option  ;
: send-dont    ( option -- )   " DONT" .sent  d# 254 send-option  ;

: will  ( rem$ -- rem$' )
   next-cmd-byte  " WILL" .got
   dup  case
\ Since we have already sent "do binary", there is no need to re-ack it
\     0  of  send-do   endof
      0  of  drop      endof	\ Suppress go-ahead

\ Since we have already sent "do suppressGA", there is no need to re-ack it
\     3  of  send-do   endof	\ Suppress go-ahead
      3  of  drop      endof	\ Suppress go-ahead

      ( default )  swap send-dont
   endcase
;

: wont  ( rem$ -- rem$' )
   next-cmd-byte  " WONT " .got
   drop
;

: tdo  ( rem$ -- rem$' )
   next-cmd-byte  " DO" .got
   dup  case
      0  of  send-will  endof	\ Binary transmission

\ Since we have already sent "will echo", there is no need to re-ack it
\     1  of  send-will  endof	\ Echo
      1  of  drop       endof

      3  of  send-will  endof	\ Suppress go-ahead
      ( default )  swap send-wont
   endcase
;

: dont  ( rem$ -- rem$' )
   next-cmd-byte  " DONT" .got
   drop
;

: subnegotiate  ( rem$ -- rem$' )
   next-cmd-byte  " SUBNEGOTIATE" .got
   \ XXX we should eat everything up to the SE marker;
   \ on the other hand, we should never get here, because
   \ we don't express willingness to subnegotiate anything.
   drop
;

: reinsert  ( rem$ char -- rem$' )
   >r
   2dup  over 1+ swap move       ( rem$ r: char )
   r> 2 pick c!  1+              ( rem$' )
;
: do-command  ( rem$ -- rem$' )
   swallow			\ Discard the IAC itself
   next-cmd-byte                ( rem$ char )
   case
\     d# 240  of                       endof    \ end subnegotiation
\     d# 241  of                       endof    \ nop
\     d# 242  of                       endof    \ data mark (end urgent)
      d# 243  of  user-abort           endof    \ break
      d# 244  of  user-abort           endof    \ interrupt process
\     d# 245  of                       endof    \ abort-output
\     d# 246  of                       endof    \ are-you-there?
      d# 247  of  control h reinsert   endof    \ erase character
      d# 248  of  control u reinsert   endof    \ erase line
      d# 249  of                       endof    \ go-ahead
      d# 250  of  subnegotiate         endof
      d# 251  of  will                 endof
      d# 252  of  wont                 endof
      d# 253  of  tdo                  endof
      d# 254  of  dont                 endof
      #iac    of  #iac reinsert        endof
   endcase
;

\ Remove the linefeed in a cr-lf pair.
\ The Windows telnet client sends CR-LF per the Telnet NVT spec.
\ The Linux telnet client just sends CR.
0 value last-was-cr?

: do-lf  ( adr len -- adr' len' )
   last-was-cr?  if  swallow  else  1 /string  then
;

: process-escapes  ( adr len -- len' )
   over swap                                   ( adr rem$ )
   begin  dup  while                           ( adr rem$ )
      over c@  dup >r  case                    ( adr rem$ r: char )
         #iac of  do-command  endof            ( adr rem$' r: char )
         linefeed of  do-lf  endof             ( adr rem$' r: char )
         ( adr rem$ char )  >r  1 /string  r>  ( adr rem$' r: char )
      endcase                                  ( adr rem$ r: char )
      r> carret =  to last-was-cr?             ( adr rem$ )
   repeat                                      ( adr end-adr 0 )
   drop swap -                                 ( len' )
;
: read  ( adr len -- actual )
   over swap  (read)              ( adr actual )
   dup 0<  if  nip exit  then     ( adr actual )
   process-escapes                ( actual' )
;
: write  ( adr len -- actual )
   tuck  begin                ( len adr len )
      #iac split-string       ( len head$ tail$ )
   dup while                  ( len head$ tail$ )
      2swap (write) drop      ( len tail$ )
      #iac putbyte            ( len tail$ )  \ Send an escape
      over 1 (write)          ( len tail$ )  \ Send the ff in the string
      1 /string               ( len tail$' ) \ Remove it from the string
   repeat                     ( len head$ null$ )
   2drop (write) drop         ( len )
;

0 instance value verbose?

: open  ( -- flag )
   my-args " verbose" $=  to verbose?

   verbose?  if
      ." telnet://"  " my-ip-addr" $call-parent .ipaddr  cr
   then

   begin  d# 23 " accept" $call-parent  until

   verbose?  if  ." Connected" cr  then

   3 send-do		\ You suppress go-ahead
   0 send-do		\ Be binary
   1 send-will		\ I will echo

   get-msecs        ( time )
   begin
      get-msecs over d# 300 +  -  0<
   while
      the-byte h# 10 (read)  dup  0<  if          ( msecs count )
         \ Bail out if the connection closed
         -1 =  if  drop false exit  then

         \ The other alternative is -2, meaning no bytes available.
         \ In that case, we'll eventually time out.
      else                                        ( msecs count )
         \ Keep advancing the timeout while bytes are still coming in
         the-byte swap process-escapes drop      ( msecs )
         drop get-msecs
      then
   repeat
   drop

   false to last-was-cr?

   true
;
: close  ( -- )  ;
end-support-package


0 value old-in
0 value old-out
0 value telnet-ih

defer getchar-hook  ' = to getchar-hook
patch getchar-hook =  stdin-getchar

: exit-telnet  ( -- )
   telnet-ih close-dev
   old-out stdout !
   old-in  stdin !
   ['] = to getchar-hook
;

: ?telnet-closed  ( read-return 1 -- flag )
   over  -1 =  if              ( -1 1 )
      exit-telnet              ( -1 1 )
      carret pending-char c!   ( 1 1 ) 
      ." Connection closed" \ cr
      2drop true exit
   then                        ( read-return 1 )
   =
;

devalias telnetd  tcp//telnet:verbose

: telnetd  ( -- )
   " telnetd" open-dev dup 0= abort" Can't open telnet"  ( ih )
   to telnet-ih
   stdin @ to old-in  stdout @ to old-out
   telnet-ih dup stdin !  stdout !
   ['] ?telnet-closed to getchar-hook
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
