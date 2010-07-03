purpose: User interface for NAND multicast updater - transmission
\ See license at end of file

: mesh-ssids  ( -- $ )
   " olpc-mesh"nolpc-mesh"nolpc-mesh"nolpc-mesh"nolpc-mesh"nolpc-mesh"
;

: select-mesh-mode  ( -- )
   \ Check for already set because re-setting it will force rescanning
   ['] mesh-ssids to default-ssids
   wifi-cfg >wc-ssid pstr@  " olpc-mesh" $=  0=  if
      " olpc-mesh" $essid
   then
;

: $file-to-mem  ( filename$ -- adr len )
   $read-open
   ifd @ fsize  dup alloc-mem  swap     ( adr len )
   2dup ifd @ fgets                     ( adr len actual )
   ifd @ fclose                         ( adr len actual )
   over <>  abort" Can't read file" cr  ( adr len )
;
: load-read  ( filename$ -- )
   open-dev  dup 0=  abort" Can't open file"  >r  ( r: ih )
   load-base " load" r@ $call-method  !load-size
   r> close-dev
;

: secure$  ( -- adr len )
   secure? security-off? 0= and  if  " secure"  else  null$  then
;

d# 20 value redundancy

: #nb-clone  ( channel# -- )
   depth 1 < abort" Usage: channel# #nb-clone"
   redundancy swap
   " rom:nb_tx ether:%d nand: %d" sprintf boot-load go
;
: #nb-copy  ( image-filename$ channel# -- )
   depth 3 < abort" #nb-copy - too few arguments"
   >r 2>r                             ( placement-filename$ r: channel# image-filename$ )
   redundancy  2r> r>                 ( redundancy image-filename$ channel# )
   " rom:nb_tx ether:%d %s %d 131072" sprintf boot-load go
;
: #nb-update  ( placement-filename$ image-filename$ channel# -- )
   depth 5 < abort" #nb-update - too few arguments"
   >r 2>r                             ( placement-filename$ r: channel# image-filename$ )
   $file-to-mem                       ( spec$ r: channel# image-filename$ )
   swap  redundancy  2r> r>           ( speclen specadr redundancy image-filename$ channel# )
   " rom:nb_tx ether:%d %s %d 131072 %d %d" sprintf boot-load go
;
: #nb-secure  ( zip-filename$ image-filename$ channel# -- )
   depth 5 < abort" #nb-secure-update - too few arguments"
   >r 2>r                             ( placement-filename$ r: channel# image-filename$ )
   load-read  sig$ ?save-string swap  ( siglen sigadr r: channel# image-filename$ )
   img$ ?save-string swap             ( siglen sigadr speclen specadr r: channel# image-filename$ )
   redundancy  2r> r>                 ( siglen sigadr speclen specadr redundancy image-filename$ channel# )
   " rom:nb_tx ether:%d %s %d 131072 %d %d %d %d" sprintf boot-load go
;

: #nb-update-def  ( channel# -- )  >r " u:\fs.plc" " u:\fs.img" r> #nb-update  ;
: #nb-secure-def  ( channel# -- )  >r " u:\fs.zip" " u:\fs.img" r> #nb-secure  ;

: nb-clone1   ( -- )      1 #nb-clone  ;
: nb-clone6   ( -- )      6 #nb-clone  ;
: nb-clone11  ( -- )  d# 11 #nb-clone  ;

: nb-update1   ( -- )      1 #nb-update-def  ;
: nb-update6   ( -- )      6 #nb-update-def  ;
: nb-update11  ( -- )  d# 11 #nb-update-def  ;

: nb-secure1   ( -- )      1 #nb-secure-def  ;
: nb-secure6   ( -- )      6 #nb-secure-def  ;
: nb-secure11  ( -- )  d# 11 #nb-secure-def  ;

: mesh-clone
   select-mesh-mode
   false to already-go?
   redundancy " boot rom:nb_tx udp:239.255.1.2 nand: %d" sprintf eval
;

\ LICENSE_BEGIN
\ Copyright (c) 2008 FirmWorks
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
