default rel



global _start
extern set_timers

section .text

_start:
    call set_timers

.l:
    
    jmp .l

_exit:

    mov rax, 60
    xor rdi, rdi
    syscall