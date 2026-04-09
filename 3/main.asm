bits 64
default rel
global _start

section .data
size equ 1024
msg_invite:
    db "Enter line: "
msg_invite_len equ $-msg_invite
str:
    times size db 0
msg_result:
    db "Result: "
newstr:
    times size db 0


section .text
_start:
; открыть файл

    mov eax, 1
    mov edi, 1
    mov rsi, msg_invite
    mov edx, msg_invite_len
    syscall

    xor eax, eax
    xor edi, edi
    mov rsi, str
    mov edx, size
    syscall



exit_ok:
    mov rdi, 0
    jmp EXIT

HANDLE_ERR:
    mov rdi, 1

EXIT:
    mov rax, 60         ; sys_exit
    syscall
