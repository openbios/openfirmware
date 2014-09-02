purpose: Create residual data structure
\ See license at end of file

hex

0 value fw-revision		\ Set me
h# dc6 value fw-supports	\ Change if needed
h# 2 value fw-supplier		\ Change if needed

defer #cpus  ' 1 to #cpus	\ Actual # of CPUs installed

: $pcall-parent  ( ?? adr len -- ?? )
   parent-device dup push-package  $call-static-method  pop-package
;
: get-parent-property  ( adr len -- val$ false | true )
   parent-device get-package-property
;   
: get-bus-id  ( -- true | bus-id false )
   " aix-bus-id" get-parent-property  if  true  exit  then
   get-encoded-int  false
;
: isa-child?  ( -- flag )  get-bus-id  if  false  else  1 =  then  ;

\ PnP stuff

0 value next-pnp-adr
: pnp-b,  ( byte -- )
   next-pnp-adr  dup 1+ to next-pnp-adr  c!
;
: pnp-w,  ( word -- )  wbsplit swap pnp-b, pnp-b,  ;
: pnp-l,  ( long -- )  lwsplit swap pnp-w, pnp-w,  ;
: pnp-x,  ( d -- )  swap pnp-l, pnp-l,  ;

: pnp,  ( adr len -- )  bounds  ?do  i c@ pnp-b,  loop  ;

: make-interrupt-items  ( -- )
   isa-child?  0=  if  exit  then
   " interrupts" get-property  0=  if            ( adr len )
      begin  dup  while
         " pnp-decode-interrupt" $pcall-parent   ( adr' len' irq-mask flags )
         ?dup  if
            h# 23 pnp-b, swap pnp-w, pnp-b,
         else
            h# 22 pnp-b,  pnp-w,
         then
      repeat
      2drop
   then
;
: make-reg-item  ( false | .. stuff .. true -- )
   0=  if  exit  then
   if                               ( adr' len' size isa-adr 16bit )
      \ Variable I/O port item
      h# 47 pnp-b, pnp-b, dup pnp-w, pnp-w, 1 pnp-b, pnp-b,
   else                             ( adr' len' d.size d.base info type )
      \ IBM "generic address" item
      h# 84 pnp-b,  d# 21 pnp-w,  9 pnp-b,  pnp-b, pnp-b, 0 pnp-w,
      pnp-x, pnp-x,
   then
;
: make-reg-items  ( -- )
   \ Possible override
   " aix-reg" get-property  0=  if  pnp,  exit  then
   " reg" get-property  0=  if         ( adr len )
      begin  dup  while
         " pnp-decode-reg" $pcall-parent make-reg-item
      repeat
      2drop
   then
   " other-bus-reg" get-property  0=  if  ( adr len )
       begin  dup  while
          decode-int  " pnp-decode-reg"  rot $call-static-method  make-reg-item
       repeat
       2drop
   then
;
: make-ranges-items  ( -- )
   \ It isn't worthwhile to automate this, because the AIX ranges stuff
   \ is too irregular.
   " pnp-ranges" get-property  0=  if  pnp,  then
;
: make-dma-items  ( -- )
   \ Only do this for children of the ISA node
   isa-child?  0=  if  exit  then

   " dma" get-property  0=  if             ( adr len )
      begin  dup  0>  while                ( adr len )
         h# 2a pnp-b,                      ( adr len )
         decode-int 1 swap lshift pnp-b,   ( adr' len' )
         decode-int pnp-b,                 ( adr'' len'' )
      repeat                               ( adr' len' )
      2drop
   then
;
: make-id-item  ( -- )
   " aix-chip-id" get-property 0=  if
      h# 75 pnp-b,  1 pnp-b,  get-encoded-int lbflip pnp-l,
   then
;
: invent-pnp-data  ( -- )
   make-interrupt-items
   make-reg-items
   make-dma-items
   make-id-item
   make-ranges-items
   " other-pnp-data" get-property  0=  if  pnp,  then
;   
: make-pnp-packet  ( -- )
   " pnp-data" get-property  0=  if  pnp,  exit  then
   " make-pnp-data" current-device find-method  if
      execute pnp, exit
   then                                      ( )
   invent-pnp-data
;

\ End of pure PNP stuff


\ Constructors for residual-data fields

0 value next-res-adr
: res-b,  ( byte -- )  next-res-adr  dup 1+ to next-res-adr  c!  ;
: res-w,  ( word -- )  wbsplit res-b, res-b,  ;
: res-l,  ( long -- )  lwsplit res-w, res-w,  ;

\ Add PnP info to the AIX device record

0 value pnp-base
: res-pnp,  ( -- )  next-pnp-adr pnp-base -  res-l,  ;
: end-pnp  ( -- )  h# 78 pnp-b,  ;
: set-pnp-fields  ( -- )
   res-pnp,  make-pnp-packet                                      end-pnp
   res-pnp,  " pnp-possible"   get-property  0=  if  pnp,  then   end-pnp
   res-pnp,  " pnp-compatible" get-property  0=  if  pnp,  then   end-pnp
;


[ifdef] compute-mem-segs
: get-instance-property  ( property-name$ ihandle -- adr len )
   ihandle>phandle get-package-property drop
;
0 value mem-reg  0 value /mem-reg
: mem-seg-open  ( -- reg-adr,len avail-adr,len )
   " reg" memory-node @ get-instance-property  to /mem-reg
   /mem-reg alloc-mem to mem-reg
   mem-reg /mem-reg move
   mem-reg /mem-reg
   " available" memory-node @ get-instance-property
;
: mem-seg-close  ( -- )  mem-reg /mem-reg free-mem  ;
: next-range  ( reg-adr,len avail-adr,len -- reg-adr,len avail-adr,len adr ty )
   
;
[then]

: mem-seg,   ( start end usage -- end )
   >r  2dup =  if  r> 2drop exit  then	\ Don't create pieces for null regions
   r> res-l,                         ( start end )
   over pageshift rshift res-l,      ( start end )
   dup rot - pageshift rshift res-l,
;

: mem-segs,  ( -- )
   next-res-adr >r  0 res-l,		\ To be patched later

   0
   \ end-address  type
   4000             4  mem-seg,  \ trap table
\  htab            10  mem-seg,  \ a little free piece
\  htab /htab +     2  mem-seg,  \ HTAB
   load-base       10  mem-seg,  \ free memory below load-base
   loaded +  pagesize round-up
                    8  mem-seg,	 \ loaded program
   origin          10  mem-seg,  \ More free mem (XXX what about allocated mem)
   limit            4  mem-seg,  \ Firmware code (dictionary)
   sp0 @ ps-size -  2  mem-seg,  \ Firmware heap
   memtop @         1  mem-seg,  \ Firmware stack
   memsize         10  mem-seg,  \ free piece above firmware
   8000.0000       20  mem-seg,  \ Unpopulated memory area
   8080.0000      440  mem-seg,  \ ISA I/O space
   8100.0000      480  mem-seg,  \ PCI config space
   bf80.0000      500  mem-seg,  \ PCI I/O space
   c000.0000      600  mem-seg,  \ System I/O registers
   ff00.0000      800  mem-seg,  \ PCI memory space
   fff0.0000     1000  mem-seg,  \ Unpopulated system ROM area
   0000.0000     2000  mem-seg,  \ ROM
   drop

   next-res-adr  r@ -  /mem-seg  /  dup r> be-l!  ( actual-#mem-segs )
   max#mem-segs swap -  /mem-seg *  next-res-adr +  to next-res-adr
;
   
: get-dev&bus#  ( -- dev/func# bus# )
   " reg" get-property drop  ( adr len )
   get-encoded-int  lbsplit  ( reg# dev,func# bus# xxx )
   drop rot drop drop        ( dev/func# )
   " bus-range" get-parent-property  if  0  else  get-encoded-int  then
;

: make-aix-device  ( -- false )
   " aix-id&type" get-property  if
      \ No AIX property; try for PCI vendor-id, device-id, class-code props.

      " vendor-id" get-property  if  false exit  then  ( adr len )

      get-encoded-int
      " device-id" get-property  abort" No device-id property"
      get-encoded-int  wljoin >r

      " class-code" get-property  abort" No class-code property"
      get-encoded-int  >r			   ( r: devid type )

   else                                            ( adr len )
      \ Use aix-id&type property value
      decode-int >r  get-encoded-int >r		   ( r: devid type )
   then                                            ( adr len )

   get-bus-id  if  2r> 2drop false exit  then      ( r: devid type ) ( bus-id )

   dup res-l,  r> r> res-l,                        ( bus-id type )

   " slave"     get-property  if    -1  else  get-encoded-int  then  res-l,
   " aix-flags" get-property  if                   ( bus-id type )
      over 4 =  if  4180  else  2800  then         ( bus-id type flags )
   else                                            ( bus-id type adr len )
      get-encoded-int                              ( bus-id type flags )
   then  res-l,                                    ( bus-id type )

   8 lshift  res-l,                                ( bus-id )

   4 =  if  get-dev&bus#  else  0 0  then  res-b, res-b,
   0 res-w,                                        ( )

   set-pnp-fields

   false
;
: cpu,  ( state cpu# type -- )  res-l,  res-b,  res-b,  0 res-b,  0 res-b,  ;
\ XXX pvr@ should be done on each individual CPU
: (cpus,)  ( -- )
   max#cpus res-w,
   #cpus res-w,

\ XXX   1 0 pvr@ cpu,		  \ Assumes that CPU 0 is running the firmware
   0 0 pvr@ cpu,		  \ Assumes that CPU 0 is running the firmware

   #cpus 1  ?do  0 i pvr@ cpu,  loop	\ Assumes that all CPUs are good
   res#cpus #cpus ?do  0 0 0 cpu,  loop	\ Zero the unused entries
;
defer cpus,  ' (cpus,) to cpus,

: mem-simm-size  ( simm# -- #bytes )
   " simm-size" memory-node @ $call-method
;
: simms,  ( -- )
   \ Count the number of SIMMs present
   0  max#mems 0  do  i mem-simm-size  if  1+  then  loop  res-l,

   \ ??? should this be densely packed or sparse?
   max#mems 0  do  i mem-simm-size d# 20 rshift res-l,  loop
;
: mem,  ( -- )
   " size" memory-node @ $call-method drop      ( #bytes )
   dup res-l,			\ Total memory
   res-l,			\ Good memory
   mem-segs,
   simms,
;

: get-root-int  ( name$ -- n )  root-phandle get-int  ;
: get-cpu-int  ( name$ -- n )  cpu-package get-int  ;

: res-erase  ( #bytes -- )  0  ?do  0 res-b,  loop  ;
: res-$,  ( adr len maxlen -- )
   dup >r  min tuck   ( adr len' )
   bounds  ?do  i c@ res-b,  loop    ( len' )  ( r: maxlen )
   r> swap  ?do  bl res-b,  loop
;
: cpu-int,  ( name$ -- )  get-cpu-int res-l, ;

: >kb  ( #bytes -- #kb )  d# 10 rshift  ;
: cache,  ( -- )
   \ XXX this needs work for 601 and other potential unified-cache processors
   " i-cache-block-size" get-cpu-int              ( line-size )
   dup res-l,		\ coherence block size
   dup res-l,		\ reservation granule size
   " i-cache-size" get-cpu-int                    ( line-size i$-size )
   " d-cache-size" get-cpu-int                    ( line-size i$-size d$-size )
   2dup + >kb  res-l,	\ Total cache size in KB

   " cache-unified" cpu-package get-package-property  if  ( /i$l /i$ /d$ )
      1 res-l,				\ split cache
      0 res-l,				\ associativity
      0 res-l,				\ unified cache line size
      over >kb res-l,   ( i$-line /i$ /d$ )	\ i-cache-size in KB
      swap 2 pick /     ( i$-line /d$ i$#lines )
      " i-cache-sets" get-cpu-int / res-l,	\ i-cache-associativity
      swap res-l,     ( /d$ )		\ i-cache-line-size
      dup >kb res-l,  ( /d$ )		\ d-cache-size in KB
      " d-cache-block-size" get-cpu-int	( /d$ /d$ln )
      tuck /          ( /d$ln d$#lines )
      " d-cache-sets" get-cpu-int / res-l, ( /d$ln) \ d-cache-associativity
      res-l,				\ d-cache-line-size

      " tlb-size" get-cpu-int		( #tlb-entries )
      dup res-l,			\ tlb-size
      620-class?  if                    ( #tlb-entries )
         drop                           ( )
         2 res-l,			\ unified TLB
         2 res-l,                       \ TLB associativity for unified TLB
         d# 128 res-l, 			\ i-tlb-size
         d# 2 res-l,			\ i-tlb-associativity
         d# 128 res-l,			\ d-tlb-size
         d# 2 res-l,			\ d-tlb-associativity
      else
         1 res-l,			\ split TLB
         0 res-l,                       \ TLB associativity for unified TLB
         2/ dup  " tlb-sets" get-cpu-int   ( #itlb-ents #itlb-ents #tlb-sets )
         2/ /                              ( #itlb-entries #itlb-sets )
         over res-l,			\ i-tlb-size
         dup  res-l,			\ i-tlb-associativity
         swap res-l,			\ d-tlb-size
              res-l,			\ d-tlb-associativity
      then
   else						( ... adr len )
      2drop
[ifdef] notdef
      2 res-l,				\ unified cache
      ?? res-l,				\ associativity
      0 res-l,				\ unified cache line size
[then]      
   then
   0 res-l,
;   

: devs,  ( -- )
   next-res-adr >r  0 res-l,		\ To be patched later

   root-phandle push-package
      ['] make-aix-device  ['] (search-preorder) catch 2drop
   pop-package

   next-res-adr  r@ -  /device  /  r> be-l!
;

: make-residual-data  ( -- )
   /residual-data alloc-mem to residual-data
   residual-data to next-res-adr

   residual-data pnp-heap-offset + to pnp-base
   pnp-base to next-pnp-adr

   residual-data /residual-data erase

   /residual-data res-l,	\ length
   0 res-b,  1 res-b,		\ version, revision
   fw-revision res-w,		\ firmware revision

   " model" root-phandle get-package-property  if
      " "
   else
      get-encoded-string
   then
   d# 31 res-$,	0 res-b,		\ Printable Model

   " aix-serial#" root-phandle get-package-property  if
      " "
   else
      get-encoded-string
   then
   d# 16 res-$,

   d# 48 res-erase

   fw-supplier res-l,		\ Firmware Supplier
   fw-supports res-l,		\ FirmwareSupports bit mask

   " size" nvram-node $call-method drop d# 1024 round-up  res-l,

   " #simm-slots" memory-node @ ihandle>phandle get-package-property
   abort" Missing #simm-slots property in memory node"
   get-encoded-int res-l,

   \ XXX depends on bridge
   1 res-w,			\ Endian switch: Port A8 bit 5 - for Eagle
   0 res-w,			\ Spread I/O: Port 850

   \ XXX for SMP
   0 res-l,			\ SMP enter-idle-loop address

   0 res-l,			\ RAM error log offset into PnP heap
   8 res-erase

   " clock-frequency" cpu-int,
   " clock-frequency" get-root-int dup res-l,   ( CPU-bus-clock-freq )
   4 res-erase

   " timebase-frequency"  get-cpu-int / d# 1000 *  res-l,

   620-class?  if  d# 64  else  d# 32  then  res-l,

   d# 4096 res-l,			\ page size

   cache,
   cpus,
   mem,

   devs,

   make-boot-name
;

\ LICENSE_BEGIN
\ Copyright (c) 1997 FirmWorks
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

