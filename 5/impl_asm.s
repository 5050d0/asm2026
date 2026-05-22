.intel_syntax noprefix
.section .data
.align 16
.Lmat:
    .long 1, 4, 6, 4, 1
    .long 4, 16, 24, 16, 4
    .long 6, 24, 36, 24, 6
    .long 4, 16, 24, 16, 4
    .long 1, 4, 6, 4, 1

# void gaussian_blur_asm
# const unsigned char *src   rdi
# unsigned char *dst         rsi
# uint64_t width             rdx
# uint64_t height            rcx
.text
.global gaussian_blur_asm
.type   gaussian_blur_asm, @function
gaussian_blur_asm:
    push rbp
    mov rbp, rsp
    push rbx
    push r12
    push r13
    push r14
    push r15
    sub rsp, 40

    cmp rdx, 4
    jl .Lexit
    cmp rcx, 4
    jl .Lexit

    mov [rsp+16], rdi #src
    mov [rsp+24], rsi #dst
    lea r11, [rdx+rdx*2] # 1 строка в байтах

    mov r8, rdx
    sub r8, 2
    mov [rsp], r8 # max_x

    mov r8, rcx
    sub r8, 2
    mov [rsp+8], r8 # max_y

    # src -> dst
    mov rax, rcx # height
    imul rax, r11 # total

    mov r8, rdi # src
    mov r9, rsi # dst
    xor r10, r10 # i = 0

.Lcopy_loop:
    cmp r10, rax
    jge .Lcopy_done
    mov cl, byte ptr [r8 + r10]
    mov byte ptr [r9 + r10], cl
    inc r10
    jmp .Lcopy_loop

.Lcopy_done:
    mov r12, [rsp+16] # src
    mov r13, [rsp+24] # dst

    mov rax, [rsp+8] # max_y
    imul rax, r11 # max_y * stride
    mov rcx, r13
    add rcx, rax
    mov [rsp+32], rcx # last row

    lea rax, [r11 + r11] # 2 * stride
    add r12, rax # src_row
    add r13, rax #dst_row

.Ly_loop:
    cmp r13, [rsp+32] # >=max_y
    jge .Lexit

    lea rbx, [r13+6] # st_row + 2px

    mov rax, [rsp] # max_x
    lea rax, [rax+rax*2] # max_x in bytes
    add rax, r13 # dst_end_ptr


    mov r15, r12
    sub r15, r11
    sub r15, r11
    add r15, 6 # верхний левый 5х5

.Lx_loop:
    cmp rbx, rax # dst_ptr>= dst_end_ptr
    jge .Lx_done

    xor r8d, r8d # rgb
    xor r9d, r9d
    xor r10d, r10d

    lea rsi, .Lmat[rip] # mat
    mov rdi, r15 # src + (y - 2) * 3 + (x-2)*3

    mov r14, 5 # my

.Lmy_loop:
    mov     rdx, 5 # mx
    push    rdi # начало строки окна

.Lmx_loop:
    mov     ebp, dword ptr [rsi] #w

    movzx ecx, byte ptr [rdi]
    imul ecx, ebp
    add r8d, ecx # acc[0] += px[0] * w

    movzx ecx, byte ptr [rdi+1]
    imul ecx, ebp
    add r9d, ecx

    movzx ecx, byte ptr [rdi+2]
    imul ecx, ebp
    add r10d, ecx

    add rsi, 4 # mat += 1
    add rdi, 3 # px += 3
    dec rdx # mx--
    jnz .Lmx_loop

    pop rdi
    add rdi, r11 # окно сдвигается на строку вниз
    dec r14 # my--
    jnz .Lmy_loop

    shr r8d, 8 #/256
    mov byte ptr [rbx], r8b
    shr r9d, 8
    mov byte ptr [rbx+1], r9b
    shr r10d, 8
    mov byte ptr [rbx+2], r10b

    add r15, 3
    add rbx, 3
    jmp .Lx_loop

.Lx_done:
    add r12, r11 # src_row += stride
    add r13, r11 # dst_row += stride
    jmp .Ly_loop
.Lexit:
    add rsp, 40
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    pop rbp
    ret
