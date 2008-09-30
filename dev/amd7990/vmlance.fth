\ ========== Copyright Header Begin ==========================================
\ 
\ Hypervisor Software File: vmlance.fth
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
purpose: Definitions for the VMware PCNET - sort of - virtual ethernet
copyright: Copyright 1995 Sun Microsystems, Inc.  All Rights Reserved

\ Register access

\ The chips that support 32-bit descriptor addresses usually
\ have two modes for accessing the control registers.  In the
\ "normal" word I/O mode, the registers are accessed with 16-bit
\ bus cycles and appear at adjacent 16-bit locations (0x10, 0x12, ...)
\ In double-word I/O mode, they are accessed with 32-bit bus
\ cycles and appear at adjacent 32-bit locations (0x10, 0x14, ...)
\ In either case, they contain only 16 bits of useful data, so
\ there is no real advantage to using 32-bit accesses.
\ The chip determines the mode from the first access cycle, and
\ "locks" into that mode.  The only way to change the mode thereafter
\ is to issue a hardware reset to it; a software reset won't do it.
\ We use 16-bit mode as the default, for the benefit of client programs
\ that use older driver code.

[ifdef] 32-bit-cycles
: >reg  ( offset -- adr )  la swap la+ h# 10 +  ;
: reg@  ( offset --  data )  >reg  rl@  ;
: reg!  ( data offset --  )  >reg  rl!  ;
[else]
: >reg  ( offset -- adr )  la swap wa+ h# 10 +  ;
: reg@  ( offset --  data )  >reg  rw@  ;
: reg!  ( data offset --  )  >reg  rw!  ;
[then]

: rdp!  ( val -- )  0 reg!  ;
: rdp@  ( -- val )  0 reg@  ;

: rap!  ( val -- )  1 reg!  ;
: rap@  ( -- val )  1 reg@  ;

: reset  ( -- )  2 reg@ drop  ;

: bdp!  ( val -- )  3 reg!  ;
: bdp@  ( -- val )  3 reg@  ;

\ Control and Status Register
: csr!  ( value reg# -- )  rap!  rdp!  ;
: csr@  ( reg# -- value )  rap!  rdp@  ;

\ Bus Control Register
: bcr!  ( value reg# -- )  rap!  bdp!  ;
: bcr@  ( reg# -- value )  rap!  bdp@  ;


\ In addition to the 16/32-bit register access, some AMD Ethernet
\ chips allow you to choose 16-bit and 32-bit versions of the
\ descriptor data structures.  Unlike the register access, there
\ is a compelling reason to use the 32-bit data structures, for
\ they contain 32-bit DMA pointers.  The 16-bit data structures
\ use 24-bit DMA pointers, thus restricting DMA to the lower 16 MBytes.

\ Message descriptor access

struct ( message-descriptor )
4 field >addr
2 field >bytecnt
1 field >reserved1
1 field >laflags
0 field >tmd2
2 field >mcnt
0 field >xerrors
1 field >rpc
1 field >rcc
4 field >reserved2
( total-length )  constant /md

/md value /rmd
/md value /tmd

\ Little-endian reads and writes
: lew@  ( addr -- w )  dup c@ swap 1+ c@ bwjoin  ;
: lew!  ( addr w -- )  >r wbsplit r@ 1+ c! r> c!  ;

: lel@  ( addr -- l )  dup lew@ swap 2+ lew@ wljoin  ;
: lel!  ( addr l -- )  >r lwsplit r@ 2+ lew! r> lew!  ;

: dump-regs  ( -- )
   hex la . cr
   h# 80 0  do  i decimal 3 u.r  hex i csr@ 9 u.r  cr loop
;

\ Get virtual address of buffer from message descriptor
: addr@  ( rmd/tmd-vaddr -- buff-vaddr )  >addr lel@  devaddr>  ;

\ gets length of incoming message - receive only
: length@  ( rmdaddr -- messagelength )  >mcnt lew@  ;

\ gets transmit errors - transmit only
: xerrors@  ( tmdaddr -- errorsflag )
   >xerrors lew@ dup rtry and 0= if    \ mask TDR unless RTRY set
      h# fc00 and
   then
;

\ Store buffer address into message descriptor
\ The message descriptor must have a DMA address in it because
\ the chip reads it.
: addr!  ( buff-vaddr  rmd/tmd-vaddr -- )  swap >devaddr swap  >addr lel!  ;

\ Set length of message to be sent - transmit only
: length!  ( length rmd/tmd-addr -- )  swap negate swap  >bytecnt lew!  ;

\ Clear transmit error flags
: clear-errors  ( tmd-addr -- )  0 swap  >xerrors lew!  ; 


\ Initialization

\ Initialization

h# 40 constant /ib

\ Tool for storing and incrementing
: ,,  ( addr val -- addr' )  over lew! wa1+  ;

: mac-addr,,  ( ibaddr buf -- ibaddr' )
   3 /w*  bounds  do  i lew@  ( wbflip )  ,,  /w +loop
;

: init-setup  ( -- )
   ib				( addr )
   mode @  ,,			\ Mode
   h# 0  #rmdsfactor 4 lshift or  ,,  \ TLEN(2^0 = 1) and RLEN

   this-en-addr mac-addr,, 0 ,,	\ Physical Ethernet Address
   0 ,, 0 ,, 0 ,, 0 ,,  	\ Logical Address Filter
   rmd0 >devaddr lwsplit	\ Receive Descriptor Ring Pointer
   >r ,, r> ,,               	\ Put in low word and high word
   tmd0 >devaddr lwsplit	\ Transmit Descriptor Ring Pointer
   >r ,, r> ,,               	\ Put in low word
   drop

   stopb 0 csr!
   2 d# 58 csr!    \ 32-bit descriptor mode

   ib >devaddr lwsplit 2 csr!  1 csr!
;

: wait-init  ( -- flag )	\ true if init succeeds
   initb 0 csr!		\ rap is now 0, so we can use rdp@ and rdp! below.
   false
   300 0  do  rdp@ idon and  if  drop true leave  then  loop  ( okay? )
   dup  if
\      idon rdp!		\ XXX may cause a problem
   else
      ." Ethernet chip initialization failed"
   then
;

\ Initialize the Lance chip
: lance-init  ( -- flag )		\ true if init succeeds
   0 rdp!		\ Write to RDP to set the access mode
   				\ We are just hoping that there are no
				\ side effects of this write.

   init-setup  wait-init  dup if		( flag )
      h# 100 0 csr!  \ Ack the init done int	( flag )
      strt   0 csr!  \ go 			( flag )
   then						( flag )
;

: dr  ( n -- )  dup decimal 3 u.r hex ." : " csr@ 5 u.r 3 spaces ;
base @ decimal
\ 6 7 
: dumpregs  ( -- )
   0 csr@ 2 and if  stopb 0 csr!  then
   0 dr 1 dr 2 dr 3 dr  cr
   4 dr 5 dr 8 dr 8 dr  cr
   9 dr 10 dr 11 dr 12 dr cr
  13 dr 14 dr 15 dr cr
  24 dr 25 dr  30 dr 31 dr cr
  58 dr 76 dr 77 dr cr
  80 dr 82 dr 88 dr 89 dr cr
  112 dr 124 dr cr
;
base !

\ Restore the chip to its default modes for the benefit of client programs
: lance-uninit  ( -- )		\ Call from close, after setting STOP
   reset		\ Issue software reset
   h#  200  d# 20 bcr!	\ Restore default "PCnet-ISA" programing interface
   h#  200  d# 58 csr!	\ Restore default "PCnet-ISA" programing interface
   h# 9060  d# 18 bcr!	\ Re-enable burst modes
         2      2 bcr!	\ Re-enable auto-selection of media
;
