purpose: CPU-dependent definitions for the source-level debugger
\ See license at end of file

headerless
\ \needs at		: at  ( row column -- )  2drop  ;
\needs kill-line	: kill-line  ( -- )  ;

hex

: low-dictionary-adr  ( -- adr )  origin  init-user-area +  ;

nuser debug-next  \ Pointer to "next"
vocabulary bug   bug also definitions
nuser 'debug   \ code field for high level trace
nuser <ip      \ lower limit of ip
nuser ip>      \ upper limit of ip
nuser cnt      \ how many times thru debug next

\ Since we use a shared "next" routine, slow-next and fast-next are no-op's
alias slow-next 2drop  ( high low -- )
alias fast-next 2drop  ( high low -- )

: copy-next  ( -- )
   \ Copy the normal next routine from the user area
   here  5 /n*  dup  allot   ( adr size )
   up@ -rot cmove
;

label normal-next
   copy-next
end-code

label debnext
   'user <ip  lwz  t0,*
   addi   t2,ip,4
   cmpl   0,0,t2,t0
   >= if
      'user ip>   lwz  t0,*
      cmpl  0,0,t2,t0
      < if
         'user cnt   lwz  t0,*
         set    t1,2
         addi   t0,t0,1
	 'user cnt  stw  t0,*
	 cmp   0,0,t0,t1
	 = if
            set  t0,0
	    'user cnt  stw  t0,*

            set  t0,h#873d0004	\ lwzu  w,4(ip)
	    stw  t0,0(up)

	    dcbf r0,up		\ flush cache
	    icbi r0,up		\ flush cache
	    isync
	    
            \ Machine code for   'debug token@ execute
            'user 'debug   lwz  w,*

            \ Tail of "NEXT"
            lwzux   t1,w,base	\ Read the contents of the code field
            add     t1,t1,base	\ Relocate
            mtspr   lr,t1
            bclr    20,0	\ Execute the code
         then
      then
   then
   copy-next   
end-code

\ Fix the next routine to use the debug version
\ XXX This assumes that the user area and the dictionary are within
\ 16 MBytes of one another.
: pnext  ( -- )
   debnext up@ - h# 3ffffff and  h# 48000000 or  up@ instruction!
;

\ Turn off debugging
\ h# 873d0004  is  "lwzu  w,4(ip)", the first instruction of "next"
: unbug  ( -- )   h# 873d0004 up@ instruction!  ;

forth definitions
syscall-vec @  0=  if
unbug
then
headers

\ LICENSE_BEGIN
\ Copyright (c) 2007 FirmWorks
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
