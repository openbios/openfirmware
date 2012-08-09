: sha1     ( data$ -- hash$ )  load-crypto throw  " sha1"   crypto-hash  ;
: sha-256  ( data$ -- hash$ )  load-crypto throw  " sha256" crypto-hash  ;
: md5      ( data$ -- hash$ )  load-crypto throw  " md5"    crypto-hash  ;

: convert-crypto-args  ( data$n..data$1 n -- 0 data$n..data$1 )
   \ signature-bad? wants the end of data to be marked by a 0 length
   \ so we move the n data strings to the return stack, push a 0,
   \ then move the strings back.  We can't use do..loop because it
   \ interferes with the return stack.
   dup                ( data$n..data$1 n rem )
   begin  dup  while  ( data$n..data$1 n rem )
      2swap 2>r       ( data$n..data$m n rem  r: data$ .. )
      1-              ( data$n..data$m n rem' r: data$ .. )
   repeat             (                n 0    r: data$ .. )
   drop               (                n      r: data$ .. )

   0 swap             ( 0              n      r: data$ .. )
   begin  dup  while  (                rem    r: data$ .. )
      2r> rot         ( 0 data$n ..    rem    r: data$ .. )
      1-              ( 0 data$n ..    rem'   r: data$ .. )
   repeat             ( 0 data$n..     0      r: data$ .. )
   drop               ( 0 data$n..data$1 )
;   

d# 128 buffer: hashbuf
: hash-n  ( data$n..data$1 n hashname$ -- result$ )
   load-crypto throw
   2>r                  ( data$n..data$1 n    r: hashname$ )

   convert-crypto-args  ( 0 data$n..data$1    r: hashname$ )

   \ The 0 above hashlen tells the crypto function to perform the hash
   \ only, without signature checking, returning the length of the
   \ hash result in hashlen.
   hashbuf d# 128  hashlen 0  2r>   ( 0 data$.. sig$ key$ hashname$ )

   signature-bad?  h# fffff and  abort" Hash failed"   ( )
   hashbuf hashlen @
;

\ For use by hmacsha1 in the wifi supplicant package
d# 20 constant /sha1-digest
alias sha1-digest hashbuf

: sha1-n  ( data$n..data$1 n -- digest$ )  " sha1" hash-n  ;
