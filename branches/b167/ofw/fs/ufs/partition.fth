\ See license at end of file
purpose: Handler for UFS-style partition maps

struct ( ufs partition )
4 field >ufsp-size
4 field >ufsp-offset
4 field >ufsp-fsize
1 field >ufsp-fstype
1 field >ufsp-frag
2 field >ufsp-cpg
constant /ufs-part

struct ( ufs label )
4 field >ufs-magic1
d# 20 field >ufs-dtype	\		 4
d# 16 field >ufs-pack	\		18
4 field >ufs-bps	\ 200
4 field >ufs-spt	\ 3f
4 field >ufs-tpc	\ 10		30
4 field >ufs-cpu	\ 9b4	
4 field >ufs-spc	\ 3f0
4 field >ufs-spu	\ 2634c0	3c
4 field >ufs-spares
4 field >ufs-altc
d# 60 field >ufs-hard
4 field >ufs-magic2
2 field >ufs-chksum
2 field >ufs-parts
4 field >ufs-bsize
4 field >ufs-sbsize
/ufs-part field >ufs-part
drop

h# 8256.4557 constant ufs-magic
defer short@  ( adr -- w )  ' be-w@ to short@
defer int@    ( adr -- l )  ' be-l@ to int@

\ Decode the partition map entry specified by "ufs-partition" and set
\ "sector-offset" and "size-low,size-high" from the information therein.
: select-ufs-partition   ( -- )
   sector-buf >ufs-part 			 ( partition-map )
   ufs-partition dup 0=  if  drop ascii a  then  ( partition-map partition )
   lcc ascii a -				 ( partition-map partition# )
   sector-buf >ufs-parts le-w@ over u<=  abort" No such UFS partition"
   /ufs-part * +				 ( partition-entry )
   dup >ufsp-fstype c@ 0=  abort" Bad filesystem type in UFS partition map"
                                                 ( partition-entry )
   dup >ufsp-offset le-l@ sector-offset +        ( partition-entry offset )
   to sector-offset	                         ( partition-entry )
   >ufsp-size le-l@   sector-buf >ufs-bps le-l@	 ( #blocks /block )
   um*  to size-high  to size-low                ( )
;

\ Return true if the portion of the disk that is currently selected
\ contains a Unix partition map.
: ufs-partition-map?  ( -- flag )
   1 read-sector
   sector-buf >ufs-magic1 le-l@  ufs-magic  = 
   sector-buf >ufs-magic2 le-l@  ufs-magic  =  and
;


\ Set "sector-offset" and "size-low,size-high" from the information
\ in the unpartitioned Unix file system.
d# 16 constant sb-sector
: direct-ufs  ( -- )
   ufs-partition 0> abort" No UFS partition map"
   sb-sector read-sector
   sector-buf 9 la+ int@        ( #blocks )
   sector-buf d# 12 la+ int@    ( #blocks /block )
   um* to size-high  to size-low
;

\ Return true if the portion of the disk that is currently selected
\ contains an unpartitioned Unix file system.
: direct-ufs?  ( -- flag )
   \ The super-block starts at sector 16, and the magic number is at
   \ offset h#55c from the beginning of the super-block, i.e. super-block
   \ sector 2.
   sb-sector 2+  read-sector   
   sector-buf h# 15c + be-l@  h# 11954 =  if
      ['] be-l@ to int@  ['] be-w@ to short@
      true exit
   then
   sector-buf h# 15c + le-l@  h# 11954 =  if
      ['] le-l@ to int@  ['] le-w@ to short@
      true exit
   then
   false
;

: ufs?  ( -- )
   ufs-partition-map?  if  true exit  then
   direct-ufs?
;

: ufs-map   ( -- )
   ufs-type to partition-type
   ufs-partition-map?  if  select-ufs-partition exit  then
   direct-ufs?  if  direct-ufs exit  then
   true abort" Bad UFS file system"
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
