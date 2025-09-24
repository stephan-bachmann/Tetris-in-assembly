default rel

%include "defines.inc"
%include "macros.inc"


%assign DEGREE_SIZE 8               ; 8바이트
%assign PIECE_SIZE DEGREE_SIZE * 4  ; 각도 4개


%macro SET_PIECE 1
    mov byte [active_piece_state], %1
    mov byte [active_piece_state+1], 0
%endmacro


global get_logic_index
global get_real_index
global update_center_block_coordinate
global update_coordinate
global update_dynamic_grid
global rotate_piece
global save_tty, restore_tty
IMPORT dynamic_grid
IMPORT previous_dynamic_grid
IMPORT color_grid
extern PIECES
extern active_piece, active_piece_state
extern previous_active_piece
extern orig_termios, orig_flags, raw_termios

section .text

save_tty:
    ; ioctl(fd=0, TCGETS=0x5401, &orig_termios)
    mov  rax, 16
    xor  rdi, rdi
    mov  rsi, 0x5401
    mov  rdx, orig_termios
    syscall

    ; fcntl(fd=0, F_GETFL=3)
    mov  rax, 72
    xor  rdi, rdi
    mov  rsi, 3
    xor  rdx, rdx
    syscall
    mov  [orig_flags], rax

    ; raw_termios = orig_termios (64바이트 복사)
    mov  rsi, orig_termios
    mov  rdi, raw_termios
    mov  rcx, 64
    rep  movsb

    ; c_lflag &= ~(ICANON|ECHO)
    mov  rbx, [raw_termios+12]
    and  rbx, ~0x0A
    mov  [raw_termios+12], rbx

    ; VMIN=0, VTIME=0
    mov  byte [raw_termios+19], 0
    mov  byte [raw_termios+20], 0

    ; ioctl(fd=0, TCSETS=0x5402, &raw_termios)
    mov  rax, 16
    xor  rdi, rdi
    mov  rsi, 0x5402
    mov  rdx, raw_termios
    syscall

    ; fcntl(fd=0, F_SETFL=4, flags|O_NONBLOCK)
    mov  rax, [orig_flags]
    or   rax, 2048
    mov  rdx, rax
    mov  rax, 72
    xor  rdi, rdi
    mov  rsi, 4
    syscall
    ret
    
restore_tty:
    ; ioctl(fd=0, TCSETS=0x5402, &orig_termios)
    mov  rax, 16
    xor  rdi, rdi
    mov  rsi, 0x5402
    mov  rdx, orig_termios
    syscall

    ; fcntl(fd=0, F_SETFL=4, orig_flags)
    mov  rax, 72
    xor  rdi, rdi
    mov  rsi, 4
    mov  rdx, [orig_flags]
    syscall
    ret
;




; 사용 순서
; update_center_block_coordinate -> 중심 블록 좌표 변경
; update_coordinate -> 중심 블록 기준으로 다른 블록 위치 계산
; update_dynamic_grid -> 바뀐 정보를 동적 그리드에 반영


; 활성 조각을 시계방향으로 회전하는 함수
; return:
;   rax = 회전된 모양 번호
rotate_piece:   
    xor rax, rax
    mov al, byte [active_piece_state+1]
    cmp al, 3
    jl .rotate
    mov al, -1
.rotate:
    inc al
    mov byte [active_piece_state+1], al
    ret
;


; 활성 조각 상태를 보고 현재 활성 조각 좌표를 계산하는 함수
update_coordinate:
    push rbp
    mov rbp, rsp
    sub rsp, 8

    push r12
    push r13

    xor rax, rax
    xor r12, r12
    xor r13, r13

    mov al, byte [active_piece_state] ; 조각 번호
    imul rax, PIECE_SIZE    ; 조각 오프셋
    mov r12b, byte [active_piece_state+1]
    imul r12, DEGREE_SIZE   ; 각도 오프셋

    add rax, r12
    mov dword [rbp-8], eax

    ; 좌표 오프셋
    xor rcx, rcx
.loop:
    mov eax, dword [rbp-8]              ; 현재 조각 모양 주소 오프셋 복구

    add rax, rcx
    mov r12b, byte [PIECES+rax]         ; 상대 행 좌표 가져옴
    mov r13b, byte [active_piece]       ; 중심 블록 행 좌표 가져옴
    add r13, r12                        ; 중심 블록 행 좌표에 상대 행 좌표 더함
    mov byte [active_piece+rcx], r13b   ; 현재 블록 행 좌표 설정
    add rcx, 1                          ; 다음 정수로 이동

    add rax, 1
    mov r12b, byte [PIECES+rax]         ; 상대 열 좌표 가져옴
    mov r13b, byte [active_piece+1]     ; 중심 블록 열 좌표 가져옴
    add r13, r12                        ; 중심 블록 열 좌표에 상대 열 좌표 더함
    mov byte [active_piece+rcx], r13b   ; 현재 블록 열 좌표 설정
    add rcx, 1                          ; 다음 블록으로 이동

    cmp rcx, 8
    jl .loop

    pop r13
    pop r12
    add rsp, 8
    leave
    ret
;

; 행과 열을 받아 논리 인덱스를 반환하는 함수
; input:
;   rdi = 행
;   rsi = 열
; return:
;   rax = 논리 인덱스
get_logic_index:
    mov rax, rdi
    imul rax, GRID_WIDTH
    add rax, rsi
    ret
;

; 행과 열을 받아 실제 인덱스를 반환하는 함수
; input:
;   rdi = 행
;   rsi = 열
; return:
;   rax = 실제 인덱스
get_real_index:
    mov rax, rdi
    imul rax, GRID_WIDTH
    add rax, rsi
    imul rax, 3
    add rax, rdi
    ret
;


; 활성 조각의 중심 블록 좌표를 변경하는 함수
; input:
;   rdi = 중심 블록의 행
;   rsi = 중심 블록의 열
update_center_block_coordinate:
    mov byte [active_piece], dil
    mov byte [active_piece+1], sil
    ret
;


; 활성 조각의 현재 상태를 동적 그리드에 반영하는 함수
; 이전 좌표 색상을 RESET
; 이전 좌표 동적 그리드를 0으로 변경
update_dynamic_grid:
    push r12
    push r13

    xor r12, r12
    xor r13, r13
    xor rcx, rcx
    xor rdx, rdx

    ; 이전 조각을 지우는 루프
.prev_clear_loop:
    mov r12b, byte [previous_active_piece+rcx]
    inc rcx
    mov r13b, byte [previous_active_piece+rcx]
    inc rcx

    mov rdi, r12
    mov rsi, r13
    call get_logic_index

    ; 블록 위치에 테두리가 있으면 넘어감
    mov dl, byte [dynamic_grid+rax]
    cmp dl, BORDER
    je .prev_clear_loop

    ; 블록 위치에 박스(이전에 설치된 조각)가 있으면 넘어감
    cmp dl, BOX
    je .prev_clear_loop

    ; 블록과 색을 제거
    mov byte [dynamic_grid+rax], SPACE
    mov byte [color_grid+rax], RESET


    cmp rcx, 8
    jl .prev_clear_loop



    xor r12, r12
    xor r13, r13
    xor rcx, rcx
    xor rdx, rdx

    ; 현재 조각을 세팅하는 루프
.current_set_loop:
    ; 현재 블록 행
    mov r12b, byte [active_piece+rcx]
    mov byte [previous_active_piece+rcx], r12b  ; 이전 위치로 저장
    inc rcx

    ; 현재 블록 열
    mov r13b, byte [active_piece+rcx]
    mov byte [previous_active_piece+rcx], r13b  ; 이전 위치로 저장
    inc rcx

    mov rdi, r12
    mov rsi, r13
    call get_logic_index

    ; 블록 위치에 테두리가 있으면 넘어감
    mov dl, byte [dynamic_grid+rax]
    cmp dl, BORDER
    je .current_set_loop


    ; 해당 위치를 활성화
    mov dl, byte [active_piece_state]
    inc dl
    mov byte [dynamic_grid+rax], ACTIVATED
    mov byte [color_grid+rax], dl



    cmp rcx, 8
    jl .current_set_loop


    pop r13
    pop r12
    ret
;


; 활성 조각 위치를 보고 설치 가불가를 반환하는 함수
; return:
;   rax = 조각 설치 가불가
can_activate:
    xor rcx, rcx
    xor rdx, rdx
    xor r8, r8
    xor r9, r9

.loop:
    mov dl, byte [active_piece+rcx]
    inc rcx
    mov r8b, byte [active_piece+rcx]
    inc rcx

    mov rdi, rdx
    mov rsi, r8
    call get_logic_index

    mov dl, byte [dynamic_grid+rax]

    cmp dl, BORDER
    je .ret
    cmp dl, BOX
    je .ret

    cmp rcx, 8
    jl .loop

    inc r9

.ret:
    ret
;
