%include "macros.inc"

global COLORS, CHARS, PIECES
global active_piece, active_piece_state
EXPORT clear_set
EXPORT cursor_visible

section .rodata
    clear_set: db 0x1b, "[2J", 0x1b, "[H", 0x1b, "[?25l"
    LEN clear_set

    cursor_visible: db 0x1b, "[?25h"
    LEN cursor_visible


    C_BLACK:      db 0x1b, "[270m"
    C_RED:        db 0x1b, "[91m"
    C_GREEN:      db 0x1b, "[92m"
    C_YELLOW:     db 0x1b, "[93m"
    C_BLUE:       db 0x1b, "[94m"
    C_MAGENTA:    db 0x1b, "[95m"
    C_CYAN:       db 0x1b, "[96m"
    C_WHITE:      db 0x1b, "[97m"

    COLORS: 
        dq C_BLACK
        dq C_RED
        dq C_GREEN
        dq C_YELLOW
        dq C_BLUE
        dq C_MAGENTA
        dq C_CYAN
        dq C_WHITE


    C_SPACE:    db 0xe2, 0x80, 0x82
    C_BOX:      db 0xe2, 0x96, 0x88
    C_HB:       db 0xe2, 0x94, 0x81
    C_VB:       db 0xe2, 0x94, 0x83
    C_VLT:      db 0xe2, 0x94, 0x8f
    C_VRT:      db 0xe2, 0x94, 0x93
    C_VLB:      db 0xe2, 0x94, 0x97
    C_VRB:      db 0xe2, 0x94, 0x9b

    CHARS: 
        dq C_SPACE
        dq C_BOX
        dq C_HB
        dq C_VB
        dq C_VLT
        dq C_VRT
        dq C_VLB
        dq C_VRB


    ; IJLOSTZ
    PIECES:
        PI:
            PI_0:       dd 0,0, -1,0, -2,0, 1,0
            PI_90:      dd 0,0, 0,1, 0,2, 0,-1
            PI_180:     dd 0,0, 1,0, 2,0, -1,0
            PI_270:     dd 0,0, 0,-1, 0,-2, 0,1
        PJ:
            PJ_0:       dd 0,0, 1,0, 1,-1, -1,0
            PJ_90:      dd 0,0, 0,1, 1,1, 0,-1
            PJ_180:     dd 0,0, -1,0, -1,1, 1,0
            PJ_270:     dd 0,0, 0,-1, -1,-1, 0,1
        PL:
            PL_0:       dd 0,0, 1,0, 1,1, -1,0
            PL_90:      dd 0,0, 0,-1, 1,-1, 0,1
            PL_180:     dd 0,0, -1,0, -1,-1, 1,0
            PL_270:     dd 0,0, 0,1, -1,1, 0,-1
        PO:
            PO_0:       dd 0,0, 0,1, 1,0, 1,1
            PO_90:      dd 0,0, 0,1, 1,0, 1,1
            PO_180:     dd 0,0, 0,1, 1,0, 1,1
            PO_270:     dd 0,0, 0,1, 1,0, 1,1
        PS:
            PS_0:       dd 0,0, 1,0, 1,-1, 0,1
            PS_90:      dd 0,0, 0,-1, -1,-1, 1,0
            PS_180:     dd 0,0, -1,0, -1,1, 0,-1
            PS_270:     dd 0,0, 0,1, 1,1, -1,0
        PT:
            PT_0:       dd 0,0, -1,0, 0,-1, 0,1
            PT_90:      dd 0,0, 0,-1, -1,0, 1,0
            PT_180:     dd 0,0, 1,0, 0,1, 0,-1
            PT_270:     dd 0,0, 0,1, -1,0, 1,0
        PZ:
            PZ_0:       dd 0,0, 1,0, 1,1, 0,-1
            PZ_90:      dd 0,0, 0,1, -1,1, 1,0
            PZ_180:     dd 0,0, -1,0, -1,-1, 0,1
            PZ_270:     dd 0,0, 0,-1, 1,-1, -1,0
            



section .bss
    ; 실제 조각 좌표
    active_piece: resd 8

    ; 첫 번째 정수는 조각 종류
    ; 두 번째 정수는 조각 회전 유형
    active_piece_state: resd 2