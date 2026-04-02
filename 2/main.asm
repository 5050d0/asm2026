bits 64
default rel
global _start

section .data
matx db 4
maty db 2
mat:
    db 8, -5, 7, -1
    db 3, -12, 5, 0

section .text

; r9 - длина строки,  r8 - адрес начала строки
sortline:
    cmp r9, 1
    jle done

    push rax
    push rbx
    push rcx
    push rdx
    push r10
    push r11
    push r12

    mov r10, r9         ; r10 текущий шаг

outer_loop:
    ;  шаг = шаг * 10 / 13
    mov rax, r10
    mov rbx, 10
    mul rbx
    mov rbx, 13
    div rbx
    mov r10, rax

    cmp r10, 1
    jge gap_ok
    mov r10, 1          ; Если шаг < 1, делаем его = 1
gap_ok:

    mov r11, 0          ; колво перестановок за цикл
    mov r12, 0          ; i=0

    ; цикл идёт до длины - шаг
    mov rcx, r9
    sub rcx, r10

inner_loop:
    cmp r12, rcx
    jge inner_done     ; выхд

    mov rdx, r12       ; rdx = i
    add rdx, r10       ; rdx = i + шаг

    mov al, byte [r8 + r12]       ; al = array[i]
    mov bl, byte [r8 + rdx]       ; bl = array[i + шаг]

    cmp al, bl
    jle no_swap

    mov byte [r8 + r12], bl
    mov byte [r8 + rdx], al
    inc r11       ; swap++

no_swap:
    inc r12
    jmp inner_loop

inner_done:
; если шаг ==1 и не было обменов то массив отсортирован, можно выходить
    cmp r10, 1
    jne outer_loop
    cmp r11, 0
    jne outer_loop

    pop r12
    pop r11
    pop r10
    pop rdx
    pop rcx
    pop rbx
    pop rax
done:
    ret

_start:
    xor rcx, rcx
    mov cl, byte [maty]

    cmp rcx, 0
    je exit_ok

    xor r9, r9
    mov r9b, byte [matx]

    cmp r9, 0
    je exit_ok

    mov r8, mat
linesloop:
    call sortline
    add r8, r9
    loop linesloop
exit_ok:
    mov rdi, 0
    jmp EXIT

HANDLE_ERR:
    mov rdi, 1

EXIT:
    mov rax, 60         ; sys_exit
    syscall
