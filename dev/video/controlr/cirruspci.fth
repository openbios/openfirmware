\ See license at end of file
purpose: PCI Methods

\ PCI access code.
\ This code is used to determine which controller is present and
\ to begin the process of sorting out which specific words are to
\ be plugged into the various defered words. Also, and just as important,
\ the REG property gets formed here.

hex
headers

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

: legacy-regs  ( -- )
      h# 3b0 0m h# a100.0000 0 h# C  0 >reg-props
      h# 3c0 0m h# a100.0000 0 h# 20 0 >reg-props
      h# a.0000 0m h# a200.0000 0 h# 2.0000 0 >reg-props
;
   
0 instance value mask-val

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
      h# 1013 of   cirrus to chip   endof
   endcase	( )

   2 c-w@ ff and	( version )

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

   drop			( )

   variant -1 <> to safe?	\ If varient is <> -1, then we know what it is.
;

headers

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

: probe
   determine-controller
   encode-reg-property			\ Build the reg property now
;

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
