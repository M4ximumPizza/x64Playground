; xor_encrypt.asm - Windows x64
; Assemble: nasm -f win64 xor_encrypt.asm -o xor_encrypt.obj
; Link: gcc xor_encrypt.obj -o xor_encrypt.exe

extern puts
global main

section .data
    message db "Secret memory block XOR-encrypted.", 0x0A, 0
    secret_msg db "TOP_SECRET_DATA", 0        ; data to "encrypt"
    
    seed dq 987654321
    modulus dq 0x7FFFFFFF
    multiplier dq 1103515245
    increment dq 12345

section .bss
    rand_key resq 1     ; 64-bit random key
    encrypted resb 32   ; space to store encrypted data

section .text
main:
    ; -----------------------
    ; Generate pseudo-random key
    ; -----------------------
    mov rax, [rel seed]
    mov rbx, [rel multiplier]
    imul rax, rbx
    add rax, [rel increment]
    mov rbx, [rel modulus]
    xor rdx, rdx
    div rbx                  ; rdx = random number
    mov [rel rand_key], rdx  ; store as raw 64-bit key

    ; -----------------------
    ; XOR "secret" message with random key
    ; -----------------------
    lea rsi, [rel secret_msg]
    lea rdi, [rel encrypted]
    mov rcx, 14              ; length of secret_msg including 0
    mov rax, [rel rand_key]  ; key
xor_loop:
    mov bl, byte [rsi]
    xor bl, al               ; XOR with lowest 8 bits of key
    mov [rdi], bl
    inc rsi
    inc rdi
    loop xor_loop

    ; -----------------------
    ; Print a status message
    ; -----------------------
    lea rcx, [rel message]
    call puts

    xor eax, eax
    ret
