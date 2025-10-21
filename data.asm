%include "defines.inc"
%include "macros.inc"

EXPORT dynamic_grid
EXPORT previous_dynamic_grid
EXPORT static_grid
EXPORT color_grid
EXPORT clear
EXPORT clear_set
EXPORT cursor_visible
EXPORT score_text
global COLORS, CHARS, PIECES, SUBGRIDS
global active_piece, active_piece_state
global previous_active_piece
global orig_termios, raw_termios, orig_flags
global score, is_kept
global input_buffer

section .rodata
    clear: db 0x1b, "[2J", 0x1b, "[H"
    LEN clear

    clear_set: db 0x1b, "[H", 0x1b, "[?25l"
    LEN clear_set

    cursor_visible: db 0x1b, "[?25h"
    LEN cursor_visible

    score_text: db "SCORE "
    LEN score_text

    


    C_BLACK:      db 0x1b, "[90m"
    C_RED:        db 0x1b, "[91m"
    C_GREEN:      db 0x1b, "[92m"
    C_YELLOW:     db 0x1b, "[93m"
    C_BLUE:       db 0x1b, "[94m"
    C_MAGENTA:    db 0x1b, "[95m"
    C_CYAN:       db 0x1b, "[96m"
    C_WHITE:      db 0x1b, "[37m"
    C_RESET:      db 0x1b, "[00m"

    COLORS: 
        dq C_BLACK
        dq C_RED
        dq C_GREEN
        dq C_YELLOW
        dq C_BLUE
        dq C_MAGENTA
        dq C_CYAN
        dq C_WHITE
        dq C_RESET


    C_SPACE:     db 0xe2, 0x80, 0x82
    C_BOX:       db 0xe2, 0x96, 0x88
    C_HB:        db 0xe2, 0x94, 0x81
    C_VB:        db 0xe2, 0x94, 0x83
    C_VLT:       db 0xe2, 0x94, 0x8f
    C_VRT:       db 0xe2, 0x94, 0x93
    C_VLB:       db 0xe2, 0x94, 0x97
    C_VRB:       db 0xe2, 0x94, 0x9b
    C_BORDER:    db 0xe2, 0x96, 0x88
    C_ACTIVATED: db 0xe2, 0x96, 0x88

    CHARS: 
        dq C_SPACE
        dq C_BOX
        dq C_HB
        dq C_VB
        dq C_VLT
        dq C_VRT
        dq C_VLB
        dq C_VRB
        dq C_BORDER
        dq C_ACTIVATED


    ; IJLOSTZ
    PIECES:
        PI:
            PI_0:    db 0,0, -1,0, -2,0, 1,0
            PI_90:   db 0,0, 0,1, 0,2, 0,-1
            PI_180:  db 0,0, 1,0, 2,0, -1,0
            PI_270:  db 0,0, 0,-1, 0,-2, 0,1

        PJ:
            PJ_0:    db 0,0, -1,0, 1,0, 1,1
            PJ_90:   db 0,0, 0,-1, 0,1, 1,-1
            PJ_180:  db 0,0, -1,0, 1,0, -1,-1
            PJ_270:  db 0,0, 0,-1, 0,1, -1,1

        PL:
            PL_0:    db 0,0, -1,0, 1,0, 1,-1
            PL_90:   db 0,0, 0,-1, 0,1, -1,-1
            PL_180:  db 0,0, -1,0, 1,0, -1,1
            PL_270:  db 0,0, 0,-1, 0,1, 1,1

        PO:
            PO_0:    db 0,0, -1,0, 0,1, -1,1
            PO_90:   db 0,0, -1,0, 0,1, -1,1
            PO_180:  db 0,0, -1,0, 0,1, -1,1
            PO_270:  db 0,0, -1,0, 0,1, -1,1

        PS:
            PS_0:    db 0,0, 0,-1, -1,0, -1,1
            PS_90:   db 0,0, -1,0, 0,1, 1,1
            PS_180:  db 0,0, 0,1, 1,0, 1,-1
            PS_270:  db 0,0, 1,0, 0,-1, -1,-1

        PT:
            PT_0:    db 0,0, 0,-1, 0,1, -1,0
            PT_90:   db 0,0, -1,0, 1,0, 0,1
            PT_180:  db 0,0, 0,-1, 0,1, 1,0
            PT_270:  db 0,0, -1,0, 1,0, 0,-1

        PZ:
            PZ_0:    db 0,0, -1,0, 0,1, -1,-1
            PZ_90:   db 0,0, 1,0, 0,1, -1,1
            PZ_180:  db 0,0, 1,0, 0,-1, 1,1
            PZ_270:  db 0,0, -1,0, 0,-1, 1,-1


    SUBGRIDS:
        dq next_piece
        dq keep_piece


section .data
    score: dd 0
    is_kept: db 0

    next_piece:
        istruc Subgrid
            at Subgrid.width,           db SUB_WIDTH
            at Subgrid.index_width,     db SUB_INDEX_WIDTH
            at Subgrid.height,          db SUB_HEIGHT
            at Subgrid.index_height,    db SUB_INDEX_HEIGHT

            at Subgrid.size,            dd SUB_SIZE_3
            at Subgrid.index_size,      dd SUB_SIZE_1

            at Subgrid.text,            db "NEXT"
            
            at Subgrid.piece,           db -1
            at Subgrid.line,            db 0
            at Subgrid.switch,          db 1

            at Subgrid.grid,            dq next_piece_grid
            at Subgrid.color_grid,      dq next_piece_color_grid
        iend

    keep_piece:
        istruc Subgrid
            at Subgrid.width,           db SUB_WIDTH
            at Subgrid.index_width,     db SUB_INDEX_WIDTH
            at Subgrid.height,          db SUB_HEIGHT
            at Subgrid.index_height,    db SUB_INDEX_HEIGHT
            
            at Subgrid.size,            dd SUB_SIZE_3
            at Subgrid.index_size,      dd SUB_SIZE_1

            at Subgrid.text,            db "KEEP"

            at Subgrid.piece,           db -1
            at Subgrid.line,            db 0
            at Subgrid.switch,          db 1
            
            at Subgrid.grid,            dq keep_piece_grid
            at Subgrid.color_grid,      dq keep_piece_color_grid
        iend    



section .bss
    ; 실제 조각 좌표
    active_piece: resb 8
    ; 직전 조각 좌표
    previous_active_piece: resb 8

    ; 첫 번째 바이트는 조각 종류
    ; 두 번째 바이트는 조각 회전 유형
    active_piece_state: resb 2

    dynamic_grid: resb GRID_SIZE
    LEN dynamic_grid

    previous_dynamic_grid: resb GRID_SIZE
    LEN previous_dynamic_grid

    static_grid: resb REAL_SIZE_3
    LEN static_grid

    color_grid: resb GRID_SIZE
    LEN color_grid

    next_piece_grid: resb SUB_SIZE_3
    LEN next_piece_grid
    next_piece_color_grid: resb SUB_SIZE_1
    LEN next_piece_color_grid

    keep_piece_grid: resb SUB_SIZE_3
    LEN keep_piece_grid
    keep_piece_color_grid: resb SUB_SIZE_1
    LEN keep_piece_color_grid

    orig_termios: resb 64     ; 원래 termios 저장용
    orig_flags:   resq 1      ; 원래 fcntl flags 저장용
    raw_termios:  resb 64     ; 수정본 임시 버퍼

    input_buffer: resb 1