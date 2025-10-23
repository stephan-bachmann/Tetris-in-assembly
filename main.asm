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
extern set_timers
extern check_0_1, check_1
extern get_piece

section .text

_start:
    call save_tty
    call set_timers
    call set_grid

    PRNT clear_set
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
    
    mov rdi, 0
    call set_score

    call get_piece
    call get_piece

    mov rdi, 3
    mov rsi, 5
    call update_center_block_coordinate
    call update_coordinate
    call update_dynamic_grid
    call update_static_grid


.l:

    call check_0_1
    call check_1
    jmp .l

_exit:
    PRNT cursor_visible
    call restore_tty

    mov rax, 60
    xor rdi, rdi
    syscall