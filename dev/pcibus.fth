\ See license at end of file
purpose: PCI bus package

hex
headerless

defer prsnt@

\ Many systems have no way to read the PRSNT bits, so the default 
\ implementation returns the worst-case information.
: (prsnt@)  ( phys.hi -- false | prsnt-bits true )  drop 2 true  ;
' (prsnt@) to prsnt@

defer setup-fcodes   ( -- )  ' noop to setup-fcodes
defer restore-fcodes ( -- )  ' noop to restore-fcodes

false value pcimsg?	\ Optional Debug Msgs
false value probemsg?	\ Optional Probing Msgs

\ The default value for first-io skips the area where built-in ISA
\ devices normally live, but stays below 64K, in order to work with
\ 16-bit PCI-PCI bridges like the DEC 21050
\ XXX we should maintain a separate I/O space allocation pointer
\ for I/O devices with "large" region sizes (e.g. some versions of
\ IBM's MPIC chip), so they do not eat up all the available space
\ below 64K.
headers		\ These headers are for debugging convenience
h# 0000.1000 package value first-io       \ Avoid on-board ISA I/O devices
h# 0001.0000 package value io-space-top   \ Stay below 64K for 16-bit bridges

h# 0100.0000 package value first-mem      \ Default: reserve 16M for ISA memory
h# 3f00.0000 package value mem-space-top
headerless

h# 40 buffer: string1
h# 40 buffer: string2
h# 40 buffer: string3
h# 40 buffer: string4

headers
" pci"  encode-string  " name"  property

\ There are no visible PCI registers
\ my-address encode-int  /pci-regs encode-int encode+  " reg" property

" pci" encode-string  " device_type"  property

3 encode-int  " #address-cells" property
2 encode-int  " #size-cells"    property

headerless
false instance value apple-hack?
false value probe-state?

headers		\ These headers are for debugging convenience
0 value current-bus#

\ These cannot be package values because some words that use them are called
\ directly from different contexts - both from the root of the PCI domain
\ and also from child nodes and subordinate PCI-PCI bridge nodes.  They need
\ not be package values because they contain no long-term information;
\ between invocations of master-probe, the allocation pointers are stored
\ in first-io and first-mem.
first-io  value next-io
first-mem value next-mem
headerless

: set-next-io   ( adr -- )  to next-io   ;
: set-next-mem  ( adr -- )  to next-mem  ;

h# 0000.0fff constant pci-pagemask

\ XXX we need a sophisticated IO space allocator that accounts for
\ hardwired devices

: self-b@  ( phys.hi -- l )  " config-b@" $call-self  ;
: self-l@  ( phys.hi -- l )  " config-l@" $call-self  ;
: self-l!  ( l phys.hi -- )  " config-l!" $call-self  ;
: 64mem?  ( phys.hi -- flag ) self-l@  7 and 4 = ;
: io?  ( phys.hi -- flag )
   \ For expansion ROM base address registers, the LSB is an enable bit,
   \ not an I/O space indicator.  Expansion ROM base address registers
   \ are at 30 or 38; the register number portion of our phys.hi argument
   \ will always be in the range 10-24 (inclusive), 30, or 38.
   dup h# 30 and  h# 30 =  if  drop false  else  self-l@  1 and  0<>  then
;
: probe-base-reg  ( phys.hi -- value )
   dup self-l@ over                   ( phys.hi old-value phys.hi )
   h# ffff.ffff over self-l! self-l@  ( phys.hi old-value new-value )
   -rot swap self-l!
;
: mask-low-bits  ( phys.hi regval -- regval' )
   swap io?  if  3  else  h# f  then  invert and   ( regval' )
;
\ Some devices neglect to implement the upper 16 bits of the IO base
\ address register!
: fix-io16  ( high-mask -- high-mask' )
   dup h# 1.8000 and  h# 0.8000 =  if  h# ffff.0000 or  then
;
: find-boundary  ( phys.hi -- low-mask )
   dup dup probe-base-reg			( phys.hi phys-hi regval )
   mask-low-bits  fix-io16  invert		( phys.hi low-mask )
   swap 64mem?  0=  if  n->l  then              ( low-mask )
;
: mask-up  ( n mask -- n' )  tuck + swap invert and  ;

: ?p  ( adr len phys -- adr' len' phys' )
   over 1 >=  if                            ( adr len phys )
      2 pick c@  upc  ascii P =  if         ( adr len phys )
         h# 4000.0000 +  >r  1 /string  r>  ( adr' len' phys' )
      then
   then
;
: ?t  ( adr len phys -- adr' len' phys' )
   over 1 >=  if                            ( adr len phys )
      2 pick c@  upc  ascii T =  if         ( adr len phys )
         h# 2000.0000 +  >r  1 /string  r>  ( adr' len' phys' )
      then
   then
;

: $hnumber  ( adr len -- true | n false )  push-hex  $number  pop-base  ;
: $hdnumber?  ( adr len -- true | d false )
   push-hex  $dnumber?  pop-base
;

headers

: decode-unit  ( adr len -- phys.lo phys.mid phys.hi )
   dup 0=  if  2drop 0 0 0  exit  then        ( adr len )
   0 >r
   over c@  upc  ascii N =  if  r> h# 8000.0000 + >r  1 /string  then  ( adr len )
   over c@  upc  case
      ascii I  of  r> h# 0100.0000 + >r  1 /string  r> ?t    >r  endof
      ascii M  of  r> h# 0200.0000 + >r  1 /string  r> ?t ?p >r  endof
      ascii X  of  r> h# 0300.0000 + >r  1 /string  r>    ?p >r  endof
      ( default )
   endcase

   \ XX do range checks

   ascii , left-parse-string                            ( rem$ DD$ )
   $hnumber  if  0  then  h# 1f and d# 11 <<  r> + >r   ( rem$ )
   dup 0=  if  2drop  0 0 r>  exit  then                ( rem$ )

   ascii , left-parse-string                            ( rem$ F$ )
   $hnumber  if  0  then  h#  f and d#  8 <<  r> + >r   ( rem$ )
   dup 0=  if  2drop  0 0 r>  exit  then                ( rem$ )

   ascii , left-parse-string                            ( rem$ RR$ )
   $hnumber  if  0  then  h# ff and           r> + >r   ( rem$ )
   dup 0=  if  2drop  0 0 r>  exit  then                ( rem$ )

   \ Parse the remaining digits as a number, forcing the result to
   \ be a double number by pushing zeroes as needed
   $hdnumber?  ( 0 | n 1 | d 2 )  2 swap  ?do  0  loop  r>
;
headerless
: convert-device  ( phys.hi -- phys.hi )
   dup d# 11 >>  h# 1f and  u#s  drop
;
: convert-function  ( phys.hi -- phys.hi )
   dup 8 >>  7 and  u#  ascii , hold  drop
;
: convert-high  ( phys.hi -- phys.hi )
   dup h# 700 and  if  convert-function  then
   convert-device
;
: convert-rr  ( phys.hi -- phys.hi )
   ascii , hold
   dup h# ff and  u# u#s  drop   ( phys.hi )  \ RR field
   ascii , hold
   convert-function convert-device
;
: ?tpn  ( phys.hi char -- 0 )
   over  h# 2000.0000 and  if  ascii t hold  then
   over  h# 4000.0000 and  if  ascii p hold  then
   hold
   h# 8000.0000 and  if  ascii n hold  then
;

headers
: encode-unit  ( phys.lo phys.mid phys.hi -- adr len )
   push-hex
   <#
   dup  d# 24 >>  3 and  case                   ( phys.low phys.mid phys.hi )
      0  of  nip nip  convert-high  drop  endof  \ Configuration space
      1  of                                      \ I/O space
             nip swap            ( phys.hi phys.low )
	     u# u#s  drop        ( phys.hi )
             convert-rr          ( phys.hi )
             ascii i  ?tpn       ( )
      endof
      2  of					 \ Memory-32 space
             nip swap            ( phys.hi phys.low )
	     u# u#s  drop        ( phys.hi )
             convert-rr          ( phys.hi )
             ascii m  ?tpn       ( )
      endof
      3  of					 \ Memory-64 space
             -rot                ( phys.hi phys.low phys.mid )
	     # #s  2drop         ( phys.hi )
             convert-rr          ( phys.hi )
	     ascii x  ?tpn       ( )
      endof
   endcase
   0 u#> string1 $save
   pop-base
;
headerless

\ Configuration space

\ [ifdef] example-ranges-property
\ : +i  ( adr len n -- adr' len' )  encode-int encode+  ;
\ : 0+i  ( adr len -- adr' len' )  0 +i  ;
\ 
\ \  ---PCI Address---     ---Host Address----    --- size ---
\ \ phys.hi    .mid .low   phys.hi   .lo          .hi    .lo
\ 0000.0000 encode-int
\               0+i  0+i    1 +i  0000.0800 +i    0+i   800 +i  \ Slot 0
\ 0000.0800 +i  0+i  0+i    1 +i  0000.1000 +i    0+i   800 +i  \ Slot 1
\ 0000.1000 +i  0+i  0+i    1 +i  0000.2000 +i    0+i   800 +i  \ Slot 2
\ 0000.1800 +i  0+i  0+i    1 +i  0000.4000 +i    0+i   800 +i  \ Slot 3
\ 0100.0000 +i  0+i  0+i    2 +i  0000.0000 +i   1 +i      0+i  \ I/O
\ 0200.0000 +i  0+i  0+i    3 +i  0000.0000 +i   1 +i      0+i  \ Mem
\ 
\    " ranges" property
\ 
\ : map-pci-phys  ( paddr size io? -- vaddr )
\    if  2  else  3  then              ( paddr size parent-space )
\    swap " map-in" $call-parent       ( vaddr )
\ ;
\ 
\ [then]

\ : mapped?  ( phys.hi -- flag )
\ \ [ifdef] clear-to-f
\ \    dup config-l@ swap             ( old phys.hi )
\ \    h# ffff.ffff over config-l!    ( old phys.hi )
\ \    \ Ignore the low-order bits because the low bit of the expansion ROM
\ \    \ base address register is writeable
\ \    2dup config-l@                 ( old phys.hi old unmapped-value )
\ \    swap 3 invert and  swap 3 invert and  <>  ( old phys.hi flag )
\ \    -rot config-l!                 ( flag )
\ \ [else]
\    config-l@ 3 invert and  0<>      ( old phys.hi )
\ \ [then]
\ ;

: +i  ( adr len n -- adr' len' )  encode-int encode+  ;
: 0+i  ( adr len -- adr' len' )  0 +i  ;

: special-!  ( data bus# -- )
   h# ff and		\ isolate bus number
   d# 16 lshift		\ shift into Bus Number Field
   h# 0000.ff00 or	\ set Device/Function Bits to 1.  Register Bits = 0
   self-l!
;

: get-address  ( phys.low phys.mid phys.hi -- phys.hi paddr )
   apple-hack?  if  2 pick  if  nip swap exit  then  then
   dup dup self-l@                    ( low mid hi hi base+type )
   mask-low-bits                      ( low mid hi base )
   2swap drop +                       ( phys.hi paddr )
;
: not-relocatable?  ( phys.hi -- flag )  h# 8000.0000 and  0<>  ;

\ As described in the PCI binding document, we must avoid I/O addresses
\ with a "1" in either the h# 100 bit or the h# 200 bit.  Such addresses
\ have special meaning in ISA systems.  When an I/O address allocation
\ attempt generates such an address, we bump the address past the bad range.

: avoid-hard-decode  ( base -- base' )
   dup h# 300 and  if  h# 3ff invert and  h# 400 +  then
;

: power-of-2?  ( n -- flag )  dup 1- and 0=  ;

: >sizemask  ( n -- mask )
   \ Mask is one less than the smallest power of two >= n.
   ?dup  if                                 ( n )
      dup power-of-2?  if                   ( n )
         1-                                 ( mask )
      else                                  ( n )
         0                                  ( n #bits )
         \ Shift left until the leftmost 1
         \ bit is in the msb of the cell
         begin  swap 2* dup 0>=  while      ( #bits n' )
            swap 1+                         ( n' #bits' )
         repeat                             ( #bits x )

         \ Starting with all ones, shift
         \ right the same number of times
         drop  -1 swap 0  do  u2/  loop     ( mask )
      then                                  ( mask )
   else                                    
      1                                     ( mask )
   then                                     ( mask )
;

headers
external

: assign-pci-addr  ( phys.lo phys.mid phys.hi len | -1 -- phys.hi paddr size )
   \ If len is -1, reset any temporary allocations
   dup -1 =  if  first-io set-next-io  first-mem set-next-mem  drop exit  then

   probemsg?  if  ??cr ." Assigning PCI Space of length " dup 8 u.r  then

   >r nip                                           ( phys.lo phys.hi )
   dup find-boundary                                ( phys.lo phys.hi mask )
   over io?  if                                     ( phys.lo phys.hi mask )
      probemsg?  if  ." I/O Space..." cr  then
      \ Use the maximum of the requested size and the
      \ size implied by the register.
      2 pick r> +  >sizemask or   dup 1+ >r         ( phys.lo phys.hi mask'' )

      next-io  swap mask-up  avoid-hard-decode      ( phys.lo phys.hi base )
      dup r> +  set-next-io                         ( phys.lo phys.hi base )
      next-io >r                                    ( ... r: next-io )
   else	                                            ( phys.lo phys.hi mask )
      probemsg?  if  ." Memory Space..." cr  then
      \ Force memory space resources to page granularity
      pci-pagemask or				    ( phys.lo phys.hi mask' )

      \ Some PCI devices (e.g. S3 928) lie about
      \ the mapping granularity by having writeable
      \ base address register bits that are not in
      \ fact decoded, so we use the maximum of the
      \ sizes implied by the base address register
      \ and the reg property entry.
      2 pick r> +  >sizemask or   dup 1+ >r         ( phys.lo phys.hi mask'' )

      next-mem swap mask-up  dup r> + set-next-mem  ( phys.lo phys.hi base )
      next-mem >r                                   ( ... r: next-mem )
   then                                             ( phys.lo phys.hi base )
   probemsg?  if  2dup swap ."   Base Reg: " . ."  = " . cr  then
   2dup swap self-l!                                ( phys.lo phys.hi base )
\ M
   over 64mem?  if  over 4 + 0 swap self-l!  then
\ M
   rot +                                            ( phys.hi paddr )
   r> over -                                        ( phys.hi paddr size )
;

\ XXX What if a stateful bridge needs to have its registers mapped
\ in order to probe its children, thus it has a probe-state mapping,
\ then during the probe long-term addresses get assigned, then the
\ subordinate probe finishes and the bridge registers are unmapped,
\ ostensibly in probe state.
\ XXX we should stipulate that, after mapping out, devices must set
\ their command registers to disable memory and I/O response.

: enable-apple-hack  ( -- )  true to apple-hack?   ;

: ?map-in-msg  ( phys.lo..hi -- phys.lo..hi )
   pcimsg?  if
      ??cr ." PCI-MAP-IN: Bus: " dup d# 16 rshift  h# ff and   . ." , "
      dup h# 300.0000 and
      case
         h# 0000.0000  of  ." CONFIG, "  endof	( phys.lo..hi )
         h# 0100.0000  of  ." I/O, "     endof	( phys.lo..hi )
         ( default )	   ." MEM, "
      endcase
      ." PCI PHYS.HI..LO = " 3dup .x space .x space .x  4 spaces
   then
;
: map-in  ( phys.low phys.mid phys.hi len -- vaddr )
   >r                                               ( phys.lo..hi )
   ?map-in-msg                                      ( phys.lo..hi )
\ XXX handle "t" bit
   \ In most systems, map-in won't be called for config space addresses,
   \ but some systems require it, so we check this case, letting
   \ map-pci-phys do most of the work.
   dup h# 300.0000 and  0=  if	\ Config Space      ( phys.lo..hi )
      nip tuck false                                ( phys.hi phys.lo io? )
   else  dup not-relocatable?  if                   ( phys.lo..hi )
      nip tuck  h# 300.0000 and h# 100.0000 =       ( phys.hi phys.lo io? )
   else                                             ( phys.lo..hi )
      probe-state?  if                              ( phys.lo..hi )
         r@ assign-pci-addr drop                    ( phys.hi paddr )
      else                                          ( phys.lo..hi)
         get-address                                ( phys.hi paddr )
      then                                          ( phys.hi paddr )
      over io?                                      ( phys.hi paddr io? )
   then then                                        ( phys.hi paddr io? )
   \ The PCI bus physical base address has been assigned.
   \ Now determine the virtual address.
   rot r> map-pci-phys                              ( vaddr )
;

: open  ( -- )  true  ;
: close  ;

headerless

\ The my-X@ words are executed in the child instance
: my-b@  ( offset -- b )  my-space +  " config-b@" $call-parent  ;
: my-b!  ( b offset -- )  my-space +  " config-b!" $call-parent  ;
: my-w@  ( offset -- w )  my-space +  " config-w@" $call-parent  ;
: my-w!  ( w offset -- )  my-space +  " config-w!" $call-parent  ;
: my-l@  ( offset -- l )  my-space +  " config-l@" $call-parent  ;
: my-l!  ( l offset -- )  my-space +  " config-l!" $call-parent  ;

\ Create an integer-valued property with name "name$" and value "n".

: int-property  ( n name$ -- )  rot encode-int  2swap property  ;

\ Create an integer-valued property named "name$" from a 16-bit
\ configuration space register.

: int16-property  ( offset name$ -- )
   >r >r  my-w@  encode-int  r> r> property
;

\ Create an integer-valued property named "name$" from an 8-bit
\ configuration space register.

: int8-property  ( offset name$ -- )
   >r >r  my-b@  encode-int  r> r> property
;

\ True if the header type indicates that the function is a PCI-PCI bridge
: bridge?  ( -- flag )  h# 0e my-b@  h# 7f and  1 =   ;

\ True if the header type indicates that the funtion is a PCI-Cardbus
: card-bus? ( -- flag ) h# 0e my-b@  h# 7f and h# 2 =  ;

\ Create properties reflecting standard configuration header information

: class-code  ( -- n )  8 my-l@ 8 rshift  ;
: make-child-properties  ( -- )
   h# 00     " vendor-id"   int16-property
   h# 02     " device-id"   int16-property
   h# 08     " revision-id" int8-property
   bridge?  card-bus? or 0=  if
      h# 3e  " min-grant"   int8-property
      h# 3f  " max-latency" int8-property
   then

   h# 3d my-b@  ?dup  if                       ( int )
      dup encode-int " interrupts" property    ( int )
      my-space swap  " assign-int-line" $call-parent  if  h# 3c my-b!  then
   then                                        ( )

   h# 2e  " subsystem-id"         int16-property
   h# 2c  " subsystem-vendor-id"  int16-property

   class-code  encode-int  " class-code"  property
   6 my-w@
      dup 9 rshift 3 and  " devsel-speed"       int-property
      dup 7 rshift 1 and  if  0 0  " fast-back-to-back"  property  then
      dup 6 rshift 1 and  if  0 0  " udf-supported"      property  then
          5 rshift 1 and  if  0 0  " 66mhz-capable"      property  then

   \ Find the cache line size, and put it (divided by 4) into the
   \ cache-line-size register at offset 0x0c

   cpu-node @  if
      " d-cache-block-size" cpu-node @	( adr len ihandle )
      ihandle>phandle			( adr len phandle )
      get-package-property		( adr len false | true )
      0=  if				( adr len )
         decode-int nip nip		( line-size )
         4 / h# 0c			( size adr )
         my-b!				(  )
      then				(  )
   then

   \ Set the latency-timer to a default of 32
   h# 20 h# 0d my-b!			( )
;
: make-function-properties  ( child-ihandle -- )
   to my-self	\ Get back into child node
   make-child-properties
;

\ Create a "name" property of the form "pciVVVV,DDDD", where VVVV and
\ DDDD are the hexadecimal representations of the vendor ID and device
\ ID, respectively.

: $hold  ( adr len -- )
   dup  if  bounds swap 1-  ?do  i c@ hold  -1 +loop  else  2drop  then
;
: ascii-vendor-id  ( device/vendor-id -- adr len )
   lwsplit
   push-hex
   <# u#s drop ascii , hold u#s  " pci" $hold  u#> string2 $save
   pop-base
;
: name-property-value  ( -- adr len )  0 my-l@ ascii-vendor-id  ;

: class-name: ( code "name" --- )  ,  parse-word ",  align  ;

hex
create class-names

ffffff ,  \ Mask
000100 class-name: display
0 , 	  \ No more entries for this mask

ff0000 ,  \ Mask
030000 class-name: display
0a0000 class-name: dock
0b0000 class-name: cpu
0 , 	  \ No more entries for this mask

ffff00 ,  \ Mask
010000 class-name: scsi
010100 class-name: ide
010200 class-name: fdc
010300 class-name: ipi
010400 class-name: raid
020000 class-name: ethernet
020100 class-name: token
020200 class-name: fddi
020300 class-name: atm
040000 class-name: video
040100 class-name: sound
050000 class-name: memory
050100 class-name: flash
060000 class-name: host
060100 class-name: isa
060200 class-name: eisa
060300 class-name: mca
060400 class-name: pci
060500 class-name: pcmcia
060600 class-name: nubus
060700 class-name: cardbus
070000 class-name: serial
070100 class-name: parallel
080000 class-name: interrupt
080100 class-name: dma
080200 class-name: timer
080300 class-name: rtc
090000 class-name: keyboard
090100 class-name: pen
090200 class-name: mouse
0c0000 class-name: firewire
0c0100 class-name: access
0c0200 class-name: ssa
0c0300 class-name: usb
0c0300 class-name: fibre
0 ,       \ No more entries for this mask
0 ,       \ End of table

: @+  ( adr -- adr' n )  dup na1+ swap @  ;

: unknown-class?  ( class-code -- true | class-name$ false )
   \ The outer loop executes once for each distinct mask value
   class-names  begin  @+  dup  while        ( code adr mask )
      2 pick and >r                          ( code adr r: masked-code )

      \ The inner loop searches all entries with that mask value
      begin  @+  dup  while                  ( code adr match )

         r@ =  if                            ( code adr )
            \ A match under the mask was found; return the string
            r> drop nip  count false  exit   ( class-name$ false )
         then                                ( code adr )

         \ Skip the string and proceed to the next entry
         count + 1+ aligned
      repeat                                 ( code adr 0 )

      \ Proceed to the next mask value
      r> 2drop                               ( code adr )
   repeat                                    ( code adr 0 )

   \ No match was found
   3drop true                                ( true )
;
: make-name-property  ( -- )
   class-code unknown-class?  if  name-property-value  then
   encode-string  " name" property
;
: +string  ( prop-adr,len string-adr,len -- prop-adr,len' )
   encode-string  encode+
;

: <#class  ( -- arguments-to-u#> )
   class-code  push-hex <# u# u# u# u# u# u#  pop-base
;
: class-property-value  ( -- adr len )
   <#class " class" $hold u#> string3 $save
;
headers
: make-compatible-property  ( -- )
   0 0 encode-bytes
   h# 2c my-l@  ?dup  if  ascii-vendor-id +string  then
   name-property-value +string
   <#class " pciclass," $hold u#>  +string
   " compatible" property
;
headerless

\ If the expansion ROM mapped at "virt" contains an FCode program,
\ copy it into RAM and return its address

: get-int-property  ( adr len -- n )
   get-my-property  if  -1  else  decode-int nip nip  then
;
: fcode-image?  ( PCI-struct-adr -- flag )
   dup " PCIR" comp  if  drop false exit  then

   \ always accept ROMs with vendor-id and device-id = ffff
   dup h# 04 + le-w@  dup h# ffff <>  if             ( adr id )
      " vendor-id" get-int-property  <>  if          ( adr )
         probemsg?  if                               ( adr )
            ??cr
            ."   Vendor IDs do not match ->  "
            ."   Function:" " vendor-id" get-int-property 4 u.r
            ." /ROM Image:" dup h# 04 + le-w@ 4 u.r  cr
         then                                        ( adr )
	 drop false exit                             ( false )
      then                                           ( adr )
   else                                              ( adr id )
      drop                                           ( adr )
   then                                              ( adr )

   dup h# 06 + le-w@  dup h# ffff <>  if             ( adr id )
      " device-id" get-int-property  <>  if          ( adr )
         probemsg?  if                               ( adr )
            ??cr ."   Function:" " device-id" get-int-property 4 u.r
            ."   /ROM Image:" le-w@ 4 u.r  ."  Device IDs do not match... " cr
         then                                        ( adr )
	 drop false exit                             ( false )
      then                                           ( adr )
   else                                              ( adr id )
      drop                                           ( adr )
   then                                              ( adr )

   h# 14 + c@  1 =                                   ( flag )
;

0 value rom-base
: locate-fcode  ( rom-image-adr -- false | adr len true )
   dup to rom-base
   begin
      dup  le-w@  h# aa55 <>  if
         probemsg?  if
            ??cr ."   Invalid ROM Header Format: " dup le-w@ . cr
         then
         drop false exit
      then                          ( rom-image-adr )

      dup  h# 18 +  le-w@  over +   ( rom-image-adr PCI-struct-adr )
      dup fcode-image?  if          ( rom-image-adr PCI-struct-adr )
         probemsg?  if  ??cr ."   FCode ROM Image Found... " cr  then
         drop dup rom-base -        ( rom-image-adr offset )
         encode-int  " fcode-rom-offset" property
         dup h# 02 + le-w@ +        ( FCode-image-adr )
	 dup >r  4 + be-l@          ( FCode-len )
	 dup alloc-mem              ( FCode-len adr )
         swap 2dup r> -rot cmove    ( adr len )
         true exit
      then
      probemsg?  if  ??cr ."   Non FCode Format ROM Image. " cr  then
      dup h# 15 + c@  h# 80 and 0=  ( rom-image-adr PCI-struct-adr )
   while    \ More images           ( rom-image-adr PCI-struct-adr )
      h# 10 +  le-w@  9 <<  +       ( rom-image-adr' )
   repeat                           ( rom-image-adr' )
   2drop false
;

\ READ orig base reg value.  write -1 and get new value. reset to orig value.
: probe-own-base-reg  ( offset -- value )
   dup my-l@  over                   ( offset old-value offset )
   h# ffff.ffff over my-l!  my-l@    ( offset old-value new-value )
   -rot swap my-l!                   ( new-value )
   l->n
;

: own-64mem?  ( phys.hi -- flag )  my-l@  7 and 4 =  ;
: own-io?  ( phys.hi -- flag )
   \ For expansion ROM base address registers, the LSB is an enable bit,
   \ not an I/O space indicator.  Expansion ROM base address registers
   \ are at 30 or 38; the register number portion of our phys.hi argument
   \ will always be in the range 10-24 (inclusive), 30, or 38.
   dup h# 30 and  h# 30 =  if  drop false  else  my-l@  1 and  0<>  then
;
: mask-own-low-bits  ( phys.hi regval -- regval' )
   swap own-io?  if  3  else  7  then  invert and   ( regval' )
;
: own-size-mask  ( offset -- high-mask )
   dup probe-own-base-reg        ( offset regval )
   mask-own-low-bits             ( regval' )
   fix-io16
;
: find-own-size  ( offset -- size )
   dup own-size-mask invert  swap own-64mem?  0=  if  n->l  then  1+
;

: expansion-rom  ( -- offset )
   bridge?  if  h# 38  else  h# 30   then
;

: base-register-bounds  ( -- high low )
   bridge?  if  h# 18  else  card-bus?	if  h# 14  else  h# 28  then  then
   h# 10
;

\ Temporarily assign addresses for all the base address registers so they
\ don't conflict with the expansion ROM address register.  Some boards do
\ not disable the response of relocatable memory regions when the expansion
\ ROM is turned on.

: temp-assign-addresses  ( -- )
   base-register-bounds  do
      i probe-own-base-reg                               ( regval )

      dup 7 and 4 =  if      \ Skip mem64 regions        ( regval )
         drop 8                                          ( increment )
      else                                               ( regval )
         dup 1 and  over 0= or  if  \ Skip IO regions    ( regval )
            drop 4                                       ( increment )
         else  			                         ( regval )
            7 invert and  invert                         ( low-mask )
            i own-64mem?  0=  if  n->l  then             ( low-mask )
            pci-pagemask or                              ( low-mask )
            next-mem over mask-up                        ( low-mask base )
            tuck swap 1+ + set-next-mem                  ( base )
            i my-l!                                      ( )
            4                                            ( increment )
         then                                            ( increment )
      then                                               ( increment )
   +loop                                                 ( )
;

\ If the function at configuration space address "phys.hi.func" has an
\ FCode program in its expansion ROM, evaluate that program and return
\ true, otherwise return false.

0 value save-mem
headers		\ find-fcode? doesn't have to be headered; it's just convenient
: find-fcode?  ( -- false | adr len true )

   next-mem to save-mem
   temp-assign-addresses
   expansion-rom                                             ( offset )

\   \ Map the expansion ROM at a high physical address that does not
\   \ conflict with the base addresses that were zeroed above.
\   mem-space-top 10.0000 - 1 or  over my-l!                  ( offset )

   \ Some PCI cards (e.g. a SciTex bridge device) implement a writeable
   \ enable bit for the expansion ROM base address register, but no other
   \ writeable bits, so comparing to zero doesn't work.
   dup probe-own-base-reg 2 u<  if  drop false  exit  then    ( offset )

\ Let map-in perform the address assignment, as we are in probe-state

   0 0 2 pick  dup find-own-size    ( offset p.rom.lo,med offset size )

   \ The following line is a bug workaround for a Sun device named
   \  "Multi-Grain", whose expansion ROM decoder responds to a 16 Mbyte region.
   dup h# 4.0000 >  if  drop h# 4.0000  then	\ Limit ROM size to 256K

   >r  h# 200.0000 or my-space +  r@ " map-in" $call-parent  ( offset virt )
   tuck >r >r                       ( r: size virt offset )  ( virt )

   \ Turn on address decode enable in Expansion ROM Base Address Register
   r@ my-l@  1 or  r@ my-l!         ( r: size virt offset )  ( virt )

   2 4 my-w!	\ Turn on memory enable                      ( virt )

   locate-fcode                                       ( false | adr len true )

   \ Turn off memory enable
   0 4 my-w!                  ( r: size virt offset ) ( false | adr len true )

   \ Turn off address decode enable in Expansion ROM Base Address Register
   r@ my-l@  1 invert and  r> my-l!  ( r: size virt ) ( false | adr len true )
   save-mem set-next-mem

   r> r>  " map-out" $call-parent                     ( false | adr len true )
;
headerless
: load-fcode  ( adr len -- )
   >r dup >r
\  0 0 " has-fcode" property       ( adr )
   1 byte-load    
   \ XXX TODO check stack depth
   r> r> free-mem
;

\ Set all base address registers to the highest possible address,
\ thus (hopefully) avoiding contention with explicitly-assigned addresses.
: clear-addresses  ( -- )
   base-register-bounds  do  -1 i my-l!  /l +loop
;

\ Add the property encoding of the address range "phys.lo..hi size.lo..hi"
\ to the property-encoded array "adr,len"

: +reg-entry  ( adr len phys.lo..hi size.lo..hi -- adr' len' )
   swap >r >r  swap rot >r >r     ( adr len p.hi ) ( r: s.lo,hi p.lo,mid )
   +i r> +i r> +i r> +i r> +i
;

: get-prefetch-mask  ( reg-val -- mask )  8 and h# 1b lshift  ;

: t-bit-mask  ( reg-val -- mask )  2 and h# 1c lshift  ;

\ Determine "phys.lo..hi", the numeric representation of the base address
\ register at configuration space address "base-reg-adr", and "increment",
\ the offset to the next base address register (8 for 64-bit memory space,
\ 4 otherwise).  If the base address register isn't implemented, return false.

\ In the code below, "mask" is a bitmask containing ones in the high bits
\ that can be programmed to set the device's address, and zeros in the
\ low bits that cannot be programmed.  The phrase "invert 1+" converts such
\ a mask into the size of the region.

: decode-base-reg  ( base-reg-offset -- ... )
   ( false increment | phys.lo..hi size true increment )

   dup probe-own-base-reg  h# f invert and  0=  if
      \ No valid address set, but the space decode, i/o or prefetchable
      \ bits are ignored.
      drop false 4 exit
   then						  ( base )

   \ XXX TODO what about non-relocatable devices?  How do we detect them?

   0 0 rot   dup own-size-mask swap               ( 0 0 mask base )

   dup my-l@  dup >r 7 and  4 =  if               ( 0 0 mask base )
      \ 64-bit memory space - look at the next base register too
      dup 4 +  probe-own-base-reg                 ( 0 0 mask base hi-mask )
      swap h# 300.0000 or r> get-prefetch-mask or ( 0 0 mask hi-mask' )
      my-space +  -rot                            ( 0 0 phys mask hi-mask )
      swap invert swap invert  1 0 d+  8          ( 0 0 phys size.lo..hi inc )
   else				                  ( 0 0 mask base )
      \ 32-bit ..
      \ Memory space or I/O space
      \ XXX what about "below 1 Meg" memory?
      r> dup 1 and  if                           ( 0 0 mask base reg )
         drop h# 100.0000                        ( 0 0 mask base hi-mask )
      else                                       ( 0 0 mask base reg )
         dup get-prefetch-mask >r                ( 0 0 mask base reg )
         t-bit-mask r> or h# 200.0000 or         ( 0 0 mask base hi-mask )
      then                                       ( 0 0 mask base type' )
      or  my-space +  swap invert 1+  0  4       ( 0 0 base' size.lo..hi inc )
   then
   true  swap
;

\ If the base address register at "offset" is implemented, add its
\ description to the property-encoded array "adr,len", returning
\ "inc" = 8 if the base address register is for 64-bit memory space,
\ "inc" = 4 otherwise.

: add-reg-entry  ( adr len offset -- adr' len' inc )
   decode-base-reg  >r  if  +reg-entry  then  r>
;

\ Create a "reg" property describing the base address registers

: make-reg-property  ( -- )
   my-space encode-int  0+i  0+i  0+i  0+i   ( adr len )

   base-register-bounds  do  i add-reg-entry  ( inc ) +loop  ( adr len )
   " reg" property
;

: set-power-property  ( prsnt-bits -- )
   \ XXX I hope we decide to switch the order of "standby" and "full-on"
   \ so we can omit the "standby" entry here.
   0 encode-int
   rot case
     0 of  d#  7.500.000  endof	\ 7.5W  (the property value is in microwatts)
     1 of  d# 15.000.000  endof	\ 15W
     2 of  d# 25.000.000  endof	\ 25W
     \ We know there is something in the slot because we only
     \ execute this word after finding something, but in case
     \ the PRSNT bits lie (or the hardware doesn't give them to us,
     \ we assume the worst case
     ( default )  d# 25.000.000 swap
   endcase
   +i  " power-consumption" property
;

\ Read the power sense pins in a system-dependent manner
: make-power-property  ( -- )
   \ Don't create the property for non-zero function numbers
   my-space 8 rshift 7 and  if  exit  then

   my-space prsnt@  if  set-power-property  then
;

\ After a function has been located and a device node has been created
\ for it, fill in the device node with properties and methods.
headers
vocabulary builtin-drivers
headerless
: no-builtin-fcode?  ( -- flag )
   probemsg?  if  ??cr ."   Checking for built-in FCode match... "  then
   name-property-value  ['] builtin-drivers  (search-wordlist)  if  ( xt )
      probemsg?  if  ." BUILTIN NAME MATCH " cr  then
      execute  false exit
   then
   name-property-value  find-drop-in  if   ( adr len )
      probemsg?  if  ." DROPIN NAME MATCH " cr  then
      2dup 2>r  'execute-buffer execute  2r> release-dropin
      false exit
   then
   class-property-value  ['] builtin-drivers  (search-wordlist)  if  ( xt )
      probemsg?  if  ." BUILTIN CLASS MATCH " cr  then
      execute  false exit
   then
   class-property-value  find-drop-in  if   ( adr len )
      probemsg?  if  ." DROPIN CLASS MATCH " cr  then
      2dup 2>r  'execute-buffer execute  2r> release-dropin
      false exit
   then
   true
;

: make-common-properties ( -- )
   make-name-property
   make-compatible-property
   make-reg-property
   make-power-property
;

: populate-device-node  ( -- )
   setup-fcodes              ( )
   make-child-properties     ( )
   card-bus?  if  make-common-properties  exit  then  ( )

   clear-addresses           ( )

   \ Interpret FCode if present; if not, invent "name" and "reg" properties
   find-fcode?  if           ( adr len )
      load-fcode             ( )
   else                      ( )
      no-builtin-fcode?  if  make-common-properties  then
   then                      ( )

   bridge? 0=  if
      clear-addresses           ( )
      b my-b@ 6 <>  if
         0 4 my-w!		\ Disables all card response
      then
   then
   restore-fcodes
;
\ Searches the direct children of the PCI node for an existing
\ whose unit address matches reg$ .  The name property is ignored,
\ because during probing, there's no target name for which to search.
: find-existing  ( reg$ -- reg$ )
   2dup decode-unit  unit# 3 /n* bounds  ?do  i !  /n +loop  ( reg$ )
   ['] unit-match?  search-level  drop                       ( reg$ )
;

\ Create a new node or activate an existing one
: make-function-node  ( arg$ reg$ -- )
   ['] find-existing catch  if  ( arg$ reg$ )   \ Make new node
      new-device  set-args      ( )
      populate-device-node      ( )
   else                         ( arg$ reg$ )	\ Active the existing node
      extend-package set-args   ( )
      make-child-properties     ( )
      " init" my-self		( adr len ihandle )
      ihandle>phandle		( adr len phandle )
      find-method  if		( xt )
         execute		( )
      then			( )
   then                         ( )
   finish-device                ( )
;

: amend-reg$  ( reg$ func# -- reg$' )
   push-hex
   >r  ascii , left-parse-string         ( rem$ head$ )
   2swap 2drop $number  if  0  then  r>  ( dev# func# )
   <# u# drop  ascii , hold  u#s u#> string4 $save
   pop-base
;

\ Returns true if the card implements a function at the indicated
\ configuration address.

\ We defer this because some systems require more careful checking, perhaps
\ using "wpeek" (which in turn may require a mapping operation).
defer function-present?  ( phys.hi.func -- flag )
: (function-present?)  ( phys.hi.func -- flag )
   " config-w@" $call-self  h# ffff <>
;
' (function-present?) to function-present?

\ Create a string of the form  "D,F" where D is the device number portion
\ of the string "reg$" and F is the hexadecimal representation of "func#"
\ Probe the card function func#
: probe-function  ( args$ reg$ phys.hi.dev func# -- args$ reg$ phys.hi.dev )

   2dup  8 lshift +  function-present?  if  ( args$ reg$ phys.hi.dev func# )

      \ Now we know that the function is present, so we can go ahead and
      \ create a device node for it

      2>r  2over 2over                      ( args$ reg$ args$ reg$ r: p f# )
      r@ amend-reg$  make-function-node     ( args$ reg$ r: p f# )
      2r>                                   ( args$ reg$ phys.hi.dev func# )
   then                                     ( args$ reg$ phys.hi.dev func# )
   drop                                     ( args$ reg$ phys.hi.dev )
;

\ Returns 0 if the card isn't present, 8 for a multifunction card, 1 otherwise
: max#functions  ( phys.hi -- phys.hi n )
   dup function-present?  if               ( phys.hi )
      dup h# e +  " config-b@" $call-self  ( phys.hi field )
      h# 80  and  if  8  else  1  then     ( phys.hi n )
   else                                    ( phys.hi )
      0                                    ( phys.hi n )
   then
;

\ XXX In order to implement put-package-property with standard words,
\ we would have to:
\ a) Save my-self and set it to 0
\ b) Get the package's "reg" property value with get-package-property
\ c) Convert the first entry therein to a string of the form "@D,F"
\ d) Pass that string to find-device to make that package the active package
\ e) Create the property
\ f) Restore my-self

: put-package-property  ( value$ name$ phandle -- )
   current token@ >r  context token@ >r   execute  ( value$ name$ )
   (property)
   r> context token!  r> current token!
;

0 value aa-adr
0 value aa-len
: init-aa-property  ( -- )  0 0 encode-bytes  to aa-len  to aa-adr  ;
: finish-aa-property  ( phandle -- )
   aa-len  if
      >r  aa-adr aa-len  " assigned-addresses"  r> put-package-property
   else
      drop
   then
;
\ "encode-phys" cannot be used to implement this, because it executes in
\ the instance context of the bus node, whereas encode-phys expects to
\ execute in the child instance context.
: +assigned-address  ( phys.hi paddr len -- )
   >r                                ( phys.hi paddr )  ( r: len )
   swap h# 8000.0000 or              ( paddr phys.hi' )
   aa-adr aa-len rot +i              ( paddr adr' len' )
   0+i  rot +i                       ( adr len )
   0+i  r> +i  to aa-len  to aa-adr  ( )
;

d# 16 buffer: already-assigned
: >assigned  ( phys.hi -- adr )
   h# 3c and  2 >>  already-assigned +
;

: (assign-address)  ( phys.lo,mid,hi size.lo,hi -- )
   \ Don't assign addresses for reg entries that refer to a base address
   \ register that has already been assigned by an earlier entry.
   2 pick  >assigned c@  if
      5drop  exit
   then                           ( phys.lo,mid,hi size.lo,hi )

   if                             ( phys.lo,mid,hi size.lo )
      ." Can't assign address ranges larger than 32-bits" cr
      4drop   exit
   then                           ( phys.lo,mid,hi size.lo )

   \ Mark as already assigned
   1  2 pick  >assigned dup 1+ >r c!  ( phys.lo,mid,hi size.lo ) ( r: adr)
   r> 2 pick 64mem?  if  1 swap c!  else  drop  then
   

   \ assign-pci-addr must be called with $call-self because the ultimate
   \ address assignment must occur in the context of the top-level PCI
   \ node within the PCI domain.  If prober is called from a PCI-PCI
   \ bridge node, the context must be changed to the top-level node
   \ so that the package values next-io and next-mem can be accessed.
   \ PCI-PCI bridges have assign-pci-addr methods that call up the tree.
   " assign-pci-addr" $call-self  ( phys.hi paddr actual-size )

   +assigned-address              ( )
;

\ Returns true if the given address should not be assigned.
defer avoid?  ( phys.hi -- flag )

\ Normally, we don't assign configuration space or non-relocatable addresses
\ In some systems, we may need to avoid additional devices or addresses;
\ in those system, avoid? can be extended as needed.
: (avoid?)  ( phys.hi -- flag )
   dup h# 300.0000 and  0=  swap h# 8000.0000 and 0<>  or
;
' (avoid?) to avoid?

: assign-address  ( phys.lo,mid,hi size.lo,hi -- )
   2 pick  avoid?  if                    ( phys.lo,mid,hi size.lo,hi )
      \ Mark it as assigned so the code that handles base address
      \ registers that don't appear in "reg" properties won't blast it.
      2drop  1 swap >assigned c!  2drop  exit   ( )
   then                                  ( phys.lo,mid,hi size.lo,hi )
   (assign-address)
;

: decode-reg-entry  ( adr len -- adr' len' phys.lo,mid,hi size.lo,hi )
   decode-int >r  decode-int >r        ( $' ) ( r: phys.hi phys.mid )
   decode-int r>  2swap r> -rot        ( phys.lo,mid,hi adr' len' )
   decode-int >r  decode-int >r        ( phys.lo,mid,hi adr'' len'' )
   rot >r 2swap r> r> r>               ( adr' len' phys.lo,mid,hi size.lo,hi )
;

\ Assign addresses for a child device
: assign-package-addresses  ( phandle -- )
   \ If there is already an assigned-addresses property, don't reassign.
   \ This handles the case where an on-board device has a preassigned address.
   " assigned-addresses" 2 pick get-package-property  0=  if  3drop exit  then

   already-assigned d# 16 erase		\ No base registers have been assigned
   init-aa-property
   >r
   " reg" r@ get-package-property  0=  if    ( adr len r: phandle )
      \ Get the configuration space address for later
      decode-reg-entry 2drop >r 2drop        ( adr' len' r: phandle phys.hi )

      begin  dup 0>  while                   ( adr len r: phandle phys.hi )
         decode-reg-entry assign-address     ( adr' len' r: phandle phys.hi )
      repeat                                 ( adr' len' r: phandle phys.hi )
      2drop                                  ( r: phandle phys.hi )

      \ Ensure that all the base registers have been assigned, even those
      \ that have no "reg" entry.

      \ Determine the last base address register according to whether or
      \ not this device is a PCI-PCI bridge.  We can't use "bridge?" because
      \ it requires that we be in an instance of the child node, but we
      \ are currently in the parent node and there is no longer a child
      \ instance.
      r@ h# 0e + self-b@  h# 7f and  1 =  if  h# 18  else  h# 28  then
                                             ( base-reg-end r: phandle phys.hi)
      \ Loop over the possible base address registers
      r@ +  r> h# 10 +  do                   ( r: phandle )
         i probe-base-reg  7 and 4 =  if   \ Skip mem64     ( )
            i find-boundary 1+  if                          ( )
               0 0
               h# 300.0000
               i or  0 0  (assign-address)                  ( )
            then                                            ( )
            8                                               ( increment )
         else   \ mem32 or I/O                              ( )
            i find-boundary 1+  if                          ( )
               0 0
               i probe-base-reg 1 and  if  h# 100.0000  else  h# 200.0000  then
               i or  0 0  (assign-address)                  ( )
            then                                            ( )
            4                                               ( increment )
         then                                               ( increment )
      +loop

   then
   r> finish-aa-property
;

\ Assign addresses for all children
: assign-all-addresses  ( -- )
   my-self ihandle>phandle  child
   begin  ?dup  while
      dup assign-package-addresses
      peer
   repeat
;

headers
: fix-adr  ( pci-devaddr size -- root-devaddr size )  swap pci-devaddr> swap  ;

[ifndef] get-property-patch
also forth definitions
headerless
: get-property-patch  ( adr len -- adr len voc )
   2dup " assigned-addresses"  $=  if
      " enable-apple-hack" ['] $call-parent catch  if  2drop  then
   then
   current-properties
;
patch get-property-patch current-properties get-property
headers
previous definitions
[then]

also forth definitions
: make-properties  ( -- )
   my-self  " make-function-properties" $call-parent
;
: assign-addresses  ( -- )
   my-self ihandle>phandle  " assign-package-addresses"  $call-parent
;
previous definitions

\ Probe the card at the address given by fcode$, setting my-address,my-space
\ in the resulting device node to the address given by reg$.
\
\ probe-self is meant to handle one PCI device (= 1 physical slot)
\ at a time.  Up to 8 functions are checked per device.  Each can have
\ a separate piece of FCode controlling it.

[ifdef] probe-exclusion
\ Check to see if pci node devices are excluded from probing
: (no-probe?)  ( dev-id no-probe-adr no-probe-len -- flag ) 3drop false ;
defer no-probe?    ' (no-probe?)  is  no-probe?
[then]

: probe-self  ( args$ reg$ fcode$ -- )
   " decode-unit" $call-self  nip nip              ( args$ reg$ phys.hi.dev )
   probemsg?  if  ." PCI PROBE-SELF:  Phys.hi = " dup . cr  then

[ifdef] probe-exclusion
   \ Check for "no probe" property
   " no-probe-list" get-my-property  if  " " else  get-encoded-string then
   2>r

   dup d# 11 rshift  h# 1f and  2r> no-probe?  if drop 2drop 2drop exit then
[then]

   max#functions  ?dup  if
      0  ?do  i probe-function  loop   ( args$ reg$ phys.hi.dev )
      diag-cr
   else
      " Nothing there" diag-type-cr
   then
   5drop
;

\ XXX TODO need to handle bus numbers somehow

also forth definitions
defer .prober-location
['] noop is .prober-location
previous definitions

headerless
\ Restore temporary allocation pointers to permanent values
: update-pointers  ( -- )  -1 " assign-pci-addr" $call-self  ;

headers
[ifndef] my-bus#
0 encode-int  0+i  " bus-range" property
[then]

: prober  ( adr len -- )

   update-pointers		\ Init the temporary allocation pointers
   begin  dup  while                              ( adr len )
      ascii , left-parse-string                   ( rem$ dev#$ )
      dup  if                                     ( rem$ dev#$ )
         .prober-location                         ( rem$ dev#$ )
         " "  2swap 2dup  probe-self              ( rem$ )
      else                                        ( rem$ dev#$ )
         2drop                                    ( rem$ )
      then                                        ( rem$ )
   repeat                                         ( null$ )
   2drop
   update-pointers		\ Re-init the temporary allocation pointers,
				\ thus erasing any probe-state mappings

   assign-all-addresses
   \ XXX TODO set-latency-timers  set-fast-back-to-backs
;
: master-probe  ( adr len -- )
   true to probe-state?
   prober

   \ Make permanent any address assignments that occurred during the
   \ execution of prober.
   next-mem to first-mem      next-io to first-io

   false to probe-state?
[ifdef] my-bus#
   my-bus# current-bus# max  to current-bus#
   my-bus#
[else]
   0
[then]
   encode-int  current-bus# +i  " bus-range" property
;
: prober-xt  ( -- adr )  ['] prober  ;

[ifdef] notdef   \ Sun uses a different approach; here is their version
\ Note that this version requires that a "prober" method exist in every
\ subordinate bus node
: master-probe  ( -- )
   \ If previously probed, we need to update current-bus#
   " bus-range"  get-my-property  0= if
      2 decode-ints drop nip nip is current-bus#
   else
      " my-pci-bus" $call-self  is current-bus#
   then

   true to probe-state?
   " prober"  $call-self
   false to probe-state?
   " my-pci-bus" $call-self  encode-int  current-bus# +i  " bus-range" property
;
[then]

\ This is called twice for each PCI-PCI bridge,
\ It is called with n=1 at the beginning of the bridge probing sequence,
\ in order to allocate a new bus number and establish base address values.
\ It is called with n=0 at the end of the bridge probing sequence,
\ in order to determine the "high water marks" of the bus numbers and
\ address ranges that were assigned during the (possibly recursive)
\ bridge probing process.

: allocate-bus#  ( n -- bus# first-mem first-io )
   current-bus# over +  dup to current-bus#			( n bus# )

   \ When beginning a new bridge (n=1), we use the permanent pointers
   \ (first-xx) in order to "erase" any temporary (probe-state) address
   \ assignments that resulted from probing ordinary devices.

   \ When finishing a bridge (n=0), we use the temporary pointers
   \ (next-xx) in order to capture the result of address
   \ assignments that resulted from "assign-addresses".

   swap  if  first-mem first-io  else  next-mem next-io  then	( bus# mem io )

   h#   1000 round-up dup to first-io   set-next-io		( bus# mem )
   h# 100000 round-up dup to first-mem  set-next-mem		( bus# )

   update-pointers						( bus# )
   first-mem first-io						( bus# mem' io' )
;

: map-out      ( vaddr size -- )                 " map-out"     $call-parent  ;

: dma-map-in   ( vaddr size cache? -- devaddr )
   " dma-map-in"  $call-parent  >pci-devaddr
;

: dma-alloc    ( size -- vaddr )                 " dma-alloc"   $call-parent  ;
: dma-free     ( vaddr size -- )                 " dma-free"    $call-parent  ;
: dma-map-out  ( vaddr devaddr size -- ) fix-adr " dma-map-out" $call-parent  ;
: dma-sync     ( vaddr devaddr size -- ) fix-adr " dma-sync"    $call-parent  ;
: dma-push     ( vaddr devaddr size -- ) fix-adr " dma-push"    $call-parent  ;
: dma-pull     ( vaddr devaddr size -- ) fix-adr " dma-pull"    $call-parent  ;

\ Define the display format for some PCI-specific properties
also known-int-properties definitions
[ifndef] alternate-reg
: alternate-reg       ( -- n )  reg  ;
: assigned-addresses  ( -- n )  reg  ;
[then]
previous definitions

[ifdef] notdef   \ Some code from Sun, untested in our environment
: lookup-ranges ( -- size phys.lo )
   decode-int drop decode-int drop decode-phys lxjoin >r
     decode-int >r decode-int r> lxjoin r> over 1- and
;

: set-avail-prop ( -- )
  select-dev
     my-self ihandle>phandle dup >r
     " available" 2dup r> get-package-property 0= if
        2drop 2dup delete-property
     then 2>r >r
     " ranges" r> get-package-property 0= if
        begin dup 0> while
           decode-int dup h# 0100.0000 = if
                 drop lookup-ranges next-io + swap next-io - >r >r
                      h# 8100.0000 " my-pci-bus" $call-self  h# 10 lshift or >r
                 else
                      h# 0200.0000 = if
                      lookup-ranges next-mem + swap next-mem - >r >r
                      h# 8200.0000 " my-pci-bus" $call-self  h# 10 lshift or >r
                 else
                      lookup-ranges 2drop
                 then then
        repeat
        2drop then
        0 0 encode-bytes
        r> +i 0+i r> +i r> xlsplit swap >r +i r> +i
        r> +i 0+i r> +i r> xlsplit swap >r +i r> +i
        2r> property
   unselect-dev
;
headerless
[then]
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
