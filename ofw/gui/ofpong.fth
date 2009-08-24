\ Adapted from  http://members.aol.com/plforth/ofpong/20020313/ofpong.txt
\ See also http://members.aol.com/plforth/ofpong/index.html
\ Originally from  1.0d1 MacHack '98 release of OFPong.of found in OFPONG.SIT.

decimal

 0 value erasecol
-1 value drawcol

0 value key_left_up
0 value key_left_down
0 value key_right_up
0 value key_right_down
0 value key_esc
0 value key_off

0 value grandseed
0 value glastupdate
0 value loopcount
0 value totalupdate

0 value ballstop

0 value ballx
0 value bally

0 value balldx
0 value balldy

0 value leftbaty
0 value rightbaty
0 value batdy

0 value leftscore
0 value rightscore

640 value screenw
480 value screenh

20 value ballsize
ballsize 2 / value scoresize
ballsize 5 * value batsize
1000 value pscale

0 value ball_limit_x
ballsize pscale * value ball_limit_lo_y
0 value ball_limit_hi_y

ballsize pscale * value bat_limit_lo_y
0 value bat_limit_hi_y

0 value hit_limit_left_lo_x
ballsize 2 * pscale * value hit_limit_left_hi_x
0 value hit_limit_right_lo_x
0 value hit_limit_right_hi_x

ballsize pscale * value reflect_left_x
0 value reflect_right_x

: initlimits
   " dimensions" $call-screen to screenh  to screenw
   screenw ballsize - pscale * to ball_limit_x
   screenh ballsize 2 * - pscale * to ball_limit_hi_y
   screenh ballsize batsize + - pscale * to bat_limit_hi_y
   screenw ballsize 3 * - pscale * to hit_limit_right_lo_x
   screenw ballsize - pscale * to hit_limit_right_hi_x

   screenw ballsize 2 * - pscale * to reflect_right_x
   get-msecs to grandseed
;

: random ( -- n ) grandseed 16807 * 17 + abs to grandseed grandseed 1000 mod ;
: unscale ( n -- n ) pscale 2/ + pscale / ;
: calcbatx ( n -- x )  screenw  ballsize 3 *  -  *  ballsize +  ;
: paintrect ( c pixx pixy pixw pixh -- ) " fill-rectangle" $call-screen ;

\needs xy* : xy*  ( x y w h -- x' y' )  rot *  >r  *  r>  ;

\ Big digits for the score

0 0 2value digitxy

: rectcol ( x y w h c -- )
  -rot >r >r  -rot           ( c  x y r: h w )
  scoresize dup  xy*         ( c x' y' r: h w )
  digitxy xy+                ( c base-xy r: h w )
  r> r> scoresize dup xy*    ( c base-xy wh-scaled )
  paintrect
;

: blackrect ( x y w h -- ) drawcol rectcol ;
: whiterect ( x y w h -- ) erasecol rectcol ;

: drawblank ( -- )  0 0 4 7 whiterect  ;

: drawzero ( -- )
  0 0 1 7 blackrect
  1 0 2 1 blackrect
  1 6 2 1 blackrect
  3 0 1 7 blackrect
  1 3 2 1 whiterect
;

: drawone ( -- )
  3 0 1 7 blackrect
  0 0 3 7 whiterect
;

: drawtwo ( -- )
  0 0 4 1 blackrect
  3 1 1 2 blackrect
  0 3 4 1 blackrect
  0 4 1 2 blackrect
  0 6 4 1 blackrect
  0 1 1 2 whiterect
  3 4 1 2 whiterect
;

: drawthree ( -- )
  0 0 4 1 blackrect
  3 1 1 2 blackrect
  0 3 4 1 blackrect
  3 4 1 2 blackrect
  0 6 4 1 blackrect
  0 1 1 2 whiterect
  0 4 1 2 whiterect
;

: drawfour ( -- )
  0 0 1 3 blackrect
  0 3 3 1 blackrect
  3 0 1 7 blackrect
  1 0 2 1 whiterect
  0 4 3 3 whiterect
;

: drawfive ( -- )
  0 0 4 1 blackrect
  0 1 1 2 blackrect
  0 3 4 1 blackrect
  3 4 1 2 blackrect
  0 6 4 1 blackrect
  3 1 1 2 whiterect
  0 4 1 2 whiterect
;

: drawsix ( -- )
  0 0 1 7 blackrect
  1 3 2 1 blackrect
  1 6 2 1 blackrect
  3 3 1 4 blackrect
  1 0 3 3 whiterect
;

: drawseven ( -- )
  0 0 3 1 blackrect
  3 0 1 7 blackrect
  0 1 3 6 whiterect
;

: draweight ( -- )
  0 0 4 1 blackrect
  0 1 1 2 blackrect
  3 1 1 2 blackrect
  0 3 4 1 blackrect
  0 4 1 2 blackrect
  3 4 1 2 blackrect
  0 6 4 1 blackrect
;

: drawnine ( -- )
  0 0 1 4 blackrect
  1 0 2 1 blackrect
  1 3 2 1 blackrect
  3 0 1 7 blackrect
  0 4 3 3 whiterect
;

: drawdigit ( x y n -- )
   -rot  to digitxy      ( n )
   case
      0  of  drawzero   endof
      1  of  drawone    endof
      2  of  drawtwo    endof
      3  of  drawthree  endof
      4  of  drawfour   endof
      5  of  drawfive   endof
      6  of  drawsix    endof
      7  of  drawseven  endof
      8  of  draweight  endof
      9  of  drawnine   endof
   endcase
;

: drawnumber ( startx starty num -- )
   abs  100 /mod drop  10 /mod        ( startxy 1s 10s )
   swap >r >r                         ( startxy r: 10s 1s )
   2dup  r>  drawdigit                ( startxy r: 1s )
   scoresize 5 * 0 xy+  r> drawdigit  ( )
;

\ Ball and bats

: plotball ( x y -- )
   drawcol -rot   swap unscale   swap unscale  ballsize ballsize  paintrect
;
: eraseball ( x y -- )
   erasecol -rot  swap unscale   swap unscale  ballsize ballsize  paintrect
;
: plotbat ( x y -- )
   drawcol -rot   swap           swap unscale  ballsize batsize  paintrect
;
: erasebat ( x y -- )
   erasecol -rot  swap           swap unscale  ballsize batsize  paintrect
;

: redraw ( -- )
   drawcol  0 0                    screenw  ballsize  paintrect
   drawcol  0 screenh  ballsize -  screenw  ballsize  paintrect

  drawcol  screenw scoresize - 2/   ballsize 2*
  scoresize  screenh ballsize 4 * -  paintrect
  
  ballsize 7 *  ballsize 2*  leftscore  drawnumber
  screenw  ballsize 7 *  9 scoresize * + -  ballsize 2*  rightscore  drawnumber
  0 calcbatx  leftbaty   plotbat
  1 calcbatx  rightbaty  plotbat
  ballx bally plotball
;

: drawboard ( -- )
  drawcol   0 0  screenw screenh  paintrect
  erasecol  0 0  screenw screenh  paintrect
  redraw
;

: resetball ( -- )
  500 to ballstop
  screenw ballsize - 2 / pscale *  ballx pscale mod  +  random +  to ballx
  screenh ballsize - 2 / pscale *  bally pscale mod  +  random +  to bally
  
  random  screenw pscale *  *  2000000 /  to balldx
  random  screenh pscale *  *  2000000 /  to balldy
  balldx  screenw pscale *      3000 / +  to balldx
  balldy  screenh pscale *      6000 / +  to balldy
  
  random 500 < if  balldx negate to balldx  then
  random 500 < if  balldy negate to balldy  then
;

: initvalues ( -- )
  ballsize 2* pscale *  to leftbaty
  screenh ballsize 2 * - batsize - pscale *  to rightbaty
  
  screenh pscale * 1000 / to batdy
;

: doreset ( -- )
   resetball
   0 to leftscore
   0 to rightscore
   drawboard
;

\ Keyboard drivers; just receiving keys is usually not good enough;
\ the response is too slow.  It is better to get up/down events or
\ poll key states if you can.

[ifdef] olpc
\ This works with the FirmWorks pckbd driver.  The key map below
\ is good for the OLPC keyboard.
[ifdef] keyboard-ih
alias pong-ih keyboard-ih
[else]
: pong-ih stdin @ ;
[then]   

: initkeys
   ." Shift, Hand, Esc, Square" cr
   d# 3000 ms
   false to key_left_up
   false to key_left_down
   false to key_right_up
   false to key_right_down
   false to key_esc
   false to key_off
;
: restorekeys
;
0 value e0-seen?
: scankeys
   begin  0 " get-scancode" pong-ih $call-method  while   ( scancode )
      dup h# e0 =  if
         drop  true to e0-seen?
      else
         dup h# 80 and 0=  swap h# 7f and     ( down? station )
         case
            h# 65  of
               e0-seen?  if  to key_right_up  else  to key_left_up  then
            endof   \ game up
            h# 66  of
               e0-seen?  if  to key_right_down  else  to key_left_down  then
            endof   \ game down
            h# 69  of  to key_esc        endof   \ lower left game button
            h# 2a  of  to key_left_up    endof   \ shift-left
            h# 5b  of  to key_left_down  endof   \ hand-left
            h# 36  of  to key_right_up   endof   \ shift-right
            h# 5c  of  to key_right_down endof   \ hand-right
            h# 5d  of  to key_esc        endof   \ square
            h#  1  of  to key_off        endof   \ ESC scancode
            nip 
         endcase
         false to e0-seen?
      then
   repeat
;
[else]
\ This version uses "key" with normal ASCII.  It is typically too slow
\ dup to limited keyboard repeat rate.
: initkeys ;
: restorekeys ;
: scankeys
   false to key_left_up
   false to key_left_down
   false to key_right_up
   false to key_right_down
   false to key_esc
   false to key_off
   0 to key_esc
   key?  if
     key upc  case
        [char] A  of  true to key_left_up    endof
        [char] Z  of  true to key_left_down  endof
        [char] '  of  true to key_right_up   endof
        [char] /  of  true to key_right_down endof
        27        of  true to key_esc        endof
        8         of  true to key_off        endof
     endcase
   then
;
[then]

: moveball ( oldx oldy newx newy -- )  2swap eraseball  plotball  ;

: doupdateball ( delta -- )
  ballx swap bally swap
  
  dup
  
  balldx * ballx + to ballx
  balldy * bally + to bally

  ballx 0<  if
    resetball
    balldx abs negate to balldx
    ballx ballsize 2 * pscale * + to ballx
    rightscore 1 + to rightscore
    rightscore 15 = if
      -1 to ballstop
    then
  then
  ballx ball_limit_x >  if
    resetball
    balldx abs to balldx
    ballx ballsize 2 * pscale * - to ballx
    leftscore 1 + to leftscore
    leftscore 15 = if
      -1 to ballstop
    then
  then

  bally ball_limit_lo_y <  if
    balldy negate to balldy
    ball_limit_lo_y 2 * bally - to bally
  then
  bally ball_limit_hi_y >  if
    balldy negate to balldy
    ball_limit_hi_y 2 * bally - to bally
  then
  
  balldx 0<  if
    ballx hit_limit_left_lo_x hit_limit_left_hi_x between if
      bally leftbaty ballsize pscale * - leftbaty batsize pscale * + between if
        
        bally leftbaty <  if
          balldy abs negate to balldy
        then
        
        bally leftbaty batsize ballsize - pscale * + >  if
          balldy abs to balldy
        then      

        ballx reflect_left_x >  if
          balldx abs random 50 / + to balldx

          leftbaty bally - unscale
          dup 0 batsize between  if
            batsize 2 / - random * 2 / batsize / 25 / balldy + to balldy
          else
            drop
          then
        then
      then
    then
  then
  
  balldx 0>  if
    ballx hit_limit_right_lo_x hit_limit_right_hi_x between  if
      bally rightbaty ballsize pscale * - rightbaty batsize pscale * + between if
      
        bally rightbaty <  if
          balldy abs negate to balldy
        then
        
        bally rightbaty batsize ballsize - pscale * + >  if
          balldy abs to balldy
        then      

        ballx reflect_right_x <  if
          balldx abs random 50 / + negate to balldx

          rightbaty bally - unscale
          dup 0 batsize between  if
            batsize 2 / - random * 2 / batsize / 25 / balldy + to balldy
          else
            drop
          then
        then
      then
    then
  then

  bally ball_limit_lo_y <  if
    ball_limit_lo_y to bally
  then
  bally ball_limit_hi_y >  if
    ball_limit_hi_y to bally
  then

  ballx bally moveball
;

: updateball ( delta -- )
  ballstop 0=  if
    doupdateball
  else
    ballstop -1 =  if
      drop
    else
      ballstop swap - to ballstop
      ballstop 0<=  if
        0 to ballstop
      then
    then
  then
;

0 value batx
: movebatup ( oldp delta -- )
   2dup >r >r   ( oldp delta  r: delta oldp )
   erasecol  batx  r> batsize + r@ +  ballsize  r> negate  paintrect

   >r >r        ( r: delta oldp )
   drawcol   batx  r>           r@ +  ballsize  r> negate  paintrect
;

: movebatdown ( oldp delta -- )
   2dup >r >r    ( oldp delta  r: delta oldp )
   erasecol  batx  r>                ballsize r>          paintrect

   >r >r        ( r: delta oldp )
   drawcol   batx  r> batsize +      ballsize r>          paintrect
;

: movebat ( n oldy newy -- )
  rot calcbatx to batx  swap            ( newy oldy )
  over unscale  over unscale -  ( newy oldy deltay )
  dup abs  batsize <  if        ( newy oldy deltay )
    dup  if                     ( newy oldy deltay )
      dup  0<  if               ( newy oldy deltay )
        swap unscale  swap  movebatup    ( newy )
      else
        swap unscale  swap  movebatdown  ( newy )
      then                               ( newy )
      drop                               ( )
    else                        ( newy oldy deltay )
      3drop                     ( )
    then                        ( )
  else                          ( newy oldy deltay )
    drop                        ( newy oldy )
    batx swap erasebat          ( newy )
    batx swap plotbat           ( )
  then
;

: updatebats ( deltat -- )
  >r
  0 leftbaty 0      ( n oldy deltay )

  over bat_limit_lo_y >  if
     key_left_up  if  batdy -  then
  then

  over bat_limit_hi_y <  if
     key_left_down  if  batdy +  then
  then

  r@ *               ( n oldy deltay' ) \ Scale by the elapsed time
  over +             ( n oldy newy )
  dup to leftbaty    ( n oldy newy )
  movebat
  
  1 rightbaty 0  ( 1 right dy )

  over bat_limit_lo_y >  if
     key_right_up  if  batdy -  then
  then

  over bat_limit_hi_y <  if
     key_right_down  if  batdy +  then
  then

  r> * over +
  dup to rightbaty
  movebat
;

: initeverything ( -- )
  cr
  0 to loopcount
  0 to totalupdate
  initlimits
  initvalues
  initkeys
  doreset
  get-msecs to glastupdate 
;

: doloop ( deltat -- )
  loopcount 1 + to loopcount
  dup totalupdate + to totalupdate

  dup updatebats
  dup updateball
  redraw

  glastupdate + to glastupdate
;

: pong ( -- )
  initeverything
  begin
    get-msecs glastupdate -
      dup 0> if
        dup 250 > if
          drop
          get-msecs to glastupdate
          250
        then
        doloop
      else
        drop
      then
    scankeys
    key_esc  if  doreset  begin scankeys key_esc 0= until   then
  key_off until
  restorekeys
  h# ffff 0 0 screenw screenh paintrect
  page
\  " Count:" type loopcount .d cr
\  " Avg millisec:" type totalupdate loopcount / .d cr
;

hex

\ pong
