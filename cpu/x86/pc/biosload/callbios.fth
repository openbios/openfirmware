purpose: Call real-mode BIOS interrupts from protected mode

\ For now we assume the following descriptors:
\ 08 - 16-bit code 0..ffff
\ 10 - 16-bit data 0..ffffffff
\ 18 - 16-bit data 0..ffff
\ 20 - 32-bit code 0..ffffffff
\ 28 - 32-bit data 0..ffffffff

\ We assume that we can use memory from h# 200 to h# 3ff

\ Bounce buffer at h# 90000

h#  8 constant rm-code-desc
h# 18 constant rm-data-desc
h# 20 constant pm-code-desc
h# 28 constant pm-data-desc

h# 002 constant rm-flagval  \ Flags for IRET

\ Low-memory addresses
h# 200 constant rm-go       \ Real mode enter code
h# 280 constant rm-return   \ Real mode return code
h# 300 constant rm-idt      \ For loading RM IDT with LIDT
h# 308 constant rm-sp       \ For loading RM SP with LSS
h# 30c constant pm-sp-save  \ Save/restore area for PM SP
h# 310 constant pm-gdt-save \ For loading PM GDT with LGDT
h# 318 constant pm-idt-save \ For loading PM IDT with LIDT
h# 3c0 constant rm-regs     \ Real-mode register buffer (in/out)
rm-regs           constant rm-gs
rm-gs     wa1+    constant rm-fs
rm-fs     wa1+    constant rm-es
rm-es     wa1+    constant rm-ds
rm-ds     wa1+    constant rm-di
rm-di     la1+    constant rm-si
rm-si     la1+    constant rm-bp
rm-bp     la1+    constant rm-xx  \ Would be stack pointer
rm-xx     la1+    constant rm-bx
rm-bx     la1+    constant rm-dx
rm-dx     la1+    constant rm-cx
rm-cx     la1+    constant rm-ax
rm-ax     la1+    constant rm-flags
rm-flags  la1+    constant rm-target  \ Full pointer for RM call target address
rm-target la1+    constant rm-retloc  \ Full pointer to rm-return
rm-retloc la1+    constant rm-rflags  \ Flags in case of return via IRET

label rmint-enter
   real-mode
   \ This must be copied to low memory

   rm-data-desc #  ax  mov  \ 16-bit data segment
   ax ds mov  ax es mov  ax fs mov  ax gs mov  ax ss mov

   pm-gdt-save #) sgdt  \ So we can get back
   pm-idt-save #) sidt  \ So we can get back

   rm-idt #) lidt
   cr0 ax mov   h# fe # al and   ax cr0 mov   \ Enter real mode

   here 5 +  rmint-enter -  rm-go +  0 #)  far jmp  \ Jump to set cs

   \ Now we are running in real mode; fix segments again
   cs ax mov   ax ds mov  ax es mov  ax fs mov  ax gs mov

   rm-sp #) sp lss

   \ Load the 16-bit registers from the rm-regs area
   gs pop  fs pop  es pop  ds pop   op: popa   op: popf

   far ret                     \ Now we are running the real-mode target code
end-code
here rmint-enter - constant /rmint-enter

label rmint-exit
   rm-target #  sp  mov   \ Set the stack pointer to the top of the rm reg area

   \ Copy the real-mode registers to the buffer
   op: pushf  op: pusha   ds push  es push  fs push  gs push

   cli
   cs ax mov   ax ds mov

   op: pm-gdt-save #) lgdt
   cr0 ax mov  1 # al or  ax cr0 mov

   here 5 +  rmint-exit -  rm-return +  pm-code-desc #)  far jmp

   protected-mode

   pm-data-desc # ax mov  ax ds mov  ax es mov  ax gs mov  ax gs mov  ax ss mov
   pm-idt-save #) lidt

   pm-sp-save #) sp mov
   popf
   popa
c;
here rmint-exit - constant /rmint-exit

\ Must set up the registers area with register values and the target address
code rm-call  ( -- )
   pusha
   pushf

   sp pm-sp-save #) mov
   cld
   cli
   sp sp xor
   rm-go  rm-code-desc #) far jmp
c;

: >seg:off  ( linear -- offset segment )  lwsplit  d# 12 lshift  ;
: seg:off!  ( linear adr -- )  >r  >seg:off  r@ 2+ w!  r> w!  ;

0 value bios-prepped?
: ?prep-bios-call  ( -- )
   bios-prepped?  if  exit  then   true to bios-prepped?
   rmint-enter rm-go     /rmint-enter move
   rmint-exit  rm-return /rmint-exit  move
   h# ffff rm-idt w!
   0 rm-idt 2+ l!
   rm-regs   rm-sp     seg:off!  \ Setup real-mode full pointer for lss
   rm-return rm-retloc seg:off!  \ Setup return address full pointer
   rm-flagval rm-retloc 4 + w!   \ Flags for return
;

: dr
   ." ax: "  rm-ax ?  2 spaces
   ." bx: "  rm-bx ?  2 spaces
   ." cx: "  rm-cx ?  2 spaces
   ." dx: "  rm-dx ?  2 spaces
   ." bp: "  rm-bp ?  2 spaces
   ." si: "  rm-si ?  2 spaces
   ." di: "  rm-di ?  2 spaces
;

: { ( int# -- )  ?prep-bios-call  rm-regs d# 44 erase   4 * @ rm-target !  ;
: } rm-call ;

: ax rm-ax !  ;
: ah rm-ax 1+ c!  ;
: al rm-ax c! ;
: bx rm-bx l! ;
: cx rm-cx l! ;
: dx rm-dx l! ;
: cf@  rm-flags @ 1 and  ;
: es:di  >seg:off rm-es w!  rm-di l!  ;
: video-mode  ( mode# -- )
   d# 55 set-tick-limit  h# 10 { 3 al  bx  }  d# 10 set-tick-limit
;
: text-mode  3 video-mode  ;
: 1024x768x8   h# 105 video-mode  ;
: 1024x768x16  h# 116 video-mode  ;
: apm-connect16  h# 15 { h# 5302 ax  0 bx  }  ;
: apm-power-off  apm-connect16  h# 15 { h# 5307 ax  1 bx  3 cx  }  ;
: bios-memsize  ( -- n )
   h# 15 { h# e801 ax }
   rm-ax @ h# 400 *  rm-bx @ h# 10000 *  +  h# 100000 +
;
: .bios-memory-map  ( -- )
   0
   begin  ( continuation )
      h# 15 { bx h# e820 ax  h# 10000 es:di  d# 20 cx " PAMS" drop @ dx }
      rm-flags @ 1 and  abort" Not supported"
      rm-cx @
      h# 10000 rm-cx @ bounds  ?do  i @ 9 u.r  4 +loop  cr
      rm-bx @  ( continuation' )
   ?dup 0= until
;
: bios-config-b@  ( adr -- b )   lwsplit h# 1a { h# b108 ax bx rm-di ! }  rm-cx @  ;
: bios-config-w@  ( adr -- w )   lwsplit h# 1a { h# b109 ax bx rm-di ! }  rm-cx @  ;
: bios-config-l@  ( adr -- l )   lwsplit h# 1a { h# b10a ax bx rm-di ! }  rm-cx @  ;
: bios-config-b!  ( b adr -- )   lwsplit h# 1a { h# b10b ax bx rm-di ! rm-cx ! }   ;
: bios-config-w!  ( w adr -- )   lwsplit h# 1a { h# b10c ax bx rm-di ! rm-cx ! }   ;
: bios-config-l!  ( l adr -- )   lwsplit h# 1a { h# b10d ax bx rm-di ! rm-cx ! }   ;
: disk-status  ( -- stat )  h# 13 { h# 0100 ax } rm-ax @  ;
0 value #sects
0 value #cyls
0 value #heads
: get-drive-params  ( -- )
   h# 13 { 8 ah h# 80 dx }
   rm-flags @ 1 and  if  true exit  then
   rm-cx @  wbsplit                     ( cl ch )
   over h# 3f and to #sects             ( cl ch )
   swap 6 rshift bwjoin 1+ to #cyls     ( )
   rm-dx @ 8 rshift 1+ to #heads        ( )
;
: #drive-sectors  ( -- n )
   h# 13 { h# 15 ah  h# 80 dx }
   rm-dx @  rm-cx @  wljoin
;
: reset-disks  ( -- )  h# 13 { 0 ah  h# 80 dx }  ;
: reset-hard-disks  ( -- )  h# 13 { h# 0d ah  h# 80 dx }  ;
: do-rw  ( sector1 cyl0 head0 drive0 #sectors ah-val -- )
   h# 13 { ah  al     ( sector1 cyl0 head0 drive0 )
   swap bwjoin dx     ( sector1 cyl0 )
   wbsplit            ( sector1 cyl.lo cyl.hi )
   6 lshift rot or    ( cyl.lo cyl.hi|sector )
   swap bwjoin cx
   h# 10000 >seg:off rm-es w!  bx
   }
;
: read-sectors  ( sector1 cyl0 head0 drive0 #sectors -- )  2 do-rw  ;
: write-sectors  ( sector1 cyl0 head0 drive0 #sectors -- )  3 do-rw  ;

: lbn>sch  ( lbn -- sector cyl head )
   #sects   /mod  swap 1+ swap   ( sector rem )
   #heads   /mod                 ( sector head cyl )
   dup #cyls > abort" LBN out of range"
   swap                          ( sector cyl head )
;
: lbn-read-sectors  ( lbn drive #sectors -- )  2>r lbn>sch 2r> read-sectors  ;
: lbn-write-sectors  ( lbn drive #sectors -- )  2>r lbn>sch 2r> write-sectors  ;
