\ ========== Copyright Header Begin ==========================================
\ 
\ Hypervisor Software File: regbits.fth
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
purpose: Generic LANCE register bits
copyright: Copyright 1995 Sun Microsystems, Inc.  All Rights Reserved

\ Common code

hex
headers

\ Control/Status Register Bits	(CSR0)
  01 constant initb     02 constant strt
  04 constant stopb     08 constant tdmd
  10 constant txon      20 constant rxon
  40 constant inea      80 constant intrp
 100 constant idon     200 constant tint
 400 constant rint     800 constant merr
1000 constant miss    2000 constant cerr
4000 constant babl    8000 constant err

\ CSR3 bits
  01 constant bcon   02 constant acon   04 constant bswp

\ Mode Register Bits	(CSR15)
  01 constant drx       02 constant dtx
  04 constant lpbk      08 constant dxmtfcs
  10 constant fcoll     20 constant drty
  40 constant intl    8000 constant prom

\ Message Descriptor Bits ( use a byte access with these bits )
   1 constant enp        2 constant stp
  10 constant ltint	\ '971 extension: Interrupt after loopback transmit
  40 constant mser      80 constant own

\ Receive Message Descriptor Bits ( use a byte access )
   4 constant buff       8 constant crc
  10 constant oflo      20 constant fram

\ Transmit Message Descriptor Bits (use a byte access )
   4 constant def        8 constant one-err
  10 constant more-errs
def one-err or more-errs or   constant retries

\ Value to write to message descriptor to enable it for use
enp stp or own or ltint or   constant ready

\ TMD3 Bits
 400 constant rtry
 800 constant lcar
1000 constant lcol
4000 constant uflo
8000 constant xbuf

decimal
