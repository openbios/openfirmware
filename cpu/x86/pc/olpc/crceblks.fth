\needs $crc  fload ../../../../../forth/lib/crc32.fth

h# 20000 constant /eblock
/eblock buffer: file-buf
: crc-eblocks  ( in-file out-file -- )
   hex
   reading writing

   begin
      file-buf /eblock ifd @ fgets  /eblock =
   while
      file-buf /eblock $crc   ( crc )
      <# u# u# u# u# u# u# u# u# u#> ofd @ fputs  fcr
   repeat
   ifd @ fclose
   ofd @ fclose
;

0 value fileih
0 value crc-ih
h# 20 buffer: line-buf
: verify-img  ( "crc-devspec" "img-devspec" -- )
   hex
   reading  ifd @ to fileih
   fileih 0=  if  fileih fclose  true abort" Can't open file"  then
   reading  ifd @ to crc-ih
   crc-ih 0=  if  crc-ih fclose  true abort" Can't open file"  then

   cr ." Verifing..." cr

   0
   begin
      line-buf 9  crc-ih fgets                  ( len )
      dup 1 8 between  abort" Short CRC line"   ( len )
   0> while
      (cr dup .  1+
      line-buf 8 $number  abort" Bad number in CRC file"   ( crc )

      file-buf /eblock  fileih fgets                       ( crc len )
      /eblock <>  abort" Short img file"                   ( crc )

      file-buf /eblock  $crc                               ( crc actual-crc )
      2dup <>  if
         cr ." CRC miscompare - expected " swap . ." got " . cr
      else
         2drop
      then
   repeat
   drop
   fileih fclose
   crc-ih fclose
;
