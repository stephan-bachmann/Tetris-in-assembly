default rel

%include "defines.inc"

BLACK equ 0
RED equ 1
GREEN equ 2
YELLOW equ 3
BLUE equ 4
MAGENTA equ 5
CYAN equ 6
WHITE equ 7
COLOR_LEN equ 5

SPACE equ 0
BOX equ 1
HB equ 2
VB equ 3
VLT equ 4
VRT equ 5
VLB equ 6
VRB equ 7
CHAR_LEN equ 3

%macro COLOR 1
    mov rax, 1
    mov rdi, 1
    mov rsi, [COLORS+(%1*8)]
    mov rdx, COLOR_LEN
    syscall
%endmacro

%macro CHAR 2
    push rbx
    mov rax, [CHARS+(%2*8)]
    mov bl, byte [rax]
    mov byte [%1], bl
    mov bl, byte [rax+1]
    mov byte [%1+1], bl
    mov bl, byte [rax+2]
    mov byte [%1+2], bl
    add %1, 3
    pop rbx
%endmacro




extern COLORS, CHARS


section .text
