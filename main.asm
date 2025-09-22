default rel

%include "defines.inc"
%include "macros.inc"


%macro SET_PIECE 1
    mov dword [active_piece_state], %1
    mov dword [active_piece_state+4], 0
%endmacro


global _start
IMPORT clear_set
IMPORT cursor_visible
IMPORT static_grid
IMPORT color_grid
extern active_piece_state
extern set_grid
extern update_coordinate
extern update_center_block_coordinate
extern print_small_grid, print_static_grid


section .text

_start:
    ;PRNT clear_set

    call set_grid
    mov byte [color_grid+276], 1
    mov byte [color_grid+278], 1
    mov byte [color_grid+280], 1
    mov byte [color_grid+282], 1

    mov rdi, color_grid
    mov rsi, 1
    mov rdx, GRID_WIDTH
    mov rcx, GRID_HEIGHT
    call print_small_grid
    
    call print_static_grid

_exit:
    ;PRNT cursor_visible

    mov rax, 60
    xor rdi, rdi
    syscall