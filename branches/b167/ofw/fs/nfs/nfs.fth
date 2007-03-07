\ See license at end of file
purpose: NFS file access

\ stat: enum
\  _OK=0,
\  ERR_PERM=1,   ERR_NOENT=2,  ERR_IO=5,           ERR_NXIO=6,    ERR_ACCES=13,
\  ERR_EXIST=17, ERR_NODEV=19, ERR_NOTDIR=20,      ERR_ISDIR=21,  ERR_FBIG=27,
\  ERR_NOSPC=28, ERR_ROFS=30,  ERR_NAMETOOLONG=63, ERR_NOTEMPTY=66,
\  ERR_DQUOT=69, ERR_STALE=70, ERR_WFLUSH=99

\ fhandle: opaque[32]
\ filename: string<255>
\ struct diropargs { fhandle  dir; filename name; };

\ attrstat: 0-status {0=okay, else error code}
\     0: attr struct
\     else: void

\ ftype: enum NFNON=0,NFREG=1,NFDIR=2,NFBLK=3,NFCHR=4,NFLNK=5
\ timeval: struct 0-seconds, 1-microseconds

\ attr: struct
\ 0-type,   1-mode, 2-nlink,  3-uid, 4-gid, 5-size, 6-blocksize, 7-rdev,
\ 8-blocks, 9-fsid, a-fileid, b-timeval atime, d-timeval mtime, f-timeval ctime

headers
d# 32 instance buffer: fh0

headerless
d# 17 /l* constant /fattrs
d# 8 /l* constant /sattrs

0 instance value nfs-port#
: ?nfs-port  ( -- )
   nfs-port#  0=  if
      d# 100003 2 map-port  if
         ." Can't get RPC port# for nfs" cr  abort
      then
      to nfs-port#
   then   
   nfs-port# to rpc-port#
;
: +nfs  ( #bytes proc# -- )
   ?nfs-port
   swap alloc-rpc
   \       xid   call  RPCv2  program#        version#   NFSPROC_xxx
   rpc-xid +xu  0 +xu  2 +xu  d# 100003 +xu   2 +xu      ( proc# ) +xu
   auth-unix auth-null
;
: .nfs-error  ( error-code -- )
   debug?  if  ." NFS error # " .d  cr  else  drop  then
;
/fattrs  instance buffer: attrs

: +fhandle  ( fh -- )  /fhandle +xopaque  ;
: +nfs-file  ( 'fh #extra code -- )
   swap /fhandle +  swap  +nfs  +fhandle
;
: +nfs-dir   ( 'diropargs #extra code -- )
   swap d# 260 +  swap  +nfs-file  +x$
;
/fhandle instance buffer: fh-res
: -fhandle  ( -- )  /fhandle -xopaque fh-res /fhandle move  ;
: -fattrs  ( -- )  /fattrs  -xopaque attrs /fattrs  move  ;
: do-nfs  ( -- error?' )
   do-rpc  ?dup  0=  if             ( )
      -xu  dup  if                  ( error-code )
         .nfs-error true            ( true )
      then                          ( error? )
   then                             ( error? )
;
: -diropres  ( error? -- error?' )  dup  0=  if  -fhandle  -fattrs  then  ;
: -attrstat  ( error? -- error?' )  dup  0=  if  -fattrs  then  ;

: nfslookup  ( adr len fh -- error? )  0 4  +nfs-dir  do-nfs -diropres  ;

: nfsattributes  ( fh -- error? )
   /l 1  +nfs-file  do-nfs  -attrstat
;

[ifdef] do-ip-frag-reasm
d# 8192
[else]
d# 1024
[then]
instance value /read-max
: nfsread  ( 'data len offset 'fh -- true | actual-len false )
   3 /l*  6  +nfs-file              ( 'data len off )
   +xu  +xu  0 +xu                  ( 'data )

   do-nfs  -attrstat  if  drop true exit  then   ( 'data )
   -x$                              ( 'data adr actual-len )
   >r  swap r@  move  r>            ( actual-len )
   false                            ( actual-len false )
;
: nfswrite  ( 'data len offset 'fh -- true | actual-len false )
   2 pick 4 round-up  4 la+  8  +nfs-file         ( 'data len off )
   0 +xu  +xu  0 +xu                              ( 'data len )
   tuck  +x$                                      ( len )
   do-nfs  -attrstat  dup  if  nip  then          ( true | actual-len false )
;

headers
0 constant #blocks  ( -- n )	\ Maximum size; 0 means no fixed limit
: current-#blocks  ( -- n )	\ Current actual size
   fh0  nfsattributes  if  0  else  attrs 5 la+ be-l@  then
;

1 instance value block-size
/read-max instance value max-transfer
headerless

: >#blocks  ( #bytes -- #blocks )  block-size 1- +  block-size /  ;

char / constant delim

d# 255 instance buffer: pathbuf
: fix-delims  ( adr len -- adr' len' )
   pathbuf pack count 2dup
   bounds  ?do  ( adr len )
      i c@  dup [char] | =  swap [char] \ =  or  if  [char] / i c!  then
   loop
;

d# 255 instance buffer: mounted
: (mount)  ( filename$ -- error? )
   2dup mounted place
   fh0  -rot  nfsmount   ( error? )
   dup  if  0 mounted c!  then
;

\ The deblocker converts a block/record-oriented interface to a byte-oriented
\ interface, using internal buffering.  Disk and tape devices are usually
\ block or record oriented, but the OBP external interface is byte-oriented,
\ in order to be independent of particular device block sizes.

0 instance value deblocker
: $call-deblocker  ( ??? adr len -- ??? )  deblocker $call-method  ;
: init-deblocker  ( -- okay? )
   " "  " deblocker"  $open-package  to deblocker
   deblocker if
      true
   else
      ." Can't open deblocker package"  cr  false
   then
;

\ If the filename itself contains "//", split it around that, returning
\ filename$' as the portion preceding the "//" and "rem$" as the trailing
\ portion beginning with the second "/" of the pair.
\ For example, "/foo/bar//oof/rab" parses to "/oof/rab" "/foo/bar"
: parse-filename  ( filename$ -- rem$ filename$' )
   2dup                             ( filename$ test$ )
   begin  dup  while                ( filename$ test$ )
      delim split-string            ( filename$ head$ tail$ )
      2swap 2drop                   ( filename$ tail$ )
      dup  if  1 /string  then      ( filename$ tail$' )  \ Remove first "/"
      dup  if                       ( filename$ tail$ )
         over c@  delim =  if       ( filename$ tail$ )
            \ We found a //         ( filename$ tail$ )
            2swap  2 pick - 1-     ( rem$ filename$' ) \ Remove tail
            exit
         then                       ( filename$ tail$ )
      then                          ( filename$ tail$ )
   repeat                           ( filename$ tail$ )
   2swap                            ( null-rem$ filename$ )
;
headers
: set-server  ( server$ -- )
   dup  if  " $set-host" $call-parent  else  2drop  then
;
: url-parse  ( url$ -- filename$ server$ )
   fix-delims                              ( url$' )

   \ If the string is shorter than 2 characters, the server portion is null
   dup 2 <  if  " " exit  then             ( url$ )

   \ If the string doesn't start with //, the server portion is null
   over  " //" comp  if  " " exit  then    ( url$ )

   2 /string                               ( server/filename$ )
   delim split-string                      ( server$ filename$ )
   2swap                                   ( filename$ server$ )
;
: colon-parse  ( adr len -- filename$ server$ )
   fix-delims
   [char] : left-parse-string
;
: unmount  ( -- )
   mounted c@  if
      mounted count nfsunmount drop
      0 mounted c!
   then
;
: mount  ( filename$ -- true | fh false )
   unmount
   (mount)  if  true exit  then
   deblocker  if
      " close" $call-deblocker 
      " open"  $call-deblocker  drop
   else
      init-deblocker drop
   then
   fh0 false   
;
: $interpose  ( arg$ pkgname$ -- okay? )
   find-package  if  package-interpose true  else  2drop false  then
;
: open  ( -- okay? )
   my-args dup 0=  if  2drop true exit  then       ( arg$ )

   url-parse  set-server                           ( filename$ )
   parse-filename  (mount)  if                     ( rem$ )
      2drop false exit
   then                                            ( rem$ )
   init-deblocker 0=  if  2drop false exit  then   ( rem$ )

   \ If any arguments remain, assume we are dealing with a ZIP
   \ archive and interpose the ZIP handler 
   dup  if                                         ( rem$ )
      " zip-file-system" $interpose                ( okay? )
   else                                            ( rem$ )
      2drop true                                   ( okay? )
   then                                            ( okay? )
;
: close  ( -- )
   deblocker close-package
   unmount
;

false instance value reports?

: dma-alloc  ( #bytes -- adr )  alloc-mem  ;
: dma-free  ( adr #bytes -- )  free-mem  ;
: read-blocks   ( addr block# #blocks -- #read )
   swap                                    ( addr #blocks block# )
   reports?  if  show-progress  then       ( addr #blocks block# )
   fh0  nfsread                            ( true | actual-len false )
   if  0  else  >#blocks  then
;
: write-blocks  ( addr block# #blocks -- #written )
   swap  fh0  nfswrite    ( true | actual-len false )
   if  0  else  >#blocks  then
;

: seek  ( offset.low offset.high -- okay? )  " seek" $call-deblocker  ;
: position  ( -- offset.low offset.high )  " position" $call-deblocker  ;
: read  ( adr len -- actual-len )  " read"  $call-deblocker  ;
: write ( adr len -- actual-len )  " write" $call-deblocker  ;
: size  ( -- d.size )  " size" $call-deblocker  ;

: load  ( adr -- len )
   true to reports?
   size drop  read
   false to reports?
;
headerless
: +default-sattrs  ( -- )
   o# 666 +xu  0 +xu  1 +xu  0 +xu  0 +xu  0 +xu  0 +xu  0 +xu
;

: nfscreate  ( 'fh-res adr len fh -- error? )
   /sattrs  9  +nfs-dir                   ( 'fh-res )
   +default-sattrs                        ( 'fh-res )
   do-nfs -diropres                       ( error? )
;
headers
: $create  ( adr len -- error? )  fh0  nfscreate  ;

headerless
: nfsreadlink  ( 'fh -- true | adr len false )
   0 5 +nfs-file do-nfs  dup  0=  if  -x$ rot  then
;
headers
: $readlink  ( adr len -- true | adr len false )
   fh0 nfslookup  if  true exit  then     ( )
   fh-res nfsreadlink
;

headerless
: nfsmkdir  ( 'fh-res adr len fh -- error? )
   /sattrs  d# 14  +nfs-dir  +default-sattrs  do-nfs  -diropres
;
headers
: $mkdir  ( adr len -- error? )  fh0  nfsmkdir  ;

headerless
: nfsremove  ( adr len fh -- error? )  0  d# 10  +nfs-dir  do-nfs  ;
headers
: $delete   ( adr len -- error? )  fh0  nfsremove  ;
: $delete!  ( adr len -- error? )  $delete  ;

headerless
: nfsrmdir  ( adr len fh -- error? )  0  d# 15  +nfs-dir  do-nfs  ;
headers
: $rmdir  ( adr len -- error? )  fh0  nfsrmdir  ;

headerless
: nfsrename  ( old-name$ old-fh new-name$ new-fh -- error? )
   >r 2>r                              ( old-name$ old-fh r: new-name$ new-fh )
   d# 260 /fhandle +  d# 11  +nfs-dir  ( r: new-name$ new-fh )
   2r> r> +fhandle +x$                 ( )
   do-nfs                              ( error? )
;

: nfsreaddir  ( cookie fh -- error? )
   2 /l*  d# 16  +nfs-file  +xu  /read-max +xu  do-nfs
;
decimal
\ UFS DIR routines
\ date&time is number of seconds since 1970
create days/month
\ Jan   Feb   Mar   Apr   May   Jun   Jul   Aug   Sep   Oct   Nov   Dec
  31 c, 28 c, 31 c, 30 c, 31 c, 30 c, 31 c, 31 c, 30 c, 31 c, 30 c, 30 c,

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
: get-attributes  ( adr len -- s m h d m y len attributes )
   fh0 nfslookup  abort" nfslookup failed"
   fh-res nfsattributes  abort" nfsattributes failed"
   attrs d# 13 la+ be-l@ sec>time&date   ( s m h d m y )
   attrs 5 la+ be-l@                     ( s m h d m y len )
   attrs 1 la+ be-l@                     ( s m h d m y len attributes )
;

headers
: next-file-info  ( id -- false | id' s m h d m y len attributes name$ true )
   begin
      fh0 nfsreaddir  if  false exit  then   ( )
      -xu  0=  if  false exit  then          ( )  \ More-entries flag
      -xu drop                               ( )  \ Numerical file id
      -x$  -xu  -rot                         ( id' name$ )
      string2 $save 2>r                      ( id' )
      2r@ ['] get-attributes  catch  0=  if  ( id' s m h d m y len attr )
         2r> true  exit           ( id' s m h d m y len attr name$ true )
      then                                   ( id' x x )

      \ If get-attributes failed, it's probably because the
      \ requested file was "..", and the server won't return
      \ information for directories above the mount point.
      \ If so, we suppress the ".." entry and go to the next one.
      2drop                                           ( id' )
      2r>  " .."  $=  0=  if  drop false exit  then   ( id' )
   again
;
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
