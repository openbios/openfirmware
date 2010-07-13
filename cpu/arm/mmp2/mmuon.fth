code page-table!  ( padr -- )
   mcr p15,0,tos,2,0,0
   pop tos,sp
c;
code page-table@  ( -- padr )
   psh tos,sp
   mrc p15,0,tos,2,0,0
   mov tos,tos,lsr #14  \ Clear low bits which read unpredictably
   mov tos,tos,lsl #14
c;


: map-section  ( pa+mode va -- )
   d# 18 rshift  page-table@ +  l!
;
: map-sections  ( pa mode va size -- )
   2>r  +  2 or   2r>     ( pa+mode va size )
   bounds  ?do            ( pa+mode )
      dup i map-section   ( pa+mode )
      /section +          ( pa+mode' )
   /section +loop         ( pa+mode )
   drop
;

: setup-sections
   page-table-pa page-table!
   page-table-pa /page-table erase

   h# 0000.0000 h# c0e             0 fb-pa        map-sections  \ Cache and write bufferable
   fb-pa        h# c06  fb-pa        fb-size      map-sections  \ Write bufferable
   h# d400.0000 h# c02  h# d400.0000 h# 0100.0000 map-sections  \ I/O - no caching or buffering
;
\ Do we need to map SRAM and DDRC ?

code start-mmu
   set     r2, 0xFFFFFFFF       \ Set domains for Manager access
   mcr     p15,0,r2,3,0,0       \ Update register 3 in CP15

   \ Enable the MMU
   mrc     p15, 0, r2, 1, 0, 0  \ Read current settings in control reg
   mov     r2,  r2, LSL #18     \ Upper 18-bits must be written as zero,
   mov     r2,  r2, LSR #18     \ ... clear them now.

   orr     r2, r2, 0x200        \ Set the ROM Protection bit
   bic     r2, r2, 0x100        \ Clear the System Protection bit
   orr     r2, r2, 0x001        \ Set the MMU bit

   ahead
      forth
      begin  here h# 1f and  while  0 c,  repeat
      assembler
   then

   mcr    p15, 0, r2, 1, 0, 0       \ Go Virtual - Wheeeeeee!
   mrc    p15, 0, r2, 2, 0, 0       \ Insure that the write completes
   mov    r2,  r2                     \ before continuing
   sub    pc,  pc,  #4
c;

: go-fast
   setup-sections
   start-mmu
   dcache-on
   icache-on
   d# 400,000 to ms-factor
   d# 400 to us-factor
;
