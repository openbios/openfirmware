purpose: CPU node
\ See license at end of file

0 value l2-cache-node
defer probe-l2-cache
' false to probe-l2-cache  ( -- false | #sets #bytes write-back? true )

\ A hook that can be used on a per-platform basis to amend any
\ information that needs to be changed.
defer get-cpu-info   ( -- )
' noop to get-cpu-info

headerless
\ Interfaces to platform-dependent code to determine the status of
\ CPUs in an MP system.
1 value max#cpus

\ keep track of cpu#; may be used by get-cpu-info and probe-l2-cache
0 value cpu	

defer firmware-cpu#  ( -- cpu# )
' 0 to firmware-cpu#	

defer cpu-started?  ( cpu# -- flag )
' 0= to cpu-started?

headers
d# 100,000,000 value cpu-clock-frequency

' cpu-node  " cpu" chosen-variable

headerless
0 value cpu-package

headers
: make-l2-cache-node  ( #sets size write-back? -- )
   new-device
      " l2-cache" device-name
      " cache" device-type
      0 0 encode-bytes  " cache-unified" property   \ Assumes a unified cache

      drop   ( #sets size )
      2dup " i-cache-size" integer-property  " i-cache-sets" integer-property
           " d-cache-size" integer-property  " d-cache-sets" integer-property

      d# 32 " d-cache-block-size" integer-property
      d# 32 " i-cache-block-size" integer-property

      current-device				( phandle )
   finish-device
   dup to l2-cache-node
   " l2-cache" integer-property
;
headerless

: make-cache-props  ( ts tsz d$s d$b d$sz i$s i$b i$sz -- )
   " i-cache-size"       integer-property
   dup to /icache-block
   " i-cache-block-size" integer-property
   " i-cache-sets"       integer-property
   " d-cache-size"       integer-property
   dup to /dcache-block
   " d-cache-block-size" integer-property
   " d-cache-sets"       integer-property
   " tlb-size"           integer-property
   " tlb-sets"           integer-property
;
: start-cpu-node  ( ts tsz d$s d$b d$sz i$s i$b i$sz adr len -- )
   new-device
   ( tlb-params cache-params adr len )  device-name
   " cpu" device-type
;
: make-603-node  ( -- )
   " PowerPC,603" start-cpu-node
   d# 64  d# 128   d# 128  d# 32  d# 8192  3dup  make-cache-props
;
: make-604-node  ( -- )
   " PowerPC,604" start-cpu-node
   d# 128  d# 256   d# 128  d# 32  d# 16384   3dup  make-cache-props
;
: make-603e-node  ( -- )
   " PowerPC,603e" start-cpu-node
   d# 64  d# 128  d# 128  d# 32  d# 16384  3dup  make-cache-props
;
: make-603ev-node  ( -- )
   " PowerPC,603ev" start-cpu-node
   d# 64  d# 128  d# 128  d# 32  d# 16384  3dup  make-cache-props
;
: make-603eva-node  ( -- )
   " PowerPC,603evARTHUR" start-cpu-node
   d# 128  d# 256   d# 128  d# 32  d# 32768   3dup  make-cache-props
;
: make-604ev-node  ( -- )
   " PowerPC,604ev" start-cpu-node
   d# 128  d# 256   d# 256  d# 32  d# 32768   3dup  make-cache-props
;
: make-604ev5-node  ( -- )
   " PowerPC,604ev5" start-cpu-node
   d# 128  d# 256   d# 256  d# 32  d# 32768   3dup  make-cache-props
;
: make-620-node  ( -- )
   " PowerPC,620" start-cpu-node
   d# 128  d# 128   d# 64  d# 64  d# 32768   3dup  make-cache-props
;
: make-704-node  ( -- )
   " PowerPC,X704" start-cpu-node
   d# 32  d# 128   d# 64  d# 32  d# 2048   3dup  make-cache-props
;
: make-8240-node  ( -- )
   " PowerPC,603ev" start-cpu-node
   d# 64  d# 128  d# 128  d# 32  d# 16384  3dup  make-cache-props
;
: make-823-node  ( -- )
   " PowerPC,MPC823" start-cpu-node
   d# 32  d# 256   d# 32  d# 16  d# 1024   d# 64  d# 16  d# 2048  make-cache-props
;

headers
0 0  " "  " /"  begin-package
" cpus" device-name
1 " #address-cells" integer-property
0 " #size-cells" integer-property

: decode-unit  ( adr len -- phys )  $number  if  0  then  ;
: encode-unit  ( phys -- adr len )  (u.)  ;

: open  ( -- true )  true  ;
: close  ( -- )  ;
end-package

headerless

defer make-cpu-extras	' noop to make-cpu-extras

: make-cpu-node  ( cpu# -- )
   to cpu
   " /cpus" find-device

   cpu-version  case
       3 of  make-603-node    endof
       4 of  make-604-node    endof
       6 of  make-603e-node   endof
       7 of  make-603ev-node  endof
       8 of  make-603eva-node endof
       9 of  make-604ev-node  endof
   h#  a of  make-604ev5-node endof
   d# 20 of  make-620-node    endof
   h# 50 of  make-823-node    endof
   h# 54 of  make-704-node    endof	\ proto... remove!
   h# 60 of  make-704-node    endof
   h# 81 of  make-8240-node   endof
   ( default ) ." make-cpu-node: Unknown CPU Version " dup . cr
   endcase

   get-cpu-info

   \ ??? cpu-version " arc-key" integer-property

   counts/ms d# 1000 *  " timebase-frequency" integer-property

   cpu firmware-cpu# =  if  current-device to cpu-package  then

   cpu " reg" integer-property

   " clock-frequency"  " /" find-package  drop  get-package-property  0=  if
      " bus-frequency" property
   then

   cpu-clock-frequency " clock-frequency" integer-property
   " : open true ; : close ;" evaluate
   
   \ check for in-line (or unshared) cache
   probe-l2-cache  if
      make-l2-cache-node
   else
      l2-cache-node ?dup if  " l2-cache" integer-property  then
   then

   make-cpu-extras

   finish-device
   device-end
;

: make-cpu-nodes  ( -- )
   \ check for look-aside cache
   " /cpus" find-device   -1 to cpu
      probe-l2-cache  if  make-l2-cache-node  then
   device-end
   max#cpus 0  do
      i cpu-started?  if  i make-cpu-node  then
   loop
;
headers

stand-init: CPU nodes
   make-cpu-nodes
   cpu-package  open-phandle  cpu-node !
;

\ LICENSE_BEGIN
\ Copyright (c) 2007 FirmWorks
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
