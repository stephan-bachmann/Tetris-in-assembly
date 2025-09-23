global sleep

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