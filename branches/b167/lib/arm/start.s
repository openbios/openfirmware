# See license at end of file
	
        .data
_cifentry:
        .long 0

_leb0:
        .ascii "exit\0"

_exitblock:
        .align 4
        .long _leb0
        .long 0
        .long 0

        .text
        .globl  _start
        .type   _start,@function
        .ent    _start
_start:
        la     $8,_cifentry
        sw     $4,0($8)                 # save firmware entry point

        jal    main
        nop

        la     $4,_exitblock            # exit to firmware
        lw     $8,_cifentry
        j      $8
        nop
        .end    _start

        .align  4
        .globl  call_firmware
        .type   call_firmware,@function
        .ent    call_firmware
call_firmware:
        addi   $sp,-32                  # save return address
        sw     $31,28($sp)

        lw     $8,_cifentry
        jal    $31,$8                   # enter client interface
        nop

        lw     $31,28($sp)
        addi   $sp,32
        j      $31                      # return to c
        nop

        .end    call_firmware

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
