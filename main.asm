default rel



global _start
extern set_timers
extern save_tty, restore_tty
extern second_1_ticks, second_0_1_ticks

section .bss
    input_buffer: resb 1

section .text

_start:
    call save_tty
    call set_timers

.l:
    mov rax, 0
    mov rdi, 0
    mov rsi, input_buffer
    mov rdx, 1
    syscall

    

    cmp byte [input_buffer], 'q'
    je _exit

    cmp qword [second_0_1_ticks], 0
    je .l

    mov qword [second_0_1_ticks], 0
    
    mov rax, 1
    mov rdi, 1
    mov rsi, input_buffer
    mov rdx, 1
    syscall

    mov qword [input_buffer], 0

    jmp .l
_exit:
    call restore_tty
    mov rax, 60
    xor rdi, rdi
    syscall