purpose: USB UART driver
\ See license at end of file

hex
headers

" serial" device-name
" serial" device-type
0 " #size-cells" integer-property
1 " #address-cells" integer-property

variable refcount  0 refcount !

: /string  ( adr len cnt -- adr' len' )  tuck - -rot + swap  ;

external

: install-abort  ( -- )  ['] poll-tty d# 100 alarm  ;   \ Check for break
: remove-abort   ( -- )  ['] poll-tty 0 alarm  ;

\ Read at most "len" characters into the buffer at adr, stopping when
\ no more characters are immediately available.
: read  ( adr len -- #read )   \ -2 for none available right now
   rpoll
   dup  0=  if  nip exit  then                   ( adr len )
   read-q deque?  0=  if                         ( adr len )
      2drop                                      ( )
      lost-carrier?  if  -1  false to lost-carrier?  else  -2  then
                                                 ( -2:none | -1:down )
      exit
   then                                          ( adr len char )
   over >r                                       ( adr len char r: len )
   begin                                         ( adr len char r: len )
      2 pick c!                                  ( adr len r: len )
      1 /string                                  ( adr' len' )
      dup 0=  if  2drop r> exit  then            ( adr' len' )
   read-q deque? 0=  until                       ( adr len r: len )
   nip r> swap -                                 ( actual )
;

: write  ( adr len -- actual )  dup  if  write-bytes  else  nip  then  ;

: open  ( -- flag )
   device set-target
   refcount @ 0=  if
      init-buf read-q init-q
      inituart rts-dtr-on
      inbuf /bulk-in-pipe bulk-in-pipe begin-bulk-in
   then
   refcount @ 1+  refcount !
   true
;
: close  ( -- )
   refcount @ 1-  0 max  refcount !
   refcount @ 0=  if
      rts-dtr-off
      end-bulk-in
      free-buf
   then
;

variable test-char
: selftest  ( -- 0 )		\ Test device by sending a bunch of characters
   refcount @  if  ." Device in use" cr 0 exit  then
   open 0=  if  ." Device won't open" cr true exit  then
   h# 7f bl  do  i test-char !  test-char 1 write drop  loop
;

: init  ( -- )
   init
   init-buf
   device set-target
   configuration set-config  if  ." Failed set serial port configuration" cr  then
   init-hook
   free-buf
;

headers

init


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
