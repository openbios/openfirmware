\ See license at end of file
purpose: Accelerometer test

: 3!  ( n1 n2 n3 adr -- )  tuck 2 na+ !  2!  ;
: 3@  ( adr -- n1 n2 n3 )  dup 2@  rot 2 na+ @  ;
3 actions
action: >user 3@  ;
action: >user 3!  ;
action: >user    ;
: 3value-cf  create-cf use-actions  ;
: 3value  ( n1 n2 n3 "name" -- )  header 3value-cf  3 /n* user#,  3!  ;

0 0 0 3value pos-b  \ Ball position
0 0 0 3value vel-b  \ Ball velocity

[ifdef] notdef
0 0 0 3value acc-0  \ Accelerometer calibration
[then]

d# 8 value #fraction-bits
: fraction*  ( -- )  * #fraction-bits >>a  ;
: 1/2  ( -- n )  1 #fraction-bits 1- lshift  ;
: >fraction  ( n -- fraction )  #fraction-bits lshift  ;
: a/b>fraction  ( num denom -- fraction )  swap #fraction-bits lshift  swap /  ;

: xyz*  ( x,y,z factor -- x',y',z' )
   >r
   rot r@ fraction*
   rot r@ fraction*
   rot r> fraction*
;
: xyz+  ( x1 y1 z1 x2 y2 z2 -- x3 y3 z3 )
   3 roll + >r  ( x1 y1 x2 y2 r: z3 )
   rot + >r     ( x1 x2  r: z3 y3 )
   +  r> r>     ( x3 y3 z3 )
;   
: xyz-  ( x1 y1 z1 x2 y2 z2 -- x3 y3 z3 )
   3 roll swap - >r  ( x1 y1 x2 y2 r: z3 )
   rot swap - >r     ( x1 x2  r: z3 y3 )
   -  r> r>          ( x3 y3 z3 )
;   

: xyz>fraction  ( x y z -- x' y' z' )
   rot #fraction-bits lshift
   rot #fraction-bits lshift
   rot #fraction-bits lshift
;
: xyz>integer  ( x y z -- x' y' z' )
   1/2 dup dup  xyz+          \ Round up
   rot #fraction-bits >>a
   rot #fraction-bits >>a
   rot #fraction-bits >>a
;

0 value accel-ih
: get-acceleration  ( -- x y z )
   " acceleration@" accel-ih $call-method  xyz>fraction
;
: init-accelerometer  ( -- )
   accel-ih  if  exit  then
   " /accelerometer" open-dev to accel-ih
   accel-ih 0= abort" Can't open accelerometer"

[ifdef] notdef
   \ Calibrate the accelerometer by averaging 4 samples
   get-acceleration       ( x y z )
   get-acceleration xyz+  ( x' y' z' )
   get-acceleration xyz+  ( x' y' z' )
   get-acceleration xyz+  ( x' y' z' )
   1 4 a/b>fraction xyz*  to acc-0
[then]
;

\ This is a damping factor for the velocity - essentially a frictional force

d# 19 d# 20 a/b>fraction value damping

d#  1 d# 80  a/b>fraction value acc-scale

d# 20 constant ball-radius
d# 40 constant ball-diameter

d# 1200 ball-diameter - >fraction constant maxx
d#  900 ball-diameter - >fraction constant maxy
d#  400 >fraction constant maxz

: 3swap  ( x1 y1 z1 x2 y2 z2 -- x2 y2 z2 x1 y1 z1 )  5 roll  5 roll  5 roll  ;
: 3over  ( x1 y1 z1 x2 y2 z2 -- x2 y2 z2 x1 y1 z1 )  5 pick  5 pick  5 pick  ;

[ifdef] notdef
0 0 0 3value pos-b' \ New ball position
0 0 0 3value vel-l  \ Laptop velocity

\ The original idea was to model a ball floating in a vat of fluid.
\ Shaking the vat would make the ball move.  That didn't work very well.
: update-laptop  ( -- )
   get-acceleration acc-0 xyz-         ( accl-x,y,z )
   acc-scale xyz*

   \ Compute new position of laptop based on acceleration and current
   \ laptop velocity, and change the coordinate system origin to the
   \ new position.
   3dup 1/2 xyz*  vel-l xyz+           ( accl-x,y,z posl-x,y,z )
   pos-b 3swap xyz-  to pos-b'         ( accl-x,y,z )

   \ Compute new laptop velocity
   vel-l damping xyz*  xyz+  to vel-l  ( )
;

\ This is a simple approximation for the magnitude of a 3-vector
\ - largest component plus 1/3 the sum of the two smaller components.
\ It works surprisingly well, especially since we use it to estimate
\ drag, which is a complicated phenomenon for which the formula is
\ only an approximation anyway.

: xyz-magnitude  ( x y z -- magnitude )
   rot abs rot abs rot abs
   2dup >  if  swap  then      ( x min-y,z max-y,z )
   rot 2dup >  if  swap  then  ( a b max )
   -rot  + 3 /  +              ( magnitude )
;

\ This is a coupling coefficient between the net velocity (laptop - ball)
\ and the ball acceleration.  It encapsulates various constant factors
\ such as the drag coefficient and unit conversions.  Its value is adjusted
\ empirically to make the simulation work nicely.
d# 1 d# 5 a/b>fraction value drag

\ Compute the acceleration on the ball resulting from the drag of
\ the differential velocity between the laptop and the ball.
\ The formula for drag force is a "constant" times the magnitude of
\ the velocity squared, in a direction opposite to the velocity.
\ That can be represented as v^2 times a unit vector.  But that
\ unit vector is velocity-vector/velocity-magnitude.  The magnitude
\ in the denominator cancels one of the numerator ones, leaving
\ velocity-magnitude * velocity-vector.

: compute-drag  ( -- acc-x,y,z )
   vel-l vel-b xyz-            ( vel-x,y,z )
   3dup xyz-magnitude          ( vel-x,y,z velocity-magnitude )
   drag fraction*              ( vel-x,y,z drag-force )
   xyz*                        ( acc-x,y,z )
;
[then]

: inelastic  ( vel -- vel' )   5 * 3 >>a  ;
: -velx  ( -- )  vel-b  rot  negate inelastic  -rot  to vel-b  ;  \ Invert the X component of ball velocity
: -vely  ( -- )  vel-b  swap negate inelastic  swap  to vel-b  ;  \ Invert the Y component of ball velocity
: -velz  ( -- )  vel-b       negate inelastic        to vel-b  ;  \ Invert the Z component of ball velocity

: live-walls  ( x,y,z -- x',y',z' )
   rot  dup 0<  if  negate -velx           then   ( y z x' )
   dup maxx >=  if  maxx 2* swap -  -velx  then   ( y z x' )

   rot  dup 0<  if  negate -vely           then   ( z x y' )
   dup maxy >=  if  maxy 2* swap -  -vely  then   ( z x y' )

   rot  dup 0<  if  negate -velz           then   ( x y z' )
   dup maxz >=  if  maxz 2* swap -  -velz  then   ( x y z' )
;
: walls  ( x,y,z -- x',y',z' )
   rot  dup 0<  if  drop 0     -velx  then   ( y z x' )
   dup maxx >=  if  drop maxx  -velx  then   ( y z x' )

   rot  dup 0<  if  drop 0     -vely  then   ( z x y' )
   dup maxy >=  if  drop maxy  -vely  then   ( z x y' )

   rot  dup 0<  if  drop 0     -velz  then   ( x y z' )
   dup maxz >=  if  drop maxz  -velz  then   ( x y z' )
;

: z>ball-radius  ( z -- radius )  d# 20 / 1+  ;
: xyz>screen  ( x y z -- x' y' radius )
\  maxy 1- rot - swap          ( x y' z )   \ Invert Y axis
   maxz 1- swap -              ( x y z' )   \ Invert Z axis
   xyz>integer                 ( x' y' z' )
   ball-radius 1+ dup 0  xyz+  ( x' y' z' )
   z>ball-radius               ( x y radius )
;
: redraw  ( new-xyz old-xyz -- )
   3swap xyz>screen  3swap xyz>screen   ( new-xyr old-xyr )
   3over 3over xyz-  or or  if          ( new-xyr old-xyr )
      h# ffff set-fg circleat           ( new-xyr )
      0 set-fg circleat                 ( )
   else                                 ( new-xyr old-xyr )
      3drop 3drop                       ( )
   then                                 ( )
;


[ifdef] notdef
d# 20 >fraction constant small
\ An unsuccessful attempt to eliminate ball jitter by reducing
\ acceleration near the edges of the window.
: clip-accel  ( acc pos limit -- acc' )
   over small <=  if       ( acc pos limit )
      debug-me drop 0 max  exit     ( acc' )
   then                    ( acc pos limit )
   small - >=  if          ( acc )
      0 min                ( acc' )
   then                    ( acc )
;
[then]

: net-acceleration  ( -- acc-x,y,z )
   get-acceleration                             ( acc-x,y,z )
   acc-scale xyz*                               ( acc'-x,y,z )

[ifdef] notdef
   rot   pos-b 2drop    maxx clip-accel  -rot   ( acc-x',y,z )
   swap  pos-b drop nip maxy clip-accel  swap   ( acc-x,y',z )
         pos-b nip  nip maxz clip-accel         ( acc-x,y',z' )
[then]
;

[ifdef] notdef
\ An unsuccessful attempt to eliminate ball jitter by forcing
\ small numbers to 0.
: clamp  ( x,y,z -- x',y',z' )
   rot  dup abs small <  if  drop 0  then  -rot
   swap dup abs small <  if  drop 0  then  swap
        dup abs small <  if  drop 0  then
;
[then]

: update-ball  ( -- )
[ifdef] notdef
   compute-drag                                ( acc-x,y,z )
   3dup  1/2 xyz*   vel-b xyz+  pos-b' xyz+    ( acc-x,y,z pos-x,y,z )
[then]

   net-acceleration                             ( acc-x,y,z )
   3dup  1/2 xyz*   vel-b xyz+  pos-b xyz+      ( acc-x,y,z pos'-x,y,z )

   3swap vel-b damping xyz*  xyz+ to vel-b      ( acc-x,y,z )
   walls                                        ( pos'-x,y,z )
   3dup pos-b redraw                            ( pos'-x,y,z )
   to pos-b                                     ( )
;

: init-ball  ( -- )
   maxx maxy maxz  1/2 xyz*  to pos-b
   0 0 0 to vel-b  ( 0 0 0 to vel-l )
;
: roller  ( -- )
   init-accelerometer
   init-ball
   text-off
   clear-drawing
   begin  ( update-laptop ) update-ball  d# 50 ms  key? until
   text-on
;

\ LICENSE_BEGIN
\ Copyright (c) 2011 FirmWorks
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
