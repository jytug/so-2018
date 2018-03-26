section .text
    global proberen
    global verhogen
    global proberen_time

    extern get_os_time

; void proberen(int32_t *semaphore, int32_t value);
proberen:
    push r14
    jmp wait_loop

give_back:
    lock add DWORD [rdi], esi

wait_loop:
    cmp DWORD [rdi], esi
    jl wait_loop

    mov DWORD r14d, esi
    neg r14d
    lock xadd DWORD [rdi], r14d

    cmp r14d, esi
    jl give_back

    pop r14
    ret

; void verhogen(int32_t *semaphore, int32_t value);
verhogen:
    lock xadd DWORD [rdi], esi
    ret

; uint64_t proberen_time(int32_t *semaphore, int32_t value);
proberen_time:
    push r12
    push rbp
    push rbx

    mov r12d, esi
    mov rbp, rdi
    call get_os_time

    mov esi, r12d
    mov rbx, rax
    mov rdi, rbp
    call proberen

    call get_os_time
    sub rax, rbx

    pop rbx
    pop rbp
    pop r12

    ret
