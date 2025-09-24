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

section .text

_start:
    ;call save_tty
    PRNT clear_set

    call set_grid
    mov byte [color_grid+276], RED
    mov byte [color_grid+277], GREEN
    mov byte [color_grid+278], YELLOW
    mov byte [color_grid+279], BLUE
    mov byte [color_grid+280], MAGENTA
    mov byte [color_grid+281], CYAN
    mov byte [color_grid+282], WHITE
    mov byte [color_grid+283], RESET
    mov byte [color_grid+284], BLACK


    xor r12, r12
    xor r13, r13

.lll:
    xor r12, r12
.ll:
    xor r13, r13
    SET_PIECE r12b
.l:
    PRNT clear
    mov rdi, 5
    call linefeed

    mov rdi, 10
    mov rsi, 5
    call update_center_block_coordinate
    call update_coordinate
    call update_dynamic_grid
    call update_static_grid
    call print_static_grid

    mov rdi, 1
    mov rsi, 0
    call sleep
    call rotate_piece

    inc r13
    cmp r13, 4
    jne .l
    
    inc r12
    cmp r12, 7
    ;;;;;;;;;;;
    jmp _exit
    ;;;;;;;;;;;
    jne .ll


_exit:
    PRNT cursor_visible
    ;call restore_tty

    mov rax, 60
    xor rdi, rdi
    syscall