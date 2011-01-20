purpose: Emulate the Linux md5sum command

\needs $md5digest1 fload ${BP}/ofw/ppp/md5.fth

: $md5sum-file  ( prefix$ filename$ -- )
   \ Read file into memory and compute its MD5 hash
   2dup $read-file         ( prefix$ filename$ adr len )
   2dup $md5digest1        ( prefix$ filename$ adr len md5$ )
   2swap free-mem          ( prefix$ filename$ md5$ )

   \ Write the hash and the filename in the same format as
   \ the output of the Linux "md5sum" command.  prefix$ should
   \ be " *" to match the output of "md5sum -b" and "  "
   \ to match the output of "md5sum" without -b.

   \ Output MD5 in lower case ASCII hex
   push-hex                ( prefix$ filename$ md5$ )
   bounds  ?do             ( prefix$ filename$ )
      i c@  <# u# u# u#> type
   loop                    ( prefix$ filename$ )
   pop-base                ( prefix$ filename$ )

   \ ... followed by "  filename" or " *filename"
   ."  "                   ( prefix$ filename$ )
   2swap type              ( filename$ )
   type                    ( )
   cr
;
