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
d# 8 constant max#partitions

: partition-map-page#  ( -- page# )
[ifdef] notdef
   bbt1  if
      bbt1  bbt0  if  bbt0 min  then           ( bbtn )
   else                                        ( )
      bbt0 dup 0= abort" No Bad Block Table"   ( bbt0 )
   then                                        ( last-bbt-page# )
   begin  pages/eblock - dup  while            ( part-page# )
      dup block-bad?  0=  if  exit  then       ( part-page# )
   repeat
[else]
   h# 10 pages/eblock *  0  do
      i block-bad? 0=  if  i unloop exit  then
   pages/eblock +loop
[then]

   true abort" No place for partition map"
;

: (#partitions)  ( adr -- n )
   0 swap                                          ( seen adr )
   max#partitions  0  ?do                          ( seen adr )
      dup i /partition-entry * +                   ( seen adr padr )
      dup w@ h# ffff =  if                         ( seen adr padr )
         2drop  if  i  else  -1  then              ( n )
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
   part-buf  partition-map-page#
   partition-start >r  0 to partition-start
   read-page
   r> to partition-start
   if  true exit  then
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

   \ Partition 1 (the FIS directory entry) begins at offset 0
   1- /partition-entry *  part-buf +             ( adr )
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
   /partition-entry *                            ( name$ len )
   part-buf swap  bounds  ?do                    ( name$ )
      2dup  i d# 16 ncstr  $=  if                ( name$ )
         2drop                                   ( )
         i d# 16 + l@ /page / to partition-start ( )
         i d# 24 + l@ /page / to partition-size  ( )
         i part-buf - /partition-entry / 1+ to partition#
         start-scan
         false  unloop exit
      then                                       ( name$ )
   /partition-entry +loop                        ( name$ )
   2drop true
;
