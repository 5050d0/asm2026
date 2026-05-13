bits 64
default rel
global main

section .data
    msg_x    db "Enter x:", 10, 0
    msg_alf  db "Enter alpha:", 10, 0
    msg_e    db "Enter epsilon:", 10, 0
    fmt      db "%f", 0

section .bss
    x        dd
    alpha    dd
    epsilon  dd
    t        dd

section .text
extern printf
extern scanf

;in: rdi - string ptr
; ret: xmm0 - float, al/rax - 0 if success
get_float:
    xor rax, rax
    call printf
    mov rdi, fmt
    mov rsi, t
    xor rax, rax
    call scanf
    movq xmm0, [t]


main: ; завернуть принт, ошибки и ввод в функцию
    push rbp
    mov rbp, rsp

    mov rdi, msg_x
    xor rax, rax
    call printf

    mov rdi, fmt
    mov rsi, x
    xor rax, rax
    call scanf

    mov rdi, msg_alf
    xor rax, rax
    call printf

    mov rdi, fmt
    mov rsi, alpha
    xor rax, rax
    call scanf

    mov rdi, msg_e
    xor rax, rax
    call printf

    mov rdi, fmt
    mov rsi, epsilon
    xor rax, rax
    call scanf


    mov rax, 0
    mov rsp, rbp
    pop rbp
    ret
