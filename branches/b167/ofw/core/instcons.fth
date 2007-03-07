\ ========== Copyright Header Begin ==========================================
\ 
\ Hypervisor Software File: instcons.fth
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
id: @(#)instcons.fth 2.27 04/02/03
purpose: Select and install console I/O devices
copyright: Copyright 1990-2004 Sun Microsystems, Inc.  All Rights Reserved
copyright: Use is subject to license terms.

headers
" keyboard" d# 32  config-string input-device
" screen"   d# 32  config-string output-device

variable prev-stdin

headerless
: report-fb  ( -- )
   'fb-node token@  origin <>  if            ( phandle )
      'fb-node token@  " screen" 2dup aliased?  if  ( phandle name$ alias$ )
	 \ There is already an alias called screen
	 2drop 3drop                                (  )
      else                                          ( phandle name$ alias$ )
	 2drop make-node-alias                      (  )
      then
   then
;

headers
: install-console  ( -- )
   report-fb

   \ Switch to romvec I/O and use ttya at first.
   fallback-device io  console-io

   \ Open NVRAM output-device as the output device
   output-device output

   \ Open NVRAM input-device as the input device
   stdin @  prev-stdin !  input-device  input

   prev-stdin @ stdin @  =   input-device " keyboard" $=   and  if
      \ NVRAM input-device was keyboard but could not open it.

      output-device " screen"   $=  stdout @ 0<>  and  if

         ." Keyboard not present.  Using "  fallback-device type
         ."  for input and output." cr

         \ Give the user time to see the message before the screen goes blank
         d# 4.000 ms
      then
      fallback-device io
   then

   \ Fail-safe in case of bad input or output device
   stdin  @  0=  if  fallback-device input   then
   stdout @  0=  if  fallback-device output  then
;
