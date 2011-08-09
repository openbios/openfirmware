purpose: USB Data Packet Definitions
\ See license at end of file

hex
headers

d# 128 constant #max-dev
d#  16 constant #max-endpoint

0 constant speed-full
1 constant speed-low
2 constant speed-high

     8 constant /pipe0
1.0000 constant /cfg
   100 constant /str

\ Structure of devices requests as defined in USB spec.
struct  ( standard device requests )
1 field >dr-rtype			\ bmRequestType
1 field >dr-request			\ bRequest
2 field >dr-value			\ wValue
2 field >dr-index			\ wIndex
2 field >dr-len				\ wLength
					\ Data
constant /dr

\ >dr-type constants
00 constant DR_OUT
80 constant DR_IN
00 constant DR_STANDARD
20 constant DR_CLASS
40 constant DR_VENDOR
00 constant DR_DEVICE
01 constant DR_INTERFACE
02 constant DR_ENDPOINT
03 constant DR_OTHERS
DR_CLASS DR_DEVICE    or constant DR_HUB
DR_CLASS DR_OTHERS    or constant DR_PORT
DR_CLASS DR_INTERFACE or constant DR_HIDD

\ >dr-request constants
01 constant CLEAR_FEATURE
08 constant GET_CONFIGURATION
06 constant GET_DESCRIPTOR
0a constant GET_INTERFACE
02 constant GET_STATE
00 constant GET_STATUS
05 constant SET_ADDRESS
09 constant SET_CONFIGURATION
07 constant SET_DESCRIPTOR
03 constant SET_FEATURE
0b constant SET_INTERFACE
0c constant SYNCH_FRAME

\ >dr-value (upper byte) for get-/set-descriptor constants
\ lower-byte is descriptor index
01 constant DEVICE
02 constant CONFIGURATION
03 constant STRING
04 constant INTERFACE
05 constant ENDPOINT
0b constant INTERFACE_ASSO
29 constant HUB

\ Hub Class Feature Selectors (dr-value)
00 constant C_HUB_LOCAL_POWER
01 constant C_HUB_OVER_CURRENT
00 constant PORT_CONNECTION
01 constant PORT_ENABLE
02 constant PORT_SUSPEND
03 constant PORT_OVER_CURRENT
04 constant PORT_RESET
08 constant PORT_POWER
09 constant PORT_LOW_SPEED
d# 16 constant C_PORT_CONNECTION
d# 17 constant C_PORT_ENABLE
d# 18 constant C_PORT_SUSPEND
d# 19 constant C_PORT_OVER_CURRENT
d# 20 constant C_PORT_RESET
d# 21 constant PORT_TEST
d# 22 constant PORT_INDICATOR

\ Use tmp-l to make sure that le-l! and le-w! are atomic writes

variable tmp-l
: le-w@   ( a -- w )   dup c@ swap ca1+ c@ bwjoin  ;
: (le-w!) ( w a -- )   >r  wbsplit r@ ca1+ c! r> c!  ;
: le-w!   ( w a -- )   swap tmp-l (le-w!) tmp-l w@ swap w!  ;

: le-l@   ( a -- l )   >r  r@ c@  r@ 1+ c@  r@ 2+ c@  r> 3 + c@  bljoin  ;
: (le-l!) ( l a -- )   >r lbsplit  r@ 3 + c!  r@ 2+ c!  r@ 1+ c!  r> c!  ;
: le-l!   ( l a -- )   swap tmp-l (le-l!) tmp-l l@ swap l!  ;


headers

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
