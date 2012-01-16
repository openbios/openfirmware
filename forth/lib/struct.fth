purpose: structures and fields

: struct  ( -- initial-offset )  0  ;

: field  		\ name  ( offset size -- offset' )
   create  over  ,  +
   does> @ +	 	( base -- addr )
;

\ Create two name fields with the same offset and size
: 2field 		\ name  name  ( offset size -- offset' )
   2dup field drop
   field
;
