\ See license at end of file
purpose: Telnet client

decimal

\ i/o

0 value telnet-done?
variable tcp-in
: tcp-getc   ( -- c )
   tcp-in 1 tcp-read  dup 0< if			( err )
      dup -1 = if  true to telnet-done?  then	( err )
      exit
   then
   drop  tcp-in c@
;

\ escapes

240	constant #se	\ End of subnegotiation parameters
\ 241	constant #nop	\ No operation
\ 242	constant #synch \ The data stream portion of a Synch
\ 243	constant #brk	\ NVT break character
\ 244	constant #ip	\ Interrupt Process
\ 245	constant #ao	\ Abort output
\ 246	constant #ayt	\ Are You There
\ 247	constant #ec	\ Erase character
\ 248	constant #el	\ Erase Line
\ 249	constant #ga	\ Go ahead
250	constant #sb	\ Suboption negotiation
251	constant #will
252	constant #wont
253	constant #do
254	constant #dont
255	constant #iac	\ interpret as command

24	constant #term-type
0	constant #is
1	constant #send

: send-is  ( string option -- )
   " "(ff fa)" tcp-type  tcp-emit  0 tcp-emit  tcp-type  " "(ff f0)" tcp-type
;

: tel-sub   ( -- )
   tcp-getc case
      #term-type  of
         tcp-getc #send =  if  " vt100" #term-type send-is  then
      endof
   endcase
;

: send-option  ( option request -- )  #iac tcp-emit  tcp-emit  tcp-emit  ;
: i-will    ( option -- )   #will send-option  ;
: i-wont    ( option -- )   #wont send-option  ;
: i-do      ( option -- )   #do   send-option  ;
: i-dont    ( option -- )   #dont send-option  ;

: he-will   ( option -- )   i-do  ;		\ offer
: he-wont   ( option -- )   i-dont  ;		\ offer
: he-does   ( option -- )			\ request
   dup case
      #term-type of	i-will	endof
      ( default )	i-wont
   endcase
;
: he-dont ( option -- )   i-wont  ;		\ request

: telnet-command   ( command -- )
   case
      #se	of				endof
\       #nop	of				endof
\       #synch	of				endof
\       #brk	of				endof
\       #ip	of				endof
\       #ao	of				endof
\       #ayt	of				endof
\       #ec	of				endof
\       #el	of				endof
\       #ga	of				endof
      #sb	of	tel-sub			endof
      #will	of	tcp-getc he-will	endof
      #wont	of	tcp-getc he-wont	endof
      #do	of	tcp-getc he-does	endof
      #dont	of	tcp-getc he-dont	endof
   endcase
;
: telnet1   ( c -- )
   dup #iac <> if   emit  exit  then  drop
   
   tcp-getc  dup #se < if  emit  exit  then	( c )

   telnet-command
;
: telnet-out  ( -- )
   d# 80 0 do
      tcp-getc dup 0< if			( c )
	 drop  leave
      else					( c )
	 telnet1
      then
   loop
;
: (telnet)  ( -- )
   false to telnet-done?
   begin  telnet-done? 0= while
      key?  if
         key  dup control ] =  if  drop exit  then
         tcp-emit
      then
      telnet-out
   repeat
;
: $telnet  ( hostname$ -- )  d# 23  open-tcp-connection  (telnet)  close-tcp  ;
: telnet  ( "hostname" -- )  safe-parse-word $telnet  ;

hex
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
