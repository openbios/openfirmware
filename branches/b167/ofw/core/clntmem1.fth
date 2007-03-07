\ ========== Copyright Header Begin ==========================================
\ 
\ Hypervisor Software File: clntmem1.fth
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
purpose: Implements client interface "claim" and "release"
copyright: Copyright 1994-2003 Sun Microsystems, Inc.  All Rights Reserved
copyright: Use is subject to license terms.

headerless
: (map)  ( size phys virthint mode -- virtual )
   >r                                ( size phys virtual ) ( r: mode )
   ?dup  if                          ( size phys virtual ) ( r: mode )
      over mmu-lowbits  over mmu-lowbits
      <> abort" Inconsistent page offsets"
      2 pick  0  mmu-claim           ( size phys virtual ) ( r: mode )
   else                              ( size phys )         ( r: mode )
      2dup mmu-lowbits +             ( size phys size' )   ( r: mode )
      pagesize  mmu-claim            ( size phys virtual ) ( r: mode )
   then                              ( size phys virtual ) ( r: mode )

   over mmu-lowbits          ( size phys virtual offset )  ( r: mode )
   over mmu-highbits +       ( size phys virtual virtual' )  ( r: mode )
   r> swap >r                ( size phys virtual mode ) ( r: virtual' )
   3 roll  swap  mmu-map     ( )  ( r: virtual' )
   r>                        ( virtual' )
;

: (allocate-aligned)  ( alignment size virthint mode -- virtual )
   2 pick 0=  if  2drop 2drop 0 exit  then
   >r rot >r                  ( size virthint ) ( r: mode align )
   tuck mmu-lowbits + tuck    ( size' virthint size' )  ( r: mode align )
   dup r> 1 max               ( size' virthint size' size' align ) ( r: mode)
   mem-claim                  ( size' virthint size' phys ) ( r: mode )

   \ Now we map in the allocated memory
   swap r>                    ( size' virthint phys size' mode )
   swap >r  over >r  >r       ( size' virthint phys ) ( r: size' phys mode )

   over mmu-lowbits +         ( size' virthint phys' )  ( r: size' phys mode )
   swap                       ( size' phys' virthint )  ( r: size' phys mode )

   r>  ['] (map)  catch  ?dup  if  ( 4*x error-code )   ( r: size' phys )

      \ If the mapping operation fails, we give back the
      \ physical memory that we have already allocated.

      >r 4drop r>             ( error-code )
      r> r> mem-release       ( error-code )
      throw                    \ Propagate the error

   then                       ( virtual )  ( r: size phys )
   2r> 2drop                  ( virtual )
;
: allocate-aligned  ( alignment size virthint -- virtual )
   mem-mode  ['] (allocate-aligned) catch  if  3drop 0  then
;

: ?release-mem  ( phys size -- )
   over memory?  if  mem-release  else  2drop  then
;

headers
also client-services definitions

: claim  ( align size virt -- base )
   rot  dup  if         ( size virt align )
      nip  swap 0       ( align size 0 )
   else
      drop  1 -rot      ( 1 size virt )
   then                 ( align size virthint )
   allocate-aligned     ( base )
;
: release  ( size virt -- )
   swap                        ( virt size )
   over mmu-translate  if      ( virt size phys mode )
      drop over ?release-mem   ( virt size )
   then                        ( virt size )
   2dup mmu-unmap mmu-release  ( )
;

previous definitions

headerless
also client-services
alias cif-release release
alias cif-claim   claim
previous

headers
