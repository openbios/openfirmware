\ ========== Copyright Header Begin ==========================================
\ 
\ Hypervisor Software File: loaddevt.fth
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
purpose: Load file for basic Open Firmware functionality
copyright: Copyright 1990-2004 Sun Microsystems, Inc.  All Rights Reserved
copyright: Use is subject to license terms.


fload ${BP}/ofw/core/standini.fth	\ S The first definition of stand-init
fload ${BP}/ofw/core/sysintf.fth	\ Interfaces to system functions

fload ${BP}/ofw/core/execbuf.fth	\ execute-buffer chain

headers

fload ${BP}/ofw/core/diagmode.fth

\ Create the options vocabulary.  Later, it will become the property
\ list of "options" node in the device tree.

vocabulary options

\ Make the options vocabulary a permanent part of the search order.

only forth also root also definitions
: fw-search-order  ( -- )  root also options also  ;
' fw-search-order to minimum-search-order
only forth hidden also forth also definitions

fload ${BP}/ofw/confvar/confact.fth	\ Action names for attribute objects

fload ${BP}/ofw/core/propenc.fth	\ Property encoding primitive

fload ${BP}/ofw/core/devtree.fth	\ Device node creation

fload ${BP}/ofw/core/breadth.fth	\ Device tree search primitives
fload ${BP}/ofw/core/finddev.fth	\ Device tree path lookup
fload ${BP}/ofw/core/testdevt.fth	\ Device tree browsing

fload ${BP}/ofw/core/relinkdt.fth	\ Devtree hooks for "dispose"

fload ${BP}/ofw/core/instance.fth	\ Package ops

fload ${BP}/ofw/core/comprop.fth	\ "Prepackaged" property words

fload ${BP}/ofw/core/finddisp.fth	\ Locate first "display" device

fload ${BP}/ofw/core/sysnodes.fth	\ Standard system nodes

fload ${BP}/ofw/core/console.fth	\ Forth I/O through package routines

fload ${BP}/ofw/core/trace.fth		\ Package tracing tool

fload ${BP}/ofw/core/execall.fth	\ execute-all-methods command

fload ${BP}/ofw/core/siftdevs.fth	\ Sifting through the device tree

fload ${BP}/ofw/core/eject.fth		\ Generic EJECT command

fload ${BP}/ofw/core/malloc.fth		\ Heap memory allocator
fload ${BP}/ofw/core/instmall.fth	\ SI Hack installation
fload ${BP}/ofw/core/msgbuf.fth		\ S init msg-buf

fload ${BP}/ofw/core/memops.fth		\ Call memory node methods
fload ${BP}/ofw/core/mmuops.fth		\ Call MMU node methods

fload ${BP}/ofw/core/alarm.fth		\ Alarm interrupt mechanism

fload ${BP}/ofw/core/clientif.fth	\ Client interface
fload ${BP}/ofw/core/canon.fth		\ "canon" client service
fload ${BP}/ofw/core/deladdr.fth	\ Remove "address" property
fload ${BP}/ofw/core/mapdev.fth		\ Map from devtree node
fload ${BP}/ofw/core/date.fth		\ Date and time formatting
fload ${BP}/ofw/core/fwfileop.fth	\ Forth file access through device tree

fload ${BP}/ofw/core/dropin.fth		\ Dropin drivers
fload ${BP}/ofw/core/dipkg.fth		\ Demand-loading of support packages
[ifdef] include-help
fload ${BP}/ofw/help/txtdecod.fth	\ Help command
fload ${BP}/ofw/help/helpdi.fth		\ Help text in dropin driver format
[else]
fload ${BP}/ofw/help/tinyhelp.fth	\ Brief help command
\ : help  ( -- )
\    " help" find-drop-in  if  'execute-buffer execute  else  basic-help  then
\ ;
[then]

only forth also definitions

hex

fload ${BP}/os/stand/probe.fth          \ Probe, peek, poke
