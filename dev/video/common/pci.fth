\ See license at end of file
purpose: PCI Methods

\ PCI access code.
\ This code is used to determine which controller is present and
\ to begin the process of sorting out which specific words are to
\ be plugged into the various defered words. Also, and just as important,
\ the REG property gets formed here.

hex
headers

3 instance value pci-ver
: .driver-info  ( -- )
   .driver-info
   pci-ver . ." PCI Code version" cr
;

false instance value needs-legacy?

struct
   04 field >physlo	\ phys.lo address
   04 field >physmid	\ phys.mid address
   04 field >physhi	\ phys.hi address
   04 field >hiflag	\ phis.hi modifiers (n/p/t... bits)
   04 field >size1	\ First size
   04 field >size2	\ Second size
   04 field >reg#	\ PCI Base address register offset (10,14,18...)
constant /array

0 instance value reg-props			\ Pointer for temp storage
0 instance value tpoint				\ A second pointer
d# 50 /array * instance value /reg-props	\ Allocate 50 entries for now

/reg-props alloc-mem to reg-props		\ Allocate some memory
reg-props /reg-props erase			\ Clean it up

: >reg-props  ( phys.[lo,mid,hi] hi.flag size size -- )

   reg-props /array - to tpoint   
   begin
      tpoint /array + to tpoint
      tpoint >physhi l@ 0=
   until				\ tpoint now points to first empty slot

			( phys.[lo,mid,hi] hi.flag size size reg# )
   tpoint >reg# l!	( phys.[lo,mid,hi] hi.flag size size )
   tpoint >size2 l!	( phys.[lo,mid,hi] hi.flag size )
   tpoint >size1 l!	( phys.[lo,mid,hi] hi.flag )
   tpoint >hiflag l!	( phys.[lo,mid,hi] )
   tpoint >physhi l!	( phys.lo phys.mid )
   tpoint >physmid l!	( phys.lo )
   tpoint >physlo l!	( )
;

: 0m  ( -- 0 my-space )  0 my-space  ;

: s3-common-regs  ( -- )
   h# 2e8  0m a100.0000 0 4 0  >reg-props
;

: legacy-regs  ( -- )
      h# 3b0 0m h# a100.0000 0 h# C  0 >reg-props
      h# 3c0 0m h# a100.0000 0 h# 20 0 >reg-props
      h# a.0000 0m h# a200.0000 0 h# 2.0000 0 >reg-props
;
   
0 instance value mask-val			
0 instance value fb-base-reg

: munge-map-size  ( raw -- new )	\ Makes a proper map-size argument
   dup 0=  if  exit  then

   1 to mask-val		\ Basically, just walk a one up mask-val value,
   begin			\ anding all the way looking for first non-zero
      mask-val 2 * to mask-val	\ bit. If chip is working correctly, first non
      dup mask-val and 0 <>	\ zero bit location tells you how big a 
   until			\ map-size you need.
   drop
   mask-val
;

: get-map-size  ( reg# -- map-size )	\ Returns the amount of memory required
   >r r@ c-l@		( old-val )	\ Get old value
   -1 r@ c-l!		( old-val )	\ Write all ones
   r@ c-l@ 		( old-val raw )	\ Read back
   ff invert and	( old-val raw ) \ Mask off low bits
   swap r> c-l!		( raw )		\ Put old value back
   munge-map-size	( map-size )	\ Mask off high bits
;

: add-arc-ident  ( adr len -- )
   encode-string " arc-identifier" property
;

: determine-controller  ( -- )	\ Determines which PCI controller we have
   0 c-w@	( id )		\ PCI ID now on stack

   case		( id )		\ First we figure out which chip set...
      h# 5333 of       s3 to chip   endof
      h# 1013 of   cirrus to chip   endof
      h# 102b of      mga to chip   endof
      h# 3d3d of    glint to chip   endof
      h# 100e of   weitek to chip   endof
      h# 105d of       n9 to chip   endof
      h# 102c of       ct to chip   endof
   endcase	( )

   2 c-w@ ff and	( version )

   s3?  if		\ If card is S3 based, sort out the various controllers
      use-s3-words		\ Select our controller methods
      dup case			\ Look for known ID values...
         b0 of s3-928  " S3_928" add-arc-ident  endof
         d0 of s3-964  " S3_964" add-arc-ident  endof
         d1 of s3-964  " S3_964" add-arc-ident  endof
         c1 of s3-864  " S3_864" add-arc-ident  endof
         c0 of s3-864  " S3_864" add-arc-ident  endof
         80 of s3-868    endof
         f0 of s3-968    endof
         11 of s3-trio64 endof
         31 of s3-virge  endof
         ( default ) -1 swap	\ Well, maybe we can't program it...
      endcase
      to variant
   then			( version )

   cirrus?  if			\ Cirrus based, sort out various controllers
      use-cirrus-words		\ Cirrus stuff is inside S3 code      
      " CL54xx" add-arc-ident
      dup case			\ Look for known ID values.
         b8 of gd5434 endof     \ Actually gd5446, but gd5434 is close enough
         a8 of gd5434 endof
         a0 of gd5430 endof
         ac of gd5436 endof
         ( default ) -1 swap	\ Well, maybe we can't program it...
      endcase
      to variant
   then			( version )

   mga?  if			\ Matrox board, verify Storm based.
      use-mga-words		\ Select controller methods
      dup case
         19 of storm endof
         ( default ) -1 swap	\ Well, maybe we can't program it...
      endcase
      to variant
   then

   glint?  if			\ Glint based, be sure it is 300SX based.
      use-glint-words		\ Select controller methods
      dup case
         1 of 300sx endof
         ( default ) -1 swap	\ Well, maybe we can't program it...
      endcase
      to variant
   then

   weitek?  if			\ Weitek based board, be sure it is P9100
      use-weitek-words		\ Select controller methods
      " P9100" add-arc-ident
      2 c-w@ case
         9100 of p9100 endof
         ( default ) -1 swap
      endcase
      to variant
   then

   n9?  if			\ Only Number nine chip so far...
      use-i128-words
      i128 to variant
   then

   ct?  if			\ Chips and Technology
      use-ct-words
      dup case
         e0 of ct6555x endof
         e4 of ct6555x endof
         e5 of ct6555x endof
         ( default ) -1 swap
      endcase
      to variant
   then

   drop			( )

   variant -1 <> to safe?	\ If varient is <> -1, then we know what it is.
;

determine-controller		\ First we find out who made it...

headers

: .vid-info  ( -- )		\ Prints out what the driver thinks it knows

   ." Controller       : "
   s3?  if  ." S3" cr  then
   cirrus?  if  ." Cirrus" cr  then
   mga?  if  ." MGA" cr  then
   glint?  if  ." Glint" cr  then
   weitek?  if  ." Weitek" cr  then
   ct?  if  ." Chips and Technology" cr  then

   s3?  if
      ." Controller Type  : "
      s3-928?  if  ." 928" cr  then
      s3-964?  if  ." 964" cr  then
      s3-864?  if  ." 864" cr  then
      s3-868?  if  ." 868" cr  then
      s3-968?  if  ." 968" cr  then
      s3-trio64?  if  ." Trio" cr  then
      s3-virge?  if  ." ViRGE" cr  then
   then
;

: reg-entry  ( map reg size -- )
   >r >r >r
   0 0 my-space
   r> r> + +
   encode-phys encode+
   0 encode-int encode+ r> encode-int encode+
;

: add-rom-regs  ( -- )
   \ If this driver is used for an on board frame buffer, the builtin.fth
   \ file for that platform should declare a "no-rom" property in the node 
   \ where this driver is used. This will prevent the reg property from 
   \ including an entry for a non-existent ROM

   " no-rom" get-my-property 0=  if
      2drop exit
   then

   h# 30 get-map-size  if
      0 0m h# 200.0030 0 h# 30 get-map-size h# 30 >reg-props \ ROM
   then
;

: encode-reg-property  ( -- )

   cirrus?  if
         0 0m h# 200.0010 0 h# 10 get-map-size h# 10 >reg-props	\ Frame buffer
         add-rom-regs
         legacy-regs
   then

   s3?  if

      s3-928? s3-964? or s3-864? or s3-868? or if
         h# 000.0000 0m 200.0010 0 h# 100.0000 10 >reg-props	\ Frame buffer
         add-rom-regs
         legacy-regs
         h#  102 0m a100.0000 0 1 0  >reg-props		\ Non-relocatable regs
         s3-common-regs
      then

      s3-968?  if
         h# 000.0000 0m 200.0010 0 h# 100.0000 10 >reg-props \ LE frame buffer
         h# 200.0000 0m 200.0010 0 h# 100.0000 10 >reg-props \ BE frame buffer
         h# 100.0000 0m 200.0010 0 h# 1.80a0 10 >reg-props   \ LE MMIO regs
         h# 300.0000 0m 200.0010 0 h# 1.80a0 10 >reg-props   \ BE MMIO regs

         add-rom-regs

         legacy-regs
         h#  102 0m a100.0000 0 1 0  >reg-props		\ Non-relocatable regs
         s3-common-regs
      then

      \ Older trio chips do not have all of these regs. However, there appears
      \ to be few of those out there and most everyone has shifted to trio64V+
      \ which does have all these regs. If someone really needs it fixed, we 
      \ can deal with it later. The problem is that at this point in the 
      \ process, we can't tell if it is a V+ or not because S3 did not change 
      \ the PCI ID values. You can only tell the difference *after* the chip 
      \ has been turned on, and then read the crt-reg 2F. 0x80 means a V+. 
      \ UUGH!

      s3-trio64? s3-virge? or  if
         h# 000.0000 0m 200.0010 0 h# 100.0000 10 >reg-props \ LE frame buffer
         h# 200.0000 0m 200.0010 0 h# 100.0000 10 >reg-props \ BE frame buffer
         h# 100.0000 0m 200.0010 0 h# 1.80a0 10 >reg-props   \ LE MMIO regs
         h# 300.0000 0m 200.0010 0 h# 1.80a0 10 >reg-props   \ BE MMIO regs

         add-rom-regs

         h# a8000 0m a200.0000 0 6900 0 >reg-props	\ MMIO regs
         legacy-regs
         h# 102 0m a100.0000 0 1 0 >reg-props	\ Unique non-relocateable IO
         s3-common-regs				\ Common non-relocateable IO
      then
   
   then

   glint?  if
      0 0m h# 200.0018 0 h# 18 get-map-size h# 18 >reg-props	\ Frame Buffer
      0 0m h# 200.0010 0 h# 10 get-map-size h# 10 >reg-props	\ IO base
      0 0m h# 200.0014 0 h# 14 get-map-size h# 14 >reg-props	\ Local Buffer
      \ Can't actually probe 1c, set = 14
      0 0m h# 200.001c 0 h# 14 get-map-size h# 1c >reg-props
      \ Can't actually probe 20, set = 18
      0 0m h# 200.0020 0 h# 18 get-map-size h# 20 >reg-props
      add-rom-regs
   then
   

   mga?  if
      0 0m h# 200.0014 0 h# 14 get-map-size h# 14 >reg-props	\ Frame Buffer
      0 0m h# 200.0010 0 h# 10 get-map-size h# 10 >reg-props	\ IO
      add-rom-regs
      legacy-regs
   then

   weitek?  if
      0 0m h# 200.0010 0 h# 10 get-map-size h# 10 >reg-props	\ Memory
      add-rom-regs
      legacy-regs
      h# 102 0m a100.0000 0 1 0 >reg-props	\ Unique non-relocateable IO
      s3-common-regs
   then

   i128?  if
      0 0m h# 200.0010 0 h# 10 get-map-size h# 10 >reg-props	\ Base 0
      0 0m h# 200.0014 0 h# 14 get-map-size h# 14 >reg-props	\ Base 1
      0 0m h# 200.0018 0 h# 18 get-map-size h# 18 >reg-props	\ Base 2
      0 0m h# 200.001c 0 h# 1c get-map-size h# 1c >reg-props	\ Base 3
      0 0m h# 200.0020 0 h# 20 get-map-size h# 20 >reg-props	\ Base 4
      0 0m h# 100.0024 0 h# 24 get-map-size h# 24 >reg-props	\ Base 5
      add-rom-regs
   then

   ct?  if
      0 0m h# 200.0010 0 h# 10 get-map-size h# 10 >reg-props	\ Frame buffer
      add-rom-regs
      legacy-regs
   then

   \ Now we build reg entry up

   my-address my-space encode-phys 0 encode-int encode+ 0 encode-int encode+

   reg-props to tpoint
   begin
      tpoint >physhi l@ 0<>  if
         tpoint >physlo l@		( phys.lo )
         tpoint >physmid l@		( phys.lo phys.mid )
         tpoint >physhi l@		( phys.lo phys.mid phys.hi )
         tpoint >hiflag l@ or		( phys.lo phys.mid phys.hi )
         encode-phys encode+
         tpoint >size1 l@		( size )
         encode-int encode+
         tpoint >size2 l@		( size )
         encode-int encode+
         tpoint /array + to tpoint
         false
      else
         true
      then
   until

   " reg" property

   reg-props /reg-props free-mem		\ Release the tempory buffer
;

encode-reg-property			\ Build the reg property now



\ LICENSE_BEGIN
\ Copyright (c) 2006 FirmWorks
\ 
\ Permission is hereby granted, free of charge, to any person obtaining
\ a copy of this software and associated documentation files (the
\ "Software"), to deal in the Software without restriction, including
\ without limitation the rights to use, copy, modify, merge, publish,
\ distribute, sublicense, and/or sell copies of the Software, and to
\ permit persons to whom the Software is furnished to do so, subject to
\ the following conditions:
\ 
\ The above copyright notice and this permission notice shall be
\ included in all copies or substantial portions of the Software.
\ 
\ THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
\ EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
\ MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
\ NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
\ LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
\ OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
\ WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
\
\ LICENSE_END
