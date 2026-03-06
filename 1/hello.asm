bits 64
default rel
global _start

section .data
a dq 9223372036854775807
b dd 60000
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
mov r10, rdx
mov r11, rax ; rdx:rax -> r10:r11


movsx rax, word [e]
mov rcx, rax
add rcx, r8 ; 16 + 32

sub rax, r8 ; 8 - 32 может выйти  за 32, но не за 64

imul rcx; (e-b)(e+b) -> rdx:rax
; не может переполниться

add rax, r11
adc rdx, r10 ; rdx:rax + r10:r11 = rdx:rax
jo HANDLE_ERR

test r8, r8; проверка на 0
jz HANDLE_ERR
imul r8, r8 ; знаменатель -> r8
jo HANDLE_ERR
mov rbx, r8

;будет переполнение если rdx:rax/rbx >= 2^63
; rdx:rax/2^63 >= rbx, rax/2^63 <=1
; rdx >= rbx
mov r10, rdx
test r10, r10
jns SKIP_ABS
neg r10
SKIP_ABS:
cmp r10, rbx
jns HANDLE_ERR
jz HANDLE_ERR

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
