HIDDEN equ 5

SUB_WIDTH equ 6
SUB_HEIGHT equ 6
%assign SUB_INDEX_WIDTH SUB_WIDTH - 1
%assign SUB_INDEX_HEIGHT SUB_HEIGHT - 1
%assign SUB_SIZE_1 SUB_WIDTH * SUB_HEIGHT
%assign SUB_SIZE_3 SUB_SIZE_1 * 3

MAP_WIDTH equ 10
%assign MAP_HEIGHT 20 + HIDDEN
%assign MAP_SIZE MAP_WIDTH * MAP_HEIGHT

GRID_WIDTH equ 12
%assign GRID_HEIGHT 22 + HIDDEN
%assign GRID_INDEX_WIDTH GRID_WIDTH - 1
%assign GRID_INDEX_HEIGHT GRID_HEIGHT - 1
%assign GRID_SIZE GRID_WIDTH * GRID_HEIGHT

REAL_WIDTH equ 13
%assign REAL_HEIGHT 22 + HIDDEN
%assign REAL_SIZE_1 REAL_WIDTH * REAL_HEIGHT
%assign REAL_SIZE_3 REAL_SIZE_1 * 3



%assign DEGREE_SIZE 8               ; 8바이트
%assign PIECE_SIZE DEGREE_SIZE * 4  ; 각도 4개


INITIAL_ROW equ 2
INITIAL_COLUMN equ 5



I equ 0
J equ 1
L equ 2
O equ 3
S equ 4
T equ 5
Z equ 6
PIECE_COUNT equ 7


BLACK equ 0
RED equ 1
GREEN equ 2
YELLOW equ 3
BLUE equ 4
MAGENTA equ 5
CYAN equ 6
WHITE equ 7
RESET equ 8
COLOR_LEN equ 5

SPACE equ 0
BOX equ 1
HB equ 2
VB equ 3
VLT equ 4
VRT equ 5
VLB equ 6
VRB equ 7
BORDER equ 8
ACTIVATED equ 9
CHAR_LEN equ 3

struc Subgrid
    .width:         resb 1
    .index_width:   resb 1
    .height:        resb 1
    .index_height:  resb 1
    
    .size:          resd 1
    .index_size:    resd 1

    .text:          resb 4

    .piece:         resb 1
    .line:          resb 1
    .switch:        resb 1

    .grid:          resq 1
    .color_grid:    resq 1
endstruc