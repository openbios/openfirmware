\ ========== Copyright Header Begin ==========================================
\ 
\ Hypervisor Software File: loadfb.fth
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
id: @(#)loadfb.fth 3.14 00/07/25
purpose: Load file for terminal emulator and framebuffer packages
copyright: Copyright 1990-2000 Sun Microsystems, Inc.  All Rights Reserved

\ Load file for frame buffer support packages
decimal

fload ${BP}/ofw/termemu/datatype.fth

headers
dev /packages
   new-device
      " terminal-emulator" device-name
      0 0  encode-bytes  " iso6429-1983-colors"  property

      fload ${BP}/ofw/termemu/framebuf.fth \ Variables used by most framebufs
      fload ${BP}/ofw/termemu/font.fth     \ Character font
      fload ${BP}/ofw/termemu/fwritstr.fth \ ANSI terminal emulator
   finish-device
device-end

[ifdef] include-fb1
fload ${BP}/ofw/termemu/fb1.fth		\ Generic 1-bit raster ops
[then]

fload ${BP}/ofw/termemu/fb8.fth		\ Generic 8-bit raster ops

headers
fload ${BP}/ofw/termemu/install.fth	\ Install terminal emulator
