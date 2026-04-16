bits 64
default rel
global _start

section .data

msg_invite    db "Enter line: "
msg_invite_len equ $-msg_invite

error_env_not_found db "Environment varible FILENAME not found",10,0
error_env_not_found_len equ $ - error_env_not_found

error_file db "Error opening file", 10, 0
error_file_len equ $ - error_file

env_key     db "FILENAME=", 0
env_key_len equ $ - env_key -1


%define BUFSIZE 4096

section .bss
    buf resb BUFSIZE

section .text
    global _start

_start:
FIND_FILE:
    mov rbx, [rsp] ; argc
    lea rsi, [rsp + 8 + rbx*8 + 8]  ; пропускаем argc и argv и NULL

.find_env:
    mov rdi, [rsi] ; rdi указатель на текущую строку окр
    test rdi, rdi
    jz  .env_not_found

    mov rcx, env_key_len
    mov rdx, rdi
    mov r8, env_key
    ;lea r8,  [rel env_key]
.cmp_loop:
    mov al, [rdx]
    mov bl, [r8]
    cmp al, bl
    jne .next_env
    inc rdx
    inc r8
    dec rcx
    jnz .cmp_loop
    jmp .continue

.next_env:
    add rsi, 8
    jmp .find_env

.env_not_found:
    mov rax, 1
    mov rdi, 2
    mov rsi, error_env_not_found
    mov rdx, error_env_not_found_len
    syscall
    jmp HANDLE_ERR

.continue:
    mov rax, 2 ; sys_open
    mov rdi, rdx
    mov rsi, 65 ; O_CREAT | O_WRONLY
    mov rdx, 0
    syscall
    test rax, rax
    js  .file_error
    mov r12, rax

.file_error:
    mov rax, 1
    mov rdi, 2
    mov rsi, error_file
    mov rdx, error_file_len
    syscall
    jmp HANDLE_ERR
; теперь file в r12 или ушли в ошибку
READ_LOOP:
    mov rax, 0                 ; sys_read
    mov rdi, 1
    lea rsi, [rel buf]
    mov rdx, BUFSIZE
    syscall
    test rax, rax
    jle .close

    mov rdx, rax               ; bytes read
    mov rax, 1                 ; sys_write
    mov rdi, r12
    mov rsi, buf
    syscall
    jmp READ_LOOP



.close:
    mov rax, 3                 ; sys_close
    mov rdi, r12
    syscall

.exit:
    mov rax, 60                ; sys_exit
    xor rdi, rdi
    syscall


    ; mov eax, 1
    ; mov edi, 1
    ; mov rsi, msg_invite
    ; mov edx, msg_invite_len
    ; syscall

    ; xor eax, eax
    ; xor edi, edi
    ; mov rsi, str
    ; mov edx, size
    ; syscall



exit_ok:
    mov rdi, 0
    jmp EXIT

HANDLE_ERR:
    mov rdi, 1

EXIT:
    mov rax, 60         ; sys_exit
    syscall
