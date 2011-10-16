\ See license at end of file
\ From date.fth
purpose: Time and date decoding functions

variable clock-node  ' clock-node  " clock" chosen-variable

: ofw-time&date  ( -- s m h d m y )
   " get-date" clock-node @ ihandle>phandle find-method  if
      drop
      " get-time" clock-node @  $call-method  swap rot
      " get-date" clock-node @  $call-method  swap rot
   else
      " get-time" clock-node @  $call-method
   then
;
stand-init:
   ['] ofw-time&date to time&date
;

headerless
: 2.d  ( n -- )   push-decimal  (.2)  type  pop-base  ;
: 4.d  ( n -- )   push-decimal  <# u# u# u# u# u#>  type  pop-base  ;

headers
: .date  ( d m y -- )   4.d ." -" 2.d ." -" 2.d  ;
: .time  ( s m h -- )   2.d ." :" 2.d ." :" 2.d  ;

\ Interactive diagnostic
: watch-clock  ( -- )
   ." Watching the 'seconds' register of the real time clock chip."  cr
   ." It should be 'ticking' once a second." cr
   ." Type any key to stop."  cr
   -1
   begin    ( old-seconds )
      begin
         key?  if  key drop  drop exit  then
         now 2drop
      2dup =  while   ( old-seconds old-seconds )
         drop
      repeat          ( old-seconds new-seconds )
      nip (cr now .time
   again
   drop
;

: watch-rtc
   begin 
      time&date .date ."  " .time (cr 500 ms
   key? until
   key drop
;

\ From fwfileop.fth
purpose: File I/O interface using Open Firmware
copyright: Copyright 1994 Firmworks  All Rights Reserved

headerless
\ Closes an open file, freeing its descriptor for reuse.

: _ofclose  ( file# -- )
   bfbase @  bflimit @ over -  free-mem   \ Hack!  Hack!
   close-dev
;

\ Writes "count" bytes from the buffer at address "adr" to a file.
\ Returns the number of bytes actually written.

: _ofwrite  ( adr #bytes file# -- #written )  " write" rot $call-method  ;

\ Reads at most "count" bytes into the buffer at address "adr" from a file.
\ Returns the number of bytes actually read.

: _ofread  ( adr #bytes file# -- #read )  " read" rot $call-method  ;

\ Positions to byte number "l.byte#" in a file

: _ofseek  ( d.byte# file# -- )  " seek" rot $call-method  drop  ;

\ Returns the current size "l.size" of a file

: _ofsize  ( file# -- d.size )  " size" rot $call-method  ;

\ Prepares a file for later access.  Name is the pathname of the file
\ and mode is the mode (0 read, 1 write, 2 modify).  If the operation
\ succeeds, returns the addresses of routines to perform I/O on the
\ open file and true.  If the operation fails, returns false.


defer _ofcreate
: null-create  ( name -- 0 )  2drop 0  ;
' null-create to _ofcreate

defer _ofdelete
' 2drop to _ofdelete

: _ofopen
   ( name mode -- [ fid mode sizeop alignop closeop writeop readop ] okay? )
   >r count                                     ( name$  r: mode )
   r@ create-flag and  if                       ( name$  r: mode )
      2dup ['] _ofdelete catch  if  2drop  then ( name$  r: mode )
   then                                         ( name$  r: mode )

   2dup open-dev  ?dup  0=  if                  ( name$    r: mode )
      r@ r/o =  if                              ( name$    r: mode )
         0                                      ( name$ 0  r: mode )
      else                                      ( name$    r: mode )
         2dup _ofcreate                         ( name$ ih r: mode )
      then                                      ( name$ ih r: mode )
      ?dup 0=  if  r> 3drop  false exit  then   ( name$ ih r: mode )
   then                                         ( name$ ih r: mode )
   nip nip                                      ( ih       r: mode )
   r@   ['] _ofsize   ['] _dfalign   ['] _ofclose   ['] _ofseek
   r@ r/o  =  if  ['] nullwrite  else  ['] _ofwrite  then
   r> w/o  =  if  ['] nullread   else  ['] _ofread   then
   true
;

headers

: stand-init  ( -- )  stand-init  ['] _ofopen to do-fopen  ;

\ From dipkg.fth
purpose: Demand-loading of packages stored as dropin drivers
copyright: Copyright 1999 Firmworks  All Rights Reserved

: load-dropin-package  ( name$ -- false  |  phandle true )
   [char] / split-after                        ( name$ path$ )
   locate-device  if  2drop false exit  then   ( name$ phandle )
   rpush-order                                 ( name$ phandle r: old-order )
   push-package                                ( name$ )
   2dup  any-drop-ins?  if                     ( name$ )
      true to autoloading?                     ( name$ )
      new-device                               ( name$ )
      base @ >r				       ( name$ ) ( r: base )
      2dup 2>r do-drop-in                      ( )       ( r: base name$ )
      2r> device-name                          ( )       ( r: base )
      r> base !				       ( )	 ( r: )
      current-device true                      ( phandle true )
      finish-device                            ( phandle true )
      false to autoloading?                    ( name$ )
   else                                        ( name$ )
      2drop false                              ( false )
   then                                        ( false | phandle true )
   rpop-order                                  ( false | phandle true )
;
' load-dropin-package to load-package

\ From probe.fth
copyright: Copyright 2006 Firmworks  All Rights Reserved

\ Test locations for accessability.
\   X is c , w , or l for 8, 16, or 32-bit access.
\
\   Xprobe  ( adr -- flag )
\	Read location, return false if bus error, otherwise return true.
\   Xpeek   ( adr -- false | value true )
\	Read location, return false if bus error, otherwise return data
\	and true.
\   Xpoke   ( value adr -- flag )
\	Write location, return false if bus error, otherwise return true.

only forth also hidden also
hidden definitions
partial-headers
: peeker  ( adr acf -- value true | false)
   guarded-execute  dup 0=  if  nip  then
;
: prober  ( adr acf -- flag )  guarded-execute nip  ;
: poker  ( value adr acf -- flag )	\ Flag is true if success
\  guarded-execute  dup 0=  if  nip nip  then
   guarded-execute
;

headers
forth definitions
: cpeek  ( adr -- false | value true )  ['] c@ peeker  ;
: wpeek  ( adr -- false | value true )  ['] w@ peeker  ;
: lpeek  ( adr -- false | value true )  ['] l@ peeker  ;
64\ : xpeek   ( adr -- false | value true )  ['] x@ peeker  ;

\ : peek   ( adr -- false | value true )  [']  @ peeker  ;

: cprobe  ( adr -- present-flag )  ['] c@ prober  ;
: wprobe  ( adr -- present-flag )  ['] w@ prober  ;
: lprobe  ( adr -- present-flag )  ['] l@ prober  ;
64\ : xprobe  ( adr -- present-flag )        ['] x@ prober  ;

\ : probe   ( adr -- present-flag )   peek probe-fix  ;

: cpoke   ( value adr -- flag )  ['] c! poker  ;
: wpoke   ( value adr -- flag )  ['] w! poker  ;
: lpoke   ( value adr -- flag )  ['] l! poker  ;
64\ : xpoke   ( value adr -- flag )          ['] x! poker   ;

only forth also definitions
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
