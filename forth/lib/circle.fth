\ Midpoint circle algorithm - see http://en.wikipedia.org/wiki/Midpoint_circle_algorithm
decimal

d# 12 constant radius

radius value y
0 value x
3 radius 2* - value err

: step  ( -- )
   x . y . err . cr
   err 0< if
      x 2* 2*  6 + err + to err
   else
      x y - 2* 2* d# 10 + err + to err
      y 1- to y
   then
   x 1+ to x
;
step step step step step step step step step
