\ See license at end of file
purpose: Encapsulate memory images in dropin-driver format

\ Examples:
\ $read-file  ( filename$ -- adr len )  Reads file in allocated memory
\ $file-size  ( filename$ -- len )  Returns length of named file
\ sys-deflate  ( in-adr in-len out-adr out-maxlen -- out-actual-len )
\       Deflates the memory image in-adr,len into the memory region
\       at out-adr,maxlen.  Returns the actual length of the deflated image.
\       The storage must be managed (e.g. allocated and freed) by the
\       caller.  If the deflated image will not fit in out-maxlen bytes,
\       at most out-maxlen bytes is written into the out buffer, and
\       the return value out-actual-len is zero.
\ $deflate  ( in-adr in-len -- out-adr out-len )
\       Allocates in-len bytes of storage and deflates the memory image
\       in-adr,in-len into that storage, returning the storage address
\       out-adr and the length of the deflated image out-len.  After you
\       are through with the deflated image, you should free out-adr for
\       in-len bytes.  This could fail (returning out-len=0) if you have
\       a pathological input image that gets larger when zipped.
\ write-dropin  ( adr len expanded-len name$ -- )
\	Adds memory image to current output file as a dropin
\ write-deflated-dropin  ( adr len name$ -- )
\	Adds memory image to current output file as a deflated dropin
\ $add-file  ( filename$ -- )  Adds dropin-format file to current output file
\ $add-dropin  ( filename$ di-name$ -- )
\	Adds image file contents to current output file as a dropin
\ $add-deflated-dropin  ( filename$ di-name$ -- )
\	Adds image file contents to current output file as a deflated dropin
\ $show-dropins  ( filename$ -- )
\	Lists the dropins contained within a file (filename on stack)
\ show-dropins  ( "filename" -- )
\	Lists the dropins contained within a file (filename on command line)
\ extract-dropins  ( "filename" -- )
\       This is a tool for modifying ROM images without recompiling from
\       source code.  It splits a ROM image file into separate files,
\       each containing a dropin module, and creates a ".bth" file with
\       which the builder will reconstruct the original image from those
\       files.  You can edit the ".bth" file to add new dropin modules to
\       the reconstructed image, remove old modules, rearrange the order, etc.
\
\       You can also reconstruct the image without using the builder;
\       simply concatenate (e.g. with Unix "cat") the extracted files
\       in the desired order.
\
\       The details are as follows:
\
\       Given the name of an image file containing a series of dropin
\       modules, extract each dropin into a separate file and create an
\       "xBASENAME.bth" file that will reconstruct a replica of the original
\       image file from those extracted files.  "BASENAME" is the name of
\       the image file minus the final extension.  The extracted dropin
\       module files are named "XNN.DINAME.di" where NN is a two-digit
\       sequence number and "DINAME" is the name of dropin in the input
\       image.  NN is necessary because multiple dropins can have the same
\       name.  Any bytes at the beginning of the input image that are not
\       in dropin format are extracted to "X00.resetvec.img", and any such
\       bytes at the end are extracted "XNN.tail.img".  Later execution of
\       "build xBASENAME" will reconstruct the original image file with an
\       "x" prepended to its name.

\ To create a dropin image file named "test.di" from a memory image:
\   writing test.di
\      origin here over -  0  " fw.dic"  write-dropin
\      ... other similar commands to write other images ...
\   ofd @ fclose
\
\ To create a dropin named "test.di" containing several dropin images:
\   writing test.di
\      " startup.img" $read-file  0  " startup"   write-dropin
\      " fw.dic"      $read-file  0  " firmware"  write-dropin
\   ofd @ fclose
\
\ Command line version of a common operation:
\   make-dropin test.di test.img test
\   make-deflated-dropin test.di test.img test

\needs push-decimal  : push-decimal  r> base @ >r >r  decimal  ;
\needs push-hex      : push-hex      r> base @ >r >r  hex      ;
\needs pop-base      : pop-base      r> r> base ! >r  ;
\needs (.dropins)    fload ${BP}/ofw/core/showdi.fth

: sys-deflate  ( in-adr,len out-adr,len -- actual-len )
   d# 188 syscall  4drop  retval
;
: $deflate  ( in-adr,len -- out-adr,len )
   dup alloc-mem              ( in-adr,len out-adr )
   dup >r over  sys-deflate   ( out-len r: out-adr )
   r> swap
;

warning @ warning off
: $read-file  ( filename$ -- adr len )
   $read-open
   ifd @ fsize              ( len )
   dup alloc-mem swap       ( adr len )
   2dup ifd @ fgets         ( adr len actual )
   over <> if               ( adr len )
      ifd @ fclose          ( adr len )
      free-mem  true abort" Can't read file"
   then                     ( adr len )
   ifd @ fclose             ( adr len )
;
: $add-file  ( filename$ -- )  $read-file  2dup  ofd @ fputs  free-mem  ;
: $copy  ( src-filename$ dst-filename$ -- )
   $new-file  $add-file  ofd @ fclose
;
warning !

: $file-size  ( filename$ -- len )
   $read-open
   ifd @ fsize              ( len )
   ifd @ fclose             ( len )
;
: putlong  ( n -- )  lbsplit  4 0 do  ofd @ fputc  loop  ;
: write-dropin  ( adr len expanded-len name-str -- )
   2>r >r                                          ( adr len )
   " OBMD" ofd @ fputs                             ( adr len )
   dup putlong                                     ( adr len )
   2dup 0 -rot bounds  ?do  i c@ +  loop  putlong  ( adr len )
   r> putlong                                      ( adr len )
   2r>  d# 16 min  tuck  ofd @ fputs               ( adr len name-len )
   d# 16 swap  ?do  0 ofd @ fputc  loop            ( adr len )
   tuck  ofd @ fputs                               ( len )

   \ Pad out to a 4-byte boundary
   dup 4 round-up swap  ?do  1 ofd @ fputc  loop   ( )
;
: write-deflated-dropin  ( adr len name-str -- )
   2>r  tuck $deflate           ( in-len out-adr,len r: name$ )
   \ XXX we should check for out-len=0 and if so, make a non-deflated dropin
   rot 3dup  2r>  write-dropin  ( out-adr,len in-len )
   nip free-mem
;
: $add-dropin  ( filename$ di-name$ -- )
   2>r $read-file               ( adr len )  ( r: di-name$ )
   2dup 0 2r> write-dropin      ( adr len )
   free-mem
;
: $add-deflated-dropin  ( filename$ di-name$ -- )
   2>r $read-file                   ( adr len )  ( r: di-name$ )
   2dup 2r> write-deflated-dropin   ( adr len )
   free-mem
;
: make-dropin  ( "out-file" "in-file" "dropin-name" -- )
   writing
   safe-parse-word  safe-parse-word  $add-dropin
   ofd @ fclose
;
: make-deflated-dropin  ( "out-file" "in-file" "dropin-name" -- )
   writing
   safe-parse-word  safe-parse-word  $add-deflated-dropin
   ofd @ fclose
;

: $show-dropins  ( filename$ -- )
   $read-file  2dup 2>r  (.dropins)  2r> free-mem
;
: show-dropins  ( "filename" -- )  safe-parse-word $show-dropins  ;

false value inclusion-mode?
warning @ warning off
: fload  ( "name" -- )
   inclusion-mode?  if  safe-parse-word  $file,  exit  then
   fload
;
warning !

0 0 value inclusion
: start-inclusion  ( -- )
   here 0  to inclusion
   true to inclusion-mode?
;
: end-inclusion  ( -- )
   inclusion drop  here  over -   to inclusion
   false to inclusion-mode?
;

\needs right-split-string fload ${BP}/forth/lib/parses1.fth
\needs 2nip  : 2nip  ( d1 d2 -- d2 )  2swap 2drop  ;


0 value input-name
0 value base-name
0 value dropin#
d# 128 buffer: new-name
d# 128 buffer: log-name


0 value bth

: outs  ( adr len -- )  bth fputs  ;
: outl  ( adr len -- )  outs  linefeed bth fputc  ;

: write-bth-line  ( name$ -- )  "    "" " outs  outs " ""  $add-file"  outl  ;

\ Start string construction
: $0  ( buffer -- )  0 over c!  count  ;
: $+  ( $2 $1 -- $1+$2 )  rot drop  rot 1- >r  r@ $cat  r> count  ;

: make-file  ( diname$ ext$ -- )
   push-decimal
   2swap                       ( ext$ diname$ name$ )
   new-name $0                 ( ext$ diname$ name$ )
   " X" $+                     ( ext$ diname$ name$ )
   dropin# <# u# u# u#>  $+    ( ext$ diname$ name$ )
   " ."  $+                    ( ext$ diname$ name$ )
   2swap $+                    ( ext$ name$ )
   2dup log-name place         ( ext$ name$ )
   2swap $+                    ( name$ )
   2dup $new-file              ( name$ )
   write-bth-line              ( )
   dropin# 1+ to dropin#       ( )
   " .log" log-name $cat       ( )
   pop-base
;

: $preserve  ( adr len -- pstr )  dup 2+ alloc-mem  pack  ;

: file\dir  ( path$ -- file$ dir )
   [char] / right-split-string  dup 0=  if    ( path$ null$ )
      2drop                                   ( path$ )
      [char] \ right-split-string             ( file$ dir$ )
   then                                       ( file$ dir$ )
;
: file\ext  ( path$ -- file$ ext$ )
   [char] . right-split-string                ( tail$ head$|null$ )
   dup  if  1- 2swap swap 1- swap 1+  then    ( file$ ext$ )
;
: get-base-name  ( adr len -- )
   file\dir 2drop
   file\ext 2drop
   $preserve to base-name  ( )          
;

: write-bytes  ( adr len -- )
   ofd @ fputs  ofd @ fclose
   log-name count delete-file drop
;
: write-image  ( adr len name$ ext$ -- )
   " .img" make-file        ( adr len name$ )
   write-bytes               ( name$ )
;

: >di-name$  ( adr -- name$ )
   d# 16 +    \ Name field address
   \ Find the first null within 16 characters
   d# 16 0  do
      dup i + c@  0=  if  i unloop exit  then
   loop
   d# 16
;

: bth-name  ( ext$ -- name$ )
   new-name $0  " x" $+  base-name count  $+  ( ext$ ) 2swap $+
;
: delete-bth-log  ( -- )  " .log" bth-name delete-file drop  ;

: write-bth-header  ( name$ -- )
   \ Make the ".bth" output file
   " .bth" bth-name $new-file  ofd @ to bth

   " purpose: Regenerate " outs  input-name count outs
   "  from extracted dropins" outl
   " " outl
   " command: &builder &this" outl
   " build-now" outl
   " " outl
   " writing x" outs input-name count file\dir 2drop  outl
;

: extract-dropins  ( "filename" -- )
   \ XXX this has a memory leak; the memory allocated by $read-file
   \ is not freed.  Oh well.

   safe-parse-word 2dup $preserve to input-name   ( filename$ )
   get-base-name                              ( )

   0 to dropin#

   write-bth-header

   input-name count $read-file        ( adr len )

   \ Handle a possible initial piece that's not in dropin format
   over swap                          ( adr adr len )
   find-first-dropin                  ( adr adr' len' )
   -rot  2dup <>  if                  ( len' adr adr' )
      2dup over -                     ( len' adr adr' adr len1 )
      " resetvec"  write-image        ( len' adr adr' )
   then                               ( len' adr adr' )
   nip swap                           ( adr' len' )

   begin  2dup  dropin?  while        ( adr len )
      over >di-name$ " .di" make-file ( adr len )
      over dup >di-extent             ( adr len adr len' )
      tuck write-bytes                ( adr len len' )
      /string
   repeat                             ( adr len )

   dup  if                            ( adr len )
      " tail" write-image             ( )
   else                               ( adr len )
      2drop                           ( )
   then                               ( )

   " ofd @ fclose" outl
   bth fclose
   delete-bth-log
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
