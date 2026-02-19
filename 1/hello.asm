bits 64
global _start           ; делаем метку метку _start видимой извне

section .data   ; секция данных
a dq 1
b dd 2
c dd 3
d db 4
e dw 5
res dq 0

section .text           ; объявление секции кода

_start:                 ; объявление метки _start - точки входа в программу
movsx rax, dword [rel b]
movsx rbx, byte [rel d]
add rax, rbx ; d+b 32+8 может выйти за 32

mov rbx, [rel a]
movsx rdx, dword [rel c]
sub rbx, rdx ; a-c
imul rax, rbx ; (d+b)*(a-c) -> rdx:rax

movsx rbx, word [rel e]
movsx rcx,dword [rel b]
sub rbx, rcx ; 8 - 32 может выйти  за 32

movsx rcx, word [rel e]
movsx rsp, dword [rel b]
add rcx, rsp ; 16 + 32

imul rbx, rcx ; (e-b)(e+b) ->rbx

xor rdx, rdx ;
add rax, rbx; числитель -> rax
adc rdx, 0 ; остаток от суммы числителя -> rdx НЕ РАБОТАЕТ

movsx rbx, dword [rel b]
imul rbx, rbx ; знаменатель -> rbx

idiv rbx; rdx:rax/rbx -> rax - частное, rdx - ост
mov [rel res], rax
nop

mov rax, 60         ; 60 - номер системного вызова exit
syscall             ; выполняем системный вызов exit
