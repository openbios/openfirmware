purpose: Driver for storing reboot info in a FLASH sector
\ See license at end of file

\ This device is subordinate to the "flash" device node.
\ It accesses reboot information stored in a FLASH sector.

\ The reboot information could be updated on every system reboot. To
\ extend the lifetime of the FLASH, we use an incremental writing strategy
\ that minimizes the number of times that the sector must be rewritten.
\ It works as follows:
\
\ The sector contains all h# ff bytes when it is completely erased.
\ If it contains all ff's, this is a normal boot, not a reboot.
\ Otherwise, the first non-ff byte is the reboot count byte.  If that
\ count byte is 0, this is a normal boot, not a reboot.
\ Otherwise, this is a reboot, and the count-1 following bytes
\ are the reboot argument string.  (If count is 1, this is a reboot with
\ a null argument string.)
\ When the firmware reads the reboot info during the reboot process, it sets
\ the count byte to zero (which can be done without erasing the sector), thus
\ cancelling the reboot information.
\ To initiate a new reboot, the driver places the new count and argument
\ string before the old one.  The driver erases the entire sector only
\ when it fills up so there isn't enough space for the new string.

" reboot-info" device-name

\ Requires that /device be defined externally
my-address my-space /device reg

: sector-buf  ( -- adr )  " 'base-adr" $call-parent  my-space +  ;

external
: open  ( -- flag )  true  ;
: close  ( -- )  ;

: reboot-byte  ( -- adr byte )
   sector-buf   /device  0  do     ( adr )
      dup c@  h# ff <>  if                        ( adr )
         dup c@ unloop exit                       ( adr byte )
      then                                        ( adr )
      1+                                          ( adr' )
   loop                                           ( adr )
   0                                              ( adr byte )
;

: write-byte  ( byte offset -- )
   my-space +  " write-byte" $call-parent
   " read-mode" $call-parent
;
: write-bytes  ( adr offset len -- )
   swap my-space + swap  " write-bytes" $call-parent
;

: erase-sector  ( -- )  my-space  " sector-erase" $call-parent  ;

: find-offset  ( len -- actual offset )
   /device min                      ( actual )
   reboot-byte drop  sector-buf -   ( actual last-offset )
   over -                           ( actual new-offset )
   dup 0<  if                       ( actual new-offset )
      drop  erase-sector            ( actual )
      /device  over -               ( actual offset )
   then                             ( actual offset )
;

: read  ( adr len -- actual )
   reboot-byte                        ( adr len reboot-adr count )
   dup 0=  if  4drop -1 exit  then    ( adr len reboot-adr count )
   0 2 pick sector-buf -  write-byte  ( adr len reboot-adr count )
   1 /string  rot min                 ( adr reboot-adr' actual )
   >r  swap r@ move  r>               ( reboot-adr actual )
;

: write  ( adr len -- actual )
   1+ find-offset                   ( adr actual+1 offset )
   2dup write-byte                  ( adr actual+1 offset )
   swap  1 /string                  ( adr offset+1 actual )
   dup >r  write-bytes              ( r: actual )
   r>
;
: size  ( -- d )  /device 0  ;

\ LICENSE_BEGIN
\ Copyright (c) 2008 FirmWorks
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
