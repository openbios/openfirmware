\ ========== Copyright Header Begin ==========================================
\ 
\ Hypervisor Software File: lancevar.fth
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
purpose: Variables for AMD7990 Ethernet driver
copyright: Copyright 1994 Firmworks  All Rights Reserved

headers

6 buffer: macbuf

\ Virtual addresses within the DMA buffer area.
\ The actual addresses will be assigned later

0 instance value dma-base
0 instance value ib     \ initialization block
0 instance value tmd0   \ transmit message descriptor#0
0 instance value rmd0   \ receive message descriptor#0
0 instance value tbuf0  \ transmit buffer#0
0 instance value rbuf0  \ receive buffer#0

0 instance value #rmds
0 instance value /rmds

0 instance value lance-dma-size	\ Amount of memory mapped
0 instance value dma-offset	\ virtual-address minus dma-address
: >devaddr  ( virt -- devaddr )  dma-offset -  ;
: devaddr>  ( devaddr -- virt )  dma-offset +  ;

instance variable mode		\ Chip mode - loopback, etc

6 instance buffer: this-en-addr	\ Station address

\ *** buffer sizes and counts ***

d# 1600 constant /rbuf  \ receive buffer size

d# 1700 value /tbuf     \ transmit buffer size

true value tp?		\ True to use twisted pair (10BASE-T)

\ I/O base address of the lance.  The actual address will be assigned later.
0 value la
