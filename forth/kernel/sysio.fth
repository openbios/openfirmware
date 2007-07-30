\ See license at end of file
purpose: System I/O interfaces

\ From sysdisk.fth

\ File I/O interface using the C wrapper program
headerless
decimal

\ Closes an open file, freeing its descriptor for reuse.

: _fclose  ( file# -- )
   bfbase @  bflimit @ over -  free-mem   \ Hack!  Hack!
   16 syscall  drop
;

\ Writes "count" bytes from the buffer at address "adr" to a file.
\ Returns the number of bytes actually written.

: _fwrite  ( adr #bytes file# -- #written )
   >r swap r>  24 syscall 3drop retval  error?  if  drop 0  then  ( #written)
;

\ Reads at most "count" bytes into the buffer at address "adr" from a file.
\ Returns the number of bytes actually read.

: _fread  ( adr #bytes file# -- #read )
   >r swap r>  20 syscall 3drop retval  error? abort" _fread failed" ( #read )
;

\ Used by _fseek, _ftell, and _fsize

: _lseek  ( whence l.byte# file# -- l.byte# error? )
   40 syscall drop ldrop drop retval error?
;

\ Positions to byte number "l.byte#" in a file

: _fseek  ( l.byte# file# -- )
   0 -rot  _lseek  abort" _fseek failed" drop
;
: _dfseek  ( d.byte# file# -- )
   swap abort" _dfseek argument too large"  _fseek
;

\ Returns the current position "l.current-position" within a file

: _ftell  ( file# -- l.byte# )  1 0 rot  _lseek  abort" _ftell failed"  ;
: _dftell  ( file# -- d.byte# )  _ftell 0  ;

\ Returns the current size "l.size" of a file

: _fsize  ( file# -- l.size )
   \ remember the current position
   >r  r@ _ftell    ( l.position )

   \ seek to end of file to find out where the eof is
   2  0 r@ _lseek  abort" _fsize failed"  ( l.pos l.size )

   \ return to the original position
   lswap r> _fseek  ( l.size )
;
: _dfsize  ( file# -- d.size )  _fsize 0  ;

\ Protection to be assigned to newly-created files
\ Defaults to public read permission, owner and group write permission.

variable file-protection
-1 is file-protection  \ Use system default until overridden

\ Prepares a file for later access.  Name is the pathname of the file
\ and mode is the mode (0 read, 1 write, 2 modify).  If the operation
\ succeeds, returns the addresses of routines to perform I/O on the
\ open file and true.  If the operation fails, returns false.

: sys_fopen
   ( name mode -- [ fid mode sizeop alignop closeop writeop readop ] okay? )
   \ remove any high mode bits, such as the Forth "bin" and "create" bits
   \ The wrapper doesn't know about those bits, and the underlying OS may
   \ misbehave if they are present.
   h# b and                                  ( name mode' )

   >r r@ swap cstr file-protection @ -rot    ( prot mode name )
   over  8 and  if                           ( prot mode name )
      nip 12  syscall 2drop  retval          ( fid )
   else                                      ( prot mode name )
      8  syscall 3drop  retval               ( fid )
   then                                      ( fid )
   error?  if  r> drop drop false  exit  then   ( fid )
   r@   ['] _dfsize   ['] _dfalign   ['] _fclose   ['] _dfseek
   r@ read  =  if  ['] nullwrite  else  ['] _fwrite  then
   r> write =  if  ['] nullread   else  ['] _fread   then
   true
;

\ Removes the named file from its directory.

headers
: delete-file  ( name$ -- ior )  $cstr 44 syscall  drop retval  ;

headerless
: sys_newline  ( -- adr )  112 syscall  retval  ;

: install-disk-io  ( -- )
   ['] sys_newline is newline-pstring
   ['] sys_fopen   is do-fopen
;

headers
\ Line terminators for various operating systems
create lf-pstr    1 c, linefeed c,               \ Unix
create cr-pstr    1 c, carret   c,               \ Macintosh, OS-9
create crlf-pstr  2 c, carret   c,  linefeed c,  \ DOS

\ From syskey.fth

\ Console I/O using the C wrapper program

headerless
decimal

: $sh  ( adr len -- )  $cstr d# 88 syscall drop  ;

: sys-emit   ( c -- )   4 syscall drop  ;	\ Outputs a character
: sys-key    ( -- c )   0 syscall retval  ;	\ Inputs a character
: sys-(key?  ( -- f )  32 syscall retval  ;	\ Is a character waiting?
: sys-cr     ( -- )   108 syscall  #out off  1 #line +!  ;  \ Go to next line

\ Is the input stream coming from a keyboard?

: sys-interactive?  ( -- f )  48 syscall retval  0=  ;

headers
\ Reads at most "len" characters into memory starting at "adr".
\ Performs keyboard editing (erase character, erase line, etc).
\ The operation terminates when either a "return" is typed or "len"
\ characters have been read.
\ The operating system does the line editing until we load the line editor

: sys-accept  ( adr len -- actual )
   56 syscall 2drop retval   #out off  1 #line +!
;
headerless

\ Outputs "len" characters from memory starting at "adr"

: sys-type  ( adr len -- )  52 syscall  2drop  ;

\ Returns to the OS

: sys-bye         ( -- )  0 36 syscall  ;
: sys-error-exit  ( -- )  1 36 syscall  ;

\ Memory allocation

: sys-alloc-mem  (s #bytes -- adr )   104 syscall  drop  retval  ;
: sys-free-mem  (s adr #bytes -- )  128 syscall  2drop  ;
: sys-resize  (s adr #bytes -- )  184 syscall  2drop  retval  dup 0=  ;

\ Cache flushing - needed for copyback data caches (e.g. 68040)

: sys-sync-cache  ( adr len -- )  swap 116 syscall 2drop  ;

: sys-$getenv  ( adr len -- true | adr' len' false )
   $cstr d# 84 syscall drop retval  dup  if  cscount false  else  drop true  then
;

: install-wrapper-alloc  ( -- )
   \ Don't use "is" in case a relocation map needs to be allocated first
   ['] sys-alloc-mem    ['] alloc-mem >body >user token!
   ['] sys-free-mem     ['] free-mem  >body >user token!
   ['] sys-resize       ['] resize    >body >user token!
;
: install-wrapper-key  ( -- )
   ['] sys-cr            is cr
   ['] sys-type          is (type
   ['] sys-emit          is (emit
   ['] sys-key           is (key
   ['] sys-(key?         is key?
   ['] sys-bye           is bye
   ['] sys-error-exit    is error-exit
   ['] sys-accept        is accept
   ['] sys-interactive?  is (interactive?
   ['] (key              is key   \ Don't poll I/O under the OS

   ['] sys-sync-cache    is sync-cache
;
: install-wrapper-io  ( -- )
   install-wrapper-alloc
   \ init-relocation goes here, for versions that need it
   install-wrapper-key
   ['] sys-$getenv is $getenv
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
