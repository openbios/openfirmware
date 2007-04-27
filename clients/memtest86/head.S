/*
 *  linux/boot/head.S
 *  Copyright (C) 1991, 1992  Linus Torvalds
 */

/*
 *  head.S contains the 32-bit startup code.
 *
 *  1-Jan-96 Modified by Chris Brady for use as a boot/loader for MemTest-86.
 *  Setup the memory management for flat non-paged linear addressing.
 *  17 May 2004 : Added X86_PWRCAP for AMD64 (Memtest86+ - Samuel D.)
 */

.text
#define __ASSEMBLY__
#include "defs.h"
#include "config.h"
#include "test.h"

/*
 * References to members of the boot_cpu_data structure.
 */
#define CPU_PARAMS	cpu_id
#define X86		0
#define X86_MODEL	1
#define X86_MASK	2
#define X86_CPUID	4
#define X86_CAPABILITY	8
#define X86_VENDOR_ID	12
#define X86_CACHE	24
#define X86_PWRCAP	40

	.code32
	.globl startup_32
startup_32:
	cld
	cli

	/* Ensure I have a stack pointer */
	testl	%esp, %esp
	jnz 0f
	movl	$(LOW_TEST_ADR + _GLOBAL_OFFSET_TABLE_), %esp
	leal	stack_top@GOTOFF(%esp), %esp
0:
	
	/* Load the GOT pointer */
	call	0f
0:	popl	%ebx
	addl	$_GLOBAL_OFFSET_TABLE_+[.-0b], %ebx

	/* Pick the appropriate stack address */
	leal	stack_top@GOTOFF(%ebx), %esp

	/* Reload all of the segment registers */
	leal	gdt@GOTOFF(%ebx), %eax
	movl	%eax, 2 + gdt_descr@GOTOFF(%ebx)
	lgdt	gdt_descr@GOTOFF(%ebx)
	leal	flush@GOTOFF(%ebx), %eax
	pushl	$KERNEL_CS
	pushl	%eax
	lret
flush:	movl	$KERNEL_DS, %eax
	movw	%ax, %ds
	movw	%ax, %es
	movw	%ax, %fs
	movw	%ax, %gs
	movw	%ax, %ss

/*
 *  Zero BSS
 */
	cmpl	$1, zerobss@GOTOFF(%ebx)
	jnz	zerobss_done
	xorl	%eax, %eax
	leal	_bss@GOTOFF(%ebx), %edi
	leal	_end@GOTOFF(%ebx), %ecx
	subl	%edi, %ecx
1:	movl	%eax, (%edi)
	addl	$4, %edi
	subl	$4, %ecx
	jnz	1b
	movl	$0, zerobss@GOTOFF(%ebx)
zerobss_done:

/* 
 * Clear the video display
 */
	cmpl	$1, clear_display@GOTOFF(%ebx)
	jnz	clear_display_done
	movw	$0x0720, %ax
	movl	$0xb8000, %edi
	movl	$0xc0000, %ecx
1:	movw	%ax, (%edi)
	addl	$2, %edi
	cmpl	%ecx, %edi
	jnz	1b
	movl	$0, clear_display@GOTOFF(%ebx)
clear_display_done:


/*
 * Setup and exception handler
 */
	leal	idt@GOTOFF(%ebx), %edi

	leal	vec0@GOTOFF(%ebx), %edx
	movl	$(KERNEL_CS << 16),%eax
	movw	%dx, %ax	/* selector = 0x0010 = cs */
	movw	$0x8E00, %dx	/* interrupt gate - dpl=0, present */
	movl	%eax, (%edi)
	movl	%edx, 4(%edi)
	addl	$8, %edi

	leal	vec1@GOTOFF(%ebx),%edx
	movl	$(KERNEL_CS << 16),%eax
	movw	%dx,%ax		   /* selector = 0x0010 = cs */
	movw	$0x8E00,%dx	   /* interrupt gate - dpl=0, present */
	movl	%eax,(%edi)
	movl	%edx,4(%edi)
	addl	$8,%edi

	leal	vec2@GOTOFF(%ebx),%edx
	movl	$(KERNEL_CS << 16),%eax
	movw	%dx,%ax		   /* selector = 0x0010 = cs */
	movw	$0x8E00,%dx	   /* interrupt gate - dpl=0, present */
	movl	%eax,(%edi)
	movl	%edx,4(%edi)
	addl	$8,%edi

	leal	vec3@GOTOFF(%ebx),%edx
	movl	$(KERNEL_CS << 16),%eax
	movw	%dx,%ax		   /* selector = 0x0010 = cs */
	movw	$0x8E00,%dx	   /* interrupt gate - dpl=0, present */
	movl	%eax,(%edi)
	movl	%edx,4(%edi)
	addl	$8,%edi

	leal	vec4@GOTOFF(%ebx),%edx
	movl	$(KERNEL_CS << 16),%eax
	movw	%dx,%ax		   /* selector = 0x0010 = cs */
	movw	$0x8E00,%dx	   /* interrupt gate - dpl=0, present */
	movl	%eax,(%edi)
	movl	%edx,4(%edi)
	addl	$8,%edi

	leal	vec5@GOTOFF(%ebx),%edx
	movl	$(KERNEL_CS << 16),%eax
	movw	%dx,%ax		   /* selector = 0x0010 = cs */
	movw	$0x8E00,%dx	   /* interrupt gate - dpl=0, present */
	movl	%eax,(%edi)
	movl	%edx,4(%edi)
	addl	$8,%edi

	leal	vec6@GOTOFF(%ebx),%edx
	movl	$(KERNEL_CS << 16),%eax
	movw	%dx,%ax		   /* selector = 0x0010 = cs */
	movw	$0x8E00,%dx	   /* interrupt gate - dpl=0, present */
	movl	%eax,(%edi)
	movl	%edx,4(%edi)
	addl	$8,%edi

	leal	vec7@GOTOFF(%ebx),%edx
	movl	$(KERNEL_CS << 16),%eax
	movw	%dx,%ax		   /* selector = 0x0010 = cs */
	movw	$0x8E00,%dx	   /* interrupt gate - dpl=0, present */
	movl	%eax,(%edi)
	movl	%edx,4(%edi)
	addl	$8,%edi

	leal	vec8@GOTOFF(%ebx),%edx
	movl	$(KERNEL_CS << 16),%eax
	movw	%dx,%ax		   /* selector = 0x0010 = cs */
	movw	$0x8E00,%dx	   /* interrupt gate - dpl=0, present */
	movl	%eax,(%edi)
	movl	%edx,4(%edi)
	addl	$8,%edi

	leal	vec9@GOTOFF(%ebx),%edx
	movl	$(KERNEL_CS << 16),%eax
	movw	%dx,%ax		   /* selector = 0x0010 = cs */
	movw	$0x8E00,%dx	   /* interrupt gate - dpl=0, present */
	movl	%eax,(%edi)
	movl	%edx,4(%edi)
	addl	$8,%edi

	leal	vec10@GOTOFF(%ebx),%edx
	movl	$(KERNEL_CS << 16),%eax
	movw	%dx,%ax		   /* selector = 0x0010 = cs */
	movw	$0x8E00,%dx	   /* interrupt gate - dpl=0, present */
	movl	%eax,(%edi)
	movl	%edx,4(%edi)
	addl	$8,%edi

	leal	vec11@GOTOFF(%ebx),%edx
	movl	$(KERNEL_CS << 16),%eax
	movw	%dx,%ax		   /* selector = 0x0010 = cs */
	movw	$0x8E00,%dx	   /* interrupt gate - dpl=0, present */
	movl	%eax,(%edi)
	movl	%edx,4(%edi)
	addl	$8,%edi

	leal	vec12@GOTOFF(%ebx),%edx
	movl	$(KERNEL_CS << 16),%eax
	movw	%dx,%ax		   /* selector = 0x0010 = cs */
	movw	$0x8E00,%dx	   /* interrupt gate - dpl=0, present */
	movl	%eax,(%edi)
	movl	%edx,4(%edi)
	addl	$8,%edi

	leal	vec13@GOTOFF(%ebx),%edx
	movl	$(KERNEL_CS << 16),%eax
	movw	%dx,%ax		   /* selector = 0x0010 = cs */
	movw	$0x8E00,%dx	   /* interrupt gate - dpl=0, present */
	movl	%eax,(%edi)
	movl	%edx,4(%edi)
	addl	$8,%edi

	leal	vec14@GOTOFF(%ebx),%edx
	movl	$(KERNEL_CS << 16),%eax
	movw	%dx,%ax		   /* selector = 0x0010 = cs */
	movw	$0x8E00,%dx	   /* interrupt gate - dpl=0, present */
	movl	%eax,(%edi)
	movl	%edx,4(%edi)
	addl	$8,%edi

	leal	vec15@GOTOFF(%ebx),%edx
	movl	$(KERNEL_CS << 16),%eax
	movw	%dx,%ax		   /* selector = 0x0010 = cs */
	movw	$0x8E00,%dx	   /* interrupt gate - dpl=0, present */
	movl	%eax,(%edi)
	movl	%edx,4(%edi)
	addl	$8,%edi

	leal	vec16@GOTOFF(%ebx),%edx
	movl	$(KERNEL_CS << 16),%eax
	movw	%dx,%ax		   /* selector = 0x0010 = cs */
	movw	$0x8E00,%dx	   /* interrupt gate - dpl=0, present */
	movl	%eax,(%edi)
	movl	%edx,4(%edi)
	addl	$8,%edi

	leal	vec17@GOTOFF(%ebx),%edx
	movl	$(KERNEL_CS << 16),%eax
	movw	%dx,%ax		   /* selector = 0x0010 = cs */
	movw	$0x8E00,%dx	   /* interrupt gate - dpl=0, present */
	movl	%eax,(%edi)
	movl	%edx,4(%edi)
	addl	$8,%edi

	leal	vec18@GOTOFF(%ebx),%edx
	movl	$(KERNEL_CS << 16),%eax
	movw	%dx,%ax		   /* selector = 0x0010 = cs */
	movw	$0x8E00,%dx	   /* interrupt gate - dpl=0, present */
	movl	%eax,(%edi)
	movl	%edx,4(%edi)
	addl	$8,%edi

	leal	vec19@GOTOFF(%ebx),%edx
	movl	$(KERNEL_CS << 16),%eax
	movw	%dx,%ax		   /* selector = 0x0010 = cs */
	movw	$0x8E00,%dx	   /* interrupt gate - dpl=0, present */
	movl	%eax,(%edi)
	movl	%edx,4(%edi)
	addl	$8,%edi

	/* Now that it is initialized load the interrupt descritor table */
	leal	idt@GOTOFF(%ebx), %eax
	movl	%eax, 2 + idt_descr@GOTOFF(%ebx)
	lidt	idt_descr@GOTOFF(%ebx)

/* Find out the CPU type */

	leal	cpu_id@GOTOFF(%ebx), %esi
	movl	%ebx, %edi
	
	movl	$-1, X86_CPUID(%esi)	#  -1 for no CPUID initially

/* check if it is 486 or 386. */

	movl	$3, X86(%esi)	# at least 386
	pushfl			# push EFLAGS
	popl	%eax		# get EFLAGS
	movl	%eax, %ecx	# save original EFLAGS
	xorl	$0x40000, %eax	# flip AC bit in EFLAGS
	pushl	%eax		# copy to EFLAGS
	popfl			# set EFLAGS
	pushfl			# get new EFLAGS
	popl	%eax		# put it in eax
	xorl	%ecx, %eax	# change in flags
	andl	$0x40000, %eax	# check if AC bit changed
	je	id_done

	movl	$4, X86(%esi)	# at least 486
	movl	%ecx, %eax
	xorl	$0x200000, %eax	# check ID flag
	pushl	%eax
	popfl			# if we are on a straight 486DX, SX, or
	pushfl			# 487SX we can't change it
	popl	%eax
	xorl	%ecx, %eax
	pushl	%ecx		# restore original EFLAGS
	popfl
	andl	$0x200000, %eax
	jne	have_cpuid

	/* Test for Cyrix CPU types */
	xorw	%ax, %ax	# clear ax
	sahf			# clear flags
	movw	$5, %ax
	movw	$2, %bx
	div	%bl		# do operation that does not change flags
	lahf			# get flags
	cmp	$2, %ah		# check for change in flags
	jne	id_done		# if not Cyrix
	movl	$2, X86(%esi)	# Use two to identify as Cyrix
	jmp	id_done

have_cpuid:
	/* get vendor info */
	xorl	%eax, %eax			# call CPUID with 0 -> return vendor ID
	cpuid
	movl	%eax, X86_CPUID(%esi)		# save CPUID level
	movl	%ebx, X86_VENDOR_ID(%esi)	# first 4 chars
	movl	%edx, X86_VENDOR_ID+4(%esi)	# next 4 chars
	movl	%ecx, X86_VENDOR_ID+8(%esi)	# last 4 chars

	orl	%eax, %eax			# do we have processor info as well?
	je	id_done

	movl	$1, %eax		# Use the CPUID instruction to get CPU type
	cpuid
#
# Initialize the floating point unit in case the BIOS does not.
#
        testb   $1, %dl
        jz      no_FPU
        wait
        finit
no_FPU:
	movb	%al, %cl		# save reg for future use
	andb	$0x0f, %ah		# mask processor family
	movb	%ah, X86(%esi)
	andb	$0xf0, %al		# mask model
	shrb	$4, %al
	movb	%al, X86_MODEL(%esi)
	andb	$0x0f, %cl		# mask mask revision
	movb	%cl, X86_MASK(%esi)
	movl	%edx, X86_CAPABILITY(%esi)

	movl	$0, X86_CACHE(%esi)
	movl	$0, X86_CACHE+4(%esi)
	movl	$0, X86_CACHE+8(%esi)
	movl	$0, X86_CACHE+12(%esi)

	movl	X86_VENDOR_ID+8(%esi), %eax
	cmpl	$0x6c65746e,%eax	# Is this an Intel CPU?
	jne	not_intel
	movb	%bl, X86_PWRCAP(%esi) 	# Store BrandID in AMD PWRCAP if the CPU is from Intel
	movl	$2, %eax		# Use the CPUID instruction to get cache info 
	cpuid
	movl	%eax, X86_CACHE(%esi)
	movl	%ebx, X86_CACHE+4(%esi)
	movl	%ecx, X86_CACHE+8(%esi)
	movl	%edx, X86_CACHE+12(%esi)
	jmp	id_done

not_intel:
	movl	X86_VENDOR_ID+8(%esi),%eax
	cmpl	$0x444d4163, %eax	# Is this an AMD CPU?
	je	amd_type
	cmpl	$0x43534e20, %eax	# " NSC" - Geode GX, now owned by AMD
	je	amd_type
	cmpl	$0x736c7561, %eax	# Is this a VIA CENTAUR?
	jne	not_amd
amd_type:
	movl	$0x80000005, %eax	# Use the CPUID instruction to get cache info 
	cpuid
	movl	%ecx, X86_CACHE(%esi)
	movl	%edx, X86_CACHE+4(%esi)
	movl	$0x80000006,%eax	# Use the CPUID instruction to get cache info
	cpuid
	movl	%ecx,X86_CACHE+8(%esi)
	movl	$0x80000007,%eax	# Use the CPUID instruction to get AMD Powercap
	cpuid
	movl	%edx,X86_PWRCAP(%esi)

not_amd:
	movl	X86_VENDOR_ID+8(%esi), %eax
	cmpl	$0x64616374, %eax	# Is this a Cyrix CPU?
	jne	not_cyrix

	movl	X86_CPUID(%esi), %eax	# get CPUID level
	cmpl	$2, %eax		# Is there cache information available ?
	jne	id_done

	movl	$2, %eax		# Use the CPUID instr to get cache info 
	cpuid
	movl	%edx, X86_CACHE(%esi)
 	jmp	id_done
 
not_cyrix:
	movl	X86_VENDOR_ID+8(%esi), %eax
	cmpl	$0x736c7561, %eax
	jne	id_done

	movl	$0x80000005, %eax	# Use the CPUID instr to get cache info 
	cpuid
	movl	%ecx, X86_CACHE(%esi)
	movl	%edx, X86_CACHE+4(%esi)
	movl	$0x80000006,%eax	# Use the CPUID instr to get cache info
	cpuid
	movl	%ecx,X86_CACHE+8(%esi)

id_done:
	movl	%edi, %ebx	/* Restore GOT pointer */

#ifdef OLPC
	/* Disable Paging */
	movl    %cr0,%eax
	andl    $~(1 << 31),%eax
	movl    %eax,%cr0
	/* Flush TLBs */
	movl    %cr3,%eax
	movl    %eax,%cr3
#endif
 
	leal	_dl_start@GOTOFF(%ebx), %eax
	call	*%eax
	call	do_test
	/* In case we return simulate an exception */
	pushfl
	pushl	%cs
	call	0f
0:	pushl	$0 /* error code */
	pushl	$257 /* vector */
	jmp	int_hand

vec0:
	pushl	$0 /* error code */
	pushl	$0 /* vector */
	jmp int_hand
vec1:
	pushl	$0 /* error code */
	pushl	$1 /* vector */
	jmp int_hand
	
vec2:
	pushl	$0 /* error code */
	pushl	$2 /* vector */
	jmp int_hand
	
vec3:
	pushl	$0 /* error code */
	pushl	$3 /* vector */
	jmp	int_hand
	
vec4:
	pushl	$0 /* error code */
	pushl	$4 /* vector */
	jmp	int_hand
	
vec5:
	pushl	$0 /* error code */
	pushl	$5 /* vector */
	jmp	int_hand
	
vec6:
	pushl	$0 /* error code */
	pushl	$6 /* vector */
	jmp	int_hand
	
vec7:
	pushl	$0 /* error code */
	pushl	$7 /* vector */
	jmp	int_hand
	
vec8:
	/* error code */
	pushl	$8 /* vector */
	jmp	int_hand
	
vec9:
	pushl	$0 /* error code */
	pushl	$9 /* vector */
	jmp int_hand
	
vec10:
	/* error code */
	pushl	$10 /* vector */
	jmp	int_hand
	
vec11:
	/* error code */
	pushl	$11 /* vector */
	jmp	int_hand
	
vec12:
	/* error code */
	pushl	$12 /* vector */
	jmp	int_hand
	
vec13:
	/* error code */
	pushl	$13 /* vector */
	jmp	int_hand
	
vec14:
	/* error code */
	pushl	$14 /* vector */
	jmp	int_hand
	
vec15:
	pushl	$0 /* error code */
	pushl	$15 /* vector */
	jmp	int_hand
	
vec16:
	pushl	$0 /* error code */
	pushl	$16 /* vector */
	jmp	int_hand
	
vec17:
	/* error code */
	pushl	$17 /* vector */
	jmp	int_hand
	
vec18:
	pushl	$0 /* error code */
	pushl	$18 /* vector */
	jmp	int_hand
	
vec19:
	pushl	$0 /* error code */
	pushl	$19 /* vector */
	jmp	int_hand
	
int_hand:
	pushl	%eax
	pushl	%ebx
	pushl	%ecx
	pushl	%edx
	pushl	%edi
	pushl	%esi
	pushl	%ebp

	/* original stack pointer */
	leal	20(%esp), %eax 
	pushl	%eax
	
	pushl	%esp /* pointer to structure on the stack */
	call	inter
	addl	$8, %esp
	
	popl	%ebp
	popl	%esi
	popl	%edi
	popl	%edx
	popl	%ecx
	popl	%ebx
	popl	%eax
	iret

/*
 * The interrupt descriptor table has room for 32 idt's
 */
.align 4	
.word 0
idt_descr:
	.word 20*8-1	       # idt contains 32 entries
	.long 0

idt:
	.fill 20,8,0	       # idt is uninitialized

gdt_descr:
	.word gdt_end - gdt - 1
	.long 0

.align 4
.globl gdt, gdt_end
gdt:
	.quad 0x0000000000000000	/* NULL descriptor */
	.quad 0x0000000000000000	/* not used */
	.quad 0x00cf9a000000ffff	/* 0x10 main 4gb code at 0x000000 */
	.quad 0x00cf92000000ffff	/* 0x18 main 4gb data at 0x000000 */

	.word	0xFFFF				# 16bit 64KB - (0x10000*1 = 64KB)
	.word	0				# base address = SETUPSEG
	.byte	0x00, 0x9b			# code read/exec/accessed
	.byte	0x00, 0x00			# granularity = bytes


	.word	0xFFFF				# 16bit 64KB - (0x10000*1 = 64KB)
	.word	0				# base address = SETUPSEG
	.byte	0x00, 0x93			# data read/write/accessed
	.byte	0x00, 0x00			# granularity = bytes

gdt_end:

.data

.macro ptes64 start, count=64
.quad \start + 0x0000000 + 0xE3
.quad \start + 0x0200000 + 0xE3
.quad \start + 0x0400000 + 0xE3
.quad \start + 0x0600000 + 0xE3
.quad \start + 0x0800000 + 0xE3
.quad \start + 0x0A00000 + 0xE3
.quad \start + 0x0C00000 + 0xE3
.quad \start + 0x0E00000 + 0xE3
.if \count-1
ptes64 "(\start+0x01000000)",\count-1
.endif
.endm

.macro maxdepth depth=1
.if \depth-1
maxdepth \depth-1
.endif
.endm

maxdepth 

.balign 4096
.globl pd0
pd0:
	ptes64 0x0000000000000000

.balign 4096
.globl pd1
pd1:
	ptes64 0x0000000040000000

.balign 4096
.globl pd2
pd2:	
	ptes64 0x0000000080000000

.balign 4096
.globl pd3
pd3:
	ptes64 0x00000000C0000000

.balign 4096
.globl pdp
pdp:
	.long pd0 + 1
	.long 0
	.long pd1 + 1
	.long 0
	
	.long pd2 + 1
	.long 0
	
	.long pd3 + 1
	.long 0
.previous

#ifndef OLPC
#define RSTART startup_32

	.globl query_pcbios
query_pcbios:
	/* Save the caller save registers */
	pushl	%ebx
	pushl	%esi
	pushl	%edi
	pushl	%ebp
	call	1f
1:	popl	%ebx
	addl	$_GLOBAL_OFFSET_TABLE_+[.-1b], %ebx

	/* Compute the reloc address */
	leal	RSTART@GOTOFF(%ebx), %esi

	/* Fixup real code pointer */
	movl	%esi, %eax
	shrl	$4, %eax
	movw	%ax, 2 + realptr@GOTOFF(%ebx)

	/* Fixup protected code pointer */
	leal	prot@GOTOFF(%ebx), %eax
	movl	%eax, protptr@GOTOFF(%ebx)
	
	/* Compute the gdt fixup */
	movl	%esi, %eax
	shll	$16, %eax	# Base low

	movl	%esi, %ecx
	shrl	$16, %ecx
	andl	$0xff, %ecx

	movl	%esi, %edx
	andl	$0xff000000, %edx
	orl	%edx, %ecx

	/* Fixup the gdt */
	andl	$0x0000ffff, REAL_CS + 0 + gdt@GOTOFF(%ebx)
	orl	%eax,        REAL_CS + 0 + gdt@GOTOFF(%ebx)
	andl	$0x00ffff00, REAL_CS + 4 + gdt@GOTOFF(%ebx)
	orl	%ecx,        REAL_CS + 4 + gdt@GOTOFF(%ebx)
	andl	$0x0000ffff, REAL_DS + 0 + gdt@GOTOFF(%ebx)
	orl	%eax,        REAL_DS + 0 + gdt@GOTOFF(%ebx)
	andl	$0x00ffff00, REAL_DS + 4 + gdt@GOTOFF(%ebx)
	orl	%ecx,        REAL_DS + 4 + gdt@GOTOFF(%ebx)

	/* Fixup the gdt_descr */
	leal	gdt@GOTOFF(%ebx), %eax
	movl	%eax, 2 + gdt_descr@GOTOFF(%ebx)
	
	lidt	idt_real@GOTOFF(%ebx)

	/* Don't disable the a20 line */

	/* Load 16bit data segments, to ensure the segment limits are set */
	movl	$REAL_DS, %eax
	movl	%eax, %ds
	movl	%eax, %es
	movl	%eax, %ss
	movl	%eax, %fs
	movl	%eax, %gs

	/* Compute the stack base */
	leal	stack@GOTOFF(%ebx), %ecx
	/* Compute the address of meminfo */
	leal	mem_info@GOTOFF(%ebx), %edi
	
	/* switch to 16bit mode */
	ljmp	$REAL_CS, $1f - RSTART
1:
	.code16
	/* Disable Paging and protected mode */
	/* clear the PG & PE bits of CR0 */
	movl	%cr0,%eax
	andl	$~((1 << 31)|(1<<0)),%eax
	movl	%eax,%cr0
	
	/* make intersegment jmp to flush the processor pipeline
	 * and reload %cs:%eip (to clear upper 16 bits of %eip).
	 */
	ljmp	*(realptr - RSTART)
real:
	/* we are in real mode now
	 * set up the real mode segment registers : %ds, %ss, %es, %gs, %fs
	 */
	movw	%cs, %ax
	movw	%ax, %ds
	movw	%ax, %es
	movw	%ax, %fs
	movw	%ax, %gs
	movw	%ax, %ss

	/* Adjust the stack pointer */
	movl	%ecx, %eax
	shrl	$4, %eax
	movw	%ax, %ss
	subl	%ecx, %esp

	/* Save my base pointer */
	pushl	%ebx

	/* Setup %ds to point to my data area */
	shrl	$4, %edi
	movl	%edi, %ds

	/* Enable interrupts or BIOS's go crazy */
	sti

# Get memory size (extended mem, kB)

#define SMAP	0x534d4150

	xorl	%eax, %eax
	movl	%eax, (E88)
	movl	%eax, (E801)
	movl	%eax, (E820NR)

# Try three different memory detection schemes.  First, try
# e820h, which lets us assemble a memory map, then try e801h,
# which returns a 32-bit memory size, and finally 88h, which
# returns 0-64m

# method E820H:
# the memory map from hell.  e820h returns memory classified into
# a whole bunch of different types, and allows memory holes and
# everything.  We scan through this memory map and build a list
# of the first 32 memory areas, which we return at [E820MAP].
# This is documented at http://www.teleport.com/~acpi/acpihtml/topic245.htm

meme820:
	xorl	%ebx, %ebx			# continuation counter
	movw	$E820MAP, %di			# point into the whitelist
						# so we can have the bios
						# directly write into it.

jmpe820:
	movl	$0x0000e820, %eax		# e820, upper word zeroed
	movl	$SMAP, %edx			# ascii 'SMAP'
	movl	$20, %ecx			# size of the e820rec
	pushw	%ds				# data record.
	popw	%es
	int	$0x15				# make the call
	jc	bail820				# fall to e801 if it fails

	cmpl	$SMAP, %eax			# check the return is `SMAP'
	jne	bail820				# fall to e801 if it fails

#	cmpl	$1, 16(%di)			# is this usable memory?
#	jne	again820

	# If this is usable memory, we save it by simply advancing %di by
	# sizeof(e820rec).
	#
good820:
	movb	(E820NR), %al			# up to 32 entries
	cmpb	$E820MAX, %al
	jnl	bail820

	incb	(E820NR)
	movw	%di, %ax
	addw	$E820ENTRY_SIZE, %ax
	movw	%ax, %di
again820:
	cmpl	$0, %ebx			# check to see if
	jne	jmpe820				# %ebx is set to EOF
bail820:


# method E801H:
# memory size is in 1k chunksizes, to avoid confusing loadlin.
# we store the 0xe801 memory size in a completely different place,
# because it will most likely be longer than 16 bits.

meme801:
	stc					# fix to work around buggy
	xorw	%cx,%cx				# BIOSes which dont clear/set
	xorw	%dx,%dx				# carry on pass/error of
						# e801h memory size call
						# or merely pass cx,dx though
						# without changing them.
	movw	$0xe801, %ax
	int	$0x15
	jc	mem88

	cmpw	$0x0, %cx			# Kludge to handle BIOSes
	jne	e801usecxdx			# which report their extended
	cmpw	$0x0, %dx			# memory in AX/BX rather than
	jne	e801usecxdx			# CX/DX.  The spec I have read
	movw	%ax, %cx			# seems to indicate AX/BX 
	movw	%bx, %dx			# are more reasonable anyway...

e801usecxdx:
	andl	$0xffff, %edx			# clear sign extend
	shll	$6, %edx			# and go from 64k to 1k chunks
	movl	%edx, (E801)			# store extended memory size
	andl	$0xffff, %ecx			# clear sign extend
 	addl	%ecx, (E801)			# and add lower memory into
						# total size.

# Ye Olde Traditional Methode.  Returns the memory size (up to 16mb or
# 64mb, depending on the bios) in ax.
mem88:

	movb	$0x88, %ah
	int	$0x15
	movw	%ax, (E88)

#ifdef APM_OFF
# check for APM BIOS
	movw	$0x5300, %ax    # APM BIOS installation check
	xorw	%bx, %bx
	int	$0x15
	jc	done_apm_bios   # error -> no APM BIOS

	cmpw	$0x504d, %bx    # check for "PM" signature
	jne	done_apm_bios   # no signature -> no APM BIOS

	movw	$0x5304, %ax    # Disconnect first just in case
	xorw	%bx, %bx
	int	$0x15           # ignore return code
	
	movw	$0x5301, %ax    # Real Mode connect
	xorw	%bx, %bx
	int	$0x15
	jc	done_apm_bios   # error
	
	movw	$0x5308, %ax    # Disable APM
	mov	$0xffff, %bx
	xorw	%cx, %cx
	int	$0x15
		
done_apm_bios: 
#endif

	/* O.k. the BIOS query is done switch back to protected mode */
	cli

	/* Restore my saved variables */
	popl	%ebx

	/* Get an convinient %ds */
	movw	%cs, %ax
	movw	%ax, %ds

	/* Load the global descriptor table */
	addr32 lgdt	gdt_descr - RSTART

	/* Turn on protected mode */
	/* Set the PE bit in CR0 */
	movl	%cr0,%eax
	orl	$(1<<0),%eax
	movl	%eax,%cr0

	/* flush the prefetch queue, and relaod %cs:%eip */
	data32 ljmp	*(protptr - RSTART)
prot:
	.code32
	/* Reload other segment registers */
	movl	$KERNEL_DS, %eax
	movl	%eax, %ds
	movl	%eax, %es
	movl	%eax, %fs
	movl	%eax, %gs
	movl	%eax, %ss

	/* Adjust the stack pointer */
	leal	stack@GOTOFF(%ebx), %eax
	addl	%eax, %esp

	/* Restore the caller saved registers */
	popl	%ebp
	popl	%edi
	popl	%esi
	popl	%ebx
	movl	$1, %eax
	ret
	
realptr:
	.word	real - RSTART
	.word	0x0000
protptr:
	.long	0
	.long	KERNEL_CS

idt_real:
	.word	0x400 - 1			# idt limit ( 256 entries)
	.word	0, 0				# idt base = 0L
#endif

.data
zerobss:	.long	1
#ifdef EMULATE_EGA
clear_display:	.long	0
#else
clear_display:	.long	1
#endif
.previous
.data
.balign 16
	.globl mem_info
mem_info:
	. = . + MEMINFO_SIZE
.previous
.bss
.balign 16
stack:
	. = . + 4096
stack_top:
.previous
