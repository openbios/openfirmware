purpose: Manufacturing data reader

h# fff1.0000 constant mfg-data-top

\ The manufacturing data format is specified by
\ http://wiki.laptop.org/go/Manufacturing_Data

: hibit?  ( adr offset -- adr flag )  over +  c@  h# 80 and  ;

: invalid-tag?  ( adr -- data-adr flag )
   -1 hibit?  if  true exit  then  \ Name char must be 7-bit ASCII
   -2 hibit?  if  true exit  then  \ Name char must be 7-bit ASCII
   -3 hibit?  if  true exit  then  \ Length must be 7 bits
   dup  3 - c@                          ( adr len )
   over 4 - c@                          ( adr len ~len )
   xor  h# ff <>  if  true exit  then   ( adr )
   dup  3 - c@  - 4 -                   ( adr' )
   false
;

: last-mfg-data  ( top-adr -- adr )  begin  invalid-tag?  until  ;

: another-tag?  ( adr -- adr false |  adr' data$ name-adr true )
   dup invalid-tag?  if   ( adr data-adr )
      drop false exit
   then                   ( adr data-adr )
   dup rot                ( data-adr data-adr adr )
   2dup swap - 4 -        ( data-adr data-adr adr data-len )
   swap 2-  true          ( adr' data$ adr )
;

: find-tag  ( name$ -- false | data$ true )
   drop >r  mfg-data-top        ( adr r: name-adr )
   begin  another-tag?  while   ( adr' data$ tname-adr r: name-adr )
      r@ 2 comp 0=  if          ( adr' data$ r: name-adr )
         r> drop  rot drop      ( data$ )
         true exit              ( -- data$ true )
      then                      ( adr' data$ r: name-adr )
      2drop                     ( adr' r: name-adr )
   repeat                       ( adr' r: name-adr )
   r> 2drop false
;

: ?erased  ( adr len -- )
   bounds  ?do  i c@  h# ff <> abort" Not erased"  loop
;

[ifdef] notdef
: put-mfg-data  ( value$ name$ -- )
   drop  over invert here c!  over here 1+ c!  ( value$ name-adr )
   here 2+ 2 move                              ( value$ )
   flash-base /ec +  last-mfg-data             ( value$ mfg-adr )
   over - 4 -                                  ( value$ new-adr )
   2dup swap  ?erased                          ( value$ new-adr )
   flash-base -                                ( value$ offset )
   2>r 2r@                                     ( value$ offset r: len offset )
   spi-start spi-identify                      ( value$ r: len offset )
   write-spi-flash                             ( r: len offset )
   here 4  2r> +  write-spi-flash              ( )
;
[then]
