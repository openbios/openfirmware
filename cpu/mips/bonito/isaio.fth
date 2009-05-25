purpose: Access to ISA IO space
copyright: Copyright 2000 Firmworks  All Rights Reserved

headers
isa-io-base value io-base

: pc@  ( offset -- n )  io-base + rb@  ;
: pc!  ( n offset -- )  io-base + rb!  ;
: pw@  ( offset -- n )  io-base + rw@  ;
: pw!  ( n offset -- )  io-base + rw!  ;
: pl@  ( offset -- n )  io-base + rl@  ;
: pl!  ( n offset -- )  io-base + rl!  ;
