; xor_buffer_test.asm 
; Demonstrates XOR-ing a buffer (common in shellcode/malware testing)
; Assemble: nasm -f win64 xor_buffer_test.asm -o xor_buffer_test.obj
; Link: gcc xor_buffer_test.obj -o xor_buffer_test.exe

extern puts
global main

section .data
    message db "Buffer XOR complete!", 0x0A, 0
    buffer_bytes db 1, 2, 3, 4, 5, 0

section .text
main:
    ; RCX = pointer to buffer
    lea rcx, [rel buffer_bytes]
    ; RDX = length of buffer
    mov rdx, 5
xor_loop:
    mov al, [rcx]       ; load byte
    xor al, 0xFF        ; invert all bits (simple XOR)
    mov [rcx], al       ; store back
    inc rcx
    dec rdx
    jnz xor_loop

    ; call payload: print completion message
    lea rcx, [rel message]
    call puts

    xor eax, eax
    ret
