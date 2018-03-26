section .text
    global proberen
    global verhogen
    global proberen_time

    extern get_os_time

; void proberen(int32_t *semaphore, int32_t value);
; Wait in a busy loop until *semaphore >= value and
; decrement it to ensure safe entrance to the critical section
proberen:
    push r14
    jmp wait_loop

; Once the waiting loop is over, there is still a chance
; for another thread to decrement the semaphore's value.
; In such cases, the value we took is returned to the semaphore
; and the thread returns to the spinlock
give_back:
    lock add DWORD [rdi], esi

; Before entering the critical section, the calling thread
; waits in a spinlock, until *semaphore >= value
wait_loop:
    cmp DWORD [rdi], esi
    jl wait_loop

    ; Decrement the semaphore by value
    mov DWORD r14d, esi
    neg r14d
    lock xadd DWORD [rdi], r14d

    ; Check if at the moment of decrementing the
    ; semaphore's value was still not less than value.
    ; If it wasn't, jump to `give_back` label
    cmp r14d, esi
    jl give_back

    ; Otherwise, return from the function
    pop r14
    ret

; void verhogen(int32_t *semaphore, int32_t value);
; Increment *semaphore by value atomically
verhogen:
    lock xadd DWORD [rdi], esi
    ret

; uint64_t proberen_time(int32_t *semaphore, int32_t value);
; Equivalent to proberen, but returns the time it took to wait
; on the semaphore. The time is determined by an external function,
;
; uint64_t get_os_time(void);
proberen_time:
    ; push callee-saved registers to the stack
    push r12
    push rbp
    push rbx

    ; get the time before calling proberen and save it to rbx
    mov r12d, esi
    mov rbp, rdi
    call get_os_time
    mov rbx, rax

    ; call proberen
    mov esi, r12d
    mov rdi, rbp
    call proberen

    ; get the time after calling proberen and subtract the previously
    ; saved time from it. It will be the return value of this function
    call get_os_time
    sub rax, rbx

    ; pop the callee-saved registers from the stack
    pop rbx
    pop rbp
    pop r12

    ret
