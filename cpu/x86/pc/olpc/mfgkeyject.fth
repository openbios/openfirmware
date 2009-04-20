purpose: Inject additional keys into manufacturing data in the factory
\ See license at end of file

\ Search for !!! for things that may need to change for different deployments

\ !!! Re-implement this for each different deployment
: wrong-sku?  ( -- flag )
   " P#" find-tag 0=  if  true exit  then              ( pn$ )

   -null                                               ( pn$' )
   2dup " 1CL11ZP0KD6" $=  if  2drop false exit  then  ( pn$ ) \ UY BYD LiFePO4
   2dup " 1CL11ZP0KD7" $=  if  2drop false exit  then  ( pn$ ) \ UY GP NiMH
   2dup " 1CL11ZP0KD9" $=  if  2drop false exit  then  ( pn$ ) \ UY GP LiFePO4
[ifdef] test-me
   2dup " 1CL11ZU0KDB" $=  if  2drop false exit  then  ( pn$ ) \ US for testing
[then]
   2drop

   true
;

\ !!! Change the key list for each different deployment
: new-key-list$  ( -- )  " o1 s1 t1 w1 a1 d0"  ;

: key-location-template  ( -- adr len )  " u:%\%s.pub"  ;

: find-key-file  ( basename$ -- false | adr len true )
   key-location-template sprintf               ( filename$ )
   open-dev dup  if                            ( ih )
      >r                                       ( )
      " size" r@ $call-method drop  ?dup  if   ( len )
         dup alloc-mem  swap                   ( adr len )
         2dup " read" r@ $call-method          ( adr len actual )
         over <>  if                           ( adr len )
            free-mem                           ( )
            ." Key file short read" cr         ( )
            false                              ( false )
         else                                  ( adr len )
            true                               ( adr len true )
         then                                  ( false | adr len true )
      else                                     ( )
         ." Empty key file" cr                 ( )
         false                                 ( false )
      then                                     ( false | adr len true )
      r> close-dev                             ( false | adr len true )
   then                                        ( false | adr len true )
;

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
   2dup find-key-file  if            ( keyname$ value$ )
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
   already-injected?   if
      " Keys Already Present" keyject-error
      false exit
   then
   true
;

: ?keyject  ( -- )
   visible
   green-letters  cr ." Security Key Injector" cr cr  black-letters

   do-keyject?  if
      flash-write-enable
      inject-keys
      flash-write-disable  \ Should reboot
   then
;

?keyject

\ LICENSE_BEGIN
\ Copyright (c) 2007 FirmWorks
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
