\ See license at end of file
purpose: Hashes (MD5, SHA1, SHA-256) using Marvell hardware acceleration

h# 8101 constant dval
: dma>hash  ( adr len -- )
   4 round-up  2 rshift  h# d429080c l!   ( adr )
   h# d4290808 l!                         ( )
   dval h# d4290800 l!                    ( )
\  begin  h# d4290814 l@  1 and  until
;
: dma-stop  h# d4290800 l@ 1 invert and h# d4290800 l!   ;
: swap-axi-bytes  ( -- )  h# 5 h# d4290838 l!  ;  \ Byte swap input and output
: in-fifo-remain  ( -- n )  h# d429083c l@  ;
\ : in-fifo@  ( -- n )  h# d4290880 l@  ;
\ : in-fifo!  ( n -- )  h# d4290880 l!  ;
\ : out-fifo@  ( -- n )  h# d4290900 l@  ;
\ : out-fifo!  ( n -- )  h# d4290900 l!  ;

h# 40 value /hash-block
d# 20 value /hash-digest
/hash-block 2* buffer: (hash-buf)
: hash-buf  ( -- adr )  (hash-buf) /hash-block round-up  ;  \ Aligned
0 value #hash-buf
0 value #hashed

: use-sha1    ( -- )  0 h# d4291800 l!  d# 20 to /hash-digest  ;
: use-sha256  ( -- )  1 h# d4291800 l!  d# 32 to /hash-digest  ;
: use-sha224  ( -- )  2 h# d4291800 l!  d# 28 to /hash-digest  ;
: use-md5     ( -- )  3 h# d4291800 l!  d# 16 to /hash-digest  ;

: hash-control!  ( n -- )  h# d4291804 l!  ;
: hash-go  ( -- )
   1 h# d4291808 l!
   begin  h# d429180c l@  1 and  until
   1 h# d429180c l!
;
: set-msg-size  ( n -- )
   0 h# d429181c l! \ High word of total size
   h# d4291818 l!   \ Low word of total size
;
: hash-init  ( -- )
   1 h# d4290c00 l!  \ Select hash (0) for Accelerator A, crossing to direct DMA to it
   dma-stop
   8 hash-control!  \ Reset
   0 hash-control!  \ Unreset
   1 hash-control!  \ Init digest
   hash-go
   0 to #hash-buf
   0 to #hashed
;

: hash-update-step  ( -- )
   hash-buf  /hash-block dma>hash   ( )
   /hash-block h# d4291810 l!       ( )
   2 hash-control!  \ Update digest ( )
   hash-go                          ( )
   dma-stop
;
: copy-to-hashbuf  ( adr thislen -- )
   tuck                             ( adr thislen )
   hash-buf #hash-buf +  swap move  ( thislen )
   #hash-buf + to #hash-buf         ( )
   #hash-buf /hash-block =  if      ( )
      hash-update-step              ( )
      0 to #hash-buf
   then
;
: hash-update  ( adr len -- adr' len' )
   dup #hashed + to #hashed                ( adr len )
   begin  dup   while                      ( adr len )
      2dup  /hash-block #hash-buf -  min   ( adr len adr this )
      tuck copy-to-hashbuf                 ( adr len this )
      /string                              ( adr' len' )
   repeat                                  ( adr len )
   2drop
;
: hash-final  ( -- )
   #hashed set-msg-size       ( )
   #hash-buf h# d4291810 l!   ( )
   #hash-buf  if
      hash-buf #hash-buf  dma>hash         ( )
   then
   7 hash-control!  \ Final, with hardware padding
   hash-go
   dma-stop
   h# d4291820 /hash-digest
;
: hash1  ( adr len -- )
   hash-init           ( adr len )
   hash-update         ( adr' len' )
   hash-final
;
0 [if]
: hash2  ( adr1 len1 adr2 len2 -- digest$ )
   third over +  >r   ( adr1 len1 adr2 len2 r: total-len )
   hash-init          ( adr1 len1 adr2 len2 r: total-len )
   2swap hash-update  ( adr2 len2  r: total-len )
   hash-update        ( r: total-len )
   r> hash-done       ( digest$ )
;
[then]

: md5  ( adr len -- digest$ )  use-md5  hash1  ;
\ alias $md5digest1 md5

\ : $md5digest2  ( adr1 len1 adr2 len2 -- digest$ )  use-md5 hash2  ;

: sha-256  ( adr len -- digest$ )   use-sha256 hash1  ;

: sha1  ( adr len -- digest$ )  use-sha1 hash1  ;

\ The following interface is for the benefit of ofw/wifi/hmacsha1.fth
d# 20 constant /sha1-digest
0 value sha1-digest
: sha1-init   use-sha1 hash-init  ;
: sha1-update hash-update  ;
: sha1-final hash-final drop to sha1-digest  ;

: ebg-set  ( n -- )  h# d4292c00 l@  or  h# d4292c00 l!  ;
: ebg-clr  ( n -- )  invert  h# d4292c00 l@  and  h# d4292c00 l!  ;

0 [if]
\ This is the procedure recommended by the datasheet, but it doesn't work
: init-entropy-digital  ( -- )
\   h# ffffffff ebg-clr   \ All off
   h# 00008000 ebg-set   \ Digital entropy mode
   h# 00000400 ebg-clr   \ RNG reset
   h# 00000200 ebg-set   \ Bias power up
   d# 400 us
   h# 00000100 ebg-set   \ Fast OSC enable
   h# 00000080 ebg-set   \ Slow OSC enable
   h# 02000000 ebg-set   \ Downsampling ratio
   h# 00110000 ebg-set   \ Slow OSC divider
   h# 00000400 ebg-set   \ RNG unreset
   h# 00000040 ebg-set   \ Post processor enable
   h# 00001000 ebg-set
;
[else]
\ This procedure works
: init-entropy  ( -- )  \ Using digital method
   h# 21117c0 h# d4292c00 l!
;
[then]

: random-short  ( -- w )
   begin  h# d4292c04 l@  dup 0>=  while  drop  repeat
   h# ffff and
;
: random-long  ( -- l )
   random-short random-short wljoin
;
alias random random-long

stand-init: Random number generator
   init-entropy
;

\ LICENSE_BEGIN
\ Copyright (c) 2010 FirmWorks
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
