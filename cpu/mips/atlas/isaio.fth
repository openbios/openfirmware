purpose: Access to ISA IO space for the Atlas board
copyright: Copyright 2000 Firmworks  All Rights Reserved

headers
kseg1 uart-pa + value uart-base

: pc@  ( offset -- n )  3 lshift uart-base + rb@  ;
: pc!  ( n offset -- )  3 lshift uart-base + rb!  ;
: pw@  ( offset -- n )  3 lshift uart-base + rw@  ;
: pw!  ( n offset -- )  3 lshift uart-base + rw!  ;
: pl@  ( offset -- n )  3 lshift uart-base + rl@  ;
: pl!  ( n offset -- )  3 lshift uart-base + rl!  ;
