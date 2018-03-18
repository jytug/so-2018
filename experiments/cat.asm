%define SYS_EXIT 60
%define SYS_READ 0
%define SYS_WRITE 1
%define SYS_OPEN 2
%define SYS_CLOSE 3
%define STDOUT 1

%define BUFFER_SIZE 2048

section .text
global  _start
_start:
  ; Get the first argument
  add rsp, byte 10h
  pop rdi

  ; Open the file
  mov rax, SYS_OPEN
  mov rsi, 0
  syscall
  mov [fd], rax


_read_write:
  ; Read the contents of the file
  mov rax, SYS_READ
  mov rdi, [fd]
  mov rsi, file_buffer
  mov rdx, BUFFER_SIZE
  syscall

  ; When end-of-file is met, exit
  cmp rax, 0
  je _exit

  ; Display the contents of the buffer
  mov rdx, rax
  mov rax, SYS_WRITE
  mov rdi, STDOUT
  mov rsi, file_buffer
  syscall

  jp _read_write


_exit:
  ; Close the file
  mov rax, SYS_CLOSE
  mov rdi, fd
  syscall

  ; Add a new line
  mov [file_buffer], dword 10
  mov rax, SYS_WRITE
  mov rdi, STDOUT
  mov rsi, file_buffer
  mov rdx, 1
  syscall

  ; Exit
  mov rax, 60
  mov rdi, 0
  syscall


section .data
fd dw 0

section .bss
file_buffer resb BUFFER_SIZE
