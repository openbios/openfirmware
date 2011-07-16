\ See license at end of file
purpose: Driver for the clock generator chip connected to the SMBus

h# d2 2/ constant clkgen-smbus-id
h# 15 constant /clkgen-buf
d# 32 buffer: clkgen-buf  \ Extra large in case the clock generator changes

: clkgen-read  ( -- )
   enable-smbus                          ( )
   clkgen-smbus-id smbus-acquire         ( )
   clkgen-buf /clkgen-buf 0  smbus-read  ( #read )
   /clkgen-buf <> abort" clkgen-read: smbus-read returned wrong byte count"
   smbus-release                         ( )
;

: clkgen-b@  ( reg# -- value )  clkgen-read  clkgen-buf + c@  ;

: clkgen-b!  ( value reg# -- )
   enable-smbus                     ( value reg# )
   clkgen-smbus-id smbus-acquire    ( value reg# )
   swap clkgen-buf c!               ( reg# )
   clkgen-buf 1  rot  smbus-write   ( )
   smbus-release                    ( )
;

\ We don't need to call disable-unused-clocks in stand-init because
\ it is done in early-startup so it will affect resume-from-S3 too.
: disable-unused-clocks  ( -- )   h# 03 5 clkgen-b!  ;
: enable-unused-clocks   ( -- )   h# df 5 clkgen-b!  ;

\ LICENSE_BEGIN
\ Copyright (c) 2009 FirmWorks
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
