purpose: Wrap an OFW image in a WinCE ".bin" file format

h# 100000 constant ofw-load-address
h# 100000 constant ofw-entry-address

: put-long  ( l -- )
   lbsplit  swap 2swap swap   ( hi hmid lmid lo )
   4 0  do  ofd @ fputc  loop
;

: make-bin-file  ( "in-filename" "out-filename" -- )
   reading writing

   " B000FF"n" ofd @ fputs      \ Signature
   ofw-load-address  put-long   \ Lowest load address
   ifd @ fsize  put-long        \ Total size

   ofw-load-address  put-long   \ Section load address - offset h# 0f
   ifd @ fsize  put-long        \ Total size             offset h# 13
   0 put-long                   \ Checksum, will be patched later - offset h# 17

   0                            ( sum )
   begin                        ( sum )
      ifd @ fgetc               ( sum char )
      dup -1 <>                 ( sum char more? )
   while                        ( sum char )
      dup ofd @ fputc           ( sum char )
      +                         ( sum' )
   repeat                       ( sum )

   \ Final record with entry address
   0 put-long                   ( )
   ofw-entry-address put-long   ( )
   0 put-long                   ( )

   h# 17 ofd @ fseek            ( sum )
   put-long                     ( )
   ofd @ fclose                 ( )
;
