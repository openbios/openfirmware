purpose: Inject additional keys into manufacturing data on non-secured machine
\ See license at end of file

\ This key insertion program is for use in manufacturing before the machines
\ have been secured, i.e. before the wp tag is created.

\ Search for !!! for things that may need to change for different deployments

\ !!! Change the list of SKUs according to which ones should receive the new keys
: wrong-sku?  ( -- flag )
   " P#" find-tag 0=  if  true exit  then              ( pn$ )

   -null                                               ( pn$' )
   2dup " 1CL1BZP0KD6" $=  if  2drop false exit  then  ( pn$ ) \ UY BYD LiFePO4
   2dup " 1CL11ZP0KD7" $=  if  2drop false exit  then  ( pn$ ) \ UY GP NiMH
   2dup " 1CL11ZP0KD9" $=  if  2drop false exit  then  ( pn$ ) \ UY GP LiFePO4
   2dup " 1CL1B000003" $=  if  2drop false exit  then  ( pn$ ) \ Preproduction XO-1.5
[ifdef] test-me
   2dup " 1CL11ZU0KDB" $=  if  2drop false exit  then  ( pn$ ) \ US for testing
[then]
   2drop

   true
;

\ !!! Change the key list according to which keys the deployment wants
: new-key-list$  ( -- )  " a1 d1 o1 s1 t1 w1 "  ;

\ !!! Change the pattern according to the location of key data files
: get-key-file  ( keyname$ -- false | value$ true )
\  " ext:\\%s.public"   \ For an SD card formatted with EXT2 (capable of handling long names)
   " u:\\%s.pub"        \ For a USB driver formatted with FAT (8.3 filename restriction)
   sprintf $read-file 0=
;

: keyject-expired?  ( -- flag )  false  ;

\ True if the all the requested tags are already present.
\ This prevents endless looping.
: already-injected?  ( -- flag )
   new-key-list$  begin  dup  while  ( $ )
      bl left-parse-string           ( $' name$ )
      find-tag  if                   ( $ value$ )
         2drop                       ( $ )
      else                           ( $ )
         2drop  false exit
      then                           ( $ )
   repeat                            ( $ )
   2drop true
;

: inject-key  ( keyname$ -- )
   2dup get-key-file  if             ( keyname$ value$ )
      2over ram-find-tag  if         ( keyname$ value$ oldvalue$ )
         2 pick <>  if               ( keyname$ value$ oldvalue$ )
            3drop                    ( keyname$ )
            ." Warning: inconsistent old tag length for " type cr   ( )
            exit
         then                        ( keyname$ value$ oldvalue-adr )
         >r 2tuck  r> swap  move     ( valu$ keyname$ )
         green-letters
         ." Replaced " type cr       ( value$ )
         black-letters
      else                           ( keyname$ value$ )
         2swap                       ( value$ keyname$ )
         2over 2over                 ( value$ keyname$ value$ keyname$ )
         ($add-tag)                  ( value$ keyname$ )
         green-letters
         ." Added " type cr          ( value$ )
         black-letters
      then                           ( value$ )
      free-mem                       ( )
   else                              ( keyname$ )
      ." Warning: Can't find a dropin module for " type cr  ( )
   then                              ( )
;

: inject-keys  ( -- )
   get-mfg-data
   new-key-list$  begin  dup  while  ( $ )
      bl left-parse-string           ( $' name$ )
      inject-key                     ( $ )
   repeat                            ( $ )
   2drop                             ( )
   (put-mfg-data)                    ( )
;

: keyject-error  ( msg$ -- )
   cr
   red-letters  ." Not injecting because:   "  type  cr  black-letters
   cr
;

: do-keyject?  ( -- flag )
   wrong-sku?  if
      " Wrong SKU" keyject-error
      false exit
   then
   keyject-expired?  if
      " Date Expired" keyject-error
      false exit
   then
   already-injected?   if
      " Keys Already Present" keyject-error
      false exit
   then
   true
;

: ac-connected?  ( -- flag )  bat-status@ h# 10 and  0<>  ;

\ Empirically, a weak-but-present battery can present the "trickle charge" (80)
\ but not present the "present" bit (01).
: battery-present?  ( -- flag )  bat-status@ h# 81 and  0<>  ;

\ Similarly, a weak-but-present battery can present the "trickle charge" (80)
\ but not present the "battery low" bit (04).
: battery-strong?  ( -- flag )  bat-status@ h# 84 and  0=  ;

: wait-enough-power  ( -- )
   ac-connected?  0=  if
      ." Please connect the AC adapter to continue..."
      begin  d# 100 ms  ac-connected?  until
      cr
   then
   battery-present?  0=  if
      ." Please insert a well-charged battery to continue..."
      begin  d# 100 ms  battery-present?  until
      cr
   then
   battery-strong?  0=  if
      ." The battery is low.  Please insert a charged one to continue..."
      begin  d# 100 ms  battery-present? battery-strong? and  until
   then
;

: ?keyject  ( -- )
   visible
   green-letters  cr ." Security Key Injector" cr cr  black-letters
   do-keyject?  if
      wait-enough-power
      flash-write-enable
      inject-keys
      flash-write-disable  \ Should reboot
   then
;

?keyject

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
