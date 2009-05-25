purpose: Interrupt handlers
copyright: Copyright 2001 FirmWorks  All Rights Reserved

headers
hex

: .intr-sw  ( intr# -- )  ." Software Interrupt " u. cr  ;
: (intr-sw0)  ( -- )  0 .intr-sw  ;  ' (intr-sw0) to intr-sw0
: (intr-sw1)  ( -- )  1 .intr-sw  ;  ' (intr-sw1) to intr-sw1

: .intr-hw  ( intr# -- )  ." Hardware Interrupt " u. cr  ;
' dispatch-interrupt to intr-hw0
' dispatch-interrupt to intr-hw1
: (intr-hw2)  ( -- )  2 .intr-hw  ;  ' (intr-hw2) to intr-hw2
: (intr-hw3)  ( -- )  3 .intr-hw  ;  ' (intr-hw3) to intr-hw3
: (intr-hw4)  ( -- )  4 .intr-hw  ;  ' (intr-hw4) to intr-hw4

headers

