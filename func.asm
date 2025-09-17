default rel

%include "defines.inc"


I equ 0
J equ 1
L equ 2
O equ 3
S equ 4
T equ 5
Z equ 6

%assign DEGREE_SIZE 4 * 8           ; 정수 8개
%assign PIECE_SIZE DEGREE_SIZE * 4  ; 각도 4개


%macro SET_PIECE 1
    mov dword [active_piece_state], %1
    mov dword [active_piece_state+4], 0
%endmacro


global update_coordinate
extern PIECES
extern active_piece, active_piece_state

set_nonblocking:
    ; f = fntl(0, F_GETFL)
    ; stdin의 플래그 정보를 가져옴
    mov rax, 72     ; syscall = fntl
    xor rdi, rdi    ; fd = 0 (stdin)
    mov rsi, 3      ; F_GETFL
    xor rdx, rdx
    syscall

    test rax, rax   ; 0 미만이면 오류
    js .error

    or rax, 2048    ; O_NONBLOCK

    ; fntl(0, F_SETFL, f | O_NONBLOCK)
    ; stdin의 플래그 다시 세팅
    mov rdx, rax    ; f | O_NONBLOCK
    mov rax, 72     ; syscall = fntl
    mov rsi, 4      ; F_SETFL
    syscall

    test rax, rax   ; 0 미만이면 오류
    js .error

    xor rax, rax    ; 성공
    ret


.error:
    ret




set_noncanonical:
    push rbp
    mov rbp, rsp
    sub rsp, 64 ; termios 구조체 버퍼

    lea r8, [rbp-64]

    ; tcgetattr(0, &termios) → ioctl(fd=0, TCGETS, &termios_buf)
    mov rax, 16                 ; syscall = ioctl
    xor rdi, rdi                ; fd = 0 (stdin)
    mov rsi, 0x5401             ; TCGETS
    mov rdx, r8                 ; &termios_buf
    syscall

    ; termios.c_lflag &= ~(ICANON | ECHO)
    ; canonical과 echo를 끔
    mov rbx, [r8 + 12]
    and rbx, ~0x0A              ; ~(0x2 | 0x8)
    mov [r8 + 12], rbx

    ; termios.c_cc[VMIN]  = 0
    mov byte [r8 + 19], 0

    ; termios.c_cc[VTIME] = 0
    mov byte [r8 + 20], 0


    ; tcsetattr(0, TCSANOW, &termios) → ioctl(fd=0, TCSETS, &termios_buf)
    mov rax, 16                 ; syscall = ioctl
    xor rdi, rdi                ; fd = 0 (stdin)
    mov rsi, 0x5402             ; TCSETS
    mov rdx, r8                 ; &termios_buf
    syscall

    leave
    ret


;

; 활성 조각을 시계방향으로 회전하는 함수
; return:
;   rax = 회전된 모양 번호
rotate_piece:
    mov eax, dword [active_piece_state+4]
    cmp eax, 3
    je .rotate
    mov eax, -1
.rotate:
    inc eax
    mov dword [active_piece_state+4], eax
    ret
;


; 활성 조각 상태를 보고 실제 좌표를 계산하는 함수
update_coordinate:
    push rbp
    mov rbp, rsp
    sub rsp, 8

    push r12
    push r13

    xor rax, rax
    xor r12, r12
    xor r13, r13

    mov eax, dword [active_piece_state] ; 조각 번호
    imul rax, PIECE_SIZE    ; 조각 오프셋
    mov r12d, dword [active_piece_state+4]
    imul r12, DEGREE_SIZE   ; 각도 오프셋

    add rax, r12
    mov dword [rbp-8], eax

    ; 좌표 오프셋
    xor rcx, rcx
.loop:
    mov eax, dword [rbp-8]              ; 현재 조각 모양 주소 오프셋 복구

    add rax, rcx
    mov r12d, dword [PIECES+rax]        ; 상대 행 좌표 가져옴
    mov r13d, dword [active_piece]      ; 중심 블록 행 좌표 가져옴
    add r13, r12                        ; 중심 블록 행 좌표에 상대 행 좌표 더함
    mov dword [active_piece+rcx], r13d  ; 현재 블록 행 좌표 설정
    add rcx, 4                          ; 다음 정수로 이동

    add rax, 4
    mov r12d, dword [PIECES+rax]        ; 상대 열 좌표 가져옴
    mov r13d, dword [active_piece+4]    ; 중심 블록 열 좌표 가져옴
    add r13, r12                        ; 중심 블록 열 좌표에 상대 열 좌표 더함
    mov dword [active_piece+rcx], r13d  ; 현재 블록 열 좌표 설정
    add rcx, 4                          ; 다음 블록으로 이동

    cmp rcx, 24
    jle .loop

    pop r13
    pop r12
    add rsp, 8
    leave
    ret
;

