default rel

%include "defines.inc"
%include "macros.inc"


%macro SET_PIECE 1
    mov byte [active_piece_state], %1
    mov byte [active_piece_state+1], 0
%endmacro


global _start
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


section .text

_start:
    ;PRNT clear_set

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

    mov rdi, color_grid
    mov rsi, GRID_WIDTH
    mov rdx, GRID_HEIGHT
    call print_small_grid
    call update_static_grid
    call print_static_grid

    SET_PIECE I
    mov rdi, 2
    mov rsi, 3
    call update_center_block_coordinate
    call update_coordinate
    call update_dynamic_grid

    mov rdi, dynamic_grid
    mov rsi, GRID_WIDTH
    mov rdx, GRID_HEIGHT
    call print_small_grid
    call update_static_grid
    call print_static_grid

    SET_PIECE T
    mov rdi, 7
    mov rsi, 5
    call update_center_block_coordinate
    call update_coordinate
    call update_dynamic_grid

    mov rdi, dynamic_grid
    mov rsi, GRID_WIDTH
    mov rdx, GRID_HEIGHT
    call print_small_grid
    call update_static_grid
    call print_static_grid

_exit:
    ;PRNT cursor_visible

    mov rax, 60
    xor rdi, rdi
    syscall