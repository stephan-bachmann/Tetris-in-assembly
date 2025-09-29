default rel

%include "defines.inc"
%include "macros.inc"

NONE equ 0
TOP equ 1
BOTTOM equ 2
LEFT equ 1
RIGHT equ 2

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
global update_static_grid
global change_subgrid
IMPORT dynamic_grid
IMPORT previous_dynamic_grid
IMPORT static_grid
IMPORT color_grid
extern COLORS, CHARS, PIECES, SUBGRIDS
extern get_logic_index, get_real_index
extern active_piece, active_piece_state
extern previous_active_piece


section .text


; 동적 그리드와 정적 그리드, 색 그리드를 초기화하는 함수
set_grid:
    push rbp
    mov rbp, rsp
    push r12
    push r13
    push r14

    ; 색 적용 테스트
    ; mov rax, color_grid_len
    ; xor rdx, rdx
    ; mov rcx, 2
    ; div rcx

    ; mov rcx, rax
    ; mov rdi, color_grid
    ; mov ax, 0x0801
    ; rep stosw


    ; 색 그리드 채우기
    mov rdi, color_grid
    mov al, RESET
    mov rcx, color_grid_len
    rep stosb

    xor rdi, rdi
    call reset_subgrid
    mov rdi, 1
    call reset_subgrid

.dynamic:
    xor r12, r12        ; 논리 인덱스
    mov r13, GRID_WIDTH

.d_loop:
    mov r14, BORDER        ; 플래그
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
    mov r14, SPACE
    jmp .d_next

.d_open:
    ; 양 끝이 아니면 뚜껑 열기
    cmp rdx, 0
    je .d_next
    cmp rdx, GRID_INDEX_WIDTH
    je .d_next

    mov r14, SPACE

.d_next:
    ; 플래그로 채우기
    mov byte [dynamic_grid+r12], r14b
    
    
    inc r12
    cmp r12, dynamic_grid_len
    jne .d_loop



    mov rdi, previous_dynamic_grid
    mov rsi, dynamic_grid
    mov rcx, dynamic_grid_len
    rep movsb




.static:
    xor r12, r12    ; 행
    xor r13, r13    ; 열
    xor r14, r14    ; 문자 코드
    mov rsi, static_grid
    
.s_loop:
    push rsi
    mov rdi, r12
    mov rsi, r13
    call get_logic_index
    pop rsi

    ; 문자 채우기
    mov rdi, dynamic_grid
    mov r14b, byte [rdi+rax]
    CHAR rsi, r14

    ; 열 루프
    inc r13
    cmp r13, GRID_WIDTH
    jne .s_loop

    ; 다음 행
    xor r13, r13
    mov byte [rsi], 0xa
    inc rsi

    ; 행 루프
    inc r12
    cmp r12, GRID_HEIGHT
    jne .s_loop

    pop r14
    pop r13
    pop r12
    leave
    ret
;

; 작은 그리드들을 출력하는 함수
; input:
;   rdi = 그리드의 주소
;   rsi = 그리드의 너비
;   rdx = 그리드의 높이
print_small_grid:
    push rbp
    mov rbp, rsp

    ; 총 출력할 길이
    mov r8, rsi
    imul r8, rdx
    add r8, rdx

    sub rsp, r8     ; 출력할 행 임시 저장 버퍼
    mov r9, rsp     ; 임시 버퍼 접근 주소
    push r12
    push r13


    mov r12, rdi    ; 그리드 주소
    mov r13, rsi    ; 그리드 너비

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
    div r13
    
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

    xor r8, r8
    xor r14, r14    ; 인덱스
    xor r15, r15    ; 행

    ; 서브 그리드 스위치 켜기
    mov r10, qword [SUBGRIDS]
    mov byte [r10+Subgrid.switch], 1
    mov r10, qword [SUBGRIDS+8]
    mov byte [r10+Subgrid.switch], 1

    xor rax, rax
.loop:
    mov al, byte [r12]
    cmp al, 0xa
    je .linefeed

.char:
    ; 문자 출력일 시 먼저 색 변경
    xor r8, r8
    mov r8b, byte [r13+r14]
    COLOR r8

    ; 문자 출력
    mov rax, 1
    mov rdi, 1
    mov rsi, r12
    mov rdx, CHAR_LEN
    syscall

    add r12, CHAR_LEN

    jmp .next

.linefeed:
    ; 히든 다음부터 다음 조각 출력
    inc r15
    cmp r15, HIDDEN
    jle .skip_next_piece

    xor rdi, rdi
    call print_subgrid_line

.skip_next_piece:

    mov r8, HIDDEN
    add r8, SUB_HEIGHT
    inc r8
    cmp r15, r8
    jle .skip_keep_piece

    mov rdi, 1
    call print_subgrid_line

.skip_keep_piece:

    ; 줄바꿈 출력
    mov rax, 1
    mov rdi, 1
    mov rsi, r12
    mov rdx, 1
    syscall

    inc r12
    jmp .loop

.next:
    inc r14
    cmp r14, REAL_SIZE_1
    jl .loop

.ret:
    COLOR RESET
    pop r15
    pop r14
    pop r13
    pop r12
    leave
    ret
;



; 동적 그리드를 정적 그리드에 반영하는 함수
update_static_grid:
    push r12
    push r13
    xor rcx, rcx
    xor rdx, rdx
    xor r12, r12    ; 행
    xor r13, r13    ; 열
    ; 루프를 돌면서 이전과 다른 부분만 새로 반영
.loop:
    mov rdi, r12
    mov rsi, r13
    call get_logic_index

    mov cl, byte [dynamic_grid+rax]
    mov dl, byte [previous_dynamic_grid+rax]

    cmp cl, dl
    je .next

    mov rdi, r12
    mov rsi, r13
    call get_real_index

    mov rsi, static_grid
    add rsi, rax
    CHAR rsi, rcx

.next:
    inc r13
    cmp r13, GRID_WIDTH
    jne .loop

    xor r13, r13
    inc r12
    cmp r12, GRID_HEIGHT
    jne .loop

.copy:
    mov rdi, previous_dynamic_grid
    mov rsi, dynamic_grid
    mov rcx, dynamic_grid_len
    rep movsb

.ret:
    pop r13
    pop r12
    ret
;





; 다음 조각 미리보기 그리드 초기화 함수
; input: 
;   rdi = 서브 그리드 플래그(0 = next_piece, 1 = keep_piece)
reset_subgrid:
    push rbp
    mov rbp, rsp
    sub rsp, 8
    push r12
    push r13
    push r14
    push r15

    mov r10, [SUBGRIDS+rdi*8]    ; 서브 그리드 포인터

    mov rdi, [r10+Subgrid.grid]
    mov qword [rbp-8], rdi      ; 그리드 위치 저장


    mov rdi, [r10+Subgrid.color_grid]
    mov al, RESET
    mov ecx, dword [r10+Subgrid.index_size]
    rep stosb

    xor rax, rax    ; 행
    xor rdx, rdx    ; 열
    xor r12, r12    ; 인덱스
    movzx r13, byte [r10+Subgrid.width]
.loop:
    mov rax, r12
    xor rdx, rdx
    div r13
    ; 좌표 구하기

    xor r14, r14    ; 상하 플래그(NONE/TOP/BOTTOM)
    xor r15, r15    ; 좌우 플래그(NONE/LEFT/RIGHT)
    
    cmp rax, 0
    je .top
    cmp al, byte [r10+Subgrid.index_height]
    je .bottom

    jmp .left_or_right

.top:
    mov r14, TOP
    jmp .left_or_right
.bottom:
    mov r14, BOTTOM

.left_or_right:
    cmp rdx, 0
    je .left
    cmp dl, byte [r10+Subgrid.index_width]
    je .right

    jmp .set_character

.left:
    mov r15, LEFT
    jmp .set_character
.right:
    mov r15, RIGHT

.set_character:
    mov rdi, qword [rbp-8]
    
    mov rax, r14
    or rax, r15
    jz .space

    cmp r14, NONE
    jne .horizon

    jmp .vertical

.space:
    mov r11, SPACE
    jmp .next
.vertical:
    mov r11, VB
    jmp .next


.horizon:
    cmp r15, NONE
    jne .vertex

    ; 맨 위면 대신에 글자 출력
    cmp r14, TOP
    jne .not_top
    
    lea rsi, [r10+Subgrid.text]

.inserting_string:
    movzx rax, byte [rsi]
    mov byte [rdi], al
    mov byte [rdi+1], 0
    mov byte [rdi+2], 0
    add rdi, 3
    inc rsi
    
    inc rdx
    cmp rdx, 4
    jle .inserting_string

    ; 이후 인덱스 4개는 스킵
    add r12, 3  ; 현재 인덱스 넘어가는 건 .string_inserted에 있기 때문에 3만 더함
    jmp .string_inserted

.not_top:
    mov r11, HB
    jmp .next


.vertex:
    cmp r14, TOP
    je .t
    jmp .b
.t:
    cmp r15, LEFT
    je .lt
    jmp .rt
.lt:
    mov r11, VLT
    jmp .next
.rt:
    mov r11, VRT
    jmp .next

.b:
    cmp r15, LEFT
    je .lb
    jmp .rb
.lb:
    mov r11, VLB
    jmp .next
.rb:
    mov r11, VRB

.next:
    CHAR rdi, r11

.string_inserted:
    mov qword [rbp-8], rdi

    inc r12
    cmp r12d, dword [r10+Subgrid.index_size]
    jle .loop


    pop r15
    pop r14
    pop r13
    pop r12
    add rsp, 8
    leave
    ret
;

; 다음 조각 미리보기 한 줄 출력 함수
; input:
;   rdi = 서브 그리드 플래그(0 = next_piece, 1 = keep_piece)
print_subgrid_line:
    push r12
    push r13
    push r14

    xor r12, r12    ; 행
    xor r13, r13    ; 열

    mov r10, [SUBGRIDS+rdi*8]

    movzx r12, byte [r10+Subgrid.line]    ; 출력할 줄

    ; 스위치가 꺼져 있으면 종료
    movzx rax, byte [r10+Subgrid.switch]
    test al, al
    jz .ret
.loop:
    mov rax, r12
    movzx rdx, byte [r10+Subgrid.width]
    imul rax, rdx
    add rax, r13

    mov r14, rax
    imul r14, 3

    mov rdi, qword [r10+Subgrid.color_grid]
    movzx rdx, byte [rdi+rax]

    COLOR rdx


    mov rdi, 1
    mov rsi, [r10+Subgrid.grid]
    add rsi,
    mov rdx, CHAR_LEN
    mov rax, 1
    syscall

    COLOR RESET

    inc r13
    cmp r13b, byte [r10+Subgrid.width]
    jne .loop

    inc r12
    cmp r12b, byte [r10+Subgrid.height]
    jne .ret

    xor r12, r12
    mov byte [r10+Subgrid.switch], 0

.ret:
    mov byte [r10+Subgrid.line], r12b
    pop r14
    pop r13
    pop r12
    ret
;

; 서브 그리드에 표시하는 조각을 변경하는 함수
; input:
;   rdi = 서브 그리드 플래그
;   rsi = 조각 번호
change_subgrid:
    push r12
    push r13
    push r14

    mov r10, qword [SUBGRIDS+rdi*8]

    ; 이전 조각과 동일하면 스킵
    movzx rax, byte [r10+Subgrid.piece]
    cmp rax, rsi
    je .ret

    mov byte [r10+Subgrid.piece], sil

    mov r12, 1      ; 행
    mov r13, 1      ; 열
    mov r14, rsi    ; 조각 번호 저장
    ; 맵 초기화
.reset_map:
    mov rax, r12
    movzx rdx, byte [r10+Subgrid.width]
    imul rax, rdx
    add rax, r13
    
    ; 색 인덱스 초기화
    mov rdi, qword [r10+Subgrid.color_grid]
    mov byte [rdi+rax], RESET

    imul rax, 3


    ; 출력 인덱스 초기화
    mov rdi, qword [r10+Subgrid.grid]
    add rdi, rax
    CHAR rdi, SPACE

    inc r13
    cmp r13b, byte [r10+Subgrid.index_width]
    jl .reset_map

    
    ; 다음 행 이동 시 열을 1로 초기화
    mov r13, 1

    inc r12
    cmp r12b, byte [r10+Subgrid.index_height]
    jl .reset_map



    xor r11, r11    ; 카운터
    xor r12, r12    ; 상대 행
    xor r13, r13    ; 상대 열
    mov r8, r14
    imul r8, PIECE_SIZE
    add r8, PIECES
.set_blocks:
    mov r12b, byte [r8]
    mov r13b, byte [r8+1]
    add r8, 2

    add r12b, 3  ; 3,2 기준
    add r13b, 2  ;

    mov rax, r12
    movzx rdx, byte [r10+Subgrid.width]
    imul rax, rdx
    add rax, r13

    mov r9, r14
    inc r9
    mov rdi, qword [r10+Subgrid.color_grid]
    mov byte [rdi+rax], r9b
    
    imul rax, 3


    mov rdi, qword [r10+Subgrid.grid]
    add rdi, rax
    CHAR rdi, BOX

    inc r11
    cmp r11, 4
    jl .set_blocks

.ret:
    pop r14
    pop r13
    pop r12
    ret
;
