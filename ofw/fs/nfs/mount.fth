\ See license at end of file
purpose: NFS mounting (i.e. get a root file handle)

headerless
d# 32 constant /fhandle
0 instance value mount-port#
0 instance value mount-version#
: >dirname-len  ( len -- #rpc-bytes )  4 + 4 round-up  la1+  ;
: do-mount  ( dirname$ proc# -- error? )
   mount-port#  0=  if                  ( dirname$ proc# )
      1 to mount-version#
      d# 100005 1 map-port  if
         d# 100005 3 map-port  if
            " Can't get port# for mount" debug-type
            2drop true exit
         then
         3 to mount-version#
      then
      to mount-port#
   then   
   mount-port# to rpc-port#

   over >dirname-len alloc-rpc       ( dirname$ proc# )

   \       xid   call  RPCv2  program#        version#            procedure#
   rpc-xid +xu  0 +xu  2 +xu  d# 100005 +xu   mount-version# +xu       +xu
   auth-unix auth-null

   ( dirname$ )  +x$                 ( )

   do-rpc                            ( error? )
;
: nfsmount  ( 'fhandle dirname$ -- error? )
   1 do-mount  if                    ( 'fhandle )
      drop true                      ( error? )
   else                              ( 'fhandle )
      -xu  if  drop true  else       ( 'fhandle )
         mount-version#  3 =  if     ( 'fhandle )
            \ The file handle is encoded as a string
            -x$ rot swap move        ( )
	    \ The file handle is followed by a list of
            \ of authorization styles, which we ignore for now.
            \ XXX get auth-styles and do something with them.
         else		\ Mountd versions 1 and 2       ( 'fhandle )
            \ The file handle is encoded as an opaque
            /fhandle -xopaque swap /fhandle move        ( )
         then                                           ( )
         false                                          ( error? )
      then                                              ( error? )
   then                                                 ( error? )
;
: nfsunmount  ( dirname$ -- error? )  3 do-mount  ;
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
