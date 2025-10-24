default rel

%include "macros.inc"

%define SYS_rt_sigaction  13
%define SYS_rt_sigreturn  15
%define SYS_timer_create  222
%define SYS_timer_settime 223
%define CLOCK_MONOTONIC   1
%define SIGUSR1           10
%define SIGUSR2           12
%define SA_RESTART        0x10000000
%define SA_RESTORER       0x04000000

global second_1_ticks, second_0_1_ticks
global timer_0_1_set
global timer_1_set

section .data
    sec_1: db "1sec", 0xa
    LEN sec_1

    sec_0_1: db "0.1sec", 0xa
    LEN sec_0_1
    txt1: db "1 installed", 0xa
    txt1_len equ $ - txt1
    failed1: db "1 failed", 0xa
    failed1_len equ $ - failed1
    txt2: db "2 installed", 0xa
    txt2_len equ $ - txt2
    failed2: db "2 failed", 0xa
    failed2_len equ $ - failed2

    global second_1_ticks, second_0_1_ticks
    second_1_ticks:     dq 0 ; 64비트 정수
    second_0_1_ticks:   dq 0 ; 64비트 정수


    sa_usr1:
        dq usr1_handler             ; 핸들러
        dq SA_RESTART | SA_RESTORER ; 플래그
        dq restorer                 ; 복귀자
        times 16 dq 0               ; 마스크

    sa_usr2:
        dq usr2_handler             ; 핸들러
        dq SA_RESTART | SA_RESTORER ; 플래그
        dq restorer                 ; 복귀자
        times 16 dq 0               ; 마스크


    sevp_usr1:
        dq 0                    ; sigev_value (미사용이면 0)
        dd SIGUSR1              ; 시그널 번호
        dd 0                    ; 타이머 만료 알림 유형(0 = 시그널)
        times 12 dd 0           ; 패딩

    sevp_usr2:
        dq 0
        dd SIGUSR2
        dd 0
        times 12 dd 0


    its_usr1:
        dq 1, 0                 ; it_interval: 1s, 0ns
        dq 1, 0                 ; it_value   : 1s, 0ns (즉시 arm; 처음 만료 1초 뒤)


    its_usr2:
        dq 0, 100000000         ; it_interval: 0s, 100000000ns
        dq 0, 100000000         ; it_value   : 0s, 100000000ns

section .bss
    timerid_usr1:   resq 1
    timerid_usr2:   resq 1

section .text

usr1_handler:
    inc qword [second_1_ticks]
    ret

usr2_handler:
    inc qword [second_0_1_ticks]
    ret

restorer:
    mov rax, SYS_rt_sigreturn
    syscall


install_second_alarm:
    mov     rax, SYS_rt_sigaction
    mov     rdi, SIGUSR1
    lea     rsi, [sa_usr1]
    xor     rdx, rdx                     ; oldact = NULL
    mov     r10, 8                       ; sizeof(sigset_t)
    syscall
    ret


install_0_1_second_alarm:
    mov     rax, SYS_rt_sigaction
    mov     rdi, SIGUSR2
    lea     rsi, [sa_usr2]
    xor     rdx, rdx                     ; oldact = NULL
    mov     r10, 8                       ; sizeof(sigset_t)
    syscall
    ret


global set_timers
set_timers:
    call install_second_alarm
    call install_0_1_second_alarm

    ; timer_create(CLOCK_MONOTONIC, &sevp_usr1, &timerid_usr1)
    mov rax, SYS_timer_create
    mov rdi, CLOCK_MONOTONIC
    lea rsi, [sevp_usr1]
    lea rdx, [timerid_usr1]
    syscall

    call timer_1_set



    ; timer_create(..., SIGUSR2, ...)
    mov rax, SYS_timer_create
    mov rdi, CLOCK_MONOTONIC
    lea rsi, [sevp_usr2]
    lea rdx, [timerid_usr2]
    syscall

    call timer_0_1_set

    ret


; 1초 타이머 시간을 초기화함
timer_1_set:
    ; timer_settime(timerid_usr1, 0, &its_usr1, NULL)
    mov rax, SYS_timer_settime
    mov rdi, qword [timerid_usr1]  ; timer_t value
    xor rsi, rsi                  ; flags = 0 (relative)
    lea rdx, [its_usr1]
    xor r10, r10                  ; old = NULL
    syscall
    ret

; 0.1초 타이머 시간을 초기화함
timer_0_1_set:
    mov rax, SYS_timer_settime
    mov rdi, qword [timerid_usr2]  ; timer_t value
    xor rsi, rsi                  ; flags = 0 (relative)
    lea rdx, [its_usr2]
    xor r10, r10                  ; old = NULL
    syscall
    ret