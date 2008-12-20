purpose: Buffers for saving program state
\ See license at end of file

headers
\ A place to save the CPU registers when we take a trap
0 value cpu-state               \ Pointer to CPU state save area

headerless
: >state  ( offset -- adr )  cpu-state  +  ;

\ Don't use buffer: for these because we may need to instantiate them
\ before the buffer: mechanism has been initialized.
0 value pssave		\ Forth data stack save area
0 value rssave		\ Forth return stack save area

headers
defer .exception		\ Display the exception type
defer handle-breakpoint		\ What to do after saving the state

\ LICENSE_BEGIN
\ Copyright (c) 1985-1994 FirmWorks
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
