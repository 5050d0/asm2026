bits 64
default rel
global main

section .data
    msg_x    db "Enter x:", 0
    msg_alf  db "Enter alpha:", 0
    msg_e    db "Enter epsilon:", 0
    fmt_input      db "%f", 0
    fmt_output_left db "Left result: %f", 10, 0
    float_one dd 1.0

section .bss
    x        resd 1
    alpha    resd 1
    epsilon  resd 1
    t        resd 1

section .text
extern printf
extern scanf
extern powf

;in: rdi - string ptr, rsi - float ptr
; ret: rax - 0 if success
get_float:
    push rbp
    mov rbp, rsp

    push rbx
    sub rsp, 8
    mov rbx, rsi
    xor rax, rax
    call printf

    mov rdi, fmt_input
    xor rax, rax
    mov rsi, rbx
    call scanf

    add rsp, 8
    pop rbx
    pop rbp

    xor rax, rax ; todo add error checking
    ret

main:
    push rbp
    mov rbp, rsp

    ; Ввод
    mov rdi, msg_alf
    mov rsi, alpha
    call get_float
    test rax, rax
    jnz exit_error

    mov rdi, msg_x
    mov rsi, x
    call get_float
    test rax, rax
    jnz exit_error

    mov rdi, msg_e
    mov rsi, epsilon
    call get_float
    test rax, rax
    jnz exit_error


    ;левая часть
    movd xmm0, [float_one]
    movd xmm2, [x]
    movd xmm1, [alpha]

    addss xmm0, xmm2
    call powf

    cvtss2sd xmm0, xmm0
    mov rax, 1
    mov rdi, fmt_output_left
    call printf

    ;ряд
    ;xmm0 - summ, xmm1 - delta, xmm2 -epsilon xmm3 - x xmm4 - alpha+1
    ; xmm5 - n xmm6 =1.0
    movd xmm0, [float_one]
    movq xmm1, xmm0
    movd xmm2, [epsilon]
    movd xmm3, [x]
    movd xmm4, [alpha]
    addss xmm4, xmm0
    movq xmm5, xmm0
    movq xmm6, xmm0

    main_loop:
        movq xmm7, xmm4
        subss xmm7, xmm5
        divss xmm7,xmm5
        mulss xmm7, xmm3
        mulss xmm1, xmm7

        addss xmm0, xmm1
        addss xmm5, xmm6
        ; check if delta is less than epsilon
        movq xmm8, xmm7
        cmpltss xmm8, xmm2
        movq rax, xmm8
        test rax,rax
        jnz main_loop


    jmp exit_success

exit_error:
    mov rax, 1
    jmp exit_inner
exit_success:
    mov rax, 0
exit_inner:
    mov rsp, rbp
    pop rbp
    ret
