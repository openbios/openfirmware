purpose: structures and fields

: struct  ( -- initial-offset )  0  ;

: field  		\ name  ( offset size -- offset' )
   create  over  ,  +
   does> @ +	 	( base -- addr )
;
