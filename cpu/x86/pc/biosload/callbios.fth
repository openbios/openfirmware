purpose: Call real-mode BIOS interrupts from protected mode

\ For now we assume the following descriptors:
\ 08 - 16-bit code 0..ffff
\ 10 - 16-bit data 0..ffffffff
\ 18 - 16-bit data 0..ffff
\ 20 - 32-bit code 0..ffffffff
\ 28 - 32-bit data 0..ffffffff

\ We assume that we can use memory from h# 200 to h# 3ff

h#  8 constant rm-code-desc
h# 18 constant rm-data-desc
h# 20 constant pm-code-desc
h# 28 constant pm-data-desc

h# 002 constant bios-flagval  \ Flags for IRET

\ Low-memory addresses
h# 200 constant 'bios-call  \ Real mode enter code
h# 280 constant 'bios-ret   \ Real mode return code
h# 300 constant 'bios-idt   \ For loading RM IDT with LIDT
h# 308 constant 'bios-sp    \ For loading RM SP with LSS
h# 30c constant pm-sp-save  \ Save/restore area for PM SP
h# 310 constant pm-gdt-save \ For loading PM GDT with LGDT
h# 318 constant pm-idt-save \ For loading PM IDT with LIDT

h# 3c0 constant bios-regs     \ Real-mode register buffer (in/out)
bios-regs         constant bios-gs
bios-gs     wa1+  constant bios-fs
bios-fs     wa1+  constant bios-es
bios-es     wa1+  constant bios-ds
bios-ds     wa1+  constant bios-di  \ offset decimal 8
bios-di     la1+  constant bios-si
bios-si     la1+  constant bios-bp
bios-bp     la1+  constant bios-xx  \ Would be stack pointer
bios-xx     la1+  constant bios-bx
bios-bx     la1+  constant bios-dx
bios-dx     la1+  constant bios-cx
bios-cx     la1+  constant bios-ax
bios-ax     la1+  constant bios-flags   \ offset decimal 40
bios-flags  la1+  constant bios-target  \ Full pointer for RM call target address
bios-target la1+  constant bios-retloc  \ Full pointer to 'bios-ret
bios-retloc la1+  constant bios-rflags  \ Flags in case of return via IRET

label bios-call
   16-bit
   \ This must be copied to low memory

   rm-data-desc #  ax  mov  \ 16-bit data segment
   ax ds mov  ax es mov  ax fs mov  ax gs mov  ax ss mov

   pm-gdt-save #) sgdt  \ So we can get back
   pm-idt-save #) sidt  \ So we can get back

   'bios-idt #) lidt
   cr0 ax mov   h# fe # al and   ax cr0 mov   \ Enter real mode

   here 5 +  bios-call -  'bios-call +  0 #)  far jmp  \ Jump to set cs

   \ Now we are running in real mode; fix segments again
   cs ax mov   ax ds mov  ax es mov  ax fs mov  ax gs mov

   'bios-sp #) sp lss

   \ Load the 16-bit registers from the bios-regs area
   gs pop  fs pop  es pop  ds pop   op: popa   op: popf

   far ret                     \ Now we are running the real-mode target code
end-code
here bios-call - constant /bios-call

label bios-ret
   16-bit

   bios-target #  sp  mov   \ Set the stack pointer to the top of the rm reg area

   \ Copy the real-mode registers to the buffer
   op: pushf  op: pusha   ds push  es push  fs push  gs push

   cli
   cs ax mov   ax ds mov

   op: pm-gdt-save #) lgdt
   cr0 ax mov  1 # al or  ax cr0 mov

   here 5 +  bios-ret -  'bios-ret +  pm-code-desc #)  far jmp

   32-bit

   pm-data-desc # ax mov  ax ds mov  ax es mov  ax gs mov  ax gs mov  ax ss mov
   pm-idt-save #) lidt

   pm-sp-save #) sp mov
   popf
   popa
c;
here bios-ret - constant /bios-ret

\ Must set up the registers area with register values and the target address
code }bios  ( -- )
   pusha
   pushf

   sp pm-sp-save #) mov
   cld
   cli
   sp sp xor
   'bios-call  rm-code-desc #) far jmp
c;

0 value bios-prepped?
: ?prep-bios-call  ( -- )
   bios-prepped?  if  exit  then   true to bios-prepped?
   bios-call 'bios-call  /bios-call move
   bios-ret  'bios-ret   /bios-ret  move
   h# ffff 'bios-idt w!
   0 'bios-idt 2+ l!
   bios-regs   'bios-sp    seg:off!  \ Setup real-mode full pointer for lss
   'bios-ret   bios-retloc seg:off!  \ Setup return address full pointer
   bios-flagval bios-retloc 4 + w!   \ Flags for return
;

: .bios-regs
   ." ax: "  bios-ax ?  2 spaces
   ." bx: "  bios-bx ?  2 spaces
   ." cx: "  bios-cx ?  2 spaces
   ." dx: "  bios-dx ?  2 spaces
   ." bp: "  bios-bp ?  2 spaces
   ." si: "  bios-si ?  2 spaces
   ." di: "  bios-di ?  2 spaces
   cr
   ." ds: " bios-ds w@ .  2 spaces
   ." es: " bios-es w@ .  2 spaces
   ." fs: " bios-fs w@ .  2 spaces
   ." gs: " bios-gs w@ .  2 spaces
   ." flags: " bios-flags ?
   cr
;

: bios{ ( int# -- )  ?prep-bios-call  bios-regs d# 44 erase   4 * @ bios-target !  ;

: ax bios-ax !  ;
: ah bios-ax 1+ c!  ;
: al bios-ax c! ;
: bx bios-bx l! ;
: cx bios-cx l! ;
: dx bios-dx l! ;
: cf@  bios-flags @ 1 and  ;
: es:di  >seg:off bios-es w!  bios-di l!  ;

\ Video - INT 10
: video-mode  ( mode# -- )
   d# 55 set-tick-limit  h# 10 bios{ 3 al  bx  }bios  d# 10 set-tick-limit
;
: text-mode  3 video-mode  ;
: 1024x768x8   h# 105 video-mode  ;
: 1024x768x16  h# 116 video-mode  ;
: apm-connect16  h# 15 bios{ h# 5302 ax  0 bx  }bios  ;
: apm-power-off  apm-connect16  h# 15 bios{ h# 5307 ax  1 bx  3 cx  }bios  ;

\ Memory map - INT 15
: bios-memsize  ( -- n )
   h# 15 bios{ h# e801 ax }bios
   bios-ax @ h# 400 *  bios-bx @ h# 10000 *  +  h# 100000 +
;
: .bios-memory-map  ( -- )
   0
   begin  ( continuation )
      h# 15 bios{ bx h# e820 ax  h# 10000 es:di  d# 20 cx " PAMS" drop @ dx }bios
      bios-flags @ 1 and  abort" Not supported"
      h# 10000 bios-cx @ bounds  ?do  i @ 9 u.r  4 +loop  cr
      bios-bx @  ( continuation' )
   ?dup 0= until
;

\ PCI BIOS - INT 1A
: (bios-config@)  ( adr axval -- n )
   h# 1a bios{ ax  lwsplit  bx bios-di ! }bios  bios-cx @
;
: (bios-config!)  ( n adr axval -- )
   h# 1a bios{ ax lwsplit bx bios-di ! bios-cx ! }bios
;

: bios-config-b@  ( adr -- b )   h# b108 (bios-config@)  ;
: bios-config-w@  ( adr -- w )   h# b109 (bios-config@)  ;
: bios-config-l@  ( adr -- l )   h# b10a (bios-config@)  ;
: bios-config-b!  ( b adr -- )   h# b10b (bios-config!)  ;
: bios-config-w!  ( w adr -- )   h# b10c (bios-config!)  ;
: bios-config-l!  ( l adr -- )   h# b10d (bios-config!)  ;

\ Disk access - INT 13 
: disk-status  ( -- stat )  h# 13 bios{ h# 0100 ax }bios bios-ax @  ;

0 value #sects
0 value #cyls
0 value #heads
: get-drive-params  ( -- )
   h# 13 bios{ 8 ah h# 80 dx }bios
   bios-flags @ 1 and  if  true exit  then
   bios-cx @  wbsplit                     ( cl ch )
   over h# 3f and to #sects               ( cl ch )
   swap 6 rshift bwjoin 1+ to #cyls       ( )
   bios-dx @ 8 rshift 1+ to #heads        ( )
;
: #drive-sectors  ( -- n )
   h# 13 bios{ h# 15 ah  h# 80 dx }bios
   bios-dx @  bios-cx @  wljoin
;
: reset-disks  ( -- )  h# 13 bios{ 0 ah  h# 80 dx }bios  ;
: reset-hard-disks  ( -- )  h# 13 bios{ h# 0d ah  h# 80 dx }bios  ;
: bios-rw  ( sector1 head0 cyl0 drive0 #sectors ah-val -- )
   h# 13 bios{ ah  al     ( sector1 head0 cyl0 drive0 )
   rot bwjoin dx          ( sector1 cyl0 )
   wbsplit                ( sector1 cyl.lo cyl.hi )
   6 lshift rot or        ( cyl.lo cyl.hi|sector )
   swap bwjoin cx
   h# 10000 >seg:off bios-es w!  bx
   }bios
;
: bios-read-sectors   ( sector1 head0 cyl0 drive0 #sectors -- )  2 bios-rw  ;
: bios-write-sectors  ( sector1 head0 cyl0 drive0 #sectors -- )  3 bios-rw  ;

: lbn>shc  ( lbn -- sector head cyl )
   #sects   /mod  swap 1+ swap           ( sector rem )
   #heads   /mod                         ( sector head cyl )
   dup #cyls > abort" LBN out of range"  ( sector head cyl )
;
: lbn-read-sectors   ( lbn drive #sectors -- )  2>r lbn>shc 2r> bios-read-sectors  ;
: lbn-write-sectors  ( lbn drive #sectors -- )  2>r lbn>shc 2r> bios-write-sectors  ;
