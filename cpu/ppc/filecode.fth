purpose: File system support code for PowerPC
\ See license at end of file

headerless
\ signed mixed mode addition
code ln+   (s n1 n2 -- n3 )  pop-to-t0   add  tos,tos,t0  c;

\ &ptr is the address of a pointer.  fetch the pointed-to
\ character and post-increment the pointer
 
code @c@++ ( &ptr -- char )
   lwz  t0,0(tos)	\ Fetch the pointer
   mr   t1,tos		\ Copy of the address
   lbz  tos,0(t0)	\ Get the byte
   addi t0,t0,1		\ Increment the pointer   
   stw  t0,0(t1)	\ Replace the pointer
c;
 
\ &ptr is the address of a pointer.  store the character into
\ the pointed-to location and post-increment the pointer

code @c!++ ( char &ptr -- )
   lwz  t0,0(tos)	\ Fetch the pointer
   lwz  t1,0(sp)	\ char in t1
   stb  t1,0(t0)	\ Put the byte
   addi t0,t0,1		\ Increment the pointer   
   stw  t0,0(tos)	\ Replace the pointer
   lwz  tos,1cell(sp)	\ Fixup top of stack
   addi sp,sp,2cells	\ Adjust stack pointer
c;

headers
\ "adr1 len2" is the longest initial substring of the string "adr1 len1"
\ that does not contain the character "char".  "adr2 len1-len2" is the
\ trailing substring of "adr1 len1" that is not included in "adr1 len2".
\ Accordingly, if there are no occurrences of that character in "adr1 len1",
\ "len2" equals "len1", so the return values are "adr1 len1  adr1+len1 0"

code split-string  ( adr1 len1 char -- adr1 len2  adr1+len2 len1-len2 )
			\ char in tos
   lwz  t1,0(sp)	\ len1
   lwz  t0,1cell(sp)	\ adr1

   cmpi 0,0,t1,0	\ Test length
   0<> if
      mfspr  t5,ctr
      mtspr  ctr,t1

      addi  t0,t0,-1	\ Account for pre-increment

      begin
         lbzu  t3,1(t0)		\ get the next character
         cmp   0,0,t3,tos	\ Look for the terminator character
      bc  0,2,*

      =  if			\ Found terminator?
         mfspr  tos,ctr		\ len1-len2-1
         addi   tos,tos,1	\ len1-len2
         subfc  t1,tos,t1	\ len2	( Use subfc for POWER compatibility)
         stw    t1,0(sp)	\ store len2 on stack

	 stwu   t0,-1cell(sp)	\ Store adr1+len2 on stack
         mtspr  ctr,t5
	 next
      then
      mtspr ctr,t5
   then

   \ The test character is not present in the input string

   stwu  t0,-1cell(sp)		\ Store adr1+len2 on stack
   addi  tos,r0,0        	\ Return rem-len=0
c;

headerless
\ Splits a buffer into two parts around the first line delimiter
\ sequence.  A line delimiter sequence is either CR, LF, CR followed by LF,
\ or LF followed by CR.
\ adr1 len2 is the initial substring before, but not including,
\ the first line delimiter sequence.
\ adr2 len3 is the trailing substring after, but not including,
\ the first line delimiter sequence.

code parse-line  ( adr1 len1 -- adr1 len2  adr2 len3 )
   mr    t1,tos		\ len1
   lwz   t0,0(sp)	\ adr1

   set   tos,10		\ Delimiter 1 (linefeed)
   set   t4,13		\ Delimiter 2 (carriage return)

   cmpi 0,0,t1,0	\ Test length
   0<> if
      mfspr  t5,ctr
      mtspr  ctr,t1

      addi  t0,t0,-1	\ Account for pre-increment

      begin
         lbzu  t2,1(t0)		\ get the next character
         cmp   0,0,t2,tos  <> if  cmp  0,0,t2,t4  then  \ Compare to delimiters
      bc  0,2,*

      =  if			\ Found delimiter?
         mfspr  t3,ctr		\ len1-len2
         addi   t3,t3,1
         addi   t0,t0,1		\ Consume first delimiter

         subfc  t1,t3,t1	\ len2 ( Use subfc for POWER compatibility)
         stwu   t1,-1cell(sp)	\ store len2 on stack

         addic. t3,t3,-1
         0<>  if		\ Is there another delimiter?
            lbz  t6,0(t0)	\ Get the next character

            \ Compare next character to other delimiter
            cmp 0,0,t2,tos  =  if  cmp 0,0,t6,t4  else  cmp 0,0,t6,tos  then

	    =  if		\ If next character is the other delimiter
	       addi t0,t0,1	\ ... consume it
               addi t3,t3,-1
            then
         then
	 stwu  t0,-1cell(sp)	\ Store adr1+len2 on stack

         mr     tos,t3		\ Return len1-len2
         mtspr  ctr,t5
	 next
      then
      mtspr ctr,t5
   then

   \ There is no line delimiter in the input string

   stwu  t1,-1cell(sp)		\ Store len2 (=len1) on stack
   stwu  t0,-1cell(sp)		\ Store adr1+len2 on stack
   addi  tos,r0,0		\ Return rem-len=0
c;

headers

nuser delimiter

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
