default rel

%include "defines.inc"
%include "macros.inc"


%macro SET_PIECE 1
    mov byte [active_piece_state], %1
    mov byte [active_piece_state+1], 0
%endmacro


global _start
IMPORT clear
IMPORT clear_set
IMPORT cursor_visible
IMPORT static_grid
IMPORT color_grid
IMPORT dynamic_grid
extern active_piece_state
extern set_grid
extern update_dynamic_grid
extern update_coordinate
extern update_center_block_coordinate
extern update_static_grid
extern print_small_grid, print_static_grid
extern rotate_piece
extern sleep
extern save_tty, restore_tty
extern linefeed
extern change_subgrid
extern score
extern set_score, add_score
extern check_collision
extern itoa
extern fixing_piece

section .text

_start:
    push rbp
    mov rbp, rsp
    sub rsp, 8
    ;call save_tty

    call set_grid

    mov rax, GRID_HEIGHT
    dec rax
    imul rax, GRID_WIDTH
    mov rdx, RED
.color_set:
    mov byte [color_grid+rax], dl
    inc rdx
    inc rax
    cmp rdx, RESET
    jle .color_set
    mov byte [color_grid+rax], BLACK
    
    mov rdi, 1000
    call set_score

    xor r14, r14
.lll:
    xor r12, r12
.ll:
    xor r13, r13
    SET_PIECE r12b
    xor rdi, rdi
    mov rsi, r12
    call change_subgrid
    mov rdi, 1
    mov rsi, r12
    inc rsi
    call change_subgrid
    
    xor rdi, rdi
    mov rsi, r12
    call change_subgrid
    mov rdi, 1
    mov rsi, r12
    inc rsi
    call change_subgrid
    
.l:
    inc r14
    PRNT clear
    PRNT clear_set
    mov rdi, 5
    imul rdi, r14
    mov rsi, 5
    call update_center_block_coordinate
    call update_coordinate
    call check_collision
    mov r15, rax

    mov rdi, rax
    lea rsi, qword [rbp-8]
    call itoa

    mov rax, 1
    mov rdi, 1
    lea rsi, qword [rbp-8]
    mov rdx, 1
    syscall

    mov rdi, 1
    call linefeed

    call update_dynamic_grid


    mov rdi, dynamic_grid
    mov rsi, GRID_WIDTH
    mov rdx, GRID_HEIGHT
    call print_small_grid

    call fixing_piece
    mov rdi, 1
    mov rsi, 0
    call sleep

    cmp r15, 1
    je .next

    call update_static_grid
    call print_static_grid

    call rotate_piece

    mov rdi, -5
    call add_score

.next:
    inc r13
    cmp r13, 4
    jne .l
    
    inc r12
    cmp r12, 7
    jne .ll

    jmp .lll

    jmp .lll


_exit:
    PRNT cursor_visible
    ;call restore_tty

    mov rax, 60
    xor rdi, rdi
    syscall