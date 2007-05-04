\ See license at end of file
purpose: Access to I/O ports and physical addresses under Linux

' (key to key

-1 value port-fd
: ?open-port  ( -- )
   port-fd 0<  if
      2 " /dev/port" $cstr 8 syscall 2drop  retval  to port-fd
   then
   port-fd 0< abort" Can't open /dev/port"
;
4 buffer: port-data
: port-seek  ( port# -- )  ?open-port  port-fd _fseek  ;
: port-in  ( port# buf n -- )
   rot port-seek  ( buf n )
   tuck port-fd _fread  <> abort" Can't read port"
;
: port-out  ( buf port# n -- )
   swap port-seek  ( buf n )
   tuck port-fd _fwrite  <> abort" Can't write port"
;

: port-read  ( port# n -- buf )  port-data swap port-in  port-data  ;
: port-write  ( port# n -- )   port-data -rot  port-out  ;

: pc@  ( port# -- byte )  1 port-read c@  ;
: pw@  ( port# -- word )  2 port-read w@  ;
: pl@  ( port# -- long )  4 port-read l@  ;
: pc!  ( byte adr -- )  swap port-data c!  1 port-write  ;
: pw!  ( word adr -- )  swap port-data w!  2 port-write  ;
: pl!  ( long adr -- )  swap port-data l!  4 port-write  ;

-1 value mem-fd
: ?open-mem  ( -- )
   mem-fd 0<  if
      2 " /dev/mem" $cstr 8 syscall 2drop  retval  to mem-fd
   then
   mem-fd 0< abort" Can't open /dev/mem; try being root"
;
4 buffer: mem-data
: mem-seek  ( padr -- )  ?open-mem  mem-fd _fseek  ;
: phys-in  ( padr buf n -- )
   rot mem-seek  ( buf n )
   tuck mem-fd _fread  <> abort" Can't read memory"
;
: phys-out  ( buf padr n -- )
   swap mem-seek  ( buf n )
   tuck mem-fd _fwrite  <> abort" Can't write memory"
;

: mem-read  ( padr n -- buf )  mem-data swap phys-in  mem-data  ;
: mem-write  ( padr n -- )   mem-data -rot  phys-out  ;

: mb@  ( adr -- byte )  1 mem-read c@  ;
: mw@  ( adr -- word )  2 mem-read w@  ;
: ml@  ( adr -- long )  4 mem-read l@  ;
: mb!  ( byte adr -- )  swap mem-data c!  1 mem-write  ;
: mw!  ( word adr -- )  swap mem-data w!  2 mem-write  ;
: ml!  ( long adr -- )  swap mem-data l!  4 mem-write  ;

: mmap  ( phys len -- virt )
   ?open-mem  mem-fd d# 380  syscall  3drop retval
   dup -1 =  abort" mmap failed"
;
: munmap  ( virt len -- )  mem-fd  d# 384  syscall  2drop  ;

-1 value msr-fd
: ?open-msr  ( -- )
   msr-fd 0<  if
      2 " /dev/cpu/0/msr" $cstr 8 syscall 2drop  retval  to msr-fd
   then
   msr-fd 0< abort" Can't open /dev/cpu/0/msr"
;
8 buffer: msr-data
: msr-seek  ( msr# -- )  ?open-msr  msr-fd _fseek  ;

: msr@  ( msr# -- d )
   msr-seek
   msr-data 8 msr-fd _fread  8 <>  abort" Can't read MSR"
   msr-data d@
;
: msr!  ( d msr# -- )
  msr-seek
  msr-data d!
  msr-data 8 msr-fd _fwrite  8 <>  abort" Can't write MSR"
;
: .msr  ( msr# -- )
   msr@         ( d )
   push-hex     ( d )
   <# [char] . hold  # # # # # # # # [char] . hold # # # # # # # # #> type  ( )
   pop-base
;

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
