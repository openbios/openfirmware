dev /packages
new-device

" touchgrid" device-name

0 instance value offset-x
0 instance value offset-y
0 instance value pitch-x
0 instance value pitch-y
0 instance value x-cols
0 instance value y-rows
0 instance value full?

: full-grid  ( x-cols y-rows -- )
   to y-rows  to x-cols                  ( )

   screen-wh                             ( w h )

   dup y-rows /  to pitch-y              ( w h )
   y-rows pitch-y * - 2/ to offset-y     ( w )
   
   dup x-cols /  to pitch-x              ( w )
   x-cols pitch-x * - 2/ to offset-x     ( )

   true to full?                         ( )
;
: exact-grid  ( offset-x offset-y  pitch-x pitch-y  x-cols y-rows  -- )
   to y-rows  to x-cols  to pitch-y  to pitch-x  to offset-y  to offset-x
   false to full?
;

: dimensions  ( -- w h )  " dimensions" $call-parent  ;
: pad?  ( -- false | x y z down? contact# true )  " pad?" $call-parent  ;

: hit?  ( -- false | x-col y-row down? contact# true )
   pad?  0=  if  false exit  then    ( x y z down? contact# )
   rot drop  2>r                     ( x y r: down? contact# )
   swap offset-x - pitch-x /         ( y x-col  r: down? contact# )
   swap offset-y - pitch-y /         ( x-col y-row  r: down? contact# )
   full?  if                         ( x-col y-row  r: down? contact# )
      swap  0 max  x-cols min        ( y-row x-col'  r: down? contact# )
      swap  0 max  y-rows min        ( x-col y-row'  r: down? contact# )
   else                              ( x-col y-row  r: down? contact# )
      over 0 x-cols within 0=  if    ( x-col y-row  r: down? contact# )
	 2r> 4drop false exit        ( -- false )
      then                           ( x-col y-row  r: down? contact# )
      dup 0 y-rows within 0=  if     ( x-col y-row  r: down? contact# )
	 2r> 4drop false exit        ( -- false )
      then                           ( x-col y-row  r: down? contact# )
   then                              ( x-col y-row  r: down? contact# )
   2r>  true
;

0 instance value down?
: one-hit?  ( -- false | x-col y-row true )
   hit?  if                   ( x-col y-row down? contact# )
      if                      ( x-col y-row down? )
	 \ Primary contact
	 if                   ( x-col y-row )
	    \ Touch event
	    down?  if         ( x-col y-row )
	       \ Suppress repetition
	       2drop false    ( false )
	    else              ( x-col y-row )
               \ Initial touch - return coordinates
	       true to down?  ( x-col y-row )
               true           ( x-col y-row true )
	    then              ( false | x-col y-row true )
	 else                 ( x-col y-row )
            \ Release event
	    false to down?    ( x-col y-row )
	    2drop false       ( false )
	 then                 ( false | x-col y-row true )
      else                    ( x-col y-row down? )
	 \ Ignore non-primary contacts
	 3drop false          ( false )
      then                    ( false | x-col y-row true )
   else                       ( )
      false                   ( false )
   then                       ( false | x-col y-row true )
;
: #contacts  ( -- n )  " #contacts" $call-parent  ;
: open  ( -- okay? )  true  ;
: close  ( -- )  ;

0 [if]
0 value #contacts
0 value contacts

: one-hit?  ( -- false | x-col y-row true )
   hit?  if              ( x-col y-row down? contact# )
      contacts na+       ( x-col y-row down? 'contact )
      swap  if           ( x-col y-row 'contact )
         dup @  if       ( x-col y-row 'contact )
	    3drop false  ( false )  \ Ignore continued down
         else            ( x-col y-row 'contact )
            on           ( x-col y-row )
	    true         ( x-col y-row true )
         then            ( false | x-col y-row true )
      else               ( x-col y-row 'contact )
         off             ( x-col y-row )
	 2drop false     ( false )
   else                  ( )
      false              ( false )
   then                  ( false | x-col y-row true )
;
[then]

finish-device
device-end
