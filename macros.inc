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


DECREMENT equ 0
%macro LOOP_FROM_TO 3-4
    %if %0 = 4
        dec %1
        cmp %1, %2
        jg %3
    %else
        inc %1
        cmp %1, %2
        jl %3
    %endif
%endmacro