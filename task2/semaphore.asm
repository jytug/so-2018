section .text
    global proberen
    global verhogen
    global proberen_time

; void proberen(int32_t *semaphore, int32_t value);
proberen:
    jmp wait_loop

give_back:
    lock xadd DWORD [rdi], esi

wait_loop:
    cmp DWORD [rdi], esi
    jl wait_loop

    mov DWORD r8d, esi
    neg r8d
    lock xadd DWORD [rdi], r8d

    cmp r8d, esi
    jl give_back

    ret

; when the wait is over, decrement the semaphore
    

; void verhogen(int32_t *semaphore, int32_t value);
verhogen:
    lock xadd DWORD [rdi], esi
    ret

; uint64_t proberen_time(int32_t *semaphore, int32_t value);
proberen_time:
    ret
