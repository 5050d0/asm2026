bits 64
default rel
global _start

section .data
a dq 9223372036854775807
b dd 6
c dd 0
d db 100
e dw -33
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
# jo HANDLE_ERR
mov r10, rdx
mov r11, rax ; rdx:rax -> r10:r11


movsx rax, word [e]
mov rcx, rax
;movsxd r8, dword [b]
add rcx, r8 ; 16 + 32

;movsxd rcx, dword [b]
sub rax, r8 ; 8 - 32 может выйти  за 32, но не за 64

imul rcx; (e-b)(e+b) -> rdx:rax

add rax, r11
adc rdx, r10 ; rdx:rax + r10:r11 = rdx:rax
jo HANDLE_ERR
;imul r9, rcx ; (e-b)(e+b) -> r9

; todo тут надо r9 + rdx:rax


;add rax, rbx; числитель -> rax
;jo HANDLE_ERR

;movsxd rbx, dword [b]
test r8, r8; проверка на 0
jz HANDLE_ERR
imul r8, r8 ; знаменатель -> rbx
jo HANDLE_ERR


;cqo; rax -> rdx:rax
idiv r8; rdx:rax/rbx -> rax - частное, rdx - ост;
mov [res], rax

mov rdi, 0 ; 0  exit code
jmp EXIT;


HANDLE_ERR:
mov rdi, 1 ; exit code
;jmp EXIT;
EXIT:
mov rax, 60
syscall
