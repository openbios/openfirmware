\ See license at end of file
: virt>phys  ( virt-adr -- phys-adr )
[ifdef] map?
XXX Add mapping code
[then]
;


0 [if]
: le-rsp-extract  ( adr residue reg# -- )
   rot >r                       ( residue reg# r: adr )
   cw@  wljoin                  ( value r: adr )
   dup  2 rshift  lwsplit drop  ( value low r: adr )
   wbsplit  r@ 1+ c!  r@ c!     ( value r: adr )
   lwsplit nip                  ( residue r: adr )
   r> 2+ swap
;

\ Store in the buffer in little-endian form
: le-get-response136  ( buf -- )  \ 128 bits (16 bytes) of data.
   h# 1e  cw@           ( buf residue )
   h# 10  h# 1c  do     ( buf residue )
      i le-rsp-extract     ( buf' residue' )
   -2 +loop             ( buf residue )
   \ At this point the residue contains the top few bits
   2 rshift tuck over c!  ( residue buf )
   
   swap  8 rshift 3 and  swap 1+ c!  ( )
;
[then]

: cmdm  ( arg cmdcode mode -- isr )
   ." CMD: " over 4 u.r space 
   rot 8 cl!    \ Arg
   h# c cw!     \ Mode
   h# e cw!     \ cmd

   begin
      isr@  dup  ( h# 8001 ) 1  and  0=
   while
      key?  if  key drop  debug-me  then
      drop
   repeat      ( isr-value )
   dup 8 and  if  cr ." DMA! " dup 8 u.r space  cr  then
   dup isr!
;
\ Special case for the common situation where mode = 0
: cmd  ( arg code -- )  0 cmdm  ;

: no-response  ( isr -- )  drop cr  ;

\ Some places to store response data
variable rdata
variable rspdata0
variable rspdata1
variable rspdata2
variable errdata

: bits39-8  ( -- n )
   rspdata0 w@  h# 3ff and  6 lshift
   rspdata1 w@  d# 10 rshift  h# 3f and  or
;

\ Some tools for making command sequences

\ : i1  ( -- )  isr@ rdata w!  ;   \ Reads the interrupt reg
: i1  ( -- )  check-error  ." RSP: "  ;
: e1  ( -- )  esr@ errdata w!  cr  ; \ Reads the error int reg
: r0  ( -- )  h# 10 cw@ dup 5 u.r rspdata0 w!  ;  \ Response 1
: r1  ( -- )  h# 12 cw@ dup 5 u.r rspdata1 w!  ;  \ Response 2
: r2  ( -- )  h# 14 cw@ dup 5 u.r rspdata2 w!  ;  \ Response 3

: rsp1  ( -- )  i1  r0  e1  ;
: rsp2  ( -- )  i1  r0 r1   ."  39-8:"  response 5 u.r  e1  ;
: rsp3  ( -- )  i1  r0 r1 r2  ."  39-8:" response 5 u.r  e1  ;

0 value rca

: cmd0  ( -- )  0 0 cmd  no-response  0 to rca  ;  \ Reset card

\ Send ids
: cmd2  ( -- cid )  0 h# 201 cmd  rsp1  rspdata0 w@  ;  \ get-cid

: cmd3  ( -- )    \ Send relative address
   0 h# 302 cmd  rsp2
   response d# 16 lshift  to rca
;
\ cmd4 is SET_DSR
\ cmd5 is for SDIO

\ To deselect, send the wrong RCA value, expect no response
: deselect  ( -- )   0  h# 700 cmd  no-response  ;  \ Deselect

\ Keep trying to select the card until it responds
: retry-select  ( -- )
  \ Keep selecting until we get a response
  begin  rca  h# 702 cmd   h# 8000 and  while  ( )   \ While error
     esr@ esr!
     2 ms
  repeat
;

: cmd9   ( -- )   rca  h# 901 cmd  rsp1  ; \ Send Card-specific data

: cmd16  ( blksize -- )  h# 1002 cmd  rsp2  ; \ Sets blocksize SET_BLOCKLEN

: cmd17  ( adr mode -- )  h# 1122 swap cmdm  rsp2  ;  \ READ_SINGLE_BLOCK
: cmd24  ( adr mode -- )  h# 1822 swap cmdm  rsp2  ;  \ WRITE_SINGLE_BLOCK

: cmd55  ( -- )  rca  h# 3702  cmd rsp3  ;  \ Prefix for app-specific commands

: acmd6  ( mode -- ) cmd55  h# 602 cmd  rsp2  ; \ App-specific - 4-bit mode
: acmd41 ( ocr -- )  cmd55  h# 2902 cmd rsp3  ; \ App-specific - sets operating condition
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
