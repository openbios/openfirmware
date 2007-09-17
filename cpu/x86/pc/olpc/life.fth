
\ rgb color value
h# ff     0     0  rgb>565 constant xred      \ red
h#  0     0     0  rgb>565 constant xblack    \ black

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
   >offset swap  if  xred  else  xblack  then  show-state
;

\ display the board of life
: lf_board_print  ( -- )
   lf_height 0  do 
      lf_width 0  do 
         j i >cell c@  j i  show-cell
      loop
   loop
;

\ working variable
variable cell-sum

: xy+  ( x1 y1 x2 y2 -- x3 y3 )  rot +  -rot +  swap ;

: +sum  ( i j +i +j -- i j )
   2over xy+             ( i j i' j' )
   >cell c@ cell-sum +!  ( i j )
;

: lf_check_live_i_j  ( i j -- ncell )
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
;

\ one step evolve the board
: lf_board_evolve

   \ copy the line before the last to the first one and the second to the last
   lf_board lf_width lf_height 2 - * + lf_board lf_width move
   lf_board lf_width + lf_board lf_width lf_height 1 - * + lf_width move

   \ copy the column before last to the first one and the second to the last
   lf_height 0   do
     i lf_width 2 - >cell @ i 0 >cell c!
     i 1 >cell @ i lf_width 1 - >cell c!
   loop

   lf_height 1 -  1  do
      lf_width 1 - 1  do
         j i lf_check_live_i_j ( sum1 )
         j i >cell c@ if      ( sum1 )
            \ caso in cui nella cella c'e' 1
            2 3 between        ( 0|-1 )
         else                  ( sum1 )
            \ caso in cui nella cella c'e' 0
            3 =                ( 0|-1 )
         then
         negate                ( 0|1 )
         dup  j i >work c!     ( 0|1 )
         dup j i >cell c@ <>  if  ( 0|1 )
            j i show-cell
         else
            drop
         then
      loop
   loop
   lf_board_work  lf_board  /board  move
;

decimal
\ initialize data
: set-cell  ( i j -- )  >cell  1 swap c!  ;
: init-board  ( -- )
   lf_board /board erase
[ifdef] notdef
   2 2 set-cell
   3 3 set-cell
   4 3 set-cell
   4 2 set-cell
   4 1 set-cell
[else]

   \ R-pentominos
   \ This placement evolves nicely
   \ 20 20 set-cell  20 21 set-cell  21 19 set-cell  21 20 set-cell  22 20 set-cell

   \ This placement is boring
   \ 40 20 set-cell  40 21 set-cell  41 19 set-cell  41 20 set-cell  42 20 set-cell

   \ This one is excellent!
   \ 20 40 set-cell  20 41 set-cell  21 39 set-cell  21 40 set-cell  22 40 set-cell
   
   \ This one almost dies out, then explodes into a complex arrangement with
   \ stuff happening everywhere.
   \ 20 60 set-cell  20 61 set-cell  21 59 set-cell  21 60 set-cell  22 60 set-cell

   \ This one takes a long time to kill off the glider gun, then lasts for a long time
   \ 20 80 set-cell  20 81 set-cell  21 79 set-cell  21 80 set-cell  22 80 set-cell

   \ This one takes out the block at the right side of the glider gun, which
   \ disperses in an interesting pattern, then the whole arena dies quickly
   \ 20 78 set-cell  20 79 set-cell  21 77 set-cell  21 78 set-cell  22 78 set-cell

   \ This one is absolutely brilliant!  It takes out the glider gun, which
   \ disperse in a boring way, but then the rest of the pattern just keeps
   \ changing and changing, after looking like it is about to die several times.
   \ It eventually dies about about 5000 generations.
   20 79 set-cell  20 80 set-cell  21 78 set-cell  21 79 set-cell  22 79 set-cell

   \ Glider gun
   55 21 set-cell
   55 22 set-cell
   56 21 set-cell
   56 22 set-cell
   53 34 set-cell
   53 33 set-cell
   54 32 set-cell
   55 31 set-cell
   56 31 set-cell
   57 31 set-cell
   58 32 set-cell
   59 33 set-cell
   59 34 set-cell
   56 35 set-cell
   54 36 set-cell
   55 37 set-cell
   56 37 set-cell
   56 38 set-cell
   57 37 set-cell
   58 36 set-cell

   55 41 set-cell
   54 41 set-cell
   53 41 set-cell
   55 42 set-cell
   54 42 set-cell
   53 42 set-cell

   52 43 set-cell
   52 45 set-cell
   51 45 set-cell
   56 43 set-cell
   56 45 set-cell
   57 45 set-cell

   53 55 set-cell
   53 56 set-cell
   54 55 set-cell
   54 56 set-cell

[then]
;
hex

: show-board  ( -- )
   cursor-off  " erase-screen" $call-screen   
   lf_board_print
;

\ Version that displays the result in-place
: generations  ( n -- )
   show-board
   ( n )  0  do   lf_board_evolve  loop
;
: life  ( #generations -- )
   page
   init-board
   generations
;

\ 500 generations
