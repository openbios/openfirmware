\ ========== Copyright Header Begin ==========================================
\ 
\ Hypervisor Software File: deblock.fth
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
purpose: Convert byte-oriented storage access to block-oriented ones
copyright: Copyright 1990-1994 Sun Microsystems, Inc.  All Rights Reserved

\ Block-to-byte conversion package using the Forth file system code to
\ do the deblocking.  Creates a file type which accesses the underlying
\ block device and opens a file descriptor for a file of that type.
\ The file descriptor is stored in the "my-data" field of the instance
\ record.  The "fid" field of file descriptor contains the address of
\ the private data for this device instance.

headerless
decimal

" /packages" find-device
new-device

0 invert 1 >> constant maxint	\ Assumes 2's complement, I suppose

0 instance value block#         \ Internal state; holds offset from last seek
0 instance value buffer         \ Buffer we use for file I/O
0 instance value bufsize 	\ Size of buffer
0 instance value blocksize	\ Sector size of underlying device
0 instance value #blocks	\ The maximum number of blocks on the device
/fd instance buffer: deblock-fd

\ Closes an open file, freeing its descriptor for reuse.

: block-fclose  ( fid -- )
   drop   buffer  if
      buffer  bufsize " dma-free" ['] $call-parent catch  if
         \ If dma-free method doesn't exist, we fall back on the
         \ system free-virtual function.  This is a hack, and can
         \ probably be eliminated in future systems.
         4drop  buffer bufsize free-virtual
      then
   then
;

\ Reduce #blocks if necessary to ensure that block# + #blocks does not
\ exceed the size of the device.

: clip-#blocks  ( block# #blocks -- block# #blocks' )
   #blocks  if                   ( block# #blocks )
      over +  #blocks umin       ( block# top-block# )
      over -                     ( block# #blocks' )
   then
;

\ Writes "count" bytes from the buffer at address "adr" to a file.
\ Returns the number of bytes actually written.

: block-fwrite  ( adr #bytes fid -- #written )
   drop  block#                  ( adr #bytes block# )
   swap blocksize  /             ( adr #blocks block# )
   clip-#blocks                  ( adr block# #blocks' )
   " write-blocks" $call-parent  ( actual-#blocks )
   blocksize *                   ( #bytes-written )
;

\ Reads at most "count" bytes into the buffer at address "adr" from a file.
\ Returns the number of bytes actually read.

: block-fread  ( adr #bytes fid -- #read )
   drop  block#                  ( adr #bytes block# )
   swap blocksize  /             ( adr block# #blocks )
   clip-#blocks                  ( adr block# #blocks' )
   " read-blocks" $call-parent   ( actual-#blocks )
   blocksize  *                  ( #bytes-read )
;


\ Positions to byte number "d.byte#" in a file

: block-fseek  ( d.byte# fid -- )
   drop  blocksize um/mod nip        ( block# )
   #blocks  if  #blocks umin  then   ( block#' )
   to block#
;


\ Returns the current size "d.size" of a file

: block-fsize  ( fid -- d.size )
   drop                                             ( )
   " current-#blocks" ['] $call-parent catch  if    ( x x )
      2drop                                         ( )
      #blocks  if  #blocks blocksize um*  else  -1 maxint  then  ( d.size )
   else                                             ( #blocks )
      blocksize um*                                 ( d.size )
   then
;


\ Aligns a number to a block boundary.

: block-falign  ( d.byte# fid -- d.aligned-byte# )
   drop  blocksize um/mod nip  blocksize um*
;

: block-size    ( -- n )
   " block-size"  ['] $call-parent catch  if  2drop d# 512  then
;

: buffer-size  ( -- n )
   " max-transfer"  ['] $call-parent catch  if  2drop  h# 1.0000  then  ( max )

   \ For fixed-length devices, block-size is greater than 1.  In that
   \ case, we use a buffer that is at least the size of a block, and
   \ preferably somewhat larger, to avoid blowing disk revs.  We don't
   \ want it to be too large though, or we will lose performance when
   \ accessing files, which may require accessing relatively-small index
   \ or directory blocks.
   \ For variable-length devices, block-size is 1.  In that case, we
   \ use a buffer the size of max-transfer.  If we use a smaller one,
   \ the device may try to map too much space.
   block-size 1 >  if  h# 4000 min  block-size max  then
;

headers
\ Externally-visible routines follow.

" deblocker" device-name

\ This property indicates that bug 1074409 has been fixed.
\ If this property is not present, client programs must install a patch.
0 0 " disk-write-fix" property

: open  ( -- okay? )

   0 to block#                          ( )
   0 to buffer                          ( )

   block-size   to blocksize            ( )
   buffer-size  to bufsize              ( )

   bufsize  " dma-alloc"                ( size adr len )
   ['] $call-parent  catch  if          ( x y z )
      3drop  bufsize allocate-dma       ( dma-addr|0 )
      dup 0=  if  exit  then            ( dma-addr )
   then                                 ( dma-addr )
   to buffer                            ( )

   " #blocks" ['] $call-parent  catch  if  ( x x )
      2drop
   else                                 ( true | n false )
      to #blocks                        ( )
   then


   file @ >r  deblock-fd file !         ( )

   buffer  bufsize  initbuf             ( )

   my-self  modify                      ( fid mode )
   ['] block-fsize   ['] block-falign   ( fid mode ops.. )
   ['] block-fclose  ['] block-fseek    ( fid mode ops.. )
   ['] block-fwrite  ['] block-fread    ( fid mode ops.. )
   setupfd                              ( )

   true                                 ( true )
   r> file !
;

: size  ( -- size.low size.high )
   deblock-fd  ['] dfsize catch  if  drop 0 0  then
;
: position  ( -- offset.low offset.high -- )
   deblock-fd  ['] dftell catch  if  drop 0 0  then
;
: seek   ( offset.low offset.high -- error? )
   deblock-fd  ['] dfseek catch  if  3drop true  else  false  then
;
: read   ( adr len -- actual-len )
   deblock-fd  ['] fgets catch  if  3drop 0  then
;
: write  ( adr len -- actual-len )
   tuck  deblock-fd  ['] fputs catch  if  4drop -1  then
;
: close  ( -- )
   deblock-fd ['] fclose catch  ?dup  if  .error drop  then
;

finish-device
device-end
