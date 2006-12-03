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
;	pushl %ebp
;	movl %esp,%ebp
	movl %eax,_cifentry
	call _ofw_setup
	lea  _exitblock, %eax
	movl _cifentry,%ebx
	call *%ebx
;	jmp L1
;	.align 2,0x90
;L1:
;	leave
	ret
Lfe1:
	.size	 _start,Lfe1-_start

.globl _call_firmware
	.type	 _call_firmware,@function
_call_firmware:
	movl 4(%esp),%eax
	push %ebx
	movl _cifentry,%ebx
	call *%ebx
	pop %ebx
	ret
Lfe2:
	.size	 _call_firmware,Lfe2-_call_firmware

