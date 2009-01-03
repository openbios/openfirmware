purpose: load iSCSI package
\ See license at end of file

devalias iscsi tcp//iscsi

"                                 "  d# 32 config-string iscsi-user
"                                 "  d# 32 config-string iscsi-password

\ true instance value debug?
\ false instance value verbose?
false value debug?
false value verbose?

fload ${BP}/ofw/inet/iscsi/low.fth
fload ${BP}/ofw/inet/iscsi/buffers.fth

\ debug.fth may be commented out to save space
fload ${BP}/ofw/inet/iscsi/debug.fth

fload ${BP}/ofw/inet/iscsi/keys.fth
fload ${BP}/ofw/inet/random.fth
fload ${BP}/ofw/ppp/md5.fth
fload ${BP}/ofw/inet/iscsi/ipackets.fth
fload ${BP}/ofw/inet/iscsi/opackets.fth
fload ${BP}/ofw/inet/iscsi/methods.fth
fload ${BP}/ofw/inet/iscsi/scsi.fth

fload ${BP}/dev/scsi/hacom.fth

support-package: disk
fload ${BP}/dev/scsi/scsidisk.fth
end-support-package

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
