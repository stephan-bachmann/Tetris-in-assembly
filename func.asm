default rel

%include "defines.inc"
%include "macros.inc"


%macro SET_PIECE 1
    mov rax, %1
    mov byte [active_piece_state], al
    mov byte [active_piece_state+1], 0
%endmacro


global get_logic_index
global get_real_index
global update_center_block_coordinate
global update_coordinate
global update_dynamic_grid
global rotate_piece
global add_score
global set_score
global save_tty, restore_tty
global check_collision
global fixing_piece
global check_0_1, check_1
global get_piece
IMPORT dynamic_grid
IMPORT previous_dynamic_grid
IMPORT color_grid
extern PIECES, SUBGRIDS
extern active_piece, active_piece_state
extern previous_active_piece
extern orig_termios, orig_flags, raw_termios
extern score, is_kept
extern input_buffer
extern second_0_1_ticks, second_1_ticks
extern update_static_grid, print_static_grid, print_small_grid
extern change_subgrid
extern piece_kept
extern timer_1_set
IMPORT cursor_visible
IMPORT clear

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


; 점수를 주어진 수로 설정하는 함수
; input:
;   rdi = 점수
set_score:
    mov dword [score], edi
    ret
;

; 점수에 주어진 수를 더하는 함수
; input:
;   rdi = 점수
add_score:
    xor rax, rax
    mov eax, dword [score]
    add rax, rdi
    mov dword [score], eax
    ret
;


; 현재 활성 조각이 다른 조각이나 테두리에 충돌했는지 여부를 반환하는 함수
check_collision:
    push rbp
    mov rbp, rsp
    sub rsp, 16
    push r12
    push r13
    push r14
    push r15

    xor r12, r12
    xor r13, r13
    mov r14, 1      ; 플래그
    xor r15, r15    ; 카운터

    lea rax, qword [rbp-16]
.prev_set:
    mov dl, byte [previous_active_piece+r15*2]
    mov byte [rax+r15*2], dl
    mov dl, byte [previous_active_piece+r15*2+1]
    mov byte [rax+r15*2+1], dl

    inc r15
    cmp r15, 4
    jl .prev_set

    xor r15, r15

.loop:
    lea rax, qword [rbp-16]
    mov r12b, byte [active_piece+r15*2]
    mov r13b, byte [active_piece+r15*2+1]

    cmp r12, 0
    jle .ret
    cmp r12, GRID_INDEX_HEIGHT
    jge .ret

    cmp r13, 0
    jle .ret
    cmp r13, GRID_INDEX_WIDTH
    jge .ret

    cmp r12b, byte [rax+r15*2]
    jne .not_equal

.row_equal:
    cmp r13b, byte [rax+r15*2+1]
    je .next

.not_equal:


    mov rdi, r12
    mov rsi, r13
    call get_logic_index


    mov dl, byte [dynamic_grid+rax]
    cmp dl, SPACE
    je .next
    cmp dl, ACTIVATED
    jne .ret

.next:
    inc r15
    cmp r15, 4
    jl .loop

    xor r14, r14

.ret:
    mov rax, r14

    pop r15
    pop r14
    pop r13
    pop r12
    add rsp, 16
    leave
    ret
;


; 현재 활성 조각 위치에 조각을 고정하고 초기화하는 함수
fixing_piece:
    push r12
    push r13
    push r14
    push r15

    xor r12, r12
    xor r13, r13
    xor r14, r14
    xor r15, r15
.loop:
    mov r12b, byte [active_piece+r15*2]
    mov r13b, byte [active_piece+r15*2+1]

    mov rdi, r12
    mov rsi, r13
    call get_logic_index

    mov byte [dynamic_grid+rax], BOX

    inc r15
    cmp r15, 4
    jl .loop

    mov byte [active_piece], 3
    mov byte [active_piece+1], 5

    call get_piece
    
    call update_coordinate

    mov byte [piece_kept], 0

    call block_clear

    pop r15
    pop r14
    pop r13
    pop r12
    ret
;


; 다음 조각을 랜덤으로 정하는 함수
; return:
;   rax = 다음 조각 정수
set_next_piece:
    rdrand rax
    mov rcx, PIECE_COUNT
    xor rdx, rdx
    
    div rcx

    push rdx
    mov rdi, 0
    mov rsi, rdx
    call change_subgrid

    pop rdx
    mov r10, [SUBGRIDS]
    lea r11, qword [r10+Subgrid.piece]

    mov byte [r11], dl


    mov rax, rdx
    ret
;


; 활성 조각을 다음 조각에서 가져오는 함수
get_piece:
    mov r10, [SUBGRIDS]
    xor r11, r11
    mov r11b, byte [r10+Subgrid.piece]

    cmp r11b, -1
    je .ret
    
    SET_PIECE r11

.ret:
    call set_next_piece
    ret
;



; 현재 활성 조각을 보관하는 함수
keep_active_piece:
    xor rax, rax
    cmp byte [piece_kept], 0
    jne .ret

    mov byte [piece_kept], 1

    ; 우선 위치 초기화
    mov byte [active_piece], 3
    mov byte [active_piece+1], 5

    mov r10, qword [SUBGRIDS+8]
    xor r11, r11
    mov r11b, byte [r10+Subgrid.piece]

    ; 보관된 조각이 있으면 서로 교환만
    cmp r11b, -1
    jne .swap

    ; 보관된 조각이 없으면 현재 조각을 보관 조각에 저장
    xor rax, rax
    mov al, byte [active_piece_state]
    push rax

    ; 다음 조각을 현재 조각으로 변경
    call get_piece
    jmp .end
    

.swap:
    xor rax, rax
    xor rdx, rdx
    mov al, byte [active_piece_state]
    mov dl, byte [r10+Subgrid.piece]

    push rax
    SET_PIECE rdx

.end:
    mov r10, qword [SUBGRIDS+8]
    mov rdi, 1
    pop rsi
    call change_subgrid

    mov rax, 1
.ret:
    ret
;

    


; 활성 조각을 조작하는 함수
AP_left:
    dec byte [active_piece+1]
    ret

AP_right:
    inc byte [active_piece+1]
    ret

AP_down:
    inc byte [active_piece]
    ret

AP_up:
    dec byte [active_piece]
    ret




check_0_1:
    mov byte [input_buffer], 0
    mov rax, 0
    mov rdi, 0
    mov rsi, input_buffer
    mov rdx, 1
    syscall

    cmp rax, 1
    jne .ret

    cmp byte [input_buffer], 'q'
    je .exit

.next:
    cmp qword [second_0_1_ticks], 0
    je .ret

    mov qword [second_0_1_ticks], 0


    cmp byte [input_buffer], 'a'
    je .left
    cmp byte [input_buffer], 's'
    je .down
    cmp byte [input_buffer], 'd'
    je .right
    cmp byte [input_buffer], 'j'
    je .rotate
    cmp byte [input_buffer], 'k'
    je .keep

    jmp .ret

.left:
    call AP_left
    call update_coordinate
    call check_collision
    cmp rax, 0
    je .changed

    call AP_right
    call update_coordinate
    jmp .ret

    
.down:
    call AP_down
    call update_coordinate
    call check_collision
    cmp rax, 0
    jne .no_reset_timer_1
    call timer_1_set
    jmp .changed

.no_reset_timer_1:
    call AP_up
    call update_coordinate
    jmp .ret
    

.right:
    call AP_right
    call update_coordinate
    call check_collision
    cmp rax, 0
    je .changed

    call AP_left
    call update_coordinate
    jmp .ret

.rotate:
    call rotate_piece
    call update_coordinate
    call check_collision
    cmp rax, 0
    je .changed

    call rotate_piece
    call rotate_piece
    call rotate_piece
    call update_coordinate
    jmp .ret

.keep:
    call keep_active_piece
    call update_coordinate
    cmp rax, 0
    je .ret
    jmp .changed

.changed:
    PRNT clear
    call update_dynamic_grid
    call update_static_grid
    call print_static_grid


.ret:
    ret

.exit:
    PRNT cursor_visible
    call restore_tty
    mov rax, 60
    xor rdi, rdi
    syscall
;


check_1:
    cmp qword [second_1_ticks], 0
    je .ret

    mov qword [second_1_ticks], 0

    call AP_down
    call update_coordinate
    call check_collision
    cmp rax, 0
    je .changed

    call AP_up
    call update_coordinate
    call fixing_piece

.changed:
    PRNT clear
    call update_dynamic_grid
    call update_static_grid
    call print_static_grid
.ret:
    ret
;


;handle SIGUSR1 nostop noprint pass
;handle SIGUSR2 nostop noprint pass

; 채워진 줄이 있으면 처리하는 함수
block_clear:
    push r12
    push r13
    xor r13, r13

    mov r12, MAP_HEIGHT

.loop:
    mov rdi, r12
    call check_line

    cmp rax, 1
    jne .skip_down

    mov rdi, r12
    call down_line
    inc r13
    jmp .loop

.skip_down:
    LOOP_FROM_TO r12, 0, .loop, DECREMENT

.calc_score:
    cmp r13, 0
    je .ret
.one:
    cmp r13, 1
    jne .two
    mov rdi, 100
    call add_score
    jmp .ret
.two:
    cmp r13, 2
    jne .three
    mov rdi, 300
    call add_score
    jmp .ret
.three:
    cmp r13, 3
    jne .four
    mov rdi, 600
    call add_score
    jmp .ret
.four:
    mov rdi, 1500
    call add_score


.ret:
    pop r13
    pop r12
    ret
;

; 한 줄이 블록으로 채워져 있는지 확인하는 함수
; input:
;   rdi = 체크할 행
; return:
;   rax = 채워져 있는지 여부
check_line:
    xor r8, r8
    xor r9, r9
    
    mov rsi, 1
    call get_logic_index
    mov r10, rax

.loop:
    cmp byte [dynamic_grid+r10+r9], BOX
    jne .ret

    LOOP_FROM_TO r9, MAP_WIDTH, .loop

    inc r8

.ret:
    mov rax, r8
    ret
;

; 행 번호를 주면 해당 행을 제거하고 윗행에 있는 블록들을 한 칸씩 내리는 함수
; input:
;   rdi = 제거할 행
down_line:
    push r12
    mov r8, rdi
    xor r9, r9
    xor r10, r10
    xor r11, r11


.line_loop:
    xor r12, r12
    mov rdi, r8
    mov rsi, 1
    call get_logic_index
    mov r9, rax                  ; 아랫줄 포인터

    mov rdi, r8
    dec rdi
    mov rsi, 1
    call get_logic_index
    mov r10, rax                 ; 윗줄 포인터


.block_loop:
    cmp byte [dynamic_grid+r10+r12], ACTIVATED
    je .activate_skip

    mov r11b, byte [dynamic_grid+r10+r12]
    mov byte [dynamic_grid+r9+r12], r11b
    mov r11b, byte [color_grid+r10+r12]
    mov byte [color_grid+r9+r12], r11b


.activate_skip:
    LOOP_FROM_TO r12, MAP_WIDTH, .block_loop
    
    LOOP_FROM_TO r8, HIDDEN, .line_loop, DECREMENT

.ret:
    pop r12
    ret
;