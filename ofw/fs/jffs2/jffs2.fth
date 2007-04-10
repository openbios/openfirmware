\ See license at end of file
purpose: JFFS2 reader

d# 20,000 constant max-inodes

0 value debug-scan?  \ True to display progress reports

0 instance value block-buf    \ Start address of working buffer
0 instance value eb-end       \ End address of working buffer
\ 0 value cleanmark?

\ Magic numbers to identify JFFS2 nodes
h# 1985 constant jffs2-magic
h# e001 constant dirent-type
h# e002 constant inode-type
h# 2003 constant cleanmarker-type
h# 2004 constant padding-type
h# 2006 constant summary-type
h# e008 constant xattr-type
h# e009 constant xref-type

\ A 150 MB filesystem uses 1.1 MB of memory for inodes and 850K for dirents

0 ( instance ) value alloc-len  \ (Computed) size of inode and dirent buffers

0 ( instance ) value inodes         \ Buffer for in-memory inodes
0 ( instance ) value next-inode     \ Pointer into inode buffer

0 ( instance ) value dirents        \ Buffer for dirent nodes
0 ( instance ) value next-dirent    \ Pointer into dirent buffer

0 ( instance ) value minodes        \ Buffer for per-file inode list
0 ( instance ) value next-minode    \ Pointer into per-file inode list

0 instance value file-buf       \ Buffer for constructing file
0 instance value file-size      \ Actual size of file

0 ( instance ) value /empty-scan    \ When to give up looking for nodes

0 ( instance ) value /page          \ Efficient size for reading
0 ( instance ) value /eblock        \ Size of erasable unit
0 ( instance ) value pages/eblock   \ pages per erase block
0 ( instance ) value pages/chip     \ total number of pages

\ In-memory inode structure

\ Access a field within a JFFS2 FLASH data structure
: j@  ( adr offset -- value )  la+ l@  ;

\ Access fields within the memory data structure for volume inodes
\ Based on struct jffs2_sum_inode_flash, with "nodetype" replaced
\ by the eblock number.  This is not the complete inode data, just
\ the part that is in the summary node.  It is just enough information
\ to let us create the list of inodes associated with a given file.
\ Having created that list, we can get the full inodes from FLASH.
\ Storing it in this form saves space and time, because we only have
\ to read the full inodes for the few files that we actually access.

: meblock@   ( adr -- eblock# )  0 j@  ;
: minum@     ( adr -- inode# )   1 j@  ;
: mversion@  ( adr -- version )  2 j@  ;
: moffset@   ( adr -- offset )   3 j@  ;
4 /l* constant /mem-inode
\ : mtotlen@   ( adr -- offset )   4 j@  ;
\ 5 /l* constant /mem-inode

\ Fields within in-memory directory entry data structure.
\ Based on struct jffs2_sum_dirent_flash, with the
\ "nodetype" and "totlen" fields replaced by the eblock #.

: eblock@  ( adr -- eblock# )  0 j@  ;
: offset@  ( adr -- offset )   1 j@  ;
: pino@    ( adr -- parent )   2 j@  ;
: version@ ( adr -- version )  3 j@  ;
: dirino@  ( adr -- inode )    4 j@  ;
: ftype@   ( adr -- type )     d# 21 + c@  ;
: fname$   ( node-adr -- adr len )
   dup d# 22 +           ( node-adr name-adr )
   swap  d# 20 + c@      ( name-adr name-len )
;

\ Access fields in per-file raw inode structure - based on
\ struct jffs2_raw_inode
: riinode@    ( adr -- inode# )    3 j@  ;
: riversion@  ( adr -- version# )  4 j@  ;
: rimode@     ( adr -- mode )      5 j@  ;
\ 6 uid,gid
: riisize@    ( adr -- size )      7 j@  ;
\ 8 atime
: rimtime@    ( adr -- mtime )     8 j@  ;
\ 10 ctime
: rioffset@   ( adr -- offset )   d# 11 j@  ;  \ Beginning of node data in file
: ricsize@    ( adr -- csize )    d# 12 j@  ;  \ Length of compressed data in node
: ridsize@    ( adr -- dsize )    d# 13 j@  ;
: ricompr@    ( adr -- compr )    d# 14 la+ c@  ;
\ 14.1 usercompr, 14.2.w flags
: ridcrc@     ( adr -- adr' )     d# 15 j@  ;
: rincrc@     ( adr -- adr' )     d# 16 j@  ;
: >ridata     ( adr -- adr' )     d# 17 la+  ;

\ see forth/lib/crc32.fth and cpu/x86/crc32.fth
: crc  ( adr len -- crc )  0 crctab  2swap ($crc)  ;

: set-sizes   ( -- )
   -1 to file-size

   " block-size" $call-parent to /page

   " erase-size" ['] $call-parent    ( adr len xt )
   catch  if  2drop h# 20000  then   ( n )
   to /eblock

   /eblock /page / to pages/eblock

   " size" $call-parent   ( d )
   /page um/mod  to pages/chip  ( rem )
   drop
;

: dma-alloc  ( len -- adr )  " dma-alloc" $call-parent  ;
: dma-free   ( len -- adr )  " dma-free" $call-parent  ;

true value first-time?

: allocate-buffers  ( -- )
   /eblock  dma-alloc     to block-buf
   /page d# 1024 max  /eblock  min  to /empty-scan
   max-inodes /n*  dma-alloc  to minodes  \ Arbitrary limit on inodes per file

   first-time?  if
      jffs2-dirent-base to dirents
      jffs2-inode-base  to inodes
   then
\   /page d# 100 /  pages/chip *  to alloc-len
\   alloc-len dma-alloc  to inodes
\   alloc-len dma-alloc  to dirents
;

: release-buffers  ( -- )

\   inodes  alloc-len     dma-free
\   dirents alloc-len     dma-free

   minodes max-inodes /n*  dma-free

   block-buf /eblock     dma-free

   \ Don't free the CRC, in case somebody wants to reuse it.
   \ The memory savings is insignificant.
   \ crc32-free
;

: eblock>page  ( eblock# -- page# )  pages/eblock *  ;
: page>eblock  ( page# -- eblock# )  pages/eblock /  ;

-1 ( instance ) value have-eblock#  \ For avoiding redundant reads
: read-pages  ( page# #pages  -- error? )
   \ Partial reads invalidate the cache
   dup pages/eblock <>  if  -1 to have-eblock#  then  ( page# #pages )

   tuck  block-buf -rot  " read-blocks" $call-parent  ( #pages #read )
   <>
;
: read-eblock  ( eblock# -- )
   dup have-eblock#  <>  if   ( eblock# )
      to have-eblock#         ( )
      have-eblock# eblock>page  pages/eblock  read-pages
      abort" jffs2: bad read"
   else
      drop
   then                      ( )
;

0 ( instance ) value sumsize

: get-summary  ( page# -- true | adr false )
   \ Get the size of the summary node
   block-buf /page + -2 j@   ( page# sumstart )
  
   \ Convert to offset within erase block, in page#/byte form
   /eblock over - to sumsize   ( page# sumstart )
   /page /mod                  ( page# byte page )

   \ We won't need the byte offset for awhile
   swap -rot                   ( byte# page# page-offset# )

   \ Determine the number of pages to read (from the end of the erase block)
   pages/eblock over -         ( byte# page# page-offset# #tail-pages)

   \ Read them
   >r  +  r>  read-pages  if  drop true exit  then   ( byte# )

   \ Return the memory address of the summary
   block-buf +  false
;

\ Summary node:   0: magic|type 1: totlen 2: hdr_crc 3: #sum_entries
\ 4: clean_marker_flag  5: total_pad_node_size  6: sum_crc  7: node_crc

\ Validate the summary; it's all in memory now
\ The numeric field references are from struct jffs2_raw_summary
: bad-summary?  ( adr -- flag )
   dup 6 /l*  crc  ( adr crc )
   over 7 j@ <>  if  drop true exit  then  \ Exit if bad node CRC

   \ Omitting CRC check of just the node header, and the
   \ totlen check, as both are covered by the node CRC.

   dup  8 la+  sumsize -8 la+  crc        ( adr crc )
   over 6 j@ <>  if  drop true exit  then  \ Exit if bad summary data CRC
   drop false
;

\ Tools for copying into memory
: c+!  ( adr c -- adr' )  over c! ca1+  ;
: l+!  ( adr l -- adr' )  over l! la1+  ;

0 instance value the-page#
0 instance value the-eblock#

\ Copy summary inode from FLASH to memory
\ Summary inode:  w.nodetype l.inode l.version l.offset l.totlen
: scan-sum-inode  ( adr -- len )
   wa1+   \ Skip the nodetype so we can use j@
   next-inode              ( adr iadr )
   the-eblock#       l+!   ( adr iadr' )  \ eblock@
   2dup   3 /l*  move      ( adr iadr )
   3 la+ to next-inode     ( adr )
   drop d# 18
;

\ Copy summary dirent from FLASH to memory
\ Summary dirent:  w.nodetype l.totlen l.offset l.pino l.version
\ l.ino c.nsize c.type name
: scan-sum-dirent  ( adr -- len )
   the-eblock#  next-dirent  l!       ( adr )

   6 +                                ( offset-adr )
   next-dirent la1+                   ( offset-adr dst-adr )
   over  d# 16 + c@  d# 18 +          ( src dst len )
   dup >r                             ( src dst len r: len )
   move                               ( )

   r@ la1+  next-dirent +  to next-dirent  ( offset-adr )

   \ 6 is the length of the fields that were skipped, not copied
   r> 6 +                             ( len )
;

[ifdef] notdef
: find-nonblank  ( len adr -- len removed-len )
   over  0  ?do   ( len adr )
      dup c@ h# ff <>  if  drop i unloop exit  then
      1+
   loop
   drop dup
;
[then]

: scan-sumnode  ( len adr -- len removed-len )
   dup w@ case     ( len adr case: type )
      inode-type  of  scan-sum-inode   endof
      dirent-type of  scan-sum-dirent  endof
      xattr-type  of  drop  d# 18   ." XA" cr   endof
      xref-type   of  drop  6       ." R" cr   endof
      h# ffff     of  drop  dup  ( find-nonblank  )  endof  \ Keep scanning to end
      ." Unrecognized summary node type " dup .x cr  abort
   endcase
;

: scan-summary  ( adr -- )
   sumsize 8 -   8 /l*               ( adr len #remove )  \ Skip summary header node
   begin  /string  dup 1 > while     ( adr len )
      over scan-sumnode              ( adr len #remove )
   repeat                            ( adr len )
   2drop
;
: no-summary?  ( page# -- flag )
\ drop true

\ dup h# 47100 = if debug-me then
   dup pages/eblock + 1-  1  read-pages  if       ( page# )
      drop true exit
   then                                           ( page# )

   \ Check magic number
   block-buf /page + -1 j@                        ( page# magic )
   h# 02851885  <>  if   drop true exit  then     ( page# )

   get-summary   if  true exit  then              ( adr )
   dup bad-summary?  if  drop true exit then      ( adr )
   scan-summary  false
;

: possible-nodes?  ( page# -- flag )
   \ We could scan as we go and bail out early - but if we did, it wouldn't
   \ help, because when we find a dirty page, we have to scan the
   \ entire erase block anyway.

   /empty-scan /page round-up  /page /  read-pages   ( error? )
   if  false exit  then                              ( )

   block-buf  /empty-scan  bounds  ?do
      i l@ h# ffff.ffff <>  if  true unloop exit  then
   /l +loop
   false
;

: header-crc?  ( node-adr -- okay? )
   dup 8 crc  ( node-adr crc )
   swap 2 j@  =
;

: +raw-node  ( adr -- adr' )  dup  1 j@  +  /l round-up  ;

\ This assumes that the entire erase block is in memory
: another-node?  ( adr -- false | adr' true )
   eb-end  swap  ?do
      i w@ jffs2-magic =  if
         i header-crc?  if
            i +raw-node  eb-end  u<=  if
               i true unloop  exit
            then
         then
      then
   loop
   false
;

: rdpino@     ( adr -- parent )   3 j@  ;
: rdversion@  ( adr -- version )  4 j@  ;
: rdinode@    ( adr -- inode )    5 j@  ;
: rdnsize@    ( adr -- nsize )    7 la+ c@  ;
: rdtype@     ( adr -- type )     7 la+ 1+ c@  ;
: >rdname     ( adr -- adr' )     d# 10 la+  ;

: scan-raw-dirent  ( adr -- adr )
\ XXX        dup 1 j@  4 round-up           ( adr len )
\ XXX        2dup next-dirent swap move     ( adr len )
   \ 
   next-dirent
   the-eblock#        l+!
   over block-buf -   l+!
   over rdpino@       l+!
   over rdversion@    l+!
   over rdinode@      l+!   ( adr iadr' )
   over rdnsize@      c+!   ( adr iadr' )
   over rdtype@       c+!   ( adr iadr' )
   over >rdname swap        ( adr str-adr iadr )
   2 pick rdnsize@  move    ( adr )
   dup rdnsize@  d# 22 +    ( adr dirent-len )

   next-dirent +  to next-dirent  ( adr )
;

\ Copy the raw inode information to memory in summary inode form
\ We do this to save space, because we will only need the full
\ information for those few inodes that correspond to the files
\ we actually access.
: scan-raw-inode  ( adr -- adr )
   next-inode    ( adr iadr )
   the-eblock#       l+!   ( adr dadr' )  \ eblock
   over  riinode@    l+!   ( adr dadr' )  \ ino
   over  riversion@  l+!   ( adr dadr' )  \ version
   over block-buf -  l+!   ( adr dadr' )  \ offset
\   over  riisize@    l+!   ( adr dadr' )  \ node length
   to next-inode
\ false to cleanmark?
;
: scan-node  ( adr -- adr' )
   dup wa1+ w@  case   ( adr nodetype )
      dirent-type  of  ( adr )
         dup rdinode@  if  ( adr )  \ Ignore deleted entries
            debug-scan?  if  ." d"  then
            scan-raw-dirent             ( adr )
         else
            debug-scan?  if  ." D"  then
         then                              ( adr )
\          false to cleanmark?             ( adr )
      endof                 ( adr nodetype )

      inode-type  of        ( adr )
         debug-scan?  if  ." i"  then
         scan-raw-inode     ( adr )
      endof                 ( adr nodetype )

      padding-type  of  ( adr )
         \ We just skip padding nodes; they contain no information
      endof             ( adr nodetype )

[ifdef] cleanmark?
      cleanmarker-type  of  ( adr )
         \ Verify that it is at the start of the buffer
         the-eblock# eblock>page  the-page#  =
         to cleanmark?
         \ We could also check that the size is correct
      endof
[then]

      ( adr nodetype )
      cr ." Unsupported nodetype " dup . cr

   endcase             ( adr )
   +raw-node           ( adr' )
;

: scan-raw-nodes  ( page# -- )
   to the-page#
   debug-scan?  if  the-page# .  then

   the-page# page>eblock  read-eblock
   block-buf /eblock + to eb-end

   block-buf  begin  another-node?  while  scan-node  repeat
;

: scan-occupied  ( -- )
   first-time?  0=  if  exit  then
   dirents to next-dirent
   inodes  to next-inode
   pages/chip  0  do
      i page>eblock  to the-eblock#
      i no-summary?  if
         i possible-nodes?  if  i scan-raw-nodes  then
      then
   pages/eblock +loop
;

: place-node  ( node where -- )
   !
   next-minode  na1+  to next-minode  ( )
;

: get-inode  ( mem-inode -- adr )
   dup meblock@  read-eblock
   moffset@  block-buf +               ( inode-adr )
;

: inode-good?  ( inode -- flag )
   dup  d# 15 /l*  crc          ( riadr node-crc )
   over rincrc@ <>   if         ( riadr )
      drop false exit           ( -- false )
   then                         ( riadr )
   dup >ridata over ricsize@    ( riadr data-adr data-len )
   crc  swap ridcrc@ =
;
: minode-good?  ( minode -- flag )  get-inode inode-good?  ;

\ This is a brute-force, no tricks, insertion sort.
\ Insertion sort is bad for large numbers of elements, but in this
\ application, the number of elements is not all that large.  The time
\ is dominated by the need to scan all the nodes.  collect-nodes takes
\ about 160 ms for a tiny file (4 nodes), about 200 ms for a very large
\ one (573 nodes).
: insert-sort  ( node -- )
   dup mversion@                   ( node version )
   next-minode  minodes  ?do       ( node version )
      dup  i @ mversion@  =  if    ( node version )
         \ If we have a collision, we check the CRC of the new node,
         \ and if it is valid, replace the existing one.  We will
         \ end up with only the last good one in the slot.
         drop                      ( node )
         dup minode-good?  if      ( node )
            i !                    ( )
         else                      ( node )
            drop                   ( )
         then                      ( )
         unloop exit
      then
                                   ( node version )
      dup  i @ mversion@  <  if    ( node version )
         \ Slide everything above up to open a slot
         i  i na1+  next-minode i -  move  ( node version )
         drop i place-node         ( node version )
         unloop exit
      then                         ( node version )
   /n +loop                        ( node version )
   drop  next-minode  place-node   ( )
;

\ This is used for symlinks and directory inodes where there
\ can only be one of them.
-1 value max-version  \ Local variable for find-node and $find-name
-1 value the-inode    \ Local variable for find-node
: latest-node  ( inum -- true | minode false )
   -1 to max-version
   \ Quick hack to shorten the inner loop - start at the minum field
   \ Reduces the time for a typical run from 260 ms down to 160 ms
   next-inode  inodes  la1+   ?do                ( inum )
      dup  i @ =  if                             ( inum )
         i /l -  minode-good?   if               ( inum )
            i /l -  mversion@                    ( inum version )
            dup max-version >  if                ( inum version )
               to max-version                    ( inum )
               i /l - to the-inode               ( inum )
            else                                 ( inum version )
               drop                              ( inum )
            then                                 ( inum )
         then                                    ( inum )
      then                                       ( inum )
   /mem-inode +loop                              ( inum )
   drop
   max-version -1 =  if  true exit  then
   the-inode false
;

\ This could be optimized out the wazoo, but in this application,
\ it just doesn't matter.  We only need to load one or two files.
: collect-nodes  ( inum -- any? )
   minodes to next-minode   \ Empty the list

   \ Quick hack to shorten the inner loop - start at the minum field
   \ Reduces the time for a typical run from 260 ms down to 160 ms
   next-inode  inodes  la1+   ?do                ( inum )
      dup  i @ =  if  i /l -  insert-sort  then  ( inum )
   /mem-inode +loop                              ( inum )
   drop
   next-minode minodes <>
;

0 [if]
\ Excessive optimization - this knocks another 70 msecs off the time
\ The next step would be to have a word that scans to find the next one.
code dupi@=  ( n -- n flag )
   0 [sp] cx mov    \ N in ax
   0 [bp] bx mov   
   4 [bp] bx add    \ i in bx
   0 [bx] bx mov    \ i @ in bx
   ax ax xor
   bx cx cmp        \ flag
   0=  if  ax dec  then
   ax push
c;
[then]

: set-length  ( final-size write-extent -- )
   2dup >  if    \ The final size extends past this segment

      \ We may have to fill a hole
      dup file-size umax     ( final write hiwater )

      \ Hiwater is the amount that has already been written or will
      \ have been written when we finish with the data in this node
      \ If the current value of file-size is the same as final,
      \ "extra" will be 0, and erase won't do anything.
      2 pick                 ( final write hiwater final )
      over -                 ( final write hiwater extra )
      swap file-buf +  swap  ( final write buf-adr extra )
      erase                  ( final write )
   then                      ( final write )
   drop to file-size   \ Set overall length
;

: ?outlen  ( expected actual -- )  <> abort" Wrong uncompressed length"  ;
: zlib-inflate  ( src dst clen dlen -- )
   nip  -rot        ( dlen src dst )
   swap 2+ swap     ( dlen src dst )     \ Skip 2-byte header
   true (inflate)   ( dlen actual-dlen )
   ?outlen
;

d# 256 /w* constant /positions
/positions instance buffer: positions

instance variable outpos
0 instance value dst

: rtime-decompress  ( src dst srclen dstlen -- )
   >r                            ( src dst srclen r: dstlen )
   swap to dst  outpos off       ( src srclen     r: dstlen )

   positions /positions  erase   ( src srclen )

   bounds  ?do                   ( )
      i 1+ c@                    ( repeat )
      i c@                       ( repeat value )
      dup outpos @ dst +  c!     ( repeat value )  \ Verbatim copied byte
      1 outpos +!                ( repeat value )
      positions swap wa+ dup w@  ( repeat 'positions backoffs )
      outpos @  rot w!           ( repeat backoffs )
      swap                       ( backoffs repeat ) 
      dup  if                    ( backoffs repeat ) 
         swap  dst +             ( repeat src )
         outpos @ dst +          ( repeat src dst )
         \ We must use cmove instead of move, because we need the
         \ repetition-when-overlapping semantics.
         2 pick cmove            ( repeat )
         outpos +!               ( )
      else                       ( backoffs repeat ) 
         2drop                   ( )
      then                       ( )
   2 +loop                       ( )
   r>  outpos @  ?outlen         ( )
;

: .inode  ( inode - )
   ." tot "    dup riisize@ 8 u.r space
   ." len "    dup ridsize@ 8 u.r space
   ." extent " dup rioffset@ over ridsize@ +  8 u.r space
   ." comp "       ricompr@ 3 u.r 
   cr
;
: play-inode  ( mem-inode -- )
   debug-scan?  if
      dup meblock@ 4 u.r  dup moffset@ 6 u.r space
   then
   get-inode                     ( inode )
   dup inode-good?  0=  if       ( inode )
      debug-scan?  if  ." Skipping bad inode."  cr  then
      drop exit
   then

   debug-scan?  if  dup .inode cr  then
   >r
   r@ riisize@  r@ rioffset@  r@ ridsize@ +  set-length

   r@ >ridata  file-buf r@ rioffset@ +  ( src dst )
   r@ ricompr@  case                    ( src dst )
      0 of   r@ ridsize@  move                           endof  ( )
      2 of   r@ ricsize@  r@ ridsize@  rtime-decompress  endof  ( )
      6 of   r@ ricsize@  r@ ridsize@  zlib-inflate      endof  ( )
      ( default )  ." Unsupported compression type " .  cr abort
   endcase
   r> drop
;

: play-log  ( -- )
   get-inflater

   -1 to the-eblock#
   -1 to have-eblock#
   0 to file-size
   next-minode  minodes  ?do   i @ play-inode  /n +loop

   release-inflater
;
: ?play-log  ( -- )  file-size -1 =  if  play-log  then  ;

: .ftype  ( adr -- )
   ftype@ 2/ 0 max  "   /  @="  rot min +  c@  emit
;

: .fname  ( dirent -- )
   dup fname$   space space type  space .ftype
;

: +dirent  ( adr -- adr' )     5 la+ dup c@ +  2+  ;

: #dirents  ( -- n )
   0
   next-dirent dirents   ( n endadr adr )
   begin  2dup >  while   +dirent  rot 1+ -rot  repeat  ( n endadr adr )
   2drop
;

char \ instance value delimiter

create root-dirent
   0 ,  \ block#
   0 ,  \ offset
   0 ,  \ pino
   0 ,  \ version
   1 ,  \ ino
   0 c, \ nsize
   4 c, \ type

-1 instance value pwd
: set-root  ( -- dirent )  root-dirent dup to pwd  ;

: strip\  ( name$ dirent -- name$' dirent' )
   -rot
   dup  0<>  if                      ( dirent name$ )
      over c@  delimiter  =  if      ( dirent name$ )
         1 /string                   ( dirent name$ )
         rot drop  set-root -rot     ( dirent name$ )
      then                           ( dirent name$ )
   then                              ( dirent name$ )
   rot
;

: dir-match?  ( name$ par adr -- flag )
   tuck pino@ <>  if  ( name$ adr )
      3drop false     ( false )
   else               ( name$ adr )
      fname$ $=       ( flag )
   then
;

-1 ( instance ) value the-dirent   \ Local variable for $find-name
: $find-name  ( name$ dirent -- true | dirent false )
   -1 to max-version
   dirino@        ( name$ parent-inode )
   dirents        ( name$ parent-inode adr )
   begin  dup next-dirent u<   while    ( $ par adr )

      \ Look for a directory type dirent with the right name and parent
      2over 2over  dir-match?  if       ( $ par adr )

         \ If this is the latest version, record its inode
         dup version@  max-version >  if
            dup version@ to max-version
            dup to the-dirent
         then
      then
      +dirent
   repeat  ( name$ parent adr )
   4drop
   max-version 0<  if  true exit  then
   the-dirent false
;

defer $resolve-path
d# 1024 constant /symlink   \ Max length of a symbolic link

\ The input dirent is for a symlink.  Resolve it to a new dirent
: minode>rinode  ( minode -- rinode )
   dup meblock@ read-eblock     ( minode )
   moffset@ block-buf +         ( rinode )
;
: dir-link  ( dirent -- true | dirent' false )
   delimiter >r  [char] / to delimiter
   /symlink alloc-mem >r

   dirino@ latest-node  if      ( )
      true
   else                            ( minode )
      minode>rinode                ( rinode )
      dup >ridata  swap ridsize@   ( adr len )
      tuck  r@ swap  move          ( len )
      r@ swap  pwd  $resolve-path  ( true | dirent false )
   then   

   r> /symlink free-mem
   r> to delimiter
;

: $find-path  ( path$ dirent -- true | dirent' false )
   begin  strip\  over  while           ( path$  dirent' )
      dup ftype@  case                  ( path$  dirent  c: type )

         4  of   \ Directory            ( path$  dirent  )
            dup  to pwd                 ( path$  dirent  )
            >r  delimiter left-parse-string  r>  ( rem$' head$ dirent )
            $find-name  if              ( rem$' )
               2drop true exit
            then                        ( rem$ dirent )
         endof                          ( rem$ dirent )

         d# 10  of                      ( rem$ dirent )
            dir-link  if                ( rem$ )
               2drop true exit
            then                        ( rem$ dirent )
         endof                          ( rem$ dirent )  \ symlink
         ( default )                    ( rem$ dirent  c: type )

         \ The parent is an ordinary file or something else that
         \ can't be treated as a directory
         4drop true exit
      endcase                           ( rem$ dirent )
   repeat                               ( rem$ dirent )
   nip nip false                        ( dirent )
;
' $find-path to $resolve-path

\ Leaves pwd set to the containing directory
: $chdir  ( path$ -- error? )
   $find-path  if  true exit  then  ( inode )
   ftype@ 4 <>     \ Return false (no error) if it's a directory
;

: do-file  ( inode -- okay? )
   collect-nodes
;

: advance-dirent  ( dirent -- false | dirent' true )
   pwd dirino@    swap   ( parent-inode dirent )
   begin  dup next-dirent u<  while   ( par dirent )
      2dup pino@ =  if                ( par dirent )
         nip true exit
      then                            ( par dirent )
      +dirent                         ( par dirent' )
   repeat                             ( par dirent' )
   2drop false
;

: insert-dirent  ( dirent -- )
   minodes  begin  dup next-minode u<  while    ( dirent listadr )
      over fname$  2 pick @ fname$  $=  if      ( dirent listadr )
         over version@  over @ version@  >  if  ( dirent listadr )
            !                                   ( )
         else                                   ( dirent listadr )
            2drop                               ( )
         then                                   ( )
         exit
      then                                      ( dirent listadr )
      na1+                                      ( dirent listadr' )
   repeat                                       ( dirent listadr )
   place-node                                   ( )
;

\ Having collected the list of directory entries for the current
\ target directory, we must prune the list to remove unlinked ones.
: remove-unlinks  ( -- )
   minodes  begin  dup next-minode <  while  ( minode )
      dup @ dirino@  if                      ( minode )
         na1+                                ( minode' )
      else                                   ( minode )
         \ Deleted, remove from list
         next-minode -1 na+ to next-minode   ( minode )
         dup na1+  over                      ( minode src dst )
         next-minode over -  move            ( minode )
      then                                   ( minode' )
   repeat                                    ( minode' )
   drop                                      ( )
;
: prep-dirents  ( -- )
   minodes to next-minode   \ Empty the list
   dirents
   begin  advance-dirent  while
      dup insert-dirent
      +dirent
   repeat
   remove-unlinks
;

decimal

headerless
0 value open-count
0 instance value seek-ptr

: clip-size  ( adr len -- len' adr len' )
   seek-ptr +   file-size min  seek-ptr -     ( adr len' )
   tuck
;
: update-ptr  ( len' -- len' )  dup seek-ptr +  to seek-ptr  ;
: 'base-adr  ( -- adr )  seek-ptr  file-buf +  ;

headers
external
: seek  ( d.offset -- status )
   0<>  over file-size u>  or  if  drop true  exit  then \ Seek offset too big
   to seek-ptr
   false
;

: ?release  ( flag -- flag )  dup 0=  if  release-buffers  then  ;

: open  ( -- flag )
   \ This lets us open the node during compilation
   standalone?  0=  if  true exit  then

   0 to seek-ptr                                ( )

   set-sizes  allocate-buffers  scan-occupied   ( )

   \ This is the value we will use for file-buf if we use read and seek
   next-inode to file-buf

   false to first-time?

   my-args " <NoFile>"  $=  if  true exit  then

   my-args set-root  $resolve-path  if  false ?release exit  then  ( dirent )

   begin
      \ We now have the dirent for the file at the end of the string
      dup ftype@  case                                   ( dirent )
         4      of  to pwd  true exit  endof               \ Directory
         8      of  dirino@ do-file  ?release exit  endof  \ Regular file
         d# 10  of                                         \ Link
            dir-link  if  false ?release exit  then  ( dirent )
         endof
         ( default )   \ Anything else (special file) is error
            2drop false ?release exit
      endcase                                       ( dirent )
   again
;
: close  ( -- )  release-buffers  ;

: size  ( -- d.size )  ?play-log file-size 0  ;
: read  ( adr len -- actual )
   ?play-log                            ( adr len )
   clip-size tuck			( len' len' adr len' )
   begin
      file-size  seek-ptr -  min	( len' len' adr len'' )
      2dup 'base-adr -rot move		( len' len' adr len'' )
      update-ptr			( len' len' adr len'' )
      rot over - -rot + over		( len' len'-len'' adr+len'' len'-len'' )
   ?dup 0=  until			( len' len'-len'' adr+len'' len'-len'' )
   2drop
;
: load  ( adr -- len )
   \ For load, we just compute the file directly into the buffer
   to file-buf
   play-log
   file-size
;

\ This code is copied from ext2fs and could be shared
decimal
\ date&time is number of seconds since 1970
create days/month
\ Jan   Feb   Mar   Apr   May   Jun   Jul   Aug   Sep   Oct   Nov   Dec
  31 c, 28 c, 31 c, 30 c, 31 c, 30 c, 31 c, 31 c, 30 c, 31 c, 30 c, 31 c,

: >d/m  ( day-in-year -- day month )
   12 0  do
      days/month i ca+ c@  2dup <  if
         drop 1+  i 1+  leave
      then
      -
   loop
;
: sec>time&date  ( seconds -- s m h d m y )
   60 u/mod  60 u/mod  24 u/mod		( s m h days )
   [ 365 4 * 1+ ] literal /mod >r	( s m h day-in-cycle )  ( r: cycles )
   dup [ 365 365 + 31 + 29 + ] literal
   2dup =  if		\ exactly leap year Feb 29
      3drop 2 29 2			( s m h year-in-cycle d m )
   else
      >  if  1-  then	\ after leap year
      365 u/mod				( s m h day-in-year year-in-cycle )
      swap >d/m				( s m h year-in-cycle d m )
   then
   rot r> 4 * + 1970 +			( s m h d m y )
;
hex
\ End of common code

: next-file-info  ( id -- false | id' s m h d m y len attributes name$ true )
   dup 0=  if  drop prep-dirents  minodes  then   ( minode )
   dup next-minode =  if  drop false exit  then   ( minode )
   dup @ >r na1+                           ( id' r: dirent )
   r@ dirino@ latest-node if               ( id' r: dirent )
      0 0 0  0 0 0           ( id' s m h  d m y  r: dirent )
      0                                ( ... len r: dirent )
      0                         ( ... attributes r: dirent )
   else                           ( id' minode r: dirent )
      minode>rinode  >r           ( id'  r: dirent rinode )
      r@ rimtime@  sec>time&date  ( id' s m h  d m y  r: dirent rinode )
      r@ riisize@                 ( id' s m h  d m y  len r: dirent rinode )
      r> rimode@                  ( id' s m h  d m y  len  mode  r: dirent )
   then
   r> fname$ true
;

: free-bytes  ( -- d.#bytes )  0 0  ;


\ create debug-jffs
[ifdef] debug-jffs
\needs mcr  : mcr cr  exit?  if  abort  then  ;

\ Tools for dumping the dirent table, for debugging
: .ldirent-hdr  ( -- )
   ."    Inode Version Eblock  Offs Parent  Name" cr
;
: .ldirent  ( adr -- adr' )
   dup dirino@   8 u.r  \ Inode
   dup version@  8 u.r  \ Version
   dup eblock@   7 u.r  \ Eblock#
   dup offset@   6 u.r  \ Offset on eblock
   dup pino@     7 u.r  \ Parent Inode
   dup .fname  mcr
   +dirent
;

: .dirents  ( -- )
   .ldirent-hdr
   next-dirent dirents   ( endadr adr )
   begin  2dup >  while   .ldirent  repeat  ( endadr adr )
   2drop
;


: .inode-hdr  ( -- )  ."    Inode Version Eblock  Offs" cr  ;
: .inode  ( adr )
   dup minum@    8 u.r  \ Inode
   dup mversion@ 8 u.r  \ Version
   dup meblock@  7 u.r  \ Eblock#
   dup moffset@  6 u.r  \ Offset on eblock
\   dup mtotlen@  8 u.r  \ Total length
   mcr
   /mem-inode +
;

: .inodes  ( -- )
   .inode-hdr
   next-inode inodes   ( endadr adr )
   begin  2dup >  while   .inode  repeat  ( endadr adr )
   2drop
;

: .dirent  ( adr parent -- adr' )
   over pino@  =  if   ( adr )    \ Check Parent Inode
\      dup version@  8 u.r  \ Version
      dup dirino@   8 u.r  \ Inode
      dup .fname mcr
   then                ( adr )
   +dirent             ( adr' )
;

: .dir  ( parent-inode -- )
   >r
   next-dirent dirents   ( endadr adr )
   begin  2dup >  while   r@  .dirent  repeat  ( endadr adr )
   2drop
   r> drop
;

: $fdir  ( path$ -- )
   $resolve-path abort" Not found"  ( dirent )
   dup ftype@ 4 =  if
      dirino@ .dir
   else
      dup dirino@ .   .fname  cr
   then
;

: dir  parse-word   set-root  $fdir  ;

: expand-file  ( inum -- )
   collect-nodes 0= abort" none"
   play-log
;
[then]



0 [if]
// Values of type field (byte at offset h# 1d) in directory entry
#define DT_UNKNOWN	0
#define DT_FIFO		1
#define DT_CHR		2
#define DT_DIR		4
#define DT_BLK		6
#define DT_REG		8
#define DT_LNK		10
#define DT_SOCK		12
#define DT_WHT		14
[then]

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
