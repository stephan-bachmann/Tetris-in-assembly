default rel

%include "macros.inc"


%macro SET_PIECE 1
    mov dword [active_piece_state], %1
    mov dword [active_piece_state+4], 0
%endmacro


global _start
IMPORT clear_set
IMPORT cursor_visible
extern update_coordinate, active_piece_state, active_piece


section .text

_start:
    SET_PIECE 3

    call update_coordinate

    mov dword [active_piece], 5
    mov dword [active_piece+4], 3
    call update_coordinate

_exit:
    mov rax, 60
    xor rdi, rdi
    syscall