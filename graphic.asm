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



global set_grid
extern COLORS, CHARS
extern dynamic_grid, static_grid


section .text


; 동적 그리드와 정적 그리드를 초기화하는 함수
set_grid:
    push rbp
    mov rbp, rsp
    sub rsp, 16
    push r12
    push r13
    push r14

.dynamic:
    xor r12, r12        ; 논리 인덱스
    mov r13, GRID_WIDTH

    mov rdi, dynamic_grid
.d_loop:
    mov r14, BOX        ; 플래그
    mov rax, r12
    xor rdx, rdx
    div r13
    ; rax = 행, rdx = 열

    cmp rax, 0
    je .d_next
    cmp rax, GRID_INDEX_HEIGHT  ; GRID_WIDTH - 1
    je .d_next
    cmp rdx, 0
    je .d_next
    cmp rdx, GRID_INDEX_WIDTH
    je .d_next

    dec r14

.d_next:
    mov byte [rdi+r12], r14b

    inc r12
    cmp r12, GRID_SIZE
    jne .d_loop



.static:
    xor r12, r12    ; 행
    xor r13, r13    ; 열
    xor r14, r14
    mov rsi, static_grid
    
.s_loop:
    push rsi
    mov rdi, r12
    mov rsi, r13
    call get_logic_index
    pop rsi

    mov rdi, dynamic_grid
    mov r14b, byte [rdi+rax]
    CHAR rsi, r14

    inc r13
    cmp r13, GRID_WIDTH
    jne .s_loop

    xor r13, r13
    mov byte [rsi], 0xa
    inc rsi
    inc r12
    cmp r12, GRID_HEIGHT
    jne .s_loop

    pop r14
    pop r13
    pop r12
    add rsp, 16
    leave
    ret
;

; 행과 열을 받아 논리 인덱스를 반환하는 함수
; input:
;   rdi = 행
;   rsi = 열
; return:
;   rax = 논리 인덱스
get_logic_index:
    mov rax, rdi
    imul rax, GRID_WIDTH
    add rax, rsi
    ret