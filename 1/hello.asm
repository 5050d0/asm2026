bits 64
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
movsx rax, dword [rel b]
movsx rbx, byte [rel d]
add rax, rbx ; d+b 32+8 может выйти за 32, но за 64 не может

mov rbx, [rel a]
movsx rdx, dword [rel c]
sub rbx, rdx ; a-c может переполниться, надо проверить
jo HANDLE_ERR


imul rax, rbx ; (d+b)*(a-c) -> rax
jo HANDLE_ERR

movsx rbx, word [rel e]
movsx rcx,dword [rel b]
sub rbx, rcx ; 8 - 32 может выйти  за 32

movsx rcx, word [rel e]
movsx rsp, dword [rel b]
add rcx, rsp ; 16 + 32

imul rbx, rcx ; (e-b)(e+b) ->rbx
jo HANDLE_ERR

xor rdx, rdx ;
add rax, rbx; числитель -> rax
jo HANDLE_ERR
;adc rdx, 0 ; остаток от суммы числителя -> rdx НЕ РАБОТАЕТ

movsx rbx, dword [rel b]
imul rbx, rbx ; знаменатель -> rbx
jo HANDLE_ERR

idiv rbx; rdx:rax/rbx -> rax - частное, rdx - ост
mov [rel res], rax
nop

mov rdi, 0 ; 0  exit code
jmp EXIT;


HANDLE_ERR:
mov rdi, 1 ; exit code
;jmp EXIT;
EXIT:
mov rax, 60
syscall
