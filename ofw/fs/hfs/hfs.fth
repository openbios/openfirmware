purpose: Macintosh File System support package
\ See license at end of file

dev /packages
new-device
" hfs-file-system" device-name
0 0  " support" property

headerless
0 instance value /al-blk
0 instance value al-blk0

\ The "extents" structure describes a contiguous piece of a file.
\ They are stored in groups of 3.  The first group of three is
\ stored in:
\   a) The catalog file node, for ordinary file data and resource forks
\   b) The volume info record, for the catalog file and the extents
\      overflow file.
\ Subsequent groups of three are stored in node records within the
\ extents overflow file, tagged by file ID and which fork.  The
\ extents overflow file itself is described solely by its first
\ three extent descriptors, and does not use overflow extents to
\ describe itself.

struct ( extent )
   /w    field >first-al-blk
   /w    field >#al-blks
constant /extent
/extent 3 * constant /extents

\ Given a target logical block number, the address of an array of 3 extents
\ entries, and the number of the logical block represented by the first
\ entry in that array, find the physical block number corresponding to the
\ target logical block number and the number of blocks after it in the
\ enclosing extent.
: (next-piece)  ( log-blk# extents-adr extent-log-blk -- phys-blk# #blks )
   3 0  do    ( log-blk# extent extent-blk# )
      over >#al-blks be-w@ +           ( log-blk# extent extent-max-blk# )
      2 pick over u<  if  leave  then  ( log-blk# extent extent-max-blk# )
      swap /extent + swap              ( log-blk# extent' extent-max-blk# )
   loop                                ( log-blk# extent' extent-max-blk# )
   swap >r  swap -                     ( #blks )
   r@ >first-al-blk be-w@  r> >#al-blks be-w@ +  over - swap
;

\ Determine the total number of blocks described by the array of 3 extents
\ entries beginning at extents-adr
: extent-#blks  ( extents-adr -- #blks )
   0  swap >#al-blks  /extents  bounds  do  i be-w@ +  /extent +loop
;

\ A node record is is a fixed length container that contains one or more
\ variable-length nodes.

struct ( node-record )
   /l    field >flink
   /l    field >blink
   /c    field >type
   /c    field >level
   /w    field >#recs
   h# 1f4 +
constant /node-record
/node-record instance buffer: node-record


\ Each B*Tree file begins with a header node.

struct  ( header-node )
   /w    field >tree-depth
   /l    field >root-index
   /l    field >#leaf-records
   /l    field >first-leaf
   /l    field >last-leaf
   /w    field >reclen
   /w    field >whatever1
   /l    field >total#nodes
   /l    field >#free-nodes
constant /master-index

\ Nodes in the catalog file come in three flavors - thread, directory, and file

struct ( thread-catalog-entry ) \ Type = 3 or 4
   1 +
   d# 8 +
   /l    field >thread-parent
   d# 32 field >thread-name
drop

struct  ( times )
   /l    field >create-time
   /l    field >modify-time
   /l    field >backup-time
constant /times

struct ( dir-catalog-entry )
   1 +
   /w    field >dir-flags
   /w    field >valence
   /l    field >dir-id
   /times field >dir-times
   d# 16 field >dir-user-finder-info
   d# 16 field >dir-finder-info
   d# 16 field >dir-reserved
drop

struct ( file-catalog-entry )
   1 +
   /c    field >file-flags   \ h#80:record used  2:thread rec exists 1:locked
   /c    field >file-type    \ Supposed to always contain 0
   d# 16 field >user-finder
   /l    field >file#
   /w    field >dblk0
   /l    field >dleof
   /l    field >dpeof
   /w    field >rblk0
   /l    field >rleof
   /l    field >rpeof
   /times field >file-times
   d# 16 field >finder-info
   /w    field >/clump
   /extents field >data-extents
   /extents field >resource-extents
   /l +  ( reserved )
constant /catalog-entry

: skip-key  ( adr -- adr' )  count  1 or  +  ;

\ Each HFS volume is described by a volume-info structure that is stored
\ at offset 1K bytes from the beginning of the volume.

struct ( volume-info )
   /w    field >magic
   /l    field >init-date
   /l    field >mode-date
   /w    field >volume-attributes
   /w    field >volume-#files
   /w    field >bitmap-blk#
   /w    field >al-ptr
   /w    field >vol-#al-blks
   /l    field >/al-blk
   /l    field >vol-/clump
   /w    field >al-blk0
   /l    field >next-file#
   /w    field >#free-blocks
   h# 1c field >vol-name
   /l    field >bkup-date
   /w    field >vseq#
   /l    field >write-count
   /l    field >/extent-clump
   /l    field >/catalog-clump
   /w    field >#rt-dirs
   /l    field >#files
   /l    field >#directories
   d# 32 field >vol-finder-info
   /w    field >vc-size
   /w    field >vcbm-size
   /w    field >ctlc-size
   /l    field >/extent-tree
   /extents field >extent-extents
   /l    field >/catalog-tree
   /extents field >catalog-extents
   h# 15e +			\ There's something at offset 0x5f4 too
constant /volume-info

/volume-info instance buffer: volume-info

3 constant extent-file-id
4 constant catalog-file-id

\ This forward reference is necessary because B*Trees are stored in
\ files that are described by extents, some of which can be stored in
\ the extents overflow B*Tree file.  Infinite recursion is prevented by
\ ensuring that the extents overflow file is contained entirely within
\ the three fixed extents, so that file does not need overflow extents.
defer search-btree

: >extent-file-blk#  ( log-blk# -- phys-blk# )
   volume-info >extent-extents  0  (next-piece)  drop
;

: extent-compare  ( key-adr1 key-adr2 -- -|0|+ )
   over ca1+ c@  over ca1+ c@  -  ?dup  if           ( key-adr1 key-adr2 +- )
      over wa1+ be-l@  over wa1+ be-l@  -  ?dup  if  ( key-adr1 key-adr2 +- )
         swap 6 + be-w@  swap 6 + be-w@  -           ( +|0|- )
      else                                           ( key-adr1 key-adr2 )
         nip nip                                     ( +|- )
      then                                           ( +|0|- )
   else                                              ( key-adr1 key-adr2 )
      nip nip                                        ( +|- )
   then                                              ( +|0|- )
;

: find-extent  ( al-blk# file-id fork -- node-adr )
   d# 10 alloc-mem  >r  ( al-blk# file-id fork r: key-buffer )
   r@ ca1+ c!		( al-blk# file-id )
   r@ wa1+ be-l!        ( al-blk# )
   r@ 6 +  be-w!        ( )
   r@  ['] extent-compare  extent-file-id  search-btree
   r> d# 10 free-mem
   0= abort" Can't find extent"
;

: >catalog-file-blk#  ( log-blk# -- phys-blk# )
   0  volume-info >catalog-extents >r        ( log-blk# 0 r: entents-adr )

   begin  2dup r@ extent-#blks +  u>  while  ( log-blk# blk# r: extents-adr )
      r> extent-#blks +                      ( log-blk# blk#' )
      dup catalog-file-id 0 find-extent      ( log-blk# blk# node-adr )
      skip-key >r                            ( log-blk# blk# r: extents-adr' )
   repeat                                    ( log-blk# blk# r: extents-adr )

   \ Now log-blk# is within the group of extents at "extents-adr" and
   \ blk# is the beginning logical block of that extents group.

   r> swap  (next-piece) drop                ( phys-blk# )
;

: al-blk>offset  ( al-blk# -- d.disk-offset )  /al-blk um*  al-blk0 0  d+  ;

0 instance value btree-file#

\ Return the physical disk offset of the indicated node record from the file
\ "btree-file#", 
: >node-rec-offset  ( rec# -- d.disk-offset )
   /node-record um*  /al-blk um/mod  0 swap        ( d.blk-offset log-blk# )
   btree-file#  case
      extent-file-id   of  >extent-file-blk#   endof
      catalog-file-id  of  >catalog-file-blk#  endof
   endcase                                         ( d.blk-offset phys-blk# )
   al-blk>offset d+                                ( d.disk-offset )
;

\ "Cache tags" to remember which node is currently in the buffer
-1 instance value node-rec#
-1 instance value node-file#

: >node-rec  ( rec# -- record-adr )
   dup node-rec# =  btree-file# node-file# =  and  if
      drop node-record exit
   then                                                 ( rec# )

   dup >node-rec-offset  " seek" $call-parent  drop     ( rec# )
   node-record /node-record " read" $call-parent  drop  ( rec# )

   \ Update "cache tags"
   to node-rec#  btree-file# to node-file#             ( )

   node-record
;

: >nextnode  ( node# rec# -- node#' rec#' )
   dup >node-rec dup >#recs be-w@   ( node# rec# rec& #recs )
   3 pick 1+                        ( node# rec# rec& #recs node#' )
   <=  if                           ( node# rec# rec& )
      nip nip  >flink be-l@  0 swap ( 0 rec#' )
   else                             ( node# rec# rec& )
      drop swap 1+ swap             ( node#' rec# )
   then
;
: >node  ( node# rec# -- node-adr )
   >node-rec  dup /node-record +  rot 1+ /w* -  be-w@  +
;

defer key-compare
: search-ply  ( key-adr node# rec# -- key-adr node#' rec#' )
   2>r 2r@
   begin 
      3dup >node key-compare                ( key-adr node#' rec#' )
      ?dup 0= if                            ( key-adr node#' rec#' )
         2r> 2drop exit
      then                                  ( key-adr node#' rec#' flag )
      0<  if                                ( key-adr node#' rec#' )
         2drop 2r> exit
      then                                  ( key-adr node#' rec#' )
      2r> 2drop  2>r                        ( key-adr node#' rec#' )
      2r@ >nextnode  2dup or  while         ( key-adr node#' rec#' )
   repeat                                   ( key-adr node#' rec#' )
   2drop  2r>
;

0 instance value last-node#
0 instance value last-rec#
: (search-btree)  ( key-adr compare-xt btree-file# -- false | node-adr true )
   btree-file# >r   to btree-file#        
   ['] key-compare behavior >r  to key-compare  ( key-adr r: old-file# old-xt )
   0 0 >node >root-index be-l@ 0 swap       ( key-adr node# rec# )
   begin                                    ( key-adr node# rec# )
      search-ply                            ( key-adr node#' rec#' )
      dup >node-rec >level c@ 1 >           ( key-adr node#' rec#' leval )
   while                                    ( key-adr node# rec# )
      \ Go down a level
      >node skip-key be-l@  0 swap          ( key-adr node#' rec#' )
   repeat                                   ( key-adr node# rec# )

   \ If we are searching the catalog tree, save the node and record
   \ numbers for the benefit of next-file
   btree-file#  catalog-file-id =  if
      2dup to last-rec#  to last-node#
   then

   >node tuck  key-compare  if              ( node-adr )
      drop false
   else
      true
   then

   r> to key-compare  r> to btree-file#
;
' (search-btree) to search-btree

: read-blocks  ( adr blk# #blks -- )
   swap al-blk>offset  " seek" $call-parent  drop   ( adr #blks )
   /al-blk *  " read" $call-parent  drop
;
: get-catalog  ( -- )
   h# 400 0  " seek" $call-parent drop
   volume-info /volume-info  " read" $call-parent  drop

   volume-info >r
   r@ >magic be-w@  h# 4244 <>  abort" Bad volume magic number"
   r@ >/al-blk be-l@ to /al-blk
   r@ >al-blk0 be-w@ h# 200 *  to al-blk0
   r> drop
;
: name-compare  ( name-adr1 name-adr2 -- -|0|+ )
   >r  count tuck                ( len1 adr1 len1 r: name-adr2 )
   r>  count dup >r              ( len1 adr1 len1 adr2 len2 r: len2 )
   rot min caps-comp  ?dup  if   ( len1 +|- r: len2 )
      nip r> drop                ( +|- )
   else                          ( len1 r: len2 )
      r> -                       ( +|- )
   then
;
: path-compare  ( key-adr1 key-adr2 -- -|0|+ )
   dup c@ 0= if 2drop 1 exit then         ( key-adr1 key-adr2 )
   swap wa1+ swap wa1+                    ( dirid-adr1 dirid-adr2 )
   over be-l@ over be-l@  -  ?dup  if     ( dirid-adr1 dirid-adr2 -|+ )
      nip nip                             ( -|+ )
   else                                   ( dirid-adr1 dirid-adr2 )
      swap la1+  swap la1+ name-compare   ( -|0|+ )
   then
;
: type-compare  ( key-adr1 key-adr2 -- -|0|+ )
   dup c@ 0= if 2drop 1 exit then         ( key-adr1 key-adr2 )
   swap wa1+ swap wa1+                    ( dirid-adr1 dirid-adr2 )
   over be-l@ over be-l@  -  ?dup  if     ( dirid-adr1 dirid-adr2 -|+ )
      nip nip exit                        ( -|+ )
   then
   node-record >level c@ 1 = if           ( dirid-adr1 dirid-adr2 )
      swap la1+  swap la1+                ( adr1 adr2 )
      skip-key dup c@ 2 = if              ( adr1 filerec )
         1+ >user-finder be-l@  swap      ( type adr1 )
         ca1+ be-l@ = if 
            0                             ( 0 )  \ found it
         else
            1                             ( 1 )  \ not the type we want
         then
      else                                ( adr1 filerec )
         2drop 1                          ( 1 )  \ not a file
      then
   else                                   ( dirid-adr1 dirid-adr2 )
      2drop -1                            ( -1 )  \ not level 1
   then
;

\ search string for %xx and replace with hex char
: translate-name ( adr len -- adr len' )
   push-hex
   2dup                             ( adr len adr len )
   begin dup while                  ( adr len adr len )
      over c@ [char] % = if         ( adr len adr len )
         rot 2 - -rot               ( adr len' adr len )
         over 1+ 2 $number 0= if    ( adr len adr len n )
            2 pick c! 2 - swap 1+ swap   ( adr len adr' len' )
            over dup 2+ swap 4 pick move ( adr len adr' len' )
         then
      else
         swap 1+ swap 1-            ( adr len adr' len' )
      then
   repeat
   2drop
   pop-base
;

d# 38 instance buffer: file-key
: find-file  ( adr len dir-id -- false | node-adr true )
   file-key wa1+ be-l!             ( adr len )
   translate-name                  ( adr len )
   over c@ [char] :   = if \ search by type
      1 /string                    ( adr len )
      file-key 6 + place           ( )
      file-key  ['] type-compare  catalog-file-id  search-btree
   else                    \ search by name
      file-key 6 + place           ( )
      file-key  ['] path-compare  catalog-file-id  search-btree
   then
;

0 instance value next-log-blk
/extents buffer: extents
0 instance value extent-log-blk
0 instance value blk-offset

0 instance value the-fork	
0 instance value current-node	\ The catalog node that the last lookup found
0 instance value cwd-id		\ The current directory; a parent if file-id !0
0 instance value file-id	\ The current fileid, or 0 if the last lookup
				\ found a directory

: follow-thread  ( adr -- node-adr false | true true )
   dup >thread-name count
   rot  >thread-parent be-l@  find-file  if
      false
   else
      true true
   then
;
\ This can fail if you try to select an alias whose referent has been deleted
: select-component  ( node-adr -- error? )
   begin
      dup to current-node
      skip-key count                                  ( adr type )
      case
         1 of  >dir-id be-l@  to cwd-id    false true   endof
         2 of  >file#  be-l@  to file-id   false true   endof
         3 of  follow-thread   endof
         4 of  follow-thread   endof
         ( default )  ." Bogus Record Type: "  dup .  nip cr
      endcase
   until
;
: select-file  ( adr len -- error? )
   dup  0=  if  2drop exit  then
   0 to file-id
   over c@  [char] \  =  if
      1 /string  2 to cwd-id
      over c@ [char] \  = if    \ blessed folder indicator?
         1 /string volume-info >vol-finder-info be-l@ to cwd-id
      then
\      " " cwd-id find-file  if  select-component  else  2drop true exit  then
   then   ( adr len )
   begin  dup  while                                        ( rem$ )

      \ Error if we have already found a file but there's more in the path
      file-id  if  
         " %RESOURCES" $=  if
            h# ff to the-fork  false
         else
            true
         then
         exit
      then                                                  ( rem$ )

      [char] \ left-parse-string                            ( rem$' name$ )

      \ Error if we can't find the path component
      cwd-id find-file  0=  if  2drop true exit  then       ( rem$ node-adr )
      
      select-component  if  2drop true exit  then           ( rem$ )
   repeat                                                   ( null$ )
   2drop  false
;

: do-seek  ( d -- )  /al-blk um/mod  to next-log-blk  to blk-offset  ;
: prime-extents  ( -- )  -1 to extent-log-blk  0 0 do-seek  ;
: extent-max-blk  ( -- last-blk#+1 )
   extent-log-blk -1 =  if  0 exit  then
   extents extent-#blks  extent-log-blk +
;
: get-extents  ( log-blk# -- )
   dup extent-log-blk u<  if
      0 to extent-log-blk
      current-node skip-key 1+
      the-fork  if  >resource-extents  else  >data-extents  then
      extents /extents  move   ( log-blk# )
   then
   \ Now ext-log-blk <= log-blk#
   begin  dup extent-max-blk u>=  while
      extent-max-blk to extent-log-blk
      extent-log-blk file-id the-fork find-extent
      skip-key extents /extents move
   repeat
   drop
   \ Now ext-log-blk <= log-blk# < extent-max-blk
;

\ Returns the address and length of the next contiguous part of the file
\ following the given logical block number
: next-piece  ( log-blk# -- phys-blk# #blks )
   dup get-extents                        ( log-blk# )
   extents  extent-log-blk  (next-piece)  ( phys-blk# #blks )
;
: hfsdfalign  ( d.byte# 'fh -- d.aligned )
   drop /al-blk um/mod nip  /al-blk um*
;

: this-size  ( -- n )
   current-node skip-key 1+  the-fork  if  >rleof  else  >dleof  then  be-l@
;
: hfsdflen   ( 'fhandle -- d.size )  drop this-size 0  ;

: hfsdfseek  ( d.byte# 'fh -- )  drop do-seek  ;

: #remaining  ( -- n )  this-size   next-log-blk /al-blk *  -  0 max  ;

: hfsfread   ( addr count 'fh -- #read )
   drop                                   ( adr len )
   #remaining min  dup >r                 ( adr #to-read )
   /al-blk 1- +  /al-blk /                ( adr #blks-to-read )
   begin  dup  while                      ( adr #blks-rem )
      >r                                  ( adr )
      dup next-log-blk next-piece         ( adr adr phys-blk# #blks )
      r@ min  dup >r                      ( adr adr phys-blk# #to-read )
      read-blocks  r> r>                  ( adr #to-read #blks-rem )
      over -  -rot                        ( #blks-rem' adr #to-read )
      /al-blk * +  swap                   ( adr' #blks-rem' )
   repeat                                 ( adr 0 )
   2drop
   r>   
;

: hfsfclose  ( 'fh -- )  drop   bfbase @  /al-blk free-mem  ;

/fd instance buffer: my-fd

: hfssetupfd  ( -- )
   0 0 do-seek
   file @ >r  my-fd file !
   /al-blk alloc-mem  /al-blk initbuf
   my-fd r/o
   ['] hfsdflen  ['] hfsdfalign  ['] hfsfclose  ['] hfsdfseek
   ['] nullwrite ['] hfsfread
   setupfd
   r> file !
;

headers

: open  ( -- )
   get-catalog
   1 to cwd-id
   -1 to extent-log-blk
   my-args select-file  if  false exit  then
   file-id  if  hfssetupfd  then
   true
;

: close  ( -- )
   file-id  if
      my-fd  ['] fclose catch  ?dup  if  .error drop  then
   then
;
: read  ( adr len -- actual )
   my-fd  ['] fgets catch  if  3drop 0  then
;
\ : write  ( adr len -- actual )
\    tuck  my-fd  ['] fputs catch  if  2drop 2drop -1  then
\ ;
: seek   ( offset.low offset.high -- error? )
   my-fd  ['] dfseek catch  if  2drop true  else  false  then
;
: size  ( -- d )  my-fd  ['] dfsize catch  if  2drop 0 0  then  ;
: load  ( adr -- size )  size drop read  ;

1 value showtype?

: file-name  ( -- adr len ) 
   current-node 6 + count                      ( adr len )
   showtype? if
      current-node skip-key c@ 2 = if
        current-node skip-key 1+ >user-finder be-l@      ( adr len type )
        file-key be-l! file-key 4 + dup h# 20 swap c! 1+ ( adr len buf )
        swap dup >r move file-key r> 5 +                 ( adr len )
      then
   then
;

headerless

\ XXX Is this correct for directory records?
: locked?  ( flags -- flag )  h# 100 and 0<>   ;

\ Convert HFS file attributes to the firmware encoding
\ see showdir.fth for a description of the firmware encoding
create type-map  h# 4000 ,  h# 8000 ,  0 ,  h# a000 ,
: >canonical-attrs  ( hfs-flags -- canon-attrs )
   >r
   \ Access permissions
   r@ locked?  if  o# 666  else  o# 777  then   \ rwxrwxrwx

   \ XXX maybe the way to set the "archive" indication is to compare
   \ the backup time with the modification time.

   \ Mutually-exclusive file types
   current-node skip-key c@ 1-  type-map swap na+ @  or

   r> drop
;

create alias-times  0 be-l,  0 be-l,  0 be-l,

decimal

\ The months are stored in this order so the leap day happens at the
\ end of a cycle.

create days/month
\ Mar   Apr   May   Jun   Jul   Aug   Sep   Oct   Nov   Dec   Jan   Feb
  31 c, 30 c, 31 c, 30 c, 31 c, 31 c, 30 c, 31 c, 30 c, 31 c, 31 c, 29 c,

: >d/m  ( day-in-year -- day month )
   d# 12 0  do
      days/month i ca+ c@  2dup <  if   ( rem days-in-month )
         drop 1+  i  leave
      then
      -
   loop
;

\ The Mac filesystem stores timestamps in seconds since midnight on 1/1/1904
: mac-time>  ( seconds -- s m h d m y )
   \ XXX we should account for accumulated leap seconds too
   60 u/mod  60 u/mod  24 u/mod          ( s m h days )
   60 -    \ shift to first cycle boundary (1Mar04)
   [ 365 4 * 1+ ] literal /mod  >r       ( s m h day-in-cycle  r: cycles )
   365 u/mod                             ( s m h day-in-year year-in-cycle )
   dup  4 =  if  2drop  365 3  then      ( s m h day-in-year year-in-cycle )
   swap  >d/m                            ( s m h year-in-cycle day month )
   9 -  dup 0>  if  rot 1+  else  12 +  rot   then  ( s m h d m year-in-cycle )
   r> 4 *  +  1904 +
;
hex

: get-mtime  ( adr -- s m h d m y )  >modify-time be-l@ mac-time>  ;
headers
: file-info  ( -- s m h d m y len attributes name$ )
   current-node skip-key count swap >r  case  ( r: adr )
      1 of
         r@ >dir-times  get-mtime  r@ >valence be-w@
      endof
      2 of
         r@ >file-times get-mtime  r@ >dleof be-l@  r@ >rleof be-l@  +
      endof
      ( default )
         >r   alias-times get-mtime  0   r>            
   endcase                                    ( s m h d m y len r: adr )
   r> >dir-flags be-w@ >canonical-attrs       ( s m h d m y len attrs )
   file-name                                  ( s m h d m y len attrs name$ )
;

headerless
: next-file  ( -- found? )
   catalog-file-id to btree-file#
   last-node# last-rec# >nextnode  2dup to last-rec#  to last-node#
   2dup or  0=  if  2drop false exit  then    ( node# rec# )
   >node  dup to current-node                 ( node-adr )
   wa1+ be-l@ cwd-id =
;

headers

: next-file-info  ( id -- false | id' s m h d m y len attributes name$ true )
   dup 0=  if
      null$ cwd-id find-file  if  drop  else  drop false exit  then
   then  ( id )
   next-file  if                       ( id )
      1+  file-info  true
   else
      drop false
   then
;
: free-bytes  ( -- d.#bytes )  volume-info >#free-blocks be-w@  /al-blk m*  ;

finish-device
device-end


\ LICENSE_BEGIN
\ Copyright (c) 1997 FirmWorks
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
