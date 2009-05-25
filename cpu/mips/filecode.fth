purpose: Code words to support the file system interface
\ See license at end of file

code ln+   (s n1 n2 -- n3 )   sp  t0  pop   tos t0  tos  addu   c;

\ &ptr is the address of a pointer.  fetch the pointed-to
\ character and post-increment the pointer
 
code @c@++ ( &ptr -- char )
   tos   t0   get     \ Fetch the pointer
   tos   t1   move    \ Copy of the address
   t0 0  tos  lbu     \ Get the byte
   t0 1  t0   addiu   \ Increment the pointer   
   t0    t1   put     \ Replace the pointer
c;
 
\ &ptr is the address of a pointer.  store the character into
\ the pointed-to location and post-increment the pointer

code @c!++ ( char &ptr -- )
   tos    t0     get     \ Fetch the pointer
   sp     t1     pop     \ char in t1 
   t1     t0  0  sb      \ Put the byte
   t0  1  t0     addiu   \ Increment the pointer   
   t0     tos    put     \ Replace the pointer
   sp     tos    pop     \ Fixup top of stack
c;

\ "adr1 len2" is the longest initial substring of the string "adr1 len1"
\ that does not contain the character "char".  "adr2 len1-len2" is the
\ trailing substring of "adr1 len1" that is not included in "adr1 len2".
\ Accordingly, if there are no occurrences of that character in "adr1 len1",
\ "len2" equals "len1", so the return values are "adr1 len1  adr1+len1 0"

code split-string  ( adr1 len1 char -- adr1 len2  adr1+len2 len1-len2 )
			\ char in tos
   sp 0      t1   lw	\ len1
   sp 4      t0   lw	\ adr1
   sp -4     sp   addiu	\ Make room for extra return value

   t1 $0 <>  if			\ If string not empty
   t0 t1     t3   addu		\ Delay: Loop limit
      begin			   \ t0 points to next character
         t0 0   t2   lbu	   \ Get the next character
         bubble
         tos t2 = if 	           \ Exit if delimiter found
            t0 1       t0   addiu  \ Delay: Increment address

            t0 -1      t0   addiu  \ Cancel last increment

            t3 t1      t1   subu   \ Reconstruct adr1
            t0 t1      t1   subu   \ Compute len2
            t1       sp 4   sw	   \ .. and store on stack

            t0       sp 0   sw	   \ store adr1+len2 on stack

            t3 t0     tos   sub	   \ Return len1-len2
            next
         then
      t0 t3 = until
      nop
   then
   \ The test character is not present in the input string

   t3      sp 0   sw	\ Store adr1+len2 on stack
   $0       tos   move	\ Return rem-len=0
c;

\ Splits a buffer into two parts around the first line delimiter
\ sequence.  A line delimiter sequence is either CR, LF, CR followed by LF,
\ or LF followed by CR.
\ adr1 len2 is the initial substring before, but not including,
\ the first line delimiter sequence.
\ adr2 len3 is the trailing substring after, but not including,
\ the first line delimiter sequence.

code parse-line  ( adr1 len1 -- adr1 len2  adr1+len2 len1-len2 )
   tos       t1   move	\ len1
   sp 0      t0   lw	\ adr1
   sp -8     sp   addiu	\ Make room for extra return values

   $0 h# 0a  tos  addiu	\ Delimiter 1
   $0 h# 0d  t4   addiu	\ Delimiter 2

   t1 $0 <>  if		\ If string not empty
   t0 t1     t3   addu	\ Delay: Loop limit
      begin			\ t0 points to next character
         t0 0   t2   lbu	\ Get the next character
         bubble

         tos t2  <> if		\ Compare to linefeed
         t0 1   t0   addiu	\ Delay: Increment address
         t4  t2  = if		\ Compare to return
         nop			\ Delay
         but then	   	\ target of linefeed comparison branch
            \ One of the delimiters matches

            t3 t1  t1  subu	\ Reconstruct adr1
            t0 t1  t1  subu	\ Compute len2
            t1 -1  t1  addiu	\ Account for incremented pointer
            t1   sp 4  sw	\ .. and store on stack

            \ Check next character too, unless we're at the
            \ end of the buffer
            t0 t3 <>  if  nop
            t0 1  t5   lbu	\ Get the next character
               bubble
               \ Compare next character to other delimiter
               tos t2 =  if  nop  t4 tos move  then  \ Other delim in tos
               tos t5 <>  if  nop	\ If nextchar equals other delim...
                  t0 1   t0  addiu	\ ... consume it
               then
            then
            t0    sp 0  sw	\ store adr1+len2 on stack
            t3 t0  tos  subu	\ Return len1-len2
            next
         then
      t0 t3 = until
      nop
   then
   \ There is no line delimiter in the input string

   t0    sp 0   sw		\ Store adr1+len2 on stack
   $0    tos    move		\ Return rem-len=0
c;

headers

nuser delimiter

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
