\ ========== Copyright Header Begin ==========================================
\ 
\ Hypervisor Software File: tokenize.fth
\ 
\ Copyright (c) 2006 Sun Microsystems, Inc. All Rights Reserved.
\ 
\  - Do no alter or remove copyright notices
\ 
\  - Redistribution and use of this software in source and binary forms, with 
\    or without modification, are permitted provided that the following 
\    conditions are met: 
\ 
\  - Redistribution of source code must retain the above copyright notice, 
\    this list of conditions and the following disclaimer.
\ 
\  - Redistribution in binary form must reproduce the above copyright notice,
\    this list of conditions and the following disclaimer in the
\    documentation and/or other materials provided with the distribution. 
\ 
\    Neither the name of Sun Microsystems, Inc. or the names of contributors 
\ may be used to endorse or promote products derived from this software 
\ without specific prior written permission. 
\ 
\     This software is provided "AS IS," without a warranty of any kind. 
\ ALL EXPRESS OR IMPLIED CONDITIONS, REPRESENTATIONS AND WARRANTIES, 
\ INCLUDING ANY IMPLIED WARRANTY OF MERCHANTABILITY, FITNESS FOR A 
\ PARTICULAR PURPOSE OR NON-INFRINGEMENT, ARE HEREBY EXCLUDED. SUN 
\ MICROSYSTEMS, INC. ("SUN") AND ITS LICENSORS SHALL NOT BE LIABLE FOR 
\ ANY DAMAGES SUFFERED BY LICENSEE AS A RESULT OF USING, MODIFYING OR 
\ DISTRIBUTING THIS SOFTWARE OR ITS DERIVATIVES. IN NO EVENT WILL SUN 
\ OR ITS LICENSORS BE LIABLE FOR ANY LOST REVENUE, PROFIT OR DATA, OR 
\ FOR DIRECT, INDIRECT, SPECIAL, CONSEQUENTIAL, INCIDENTAL OR PUNITIVE 
\ DAMAGES, HOWEVER CAUSED AND REGARDLESS OF THE THEORY OF LIABILITY, 
\ ARISING OUT OF THE USE OF OR INABILITY TO USE THIS SOFTWARE, EVEN IF 
\ SUN HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGES.
\ 
\ You acknowledge that this software is not designed, licensed or
\ intended for use in the design, construction, operation or maintenance of
\ any nuclear facility. 
\ 
\ ========== Copyright Header End ============================================
purpose: Tokenizer program source - converts FCode source to byte codes
copyright: Copyright 2006 Sun Microsystems, Inc.  All Rights Reserved
copyright: Use is subject to license terms.

\ TODO:
\ Add a means to define symbols for use with ifdef
\ Add a means to set the start code from the command line

only forth also definitions

\ ' $report-name is include-hook  ' noop is include-exit-hook

vocabulary tokenizer
also tokenizer also definitions

decimal	 warning off  caps on
fload ${BP}/forth/lib/split.fth	  \ 32>8,8,8,8; 16>8,8; 8,8>16 ...

\ Keep quiet about warnings and statistics.
variable silent  silent off

\ For error checking
0 value start-depth

128 buffer: string3		\ Used by begin/end-tokenizing
: save$3  ( adr len -- pstr )  string3 pack  ;

\ true to prepend an a.out header to the output file
variable aout-header?  aout-header? off

\ Statistics variables used in final statistics word
variable #literals
variable #locals
variable #apps
variable #primitives

variable #constants
variable #values
variable #variables
variable #buffers
variable #defers

variable compiling		\ True if in an FCode definition
variable #end0s  #end0s off	\ How many END0 tokens encountered
variable offset-8?  offset-8? off  \ Can be set to true by tokenize script

defer fcode-start-code		\ start0, start1, start2, or start4

variable names			\ true=(create named local tokens)

variable rev-level		\ Variable for FCode rev-level in PCI header
1 rev-level !

variable fcode-offset		\ Variable for FCode offset relative to PCI hdr
h# 34 fcode-offset !		\ Our "normal" offset

variable indicator		\ Variable to set indicator field in PCI header
h# 80 indicator !

variable vpd-addr		\ Variable for VPD pointer in PCI header
0 vpd-addr !

variable been-there-done-that	\ If <>0 means fcode-end has already finished
				\ up file info
0 been-there-done-that !

variable outf-name		\ Place to save file name so that file 
variable outf-len		\ can be post-processed


\  File header creation, fill in size later (see a.out(5) for format)
create header  h# 01030107 ,  0 ,  0 ,  0 ,  0 ,  h# 4000 ,  0 ,  0 ,

\  Monitor current output counters
\ 'bhere' returns the total # of byte-codes output so far.
\ 'fhere' returns the current position in the file.  This will be
\ different, because of the file header (32 bytes), and sometimes more
\ because of debugging information being output as well as byte-codes.

variable bytes-emitted  \ Total # of byte-codes output so far
: bhere	 ( -- #token-bytes-emitted )  bytes-emitted @  ;
: fhere	 ( -- cur-file-pos )  ofd @ ftell  ;


\ Vectored output primitives
: .byte	 ( c -- )
   \ put byte to output file
   ofd @ fputc
;

\  : .word  ( w -- )
\     wbsplit .byte .byte
\  ;
\
\  : .long  ( l -- )
\     lbsplit .byte .byte .byte .byte
\  ;


: inc	 ( adr -- )  1 swap +! ;   \ increment variable

variable checksum	\ Running total of all emitted bytes
: emit-fbyte  ( c -- )
   dup checksum +!  .byte  bytes-emitted inc
\   bytes-emitted @ .x checksum @ .x cr
;

\ The user-level "emit-byte" will *not* affect the running-total
\ length and checksum fields before "fcode-versionx" and after "end0"
\ This allows embedded binary before and after the fcode to work
\ correctly, i.e. leave the fcode-only image unaltered. 
defer emit-byte	  
' .byte is emit-byte  \ Will later be vectored to emit-fbyte

: emit-word  ( w -- )  wbsplit	emit-byte emit-byte  ;
: emit-long  ( l -- )  lwsplit	emit-word emit-word  ;

: emit-token	    ( apf -- )
   c@ emit-byte
;

: emit-local-escape ( apf -- )	\ (adr+1)c@=0 then output 1 byte token
   ca1+	 dup c@	 if  emit-token	 else  drop  then
;

: emit-local  ( apf -- )
   dup emit-local-escape emit-token
;

: pad-size  ( -- )  \ Pad file to longword boundary
   ofd @ ftell	( size )
   dup /l round-up swap -  0  ?do  0 emit-byte	loop 
;


\  Compiling word to create primitive tokens
variable which-version	  \ bit variable - each bit represents a version's use

variable #version1s    \ accumulator of version 1   tokens compiled
variable #version1+2s  \ accumulator of version 1+2 tokens compiled
variable #version2s    \ accumulator of version	  2.x tokens compiled
variable #version2.1s  \ accumulator of version	  2.1 tokens compiled
variable #version2.2s  \ accumulator of version	  2.2 tokens compiled
variable #version2.3s  \ accumulator of version	  2.3 tokens compiled
variable #version3s    \ accumulator of version	  3   tokens compiled
variable #obsoletes    \ accumulator of obsolete      tokens compiled
variable #firmworks    \ accumulator of firmworks custom tokens compiled

: or!	 ( adr bit$ -- ) over @ or swap ! ;  \ or in bit string

: v1   ( -- ) which-version 1 or! ;  \ FCode was/is versions 1
: v2   ( -- ) which-version 2 or! ;  \ FCode was/is versions 2.0
: v2.1 ( -- ) which-version 4 or! ;  \ FCode was/is versions 2.1
: v2.2 ( -- ) which-version 8 or! ;  \ FCode was/is versions 2.2
: v2.3 ( -- ) which-version h# 10 or! ;	 \ FCode was/is versions 2.3
: v3   ( -- ) which-version h# 20 or! ;	 \ FCode was/is versions 3
: obs  ( -- ) h# 40 which-version ! ;  \ FCode is obsolete
: vfw  ( -- ) h# 80 which-version ! ;  \ FCode is FirmWorks-specific

: byte-code:  \ name  ( token# table# -- )  \ Compiling
   ( -- )  \ At execute time, sends proper token# to output stream
   which-version dup @	swap off
   dup 0=  abort" missing v1, v2 ... byte-code: prefix"
   create  rot c, swap c, c,
   does>  dup 2 ca+ c@ case
      1 of
	  cr ." *** Warning: `"	 dup body> >name name>string type
	  ." ' is an obsoleted version 1 token. ***"  #version1s
	endof
       2 of  #version2s	   endof
       3 of  #version1+2s  endof

       4 of  #version2.1s  endof
       8 of  #version2.2s  endof
   h# 10 of  #version2.3s  endof
   h# 20 of  #version3s	   endof
   h# 40 of
	   silent @ 0=	if
	      cr ." *** Warning: `"  dup body> >name name>string type
	      ." ' is an obsolete FCode token. ***" cr
	   then
	   #obsoletes
	endof
   h# 80 of  #firmworks	   endof
   endcase
   ( pfa adr ) inc  emit-local	#apps inc
;

: (.name)  ( xt -- )  >name name>string type  ;
: v2-compat:  \ old-name new-name  ( -- )
   create  ' token,
   does>
      silent @ 0=  if
	 ." Warning: Substituting `" dup token@ (.name)
	 ." ' for old name `" dup body> (.name) ." '" cr
      then
      token@ execute
;

\ When executing, forth, tokens and 'reforth' words are allowed.
\   'reforth' vocab. redefines certain words like : and constant.
\
\ When compiling, *only* prim. tokens, macros or new local tokens
\   are allowed.  The file 'crosslis.fth' holds equivalent names
\   for missing primitives, e.g.  : 2+	2 + ;
\
\ Needed words which do not have primitive token equivalents (e.g.
\   h#, ascii, etc. ) are handled with aliases to standard forth.
\
\ Control words (if, begin, loop, etc.) have custom definitions, as
\   do a limited set of string input words.


\  Add allowed tokens into 'tokens' vocabulary
only forth definitions
vocabulary tokens
vocabulary reforth

also tokenizer definitions
\  Length & checksum creation
variable checksumloc	\ Location of checksum and length fields

\  Go back and patch previous output items
: patch-byte  ( byte addr -- )	   \ Go back to 'addr' and insert 'val'
   fhere  >r			   \ Save current file pointer
   ofd @  fseek			   \ Move back to 'addr' location
   emit-fbyte  -1 bytes-emitted +! \ fix forward reference
   r>  ofd @  fseek		   \ Restore current file pointer
;
: patch-word  ( word addr -- )	>r wbsplit  r@ patch-byte  r> 1+ patch-byte  ;
: patch-long  ( long addr -- )	>r lwsplit  r@ patch-word  r> 2+ patch-word  ;

: .stats ( -- )
   decimal
   #literals   @ 8 .r  ."  Literals " cr
   #primitives @ 8 .r  ."  Non-(lit) Primitives" cr
   #apps       @ 8 .r  ."  Application Codes "	cr
   #locals     @ 8 .r  ."  Local Codes " cr
   #variables  @ 8 .r  ."  Variables " cr
   #values     @ 8 .r  ."  Values " cr
   #constants  @ 8 .r  ."  Constants " cr
   #buffers    @ 8 .r  ."  Buffer:s " cr
   #defers     @ 8 .r  ."  Defers " cr
;

: write-header	( -- )	header	d# 32  ofd @ fputs  ; \ don't affect checksum

: full-size  ( -- size )  \ Entire file, except a.out header
   ofd @ ftell	aout-header? @	if  d# 32 -  then
;
: fcode-size  ( -- size )  \ fcode-versionx thru end0 ONLY
   bytes-emitted @
;

: fix-length   ( -- size )
   #end0s @ 0=	if
      silent @ 0=  if
	 ??cr ." *** Warning: FCode token END0 is missing at the end of the file. ***" cr
      then
      0 emit-byte  \ END0
   then
   fcode-size  checksumloc @ 2+  patch-long
;
: fix-checksum ( -- )
   checksum @  checksum off
   lwsplit + lwsplit +
   h# ffff and	checksumloc @  patch-word
;
: fix-header ( -- )
   aout-header? @  if  full-size 4 patch-long  then 
;

create symtab  4 , 5 c, 0 c, 0 w, 0 , 0 w, 0 c,
d# 15 constant /symtab

\ a.out(5) symbol buffer
128 buffer: label-string

variable append-label?	  append-label? off

: fix-symtab ( -- )
   append-label? @  if
      h# 0c h# 10 patch-long
      symtab /symtab ofd @ fputs	      (	 )
      bl word label-string "copy	      (	 )
      label-string dup c@ dup >r	      ( adr len )
      1+ 4 + swap c!			      (	 )
      label-string r> 2+ ofd @ fputs   (  )
   then
;
: adjust-file-numbers  ( -- )
   pad-size
   fix-checksum
   fix-length
   fix-header	      \ !!! fix header last so checksum is correct.
   fix-symtab
;
previous definitions

\   don't search the tokens voc because it includes numbers (-1, 0, 1, ..)
only forth also tokenizer also	tokens definitions  tokenizer
\ root forth forth : tokens

\ begin-tokenizing lives in the forth vocabulary and causes a transition
\ to the tokens vocabulary.
\ Conversely, end-tokenizing lives in the tokens vocabulary and causes a
\ transition to the forth vocabulary.
: end-tokenizing  ( -- )
   \ Compare the current SP against the previous one
   depth start-depth <> if  ." Error: Stack depth changed"  cr  then

   silent @ 0=	if  cr	then

   been-there-done-that @ 0=  if
      adjust-file-numbers
   then

   ofd @ fclose

   ( out-file$ )

   #version1s @	 if
      cr ." Fatal error:  Obsolete version 1 tokens used"
      string3 count delete-file drop cr
      ."    Output file not generated" cr cr
   then
   only forth also definitions
;

fload ${BP}/ofw/fcode/primlist.fth	\ basic words - escape-code=0
fload ${BP}/ofw/fcode/sysprims.fth	\ gen purpose plug in routines
fload ${BP}/ofw/fcode/regcodes.fth	\ Register access words
fload ${BP}/ofw/fcode/extcodes.fth	\ Firmworks extension FCodes

only forth also tokenizer also

\   For the rest of this file, the search order is *always* either:
\
\     context: forth   forth root     current: forth	 - or -
\     context: tokens  forth root     current: tokens	 - or -
\     context: reforth forth root     current: reforth


tokens definitions
alias \		\
alias 16\	\
alias (		(
alias (s	(
alias .(	.(
alias th	th	\ becoming obsolete
alias td	td	\ becoming obsolete
alias h#	h#
alias d#	d#
alias o#	o#
alias b#	b#

alias [ifdef]  [ifdef]
alias [ifndef] [ifndef]
alias [if]     [if]
alias [then]   [then]
alias [else]   [else]

tokenizer definitions

\ Init search path during execution
: init-path  ( ) \ Out of definitions, allow  'tokens' and 'reforth'
   only ( root ) definitions also reforth also tokens definitions
;

: tokens-only  ( -- )  \ Allow only tokens within definitions
   only tokens also definitions
;

\  More output primitives
: emit-number  ( n -- )
   [ also tokens ]  b(lit)  [ previous ]  emit-long
   1 #literals +!
;
: tokenize-literal  ( n 1 | d 2 -- )  0	 ?do  emit-number  loop	 ;

\ Lookup table primitives
\ 'lookup' table contains 256 longword values, corresponding
\ to 256 possible local tokens.	 Entry #n contains the offset from the
\ beginning of the bytes-output file where the definition of local
\ token#n begins.  For variables and constants, entry #n+1 contains
\ the actual value of the variable (0 initially) or constant.

8 constant first-local-escape

256 /l* constant 1tablesize  \ Size of one 256-word table
1tablesize  8 * buffer: lookup

variable next-lookup#  \ Next lookup# available
variable local-escape  \ Current local escape-code

: advance-lookup#  ( -- )  1 next-lookup# +!  ;
: lookup#-range-check  ( -- )
   next-lookup# @  d# 254 >  if
      1 local-escape +!	  0 next-lookup# !
   then
;

: next-lookup  ( -- addr )
   next-lookup# @  /l*
   local-escape @  first-local-escape -	 1tablesize *  +
   lookup +
;

: set-lookup-pointer  ( bhere -- )  \ Pnt cur lookup# to current byte-out
   lookup#-range-check
   next-lookup	l!
;

variable local-start  \ Byte-count at start of current word
: save-local-start  ( -- )  \ Save current bytes-emitted value
   bhere  local-start !
;

variable fcode-vers fcode-vers off
: .fcode-vers-error ( -- )
   silent @ 0=	if
      ??cr ." Warning: Multiple Fcode-version# commands encountered. " cr
   then
;
: restore-header ( -- )
   ['] tokenize-literal	 is do-literal
   [ forth ]  ['] (header)  is header [ tokenizer ]
;

tokens definitions
\ The accepted plug-in format is:
\ fd  - version1 fcode (1 byte) for first encountered fcode.
\  0  - revision byte
\ checksum - 2 bytes containing the fcode PROM checksum.
\ length - 4 bytes specifying the total usable length of fcode data
\	   (i.e. from 'version1' to 'end0' inclusive)
\
\ The checksum is calculated by summing all remaining bytes, from just after
\ the length field to the end of the usable fcode data (as indicated
\ by the length field).


: (fcode-version) ( -- )
   bhere abort" Fcode-version# should be the first FCode command!"
   [ tokenizer ]
   which-version off  \ init version flag to normal state
   #version1s	 off  \ init version 1 code counter
   #version1+2s	 off  \ init version 1 and 2 code counter
   #version2s	 off  \ init version 2 code counter
   #version2.1s	 off  \ init version 2.1 code counter
   #version2.2s	 off  \ init version 2.2 code counter
   #version2.3s	 off  \ init version 2.3 code counter
   #version3s	 off  \ init version 3 code counter
   #obsoletes	 off  \ init obsolete  code counter
   #firmworks	 off  \ init firmworks  code counter
   checksum	 off  \ Clear checksum bits set by version1
   pad-size
   ['] emit-fbyte is emit-byte
   [ tokens ]
;

: Fcode-version1 ( -- )
   [ tokenizer ]
   fcode-vers @ 0=  if
      fcode-vers on
      restore-header

      [ tokens ] (fcode-version)  version1  [ tokenizer ]  \ (0xfd token)
      h# 3 emit-byte	   \ revision: (rev 2.2 - fixed checksum problem)
      fhere checksumloc !
      0 emit-word	   \ Filler for later checksum field
      0 emit-long	   \ Filler for later length field
      checksum	off
      offset-8?	 @ 0=  if
	 [ tokens ]  offset16  [ tokenizer ]	\ compile offset16 Fcode
      then
   else
      .fcode-vers-error
   then
   [ tokens ]
;

:  Fcode-version2 ( -- )
   [ tokenizer ]
   fcode-vers @ 0=  if
      fcode-vers on
      restore-header

      [ tokens ] (fcode-version)  start1  [ tokenizer ]
      h# 3 emit-byte	     \ sub-version (2.2 with fixed checksum)
      fhere checksumloc !
      0 emit-word	  \ Filler for later checksum field
      0 emit-long	  \ Filler for later length field
      checksum off
      offset-8? [ forth ] off [ tokenizer ]
   else
      .fcode-vers-error
   then
   [ tokens ]
;

' start1 is fcode-start-code

:  Fcode-version3 ( -- )
   [ tokenizer ]
   fcode-vers @ 0=  if
      fcode-vers on
      restore-header

      [ tokens ] (fcode-version)  fcode-start-code  [ tokenizer ]
      h# 8 emit-byte	     \ sub-version (2.2 with fixed checksum)
      fhere checksumloc !
      0 emit-word	  \ Filler for later checksum field
      0 emit-long	  \ Filler for later length field
      checksum off
      offset-8? [ forth ] off [ tokenizer ]
   else
      .fcode-vers-error
   then
   [ tokens ]
;

tokenizer definitions
\ Test for branch offsets greter than one byte
: test-span   ( delta -- )   \ Test if offset is too great
   d# -128 d# 127  between  0=	( error? )  if
     ." Warning: Branch interval of +-127 bytes exceeded." cr
     ." Use OFFSET16 or, better yet, use shorter dfns." cr
  then
;


\ Token control structure primitives
\ Number of bytes in a branch offset
: /branch-offset ( -- n )  1 offset-8? @ 0= if	1+  then  ;
variable Level

: +Level  ( -- )  1 Level +!  ;
: -Level  ( -- )  -1 Level +!  Level @ 0< abort" Bad conditional"  ;

: >Mark	   ( -- bhere fhere )
   bhere fhere	 0 emit-byte
   offset-8? @ 0= if 0 emit-byte then  \ Two bytes if offset-16 is true
;

: >Resolve ( oldb oldf -- )
   bhere  rot -	 swap	 ( delta oldf )
   offset-8? @ 0= if
      patch-word
   else
      over test-span patch-byte
   then
;

: <Mark	 ( -- bhere fhere )  bhere fhere  ;
: <Resolve ( oldb oldf -- )
   drop bhere  -   ( delta )
   offset-8? @ 0= if
      emit-word
   else
      dup  test-span emit-byte
   then
;

: but  ( b1 f1 t1 b2 f2 t2 -- b2 f2 t2 b1 f1 t1 )
   >r rot >r  2swap	   ( b2 f2 b1 f1 )  ( r: t2 t1 )
   r> r> swap >r -rot r>   ( b2 f2 t2 b1 f1 t1 )
;
: +>Mark  ( -- bhere fhere )	 +Level >Mark	   ;
: +<Mark  ( -- bhere fhere 11 )	 +Level <Mark  11  ;
: ->Resolve  ( oldb oldf chk2 chk1 -- )	 ?pairs >Resolve -Level	 ;
: -<Resolve  ( oldb oldf chk -- )  11 ?pairs <Resolve -Level  ;


tokens definitions
\ Take Forth/tokenizer commands only
: tokenizer[  ( -- )
   ['] (do-literal) is do-literal
   only forth also tokenizer definitions
;

tokenizer definitions
\ Restore normal FCode behavior
: ]tokenizer  ( -- )
   ['] tokenize-literal is do-literal
   compiling @	if  tokens-only	 else  init-path  then
;

tokens definitions
\  Token control structure words
\   !! Any word followed by ( T) is an executable token, *not* forth!

: ['] ( -- )  b(')  ;
: to ( -- )  b(to)  ;

: ahead	 ( -- fhere 22 )  bbranch  ( T)	 +>Mark 22  ;
: if	 ( -- fhere 22 )  b?branch ( T)	 +>Mark 22  ;

: then ( oldb oldf 22 -- )
   b(>resolve)	( T)
   [ tokenizer ]  22 ->Resolve	[ tokens ]
;

: else ( fhere1 22 -- fhere2 22 )
   ahead  [ tokenizer ]	 but  [ tokens ]     ( fhere2 22 fhere1 22 )
   then ( T)		 ( )
;

: begin	 ( -- bhere fhere 11 )	b(<mark) ( T)	+<Mark	;
: again	 ( oldb 11 -- )	  bbranch ( T)	-<Resolve  ;
: until	 ( oldb 11 -- )	 b?branch ( T)	-<Resolve  ;

: while	 ( bhere fhere 11 -- bhere2 fhere2 22  bhere fhere 11 )
   if ( T)
   [ tokenizer ] but ( whileb whilef 22 oldb 11 )  [ tokens ]
;

: repeat  ( fhere 22 bhere 11 -- )  again ( T)	then ( T)  ;


: case	( -- 0 44 )
   +Level b(case) ( T) [ tokenizer ]  0	 44  [ tokens ]
;

: of  ( 44 -- of-b of-f 55 )  44 ?pairs	  b(of) ( T)  >Mark  55	 ;

: endof ( of-b of-f 55 -- endof-b endof-f 44 )
   b(endof) ( T)  >Mark 66 ( of-b of-f endof-b endof-f )
   [ tokenizer ] but  55 ?pairs	 >Resolve   44 [ tokens ]
;

: endcase ( 0 [endof-address 66 ...] 44 -- )
   b(endcase) ( T)
   44 ?pairs
   [ tokenizer ]
   begin  66 =	while  >Resolve	 repeat
   -Level
   [ tokens ]
;


: do  ( -- >b >f 33 <b <f 11 )	b(do)  ( T)  +>Mark 33	+<Mark	;
: ?do ( -- >b >f 33 <b <f 11 )	b(?do) ( T)  +>Mark 33	+<Mark	;

: loop	( >b >f 33 <b <f 11 -- )
   b(loop) ( T)	 [ tokenizer ]	-<Resolve  33 ->Resolve	 [ tokens ]
;

: +loop	 ( oldb oldf 33 -- )
   b(+loop) ( T)  [ tokenizer ]	 -<Resolve  33 ->Resolve  [ tokens ]
;

: leave ( ??? -- ??? ) b(leave) ( T)  ;
: ?leave ( ??? -- ??? )	 if ( T)  leave ( T)  then ( T)	 ;


\  Add cross-compiler macros for common non-tokens
fload ${BP}/ofw/tokenizer/crosslis.fth


: hex ( -- )
   [ also forth ]
   compiling @	if  m-hex  else	 hex  then
   [ previous ]
;
: decimal ( -- )
   [ also forth ]
   compiling @	if  m-decimal  else  decimal  then
   [ previous ]
;
: octal ( -- )
   [ also forth ]
   compiling @	if  m-octal  else  octal  then
   [ previous ]
;
: binary ( -- )
   [ also forth ]
   compiling @	if  m-binary  else  binary  then
   [ previous ]
;


tokens definitions
\ String compiling words

\ (Implementation word, will not be supported)
: ",  ( adr len -- )  \ compile the string into byte-codes
   [ tokenizer ]
   dup emit-byte    ( adr len )
   bounds  ?do
      i c@  emit-byte
   loop
   [ tokens ]
;

\ (Implementation word, will not be supported)
: ,"  \ name"  ( -- )
   [ tokenizer ]  get-string ( ascii " parse ) [ tokens ] ",
;

: "  \ text"  ( -- )  \ Compiling ( -- adr len )  \ Executing
   b(")	 ,"
;

: s" \ text"  ( -- )  \ Compiling ( -- adr len )  \ Executing
   b(")
   [ tokenizer ]  ascii " parse	 [ tokens ] ",
;

: ."   ( -- )  \ text"
   "  type
;

: .( ( -- )  \	text)
   b(")	 [ tokenizer ]	ascii ) parse [ tokens ]  ",  type
;

\  Offset16 support
: offset16  ( -- )   \ Intentional redefinition
   offset16	     \ compile token
   offset-8? [ tokenizer ] off	\ Set flag for 16-bit branch offsets
   [ tokens ]
;


\  New NAME shorthand form for "name" property
: name	 ( adr len -- )
   encode-string  b(") [ tokenizer ] " name"   [ tokens ]  ", property
;

: ascii	 \ name	 ( -- n )
   [ tokenizer ]  safe-parse-word drop	c@ emit-number	[ tokens ]
;

: control  \ name  ( -- n )
   [ tokenizer ]  safe-parse-word drop	c@ h# 1f and  emit-number  [ tokens ]
;

: char	\ name	( -- n )
   compiling @  abort" 'char' is not permitted inside FCode definitions"
   ascii
;

: [char]  \ name  ( -- n )
   compiling @  0= abort" '[char]' is not permitted outside FCode definitions"
   ascii
;

tokenizer definitions
\  Create word for newly-defined 'local' tokens
: local:  \ name  ( -- )
   safe-parse-word  2dup $create  ( adr len )
   names @ case
      -1 of	    [ also tokens ]  named-token    ", [ previous ] endof
      0	 of  2drop  [ also tokens ]  new-token	       [ previous ] endof
      1	 of	    [ also tokens ]  external-token ", [ previous ] endof
   endcase
   here	  next-lookup# @ c,
   local-escape @ c,  emit-local advance-lookup#
   does>   emit-local  1 #locals +!
;


: define-local: ( -- )	also tokens definitions	 local:	 previous  ;


\  End creation of new local token
: end-local-token  ( -- )
   [ also tokens ] b(;) [ previous ]
   \	patch-size
   compiling @ 0= abort" Error: ';' only allowed within definitions."
   init-path
   compiling off
;

tokens definitions

: abort"  \ text"  ( -- )  \ Compiling ( error? -- )  \ Executing
   ." abort
;

: ;  ( -- )  \ New version of ; to end new-token definitions
  ?csp reveal end-local-token
;


tokenizer definitions
\ Create new local tokens
: start-local-token  \ name ( -- )
   bhere set-lookup-pointer define-local:
   tokens-only	 \ Restrict search within localword to tokens
;

variable crash-site
: emit-crash  ( -- )
   bhere crash-site ! [ also tokens ]  crash  unnest  [ previous ]
;

only forth also tokenizer also reforth definitions
: headers     ( -- )  -1 names ! ;
: headerless  ( -- )   0 names ! ;
: external    ( -- )   1 names ! ;
: internal    ( -- )   headers  ;

alias fload	 fload
alias id:	 id:
alias purpose:	 purpose:
alias copyright: copyright:

: defer	 \ name	 ( -- )	 \ Compiling
   #defers inc
   crash-site @	 set-lookup-pointer  \ Deferred token points to 'crash'
   define-local:  [ also tokens ]  b(defer)  [ previous ]
;

: constant  \ name  ( -- )  \ Compiling	 ( -- n )  \ Executing
   start-local-token  ( n ) #constants inc
   [ also tokens ]  b(constant)	 [ previous ]
   \ advance-lookup#
   init-path
;

: value	 \ name	 ( -- )	 \ Compiling ( -- n )  \ Executing
   start-local-token  ( n )  #values inc
   [ also tokens ]  b(value)  [ previous ]
   \ advance-lookup#
   init-path
;

: variable  \ name  ( -- )  \ Compiling ( -- adr )  \ Executing
   start-local-token #variables inc
   [ also tokens ]  b(variable)	 [ previous ]
   \ advance-lookup#
   init-path
;

alias lvariable variable
alias alias   alias

\  Override certain Forth words in interpret state

\ We only allow 'create' in interpret state, for creating data tables
\   using c, w, etc.
: create  \ name  ( -- )  \ This 'create' for interpreting only
   start-local-token
   [ also tokens ]  b(create)  [ previous ]
   init-path
;

: buffer:  \ name  ( -- )  \ Tokenizing ( -- buff-adr )	 \ Executing
   start-local-token #buffers inc
   [ also tokens ]  b(buffer:)	[ previous ]
   init-path
;

: ' ( -- )  \ name
   [ also tokens ]  b(')  [ previous ]
;
: colon-cf ( -- )
   [ also tokens ]  b(:)  [ previous ]
;

: dict-msg ( -- )  ." Dictionary storage is restricted. "  where  ;
: allot ( #bytes -- ) ." ALLOT - "  dict-msg  ;


\  New STRUCT structure words
: struct ( -- )	 [ also tokens ]  0  [ previous ]  ;

: field	 \ name	 ( -- )	 \ Tokenizing ( struct-adr -- field-adr )  \ Executing
   start-local-token
   [ also tokens ]  b(field)  [ previous ]
   init-path
;

: vocab-msg  ." Vocabulary changing is not allowed. "  where  ;
\ : only	vocab-msg  ;  \ Escape below with 'only'
: also	      vocab-msg	 ;
: previous    vocab-msg	 ;
: except      vocab-msg	 ;
: seal	      vocab-msg	 ;
: definitions vocab-msg	 ;
: forth	      vocab-msg	 ;
: root	      vocab-msg	 ;
: hidden      vocab-msg	 ;
: assembler   vocab-msg	 ;


\  Save dangerous defining words for last
: :  \ name  ( -- )  \ New version of : to create new tokens
   !csp		       \ save stack so ";" can check it
   start-local-token  colon-cf
   hide	 compiling on
;


only forth also tokenizer also definitions
\  Final init & execute
: init-vars  ( -- )
   #literals	 off
   #apps	 off
   #locals	 off
   #primitives	 off

   #values	 off
   #variables	 off
   #constants	 off
   #defers	 off
   #buffers	 off

   #end0s	 off

   [ reforth ] headers [ tokenizer ]
   bytes-emitted off
   next-lookup#	 off
   checksum	 off
   Level	 off
   compiling	 off
   first-local-escape local-escape !
   -1 checksumloc !
;

: debug-interpret ( -- )
   begin
      ?stack parse-word dup
   while
      cr ." stack is: " .s
      cr ." word is: "	2dup type
      cr ." order is: " order
      cr $compile
   repeat
   2drop
;

: .warnings ( -- )
   base @ >r  decimal
   #version1s	@  ?dup	 if
      8 .r  ."	:Version 1   FCodes compiled (obsolete FCodes)" cr
   then
   #version1+2s @  ?dup	 if
      8 .r  ."	:Version 1   FCodes compiled" cr
   then
   #version2s	@  ?dup	 if
      8 .r
      ."  :Version 2.0 FCodes compiled (may require version 2 bootprom)" cr
   then
   #version2.1s @  ?dup	 if
      8 .r
      ."  :Version 2.1 FCodes compiled (may require version 2.3 bootprom)" cr
   then
   #version2.2s @  ?dup	 if
      8 .r
      ."  :Version 2.2 FCodes compiled (may require version 2.4 bootprom)" cr
   then
   #version2.3s @  ?dup	 if
      8 .r
      ."  :Version 2.3 FCodes compiled (may require version 2.6 bootprom)" cr
   then
   #version3s @	 ?dup  if
      8 .r
      ."  :Version 3 FCodes compiled (may require version 3 bootprom)" cr
   then
   #obsoletes @	 ?dup  if
      8 .r
      ."  :Obsolete FCodes compiled (may not work on version 3 bootproms)" cr
   then
   #firmworks @	 ?dup  if
      8 .r
      ."  :Firmworks FCodes compiled (may not work on non-Firmworks bootproms)" cr
   then
   r> base !
;

tokens definitions
: end0	( -- )	\ Intentional redefinition
   end0	 [ tokenizer ]	silent @ 0=  if
      cr ." END0 encountered."	cr
      .warnings
   then
   compiling @ 0=  if  1 #end0s +! pad-size  else  #end0s off  then
   ['] .byte is emit-byte
\  [ tokens ]
   ['] (do-literal)  is do-literal
\   only forth also definitions
;

tokenizer definitions
: set-rev-level  ( revision -- )	\ Sets PCI header rev level field
   h# ffff and rev-level !
;
: last-image  ( -- )	\ Sets indicator byte in PCI header for last image
   h# 80 indicator !
;
: not-last-image  ( -- ) \ Sets indicator byte in PCI header for not last image
   h# 00 indicator !
;
: set-vpd-offset  ( addr -- )	\ Sets VPD offset address in PCI header
   h# ffff and vpd-addr !
;
: set-fcode-offset  ( #bytes -- )	\ Set offset of FCode relative to ROM
   h# ffff and dup h# 3 and  if
      ." Warning: Rounding Fcode offset up for word alignment." cr
      4 + h# fffc and
   then
   dup fcode-offset @ <  if
      ." Warning: Specified FCode offset is too small. "
      ." Using default value of: " fcode-offset @ u. cr
      drop exit
   then
   fcode-offset !		\ header.
;
: pci-header  ( vendor-id device-id class-code -- )	\ Generate ROM header

   \ The device-id and vendor-id should be 2-byte (word) values.
   \ The class-code is a 3-byte value. This method will check that 
   \ the values passed in are not too big, but will not report a
   \ problem if they are too small...

				( vendor-id device-id class-code )
   dup h# ff00.0000 and 0<>  if
      ." Class-code value too large. Must be a 3-byte value!" cr
      2drop drop		(  )
      exit
   then

				( vendor-id device-id class-code )
   over h# ffff.0000 and 0<>  if
      ." Device-id value too large. Must be a 2-byte value!" cr
      2drop drop		(  )
      exit
   then

				( vendor-id device-id class-code )
   rot dup h# ffff.0000 and 0<>  if
      ." Vendor-id value too large. Must be a 2-byte value!" cr
      2drop drop		(  )
      exit
   then

   -rot

   \ Preliminaries out of the way, now to build the header...
   \ First re-arrange stack to get value in order we need them...

				( vendor-id device-id class-code )
   >r				( vendor-id device-id ) ( r: class-code )
   swap				( device-id vendor-id ) ( r: class-code )
   r>				( device-id vendor-id class-code )
   -rot				( class-code device-id vendor-id )

				( class-code device-id vendor-id )
   \ PCI magic number   
   55 emit-byte aa emit-byte	( class-code device-id vendor-id )

   \ Start of FCode
\   34 emit-byte 00 emit-byte	( class-code device-id vendor-id )
   fcode-offset @ wbsplit swap
   emit-byte emit-byte

   \ Skip over reserved bytes
   14 0 do 0 emit-byte loop	( class-code device-id vendor-id )

   \ Start of PCI Data Structure:
   1a emit-byte 00 emit-byte	( class-code device-id vendor-id )

   \ PCIR string
   ascii P emit-byte		( class-code device-id vendor-id )
   ascii C emit-byte		( class-code device-id vendor-id )
   ascii I emit-byte		( class-code device-id vendor-id )
   ascii R emit-byte		( class-code device-id vendor-id )

   \ Now we consume the vendor-id
   wbsplit swap			( class-code device-id vend-hi vend-lo )
   emit-byte emit-byte		( class-code device-id )

   \ Now we consume the device-id
   wbsplit swap			( class-code dev-hi dev-lo )
   emit-byte emit-byte		( class-code )

   \ Now set the VPD pointer
   vpd-addr @ h# ffff and
   wbsplit swap			( class-code vpd.hi vpd.lo )
   emit-byte emit-byte		( class-code )			\ 2 VPD

   18 emit-byte 00 emit-byte	( class-code )			\ 2 DS len
   00 emit-byte			( class-code )			\ 1 rev

   \ Now we consume the class-code
   lwsplit swap			( class-up class-lo )
   wbsplit swap			( class-up class-lohi class-lolo )
   emit-byte emit-byte		( class-up )
   wbsplit swap			( class-uphi class-uplo )	
   emit-byte drop		( )

   \ Now finish off the header
   
   10 emit-byte 00 emit-byte	( )	\ image len, will be fixed later
   rev-level @ wbsplit swap	( rev.hi rev.lo )
   emit-byte emit-byte		( )			\ 2 rev of code
   01 emit-byte                 ( )			\ 1 code type
   indicator @ h# ff and	( indicator )
   emit-byte	                ( )			\ 1 indicator
   00 emit-byte 00 emit-byte	( )			\ 2 reserved

   \ We just "know" that we have so far put out 0x32 bytes

   fcode-offset @ h# 32 -	( padding )

   0 ?do
      h# ff emit-byte
   loop				( )
;

also tokens definitions
alias  pci-header        pci-header
alias  set-rev-level     set-rev-level
alias  set-vpd-offset    set-vpd-offset
alias  set-fcode-offset  set-fcode-offset
previous definitions

tokenizer definitions

: Fcode-version1 ( -- )
   [ tokens ] Fcode-version1 [ tokenizer ]
;
: Fcode-version2 ( -- )
   [ tokens ] Fcode-version2 [ tokenizer ]
;
: Fcode-version3 ( -- )
   [ tokens ] Fcode-version3 [ tokenizer ]
;

: .tokenize-error ( -- )
   true abort" Fcode-version# should be the first FCode command!"
;

only forth also tokenizer also forth definitions

d# 100 buffer: output-name-buf

\ Remove the filename extension if there is one in the last pathname component
: ?shorten-name	 ( input-file$ -- file$ )
   2dup			   ( adr len  adr len )
   begin  dup  while	   ( adr len  adr len' )
      1-  2dup + c@  case  ( adr len  adr len' )
	 \ Stop if we encounter "/" or "\" before a "."
	 ascii /  of	    2drop exit	endof
	 ascii \  of	    2drop exit	endof
	 ascii .  of  2swap 2drop exit	endof
      endcase
   repeat		   ( adr len  adr len' )
   2drop
;
: synthesize-name  ( input-file$ -- input-file$ output-file$ )
   0 output-name-buf c!
   2dup ?shorten-name  output-name-buf $cat
   " .fc" output-name-buf $cat
   output-name-buf count
;

: check-args  ( input-file$ output-file$ -- )
   2 pick  0=  if
      ." Usage: tokenize input-filename [ output-filename ]" cr
      abort
   then
   dup	0=  if	2drop synthesize-name  then
;

: $begin-tokenizing  ( output-file$ -- )

   2dup outf-len ! outf-name !	\ Save output file name for later re-open
   warning on
   ['] noop   is include-hook
   ['] noop   is include-exit-hook

   only forth also tokenizer also forth definitions
   ['] .tokenize-error is header
   ['] .tokenize-error is do-literal
   silent @ 0=	if
      ." FCode Tokenizer Version 3.0" cr
      ." Copyright (c) 1994 FirmWorks  All Rights Reserved" cr
   then
   silent @  if	 warning off  then

   init-vars
   init-path

   save$3 new-file			       ( )
   aout-header? @  if  write-header  then      ( )

   \ Save the current stack depth
   depth to start-depth
;

: begin-tokenizing  ( "output-filename" -- )  parse-word $begin-tokenizing  ;

: $tokenize  ( input-filename$ output-filename$ -- )
   check-args			    ( input-filename$ output-filename$ )

   2swap 2>r		\ Get the string off the data stack to avoid
			\ confusing the depth check
   $begin-tokenizing

   2r>                              ( input-filename$ )

   ['] included catch  ?dup  if
      .error
      string3 count delete-file drop bye
   then

   [ also tokens ]  end-tokenizing  [ previous ]
;

: tokenize ( -- )  \ input-filename  output-filename
   parse-word parse-word $tokenize
;

tokens definitions
: fcode-end  ( -- )		\ Terminates compile, fixes cheksum 
				\ and length in fcode image
   [ also forth ]

   1 been-there-done-that !	\ Tells "tokenize" not to generate checksums.
				\ This to be backward compatible with old 
				\ sources that end with "end0" instead of 
				\ "fcode-end"
   end0

   [ also tokenizer ]

   adjust-file-numbers
;

: pci-header-end  ( -- )	\ Fixes up PCI header with correct length count

   [ also tokenizer ]
   [ also forth ]

   \ First we *know* that our "PCIR" string starts 0x1a Bytes into the
   \ the ROM image file. We also know that our PCI header is 0x18 bytes
   \ long. Our Fcode image is going to be dropped in, word alinged after
   \ that, so the short version is, the FCode starts at offset 0x34 on 
   \ images Firmworks generates.

   \ In the FCode image, the length field is at offset 6 & 7, hi byte in
   \ 6, lo byte is 7. So Finally, what need to get are bytes 0x3a and 0x3b

\   h# 3a
   fcode-offset @ 4 +
   ofd @ fseek					\ Position file to Fcode size
   ofd @ fgetc		( len.hi )		\ Read hi
   ofd @ fgetc swap	( hm hi )		\ Read hi-mid
   ofd @ fgetc		( hm hi lm )		\ Read lo-mid
   ofd @ fgetc swap	( hm hi lo lm )		\ Read lo
   2swap bljoin		( fcode-len )		\ Merge
\   h# 34 +		( image-len )		\ PCI header is 52 bytes long
   fcode-offset @ +	( image-len )
   d# 512 +		( image-len+ )		\ Round up for following div
   d# 512 /		( #of512blks )		\ Number of 512 byte blocks
   dup ." Adjusting for: " . ."  Blocks" cr
   wbsplit swap		( hi lo )

   \ Length field of *our* PCI headers lives at offsets 0x2a and 0x2b

   h# 2a patch-byte	( hi )		\ Punch the PCI Header length.lo field

   h# 2b patch-byte	(  )		\ Punch the PCI Header length.hi field
;

: pci-end  ( -- )  pci-header-end ;

only forth also tokenizer also forth definitions

\ Make the following variables available in vocabulary forth
alias silent	      silent
alias silent?	      silent
alias append-label?   append-label?
alias aout-header?    aout-header?
alias offset-8?	      offset-8?

only forth definitions

fload ${BP}/ofw/fcode/detokeni.fth	\ Detokenizer
only forth definitions
"   No new words defined yet." $create
