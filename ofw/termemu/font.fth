\ ========== Copyright Header Begin ==========================================
\ 
\ Hypervisor Software File: font.fth
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
purpose: FCode interface to default font
copyright: Copyright 1990 Sun Microsystems, Inc.  All Rights Reserved

decimal
headers
0 termemu-value font-base		\ Base address of font

0 termemu-value char-width		\ FCode character width in pixels
0 termemu-value char-height		\ FCode character height in pixels (scan lines)
0 termemu-value fontbytes		\ FCode distance in bytes from one scan line of
					\ a glyph to the next
0 termemu-value glyph-bytes		\ distance between glyphs
headerless
0 termemu-value min-char		\ The lowest character in the font
0 termemu-value #glyphs			\ The number of glyphs in the font

headers
defer font
' romfont is font

headerless
: decode-font  ( hdr-adr -- bits-adr width height advance min-char #glyphs )
   dup d# 24 + swap          ( bits-adr hdr-adr )
   d# 24                     ( bits-adr hdr-adr hdr-len )
   4 decode-bytes  " font"  $=  0= abort" Not a font"  ( bits-adr str )
   5 0 do  decode-int -rot  loop  ( bits-adr width height advance min #gl str )
   2drop                     ( bits-adr width height advance min-char #glyphs )
;
headers
also forth definitions
\ There are no glyphs for control characters, so the font bitmaps actually
\ begin with the glyph for the space (blank) character.

\ The 1- after char-height is due to the way that the PROM stores character
\ bitmaps.  Since the top and bottom scan lines of the character are both 0,
\ only  char-height 1-  scan-lines are actually stored, and the bottom zero
\ scan line of a glyph is overlapped with the top zero scan line of the
\ next glyph.  This is probably a bad idea in the long run.

: >font  ( char -- adr )					\ FCode
   min-char -  0 max  #glyphs min   ( char# )	\ Clip the glyph number
   glyph-bytes * font-base +
;

headerless
: character-set ( -- )
   " character-set"  2dup get-my-property  if  ( adr,len )
      " ISO8859-1" encode-string 2swap  property   (  )
   else                                         ( adr,len adr,len' )
      2drop 2drop                               (  )
   then                                         (  )
;
headers
: default-font  ( -- adr width height advance min-char #glyphs ) \ FCode
   character-set  font decode-font
;

: set-font  ( adr width +-height advance min-char #glyphs -- )	\ FCode
   is #glyphs  is min-char
   is fontbytes
   dup >r abs is char-height  is char-width  ( r: +-height )
   is font-base

   \ If +-height is positive, then we use the original packed font
   \ storage format in which the last scan line of one glyph overlaps
   \ the first scan line of the next.  If +-height is negative, we
   \ use an unpacked format in which each glyph is self-contained.
   r>  dup 0>  if  1-  else  negate  then  fontbytes *  to glyph-bytes
;
previous definitions
