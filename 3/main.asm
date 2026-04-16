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
    writebuf resb BUFSIZE
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

.cmp_loop:
    mov al, [rdx]
    mov r9b, [r8]
    cmp al, r9b
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
    mov rsi, 1+64+512 ; O_CREAT | O_WRONLY | O_TRUNC
    mov rdx, 0644o
    syscall
    test rax, rax
    js  .file_error
    mov r12, rax
    jmp cont

.file_error:
    mov rax, 1
    mov rdi, 2
    mov rsi, error_file
    mov rdx, error_file_len
    syscall
    jmp HANDLE_ERR
; теперь file в r12 или ушли в ошибку


cont:
    mov r8b, 0 ; is letter found
    mov r9b, 0 ; letter
.read_loop:
    mov eax, 1
    mov edi, 1
    mov rsi, msg_invite
    mov edx, msg_invite_len
    syscall

    mov rax, 0                 ; sys_read
    mov rdi, 0
    mov rsi, buf
    mov rdx, BUFSIZE
    syscall
    test rax, rax
    jle .close

    mov r10, buf
    mov r11, writebuf
.copy_loop:
    mov r12b, [r10]
; \t \n -> found =0
; r12b == letter -> no copy
    cmp r12b, 10 ; \n
    je .set_found
    cmp r12b, 32 ; ' '
    je .set_found
    cmp r12b, 9 ; \t
    je .set_found
    jmp .aaa
.set_found:
    mov r8b, 0
    mov [r11], r12b
    inc r11
    inc r10
    dec rax
    jnz .copy_loop
    jmp .finish

.aaa:
    test r8b, r8b
    jnz .skip
    cmp r12b, r12b
.skip

.next:

.finish:



    mov rdx, rax               ; bytes read
    mov rax, 1                 ; sys_write
    mov rdi, r12
    mov rsi, writebuf
    syscall
    jmp .read_loop



.close:
    mov rax, 3                 ; sys_close
    mov rdi, r12
    syscall

.exit:
    mov rax, 60                ; sys_exit
    xor rdi, rdi
    syscall

exit_ok:
    mov rdi, 0
    jmp EXIT

HANDLE_ERR:
    mov rdi, 1

EXIT:
    mov rax, 60         ; sys_exit
    syscall
