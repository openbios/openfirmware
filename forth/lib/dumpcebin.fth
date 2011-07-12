purpose: Show the sections of a WinCE .bin file

h# 60 constant /buf
/buf buffer: secbuf
: +buf  ( offset -- adr )  secbuf +  ;
: sec@  ( offset -- l )  +buf l@  ;

0 value section-len
: .section  ( offset -- offset' )
   ." File offset: " dup 8 u.r
   dup ifd @ fseek   ( offset )
   secbuf d# 12 ifd @ fgets d# 12 <> abort" read failure"
   0 sec@ 0=  if
      ."   Final record: "  4 sec@ 8 u.r  ."   " 8 sec@ 8 u.r cr
      exit
   then

   ."   Start " 0 sec@ 8 u.r  ."   Length " 4 sec@ 8 u.r  ."   Sum " 8 sec@ 8 u.r  cr
   4 sec@ to section-len
   secbuf  h# 60  section-len min  ifd @ fgets drop
   secbuf  h# 60  section-len min  ldump  cr  ( offset )
   d# 12 +  section-len +
;

: (dump-bin)  ( filename$ -- )
   hex
   $read-open
   secbuf h# f ifd @ fgets  h# f <> abort" Signature read failure"
   secbuf  " B000FF"n"  comp  abort" Bad signature"

   ." Load start " 7 sec@ 8 u.r   ."  Total length "  h# b sec@ 8 u.r  cr cr

   h#  f   begin  ifd @ ftell  ifd @ fsize  <  while  ( offset )
      .section              ( offset' )
   repeat                   ( offset )
   drop                     ( )
   ifd @ fclose
;
: dump-bin  ( "filename" -- )
   safe-parse-word  (dump-bin)
;
