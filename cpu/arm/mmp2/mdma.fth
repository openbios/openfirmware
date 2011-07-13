purpose: Test code to determine the speed of MMP2 memory to memory DMA

\ Copy from cache to cache - 1.3 GB/sec
\ Copy from memory to memory - 323 MB/sec
\ DMA from memory to memory - 425 MB/sec
\ Read from cache  (address constant) 4.2 GB/sec
\ Read from memory (advancing address) 390 MB/sec

h# d42a.0a00 value mdma0-base

: mdma!  ( n offset -- )  mdma0-base + l!  ;
: mdma@  ( offset -- n )  mdma0-base + l@  ;

h# 0010.0000 constant mdma-ram
h# ffc0 constant /mdma-buf
mdma-ram constant mdma-desc0
h# 10 constant /dma-desc

\ Descriptor format:
\ Byte count
\ Source
\ Destination
\ link

: set-descriptor   ( next dest source length adr -- )
   >r  r@ l!  r@ la1+ l!  r@ 2 la+ l!  r> 3 la+ l!
;

code cmake-test-ring  ( src-adr dst-adr len desc -- )
                      \ tos: desc
   pop    r4,sp       \ r4: Total length
   pop    r2,sp       \ r2: dst
   pop    r1,sp       \ r1: src
   set    r0,#0xffc0
   begin
      add    r3,tos,#0x10
      stmia  tos!,{r0,r1,r2,r3}
      inc    r1,r0
      inc    r2,r0
      decs   r4,r0
   0<= until
   \ Go back to last descriptor
   dec  tos,#0x10
   mov  r3,#0
   str  r3,[tos,#0x0c]  \ Last link is 0
   inc  r4,r0
   str  r4,[tos]        \ Fixup last length
   pop  tos,sp
c;
0 value dst-adr
0 value src-adr
0 value desc-adr
: make-test-ring  ( src-adr dst-adr len -- )
   swap to dst-adr  swap to src-adr  
   mdma-desc0 to desc-adr
   0  ?do
      desc-adr /dma-desc +  dst-adr i +   src-adr i +  /mdma-buf  desc-adr  set-descriptor
      desc-adr /dma-desc +  to desc-adr
   /mdma-buf +loop

   desc-adr /dma-desc -  to desc-adr
   0 desc-adr 3 la+ l!       \ Put null in last link

   mdma-desc0  h# 30 mdma!   \ Link to first descriptor
;
: start-test-ring  ( -- )
\   8 h# d428.2864 l!       \ Enable DMA clock
   1 h# 80 mdma!           \ Enable DMA completion interrupts
   h# 0000.3d80   h# 40 mdma! \ fetch next, enable, chain, 32 bytes, inc dest, inc src
;
: abort-test-ring  ( -- )  h# 10.0000 h# 40 mdma!  ;
