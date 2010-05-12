: bits-run  ( adr len pattern -- fail? )
   dup .x  ." pattern ... "
   3dup lfill            ( adr len pattern )
   3dup lskip            ( adr len pattern residue )
   dup  if               ( adr len pattern residue )
      ." FAILED - got "  ( adr len pattern residue )
      nip - +            ( adr' )
      dup l@ .x  ." at " .x  cr   ( )
      true
   else                  ( adr len pattern residue )
      ." passed"  cr     ( adr len pattern residue )
      4drop false
   then
;
: mem-bits-test  ( membase memsize -- fail-status )
   2dup h# aaaaaaaa bits-run  if  true exit  then
   h# 55555555 bits-run
;

code inc-fill  ( adr len -- )
   cx pop  2 # cx shr
   ax pop
   begin
      ax  0 [ax]  mov
      4 [ax]  ax  lea
   loopa
c;

code inc-check  ( adr len -- false | adr data true )
   cx pop  2 # cx shr
   ax pop
   begin
      0 [ax]  bx  mov
      bx ax cmp  <>  if
         ax push  bx push  -1 # push
         next
      then
      4 [ax]  ax  lea
   loopa
   ax ax xor  ax push
c;

: address=data-test  ( membase memsize -- fail-status )
   ." Address=data test ..."
   2dup inc-fill     ( membase memsize )
   inc-check         ( false | adr data true )
   if
      ." FAILED - got " .x ." at " .x cr
      true
   else
      ." passed" cr
      false
   then
;
