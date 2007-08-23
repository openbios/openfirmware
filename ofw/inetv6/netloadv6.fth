\ See license at end of file
purpose: Network loading using TFTP/IPv6.

\ Network loading using TFTP.  Loads either a named file using the "dload"
\ command, or the default tftpboot file whose name is constructed from
\ the Internet address (derived from the Neighbor Discovery)
\ and the CPU architecture type.

[ifndef] include-ipv4
partial-headers
d# 128 buffer: file-name-buf
d# 256 buffer: 'root-path
d#  32 buffer: tmpname
false instance value bootp-only?
[then]

: (.ipv6)  ( buf -- adr len )
   push-hex
   <#  dup /ipv6 + 1-  do  i c@ u# u# drop  -1 +loop  0 u#>
   pop-base
;

\ Construct the file name for the second-stage boot program from
\ the IP address and the architecture.
: boot-filenamev6  ( -- adr len )
   file-name-buf cscount dup  if  exit  then   ( adr len )
   2drop
   my-ipv6-addr (.ipv6)  2dup upper            ( adr len )
   tmpname place
   cpu-arch dup  if  " ."  tmpname $cat  tmpname $cat  else  2drop  then
   tmpname count file-name-buf place-cstr  drop
   file-name-buf  cscount
;

[ifndef] include-ipv4
headers

true instance value use-bootp?
false instance value use-last?
false instance value use-nfs?
[then]

headerless

: delim?  ( char -- flag )  dup [char] / =  swap [char] \ =  or  ;

d# 128 buffer: nfs-filename

: nfs-read  ( adr filename$ -- len )
   dup  if                                              ( adr filename$ )
      \ If the name is relative; construct a full pathname
      over c@  delim?  0=  if                           ( adr filename$ )
         \ Prepend root path (if present) or "/"
         'root-path cscount  dup  0=  if                ( adr filename$ root$ )
            2drop  " /"                                 ( adr filename$ root$ )
         then                                           ( adr filename$ )
         nfs-filename pack                              ( adr filename$ 'buf )

         \ Insert a "/" after the root path if necessary
         count + 1- c@  delim?  0=  if                  ( adr filename$ )
            " /" nfs-filename $cat                      ( adr filename$ )
         then                                           ( adr filename$ )

         \ Append the filename
         nfs-filename $cat  nfs-filename count          ( adr filename$' )
      then
   then
   bootnet-debug  if  ." NFS protocol: Reading file: " 2dup type cr  then
   " nfs" $open-package >r r@ 0=  if
      collect(
         ." NFS open failed." cr
         [ifdef] .dhcp-server .dhcp-server  [then]
         ." NFS Server: "  his-ipv6-addr .ipv6  cr
         ." Filename: "  nfs-filename count type  cr
      )collect $abort
   then                           ( adr r: ih )
   " load" r@ $call-method        ( len )
   r> close-package
;

: url?  ( filename$ -- flag )
   " /\" lex  if                            ( rem$ head$ delim )
      drop 2swap 2drop                      ( head$ )
   then                                     ( head$ | filename$ )
   " :" lex  if  5drop true exit  then      ( head$ )
   2drop false                              ( false )
;
char / constant delim

d# 255 instance buffer: pathbuf
: fix-delims  ( adr len -- adr' len' )
   pathbuf pack count 2dup
   bounds  ?do  ( adr len )
      i c@  [char] / =  if  [char] \ i c!  then
   loop
;

: load-url  ( adr filename$ -- len )
   fix-delims
   2dup open-dev >r r@ 0=  if   ( adr filename$ )
      collect(
         ." Can't open " type cr
         [ifdef] .dhcp-server .dhcp-server  [then]
      )collect $abort
   then                            ( adr filename$ r: ih )
   2drop " load" r@ $call-method   ( len )
   r> close-dev
;

: read-file  ( adr filename$ -- len )
   2dup  url?  if  load-url exit  then     ( adr filename$ )

[ifdef] use-dhcp
   use-bootp?  use-server? 0=  and  bootp-only? 0=  and
   abort" The DHCP server did not specify a boot server"
[then]

   use-nfs?  if  nfs-read  else  tftpread  then
;

headers
: next-xid  ( -- id )  rpc-xid 1+ dup to rpc-xid  ;

: load   ( adr -- len )  boot-filenamev6 read-file  ;

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
