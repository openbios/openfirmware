\ See license at end of file
purpose: Demand-loading of word sets

\ Autoload code from a dropin module.  Use as follows:
\    autoload: filename
\    defines: word1
\    defines: word2
\    defines: word3

defer do-autoload  ( filename$ -- )	\ This vector must be set later
0 value last-autoload

: rpush-order  ( -- r: search order )
   r>  get-order  dup                            ( ra vocn .. voc1 n n )
   begin  dup 0>  while  rot >r  1-  repeat      ( ra n 0  r: voc1 .. vocn )
   drop >r >r                                    ( r: voc1 .. vocn n ra )
   only forth also definitions
;
: rpop-order  ( r: search order -- )
   r>                                                 ( ra r: voc1 .. vocn n )
   r>  dup begin  dup 0>  while  r> -rot  1-  repeat  ( ra vocn .. voc1 n 0 )
   drop set-order                                     ( ra )
   >r 
;

: this-name  ( apf -- name$ )  body> >name name>string  ;
: autoload:  ( "name$" -- )
   create  0 /n user#, !
   lastacf is last-autoload
   does>  ( -- )
   dup >user @  if  drop exit  then     ( body-adr )
   rpush-order
   base @ >r warning @ >r  warning off  ( r: base )
   dup >r this-name do-autoload         ( r: base warning body-adr )
   r> on			        ( r: base warning )
   r> warning !			        ( r: base )
   r> base !			        ( )
   rpop-order
;
: find-new  ( body-adr -- body-adr false | body-adr xt true )
   dup this-name $find  if           ( body-adr xt )
      2dup swap body> <>  if         ( body-adr xt )
         true                        ( body-adr xt true )
      else                           ( body-adr xt )
         drop false                  ( body-adr false )
      then
   else                              ( body-adr name$ )
      2drop false                    ( body-adr false )
   then
;
: do-autoloaded  ( apf -- )
   dup >user token@  non-null?  if  nip execute exit  then  ( body-adr )
   dup >r ta1+ token@ execute r>                      ( body-adr )
   find-new  if                                       ( body-adr xt )
      dup rot >user token!  execute                   ( )
   else                                               ( body-adr )
      drop true abort" Autoload didn't define the word"
   then
;
: preload  ( "name" -- )  '  >body ta1+ token@ execute  ;
: defines:  ( "word" -- )
   create
   /token user#, !null-token
   last-autoload token,
   does> do-autoloaded
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
