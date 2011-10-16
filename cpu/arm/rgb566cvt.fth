purpose: Copy from 16bpp to 24bpp frame buffer format

code copy16>24-line  ( src-adr dst-adr #pixels -- )
   mov     r2,tos            \ #pixels in r2
   ldmia   sp!,{r0,r1,tos}   \ r0: src, r1: dst, r2: #pixels
   begin
      ldrh  r3,[r0]
      inc   r3,2

      mov   r4,r3,lsr #8
      and   r4,r4,#0xf8
      strb  r4,[r1],#1

      mov   r4,r3,lsr #3
      and   r4,r4,#0xfc
      strb  r4,[r1],#1

      mov   r4,r3,lsl #3
      and   r4,r4,#0xf8
      strb  r4,[r1],#1

      decs  r2,1
   0= until
c;

0 value rect-w
0 value rect-h

0 value dst-base
0 value dst-pitch
0 value dst-x
0 value dst-y

: dst-base  ( -- adr )  dst-y dst-pitch *  dst-x +  ;

0 value src-base
0 value src-pitch
0 value src-x
0 value src-y

: src-base  ( -- adr )  dst-y dst-pitch *  dst-x +  ;

: copy16>24  ( src-base src-pitch src-x,y dst-x,y w,h -- )
   src-base dst-base    ( src-adr dst-adr )
   rect-h 0  ?do        ( src-adr dst-adr )
      2dup rect-w copy16>24-line          ( scr-adr dst-adr )
      swap src-pitch +  swap dst-pitch +  ( scr-adr' dst-adr' )
   loop                 ( src-adr dst-adr )
   2drop                ( )
;
