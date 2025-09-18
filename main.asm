default rel

%include "defines.inc"
%include "macros.inc"


global _start
IMPORT clear_set
IMPORT cursor_visible
IMPORT static_grid
extern set_grid


%macro COLOR 1
    mov rax, 1
    mov rdi, 1
    mov rsi, [COLORS+(%1*8)]
    mov rdx, 5
    syscall
%endmacro



extern COLORS, CHARS


section .text

_start:
    PRNT clear_set

    call set_grid

    COLOR 1
    PRNT static_grid
    COLOR 7

_exit:
    PRNT cursor_visible

    mov rax, 60
    xor rdi, rdi
    syscall