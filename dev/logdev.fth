\ See license at end of file
purpose: Device to log console output to memory

dev /
new-device

" log" device-name

0 value open-count
0 value log-buf
0 value log-size
0 value log-wptr
0 value log-rptr
h# 1000 value log-increment

: open  ( -- flag )
   open-count 0=  if  
      log-size log-increment + to log-size
      log-size alloc-mem to log-buf
      0 to log-wptr
   then
   open-count 1+ to open-count
   true
;
: close  ( -- )
   open-count 1 =  if
      log-buf log-size free-mem
      0 to log-size
      0 to log-buf
      0 to log-wptr
   then
   0 to log-rptr
   open-count 1- to open-count
;

: size  ( -- ud )  log-wptr u>d  ;
: seek  ( ud -- error? )
   0<>  if  drop true  exit   then             ( low )  \ High word must be 0
   dup log-size >  if  drop true  exit  then   ( low )
   to log-rptr
;
: write  ( adr len -- actual )
   dup log-wptr +  log-size -            ( adr len needed )
   dup 0>  if                            ( adr len needed )
      log-increment round-up             ( adr len needed' )
      log-size + dup to log-size         ( adr len new-size )
      log-buf over resize  if            ( adr len new-size buf-adr )
         4drop 0 exit                    ( -- 0 )
      then                               ( adr len new-size buf-adr )
      to log-buf  to log-size            ( adr len )
   else                                  ( adr len needed )
      drop                               ( adr len )
   then                                  ( adr len )
   tuck  log-buf log-wptr +  swap  move  ( len )
   dup log-wptr + to log-wptr            ( len )
;
: read  ( adr len -- actual )
   log-wptr log-rptr -              ( adr len avail )
   min  tuck                        ( actual adr actual )
   log-rptr log-buf +  -rot move    ( actual )
   dup log-rptr + to log-rptr       ( actual )
;
: load  ( adr -- len )
   log-buf  swap  log-wptr move
   log-wptr
;

finish-device
device-end

0 value log-ih
: start-logging  ( -- )
   log-ih 0=  if
      " /log" open-dev to log-ih
      log-ih add-output
   then
;
: stop-logging  ( -- )
   log-ih   if
      log-ih remove-output
      log-ih close-dev
      0 to log-ih
   then
;
: save-log  ( "filename" -- )
   " /log" safe-parse-word $copy1
;
: no-esc-list  ( adr len -- )
   bounds  ?do    ( -- )
      i c@  bl >=  i c@ h# 9b <>  and  if
         i c@ emit
      else
         i c@  case
            newline of  newline emit  exit? ?leave  endof
            carret  of  carret  emit  endof
            tab     of  tab emit  endof
\           bs      of  bs  emit  endof
            h# 9b   of  ." ^["   endof
            ( default )
            ." ^"  dup h# 1f and   [char] @ or  emit
         endcase
      then
   loop
;
: show-log-no-ctl  ( -- )
   log-ih remove-output
   ." <OFW_Console_Log>" cr
   ['] no-esc-list ['] list ['] more (patch
   " more /log" evaluate
   ['] list ['] no-esc-list ['] more (patch
   ." </OFW_Console_Log>" cr
   log-ih add-output
;

: show-log  ( -- )
   log-ih remove-output
   ." <OFW_Console_Log>" cr
   " more /log" evaluate
   ." </OFW_Console_Log>" cr
   log-ih add-output
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
