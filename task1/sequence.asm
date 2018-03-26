%define SYS_EXIT 60
%define SYS_READ 0
%define SYS_OPEN 2
%define SYS_CLOSE 3

%define BUFFER_SIZE 2048

section .data
    fd dw 0

section .bss
    file_buffer resb BUFFER_SIZE

; Code goes in the text section
section .text
    global _start 

; Set one of the bits of an area of 32 bytes (256 bits)
; Takes two arguments: pointer to 32-byte area (rdi), bit to set (rsi)
; Return 1 if this bit is already set, 0 otherwise
; Equivalent to:

; int set_bit(uint64_t *x, unsigned char bit) {
;     int which = bit / 64; 
;     uint64_t shift = ((uint64_t)1) << (63 - bit % 64);
;     if (x[which] & shift)
;         return 1;
;     x[which] |= shift;
;     return 0;
; }
set_bit:
    ; Copy second argument and divide it by 64
    mov ecx, esi
    shr sil, 0x6
    movzx esi, sil

    ; load effective address of the quadword where the bit lies
    lea rsi, [rdi + rsi*8]

    ; shift one by (63 - bit % 64) (a hack learned from gcc -O3)
    not ecx
    mov edx, 0x1
    shl rdx, cl

    ; if the bit is already one, return 1
    mov eax, 0x1
    mov rcx, QWORD [rsi]
    test rcx, rdx
    jne set_bit_ret


    ; otherwise, set the bit to one
    or rdx, rcx
    xor rax, rax
    mov QWORD [rsi], rdx

set_bit_ret:
    ; see http://repzret.org/p/repzret/
    repz ret

; Read an injective sequence of non-zero bytes followed by a zero byte from the file
; and save it into a 32-byte memory area. Takes one argument:
;   - pointer to 32-byte memory area
; Returns:
;   - 0 if the permutation has been read correctly
;   - 1 if there was nothing in the file to be read
;   - -1 if the sequence was not a permutation
; The following must be set before calling this function:
;   - fd
;   - r14, r15, containing the offset of the buffer and the
;               size of the data stored in buffer, respectively

read_permutation:
    mov QWORD [rdi], 0
    mov QWORD [rdi + 0x8], 0
    mov QWORD [rdi + 0x10], 0
    mov QWORD [rdi + 0x18], 0

    ; first, check if there's anything to be read inside the buffer
    cmp r14, r15 
    jnz _read_from_buffer

    ; read the contents of the file to buffer
    mov rax, SYS_READ
    mov rdi, [fd]
    mov rsi, file_buffer
    mov rdx, BUFFER_SIZE
    syscall

    ; initialize global variables
    mov r14, 0
    mov r15, rax

    ; if there's nothing left in the file, return 1
    cmp rax, 0
    mov rax, 0x1
    jz read_permutation_ret

    ; otherwise, read normally
    jmp _read_byte

_read_byte:
    cmp r14, r15
    jnz _read_from_buffer
    jmp _read_from_file

_read_from_file:
    ; read the contents of the file to buffer
    mov rax, SYS_READ
    mov rdi, [fd]
    mov rsi, file_buffer
    mov rdx, BUFFER_SIZE
    syscall

    ; initialize global variables
    mov r15, rax
    mov r14, 0

    ; if there's nothing left, return -1
    cmp eax, 0
    mov eax, -1
    jz read_permutation_ret
    

_read_from_buffer:
    mov r12, file_buffer
    add r12, r14

    inc r14

    xor r13, r13
    mov r13b, [r12]

    ; on zero, return zero
    xor rax, rax 
    test r13, r13
    je read_permutation_ret

    inc rbx

    ; on non-zero, try to set the bit
    mov rdi, rdi
    mov sil, [r12]
    call set_bit

    ; if the bit was already set, return -1
    mov rax, -1
    cmp rax, 0x1
    jz read_permutation_ret

    ; otherwise, continue reading
    jmp _read_byte

read_permutation_ret:
    repz ret

compare:
    mov rax, QWORD [rdi]
    mov rdx, QWORD [rdi + 0x8]
    xor rax, QWORD [rsi]
    xor rdx, QWORD [rsi + 0x8]
    or rdx, rax
    jne compare_ret_zero

    mov rax, QWORD [rdi + 0x10]
    mov rdx, QWORD [rdi + 0x18]
    xor rax, QWORD [rsi + 0x10]
    xor rdx, QWORD [rsi + 0x18]
    or rdx, rax
    je compare_ret_one

compare_ret_zero:
    mov rax, 0
    ret

compare_ret_one:
    mov rax, 1
    ret
    

; Main function
_start:
    xor r14, r14
    xor r15, r15

    xor rbx, rbx

    ; Check that argument count is 2
    pop r10
    cmp r10, 0x2
    jne _exit_one

    ; Skip the program name
    add rsp, 0x8

    ; Open the file
    mov rax, SYS_OPEN
    pop rdi
    mov rsi, 0
    syscall
    mov [fd], rax

    ; Check if opening the file succeeded
    cmp rax, 0
    jl _exit_one

    ; initialize in_buffer and read_from_buffer values
    xor r14, r14
    xor r15, r15

    ; allocate 64 bytes for first permutation and for next permutations
    ; r8 stores the first permutation, r9 each next one
    sub rsp, 0x20
    mov r8, rsp
    sub rsp, 0x20
    mov r9, rsp

    mov rdi, r8
    call read_permutation

    ; if the read was in any way unsuccesful, return 1
    cmp rax, 0
    mov rax, 0x1
    jnz _cleanup

read_next_permutation:

    mov rdi, r9
    call read_permutation

    ; if the file is used up, return 0
    cmp rax, 1
    xor rax, rax
    mov rax, rbx
    jz _cleanup

    ; if reading the permutation failed, return 1
    cmp rax, -1
    mov rax, 1
    jz _cleanup

    ; if any one of the 32 bytes differ, return 1
    mov rdi, r8
    mov rsi, r9
    call compare
    cmp rax, 0
    mov rax, 0x1
    jz _cleanup

    jmp read_next_permutation
    

_cleanup:
    push rax

    ; close the file
    mov rax, SYS_CLOSE
    mov rdi, fd
    syscall

    pop rdi

    ; free the allocated memory
    add rsp, 0x40

    jmp _exit

_exit:
    mov rax, SYS_EXIT
    syscall

_exit_one:
    mov rax, SYS_EXIT
    mov rdi, 1
    syscall

_exit_two:
    mov rax, SYS_EXIT
    mov rdi, 3
    syscall

