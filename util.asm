global sleep
global linefeed

; 지연 함수
; input:
;   rdi = 초 단위
;   rsi = 밀리초 단위 (0~999)
sleep:
    sub rsp, 0x10

    ; tv_sec = rdi (초)
    mov [rsp], rdi

    ; tv_nsec = rsi * 1,000,000 (밀리초 -> 나노초)
    mov rax, rsi
    imul rax, 1000000
    mov [rsp+8], rax

    ; rdi = &req (timespec 주소)
    mov rdi, rsp

    ; rsi = NULL (rem 포인터 무시)
    xor esi, esi

    mov eax, 35       ; syscall: nanosleep
    syscall

    add rsp, 16       ; 스택 원상복구
    ret
;


; 줄바꿈을 출력하는 함수
; input:
;   rdi = 출력할 개수
linefeed:
    push rbp
    mov rbp, rsp
    sub rsp, 8
    push r12

    mov byte [rbp-8], 0xa

    cmp rdi, 0
    jle .ret

    mov r12, rdi
.loop:
    mov rax, 1
    mov rdi, 1
    lea rsi, [rbp-8]
    mov rdx, 1
    syscall

    dec r12
    cmp r12, 0
    jg .loop

.ret:
    pop r12
    add rsp, 8
    leave
    ret

