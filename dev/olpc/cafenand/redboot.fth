purpose: Handler for Redboot FIS FLASH partition maps

[ifdef] notdef
struct fis_image_desc {
    unsigned char name[16];      // Null terminated name
    uint32_t	  flash_base;    // Address within FLASH of image
    uint32_t	  mem_base;      // Address in memory where it executes
    uint32_t	  size;          // Length of image
    uint32_t	  entry_point;   // Execution entry point
    uint32_t	  data_length;   // Length of actual data
    unsigned char _pad[256-(16+7*sizeof(uint32_t))];
    uint32_t	  desc_cksum;    // Checksum over image descriptor
    uint32_t	  file_cksum;    // Checksum over image data
};
[then]

d# 256 constant /partition-entry
d# 7 constant max#partitions  \ Not counting the FIS directory entry

: partition-map-page#  ( -- true | page# false )
   h# 10 pages/eblock *  0  do
      i block-bad? 0=  if  i false unloop exit  then
   pages/eblock +loop
   ." No place for partition map"
   true
;

: (#partitions)  ( adr -- n )
   0 swap                                          ( seen adr )
   max#partitions 1+  0  ?do                       ( seen adr )
      dup i /partition-entry * +                   ( seen adr padr )
      dup w@ h# ffff =  if                         ( seen adr padr )
         2drop  if  i 1-  else  -1  then           ( n )
         unloop exit                               ( n )
      then                                         ( seen adr padr )
      " FIS directory" rot swap comp  0=  if       ( seen adr )
         nip true swap                             ( seen adr )
      then                                         ( seen adr )
   loop                                            ( seen adr )
   drop  if  max#partitions  else  -1  then
;

/page instance buffer: part-buf

0 instance value #partitions
: read-partmap  ( -- )
   part-buf  partition-map-page#  if  drop exit  then   ( buf page# )
   partition-start >r  0 to partition-start             ( buf page# )
   read-page                                            ( error? )
   r> to partition-start                                ( error? )
   if  exit  then                                       ( )
   part-buf (#partitions)  to #partitions
;

: set-partition-number  ( partition# -- error? )
   dup 0=  if                                    ( partition# )
      to partition#
      0 to partition-start  usable-page-limit to partition-size
      false exit
   then                                          ( partition# )

   dup #partitions u>  if  drop true exit  then  ( partition# )

   dup to partition#                             ( partition# )

   \ "Real" partitions are numbered starting at 1
   \ The partition buffer entry at offset 0 is the FIS directory
   /partition-entry *  part-buf +                ( adr )
   dup d# 16 + l@ /page / to partition-start     ( adr )
   d# 24 + l@ /page / to partition-size          ( )
   false
   start-scan
;

\ C string length no longer than maxlen
: ncstr  ( adr maxlen -- adr len )
   2dup  bounds  ?do    ( adr maxlen )
      i c@ 0=  if  drop  i over -  unloop exit  then
   loop                 ( adr maxlen )
;

: $=  ( adr1 len1 adr2 len2 -- flag )
   rot over <>  if  3drop false exit  then  ( adr1 adr2 len2 )
   comp 0=
;

: set-partition-name  ( name$ -- error? )
   #partitions  dup 0<  if  2drop false exit  then  ( name$ #partitions )
   1+  /partition-entry *                        ( name$ part-buf-len )
   part-buf swap  bounds  ?do                    ( name$ )
      2dup  i d# 16 ncstr  $=  if                ( name$ )
         2drop                                   ( )
         i d# 16 + l@ /page / to partition-start ( )
         i d# 24 + l@ /page / to partition-size  ( )
         i part-buf - /partition-entry / to partition#
         start-scan
         false  unloop exit
      then                                       ( name$ )
   /partition-entry +loop                        ( name$ )
   2drop true
;
