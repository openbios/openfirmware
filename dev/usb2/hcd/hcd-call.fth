purpose: Functional interface to HCD driver provided for all usb children
\ See license at end of file

\ All hub drivers must forward all the following methods for their children.
\ A device driver may include only a subset of the methods it needs.

hex
external

: dma-alloc    ( size -- virt )              " dma-alloc" $call-parent    ;
: dma-free     ( virt size -- )              " dma-free" $call-parent     ;

: set-target  ( device -- )  " set-target" $call-parent  ;
: probe-hub-xt  ( -- adr )   " probe-hub-xt" $call-parent  ;
: set-pipe-maxpayload  ( size len -- ) " set-pipe-maxpayload" $call-parent  ;

\ Control pipe operations
: control-get  ( adr len idx value rtype req -- actual usberr )
   " control-get" $call-parent  
;
: control-set  ( adr len idx value rtype req -- usberr )
   " control-set" $call-parent
;
: control-set-nostat  ( adr len idx value rtype req -- usberr )
   " control-set-nostat" $call-parent
;
: get-desc  ( adr len lang didx dtype rtype -- actual usberr )
   " get-desc" $call-parent
;
: get-status  ( adr len intf/endp rtype -- actual usberr )
   " get-status" $call-parent
;
: set-config  ( cfg -- usberr )
   " set-config" $call-parent
;
: set-interface  ( alt intf -- usberr )
   " set-interface" $call-parent
;
: clear-feature  ( intf/endp feature rtype -- usberr )
   " clear-feature" $call-parent
;
: set-feature  ( intf/endp feature rtype -- usberr )
   " set-feature" $call-parent
;
: unstall-pipe  ( pipe -- )  " unstall-pipe" $call-parent  ;

\ Bulk pipe operations
: bulk-in  ( buf len pipe -- actual usberr )
   " bulk-in" $call-parent
;
: bulk-out  ( buf len pipe -- usberr )
   " bulk-out" $call-parent
;
: begin-bulk-in  ( buf len pipe -- )
   " begin-bulk-in" $call-parent
;
: bulk-in?  ( -- actual usberr )
   " bulk-in?" $call-parent
;
: restart-bulk-in  ( -- )
   " restart-bulk-in" $call-parent
;
: end-bulk-in  ( -- )
   " end-bulk-in" $call-parent
;
: set-bulk-in-timeout  ( t -- )
   " set-bulk-in-timeout" $call-parent
;
: bulk-in-ready?  ( -- false | error true | buf len 0 true )
   " bulk-in-ready?" $call-parent
;


\ Interrupt pipe operations
: begin-intr-in  ( buf len pipe interval -- )
   " begin-intr-in" $call-parent
;
: intr-in?  ( -- actual usberr )
   " intr-in?" $call-parent
;
: restart-intr-in  ( -- )
   " restart-intr-in" $call-parent
;
: end-intr-in  ( -- )
   " end-intr-in" $call-parent
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
