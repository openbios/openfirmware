\ See license at end of file
purpose: Linux ext2fs file system superblock

decimal

512     constant ublock
2       constant super-block#
1024    constant /super-block
h# ef53 constant fs-magic

0 instance value super-block
0 instance value gds

\ XXX note: if the ext2fs is always LE, simplify this code.
defer short@  ( adr -- w )  ' be-w@ to short@
defer int@    ( adr -- l )  ' be-l@ to int@
defer short!  ( w adr -- )  ' be-w! to short!
defer int!    ( l adr -- )  ' be-l! to int!

\ superblock data
: +sbl  ( index -- value )  super-block  swap la+ int@  ;
: +sbw  ( index -- value )  super-block  swap wa+ short@  ;
: datablock0    ( -- n )   5 +sbl  ;
: logbsize	( -- n )   6 +sbl 1+  ;
: bsize		( -- n )   1024  6 +sbl lshift  ;	\ 1024
: /frag		( -- n )   1024  7 +sbl lshift  ;	\ 1024
: bpg		( -- n )   8 +sbl  ;			\ h#2000 blocks_per_group
: fpg		( -- n )   9 +sbl  ;			\ h#2000 frags_per_group
: ipg		( -- n )  10 +sbl  ;			\ h#790  inodes_per_group
: magic         ( -- n )  28 +sbw  ;
: revlevel	( -- n )  19 +sbl  ;
: /inode        ( -- n )  revlevel 1 =  if  44 +sbw  else  h# 80  then  ;
\ : bsize	( -- n )
\    /block if   1024  6 +sbl lshift to /block  then  /block
\ ;

: ceiling   ( nom div -- n )   /mod swap if  1+  then  ;

\ : total-inodes		( -- n )   0 +sbl  ;
: total-blocks		( -- n )   1 +sbl  ;
: total-free-blocks	( -- n )   3 +sbl  ;
\ : total-free-inodes	( -- n )   4 +sbl  ;
\ : total-free-blocks+!	( -- n )   3 +sbl  +  super-block  3 la+ int!  ;
\ : total-free-inodes+!	( -- n )   4 +sbl  +  super-block  4 la+ int!  ;
: total-free-blocks!	( -- n )   super-block  3 la+ int!  ;
: total-free-inodes!	( -- n )   super-block  4 la+ int!  ;
: #groups   ( -- n )   total-blocks bpg ceiling  ;

\ Don't write to a disk that uses extensions we don't understand
: unknown-extensions?   ( -- unsafe? )
   24 +sbl 4 and   if  ." ext3 journal needs recovery" cr  then 

   23 +sbl h# ffffffff invert and        \ Accept all compat extensions
   24 +sbl h# 00000002 invert and  or    \ Incompatible - accept FILETYPE
   25 +sbl h# 00000001 invert and  or    \ RO - accept SPARSE_SUPER
;

: do-alloc  ( adr len -- )  " dma-alloc" $call-parent  ;
: do-free   ( adr len -- )  " dma-free" $call-parent  ;

: init-io  ( -- )
   \ Used to set partition-offset but now unnecessary as parent handles it
;

: write-ublocks  ( adr len dev-block# -- error? )
   ublock um* " seek" $call-parent ?dup  if  exit  then		( adr len )
   tuck " write" $call-parent <>
;
: put-super-block  ( -- error? )
   super-block /super-block super-block# write-ublocks
;

: read-ublocks  ( adr len dev-block# -- error? )
   ublock um* " seek" $call-parent ?dup  if  exit  then		( adr len )
   tuck " read" $call-parent <>
;

: get-super-block  ( -- error? )
   super-block /super-block super-block# read-ublocks ?dup  if  exit  then

   ['] le-l@ to int@  ['] le-w@ to short@
   ['] le-l! to int!  ['] le-w! to short!
   magic fs-magic =  if  false exit  then

   ['] be-l@ to int@  ['] be-w@ to short@
   ['] be-l! to int!  ['] be-w! to short!
   magic fs-magic <>
;

: gds-fs-block#  ( -- fs-block# )
   bsize d# 1024 =  if  2  else  1  then	( logical block# )
;
: gds-block#  ( -- dev-block# )
   gds-fs-block#  bsize ublock / *		( dev-block# )
;
: /gds  ( -- size )  #groups h# 20 *  ublock round-up  ;
: group-desc  ( group# -- adr )  h# 20 *  gds +  ;
: gpimin    ( group -- block# )   group-desc  2 la+ int@  ;
: blkstofrags  ( #blocks -- #frags )  ;		\ XXX is this needed?


\ LICENSE_BEGIN
\ Copyright (c) 2006 FirmWorks
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
