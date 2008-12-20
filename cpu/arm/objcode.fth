purpose: Code words for support of multiple-code-field objects
\ See license at end of file

code >code-adr	( acf -- code-adr )
	r0	top )		ldr
	r0	r0	8 #lsl	mov
	top	top  r0 6 #asr	add
	top	2 cells		incr c;

\ As i understand your high-level definition of >action-adr
\ it assumes action to be: 0 < action# <= #actions, is this ok?
\ Testing for action#=0 not necessary? 

code >action-adr	( object-acf action# -- ... )
( ... -- object-acf action# #actions true | object-apf action-adr false )
\ !!!! the next line should ONLY be included for RiscOS Forthmacs testing
\	BASE	'body origin	pcr ldr
	r1	sp )		ldr	\ r1: object-acf    top: action#

	r0	r1 )		ldr	\ r0: object-code-field
	r0	r0	8 #asl	mov	\ remove opcode bits
	r0	r1   r0	6 #asr	add	\ r0: adr of object ;code clause - 8

					\ adding /cell is the same as adding
					\ 8 then subtracting 4
	r0	/cell		incr	\ r0: object-#actions-adr r1: obj-acf

	r2	r0 )		ldr	\ r2: #actions
	top	r2		cmp	\ action# greater #actions
gt if	top r2 2	sp db!	stm	\ push action# and #actions
	top	-1 #		mov	\ return true
				next
then	\ r0: object-#actions-adr  r1: object-acf  r2: #actions  top: action#

	r0	r0  top	2 #asl	sub	\ r0: adr of action cell
	r0	r0 )		ldr	\ r0: action-adr
\	r0	r0	BASE	add
	\ r0: object-action-adr  r1: object-acf  top: action#
	r1	/cell		incr	\ r1: object-apf
	r1	sp )		str	\ put object-apf on stack
	r0	sp		push	\ push action-adr
	top	0 #		mov c;	\ return false

\ Object data structure:
\
\ Created by object defining words (actions, action:, etc):
\
\   tokenN-1  tokenN-1   ...    token1   #actions  (does-clause) ...
\   |________|________|________|________|________|________

: action-name	\ name  ( action# -- )
	create ,
	;code
\ !!!! the next line should ONLY be included for RiscOS Forthmacs testing
	\	BASE	'body origin pcr ldr	\ Test
\	r0	top )		ldr	\ r0: action#

	r0	get-link
	r0	r0 )		ldr	\ r0: action#

	r2	ip )+		ldr
\	r2	r2	BASE	add	\ r2: object-acf
        top     sp              push    \ make room on stack
	top	r2	/cell #	add	\ top: object-apf

	r3	r2 )		ldr	\ r3: object-code-field
	r3	r3   	8 #lsl	mov	\ remove opcode bits
	r3	r2   r3	6 #asr	add	\ r3: adr of object ;code clause - 8
	r3	2 cells		incr	\ r3:object-code-adr

	r0	1		incr	\ r0: index to action-cell
	r3	r3   r0 2 #asl	sub	\ r3: adr of action cell
\ I am not sure about implementing execute, here the pc is just
\ set to token@
	pc	r3 )		ldr	\ execute action
\	pc	r3	BASE	add
c;

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
