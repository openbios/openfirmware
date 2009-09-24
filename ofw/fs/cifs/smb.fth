\ See license at end of file
purpose: Server Message Block layer of CIFS file system code

\ This lets you access Windows shares from OFW

\ TODO:
\ fix opening dir when \ missing from end of URL
\ next-file-info needs to merge pathname$ into search string
\ test with other servers
\ get password and username from config variables if they exist and not specified in URL


char \ constant delim

0. instance 2value share$
0. instance 2value server$
0. instance 2value password$
0. instance 2value pathname$
0. instance 2value tail$

0. instance 2value account$

: set-account  ( adr len -- )
   dup alloc-mem            ( adr len dst-adr )
   swap to account$         ( adr )
   account$ move            ( )
;

: parse-server  ( url$ -- rem$ )
   \ If the string is shorter than 2 characters, the server portion is null
   dup 2 <  if  " " exit  then             ( url$ )

   \ If the string doesn't start with \\, the server portion is null
   over  " \\" comp  if  " " exit  then    ( url$ )

   2 /string                               ( url$' )
   delim left-parse-string                 ( rem$ server$ )
   [char] @ split-string                   ( rem$ head$ tail$ )
   dup  if  \ @ is present, tail is server ( rem$ cred$ server$ )
      1 /string to server$                 ( rem$ cred$ )
      [char] : left-parse-string           ( rem$ password$ user$ )
      to account$  to password$            ( rem$ )
   else  \ No @; head is server            ( rem$ server$ empty$ )
      2drop  to server$                    ( rem$ )
      " GUEST" to account$                 ( rem$ )
   then                                    ( rem$ )
;

\ If the filename itself contains "\\", split it around that, returning
\ filename$' as the portion preceding the "\\" and "rem$" as the trailing
\ portion beginning with the second "\" of the pair.
\ For example, "\foo\bar\\oof\rab" parses to "\oof\rab" "\foo\bar"
: parse-pathname  ( filename$ -- rem$ filename$' )
   2dup                             ( filename$ test$ )
   begin  dup  while                ( filename$ test$ )
      delim split-string            ( filename$ head$ tail$ )
      2swap 2drop                   ( filename$ tail$ )
      dup  if  1 /string  then      ( filename$ tail$' )  \ Remove first "\"
      dup  if                       ( filename$ tail$ )
         over c@  delim =  if       ( filename$ tail$ )
            \ We found a \\         ( filename$ tail$ )
            2swap  2 pick - 1-      ( rem$ filename$' ) \ Remove tail
            to pathname$            ( rem$ )
            exit
         then                       ( filename$ tail$ )
      then                          ( filename$ tail$ )
   repeat                           ( filename$ tail$ )
   2swap to pathname$               ( null-rem$ )
;

: parse-share  ( share+path$ -- /path$ )
   delim split-string  2swap to share$  ( /path$ )
;

headers
: set-server  ( server$ -- )
   dup  if  " $set-host" $call-parent  else  2drop  then
;

8 instance buffer: signature
h# c001 constant smb-flags
h# c05c constant my-capabilities \ LargeRd, LargeWr, NTStat, NT SMBs, Large files, Unicode
0 instance value pid
0 instance value tid
0 instance value uid
0 instance value mid
0 instance value sid  \ Search ID
0 instance value msg#

0 instance value last-command

: smb-init  ( -- )
   signature 8 erase
   random h# ffff and to pid
   0 to tid
   0 to mid
   0 to uid
;

: +dialect  ( adr len -- )  2 +xb  +xbytes  0 +xb  ;

: needed  ( adr len needed -- adr len )
   over >  abort" SMB response too short"
;
: -xb  ( adr len -- adr' len' byte )
   1 needed  over c@ >r  1 /string r>
;
: -xw  ( adr len -- adr' len' byte )
   2 needed  over le-w@ >r  2 /string r>
;
: -xl  ( adr len -- adr' len' byte )
   4 needed  over le-l@ >r  4 /string r>
;
: drop-b  ( rem$ -- rem$' )  -xb drop  ;
: drop-w  ( rem$ -- rem$' )  -xw drop  ;
: drop-l  ( rem$ -- rem$' )  -xl drop  ;

: -magic  ( adr len -- adr' len' )
   4 needed  over " "(ff)SMB" comp  abort" Non-SMB response!"
   4 /string
;
: -xbytes  ( adr len n -- rem$ this$ )
   >r r@ needed                 ( adr len )
   2dup r@ /string  2swap       ( rem$ adr len )
   drop r>
;
: -wcnt  ( rem$ -- rem$' wcnt )
   -xb >r r@  2* needed  r>
;
: expect-wcnt  ( rem$ n -- rem$' )
   >r  -wcnt  r> <> abort" Unexpected word count"
;

: shift$   ( tail$ head$ -- tail$' head$' )
   2+  2swap 2 /string 2swap
;

\ The unicode length excludes the null terminator word (or byte)
: -unicode$  ( adr len -- rem$ unicode$ )
   over 0                                ( rem$ unicode$ )
   begin  third 1 >  while               ( rem$ unicode$ )
      shift$                             ( rem$' unicode$' )
      over le-w@  0=  if  2- exit  then  ( rem$ unicode$ )
   repeat
;

0 instance value server-flags
8 instance buffer: his-signature
: -smb  ( adr len -- true | adr len false )
   d# 32 needed
   -magic                      ( rem$' )
   -xb last-command <>  abort" Wrong command value in response"
   -xl  ?dup  if               ( rem$' error )
      ." SMB Error: " .x cr
      2drop true exit
   then                        ( rem$ )
   -xb >r                      ( rem$ r: flags-hi )
   r@ h# 80 and 0= abort" Reply bit not set in SMB response"
   -xw r> wljoin to server-flags      ( rem$' )
   drop-w                             ( rem$' )  \ Ignore PID high
   8 -xbytes his-signature swap move  ( rem$' )  \ Signature
   drop-w                             ( rem$' )  \ Ignore reserved
   -xw to tid                         ( rem$' )  \ Lock onto new TID
   -xw pid <> abort" PID mismatch"    ( rem$' )
   -xw to uid                         ( rem$' )  \ Lock onto new UID
   -xw mid <> abort" MID mismatch"    ( rem$' )
   false
;

0 instance value byte-cnt-adr
: bytes{  ( -- )
   x-adr to byte-cnt-adr
   0 +xw
;
: }bytes  ( -- )
   x-adr byte-cnt-adr - 2-  byte-cnt-adr le-w!
;

0 instance value word-cnt-adr
: words{  ( -- )
   x-adr to word-cnt-adr
   0 +xb
;
: }words  ( -- )
   x-adr word-cnt-adr - 1-  ( #bytes )
   dup 1 and abort" Word area length is odd!"
   2/ word-cnt-adr c!
;

: --bytes--  ( -- )  }words bytes{  ;

: smb{  ( cmd -- )
   0 session{
   " "(ff)SMB" +xbytes  ( cmd )
   dup to last-command  +xb   ( )
   0 +xl                       \ NT_STATUS_SUCCESS
   smb-flags lwsplit +xb +xw
   0 +xw                       \ PID high - always 0
   signature 8 +xbytes
   0 +xw                       \ Reserved
   tid +xw
   pid +xw
   uid +xw
   mid +xw
   words{
;
: }smb  ( -- true | adr len false )
   }bytes
   }session  if  true exit  then
   get-session-response  if  true exit  then
   -smb
;

0 instance value encrypt?
0 instance value max-tbuf
0 instance value max-raw
0 instance value max-mpx
0 instance value session-key
0 instance value capabilities
0 instance value time-hi
0 instance value time-lo
0 instance value time-zone
0 instance value key-length
0. instance 2value challenge$

: parse-negotiate  ( adr len -- error? )
   d# 17 expect-wcnt                           ( rem$' )
   -xw  0<>  abort" Bogus dialect index"       ( rem$' )
   -xb  dup 1 and 0= abort" Not supporting share-level security"  ( rem$' mode )
   2 and 0<> to encrypt?                       ( rem$ )
   -xw to max-mpx                              ( rem$' )
   drop-w                                      ( rem$' )  \ MaxNumberVcs
   -xl to max-tbuf                             ( rem$' )
   -xl to max-raw                              ( rem$' )
   -xl to session-key                          ( rem$' )
   -xl to capabilities                         ( rem$' )
   drop-l                                      ( rem$' )  \ time-low
   drop-l                                      ( rem$' )  \ time-hi
   drop-w                                      ( rem$' )  \ time zone
   -xb dup alloc-mem swap to challenge$        ( rem$ )
   -xw dup needed                              ( rem$' strings-len )
   nip                                         ( rem$' )
   challenge$ nip -xbytes drop challenge$ move ( rem$' )
   \ The rest is the server domain name and name, which we don't need
   2drop false
;
: +unicode$  ( adr len -- )
   +xalign                      \ Force to even address
   bounds ?do  i c@ +xw  loop
   0 +xw
;
: negotiate  ( -- error? )
   h# 72 smb{
   --bytes--
   " NT LM 0.12" +dialect
   }smb if  true exit  then   ( rem$ )
   parse-negotiate
;

\ Authentication for NT LM 0.12

8 instance buffer: buf8

: @7bits  ( adr bit# -- n )
   dup 7 and >r 3 rshift  ( adr byte# r: bit# )
   + be-w@  r> lshift h# fe00 and 8 rshift
;

\ This really should compute the parity bit and insert it in the LSB,
\ but I happen to know that the DES implemention in bios_crypto ignores that bit.
: >odd  ( byte -- byte' )  ;

: 7to8  ( adr -- adr' 8 )
   8 0  do  ( adr )
      dup i 7 * @7bits  >odd  buf8 i + c!   ( adr )
   loop     ( adr )
   drop     ( )
   buf8 8
;      

0 instance value password-buf
d# 16 buffer: p21-buf
d# 24 buffer: p24-buf
: p24$  ( -- adr len )  p24-buf d# 24  ;

: set-password  ( adr len -- )
   load-crypto abort" Crypto load failed"
   dup 2* alloc-mem to password-buf     ( adr len )
   tuck  0  ?do                 ( len adr )
      dup i + c@                ( len adr )
      password-buf i wa+ le-w!  ( len adr )
   loop                         ( len adr )
   drop                         ( len )
   password-buf over 2*  " md4"  crypto-hash  ( len hashed$ )
   p21-buf swap move               ( len )
   p21-buf d# 16 + 5 erase         ( len )
   password-buf swap 2* free-mem   ( )
;

: compute-password  ( -- )
   \ XXX should be contingent upon encrypt?
   challenge$  p21-buf d# 00 +  7to8  des  p24-buf d# 00 +  swap move
   challenge$  p21-buf d# 07 +  7to8  des  p24-buf d# 08 +  swap move
   challenge$  p21-buf d# 14 +  7to8  des  p24-buf d# 16 +  swap move
;

: no-andx  ( -- )
   h# ff +xb           \ No more AndX commands
   0 +xb               \ Reserved
   0 +xw               \ Offset to next AndX command
;

: send-setup  ( -- true | rem$ false )
   h# 73 smb{
   no-andx
   max-tbuf my-max-buf min  +xw
   max-mpx  my-max-mpx min  +xw
   0 +xw                      \ VC number
   0 +xl                      \ Session key  (unused when VC number is 0)
   p24$ nip dup +xw +xw       \ Password length and unicode password length
   0 +xl                      \ Reserved
   my-capabilities +xl
   }words
   bytes{
   p24$ +xbytes          \ ASCII
   p24$ +xbytes          \ Unicode
   account$ +unicode$
   " " +unicode$
   " Open Firmware" +unicode$
   " Open Firmware CIFS Client" +unicode$
   }smb
;
: drop-andx  ( rem$ -- rem$' )
   -xb h# ff <> abort" Unexpected AndX continuation"
   drop-b      ( rem$' )
   drop-w      ( rem$' )
;
0 instance value guest?
: parse-setup  ( adr len -- error? )
   3 expect-wcnt                     ( rem$ )
   drop-andx                         ( rem$' )
   -xw 1 and 0<> to guest?           ( rem$' )
   \ There is also a byte string section containing
   \   ServerOSName
   \   ServerLANManagerName
   \   ServerPrimaryDomain
   \ We don't care about them, so we stop parsing here
   \ BTW, in the setup response from WinXP, the Domain
   \ string is one byte too short - the null word in the
   \ Unicode string is really a null byte.
   2drop false
;

: session-setup  ( -- error? )
   0 to msg#
   send-setup  if  true exit  then   ( rem$ )
   parse-setup
;

: empty-response  ( true | rem$ false -- error? )
   if  true exit  then   ( rem$ )
   2drop false           ( error? )
;

: tree-disconnect  ( path$ -- error? )
   h# 71 smb{ --bytes-- }smb  empty-response
;

: tree-connect  ( server+share$ -- error? )
   h# 75 smb{
   no-andx
   8 +xw   \ Flags - 8 is set for some reason in mount.cifs, but is not defined
   1 +xw   \ Password length - 1 for null-terminator since no share-level security
   --bytes--
   0 +xb                      \ Null share password
   ( path$ ) +unicode$
   " ?????" +xbytes  0 +xb
   }smb  if  true exit  then    ( rem$ )
   2drop false
   \ The tree connect response has several uninteresting fields
;

: +path  ( path$ -- )  4 +xb  +unicode$  ;  \ 4 is buffer format

: +path}smb  ( path$ -- true | rem$ false )
   --bytes--    ( path$ )
   +path        ( )
   }smb         ( true | rem$ false )
;   

0 instance value fid
0 instance value attributes  \ 01:RO  02:Hidden  04:System  08:Volume  10:Directory  20:Archive

: $create  ( path$ -- error? )
   h# 03 smb{                       ( path$ )
   attributes +xw                   ( path$ )
   0 +xl     \ Creation time        ( path$ )
   +path}smb  if  true exit  then   ( rem$ )
   1 expect-wcnt                    ( rem$ )
   -xw to fid                       ( rem$' )
   \ The byte array is supposed to be empty
   2drop false
;

0. instance 2value size

\ We should probably use the ANDX CREATE so we can handle large files
\ Good value for access: h# 0002
\ Bits: 4000: WriteThrough  1000:DontCache  700:LocalityOfReference
\ 70: SharingMode  7: Access-0:RO,1:WO,2:RW,3:Exec
: open-file  ( path$ access -- error? )
   h# 02 smb{      ( path$ access )
   +xw             ( path$ )
   attributes +xw  ( path$ )
   +path}smb  if  true exit  then    ( rem$ )

   7 expect-wcnt                     ( rem$ )
   -xw to fid                        ( rem$' )
   drop-w  \ Attributes              ( rem$' )
   drop-l  \ Last write time         ( rem$' )
   -xl u>d  to size                  ( rem$' )
   drop-w  \ Granted access          ( rem$' )
   \ The byte array is supposed to be empty
   2drop false
;

: $mkdir  ( path$ -- error? )
   0 smb{  +path}smb  empty-response
;
: $rmdir  ( path$ -- error? )
   1 smb{  +path}smb  empty-response
;

: close-file  ( -- error? )
   4 smb{
   fid +xw
   0 +xl  \ Time
   --bytes--
   }smb
   empty-response
;

: $delete  ( path$ -- error? )
   6 smb{                     ( path$ )
   attributes +xw             ( path$ )
   +path}smb  empty-response  ( error? )
;
: $delete!  ( path$ -- error? )
   $delete
;
: $rename  ( old-path$ new-path$ -- error? )
   7 smb{                     ( old-path$ new-path$ )
   attributes +xw             ( old-path$ new-path$ )
   --bytes--                  ( old-path$ new-path$ )
   2swap +path  +path         ( )
   }smb  empty-response       ( error? )
;

: $getattr  ( path$ -- true | attr false )
   8 smb{ +path}smb  if  true exit  then
   d# 10 expect-wcnt    ( rem$' )
   -xw                  ( rem$' attr )
   nip nip  false
;

: flush  ( -- error? )
   5 smb{  fid +xw  --bytes--  }smb  empty-response
;

0. instance 2value position
: seek  ( d.offset -- error? )
   size  2over  d<  if  2drop true exit  then
   to position
   false
;

: read-some  ( adr len -- actual-len )
   max-data min
   h# 2e smb{
   no-andx
   fid +xw            ( adr len )
   position drop +xl  ( adr len )
   +xw                ( adr )
   0 +xw              ( adr )  \ min count (reserved)
   0 +xl              ( adr )  \ reserved
   0 +xw              ( adr )  \ remaining (reserved)
   position nip +xl   ( adr )
   --bytes--          ( adr )
   }smb  if  drop -1 exit  then        ( adr rem$ )
   d# 12 expect-wcnt                   ( adr rem$' )
   drop-andx                           ( adr rem$' )
   drop-w  \ Reserved                  ( adr rem$' )
   drop-w  \ Data compaction mode      ( adr rem$' )
   drop-w  \ Reserved                  ( adr rem$' )
   -xw >r  \ Actual length             ( adr rem$' r: actual )
   drop-w  \ Offset to data            ( adr rem$' r: actual )
   drop-w drop-w drop-w drop-w drop-w  ( adr rem$' r: actual )
   -xw  if  drop-b  then               ( adr rem$' r: actual ) \ Byte count and pad
   drop swap r@ move  r>               ( actual )
   dup 0  position d+ to position      ( actual )
;
: read  ( adr len -- actual )
   tuck                    ( len adr remlen )
   begin  dup  while       ( len adr remlen )
      2dup read-some       ( len adr remlen thislen )
      dup  -1  =  if       ( len adr remlen thislen )
         nip nip nip  exit
      then                 ( len adr remlen thislen )
      dup 0=  if           ( len adr remlen thislen )
         drop nip -  exit  ( actual )
      then                 ( len adr remlen thislen )
      /string              ( len adr remlen' )
   repeat                  ( len adr remlen' )
   2drop
;

: write-some  ( adr len -- actual-len )
   max-data min
   h# 2f smb{
   no-andx
   fid +xw         ( adr len )
   position drop +xl ( adr len )  \ File offset low
   0 +xl           ( adr len )  \ Reserved
   0 +xw           ( adr len )  \ Write mode - 0 is write behind, 1 is write through, other bits for pipes
   0 +xw           ( adr len )  \ Remaining - used for pipes when mode&8 is set
   0 +xw           ( adr len )  \ Reserved
   dup +xw         ( adr len )  \ Data length
   d# 64 +xw       ( adr len )  \ offset to data byte
   position nip +xl  ( adr len )  \ File offset high
   --bytes--       ( adr len )
   0 +xb           ( adr len )  \ Pad
   +xbytes         ( )          \ Data
   }smb  if  -1 exit  then             ( rem$ )
   6 expect-wcnt                       ( rem$' )
   drop-andx                           ( rem$' )
   -xw >r  \ Actual length             ( rem$' r: actual )
\ We don't anything following
\  drop-w  \ Remaining                 ( rem$' )
\  drop-l  \ Reserved                  ( rem$' )
   2drop  r>                           ( actual )
   dup 0  position d+ to position      ( actual )
;
: write  ( adr len -- actual )
   tuck                    ( len adr remlen )
   begin  dup  while       ( len adr remlen )
      2dup write-some      ( len adr remlen thislen )
      dup  -1  =  if       ( len adr remlen thislen )
         nip nip nip  exit
      then                 ( len adr remlen thislen )
      dup 0=  if           ( len adr remlen thislen )
         drop nip -  exit  ( actual )
      then                 ( len adr remlen thislen )
      /string              ( len adr remlen' )
   repeat                  ( len adr remlen' )
   2drop
;

\ template
0 [if]
: transact  ( timeout oneway #setup #retdata #retparm #data #param -- )
   h# 32 smb{
   #param     +xw
   #data      +xw
   #retparm   +xw
   #retdata   +xw
   #setupdata +xb
   0 +xb  \ Reserved
   oneway     +xw
   timeout    +xl
   0 +xw  \ Reserved
   parmcnt    +xw
   parmoffset +xw
   datacnt    +xw
   dataoffset +xw
   setupcnt   +xb
   0 +xb  \ Reserved
   [ setupcnt * +xw ]
   --bytes--
   " " +unicode$  \ Name (NULL for TRANSACTION2)
   pad +xb    \ Pad to short or long
   [ parmcnt * +xb ]
   pad +xb    \ Pad to short or long
   [ datacnt * +xb ]
   }smb
;

[then]

: continue-search  ( resumekey -- true | rem$ false )
   1-            ( resumekey' )  \ We bias it by 1 because 0 is special to OFW
   h# 32 smb{
   d# 14    +xw  \ #param
   0        +xw  \ #data
   d# 10    +xw  \ #retparm
   max-data +xw  \ #retdata
   0        +xb  \ #setupdata
   0        +xb  \ Reserved
   0        +xw  \ flags - two way, no disconnect
   0        +xl  \ timeout - return immediately
   0        +xw  \ Reserved
   d# 14    +xw  \ parmcnt
   d# 66    +xw  \ parmoffset
   0        +xw  \ datacnt
   0        +xw  \ dataoffset
   1        +xb  \ setupcnt
   0        +xb  \ Reserved

   2        +xw  \ Setup[0] = Subcommand FIND_NEXT2
   --bytes--
   0        +xb  \ Pad to align
   sid      +xw  \ Search ID
   d# 1     +xw  \ Search count
   \  h# 101   +xw  \ This value returns a 64-bit date in 100 nS unit since the Gregorian epoch
   h# 001   +xw  \ Get info in DOS format for now, so we can decode the time
   ( resumekey )
            +xl
   h# e     +xw  \ Search flags - pick up where left off 8, return resume keys 4, close on end 2
   " "      +unicode$  \ Search pattern
   }smb
;

: start-search  ( -- true | rem$ false )
   h# 32 smb{
   d# 18    +xw  \ #param
   0        +xw  \ #data
   d# 10    +xw  \ #retparm
   max-data +xw  \ #retdata
   0        +xb  \ #setupdata
   0        +xb  \ Reserved
   0        +xw  \ flags - two way, no disconnect
   0        +xl  \ timeout - return immediately
   0        +xw  \ Reserved
   d# 18    +xw  \ parmcnt    \ Actually d# 12 plus pattern length (unicode, null terminated)
   d# 66    +xw  \ parmoffset
   0        +xw  \ datacnt
   0        +xw  \ dataoffset
   1        +xb  \ setupcnt
   0        +xb  \ Reserved

   1        +xw  \ Setup[0] = Subcommand FIND_FIRST2
   --bytes--
   0        +xb  \ Pad to align
   h# 17    +xw  \ Search attributes - include dir 10, system 4, hidden 2, RO 1
   d# 1     +xw  \ Search count
   6        +xw  \ Search flags - return resume keys 4, close on end 2
   \  h# 101   +xw  \ This value returns a 64-bit date in 100 nS unit since the Gregorian epoch
   h# 001   +xw  \ Get info in DOS format for now, so we can decode the time
   0        +xl  \ Storage type
   " \*"    +unicode$  \ Search pattern
   }smb
;

: >hms  ( dos-packed-time -- secs mins hours )
   dup h#   1f and      2*   swap  ( secs packed )
   dup h# 07e0 and      5 >> swap  ( secs mins packed )
       h# f800 and  d# 11 >>       ( secs mins hours )
;  
: >dmy  ( dos-packed-date -- day month year )
   dup h#   1f and          swap   ( day packed )
   dup h# 01e0 and  5 >>    swap   ( day month packed )
       h# fe00 and  9 >> d# 1980 + ( day month year )
;  
\ Convert DOS file attributes to the firmware encoding
\ see showdir.fth for a description of the firmware encoding
: >canonical-attrs  ( dos-attrs -- canon-attrs )
   >r
   \ Access permissions
   r@     1 and  if  o# 666  else  o# 777  then \ rwxrwxrwx

   \ Bits that are independent of one another
   r@     2 and  if  h# 10000 or  then		\ hidden
   r@     4 and  if  h# 20000 or  then		\ system
   r@ h# 20 and  if  h# 40000 or  then		\ archive

   \ Mutually-exclusive file types
   r@     8 and  if  h#  3000 or  then		\ Volume label
   r> h# 10 and  if  h#  4000 or  then		\ Subdirectory
   dup h# f000 and  0=  if  h# 8000 or  then	\ Ordinary file	
;

: unicode>ascii  ( adr -- adr len )
   dup dup                        ( adr aadr uadr )
   begin                          ( adr aadr uadr )
      dup le-w@                   ( adr aadr uadr uchar )
      rot 2dup c!                 ( adr uadr uchar aadr )
      ca1+ -rot                   ( adr aadr uadr uchar )
      swap wa1+ swap              ( adr aadr uadr uchar )
  0= until                        ( adr aadr uadr )
  drop                            ( adr aadr )
  over - 1-                       ( adr len )
;

0 instance value parm-cnt
0 instance value smb-base
0 instance value parm-base
0 instance value data-base
: parse-search  ( rem$ -- false | file info .. true )
   over d# 32 - to smb-base
   d# 10 expect-wcnt
   drop-w  \ Total parameter count
   drop-w  \ Total data count
   drop-w  \ reserved
   -xw to parm-cnt
   -xw smb-base + to parm-base
   drop-w  \ Parameter displacement
   drop-w  \ # of data bytes
   -xw smb-base + to data-base
   2drop
   \ At this point we stop deserializing and just go straight to the info
   \ id s m h d m y len attr name$ true 
   parm-cnt d# 10 =  if
      parm-base le-w@ to sid
      2   ( search-count-offset )
   else   ( )
      0   ( search-count-offset )
   then   ( search-count-offset )
   parm-base + le-w@  0=  if  false  exit  then

   data-base le-l@ 1+                        ( id' )
   data-base d# 14 + le-w@ >hms              ( id s m h )
   data-base d# 12 + le-w@ >dmy              ( id s m h d m y )
   data-base d# 16 + le-l@                   ( id s m h d m y len )
   data-base d# 24 + le-w@ >canonical-attrs  ( id s m h d m y len attr )
   data-base d# 28 + unicode>ascii           ( id s m h d m y len attr name$ )
   true
;

: next-file-info  ( id -- false | id' s m h d m y len attributes name$ true )
   dup -1 =  if  drop false  exit  then                 ( id )
   ?dup  if  continue-search  else  start-search  then  ( true | adr len false )
   if  false  exit  then                                ( rem$ )
   parse-search
;

: free-bytes  ( -- d.#bytes )
   h# 80 smb{ --bytes-- }smb  if  0. exit  then
   -wcnt                   ( rem$ )
   drop-w                  ( rem$ )
   -xw >r   \ Blocks/unit  ( rem$ )
   -xw >r   \ bytes/block  ( rem$ )
   -xw >r   \ free-unit    ( rem$ )
   2drop                   ( )
   r> r> u*  r> um*        ( d.#bytes )
;

0 [if]
: send-create-andx  ( path$ access flags -- )
   h# a2 smb{
   words{
   no-andx                ( path$ access flags )
   third 1+ 2*  +xw       ( path$ access flags )  \ Byte count for string + terminator
   +xw                    ( path$ access )  \ Create flage
   0 +xw                  ( path$ access )  \ Root FID
   
   --bytes--
   0 +xb                      \ Null share password
   ( path$ ) +unicode$
   " ?????" +xbytes  0 +xb
   }smb  if  true exit  then
   XXX
;
[then]

: $interpose  ( arg$ pkgname$ -- okay? )
   find-package  if  package-interpose true  else  2drop false  then
;

: allocate-buffers  ( -- )
   my-max-buf alloc-mem to session-buf
;
: free-buffers  ( -- )
   session-buf my-max-buf free-mem
   account$    dup  if  free-mem  else  2drop  then
   challenge$  dup  if  free-mem  else  2drop  then
;

: open  ( -- okay? )
   my-args dup 0=  if  2drop true exit  then       ( arg$ )
   allocate-buffers                                ( arg$ )

   parse-server parse-share parse-pathname to tail$
   server$ set-server
   d# 139 " connect" $call-parent  0=  if  false exit  then
   " OFW " " *SMBSERVER " start-session if  false exit  then
   negotiate      if  free-buffers  false exit  then   ( )
   password$ set-password  compute-password            ( )
   session-setup  if  free-buffers  false exit  then   ( )
   share$ server$  " \\\\%s\\%s" sprintf               ( server+share$ )
   tree-connect   if  free-buffers  false exit  then   ( )

   \ If we just opened the share without a path, return success now
   pathname$ nip  0=  if             ( )
      " \" to pathname$              ( )
      true exit
   then                              ( )

   \ Otherwise determine if the path refers to a directory or a file
   pathname$ $getattr  if            ( )
      ." Bad CIFS pathname" cr       ( )
      free-buffers  false exit
   then                              ( attr )

   \ If the 10 bit is set it's a directory, so we just return success
   h# 10 and  if  true exit  then    ( )

   \ It's a file, so open it - first try to open read/write.
   pathname$ 2 open-file  if         ( )
      \ Failing that, try to open read-only            
      pathname$ 0 open-file  if      ( )
         free-buffers  false exit
      then                           ( )
   then                              ( )

   \ If any arguments remain, assume we are dealing with a ZIP
   \ archive and interpose the ZIP handler 
   tail$  dup if                     ( tail$ )
      " zip-file-system" $interpose  ( okay? )
   else                              ( tail$ )
      2drop true                     ( okay? )
   then                              ( okay? )
;
: close  ( -- )
   fid  if  close-file drop  then
   tree-disconnect drop
   free-buffers
;

: dma-alloc  ( #bytes -- adr )  alloc-mem  ;
: dma-free  ( adr #bytes -- )  free-mem  ;

: load  ( adr -- len )  size drop  read  ;

\ LICENSE_BEGIN
\ Copyright (c) 2009 FirmWorks
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
