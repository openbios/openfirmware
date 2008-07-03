\ See license at end of file
purpose: Boot sectors for loading OFW

hex

create debug-start
\ create debug-dos

: le-w,  here  /w allot  le-w!  ;
: le-l,  here  /l allot  le-l!  ;

[ifdef] debug-dos

1520 constant boot-seg		\ Need to convert CS, DS and ES to 7c0
1560 constant part-seg		\ a0:0 contains HD active partition sector 0
1580 constant hd-seg		\ 80:0 contains HD sector 0
15a0 constant fat-seg		\ 100:0-100:1200 is where FAT will be loaded
1700 constant ofw-seg		\ 800:0 is where OFW will be loaded

[else]

7c00 constant boot-base		\ 0:7c00 is where this program is loaded
 7c0 constant boot-seg		\ Need to convert CS, DS and ES to 7c0
 800 constant ofw-seg		\ 800:0 is where OFW will be loaded
 100 constant fat-seg		\ 100:0-100:1200 is where FAT will be loaded
  c0 constant part-seg		\ c0:0 contains HD active partition sector 0
  80 constant hd-seg		\ 80:0 contains HD sector 0

[then]

  78 constant bios-dpt		\ 0:78 is pointer to disketter params table
 1be constant ptable		\ hd-seg:ptable = first partition entry
   9 constant #fat-sectors	\ # sectors in FAT on 1.44MB floppy
   c constant fat-type12
  10 constant fat-type16

\ Assembler macros for startup diagnostics
[ifdef]  debug-start
: reportc  ( char -- )
   " pusha" evaluate
   ( char ) " # al mov  0e # ah mov  7 bx mov  10 int" evaluate
   " popa" evaluate
;
: reportd  ( al -- )
   " pusha" evaluate
   " f # al and d# 10 # al cmp" evaluate
   " >=  if  ascii a d# 10 - # al add  else  ascii 0 # al add  then" evaluate
   " 0e # ah mov  7 bx mov  10 int" evaluate
   " popa" evaluate
;
: reportw  ( ax -- )
   " pusha" evaluate
   " 4 # cx mov  begin  4 # ax rol  reportd  cx dec  0= until" evaluate
   " popa" evaluate
;
[else]
: reportc  ( char -- )  drop  ;
: reportd  ( al -- )  ;
: reportw  ( ax -- )  ;
[then]

start-assembling

\ ***************************************************************************
\ sector 0

label my-entry0
   16-bit
   e9 c,  0 le-w,  \ Branch instruction; patch later
end-code

   46 c, 6f c, 72 c, 74 c, 68 c, 6d c, 61 c, 78 c,	\ System Id: Forthmax

\ ---------------------------------------------------------------------------
\ bpb definition
label bp-bps
   200 le-w,
end-code

label bp-spc
   1 c,
end-code

label bp-res
   2 le-w,
end-code

label bp-nfats
   2 c,
end-code

label bp-ndirs
   e0 le-w,
end-code

label bp-nsects
   b40 le-w,
end-code

label bp-media
   f0 c,
end-code

label bp-spf
   9 le-w,
end-code

label bp-spt
   12 le-w,
end-code

label bp-nsides
   2 le-w,
end-code

label bp-nhidlo
   0 le-w,
end-code

label bp-nhidhi
   0 le-w,
end-code

3e pad-to

\ ---------------------------------------------------------------------------
\ local variables
label drive
   0 c,
end-code

label head
   0 c,
end-code

label track
   0 le-w,
end-code

label sector
   0 c,
end-code

label s-dirlo		\ include partition offset
   0 le-w,
end-code

label s-dirhi
   0 le-w,
end-code

label s-datalo		\ include partition offset
   0 le-w,
end-code

label s-datahi
   0 le-w,
end-code

label s-fatlo		\ include partition offset
   0 le-w,
end-code

label s-fathi
   0 le-w,
end-code

label s-cfat		\ sector offset of FAT in fat-seg
   0 le-w,
end-code

label fat-type		\ C: only, FAT type
   0 c,
end-code

label dpt
   0 c, 0 c, 0 c, 0 c, 0 c, 0 c, 0 c, 0 c, 0 c, 0 c, 0 c,
end-code

label ofw-fn
   4f c, 46 c, 57 c, 20 c, 20 c, 20 c, 20 c, 20 c, 49 c, 4d c, 47 c, \ OFW.IMG
end-code

label err-msg
   d c, a c,
   4e c, 6f c, 6e c, 2d c, 53 c, 79 c, 73 c, 74 c,	\ Non-Syst
   65 c, 6d c, 20 c, 64 c, 69 c, 73 c, 6b c, 20 c,	\ em disk 
   6f c, 72 c, 20 c, 64 c, 69 c, 73 c, 6b c, 20 c,	\ or disk
   65 c, 72 c, 72 c, 6f c, 72 c, 0d c, 0a c, 52 c,	\ error..R
   65 c, 70 c, 6c c, 61 c, 63 c, 65 c, 20 c, 61 c,	\ eplace a
   6e c, 64 c, 20 c, 70 c, 72 c, 65 c, 73 c, 73 c,	\ nd press
   20 c, 61 c, 6e c, 79 c, 20 c, 6b c, 65 c, 79 c,	\  any key
   20 c, 77 c, 68 c, 65 c, 6e c, 20 c, 72 c, 65 c,	\  when re
   61 c, 64 c, 79 c, 0d c, 0a c, 00 c,			\ ady ...
end-code

\ ---------------------------------------------------------------------------
\ subroutines
label compute-start  ( -- )
   16-bit
   bp-res asm-base - #) ax mov		\ Compute sector# of FAT
   dx dx xor
   bp-nhidlo asm-base - #) ax add
   bp-nhidhi asm-base - #) dx adc
   ax s-fatlo asm-base - #) mov		\ Save sector#
   dx s-fathi asm-base - #) mov

   ah ah xor
   bp-nfats asm-base - #) al mov	\ Compute sector# of root directory
   bp-spf asm-base - #) mul
   s-fatlo asm-base - #) ax add
   s-fathi asm-base - #) dx adc

   ax s-dirlo asm-base - #) mov		\ Save sector#
   dx s-dirhi asm-base - #) mov
   ax s-datalo asm-base - #) mov
   dx s-datahi asm-base -  #) mov

   20 # ax mov				\ Compute and store data sector#
   bp-ndirs asm-base - #) mul
   bp-bps asm-base - #) bx mov
   bx ax add
   ax dec
   bx div
\   ax s-datalo asm-base - #) add	\ The assembler made me do it
   s-datalo asm-base - #) ax add	\ The assembler made me do it
   ax s-datalo asm-base - #) mov	\ The assembler made me do it
   0 # s-datahi asm-base - #) adc

   ret
end-code

label hd-tk-sec ( dx:ax: sector# -- )
   16-bit
   bp-spt asm-base - #) dx cmp
   u>=  if  stc ret  then
   bp-spt asm-base - #)  div
   dl inc
   dl sector asm-base - #)  mov
   dx dx xor
   bp-nsides asm-base - #)  div
   dl head asm-base - #)  mov
   ax track asm-base - #) mov
   clc
   ret
end-code

label read-sector  ( es:bx: address -- )
   16-bit
   201 # ax mov			\ read 1 sector
   track asm-base - #) cx mov
   6 # ch shl
   sector asm-base - #) ch or
   86 c, e9 c,			\ ch cl xchg
   drive asm-base - #) dl mov
   head asm-base - #) dh mov
   13 int
   ret
end-code

label display-str  ( si: msg -- )
   16-bit
   begin
      al lodsb
      al al or
      0=  if  ret  then
      pushf
      0e # ah mov
      07 # bx mov
      10 int			\ display byte
      popf
   again
end-code

label error-exit  ( -- )
   16-bit
   boot-seg # bx mov
   bx ds mov
   err-msg asm-base - #  si  mov
   display-str #) call
   ax ax xor
   16 int			\ wait for keyboard input
   si pop			\ restore diskette parameters table
   ds pop
   0 [si] pop
   2 [si] pop
   19 int			\ bootstrap loader
end-code

label use-floppy  ( -- ds: boot-seg )
   16-bit
   boot-seg # push
   ds pop
end-code

label floppy-entry  ( -- )
   16-bit
   e9 c, 0 le-w,		\ Branch to load from floppy; patch later
end-code

\ ---------------------------------------------------------------------------
\ entry point
label start0  ( dl: drive# -- )
   16-bit
   cli

[ifdef] debug-dos

   0 # dl mov
   ds bp mov
   ax ax  xor				\ Make a copy of floppy parameters table
   ax es  mov
   bios-dpt # bx mov
   es: 0 [bx] si lds
   ds push si push es push bx push

   bp es mov
   dpt asm-base - # di mov
   0b # cx mov
   cld repz movsb

   bp ds mov				\ Make DS 7c0
   dl drive asm-base - #) mov		\ Save drive#
   0f # -2 [di] byte mov		\ Head seek delay time for 1.44MB diskette
   bp-spt asm-base - #) cx mov
   cl -7 [di] mov			\ End of track

   ax ax xor
   ax ds mov
   boot-seg # 2 [bx] mov		\ Load new diskette parameters table
   dpt asm-base - # 0 [bx] mov
   bp ds mov

[else]

   here asm-base - 5 + boot-seg #) far jmp	\ Make cs:ip = 7c0:xxx

   ax ax  xor				\ Make a copy of floppy parameters table
   ax ss  mov
   boot-base # sp mov
   bios-dpt # bx mov
   ss: 0 [bx] si lds
   ds push  si push  ss push  bx push
   boot-seg # ax mov
   ax es mov
   dpt asm-base - # di mov
   0b # cx mov
   cld repz movsb

   ax ds mov				\ Make DS 7c0
   dl drive asm-base - #) mov		\ Save drive#
   0f # -2 [di] byte mov		\ Head seek delay time for 1.44MB diskette
   bp-spt asm-base - #) cx mov
   cl -7 [di] mov			\ End of track

ascii a reportc

   ss: boot-seg # 2 [bx] mov		\ Load new diskette parameters table
   ss: dpt asm-base - # 0 [bx] mov

[then]

   sti
   ax ax xor				\ Reset floppy drive
   13 int
pushf
\ ascii b reportc
popf
   carry?  if  error-exit #) jmp  then

   compute-start #) call

[ifndef] debug-dos

\ ascii c reportc

   1 # ax mov				\ Read floppy sector 1
   dx dx xor
   hd-tk-sec #) call
   bp-bps asm-base - #) bx mov
   read-sector #) call
   carry?  if  error-exit #) jmp  then

[then]

\ ascii d reportc

   11 # ah mov				\ Recalibrate C:
   80 # dl mov
   13 int
   carry?  if  use-floppy #) jmp  then	\ If C: not found, load from floppy

ascii e reportc

end-code

label my-entry1
   16-bit
   e9 c, 0 le-w,	\ Branch to next sector; patch later
end-code

\ ---------------------------------------------------------------------------
\ End of sector 0
1fe here asm-base - asm-origin +  over .x dup .x cr
also forth u<  if  ." 1fe Padding Overflow" cr  then  previous 

1fe pad-to
   55 c, aa c,

\ ***************************************************************************
\ sector 1

\ ---------------------------------------------------------------------------
\ subroutines
label read-fat  ( ax: fat-sector-offset -- )
   16-bit
   pusha
   ax s-cfat asm-base - #) mov		\ Save sector offset
   dx dx xor
   s-fatlo asm-base - #) ax add
   s-fathi asm-base - #) dx adc
   #fat-sectors # cx mov
   es push
   fat-seg # bx mov
   bx es mov
   bx bx xor

   begin				\ Read FAT sectors
      pusha
      hd-tk-sec #) call
      read-sector #) call
      popa
      ax inc
      0 # dx adc
      bp-bps asm-base - #) bx add
      cx dec
   0= until

   es pop
   popa
   ret
end-code

label ?read-fat  ( ax: fat-sector-offset dx: byte-offset -- bx: byte-offset )
   16-bit
   dx push
   s-cfat asm-base - #) dx mov
   dx ax cmp
   u>=  if
      #fat-sectors # dx add
      dx ax cmp
      u<  if				\ Fat sector in memory
         s-cfat asm-base - #) dx mov	\ Compute offset from fat-seg
         dx ax sub
         bp-bps asm-base - #) bx mov
         bx mul
         bx pop
         ax bx add
         ret
      then	\ Fat sector in memory
   then
   read-fat #) call			\ Read fat sector
   bx pop
   ret
end-code


label cluster12>next  ( es: fat-seg ax: cluster# -- flags ax: next-cluster#  )
   16-bit
   bx push  cx push  dx push

   ax push
   bp-bps asm-base - #) ax mov		\ Compute sector, bit offset
   8 # bx mov
   bx mul
   ax cx mov
   ax pop
   c # bx mov
   bx mul
   cx div

   ax cx mov
   dx ax mov
   dx dx xor
   8 # bx mov
   bx div
   dx push				\ Save bit offset

   ax dx mov				\ Byte offset
   cx ax mov				\ Sector offset
   ?read-fat #) call
   es: 0 [bx] ax mov
   dx pop				\ Bit offset
   0 # dx cmp
   = if
      fff # ax and
   else
      4 # ax shr
   then
   ff0 # ax cmp

   dx pop  cx pop  bx pop
   ret
end-code

label cluster16>next  ( es: fat-seg ax: cluster# -- flags ax: next-cluster# )
   16-bit
   bx push  cx push  dx push

   dx dx xor				\ Compute fat sector, offset
   100 # bx mov
   bx div
   1 # dx shl

   ?read-fat #) call			\ Read fat if not in memory
   es: 0 [bx] ax mov
   fff0 # ax cmp

   dx pop cx pop bx pop
   ret
end-code

label cluster>next  ( ax: cluster# -- flags ax: next-cluster# )
   16-bit
   es push
   bx push
   fat-seg # bx mov
   bx es mov

   bp-media asm-base - #) bl mov   
   f0 # bl cmp
   =  if
      cluster12>next #) call
   else
      fat-type asm-base - #) bl mov
      fat-type12 # bl cmp
      =  if
         cluster12>next #) call
      else
         cluster16>next #) call
      then
   then
   bx pop es pop
   ret
end-code

label cluster>sec  ( ax: cluster# -- dx:ax: sector# )
   16-bit
   ax dec ax dec
   bx push
   bx bx xor
   bp-spc asm-base - #) bl mov
   bx mul
   bx pop
   s-datalo asm-base - #) ax add
\   s-datahi asm-base - #) dx adc	\ The assembler made me do it
   0 # dx adc				\ The assembler made me do it
   s-datahi asm-base - #) dx add	\ The assembler made me do it
   ret
end-code

label find-ofw ( es: -- bx: directory address )
   16-bit
   20 # ax mov				\ Compute # of sectors in root directory
   bp-ndirs asm-base - #) mul
   bp-bps asm-base - #) bx mov
   bx ax add
   ax dec
   bx div

   begin
      ax push
      s-dirlo asm-base - #) ax mov
      s-dirhi asm-base - #) dx mov
      hd-tk-sec #) call
      bx bx xor
      read-sector #) call	\ Read one sector in root directory

\ ascii 1 reportc
      dx dx xor
      bp-bps asm-base - #) ax mov
      20 # cx mov
      cx div			\ # of directory entries per sector

      ds push
      boot-seg # push
      ds pop
      begin			\ Search for OFW.IMG
         bx di mov
         ofw-fn asm-base - # si mov
         d# 11 # cx mov
         repz byte cmps
         0=  if  ds pop  ax pop  clc  ret  then
         20 # bx add
\ ascii 2 reportc
         ax dec
      0=  until
      ds pop

      s-dirlo asm-base - #) inc
      0 s-dirhi asm-base - #) adc
      ax pop
      ax dec
   0=  until
   stc
   ret				\ OFW.IMG not found
end-code

\ ---------------------------------------------------------------------------
\ entry point (continue from start0)  C: only code
label start1
   16-bit

\ ascii t reportc

   201 # ax mov				\ Read C: partition table
   1 # cx mov
   80 # dx mov
   hd-seg # bx mov
   bx es mov
   bx bx xor
   13 int

   es: ptable 4 + #) al mov		\ Check partition type
   fat-type16 # bx mov
   1 # al cmp  =  if
      fat-type12 # bx mov
   else
      4 # al cmp  <>  if
         6 # al cmp <>  if
            use-floppy #) jmp		\ FAT16 partition not found
         then
      then
   then
   bx push				\ Save C: partition type

\ ascii u reportc

   201 # ax mov				\ Read C: partition 1 sector 1
   es: ptable 2 + #) cx mov
   es: ptable 1 + #) dh mov
   80 # dl mov
   part-seg # bx mov
   bx es mov
   bx bx xor
   13 int

   es push
   ds pop				\ DS = C: partition sector 1

   ax pop				\ Partition type
   al fat-type asm-base - #) mov
   80 # drive asm-base - #) mov
   compute-start #) call
end-code

label floppy-start  ( ds: boot-seg for floppy or hd-seg for c: )
   16-bit

\ ascii v reportc

   ax ax xor				\ Read first sectors of FAT
   read-fat #) call

\ ascii w reportc

   \ Search for OFW image.
   ofw-seg # bx mov
   bx es mov
   find-ofw #) call			\ Returns only if found

   carry?  if				\ If not found and c:, try a:
      bp-media asm-base - #) bl mov
      f0 # bl cmp
      =  if
         error-exit #) jmp
      else
         use-floppy #) jmp
      then
   then

\ ascii x reportc

   \ Load OFW image.
   es: 1a [bx] ax mov
   bx bx xor

   begin
      ax push
      cluster>sec #) call
      bp-spc asm-base - #) cl mov
      begin	( dx:ax=sector# )	\ Load one cluster at a time
         ax push cx push dx push
         hd-tk-sec #) call
         read-sector #) call
bx push
ascii . reportc
bx pop
         dx pop cx pop ax pop
         bp-bps asm-base - #) bx add
         0=  if				\ Advance to next 64K segment
            es dx mov
            1000 # dx add
            dx es mov
         then
         ax inc
         0 # dx adc
         cl dec
      0= until
\ ascii y reportc
      ax pop
      cluster>next #) call
   u>=  until

\ ascii z reportc
   ea c, 0 le-w, ofw-seg le-w,		\ Far jump to OFW
400 here asm-base - asm-origin +  over .x dup .x cr
also forth u<  if  ." 400 Padding Overflow" cr  then  previous
   400 pad-to
end-code

start0 my-entry0 put-branch16
start1 my-entry1 put-branch16
floppy-start floppy-entry put-branch16
end-assembling





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
