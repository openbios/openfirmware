\ See license at end of file
purpose: Construct a flattened device tree blob for Linux

0 value boot-cpu

8 constant /fdt-align
0 value fdt
0 value fdt-end
0 value fdt-ptr
0 value fdt-strings
0 value fdt-strings-ptr
0 value fdt-strings-end
h# 40000 value /fdt

0 value the-node

: fdt-remaining  ( -- n )  fdt-end fdt-ptr -  ;
: ?fdt-enough  ( n -- )
   
;

: +fdt  ( n -- ptr )
   dup fdt-remaining >  abort" FDT buffer overflow"  ( n )
   fdt-ptr tuck + to fdt-ptr   ( ptr )
;
: fdt-align  ( boundary -- )
   fdt-ptr swap round-up fdt-ptr -  ( n )
   +fdt drop
;
: fdt-c,  ( c -- )  /c +fdt c!  ;
: fdt$,  ( adr len -- )  dup +fdt  ( adr len ptr )  swap move  ( )  ;
: fdt,  ( l -- )  /l +fdt be-l!  ;
: fdt-strings-remaining  ( -- n )  fdt-strings-end fdt-strings-ptr -  ;
: fdt-strings-len  ( -- n )  fdt-strings-ptr fdt-strings -  ;

: fdt-string,  ( adr len -- )
   >r                                            ( adr r: len )
   fdt-strings-ptr r@ move                       ( r: len )
   0 fdt-strings-ptr r@ + c!                     ( r: len )
   fdt-strings-ptr r> +  1+  to fdt-strings-ptr  ( )
;
: >string-offset  ( $ -- offset )
   \ If the string is already in the table, return its offset
   fdt-strings 4 +  begin  dup fdt-strings-ptr u<  while    ( $ adr )
      cscount                                           ( $ adr len )
      4dup $=  if                                       ( $ adr len )
         drop nip nip  fdt-strings -  exit              ( -- offset )
      then                                              ( $ adr )
      + 1+                                              ( $ adr' )
   repeat                                               ( $ adr )

   \ Otherwise add it to the table
   fdt-strings-ptr <> abort" FDT string table error"    ( $ )
   fdt-strings-ptr fdt-strings -  -rot                  ( offset $ )
   fdt-string,                                          ( offset )
;

also client-services
: flatten-path  ( -- )
   the-node phandle>devname       ( adr len )
   fdt$,  0 fdt-c,  4 fdt-align   ( )
;
: (flatten-property)  ( propname$ propvalue$ -- )
   3 fdt,                              ( propname$ propvalue$ )  \ OF_DT_PROP
   dup fdt,                            ( propname$ propvalue$ )  \ Value length
   2swap >string-offset fdt,           ( propvalue$ )            \ Name offset
   fdt$,                               ( )                       \ Value data
   4 fdt-align                         ( )
;
: flatten-property  ( propname$ -- )
   2dup the-node get-package-property  abort" FDT missing property"  ( propname$ propvalue$ )
   (flatten-property)                   ( )
;
variable fdt-phandle
: add-phandle-property  ( -- )
   the-node  fdt-phandle be-l!
   " phandle"  fdt-phandle /l  (flatten-property)
;
: flatten-properties  ( -- )
   " "                                   ( propname$ )
   begin  the-node next-property  while  ( propname$' )
      2dup " name" $=  0=  if            ( propname$' )
         2dup flatten-property           ( propname$' )
      then                               ( propname$' )
   repeat                                ( )
;
: flatten-node  ( phandle -- )  recursive
   to the-node
   1 fdt,      \ OF_DT_BEGIN_NODE

   flatten-path
   add-phandle-property
   flatten-properties   

   the-node child                  ( phandle )
   begin  ?dup  while              ( phandle )
      dup flatten-node             ( phandle )
      peer                         ( phandle' )
   repeat                          ( )

   2 fdt,      \ OF_DT_END_NODE
;

: flatten-device-tree  ( -- adr )
   /fdt alloc-mem /fdt-align round-up to fdt
   fdt /fdt erase
   fdt to fdt-ptr
   fdt /fdt + to fdt-end

   /fdt alloc-mem to fdt-strings
   fdt-strings /fdt erase
   0 fdt-strings l!
   fdt-strings 4 + to fdt-strings-ptr
   fdt-strings /fdt + to fdt-strings-end
   
   h# d00dfeed fdt,  \ 00: magic
   0        fdt,     \ 04: Size, set later
   h# 80    fdt,     \ 08: Offset to structure
   0        fdt,     \ 0c: Offset to strings, set later
   h# 40    fdt,     \ 10: Offset to memory reserve map
   d# 17    fdt,     \ 14: version  
   d# 16    fdt,     \ 18: last compatible version
   boot-cpu fdt,     \ 1c: CPU ID (version 2)
   0        fdt,     \ 20: Strings size (version 3)   
   0        fdt,     \ 24: Reserved for struct size (version 17)

   fdt h# 40 + to fdt-ptr

   \ 40: Reserve map
   0 fdt,            \ 40: initrd-start.high
   0 fdt,            \ 44: initrd-start.low
   0 fdt,            \ 48: initrd-size.high
   0 fdt,            \ 4c: initrd-size.low

   0 fdt,            \ 50: reserve map terminator
   0 fdt,            \ 54: reserve map terminator
   0 fdt,            \ 58: reserve map terminator
   0 fdt,            \ 5c: reserve map terminator

   fdt h# 80 + to fdt-ptr

   \ 80: Structure
   0 peer  flatten-node  
   9 fdt,            \ OF_DT_END

\  fdt-ptr  fdt h# 80 +  -  fdt h# 24 +  be-l!  \ Set struct size
   fdt-strings-len          fdt h# 20 +  be-l!  \ Set strings size

   fdt-ptr /fdt-align round-up  to fdt-ptr
   fdt-ptr fdt -            fdt h# 0c +  be-l!  \ Set strings offset

   \ Copy string into the blob
   fdt-strings fdt-ptr fdt-strings-len move
   fdt-strings /fdt free-mem
   fdt-ptr fdt-strings-len +  to fdt-ptr
   
   fdt-ptr fdt -            fdt h# 04 +  be-l!  \ Set total size

[ifdef] notdef
   \ This is redundant because the Linux kernel reserves the initrd explicitly,
   \ independent of the reserve map (and it reserves the device tree blob too).
   " linux,initrd-start"  get-chosen-int  dup  fdt h# 40 +  be-l!  ( start )
   " linux,initrd-end"    get-chosen-int  swap -                   ( length )
   fdt h# 4c +  be-l!  ( start )
[then]

   fdt
;
previous

\ LICENSE_BEGIN
\ Copyright (c) 2012 FirmWorks
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
