bits 64
default rel
global _start

section .data
a dq 1
b dd 2
c dd 3
d db 4
e dw 5
res dq 0

section .text
_start:
movsxd r8, dword [b]
movsx rax, byte [d]
add rax, r8 ; d+b 32+8 может выйти за 32, но за 64 не может

mov rbx, [a]
movsxd rdx, dword [c]
sub rbx, rdx ; a-c может переполниться, надо проверить
jo HANDLE_ERR

imul rbx ; (d+b)*(a-c) -> rdx:rax
jo HANDLE_ERR


movsx r9, word [e]
mov rcx, r9
;movsxd r8, dword [b]
add rcx, r8 ; 16 + 32

;movsxd rcx, dword [b]
sub r9, r8 ; 8 - 32 может выйти  за 32, но не за 64


imul r9, rcx ; (e-b)(e+b) -> r9
;jo HANDLE_ERR

; todo тут надо r9 + rdx:rax


;add rax, rbx; числитель -> rax
;jo HANDLE_ERR

;movsxd rbx, dword [b]
test r8, r8; проверка на 0
jz HANDLE_ERR
imul rbx, rbx ; знаменатель -> rbx
jo HANDLE_ERR


cqo; rax -> rdx:rax
idiv rbx; rdx:rax/rbx -> rax - частное, rdx - ост; не может переполни
mov [res], rax

mov rdi, 0 ; 0  exit code
jmp EXIT;


HANDLE_ERR:
mov rdi, 1 ; exit code
;jmp EXIT;
EXIT:
mov rax, 60
syscall
