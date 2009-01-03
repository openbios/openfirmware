purpose: iSCSI parameters
\ See license at end of file

decimal

\ these are negotiated between initiator and target as key=value strings
\ each chategory has different behavior: boolean, digest, numeric, text

\ Note: we negotiate the values with the target, but do not implement
\ the functionality in many cases. During negotiation we request that 
\ digests and markers not be used, and expect the target to comply.

\ For numerical values we simply accept values provided by the target.
\ Currently only MaxRecvDataSegmentLength is used.

\ The keys are grouped by behavior.

vocabulary bkeys
vocabulary dkeys
vocabulary nkeys
vocabulary tkeys

\ boolean
also bkeys definitions

variable DataPDUInOrder
variable DataSequenceInOrder
variable ImmediateData
variable InitialR2T
variable IFMarker
variable OFMarker

\ digest
dkeys definitions

variable DataDigest
variable HeaderDigest

\ numeric
nkeys definitions

variable DefaultTime2Wait
variable DefaultTime2Retain
variable ErrorRecoveryLevel
variable FirstBurstLength
variable MaxBurstLength
variable MaxConnections
variable MaxOutstandingR2T
variable MaxRecvDataSegmentLength
variable TargetPortalGroupTag
variable CHAP_A
variable CHAP_I

\ text
tkeys definitions

256 buffer: TargetAddress
256 buffer: TargetAlias
256 buffer: TargetName
256 buffer: InitiatorName
256 buffer: InitiatorAlias
256 buffer: AuthMethod
256 buffer: CHAP_C
256 buffer: CHAP_N
256 buffer: CHAP_R
256 buffer: CHAP_S

previous definitions

: find-key   ( $ -- false | a type )
   ['] nkeys $vfind  if    	( xt )
      execute ['] nkeys exit 	( a t )
   then			    	( $ )
    
   ['] tkeys $vfind  if		( xt )
      execute ['] tkeys exit	( a t )
   then		    		( $ )

   ['] bkeys $vfind  if		( xt )
      execute ['] tkeys exit	( a t )
   then		    		( $ )

   ['] dkeys $vfind  if		( xt )
      execute ['] tkeys exit	( a t )
   then			    	( $ )

   2drop false
;

: default-keys   ( -- )
   [ also bkeys ]
   1 DataPDUInOrder !
   1 DataSequenceInOrder !
   1 ImmediateData !
   0 InitialR2T !
   0 IFMarker !
   0 OFMarker !

   [ dkeys ]
    
   0 DataDigest !
   0 HeaderDigest !
    
   [ nkeys ]
    
   0 DefaultTime2Wait !
   0 DefaultTime2Retain !
   0 ErrorRecoveryLevel !
   65536 FirstBurstLength !
   262144 MaxBurstLength !
   1 MaxConnections !
   1 MaxOutstandingR2T !
   65536 MaxRecvDataSegmentLength !
   \ 0 TargetPortalGroupTag !
   5 CHAP_A !

   [ tkeys ]
    
   0 TargetAddress c!
   0 TargetAlias c!
   0 TargetName c!
   0 CHAP_C c!

   [ previous ]
;

: get-addr   ( $name --a )    find-key 0= abort" key not found"  ;

: get-num    ( $name -- value )
   find-key ['] nkeys <> abort" numeric key not found"		( a )
   @
;
: get-text   ( $name -- $text )
   find-key ['] tkeys <> abort" text key not found"		( a )
   count
;
: get-key   ( $key -- $value )
   ['] nkeys $vfind  if    	( xt )
      execute @ push-decimal (.) pop-base
      exit
   then		    		( $ )
    
   ['] tkeys $vfind  if		( xt )
      execute count exit
   then		    		( $ )

   ['] bkeys $vfind  if		( xt )
      execute  @ if  " Yes"  else  " No"  then
      exit
   then		    		( $ )

   ['] dkeys $vfind  if		( xt )
      execute @ if  " CRC32C"  else  " None"  then
      exit			( a t )
   then		    		( $ )

   2drop " Unknown key"
;
: set-key   ( $value $key -- )
   ['] nkeys $vfind  if	    	( $v xt )
      execute -rot $dnumber if  drop bad-number throw  then
      swap !  exit
   then		    		( $v $k )
    
   ['] tkeys $vfind  if		( $v xt )
      execute place exit
   then		    		( $v $k )

   ['] bkeys $vfind  if		( $v xt )
      execute -rot		( a $v )
      " Yes" $= swap ! exit
   then			    	( $v $k )

   ['] dkeys $vfind  if		( $v xt )
      execute -rot		( a $v )
      " CRC32C" $= swap ! exit
   then		    		( $v $k )

   4drop true abort" Invalid key"
;

: set-text   ( $text $name -- )
   find-key ['] tkeys <>  if
      2drop true abort" text key not found"
   then		  	( $text a )
   place
;
: set-iname   ( -- )
   " iqn.1986-03.com.sun:boot."  (mac-address)  $cat2
   " InitiatorName" set-text
   " openboot" " InitiatorAlias" set-text
;


create $(   char " c, char ( c,
create $)   char ) c,
\ for CHAP
: 2hd   ( a n -- a' )
   swap >r
   dup 4 >> >digit r@ c!
   h# 0f and >digit r@ 1+ c!
   r> 2+
;
: put-hex   ( $number $name -- )
   find-key ['] tkeys <> if   	( $number )
      2drop true abort" text key not found"
   then			  	( $number a )

   dup >r
    
   1+ [char] 0 over c! 1+  [char] x over c! 1+
   -rot bounds ?do		( a' )
      i c@ 2hd
   loop				( a' )
   r@ - r> c!
;

256 buffer: hexbuf
: get-hex   ( $name -- $hex )
   get-addr  dup 1+ 2 " 0x" $= 0=  if	( a )
      drop true abort" invalid hex format"
   then				( a )

   count dup 1 and  if
      2drop true abort" invalid hex format"		\ odd number of digits
   then				( a n )
    
   2 /string  hexbuf -rot bounds ?do		( buf )
     i c@ d# 16 digit 0= abort" bad number"		( buf h )
     4 <<  i 1+ c@ d# 16 digit 0= abort" bad number"	( buf h l )
     + over c! 1+			( buf' )
   2 +loop
   hexbuf tuck -
;


: append-key   ( $name -- )
   2dup get-key	  		( $name $value )
   " =" 2swap $cat3 append0
;


\ handle incoming k=v pairs
256 buffer: keybuf
256 buffer: valbuf
0 value parsely

: update-kev   ( -- )
   debug?  if
      ." set " keybuf count type ." =" valbuf count type cr
   then
   valbuf count  keybuf count set-key
;
: parse-keys   ( a n -- )
   over to parsely
   bounds  ?do
      i c@ [char] = =  if
         parsely  i over - keybuf place
         i 1+ to parsely
      else
         i c@ 0=  if
            parsely i over - valbuf place
            i 1+ to parsely
            update-kev
            parsely c@ 0=  if  unloop exit  then   \ teminate on double null
         then
      then
   loop
   debug?  if  cr  then
;

\ LICENSE_BEGIN
\ Copyright (c) 2009 FirmWorks
\ 
\ Permission is hereby granted, free of charge, to any person obtaining
\ a copy of this software and associated documentation files (the
\ "Software"), to deal in the Software without restriction, including
\ without limitation the rights to use, copy, modify, merge, publish,
\ distribute, sublicense, and/or sell copies of the Software, and to
\ permit persons to whom the Software is furnished to do so, subject to
\ the following conditions:
\ 
\ The above copyright notice and this permission notice shall be
\ included in all copies or substantial portions of the Software.
\ 
\ THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
\ EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
\ MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
\ NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
\ LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
\ OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
\ WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
\
\ LICENSE_END
