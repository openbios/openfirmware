0 value buf
: get-file  \ name  ( -- )
   reading
   ifd @ fsize  alloc-mem  to buf
   buf ifd @ fsize  ifd @ fgets  ." Read " . ." bytes" cr
   ifd @ fclose
;
