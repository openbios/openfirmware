\ See license at end of file

decimal

user-size-t constant user-size

\ Initial user number

[ifdef] #user-init
#user-init
[else]
0
[then]

[ifndef] run-time
\ First 5 user variables are used for multitasking
     dup user link       \ link to next task
/n + dup user entry      \ entry address for this task
/n + dup user saved-ip
/n + dup user saved-rp
/n + dup user saved-sp
[then]

\ next 2 user variables are used for booting
/n + dup user up0     \ initial up
/n + dup user #user   \ next available user location
/n +     #user-t !

/n constant #ualign
: ualigned  ( n -- n' )  #ualign round-up  ;

: ualloc  ( #bytes -- new-user-number )  \ allocates user space
   #user @ user-size >=  ( ?? ) abort" User area used up!"   ( #bytes )

   \ If we are allocating fewer bytes than the alignment granularity,
   \ it is safe to assume that strict alignment is not required.
   \ For example, a 2-byte token doesn't have to be aligned on a 4-byte
   \ boundary.
   ( #bytes )
   #user @  over #ualign >=  if  ualigned dup #user !  then  ( #bytes user# )

   swap #user +!
;

[ifndef] run-time
: nuser  \ name  ( -- )  \ like user but automatically allocates space
   /n ualloc user
;
: tuser  \ name  ( -- )  \ like user but automatically allocates space
   /token ualloc user
;
: auser  \ name  ( -- )  \ like user but automatically allocates space
   /a ualloc user
;
[then]

nuser sp0          \ initial parameter stack
nuser rp0          \ initial return stack

headerless
\ This is the beginning of the initialization chain
: init  ( -- )  up@ link !  ;	\ Initially, only one task is active
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
