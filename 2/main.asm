bits 64
default rel
global _start

section .data
matx db 4
maty db 2
mat: ; x/8hb &mat
    db 5, 6, 7, 8
    db 3, 4, 5, 6

section .text

sortline: ; cl - line length, r8 - line start adress
ret

_start:
xor rcx,rcx
mov cl, [maty]
xor r9, r9
mov r9b, matx
mov r8, mat
linesloop:
call sortline
add r8, r9
loop linesloop

mov rdi, 0 ; 0  exit code
jmp EXIT;
HANDLE_ERR:
mov rdi, 1 ; exit code
EXIT:
mov rax, 60
syscall
