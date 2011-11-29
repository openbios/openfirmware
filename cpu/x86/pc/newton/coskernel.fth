
h# 10000 constant /kbuf
0 value kbuf

: alloc-kbuf  ( -- )  /kbuf alloc-mem to kbuf  ;
: free-kbuf  ( -- )  kbuf /kbuf free-mem  0 to kbuf  ;

: get-kparams  ( name$ -- )
   open-dev ?dup  0=  if  exit  then  >r  ( r: ih )
   kbuf /kbuf " read" r@ $call-method     ( r: ih )
   r> close-dev
;

: .keydata  ( adr len -- )
   over  6 cdump       ( adr len )
   ." ... "            ( adr len )
   2dup + 6 - 6 cdump  ( adr len )
   nip  ." (0x" .x ." bytes)" cr   ( )
;
   
: .signature  ( adr -- )
   dup x@ x>u           ( adr offset )
   over +               ( adr sig-adr )
   swap x@ x>u          ( sig-adr sig-len )
   .keydata             ( )
;

string-array algorithm-names
," RSA1024 SHA1"
," RSA1024 SHA256"
," RSA1024 SHA512"
," RSA2048 SHA1"
," RSA2048 SHA256"
," RSA2048 SHA512"
," RSA4096 SHA1"
," RSA4096 SHA256"
," RSA4096 SHA512"
," RSA8192 SHA1"
," RSA8192 SHA256"
," RSA8192 SHA512"
end-string-array

: .key  ( adr -- )
   dup .signature                    ( adr )
   ." Ver " over h# 18 + x@ x>u .x   ( adr )
   h# 10 + x@ x>u algorithm-names count type  ( )
;
