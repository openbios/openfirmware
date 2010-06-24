purpose: User interface for NAND multicast updater - reception
\ See license at end of file

: #nb  ( channel# -- )
   depth 1 < abort" Usage: channel# #nb"
   secure$ rot
   " rom:nb_rx ether:%d %s" sprintf boot-load go
;
: meshnand
   use-mesh
   false to already-go?
   " boot rom:nb_rx ,,239.255.1.2" eval
;

: ucastnand
   false to already-go?
   " boot rom:nb_rx 10.20.0.16,,10.20.0.44" eval
;

: nb1  ( -- )       1 #nb  ;
: nb6  ( -- )       6 #nb  ;
: nb11  ( -- )  d# 11 #nb  ;

: nandblaster  ( -- )
   find-multinand-server abort" No multicast NAND server"  ( chan# )
   #nb
;
alias nb nandblaster


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
