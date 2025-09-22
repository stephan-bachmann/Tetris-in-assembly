%macro PRNT 1
    mov rax, 1
    mov rdi, 1
    mov rsi, %1
    mov rdx, %1_len
    syscall
%endmacro


%macro LEN 1
    %1_len equ $ - %1
%endmacro


%macro EXPORT 1
    global %1, %1_len
%endmacro


%macro IMPORT 1
    extern %1, %1_len
%endmacro

; 그리드 이름, 단위 바이트, 그리드 너비
%macro PRNT_GRID 3
    mov rax, %2
    mov 
%endmacro