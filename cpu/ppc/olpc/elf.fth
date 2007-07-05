purpose: Load image handler for ELF (Extended Linker Format)
\ See license at end of file

hex

headerless
: elf?  ( -- flag )  0 +base 4  " "(7f)ELF" $=  ;
: elf-le?  ( -- flag )  5 +base c@  1 =  ;
: elfl@  ( adr -- n )  elf-le?  if   le-l@  else  be-l@  then  ;
: elfw@  ( adr -- w )  elf-le?  if   le-w@  else  be-w@  then  ;

: eh-l@  ( offset -- l )  +base elfl@  ;
: eh-w@  ( offset -- w )  +base elfw@  ;

: +elfl@  ( adr offset -- n )  + elfl@  ;

\ XXX the following code assumes that the value of load-base is such that
\ the copying of program sections to their correct locations does not
\ overwrite portions of other sections that have not yet been copied.

\ One sufficient condition is that the program sections are stored in the
\ ELF file in ascending order of their execution addresses (vaddr fields)
\ and that load-base is large enough that the sections must be moved to
\ lower addresses.

0 value high-water
0 value low-water
: record-extent  ( adr len -- )
   bounds  low-water umin to low-water   high-water umax to high-water 
;   

: prepare-elf-program  ( -- entry-point )
   0  to high-water
   -1 to low-water

   \ Copy all pheaders to allocated memory to protect them from being
   \ overwritten when we copy the programs to their final destinations.

   \ e_entry       e_phentsize      e_phnum  
   h# 18 eh-l@  h# 2a eh-w@ dup  h# 2c eh-w@ *   ( entry phentsize phsize)
   dup alloc-mem  swap                       ( entry phentsize pbbuf phsize )

   \     e_phoff
   2dup  1c eh-l@ +base   -rot move          ( entry phentsize phbuf phsize )

   \ Scan the program sections and determine how much memory is needed
   2dup bounds  ?do	( entry phentsize phbuf phsize ) \ throughout loop
      \ p_type  PT_LOAD
      i 0 +elfl@  1 =  if
	 \ p_vaddr       p_memsz
         i 8 +elfl@  i h# 14 +elfl@  record-extent
      then
   2 pick +loop		( entry phentsize phbuf phsize )

   \ XXX Ultimatelty we need to allocate physical memory and map
   \ it appropriately, but for now we just claim the virtual address
   \ space, assuming that it is already mapped.

   low-water 0   high-water low-water -  0  mem-claim drop  ( adr )
   low-water <> abort" Couldn't claim the program's memory"

   2dup bounds  ?do	( entry phentsize phbuf phsize ) \ throughout loop
      \ p_type  PT_LOAD
      i 0 +elfl@  1 =  if

         \ XXX we need to acquire and map the memory first!

	 \ Move it into the correct vaddr.
         \ p_offset          p_vaddr      p_filesz
	 i 4 +elfl@ +base   i 8 +elfl@  i h# 10 +elfl@   ( src dst len )
         2dup 2>r  move  2r> sync-cache

         \ Zero any bytes that are not stored in the file
	 \ p_vaddr       p_memsz        p_filesz
         i 8 +elfl@  i h# 14 +elfl@  i h# 10 +elfl@  /string  erase
      then
   2 pick +loop		( entry phentsize phbuf phsize )
   free-mem  drop       ( entry )
;

defer verify-machine-type
: (verify-machine-type)   ( -- )
   h# 10 eh-w@  2  <>  abort" The loaded file is not executable"
   h# 12 eh-w@  dup d# 17 <>  swap d# 20 <>  and
   abort" The loaded file is not a PowerPC program"
;
' (verify-machine-type) to verify-machine-type

: init-elf-program   ( -- )
   verify-machine-type

   prepare-elf-program           ( pc )

   h# 8000 alloc-mem  h# 8000 +  ( pc sp )

   (init-program)
;

headers
warning @ warning off
: init-program  ( -- )  elf?  if  init-elf-program  else  init-program  then  ;
warning !

\ LICENSE_BEGIN
\ Copyright (c) 2007 FirmWorks
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
