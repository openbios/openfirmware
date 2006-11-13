\ See license at end of file
purpose: Icon definition for CONFIGURE programming item

headerless

icon: config.icon      ${BP}/ofw/gui/config.icx
icon: environ.icon     ${BP}/ofw/gui/environ.icx
icon: bridge.icon      ${BP}/ofw/gui/bridge.icx
icon: grackle.icon     ${BP}/ofw/gui/grackle.icx
icon: time.icon        ${BP}/ofw/gui/time.icx

: config  ( -- )
   restore-scroller
   ." ... Configuration Variables ..." cr cr
   printenv-all
   wait-return
;

defer .environ
['] noop to .environ

: config-g  ( -- )
   restore-scroller
   ." ... Bridge Setup ..." cr cr
   .environ
   wait-return
;

: smoosh
   base @ >r d# 10 base ! (.) r> base !	( start start adr len )
;

d# 50 constant /timebuf
/timebuf buffer: timebuf

: putnum    ( # start -- end )
   dup -rot				( start # start )
   timebuf + swap			( start start # )
   smoosh				( start start adr len )
   -rot swap rot			( start adr start len )
   dup >r				( start adr start len ) ( r: len )
   move					( start ) ( r: len )
   r> +					( end )
;

: puttext  ( adr len offset -- end )
   2dup + >r
   timebuf + swap move 
   r>
;

h# 2f value separator		\ 2f is a "/"
: putsep  ( offset -- offset' )
   dup				( offset offset )
   timebuf + separator swap c!	( offset )
   1+				( offset' )
;

: time-is  ( -- )
   timebuf /timebuf 20 fill
   " Date: "					( adr len )
   2 puttext					( date-end )
   " Time: "					( date-end adr len )
   d# 20 puttext				( date-end time-end )
   >r >r					( ) ( r: time date )

   " get-time" clock-node @ $call-method	( s m h d m y )( r: time date )

   swap r> 1+ putnum >r				( s m h d y ) ( r: time date )
   swap r> putsep putnum >r			( s m h y )   ( r: time date )
   h# 64 mod r> putsep putnum drop		( s m h )     ( r: time )

   h# 3a to separator				\ 3a is a ":"
   r> 1+ putnum >r				( s m )	( r: time )
   r> putsep putnum >r				( s )   ( r: time )
   r> putsep putnum					( )
  
   timebuf /timebuf				( adr len )
   dialog-alert					( )
;

: install-config-menu  ( -- )
   clear-menu

   " Display Environment Variables "
   ['] config     environ.icon     1 1  selected  install-icon

   0 config-w@ h# 1057 =  if
      " Display Grackle Bridge Chip Parameters "
      ['] config-g   grackle.icon     1 2  install-icon
   else
      " Display Golden Gate Bridge Chip Parameters "
      ['] config-g   bridge.icon     1 2  install-icon
   then
   
   " Display System Time and Date "
   ['] time-is   time.icon     1 3  install-icon

   " Exit to previous menu "
   ['] menu-done           exit.icon	   2  cols 1-  install-icon
;

: config-menu  ( -- )  ['] install-config-menu nest-menu  ;

: config-item  ( -- $ xt adr )
   " Manage configuration variables "
   ['] config-menu  config.icon
;

headers
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
