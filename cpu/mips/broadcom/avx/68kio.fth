purpose: Access to 68K IO space
copyright: Copyright 2001 Firmworks  All Rights Reserved

headers
68k-io-base value io-base

: pc@  ( offset -- n )  io-base + rb@  ;
: pc!  ( n offset -- )  io-base + rb!  ;
: pw@  ( offset -- n )  io-base + rw@  ;
: pw!  ( n offset -- )  io-base + rw!  ;
: pl@  ( offset -- n )  io-base + rl@  ;
: pl!  ( n offset -- )  io-base + rl!  ;
