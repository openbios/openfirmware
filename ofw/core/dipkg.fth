\ See license at end of file
purpose: Demand-loading of packages stored as dropin drivers

: load-dropin-package  ( name$ -- false  |  phandle true )
   [char] / split-after                        ( name$ path$ )
   locate-device  if  2drop false exit  then   ( name$ phandle )
   rpush-order                                 ( name$ phandle r: old-order )
   push-package                                ( name$ )
   2dup  any-drop-ins?  if                     ( name$ )
      true to autoloading?                     ( name$ )
      new-device                               ( name$ )
      base @ >r				       ( name$ ) ( r: base )
      2dup 2>r do-drop-in                      ( )       ( r: base name$ )
      2r> device-name                          ( )       ( r: base )
      r> base !				       ( )	 ( r: )
      current-device true                      ( phandle true )
      finish-device                            ( phandle true )
      false to autoloading?                    ( name$ )
   else                                        ( name$ )
      2drop false                              ( false )
   then                                        ( false | phandle true )
   rpop-order                                  ( false | phandle true )
;
' load-dropin-package to load-package
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
