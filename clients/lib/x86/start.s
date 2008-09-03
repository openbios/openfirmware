# See license at end of file

	.file	"start.s"
.data
	.align 2
	.type	 _cifentry,@object
	.size	 _cifentry,4
_cifentry:
	.long 0

LEB0:
	.ascii "exit\0"

	.type	 _exitblock,@object
	.size	 _exitblock,12
_exitblock:
	.long LEB0
	.long 0
	.long 0

.text
	.align 2
.globl _start
	.type	 _start,@function
_start:
#	pushl %ebp
#	movl %esp,%ebp
	movl %eax,_cifentry
	call ofw_setup
	lea  _exitblock, %eax
	movl _cifentry,%ebx
	call *%ebx
#	jmp L1
#	.align 2,0x90
#L1:
#	leave
	ret

.globl call_firmware
	.type	 call_firmware,@function
call_firmware:
	movl 4(%esp),%eax
	push %ebx
	movl _cifentry,%ebx
	call *%ebx
	pop %ebx
	ret

# LICENSE_BEGIN
# Copyright (c) 2006 FirmWorks
# 
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:
# 
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
# WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
#
# LICENSE_END
