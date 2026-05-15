bits 64
default rel
global main

section .data
    msg_x    db "Enter x:", 0
    msg_alf  db "Enter alpha:", 0
    msg_e    db "Enter epsilon:", 0
    msg_error_input db "Invalid input!", 10,0
    msg_error_range db "Input out of range!", 10,0
    msg_error_file  db "Cannot open file!", 10, 0
    msg_usage       db "Usage: %s output_file", 10, 0
    fmt_open        db "w+", 0
    fmt_input      db "%f", 0
    fmt_filewrite       db "%f", 10, 0
    fmt_output_math db "Math result: %f", 10, 0
    fmt_output_series db "Series summ: %f", 10, 0
    float_one dd 1.0
    abs_mask dd 0x7fffffff

section .bss
    x        resd 1
    alpha    resd 1
    epsilon  resd 1
    fileptr  resq 1

section .text
extern printf
extern scanf
extern powf
extern fopen
extern fclose
extern fprintf

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

    cmp rax,1
    je .ok
    mov rax, 1
    jmp .ret
.ok:
    xor rax, rax
.ret:
    ret

main:
    push rbp
    mov rbp, rsp

    cmp rdi,1
    jle exit_error_usage
    cmp rdi,3
    jge exit_error_usage

    mov rdi, [rsi+8]
    mov rsi, fmt_open
    call fopen

    test rax, rax
    jz exit_error_file
    mov [fileptr], rax

    ; Ввод
    mov rdi, msg_alf
    mov rsi, alpha
    call get_float
    test rax, rax
    jnz exit_error_input

    mov rdi, msg_x
    mov rsi, x
    call get_float
    test rax, rax
    jnz exit_error_input

    movd xmm0, [x]
    movd xmm1, [abs_mask]
    movd xmm2, [float_one]
    andps xmm0, xmm1
    cmpltss xmm0, xmm2
    movq rdi, xmm0
    test rdi,rdi
    jz exit_error_range

    mov rdi, msg_e
    mov rsi, epsilon
    call get_float
    test rax, rax
    jnz exit_error_input


    ;левая часть
    movd xmm0, [float_one]
    movd xmm2, [x]
    movd xmm1, [alpha]

    addss xmm0, xmm2
    call powf

    cvtss2sd xmm0, xmm0
    mov rax, 1
    mov rdi, fmt_output_math
    call printf

    ;ряд
    ;xmm0 - summ, xmm1 - delta, xmm2 -epsilon xmm3 - x xmm4 - alpha+1
    ; xmm5 - n xmm6 =1.0
    ; xmm9 - abs mask
    movd xmm0, [float_one]
    movss xmm1, xmm0
    movd xmm2, [epsilon]
    movd xmm3, [x]
    movd xmm4, [alpha]
    addss xmm4, xmm0
    movss xmm5, xmm0
    movss xmm6, xmm0
    movss xmm9, [abs_mask]
    mov r12, [fileptr]
    mov r13, fmt_filewrite
    main_loop:
    ;запись в файл
        sub rsp, 32
        movss [rsp], xmm0
        movss [rsp+4], xmm1
        movss [rsp+8], xmm2
        movss [rsp+12], xmm3
        movss [rsp+16], xmm4
        movss [rsp+20], xmm5
        movss [rsp+24], xmm6
        movss [rsp+28], xmm9
        mov rdi, r12
        mov rsi, r13
        cvtss2sd xmm0, xmm1
        mov rax, 1
        call fprintf

        movss xmm0, [rsp]
        movss xmm1, [rsp+4]
        movss xmm2, [rsp+8]
        movss xmm3, [rsp+12]
        movss xmm4, [rsp+16]
        movss xmm5, [rsp+20]
        movss xmm6, [rsp+24]
        movss xmm9, [rsp+28]
        add rsp, 32
    ; осн. логика
        movss xmm7, xmm4
        subss xmm7, xmm5
        divss xmm7,xmm5
        mulss xmm7, xmm3
        mulss xmm1, xmm7

        addss xmm0, xmm1
        addss xmm5, xmm6


        movss xmm8, xmm1
        andps xmm8, xmm9
        cmpltss xmm8, xmm2
        movq rax, xmm8
        test rax,rax
        jz main_loop

    cvtss2sd xmm0, xmm0
    mov rax, 1
    mov rdi, fmt_output_series
    call printf

    jmp exit_success

exit_error_file:
    mov rdi, msg_error_file
    xor rax, rax
    call printf
    mov rax, 1
    jmp  exit_inner
exit_error_usage:
    mov  rdi, msg_usage
    mov  rsi, [rsi]
    xor  rax, rax
    call printf
    mov rax, 1
    jmp  exit_inner
exit_error_range:
    mov rdi, msg_error_range
    xor rax, rax
    call printf
    jmp exit_error
exit_error_input:
    mov rdi, msg_error_input
    xor rax, rax
    call printf
    jmp exit_error

exit_error:
    mov rdi, [fileptr]
    call fclose
    mov rax, 1
    jmp exit_inner
exit_success:
    mov rdi, [fileptr]
    call fclose
    mov rax, 0
exit_inner:
    mov rsp, rbp
    pop rbp
    ret
