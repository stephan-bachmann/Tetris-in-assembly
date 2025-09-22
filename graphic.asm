default rel

%include "defines.inc"
%include "macros.inc"


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
CHAR_LEN equ 3


ACTIVATED_BOX equ 8

; 파라미터가 rax로 전달되면 안 됨
%macro COLOR 1
    mov rax, 1
    mov rdi, 1
    mov rsi, [COLORS+(%1*8)]
    mov rdx, COLOR_LEN
    syscall
%endmacro

; 파라미터가 rax로 전달되면 안 됨
%macro CHAR 2
    push rbx
    mov rax, [CHARS+(%2*8)]
    mov bl, byte [rax]
    mov byte [%1], bl
    mov bl, byte [rax+1]
    mov byte [%1+1], bl
    mov bl, byte [rax+2]
    mov byte [%1+2], bl
    add %1, CHAR_LEN
    pop rbx
%endmacro



global set_grid
global print_small_grid, print_static_grid
IMPORT dynamic_grid
IMPORT static_grid
IMPORT color_grid
extern COLORS, CHARS
extern get_logic_index
extern active_piece, active_piece_state
extern previous_active_piece


section .text


; 동적 그리드와 정적 그리드, 색 그리드를 초기화하는 함수
set_grid:
    push rbp
    mov rbp, rsp
    sub rsp, 16
    push r12
    push r13
    push r14

    mov rdi, color_grid
    mov al, 8
    mov rcx, color_grid_len
    rep stosb

.dynamic:
    xor r12, r12        ; 논리 인덱스
    mov r13, GRID_WIDTH

.d_loop:
    mov r14, BOX        ; 플래그
    mov rax, r12
    xor rdx, rdx
    div r13
    ; rax = 행, rdx = 열

    cmp rax, HIDDEN ; 히든 구역이면 공백으로 채움
    jl .d_hidden

    ; 테두리인지 확인
    cmp rax, HIDDEN
    je .d_open  ; 맨 윗부분은 뚜껑 열기
    cmp rax, GRID_INDEX_HEIGHT  ; GRID_WIDTH - 1
    je .d_next
    cmp rdx, 0
    je .d_next
    cmp rdx, GRID_INDEX_WIDTH
    je .d_next

.d_hidden:
    dec r14
    jmp .d_next

.d_open:
    ; 양 끝이 아니면 뚜껑 열기
    cmp rdx, 0
    je .d_next
    cmp rdx, GRID_INDEX_WIDTH
    je .d_next

    dec r14

.d_next:
    mov byte [dynamic_grid+r12], r14b
    
    
    inc r12
    cmp r12, dynamic_grid_len
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

; 작은 그리드들을 출력하는 함수
; input:
;   rdi = 그리드의 주소
;   rsi = 그리드의 단위 바이트 수
;   rdx = 그리드의 너비
;   rcx = 그리드의 높이
print_small_grid:
    push rbp
    mov rbp, rsp

    ; 총 출력할 길이
    mov r8, rsi
    imul r8, rdx
    imul r8, rcx
    add r8, rcx

    sub rsp, r8     ; 출력할 행 임시 저장 버퍼
    mov r9, rsp     ; 임시 버퍼 접근 주소
    push r12
    push r13
    push r14
    push r15


    mov r12, rdi    ; 그리드 주소
    mov r13, rsi    ; 단위 바이트
    mov r14, rdx    ; 그리드 너비
    mov r15, rcx    ; 그리드 높이

    xor r10, r10    ; 오프셋
    xor r11, r11    ; 행
.loop:
    mov al, byte [r12+r10]
    add al, 0x30

    mov rcx, r10
    add rcx, r11
    mov byte [r9+rcx], al
    inc r10

    ; 마지막 열이면 줄바꿈 추가
    mov rax, r10
    xor rdx, rdx
    div r14
    
    cmp rdx, 0
    jne .next
    mov rcx, r10
    add rcx, r11
    mov byte [r9+rcx], 0xa
    inc r11

.next:
    mov rcx, r10
    add rcx, r11
    cmp rcx, r8
    jl .loop
    

    mov rax, 1
    mov rdi, 1
    mov rsi, r9
    mov rdx, r8
    syscall

.ret:
    pop r15
    pop r14
    pop r13
    pop r12
    add rsp, r8
    leave
    ret
;

; 정적 그리드를 출력하는 함수
print_static_grid:
    push rbp
    mov rbp, rsp
    push r12
    push r13
    push r14
    push r15

    mov r12, static_grid
    mov r13, color_grid

    xor r14, r14    ; 인덱스
    mov r15, r12    
    
.loop:
    mov r8b, byte [r13+r14]
    COLOR r8

    mov al, byte [r15]
    cmp al, 0xa
    je .linefeed

.char:
    mov rax, 1
    mov rdi, 1
    mov rsi, r15
    mov rdx, CHAR_LEN
    syscall

    add r15, CHAR_LEN

    jmp .next

.linefeed:
    mov rax, 1
    mov rdi, 1
    mov rsi, r15
    mov rdx, 1
    syscall

    inc r15

.next:
    mov r8, REAL_WIDTH
    imul r8, REAL_HEIGHT

    inc r14
    cmp r14, r8
    jl .loop

.ret:
    pop r15
    pop r14
    pop r13
    pop r12
    leave
    ret