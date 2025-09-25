; nop_sled_win.asm - minimal working Windows x64 NOP sled with output
; Assemble: nasm -f win64 nop_sled_win.asm -o nop_sled_win.obj
; Link: gcc nop_sled_win.obj -o nop_sled_win.exe

extern puts
global main

section .data
    message db "Payload reached!", 0x0A, 0

section .text
main:
    ; NOP sled
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop

    ; Call puts
    lea rcx, [rel message]
    call puts

    xor eax, eax
    ret
