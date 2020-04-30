factorial.S:
.align 4
.section .text
.globl _start

_start:
  # initialize registers
loop:
  addi x4, x4, 16
  addi x2, x2, 1
  add x3, x2, x2
  la x1, argument5
  sw x3,  0(x1)  # dcache miss
  add x2, x4, x2    # leap here
  add x2, x2, x2    # leap here
  add x3, x3, x3    # leap
  add x2, x0, x2
  lw x7, argument05
  add x5, x7, x2
halt:
  beq x2, x2, halt

.section .rodata
argument0:        .word  0x12345678
argument00:        .word  0x12345678
argument01:        .word  0x12345678
argument02:        .word  0x12345678
argument03:        .word  0x12345678
argument04:        .word  0x12345678
argument05:        .word  0x12345678
argument06:        .word  0x12345678
argument07:        .word  0x12345678
argument08:        .word  0x12345678
argument09:        .word  0x12345678
argument1:        .word  0x87654321
argument2:        .word  0x02040608
argument3:        .word  0x10245674
argument4:        .word  0x12d43a78
argument5:        .word  0xaa3cc56e
loop1_check:      .word 0x00000000
loop2_check:      .word 0x00000001
