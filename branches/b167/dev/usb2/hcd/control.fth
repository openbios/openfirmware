purpose: Common USB control pipe API
\ See license at end of file

hex
headers

: setup-buf-arg  ( -- sbuf sphy slen )  setup-buf setup-buf-phys /dr  ;
: cfg-buf-arg    ( -- cbuf cphy )       cfg-buf cfg-buf-phys  ;

: fill-setup-buf  ( len idx value rtype req -- )
   setup-buf dup /dr  erase			( len idx value rtype req vpcbp )
   tuck >dr-request c!				( len idx value rtype vpcbp )
   tuck >dr-rtype c!				( len idx value vpcbp )
   tuck >dr-value le-w!				( len idx vpcbp )
   tuck >dr-index le-w!				( len vpcbp )
   >dr-len le-w!				( )
   setup-buf setup-buf-phys /dr dma-sync	( )
;

external
: control-get  ( adr len idx value rtype req -- actual usberr )
   4 pick >r					( adr len idx value rtype req )  ( R: len )
   fill-setup-buf				( adr )  ( R: len )
   setup-buf-arg cfg-buf-arg r@  (control-get)	( adr actual usberr )  ( R: len )
   dup  if
      r> drop nip nip 0 swap			( actual usberr )
   else
      -rot r> min tuck cfg-buf -rot move swap	( actual usberr )
   then
;

: control-set  ( adr len idx value rtype req -- usberr )
   5 pick ?dup  if  cfg-buf 6 pick move	 then	( adr len idx value rtype req )
   4 pick >r					( adr )  ( R: len )
   fill-setup-buf drop				( )  ( R: len )
   setup-buf-arg cfg-buf-arg r>  (control-set) 	( usberr )
;

: control-set-nostat  ( adr len idx value rtype req -- usberr )
   5 pick ?dup  if  cfg-buf 6 pick move	 then	( adr len idx value rtype req )
   4 pick >r					( adr )  ( R: len )
   fill-setup-buf drop				( )  ( R: len )
   setup-buf-arg cfg-buf-arg r>  (control-set-nostat)	( usberr )
;

headers

: set-address  ( dev -- usberr )
   \ To get the right characteristics for dev in control-set, then normal
   \ set-my-dev is nooped.  We set my-dev and my-real-dev here instead.
   ['] set-my-dev behavior swap			( xt dev )	\ Save set-my-dev
   ['] noop to set-my-dev			( xt dev )	\ Make it noop
   dup >r					( xt dev )  ( R: dev )
   0 set-real-dev				( xt )  ( R: dev )

   0 0 0 r@ DR_OUT DR_DEVICE or SET_ADDRESS control-set  if
      ." Failed to set device address: " r> u. cr
   else
      r> drop
      d# 10 ms        				\ Let the SET_ADDRESS settle
   then						( xt )

   to set-my-dev				\ Restore set-my-dev
   usb-error
;

external

: get-desc  ( adr len lang didx dtype rtype -- actual usberr )
   -rot bwjoin swap DR_IN or GET_DESCRIPTOR control-get
;

: get-status  ( adr len intf/endp rtype -- actual usberr )
   0 swap DR_IN or GET_STATUS control-get
;

: set-config  ( cfg -- usberr )
   >r 0 0 0 r> DR_DEVICE DR_OUT or SET_CONFIGURATION control-set 
;

: set-interface  ( alt intf -- usberr )
   0 0 2swap DR_INTERFACE DR_OUT or SET_INTERFACE control-set
;

: clear-feature  ( intf/endp feature rtype -- usberr )
   >r 0 0 2swap r> DR_OUT or CLEAR_FEATURE control-set
;
: set-feature  ( intf/endp feature rtype -- usberr )
   >r 0 0 2swap r> DR_OUT or SET_FEATURE control-set
;

: set-pipe-maxpayload  ( size pipe -- )
   target di-maxpayload!
;

headers

: (unstall-pipe)  ( pipe -- )  0 DR_ENDPOINT clear-feature drop  ;
' (unstall-pipe) to unstall-pipe

: get-cfg-desc  ( adr idx -- actual )
   swap >r					( idx )  ( R: adr )
   r@ 9 0 3 pick CONFIGURATION DR_DEVICE get-desc nip 0=  if
      r> dup 2 + le-w@ rot 0 swap CONFIGURATION DR_DEVICE get-desc drop	( actual )
   else
      r> 2drop 0				( actual )
   then
;
: get-dev-desc  ( adr len -- actual )
   0 0 DEVICE DR_DEVICE get-desc drop		( actual )
;
: (get-str-desc)  ( adr len lang idx -- actual )
   STRING DR_DEVICE get-desc drop		( actual )
;
: get-str-desc  ( adr lang idx -- actual )
   3dup 2 -rot (get-str-desc) 0=  if  3drop 0 exit  then	\ Read the length
   >r 2dup r>					( adr lang adr lang idx )
   2 pick c@ -rot  (get-str-desc) 0=  if  2drop 0 exit  then	\ Then read the whole string
   						( adr lang )
   encoded$>ascii$				( )
;

headers

\ LICENSE_BEGIN
\ Copyright (c) 2006 FirmWorks
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
