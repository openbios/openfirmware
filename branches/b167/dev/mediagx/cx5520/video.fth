\ See license at end of file
purpose: Methods for the 5520 Display Subsystem Extensions

hex
headers

external

\ The MediaGX video driver should call init-video to setup the
\ 5520 display subsystem properly.

: temp-map-video-reg  ( -- command )
   map-video-reg
;
: temp-unmap-video-reg  ( command -- )
   video-base  /video-reg  map-out
;

: init-video  ( -- )
   temp-map-video-reg

   0000.0000 00 video-l!		\ video config register
   0031.0100 04 video-l!		\ display config register

   temp-unmap-video-reg
;

\ The MediaGX video driver should call video-on to enable syncs
\ from the 5520 to CRT.

: video-on  ( -- )
   temp-map-video-reg

   04 video-l@ 2f or 04 video-l!	\ power DAC, enable sync, enable display

   temp-unmap-video-reg
;

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
