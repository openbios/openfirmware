/*
 * setup.s is responsible for getting the system data from the BIOS,
 * and putting them into the appropriate places in system memory.
 * both setup.s and system has been loaded by the bootblock.
 *
 * 1-Jan-96 Modified by Chris Brady for use as a boot/loader for memtest-86.
 */

#define __ASSEMBLY__
#include "defs.h"

.code16
.section ".setup", "ax", @progbits
.globl start
start:
# ok, the read went well 
# now we want to move to protected mode ...


	cli			# no interrupts allowed #
	movb	$0x80, %al	# disable NMI for the bootup sequence
	outb	%al, $0x70

        movb    $0x01, %ah      # turn off the cursor
        movb    $0x00, %bh
        movw    $0x2000, %cx
        int     $0x10 

# The system will move itself to its rightful place.

	push	%cs
	pop	%ds
	lidt	idt_48 - start	# load idt with 0,0
	lgdt	gdt_48 - start	# load gdt with whatever appropriate

# that was painless, now we enable A20

	call    empty_8042
	
	movb	$0xD1, %al	# command write
	outb	%al, $0x64
	call    empty_8042	

	movb	$0xDF, %al	# A20 on
	outb	%al, $0x60
	call	empty_8042

/*
 * Note that the short jump isn't strictly needed, althought there are
 * reasons why it might be a good idea. It won't hurt in any case.
 */
	movw	$0x0001, %ax	# protected mode (PE) bit
	lmsw	%ax		# This is it#
	jmp	flush_instr
flush_instr:
	movw	$KERNEL_DS, %ax
	movw	%ax, %ds
	movw	%ax, %es
	movw	%ax, %ss
	movw	%ax, %fs
	movw	%ax, %gs

data32	ljmp	$KERNEL_CS, $(TSTLOAD <<4)	# jmp offset 2000 of segment 0x10 (cs)

/*
 * This routine checks that the keyboard command queue is empty
 * (after emptying the output buffers)
 *
 * No timeout is used - if this hangs there is something wrong with
 * the machine, and we probably couldn't proceed anyway.
 */
empty_8042:
	call	delay
	inb	$0x64, %al	# 8042 status port
	testb	$1, %al		# output buffer?
	jz	no_output
	call	delay
	inb	$0x60, %al	# read it
	jmp	empty_8042
	
no_output:
	testb	$2, %al		# is input buffer full?
	jnz	empty_8042	# yes - loop
	ret
#
# Delay is needed after doing i/o
#
delay:
	.word	0x00eb			# jmp $+2
	ret

gdt:
	.word	0,0,0,0		# dummy

	.word	0,0,0,0		# unused

	.word	0x7FFF		# limit 128mb
	.word	0x0000		# base address=0
	.word	0x9A00		# code read/exec
	.word	0x00C0		# granularity=4096, 386

	.word	0x7FFF		# limit 128mb
	.word	0x0000		# base address=0
	.word	0x9200		# data read/write
	.word	0x00C0		# granularity=4096, 386

idt_48:
	.word	0			# idt limit=0
	.long	0			# idt base=0L

gdt_48:
	.word	0x800		# gdt limit=2048, 256 GDT entries
	.word	512+gdt - start,0x9	# gdt base = 0X9xxxx

msg1:
	.asciz "Setup.S\r\n"

	/* Pad setup to the proper size */
	.org	(SETUPSECS*512)

