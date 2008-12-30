\ See license at end of file
purpose: Callbacks into C wrapper.

\ From wrcall.fth

\ The somewhat-clumsy design of this was an historical artifact of
\ the process by which the x86 world migrated from 16-bit to 32-bit
\ systems.  The intermediate steps involved a sequence of incompatible
\ third-party "DOS extenders", each with their own quirks and restrictions.

\ at memtop:  0  4   8   C   10  14  18
\             SP SS  CS  DS  ES  FS  GS
hex

\ True if we are running in a "flat" memory space with all segment
\ selectors referring to the same address range.  This is generally
\ the case when running under Win32 or Unix, but not when running
\ native or under DOS, VCPI, or DPMI.
false value flat?

code (wrapper-call)  ( arg call# memtop -- )
   bx  pop
   ax  pop				\ Syscall# in AX
   dx  pop				\ pstr in DX
   sp  cx  mov				\ Save my SP in CX
   ss push  gs pop			\ Save my SS in GS

   \ Go back to loader's stack, setting SS if necessary
   1 #  'user flat?  test  0<> if
      0 [bx]  sp  mov
   else
      0 [bx]  sp  lss
   then

   \ Nonce pushes to enforce 16-byte stack args alignment for Darwin
   ax push  ax push

   cx push				\ my SP
   gs push				\ my SS
   ds push				\ my DS

   ds push				\ pstr segment
   dx push				\ pstr offset
   ax push				\ call#

   10 [bx]  es mov			\ his ES
   14 [bx]  fs mov			\ his FS
   18 [bx]  gs mov			\ his GS
   0c [bx]  ds mov			\ his DS

   here-t 5 + #)  call   here-t origin-t -  ( offset )
   dx pop
   ( offset ) #  dx  sub

   1 #  'user flat?  test  0<> if
      6 [dx] call		\ cs = 0, forth was called from windows or unix
   else
      cs: 6 [dx] far call	\ Call through far pointer at loc 6
   then

   ax pop  ax pop  ax pop		\ Discard call# and pointer

   ax pop				\ DS
   ax ds mov				\ Reload my DS
   ax es mov				\ Reload my ES
   ax fs mov				\ Reload my FS
   ax gs mov				\ Reload my GS

   bx pop				\ my SS
   cx pop				\ my SP

   ax pop  ax pop  \ Undo nonce pushes

   1 #  'user flat?  test   0= if
      bx ss mov				\ Reload my SS:SP
   then
   cx sp mov				\ my SP
c;

\ Later, when Forth takes over interrupt vector 13, the following
\ defer words should be set to save and restore vector 13.
\ Typically, that would be done in catchexc.fth

defer wrapper-vectors  ' noop is wrapper-vectors
defer forth-vectors    ' noop is forth-vectors

: wrapper?  ( -- flag )  origin 6 + le-l@  0<>  ;
: wrapper-call  ( arg call# -- )
   wrapper?  0=  abort" Wrapper calls are not available"

   wrapper-vectors
   memtop @  (wrapper-call)
   forth-vectors
;   

create c-args 6 /n* allot-t

: his-ds  ( -- sel# )  memtop @ h# c + le-l@  ;

[ifdef] notdef
: malloc  ( size -- adr )  c-args le-l!  c-args 1 wrapper-call  c-args le-l@  ;
: free   ( adr -- )  c-args le-l!   c-args 2 wrapper-call  ;
: free2  ( adr size -- )  drop free  ;
: wr-fopen  ( mode name-cstr -- file# )  sp@  3 wrapper-call  nip  ;

: sys-init-malloc  ( -- )
   wrapper?  if
      ['] malloc    is alloc-mem
      ['] free2     is free-mem
      ['] wr-fopen  is _fopen
   else
      install-dumb-alloc
   then
;
[else]
: sys-init-malloc  ;
[then]

\ From syscalls.fth
\ interface layer between syscall and wrapper-call, for compatibility

code fill-args   (s c-args -- )
\ transfers 6 top items of stack to array c-args
\ top goes to c-args[0], top-1 to c-args[1], etc.
 
   dx pop
   sp bx mov    \ must be after dx pop, so as not to include c-args itself
   6 # cx mov   \ size of array c-args
   begin

[ifdef] big-endian-t

        0 [bx] al mov   al 3 [dx] mov
        1 [bx] al mov   al 2 [dx] mov
        2 [bx] al mov   al 1 [dx] mov
        3 [bx] al mov   al 0 [dx] mov

[else]

        0 [bx] ax mov   ax 0 [dx] mov

[then]

        4 # bx add   4 # dx add   cx dec
   0= until
c;


: syscall   ( call# -- )

        >r
        c-args fill-args
        c-args r> wrapper-call
;

: retval   ( -- args[0] )

        c-args le-l@ 
;

\ From sys.fth
decimal

nuser errno	\ The last system error code
: error?  ( return-value -- return-value error? )
   dup 0< dup  if  ( 60 syscall retval errno !  ) then   ( return-value flag )
;

\ Rounds down to a block boundary.  This causes all file accesses to the
\ underlying operating system to occur on disk block boundaries.  Some
\ systems (e.g. CP/M) require this; others which don't require it
\ usually run faster with alignment than without.

hex
\ Aligns to a 512-byte boundary; this is okay for most systems.
: _falign  ( l.byte# fd -- l.aligned )  drop  1ff invert and  ;
: _dfalign  ( d.byte# fd -- d.aligned )  drop  swap 1ff invert and swap	;

: sys-init-io  ( -- )
   init-relocation 		\ must be first, for [is] to work
   install-wrapper-io

   install-disk-io
   \ Don't poll the keyboard under an OS; block waiting for a key
   ['] (key              ['] key            (is
;
' sys-init-io is init-io
: sys-init  ( -- )  ;
' sys-init is init-environment

decimal
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
