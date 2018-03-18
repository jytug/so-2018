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

_start:
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

_read_to_buffer:
    ; Read the file in chunks of BUFFER_SIZE bytes
    xor r10, r10
    mov rax, SYS_READ
    mov rdi, [fd]
    mov rsi, file_buffer
    mov rdx, BUFFER_SIZE
    syscall

    ; When end-of-file is met, exit
    cmp rax, 0
    je _exit

    ; Otherwise, we will read the buffer byte by byte
    mov r10, file_buffer
    xor r11, r11

_read_byte:
    ; When end-of-file is met, exit
    cmp rax, 0
    je _exit_zero

    jmp _exit_zero

_exit:
    jmp _exit_zero

_exit_zero:
    mov rax, SYS_EXIT
    mov rdi, 0
    syscall

_exit_one:
    mov rax, SYS_EXIT
    mov rdi, 1
    syscall
