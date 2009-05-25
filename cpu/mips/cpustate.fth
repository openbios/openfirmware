purpose: Buffers for saving program state
\ See license at end of file

headers
\ Data structures defining the CPU state saved by a breakpoint trap.
\ This must be loaded before either catchexc.fth or register.fth,
\ and is the complete interface between those 2 modules.

headerless
\ A place to save the CPU registers when we take a trap
0 value /save-area
0 value cpu-state

: clear-save-area  ( -- )  cpu-state /save-area erase  ;

h# 40 constant ua-size

0 value pssave		\ A place to save the Forth data stack
0 value rssave		\ A place to save the Forth return stack
ua-size  buffer: uasave	\ A place to save part of the Forth user area
			\ we really want to save saved-rp and saved-sp

headers
defer .exception	\ Display the exception type
defer handle-breakpoint	\ What to do after saving the state

: init  ( -- )
   init   /save-area alloc-mem to cpu-state  clear-save-area
;

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
