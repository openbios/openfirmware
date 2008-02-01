\ See license at end of file
purpose: JFFS2 reader

d# 20,000 constant max-inodes

defer scan-callout  ' noop to scan-callout

0 value debug-scan?  \ True to display progress reports

0 instance value block-buf    \ Start address of working buffer
0 instance value eb-end       \ End address of working buffer
0 value cleanmark?

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
variable 'next-inode     \ Pointer into inode buffer
: next-inode  ( -- val )  'next-inode @  ;

0 ( instance ) value dirents        \ Buffer for dirent nodes
variable 'next-dirent    \ Pointer into dirent buffer
: next-dirent  ( -- val )  'next-dirent @  ;

\ minodes is an area that is used for constructing dynamic lists
\ that don't persist between opens

variable 'next-minode    \ Pointer into per-file inode list
: next-minode  ( -- adr ) 'next-minode @  ;
: minodes ( -- adr )  next-inode  ;  \ Start the inode pointer list after the inodes

0 instance value file-buf       \ Buffer for constructing file
0 instance value file-size      \ Actual size of file

0 ( instance ) value /empty-scan    \ When to give up looking for nodes

0 ( instance ) value /page          \ Efficient size for reading
0 ( instance ) value /eblock        \ Size of erasable unit
0 ( instance ) value pages/eblock   \ pages per erase block
0 ( instance ) value pages/chip     \ total number of pages

0 instance value the-page#
0 instance value the-eblock#

\ Access a field within a JFFS2 FLASH data structure
: j@  ( adr offset -- value )  la+ l@  ;
: j!  ( adr offset -- value )  la+ l!  ;

: pack-offset  ( offset -- n )  the-eblock#  /eblock *  +  ;

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

: dma-alloc  ( len -- adr )  " dma-alloc" $call-parent  ;
: dma-free   ( len -- adr )  " dma-free" $call-parent  ;

true value first-time?
-1 value partition#
-1 value #writes

\ This is a run-time cache of the parent inums for the directory inums we
\ have seen, used for resolving "..".
d# 256 2* /n* constant /parent-buf
/parent-buf buffer: parents
0 value next-parent

: allocate-buffers  ( -- )
   /eblock  dma-alloc     to block-buf
   /page d# 1024 max  /eblock  min  to /empty-scan
\   max-inodes /n*  dma-alloc  to minodes  \ Arbitrary limit on inodes per file

   first-time?  if
      jffs2-dirent-base to dirents
      jffs2-inode-base  to inodes
   then
\   /page d# 100 /  pages/chip *  to alloc-len
\   alloc-len dma-alloc  to inodes
\   alloc-len dma-alloc  to dirents
   parents to next-parent
;

: release-buffers  ( -- )

\   inodes  alloc-len     dma-free
\   dirents alloc-len     dma-free

\   minodes max-inodes /n*  dma-free

   block-buf /eblock     dma-free

   \ Don't free the CRC, in case somebody wants to reuse it.
   \ The memory savings is insignificant.
   \ crc32-free
;

: eblock>page  ( eblock# -- page# )  pages/eblock *  ;
: page>eblock  ( page# -- eblock# )  pages/eblock /  ;

-1 instance value have-eblock#  \ For avoiding redundant reads
: (read-pages)  ( page# #pages  -- #read )
   \ Partial reads invalidate the cache
   dup pages/eblock <>  if  -1 to have-eblock#  then  ( page# #pages )

   block-buf -rot  " read-blocks" $call-parent        ( #read )
;
: read-pages  ( page# #pages  -- error? )  tuck (read-pages) <>  ;
: read-eblock  ( eblock# -- )
   dup have-eblock#  <>  if      ( eblock# )
      to have-eblock#            ( )
      have-eblock# eblock>page  pages/eblock  (read-pages)  ( npages )
      dup pages/eblock <>  if    ( npages )
         ." JFFS2: bad read - eblock# " have-eblock# .x  ." page " dup .x cr
         /page *                 ( block-offset )
         dup block-buf +         ( block-offset adr )
         /eblock rot -           ( adr erase-length )
         h# ff fill              ( )
      else                       ( npages )
         drop                    ( )
      then                       ( )
   else                          ( eblock# )
      drop                       ( )
   then                          ( )
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

3 /n* instance buffer: curinum  \ cur-inum, cur-vers, cur-offset
: curvers  curinum na1+   ;
: curoffs  curinum 2 na+  ;

\ 0 instance variable cur-inum
\ 0 instance variable cur-vers
\ 0 instance variable cur-offset

instance variable dirent-offset
instance variable cur-pino

: init-curvars  ( -- )
   h# -100000 dup dirent-offset !  curoffs !
   0 curinum !
   0 curvers !
;

1 [if]
code aencode-inode  ( version inum offset 'curinum 'next-inode -- )
   dx pop   \ dx: 'next-inode
   cx pop   \ cx: 'curinum
   bx pop   \ bx: offset
            \ 0 [sp]: inum     4 [sp]: version  
            \ 0 [cx]: curinum  4 [cx]: curvers  8 [cx]: curoffs
   8 [cx]  ax  mov  \ ax: Old curoffs
   bx  8 [cx]  mov  \ Update curoffs
   ax      bx  sub  \ Delta

   h# 200 #  bx  cmp  <  if
      \ All 1-byte forms require offset < 200

      4 [sp] ax mov   ax dec  4 [cx] ax cmp  =  if    \ version == curvers+1 ?
         0 [sp] ax mov  0 [cx] ax  cmp  =  if         \ inum == curinum ?
            1 # bx shr                                \ Shift delta to remove low 0 bit
            0 [dx] ax mov  bl 0 [ax] mov  0 [dx] inc  \ Store encoded byte at next-inode++
            4 [cx] inc                                \ Update curvers
            ax pop  ax pop                            \ Remove inum and version from stack
            next
         then
      then

      1 #  4 [sp]  cmp  =  if                         \ version == 1 ?
         0 [sp] ax mov  ax dec  0 [cx] ax  cmp  =  if \ inum == curinum+1 ?
            1 # bx shr  bx inc                        \ Shift delta and add in the next-inum bit
            0 [dx] ax mov  bl 0 [ax] mov  0 [dx] inc  \ Store encoded byte at next-inode++
            0 [cx] inc    1 # 4 [cx] mov              \ Update inum and set curvers to p
            ax pop  ax pop                            \ Remove inum and version from stack
            next
         then
      then
   then

   2 # bx shr                     \ Throw away unused 0 bits in delta
   h# 10000 # ax mov
   ax bx cmp  <  if               \ delta fits in 16 bits?
      0 [sp]  ax  cmp  >  if      \ inum fits in 16 bits?
         4 [sp]  ax  cmp  >  if   \ version fits in 16 bits?
            0 [dx] di xchg        \ Get pointer in di
            al inc         al stosb                \ encode a 1 byte to indicate the long form
            ax pop     op: ax stos  ax 0 [cx] mov  \ Encode the inum    as 16 bits
            ax pop     op: ax stos  ax 4 [cx] mov  \ Encode the version as 16 bits
            bx ax mov  op: ax stos                 \ Encode the version as 16 bits               
            0 [dx] di xchg        \ Update next-inode pointer in di
            next
         then
      then
   then

   0 [dx] di xchg  \ Get pointer in di
   ax ax xor
   al stosb        \ encode a 0 byte to indicate the long form
   
   ax pop          \ inum
   ax stos         \ encode it
   ax 0 [cx] mov   \ Update curinum

   ax pop          \ version
   ax stos         \ encode it
   ax 4 [cx] mov   \ Update curvers

   8 [cx] ax mov   \ offset (from already-updated curoffs)
   ax stos         \ encode it

   0 [dx] di xchg  \ Update next-inode
c;

code amatch-inode  ( inum adr endadr 'curinum -- inum false | inum adr' offset version true )
   dx pop  cx pop  ax pop  0 [sp] bx mov  \ dx: 'curinum  cx: endadr  ax: adr  bx: inum
   si push
   ax si mov     \ si: adr

   begin  cx si cmp   u<  while
      ax ax xor
      al lodsb   \ ax: byte
      h# 20 #  al  cmp  u<  if
         al al or  0=  if
            \ Long form: 0, inum.32, version.32, offset.32
            ax lods  ax 0 [dx]  mov
            ax lods  ax 4 [dx]  mov
            ax lods  ax 8 [dx]  mov
         else
            \ Short form: 0, inum.16, version.16, delta_offset.16
            op: ax lods  ax 0 [dx]  mov
            op: ax lods  ax 4 [dx]  mov
            op: ax lods  2 # ax shl  ax 8 [dx]  add
         then
      else
         1 #  al  test  0<>  if
            0 [dx]  inc
            1 #  4 [dx]  mov
            h# fe #  al  and
         else
            4 [dx]  inc
         then
         ax ax add
         ax  8 [dx]  add
      then
      bx  0 [dx]  cmp  =  if
         si ax mov  si pop   ax push  8 [dx] push  4 [dx] push  -1 # push  next
      then
   repeat
   si pop  0 # push
c;

[else]

: short-encode   ( version inum lowbit offset -- )
   2/ or next-inode c!  1 'next-inode +!    ( inum version )
   curinum !  curvers !                     ( )
;

: encode-inode  ( version inum offset -- )
   curoffs                 ( version inum offset &curoffset )
   2dup @ -  >r            ( version inum offset &curoffset r: delta )
   !                       ( version inum r: delta )
   r@ h# 200 <  if         ( version inum r: delta )
      \ All 1-byte forms require offset < 200

      \ 1-byte form 0: nnnnnnn0: inum = cur-inum, vers = cur-vers + 1
      \ This is the next data node in a sequence from one file

      dup curinum @ =  if                  ( version inum )
         over 1- curvers @ =  if           ( version inum )
            0 r> short-encode  exit
         then                              ( version inum )
      then                                 ( version inum )

      \ 1-byte form 1: nnnnnnn1: inum = cur-inum + 1, vers = 1
      \ This is the beginning of a new file
      \ With: 4,350,592   Without: 4,476,904

      dup 1- curinum @  =  if              ( version inum )
         over 1 =  if                      ( version inum )
            1 r> short-encode  exit
         then                              ( version inum )
      then                                 ( version inum )
   then                                    ( version inum  r: delta )
   r> drop                                 ( version inum )

   curinum !   curvers !                   ( )

   \ XXX implement short form: 1.byte, inum.16, version.16, delta.16

   \ If we can't use a short form, use the long form:
   \ 0.byte, inum.32, version.32, offset.32

   \ At some point we might want to have another form with .short fields

   next-inode
   0           over    c!    1+        ( adr' )
   curinum @   over     !  na1+        ( adr' )
   curvers @   over     !  na1+        ( adr' )
   curoffs @   over     !  na1+        ( adr' )
   'next-inode !                       ( )
;

: decode-inode  ( adr -- len )
   dup  c@  h# 20 <  if             ( adr )
      1+
      dup @  curinum !  na1+        ( adr' )  \ Inum
      dup @  curvers !  na1+        ( adr' )  \ Version
          @  curoffs !              ( )       \ Offset
      d# 13                         ( len )
   else                             ( adr )
      c@  dup 1 and  if             ( byte )
         1 curinum     +!           ( byte )  \ Inum
         1 curvers      !           ( byte )  \ Version
         1 invert and               ( byte' )
      else                          ( byte )
         1 curvers     +!           ( byte )  \ Version
      then                          ( byte )
      2* curoffs +!                 ( )       \ Offset
      1                             ( len )
   then                             ( len )
;

: match-inode  ( inum mem-inode -- inum false | inum mem-inode' offset version true )
   next-inode  swap  ?do        ( inum )
      i decode-inode            ( inum len )
      over curinum @ =  if      ( inum len )  \ Inum
         i +  curoffs @  curvers @  ( inum mem-inode' offset version )
         true unloop exit
      then                      ( inum len )
   +loop                        ( inum )
   false
;
[then]

\ Tools for copying into memory
: c+!  ( adr c -- adr' )  over c! ca1+  ;
: l+!  ( adr l -- adr' )  over l! la1+  ;

: store-inode  ( inum version offset -- )
   -rot  swap  next-inode   ( offset version inum adr )
   tuck l!  la1+            ( offset version adr' )
   tuck l!  la1+            ( offset adr' )
   tuck l!  la1+            ( adr' )
   'next-inode !
;

\ Copy summary inode from FLASH to memory
\ Summary inode:  w.nodetype l.inode l.version l.offset l.totlen
: scan-sum-inode  ( adr -- len )
   wa1+   \ Skip the nodetype so we can use j@
   >r  r@ 1 j@  r@ 0 j@  r> 2 j@ pack-offset  ( version inum offset )
\   store-inode
\  encode-inode
   curinum 'next-inode aencode-inode
   d# 18                         ( len )
;

\ There are three dirent record formats:
\ delta is  current-dirent-offset - last-dirent-offset
\ 1-byte format:  (delta >> 1) | 1                \ for delta < 0x200
\ 2-byte format:  (delta >> 1) | 0, (delta >> 9)  \ for delta < 0x20000
\ 10-byte format: 0.w, pino.l, offset.l   \ For delta >= 0x20000 or different pino
\
\ The reason for this complexity is to save space in the dirent map in the
\ face of JFFS2 pathologies that could cause the dirent map to overflow.
\ An example would be a filesystem with millions of hard links to the same file.

: +dirent  ( adr -- adr' )
   c@+  dup 1 and  if  drop exit  then   ( adr' c )
   >r c@+ r> swap bwjoin                 ( adr' w )
   0=  if  2 na+  then
;

: #dirents  ( -- n )
   0
   next-dirent dirents   ( n endadr adr )
   begin  2dup >  while   +dirent  rot 1+ -rot  repeat  ( n endadr adr )
   2drop
;

\ ?erase-previous is an optimization/workaround for a JFFS2 pathology
\ in which multiple nearly-identical dirents appears one after another.
\ The pathology is caused by a garbage collection bug; we don't
\ know if the situation can also appear for other reasons.
\ The optimization overwrites the previous dirent record if the next
\ one supersedes it, thus preventing the dirent buffer from filling up
\ with millions (literally) of obsolete records.

variable prev-dirent  -1 prev-dirent !  \ Needed for erasing old one
variable prev-pino    -1 prev-pino   !  \ Needed for restoring old state for regenerating
variable prev-offset  -1 prev-offset !  \ Needed for restoring old state for regenerating
d# 256 instance buffer: prev-name

: ?erase-previous   ( boffset pino adr len -- boffset pino )
   2dup  prev-name count  $=  0=   if   ( boffset pino adr len )
      d# 255 min prev-name place        ( boffset pino )
      exit
   then                                 ( boffset pino adr len )
   2drop                                         ( boffset pino )

   dup  cur-pino @  <>  if  exit  then           ( boffset pino )

   prev-pino   @ cur-pino !
   prev-dirent @ 'next-dirent !
   prev-offset @ dirent-offset !
;

: encode-dirent-long   ( offset pino -- offset dirent-len )
   0 next-dirent w!          ( offset pino)
   next-dirent wa1+ !        ( offset )
   dup next-dirent 6 + !     ( offset )
   d# 10                     ( offset dirent-len )
;

: encode-dirent  ( boffset pino adr len -- )
   ?erase-previous                     ( boffset pino )

   next-dirent d# 10 +  jffs2-inode-base  >  if
      ." JFFS2 dirent overflow - " #dirents .d ." dirents" cr
      abort
   then

   swap pack-offset  swap               ( offset pino )
   dup cur-pino @ <>  if                ( offset pino )
      cur-pino @ prev-pino !            ( offset pino )
      dup cur-pino !                    ( offset pino )
      encode-dirent-long                ( offset dirent-len )
   else                                 ( offset pino )
      over dirent-offset @ -  1 rshift  ( offset pino delta )
      dup h# 10000 >=   if              ( offset pino delta )
         drop encode-dirent-long        ( offset dirent-len )
      else                              ( offset pino delta )
         dup h# 100 <  if               ( offset pino delta )
            1 or  next-dirent c!        ( offset pino )
            drop  1                     ( offset dirent-len )
         else                           ( offset pino delta )
            next-dirent le-w!           ( offset pino )
            drop  2                     ( offset dirent-len )
         then
      then                              ( offset dirent-len )
   then                                 ( offset dirent-len )
   next-dirent prev-dirent !            ( offset dirent-len )
   'next-dirent +!                      ( offset )
   dirent-offset @ prev-offset !        ( offset )
   dirent-offset !                      ( )
;

: w@+  ( adr -- w adr' )  dup wa1+ swap w@  ;
: l@+  ( adr -- adr' l )  dup la1+ swap l@  ;

: decode-dirent  ( adr -- false | adr' offset true )
   dup  next-dirent  >=  if  drop false exit  then
   dup c@  dup 1 and  if           ( adr c )   \ 1-byte form
      2/  /l* dirent-offset +!     ( adr )
      ca1+                         ( adr' )
      dirent-offset @              ( adr offset )
   else                            ( adr c )   \ Longer form
      drop                         ( adr )
      w@+  ?dup  if                ( adr' w )   \ 2-byte form
         /w* dirent-offset +!      ( adr )
         dirent-offset @           ( adr offset )
      else                         ( adr )     \ Long form
         l@+ cur-pino !            ( adr' )
         l@+ dirent-offset !       ( adr' )
         dirent-offset @           ( adr offset )
      then                         ( adr offset )
   then                            ( adr offset )
   true
;

\ Information that we need about the working file/directory
\ The working file changes at each level of a path search

0 instance value wd-inum  \ Inumber of directory
0 instance value wf-inum  \ Inumber of file or directory
0 instance value wf-type  \ Type - 4 for directory, d# 10 for symlink, etc

1 [if]
code (next-pino-match)  ( adr next-dirent pino cur-pino dirent-offset -- false | adr' offset true )
   dx pop             \ dx: dirent-offset
   cx pop             \ cx: cur-pino
   bx pop             \ bx: pino
   0 [sp]  bp  xchg   \ bp: next-dirent
   4 [sp]  si  xchg   \ si: adr

   si bp cmp  =  if
      0 [sp]  bp  mov            \ restore bp
      4 [sp]  si  mov            \ restore si
      4 #     sp  add            \ clean stack
      ax ax xor  0 # 0 [sp] mov  \ return false
      next
   then

   \ If the first encoded dirent is short-form, the pino is the same as
   \ before and thus matches.
   ax ax xor  0 [si] al mov         \ ax: b
   al shr  carry?  if               \ 1-byte form
      2 # ax shl  ax 0 [dx] add     \ Update dirent-offset
      1 #     si  add               \ skip byte offset
      4 [sp]  si  xchg              \ Put adr back on stack and restore si
      0 [dx]  bp  mov               \ bp: offset
      0 [sp]  bp  xchg              \ Put offset on stack and restore bp
      -1 #        push              \ Put true on stack
      next
   then

   op: 0 [si] ax mov                \ ax: w
   ax ax and  0<>  if               \ 2-byte form
      1 # ax shl  ax 0 [dx] add     \ Update dirent-offset
      2 #     si  add               \ skip word offset
      4 [sp]  si  xchg              \ Put adr back on stack and restore si
      0 [dx]  bp  mov               \ bp: offset
      0 [sp]  bp  xchg              \ Put offset on stack and restore bp
      -1 #        push              \ Put true on stack
      next
   then


   long-offsets on
   begin  
      ax ax xor
      0 [si] al mov                    \ ax: b
      al shr  carry?  if               \ 1-byte form
         2 # ax shl  ax 0 [dx] add     \ Update dirent-offset
         1 #     si  add               \ skip byte offset
      else
         op: 0 [si]  ax  mov           \ ax: w
         ax ax or  0<>  if                \ Short form
            1 # ax shl  ax 0 [dx] add     \ Update dirent-offset
            2 #     si  add               \ skip word offset
         else
            d#  6 [si]  ax  mov   ax  0 [dx]  mov  \ Update dirent-offset
            d#  2 [si]  ax  mov   ax  0 [cx]  mov  \ Update cur-pino
            d# 10 #     si  add                    \ skip record
            ax bx cmp  =  if
               4 [sp]  si  xchg           \ Put adr back on stack and restore si
               0 [dx]  bp  mov            \ bp: offset
               0 [sp]  bp  xchg           \ Put offset on stack and restore bp
               -1 #        push           \ Put true on stack
               next
            then
         then
      then
   bp si cmp  = until
   long-offsets off

   0 [sp]  bp  mov          \ restore bp
   4 [sp]  si  mov          \ restore si
   4 #     sp  add          \ clean stack
   ax ax xor  0 # 0 [sp] mov  \ return false
c;
: next-pino-match  ( adr -- false | adr' offset true )
   next-dirent wd-inum cur-pino dirent-offset (next-pino-match)
;
[then]

[ifndef] next-pino-match
: next-pino-match  ( adr -- false | adr' offset true )
   dup  next-dirent  >=  if  drop false exit  then

   \ If the first encoded dirent is short-form, the pino is the same as
   \ before and thus matches.
   dup c@  dup  1 and  if     ( adr b )
      2/ /l* dirent-offset +! ( adr )
      dirent-offset @         ( adr offset )
      swap  ca1+  swap        ( adr' offset )
      true                    ( adr offset true )
      exit
   then                       ( adr b )
   drop                       ( adr )

   dup w@  ?dup  if           ( adr w )
      /w* dirent-offset +!    ( adr )
      dirent-offset @         ( adr offset )
      swap  wa1+  swap        ( adr' offset )
      true                    ( adr offset true )
      exit
   then                       ( adr )

   begin                             ( adr )
      dup c@  dup 1 and  if          ( adr b )
         2/ /l* dirent-offset +!     ( adr )
         ca1+                        ( adr' )
      w@+ ?dup  if                   ( adr' w )
         /w* dirent-offset +!        ( adr' )
      else                           ( adr' )
         l@+ cur-pino !              ( adr' )
         l@+ dirent-offset !         ( adr' )
         wd-inum cur-pino @ =  if    ( adr' )
            dirent-offset @          ( adr' offset )
            true                     ( adr' offset true )
            exit
         then                        ( adr )
      then                           ( adr )
   dup next-dirent >=  until         ( adr )
   drop false                        ( false )
;
[then]

\ Copy summary dirent from FLASH to memory
\ Summary dirent:  w.nodetype l.totlen l.offset l.pino l.version
\ l.ino c.nsize c.type name
: scan-sum-dirent  ( adr -- len )
   2+ >r
   r@ 1 j@  r@ 2 j@            ( offset pino )
   r@ d# 22 +  r> 5 la+ c@     ( offset pino adr namelen )
   dup >r  encode-dirent       ( r: namelen )
   r> d# 24 +                  ( len )
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
      xattr-type  of  drop  d# 18   ( ." XA" cr )  endof
      xref-type   of  drop  6       ( ." R" cr  )  endof
      h# ffff     of  drop  dup  ( find-nonblank  )  endof  \ Keep scanning to end
      debug-me
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
: rdname$     ( adr -- adr len )  dup >rdname  swap rdnsize@  ;

: scan-raw-dirent  ( adr -- adr )
   dup >r
   r@ block-buf -  r@ rdpino@  r> rdname$  encode-dirent
;

\ Copy the raw inode information to memory in summary inode form
\ We do this to save space, because we will only need the full
\ information for those few inodes that correspond to the files
\ we actually access.
: scan-raw-inode  ( adr -- )
   >r  r@ riversion@  r@ riinode@  r> block-buf -  pack-offset  ( version inum offset )
   curinum 'next-inode aencode-inode
\ false to cleanmark?
;
: scan-node  ( adr -- adr' )
   dup wa1+ w@  case   ( adr nodetype )
      dirent-type  of  ( adr )
         debug-scan?  if  ." d"  then
         scan-raw-dirent    ( adr )
\          false to cleanmark?             ( adr )
      endof                 ( adr nodetype )

      inode-type  of        ( adr )
         debug-scan?  if  ." i"  then
         dup scan-raw-inode ( adr )
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

      summary-type  of   ( adr )
         ." JFFS2 warning: Bad summary node in erase block 0x" have-eblock# . cr
         drop eb-end exit
      endof              ( adr nodetype )

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
   " partition#" $call-parent partition# =
   first-time? 0= and
   " #writes" $call-parent #writes =  and
   if  exit  then

   init-curvars
   dirents 'next-dirent !
   inodes  'next-inode  !
   pages/chip  0  do
      i page>eblock  to the-eblock#
      0 prev-name c!
      i h# 3fff and 0=  if  scan-callout  then
      i no-summary?  if
         i possible-nodes?  if  i scan-raw-nodes  then
      then
   pages/eblock +loop

   " partition#" $call-parent to partition#
   " #writes"    $call-parent to #writes
;

0 [if]
\ This is some unfinished filesystem consistency checking code
\ It was started for debugging a crash that turned out to be
\ caused by overflow of the memory tables, leading to a rewrite
\ to use much less memory.

/eblock value summary-start

: .eb  ( -- )
   the-eblock# .xxx
;

: xanother-node?  ( adr -- false | adr' true )
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
: .offset  ( adr -- )  ." offset " block-buf - . ." in " .eb  ;

: check-node-data  ( adr -- )
;
Mitch_Bradley: the most common type of 'bad node'will have a mismatching data crc. And the node will end in 0xff 0xff 0xff .... when it wasn't intended to. Because of an interrupted write.
[22:52]	<dwmw2_gone>	those ones are almost certainly harmless

>	Mitch_Bradley: it should also always be true that there is no range of a file _not_ covered by a data node
[22:54]	<dwmw2_gone>	even if it's just a "hole" node -- with JFFS2_COMPR_ZERO.
[22:54]	<Mitch_Bradley>	oh, that's useful
[22:54]	<dwmw2_gone>	I had to add those 'hole' nodes to deal with truncation and then later writes past the (new) end of the file

: check-node  ( adr -- len )
   dup w@ jffs2-magic =  if    ( adr )
      dup header-crc?  if      ( adr )
         dup +raw-node         ( adr adr' )
         over - swap           ( len adr )
         check-node-data       ( len )
      else
         ." Bad header CRC at " .offset
         /eblock               ( len )
      then                     ( len )
   else                        ( adr )
      check-em
   then
;

: check-nodes  ( -- )
   block-buf  summary-start  erased?  if  exit  then
   block-buf  summary-start  bounds  ?do  i  check-node  +loop
;

: check-summary  ( -- )
   /eblock to summary-start

   \ Check magic number
   block-buf /page + -1 j@  h# 02851885  <>  if   exit  then

   block-buf /eblock + -2 j@  to summary-start

   block-buf summary-start +  bad-summary?  if
      ." Bad summary CRC for " .eb  exit
   then
;

: check-blocks  ( -- )
   pages/chip  0  do
      i page>eblock  to the-eblock#
      the-eblock# read-eblock
      check-summary
      check-nodes
   pages/eblock +loop
;
[then]

: inode-good?  ( inode -- flag )
   dup  d# 15 /l*  crc          ( riadr node-crc )
   over rincrc@ <>   if         ( riadr )
      drop false exit           ( -- false )
   then                         ( riadr )
   dup >ridata over ricsize@    ( riadr data-adr data-len )
   crc  swap ridcrc@ =
;

: get-node  ( offset -- adr )  /eblock /mod  read-eblock  block-buf +  ;

\ This is a brute-force, no tricks, insertion sort.
\ Insertion sort is bad for large numbers of elements, but in this
\ application, the number of elements is not all that large.  The time
\ is dominated by the need to scan all the nodes.  collect-nodes takes
\ about 160 ms for a tiny file (4 nodes), about 200 ms for a very large
\ one (573 nodes).
: insert-node  ( offset version adr -- )
   \ XXX check for list overflow here
   >r
   r@  r@ 2 na+  next-minode r@ -  move   ( offset version r: adr )
   r>  2!
   2 /n*  'next-minode +!                 ( )
;

: insert-sort  ( offset version -- )
   \ If the list is empty, insert at the beginning
   next-minode  minodes  =  if         ( offset version )
      minodes insert-node             ( )
      exit
   then

   \ Run the loop backwards because versions are more likely to increase
   minodes  next-minode 8 -  do              ( offset version )
      dup  i @  >  if                        ( offset version )
         \ Slide everything above up to open a slot
         i 2 na+  insert-node               ( )
         unloop exit
      then                                   ( offset version )

      dup  i @  =  if                        ( offset version )
         \ If we have a collision, we check the CRC of the new node,
         \ and if it is valid, replace the existing one.  We will
         \ end up with only the last good one in the slot.
         drop                                ( offset )
         dup get-node inode-good?  if        ( offset )
            i na1+  !                        ( )
         else                                ( offset )
            drop                             ( )
         then                                ( )
         unloop exit
      then
                                             ( offset version )
   -8 +loop                                  ( offset version )

   \ If we get here, the new node goes at the beginning of the list
   minodes  insert-node                     ( )
;


: set-root  ( -- )  1 to wd-inum  1 to wf-inum  4 to wf-type  ;

\ latest-node is for symlinks and directories, which have only one data node.

-1 value max-version  \ Local variable for latest-node
-1 value the-offset   \ Local variable for latest-node

: latest-node  ( inum -- true | rinode false )
   init-curvars  -1 to max-version      ( inum )
   inodes  begin  next-inode curinum  amatch-inode  while    ( inum inode' offset version )
\  inodes  begin  match-inode  while    ( inum inode' offset version )
      over get-node inode-good?  if     ( inum inode' offset version )
         dup max-version >  if          ( inum inode' offset version )
            to max-version              ( inum inode' offset )
            to the-offset               ( inum inode' )
         else                           ( inum inode' )
            2drop                       ( inum inode' )
         then                           ( inum inode' )
      else                              ( inum inode' offset version )
         2drop                          ( inum inode' )
      then                              ( inum inode' )
   repeat                               ( inum )
   drop
   max-version -1 =  if  true exit  then
   the-offset get-node  false
;

\ collect-node is for ordinary files which can have many data nodes

: collect-nodes  ( -- any? )
   wf-inum
   init-curvars
   minodes 'next-minode !    \ Empty the list

   inodes  begin  next-inode curinum  amatch-inode  while    ( inum inode' offset version )
\   inodes  begin  match-inode  while   ( inum inode' offset version )
      insert-sort                      ( inum inode' )
   repeat                               ( inum )
   drop                                 ( )
   next-minode minodes <>
;

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
      0 max  erase           ( final write )  \ 0 max accounts for truncation
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

: (play-inode)  ( inode -- )
   dup inode-good?  0=  if       ( inode )
      debug-scan?  if  ." Skipping bad inode."  cr  then
      drop exit
   then

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

\ This is related to play-log, but instead of going forward and
\ reading the data, it goes backward and just looks for the last
\ good node, from which it extracts the total size field.
: find-size  ( -- size )
   -1 to the-eblock#
   -1 to have-eblock#
   next-minode  begin  dup minodes <>  while   ( 'minode )
      8 -  dup na1+ @ get-node                 ( 'minode' inode )
      dup inode-good?  if                      ( 'minode inode )
         nip  riisize@                         ( size )
         exit                                  ( -- size )
      then                                     ( 'minode inode )
      drop                                     ( 'minode )
   repeat                                      ( 'minode )
   drop  0                                     ( size )
;

: play-log  ( -- )
   get-inflater

   -1 to the-eblock#
   -1 to have-eblock#
   0 to file-size
   next-minode  minodes  ?do   i na1+ @ get-node  (play-inode)  8 +loop

   release-inflater
;
: ?play-log  ( -- )
   file-size -1 =  if
      file-buf -1 =  if
         \ This is the value we will use for file-buf if we use read and seek
         \ For load, the buffer address is given to us
         next-minode to file-buf
      then
      play-log
   then
;

char \ instance value delimiter

defer $resolve-path
d# 1024 constant /symlink   \ Max length of a symbolic link

: strip\  ( name$ -- name$' )
   dup  0<>  if                      ( name$ )
      over c@  delimiter  =  if      ( name$ )
         1 /string                   ( name$ )
         set-root                    ( name$ )
      then                           ( name$ )
   then                              ( name$ )
;

0 instance value my-vers  \ Highest version number - local to $find-name
0 0 2value tail-name$

: ?update-dirent  ( offset name$  -- )
   2dup to tail-name$
   rot get-node >r                        ( name$  r: rdirent )
   r@ rdname$  $=  if                     ( r: rdirent )
      wd-inum  r@ rdpino@  =  if          ( r: rdirent )
         r@ rdversion@  my-vers  >  if    ( r: rdirent )
            r@ rdversion@  to my-vers     ( r: rdirent )
            r@ rdinode@    to wf-inum     ( r: rdirent )
            r@ rdtype@     to wf-type     ( r: rdirent )
         then                             ( r: rdirent )
      then                                ( r: rdirent )
   then                                   ( r: rdirent )
   r> drop                                ( )
;

: >parent  ( ino -- true | pino false )
   dup 1 =  if  false exit  then                  ( ino )  \ Root is special
   parents  begin  dup next-parent  <>  while     ( ino adr )
      2dup @ =  if   nip na1+ @ false exit  then  ( ino adr )
      2 na+                                       ( ino adr' )
   repeat                                         ( ino adr )
   2drop true
;

: remember-parent  ( pino ino -- )
   dup >parent  if    ( pino ino )
      next-parent parents -  /parent-buf >=  if
         ." Parent directory cache overflow" cr
         2drop exit
      then
      next-parent !  next-parent na1+ !
      next-parent 2 na+  to next-parent
   else               ( pino ino existing-pino )
      3drop
   then
;

: select-parent  ( -- error? )
   wd-inum  >parent   if  true exit  then  ( pino )
   to wd-inum
   false
;
: .finum  ( inum -- )
   init-curvars
   inodes  begin  next-inode curinum  amatch-inode  while    ( inum inode' offset version )
      drop  get-node                  ( inum inode' adr )
      ." Vers: " dup riversion@ .     ( inum inode' len adr )
      ." Floc: " dup rioffset@ .      ( inum inode' len adr )
      ." Dlen: " dup ridsize@ .       ( inum inode' len adr )
      ." Mode: " dup rimode@ .        ( inum inode' len adr )
      drop cr                         ( inum inode' len )
   repeat                             ( inum )
   drop
;

: .dirinum  ( inum -- )
   >r
   dirents  begin  decode-dirent  while  ( adr' offset pino r: )
      get-node dup rdinode@              ( adr' node-adr this-inum r: inum )
      r@ =  if
         dup rdname$ type
         ."  Vers: "  dup rdversion@ .
         ."   Pino: " dup rdpino@ .
\ Inum is known since we searched for it, and type is always "directory"
\ since we searched the dirent list.
\         ."  Inum: "  dup rdinode@ .
         cr
      then                               ( adr' node-adr r: inum )
      drop                               ( adr' r: inum )
   repeat                                ( r: inum )
   r> drop
;

: $find-name  ( name$ -- error? )
   -1 to my-vers                         ( name$ )

   2dup " ." $=  if  2drop false exit  then   ( name$ )  \ Change nothing...
   2dup " .." $=  if                       ( name$ )
      2drop                                ( )
      select-parent  exit
   then                                    ( name$ )

   0 dirent-offset !
   dirents  begin  next-pino-match  while  ( name$  adr' offset )
      2over  ?update-dirent                ( name$ adr )
   repeat                                  ( name$ )
   2drop                                   ( )
   my-vers 0<   if  true exit  then        ( )  \ Name not found
   wf-inum 0=   if  true exit  then        ( )  \ Name was deleted
   wf-type 4  =  if
      wd-inum wf-inum remember-parent
      wf-inum to wd-inum
   then
   false
;

\ The work file is a symlink.  Resolve it to a new dirent
: dir-link  ( -- error? )
   delimiter >r  [char] / to delimiter

   \ Allocate temporary space for the symlink value (new name)
   /symlink alloc-mem >r

   wf-inum latest-node  if         ( )
      true
   else                            ( rinode )
      dup >ridata  swap ridsize@   ( adr len )
      tuck  r@ swap  move          ( len )
      r@ swap  $resolve-path       ( error? )
   then   

   r> /symlink free-mem
   r> to delimiter
;

: ($resolve-path)  ( path$ -- error? )
   4 to wf-type
   begin  strip\  dup  while            ( path$  )
      wf-type  case                     ( path$  c: type )
         4  of   \ Directory                       ( path$ )
            delimiter left-parse-string            ( rem$' head$ )
            $find-name  if  2drop true exit  then  ( rem$ )
         endof                                     ( rem$ )

         d# 10  of   \ symlink                     ( rem$ )
            dir-link  if  2drop true exit  then    ( rem$ )
         endof                                     ( rem$ )
         ( default )                               ( rem$  c: type )

         \ The parent is an ordinary file or something else that
         \ can't be treated as a directory
         3drop true exit
      endcase                           ( rem$ )
   repeat                               ( rem$ )
   2drop false                          ( false )
;

\ : $chdir  ( path$ -- error? )
\    \ XXX should save wf-* and restore them on failure
\    $resolve-path  if  true exit  then  ( dirent )
\    wf-type 4 <>     \ Return true (error) if it's not a directory
\ ;

' ($resolve-path) to $resolve-path

\ "tdirent" section

\ This section makes a list of directory entries for a given directory.
\ It is used only by "next-file-info".  It scans the in-memory abbreviated
\ directory list, looking for entries whose parent inum matches that of
\ the current directory.  It checks for duplicate names, superseding
\ older versions and removing unlinked ones.

: tdinum@     ( tdirent -- inum )   l@  ;
: tdversion@  ( tdirent -- vers )   la1+ l@  ;
: tdname$     ( tdirent -- name$ )  2 la+ count ;
: tdlen       ( tdirent -- len )  dup tdname$ + swap -  ;

\ Move down all the following tdirents to overwrite the current one.

: remove-tdirent  ( tdirent -- )
   dup  tdlen              ( tdirent len )
   2dup +                  ( tdirent len  next-tdirent )
   rot                     ( len  next-tdirent tdirent )
   next-minode 2 pick -    ( len  next-tdirent tdirent move-len )
   move                    ( len )
   negate 'next-minode +!  ( )
; 
: replace-tdirent  ( rdirent tdirent -- )
   over rdinode@    over      l!    ( rdirent tdirent' )  \ Inum
   swap rdversion@  swap la1+ l!    ( )                   \ Version
;

: place-tdirent  ( rdirent -- )
   next-minode               ( rdirent tdirent )
   over rdinode@   l+!       ( rdirent tdirent' )
   over rdversion@ l+!       ( rdirent tdirent' )
   swap rdname$              ( tdirent name$ )
   rot pack                  ( tdirent )
   count + 'next-minode !    ( )
;

: insert-dirent  ( offset -- )
   get-node                                     ( rdirent )
   next-minode  minodes  ?do                    ( rdirent )
      dup rdname$  i tdname$  $=  if            ( rdirent )  \ Same name
         dup rdversion@  i tdversion@  >  if    ( rdirent )  \ New version
            dup i replace-tdirent               ( rdirent )
         then                                   ( rdirent )
         drop unloop exit
      then                                      ( rdirent )
      i tdlen                                   ( rdirent )
   +loop                                        ( rdirent )
   place-tdirent
;

: prep-dirents  ( -- )
   minodes 'next-minode !   \ Empty the list
   dirents                         ( adr )
   begin  next-pino-match  while   ( adr'  offset )
      insert-dirent                ( adr )
   repeat                          ( )
;

\ End of "tdirent" section

true [if]
\ "delete file" section

\ For now, just 0 the modify time, since we only support deleting
: now-seconds  ( -- secs )  0  ;

: make-raw-dirent  ( pino version name$ dirino ftype -- adr len )
   2 pick d# 40 + /l round-up          ( pino version name$ dirino ftype len )
   dup >r alloc-mem                    ( pino version name$ dirino ftype adr r: len )
   dup r@ erase  >r                    ( pino version name$ dirino ftype r: len adr )
   now-seconds over 6 j!  \ mctime     ( pino version name$ dirino ftype r: len adr )
   r@ 7 la+ 1+ c!         \ type       ( pino version name$ dirino       r: len adr )
   r@ 5 j!                \ dirino     ( pino version name$              r: len adr )
   dup  r@ 7 la+ c!       \ nsize      ( pino version name$              r: len adr )
   2dup crc  r@ 9 j!      \ name_crc   ( pino version name$              r: len adr )
   dup d# 10 la+  r@ 1 j! \ node-len   ( pino version name$              r: len adr )
   r@ d# 10 la+ swap move \ name       ( pino version                    r: len adr )
   \ Null terminate?
   r@ 4 j!                \ version    ( pino                            r: len adr )
   r@ 3 j!                \ pino       ( r: len adr )
   dirent-type r@ wa1+ w! \ nodetype   ( r: len adr )
   jffs2-magic r@ w!      \ magic      ( r: len adr )
   r@ 8 crc r@ 2 j!       \ hdr_crc    ( r: len adr )
   r@ 8 /l* crc  r@ 8 j!  \ node_crc   ( r: len adr )
   r> r>                               ( adr len )
;

: erased?  ( adr len -- flag )
   bounds  ?do
      i l@ -1 <>  if  false unloop exit  then
   /n +loop
   true
;
: find-empty-page   ( -- true | page# false )
   pages/chip  0  ?do
      \ If the last page in the eblock is readable and erased ...
      i pages/eblock + 1-  1 read-pages  0=  if
         block-buf /page erased?  if
            \ Find the first readable and erased page in that eblock
            i pages/eblock bounds  do
               i 1 read-pages  0=  if
                  block-buf /page erased?  if
                     i false  unloop unloop exit
                  then
               then
            loop
         then
      then
   pages/eblock +loop
   true
;
: put-node  ( adr len page# -- )
   true to first-time?
   -1 to have-eblock#               ( adr len page# )
   >r                               ( adr len         r: page# )
   2dup block-buf  swap move        ( adr len         r: page# )
   tuck free-mem                    ( len             r: page# )
   block-buf /page rot /string      ( pad-adr pad-len r: page# )
   2dup erase                       ( pad-adr pad-len r: page# )
   over 1 j!                  \ totlen      ( pad-adr r: page# )
   jffs2-magic over w!        \ magic       ( pad-adr r: page# )
   padding-type over wa1+ w!  \ nodetype    ( pad-adr r: page# )
   dup 8 crc  swap 2 j!       \ crc         (         r: page# )
   block-buf r> 1  " write-blocks" $call-parent              ( )
   1 <>  dup  if  ." JFFS2: write failed"  then       ( error? )
;

: $delete  ( adr len -- error? )
   $resolve-path  if  true exit  then           ( )
   wf-type 4 =  if  true exit  then             ( )  \ Don't delete directories
   wd-inum                                      ( parent-ino )
   my-vers 1+                                   ( parent-ino new-version )
   tail-name$                                   ( parent-ino new-version name$ )
   0 0 make-raw-dirent                          ( adr len )
   find-empty-page  if  2drop true exit  then   ( adr len page# )
   put-node
;

\ XXX check for empty first
: $rmdir  ( adr len -- error? )
   $resolve-path  if  true exit  then           ( )
   wf-type 4 <>  if  true exit  then            ( )  \ Must be a directory
   wf-inum  >parent  if  true exit  then        ( parent-ino )
   my-vers 1+                                   ( parent-ino new-version )
   tail-name$                                   ( parent-ino new-version name$ )
   0 0 make-raw-dirent                          ( adr len )
   find-empty-page  if  2drop true exit  then   ( adr len page# )
   put-node
;


\ End of "delete file" section
[then]

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

headers
external
: seek  ( d.offset -- status )
   0<>  over file-size u>  or  if  drop true  exit  then \ Seek offset too big
   to seek-ptr
   false
;

: ?release  ( flag -- flag )  dup 0=  if  release-buffers  then  ;

\ Starting at the current directory (wd-inum), process all the path components,
\ resolving symlinks until either a directory or an ordinary file is found.
\ If the resulting final component is a directory, leave wd-inum set to it.
\ If the resulting final component is a file, collect its data nodes so that
\ "seek", "read", and "load" will access its data.

: $find-file  ( name$ -- found? )
   $resolve-path  if  false exit  then  ( )

   begin
      \ We now have the dirent for the file at the end of the string
      wf-type  case
         4      of  wf-inum to wd-inum   true exit  endof  \ Directory
         8      of  collect-nodes             exit  endof  \ Regular file
         d# 10  of  dir-link  if  false exit  then  endof  \ Link
         ( default )   \ Anything else (special file) is error
            drop false exit
      endcase
   again
;

: open  ( -- flag )
   \ This lets us open the node during compilation
   standalone?  0=  if  true exit  then

   0 to seek-ptr                                ( )

   set-sizes  allocate-buffers                  ( )

\   my-args " :check" $=  if  check-blocks true exit  then

   scan-occupied                                ( )

   false to first-time?

   my-args " <NoFile>"  $=  if  true exit  then

   set-root
   my-args  $find-file  ( okay? )
   ?release
;

: close  ( -- )  release-buffers  ;

: size  ( -- d.size )  find-size 0  ;

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

0 instance value last-tdirent
0 instance value last-rinode
: $readlink  ( name$ -- true | expansion$ false )
   last-tdirent tdname$ $=  0=  if  true exit  then   ( )
   last-rinode >ridata  last-rinode ridsize@ false    ( expansion$ false )
;

: next-file-info  ( id -- false | id' s m h d m y len attributes name$ true )
   dup 0=  if  drop prep-dirents  minodes  then   ( tdirent )

   \ Skip deleted nodes
   begin
      dup next-minode =  if  drop false exit  then   ( tdirent )
      dup tdinum@  0=                                ( tdirent deleted? )
   while                                             ( tdirent )
      dup tdlen +                                    ( tdirent' )
   repeat                                            ( tdirent )

   dup to last-tdirent                               ( tdirent )
   dup >r  dup tdlen +                               ( id' r: tdirent )
   r@ tdinum@  latest-node  if                       ( id' r: tdirent )
      ." Can't find data node" cr
      0 0 0  0 0 0           ( id' s m h  d m y  r: tdirent )
      0                                ( ... len r: tdirent )
      0                         ( ... attributes r: tdirent )
   else                           ( id' rinode r: tdirent )
      dup to last-rinode
      >r                          ( id'  r: tdirent rinode )
      r@ rimtime@  unix-seconds>  ( id' s m h  d m y  r: tdirent rinode )
      r@ riisize@                 ( id' s m h  d m y  len r: tdirent rinode )
      r> rimode@                  ( id' s m h  d m y  len  mode  r: tdirent )
   then
   r> tdname$ true
;

: free-bytes  ( -- d.#bytes )  0 0  ;

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
