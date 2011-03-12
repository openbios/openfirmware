\ See license at end of file
purpose: EC commands that are the same for all XO versions

: ec-api-ver@    ( -- b )  h# 08 ec-cmd-b@  ;
: bat-voltage@   ( -- w )  h# 10 ec-cmd-w@  ;
: bat-current@   ( -- w )  h# 11 ec-cmd-w@  ;
: bat-acr@       ( -- w )  h# 12 ec-cmd-w@  ;
: bat-temp@      ( -- w )  h# 13 ec-cmd-w@  ;
: ambient-temp@  ( -- w )  h# 14 ec-cmd-w@  ;
: bat-status@    ( -- b )  h# 15 ec-cmd-b@  ;
: bat-soc@       ( -- b )  h# 16 ec-cmd-b@  ;

: ec-abnormal@   ( -- b )  h# 1f ec-cmd-b@  ;

: reset-ec       ( -- )    h# 28 ec-cmd  ;

: autowack-on    ( -- )  1 h# 33 ec-cmd-b!  ;
: autowack-off   ( -- )  0 h# 33 ec-cmd-b!  ;

: mppt-active@   ( -- b )  h# 3d ec-cmd-b@  ;
: mppt-limit@    ( -- b )  h# 3e ec-cmd-b@  ;
: mppt-limit!    ( b -- )  h# 3f ec-cmd-b!  ;
: mppt-off       ( -- )    h# 40 ec-cmd  ;
: mppt-on        ( -- )    h# 41 ec-cmd  ;
: vin@           ( -- b )  h# 42 ec-cmd-b@  ;

\ LICENSE_BEGIN
\ Copyright (c) 2010 FirmWorks
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
