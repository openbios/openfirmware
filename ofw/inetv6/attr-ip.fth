\ See license at end of file
purpose: Add properties describing the network to /chosen

headerless
: set-chosen-property  ( adr,len prop,len -- )
   2dup  " /chosen" find-package drop		( ip-adr$ prop$ prop$ phandle )
   dup >r  get-package-property  if		( ip-adr$ prop$ )
      \ Create new property
      r>  0 package(  push-package		( ip-adr$ prop$ )
      2>r encode-bytes  2r> property            ( )
      pop-package )package
   else                                 	( ip-adr$ prop$ xdr,len )
      \ Replace existing property
      2swap 2drop  rot drop  move		(  )
      r> drop
   then
;
[ifdef] notdef
: ?set-chosen-string  ( value$ name$ -- )
   2swap  dup  if                                ( name$ value$ )
      $cstr 1+ 2swap set-chosen-property         ( )
   else                                          ( name$ value$ )
      2drop 2drop                                ( )
   then
;
[then]

: (setup-ip-attr)  (  --  ) 	\ set tftp ip addresses
   my-ip-addr /i        " client-ip"     set-chosen-property
   his-ip-addr /i       " server-ip"     set-chosen-property
   router-ip-addr /i    " gateway-ip"    set-chosen-property
   netmask /i           " netmask-ip"    set-chosen-property
   broadcast-ip-addr /i " broadcast-ip"  set-chosen-property

[ifdef] notdef
   tftp-name            " tftp-file"      ?set-chosen-string
   domain-name          " domain-name"    ?set-chosen-string
   vendor-options       " vendor-options" ?set-chosen-string
   client-name          " client-name"    ?set-chosen-string
[then]

   report-buffer  if
      report-buffer bootp-len encode-bytes " bootp-response"
      set-chosen-property

      report-buffer /bootp-packet free-mem
      0 to report-buffer

      \ h# f0 is offset of the options field with the bootp packet
      bootp-packet  next-option h# f0 +  encode-bytes
      " bootp-request" set-chosen-property
   then
;

['] (setup-ip-attr) is setup-ip-attr
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
