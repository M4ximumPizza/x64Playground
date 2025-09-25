; random_number.asm - Windows x64
; Assemble: nasm -f win64 random_number.asm -o random_number.obj
; Link: gcc random_number.obj -o random_number.exe

extern puts
global main

section .data
    message db "Random number generated (binary in memory).", 0x0A, 0

    seed dq 1234567890
    modulus dq 0x7FFFFFFF
    multiplier dq 1103515245
    increment dq 12345

section .bss
    rand_num resq 1   ; 64-bit binary random number stored here

section .text
main:
    ; -----------------------
    ; Generate pseudo-random number (binary)
    ; -----------------------
    mov rax, [rel seed]
    mov rbx, [rel multiplier]
    imul rax, rbx
    add rax, [rel increment]
    mov rbx, [rel modulus]
    xor rdx, rdx
    div rbx                 ; rdx = random number
    mov [rel rand_num], rdx ; store as raw 64-bit binary

    ; -----------------------
    ; Print a message
    ; -----------------------
    lea rcx, [rel message]
    call puts

    xor eax, eax
    ret
