\ See license at end of file
purpose: Loadfile for Graphics Controllers

hex
headers

fload ${BP}/dev/video/controlr/vga.fth		\ Load generic VGA routines
fload ${BP}/dev/video/controlr/s3.fth		\ Load S3 routines
fload ${BP}/dev/video/controlr/cirrus.fth	\ Load Cirrus routines
fload ${BP}/dev/video/controlr/mga.fth		\ Load MGA routines
fload ${BP}/dev/video/controlr/glint.fth	\ Load Glint routines
fload ${BP}/dev/video/controlr/viper.fth	\ Load Viper routines
fload ${BP}/dev/video/controlr/i128.fth		\ Load I128 routines
fload ${BP}/dev/video/controlr/ct65550.fth	\ Load Chips and Technology routines\ LICENSE_BEGIN
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
