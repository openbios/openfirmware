\ See license at end of file
purpose: Load file for TCP extensions

create ip-redirector

[ifdef] ip-redirector
fload ${BP}/ofw/inet/ippkg.fth
devalias ip   //ip
[else]
devalias ip   net//obp-tftp:last
[then]

devalias tcp  ip//tcp
devalias http tcp//http
devalias httpd tcp//httpd:verbose
devalias nfs  ip//nfs

fload ${BP}/ofw/inet/ping.fth
fload ${BP}/ofw/inet/tcpapp.fth
fload ${BP}/ofw/inet/finger.fth
fload ${BP}/ofw/inet/telnet.fth
fload ${BP}/ofw/inet/loadmail.fth
fload ${BP}/ofw/inet/telnetd.fth
fload ${BP}/ofw/inet/rdc.fth

also forth definitions
" "  d# 64  config-string  http-proxy
previous definitions

fload ${BP}/ofw/inet/httpd.fth

[ifdef] resident-packages
support-package: tcp
   fload ${BP}/ofw/inet/tcp.fth
end-support-package
[then]
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
