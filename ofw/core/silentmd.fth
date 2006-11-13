purpose: Silent mode, in which most messages are suppressed

headers
false config-flag  silent-mode?

: (silent-mode? ( -- flag )  diagnostic-mode?  0=  silent-mode?  and  ;

: silent-type     ( adr,len -- )  (silent-mode?  if  2drop  else  type  then  ;
: silent-cr       ( -- )          (silent-mode? 0=  if  cr  then  ;
: silent-.d       ( n -- )        (silent-mode?  if  drop  else  .d  then  ;
: silent-type-cr  ( adr,len -- )  silent-type silent-cr  ;
headers
