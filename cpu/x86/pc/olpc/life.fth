
\ rgb color value
h# ff    ff     0  rgb>565 constant lf_fg    \ yellow
h#  0     0     0  rgb>565 constant lf_bg    \ black

\ screen size constant
d# 128 constant lf_width
d#  95 constant lf_height

\ board and working area
lf_width lf_height * constant /board
/board buffer: lf_board
/board buffer: lf_board_work  

\ some macros to get a linear address o a cell of board or working area
: >offset ( i j -- lin_addr ) swap lf_width *  + ;
: >cell  ( i j -- adr )  swap lf_width *  + lf_board +  ;
: >work  ( i j -- adr )  swap lf_width *  + lf_board_work +  ;

: show-cell  ( state y x -- )
   >offset swap  if  lf_fg  else  lf_bg  then  show-state
;

\ display the board of life
: lf_board_print  ( -- )
   lf_height 1-  1  do 
      lf_width 1- 1  do 
         j i >cell c@  j i  show-cell
      loop
   loop
;

\ working variable
variable cell-sum

: xy+  ( x1 y1 x2 y2 -- x3 y3 )  rot +  -rot +  swap ;

code sumcell  ( adr -- sum )
   bx pop
   ax ax xor
   lf_width    negate [bx]  al add
   lf_width 1- negate [bx]  al add
   lf_width 1+ negate [bx]  al add
   -1                 [bx]  al add
    1                 [bx]  al add
   lf_width           [bx]  al add
   lf_width 1-        [bx]  al add
   lf_width 1+        [bx]  al add

   ax push
c;


: +sum  ( i j +i +j -- i j )
   2over xy+             ( i j i' j' )
   >cell c@ cell-sum +!  ( i j )
;

: lf_check_live_i_j  ( i j -- ncell )
[ifdef] notdef
   cell-sum off      ( i j )
   -1 -1 +sum
   -1  0 +sum
   -1  1 +sum
    0 -1 +sum
    0  1 +sum
    1 -1 +sum
    1  0 +sum
    1  1 +sum        ( i j )
   2drop cell-sum @  ( sum )
[else]
    >offset lf_board + sumcell
[then]
;

\ one step evolve the board
: lf_board_evolve

   \ copy the line before the last to the first one and the second to the last
   lf_board lf_width lf_height 2 - * + lf_board lf_width move
   lf_board lf_width + lf_board lf_width lf_height 1 - * + lf_width move

   \ copy the column before last to the first one and the second to the last
   lf_board               ( adr )
   lf_height 0   do       ( adr )
      dup lf_width +          ( adr end-adr )
      over 1+ c@  over 1- c!  ( adr end-adr )
      tuck 2- c@  swap c!     ( end-adr )
   loop
   drop

   0                                    ( row-offset )
   lf_height 1-  1  do                  ( row-offset )
      lf_width +                        ( row-offset )
      dup 1+  lf_width 2-  bounds  do   ( row-offset )
         i lf_board +  dup sumcell      ( row adr sum1 )
         swap c@ if                     ( row sum1 )
            \ caso in cui nella cella c'e' 1
            2 3 between                 ( row 0|-1 )
            dup 0=  if  i  lf_bg show-state  then
         else                           ( row sum1 )
            \ caso in cui nella cella c'e' 0
            3 =                         ( row 0|-1 )
            dup  if  i  lf_fg show-state  then
         then                           ( row 0|-1 )
         negate                         ( row 0|1 )
         i lf_board_work + c!           ( row 0|1 )
      loop                              ( row )
   loop
   drop
[then]
   lf_board_work  lf_board  /board  move
;

: compile-pattern  ( -- )
   begin  refill  while
      parse-word  tuck  ",
      0=  if  exit  then
   repeat
;
: place-pattern  ( x y adr -- )
   -rot >cell  swap       ( board-adr pattern-adr )
   begin  dup c@  while   ( board-adr pattern-adr )
      2dup count  bounds  ?do      ( board-adr pattern-adr board-adr )
         i c@ [char] . <> negate   ( board-adr pattern-adr board-adr value )
         over c!  1+               ( board-adr pattern-adr board-adr' )
      loop                         ( board-adr pattern-adr board-adr )
      drop                         ( board-adr pattern-adr )
      swap lf_width +  swap +str   ( board-adr' pattern-adr' )
   repeat                 ( board-adr pattern-adr )
   2drop
;
: life-pattern:
   create  compile-pattern
   does>  ( x y adr )  place-pattern
;

life-pattern: r-pentomino
.**
**.
.*.

life-pattern: twin-bees
.OO........................
.OO........................
...........................
...............O...........
OO.............OO........OO
OO..............OO.......OO
...........OO..OO..........
...........................
...........................
...........................
...........OO..OO..........
OO..............OO.........
OO.............OO..........
...............O...........
...........................
.OO........................
.OO........................

life-pattern: turtle
.OOO.......O
.OO..O.OO.OO
...OOO....O
.O..O.O...O
O....O....O
O....O....O
.O..O.O...O
...OOO....O
.OO..O.OO.OO
.OOO.......O

life-pattern: gosper-gun
........................O
......................O.O
............OO......OO............OO
...........O...O....OO............OO
OO........O.....O...OO
OO........O...O.OO....O.O
..........O.....O.......O
...........O...O
............OO


: erase-board  ( -- )  lf_board /board erase  ;

\ initialize data
: set-cell  ( i j -- )  >cell  1 swap c!  ;
: init-board  ( -- )
;
hex

: generations  ( n -- )
   cursor-off  " erase-screen" $call-screen   
   lf_board_print
   ( n )  0  do
      lf_board_evolve
      key?  if  key drop  leave  then
   loop
   cursor-on
;
: life-demo  ( -- )
   page
   erase-board
   d# 20 d# 78 r-pentomino
   d# 51 d# 21 gosper-gun
   d# 5500 generations
;

life-pattern: toad-flipper
.O..............O.
.O..............O.
O.O............O.O
.O..............O.
.O......O.......O.
.O......OO......O.
.O......OO......O.
O.O......O.....O.O
.O..............O.
.O..............O.


: flip-toad
   page
   erase-board
   d# 40 d# 40 toad-flipper
   d# 500 generations
;

\ 500 generations
