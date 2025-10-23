global sleep
global linefeed
global itoa

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



; input:
;   rdi = 정수
;   rsi = 변환된 문자열을 쓸 버퍼
; return: 
;   rax = 변환된 문자열의 길이
itoa:
.setup:
    push rbx    ; div

    mov rbx, 10
    xor rcx, rcx
    xor rdx, rdx

    mov rax, rdi
    mov rdi, rsi


.push_last_number:
    ; 10으로 나누기
    div rbx

    ; 마지막 자리 수 추출
    add rdx, 0x30
    push rdx
    xor rdx, rdx

    ; 길이 증가
    inc rcx

    ; 몫이 0이 아니면 루프
    test rax, rax
    jnz .push_last_number

    ; 루프에 사용하기 전, 문자열 길이 임시 저장
    mov rdx, rcx


.pop_number_string:
    ; 변환된 문자열의 맨 앞부터 가져오기
    pop rax

    ; 문자를 버퍼에 쓰기
    mov byte [rdi], al
    inc rdi
    
    ; 문자열 길이만큼 반복
    loop .pop_number_string

.ret:
    ; 길이 반환
    mov rax, rdx

    pop rbx
    ret

;

