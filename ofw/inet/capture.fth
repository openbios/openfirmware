\ See license at end of file
purpose: Capture ethernet packets into PCAP-format trace files
\ PCAP is the file format used by tcpdump and wireshark etc.
\ Spec: http://wiki.wireshark.org/Development/LibpcapFileFormat

\ NOTE: This program does not economise on calls to fputs. should it?

headerless

0 value capture-file
d# 64 value capture-length
0 value #captured

\ Write n-byte integers in host byte order. there's probably a simpler way..
variable buffer
: write32  ( u -- )  buffer !  buffer 4 capture-file fputs  ;
: write16  ( u -- )  buffer w!  buffer 2 capture-file fputs  ;

: snaplen    ( len -- snaplen )  capture-length min  ;
: write-seconds       ( ms -- )  d# 1000 / write32 ;
: write-microseconds  ( ms -- )  d# 1000 mod  d# 1000 *  write32  ;
: write-timestamp  ( -- )  get-msecs  dup write-seconds  write-microseconds  ;

: write-packet  ( adr len -- )
   write-timestamp                 ( adr len )
   dup snaplen write32             ( adr len )
   dup write32                     ( adr len )
   snaplen capture-file fputs      ( )
;

: capture-packet  ( adr len -- adr len )
   2dup write-packet          ( adr len )
   #captured 1+ to #captured  ( adr len )
;

: install-hooks  ( -- )
   ['] capture-packet to send-ethernet-packet-hook
   ['] capture-packet to receive-ethernet-packet-hook
;

: uninstall-hooks  ( -- )
   ['] noop to send-ethernet-packet-hook
   ['] noop to receive-ethernet-packet-hook
;

headers

: stop-capture  ( -- )
   capture-file close-file
   0 to capture-file
   uninstall-hooks
;

: start-capture  ( fileid -- )
   to capture-file
   0 to #captured
   h# a1b2c3d4 write32      \ magic (host byte order)
   2 write16                \ major version
   4 write16                \ minor version
   0 write32                \ gmt offset - ignore
   0 write32                \ timestamp accuracy - ignore
   capture-length write32   \ per-packet capture length
   1 write32                \ data link type (1 = ethernet)
   install-hooks
;

also forth definitions
: capture  ( "file" -- )
   safe-parse-word r/w create-file  abort" couldn't create capture file"
   start-capture
;

: .capture  ( -- )
   capture-file if
      ." Capture enabled: " #captured . ." packet(s) captured." cr
   else
      ." Capture not enabled"
   then
;
previous definitions

\ LICENSE_BEGIN
\ Copyright (c) 2009 Luke Gorrie
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

