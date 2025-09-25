; scan_xor.asm - Windows x64
; Assemble: nasm -f win64 scan_xor.asm -o scan_xor.obj
; Link: gcc scan_xor.obj -o scan_xor.exe
; Purpose: Example memory scanner + XOR-encrypt demo for learning/CTF exercises.

extern printf
global main

section .data
    title_msg     db "Memory Scanner & XOR Encrypt Demo", 0x0A, 0
    start_msg     db "Starting scan...", 0x0A, 0
    done_msg      db "Scan complete. Encrypted matches in-place.", 0x0A, 0
    fmt_found     db "Found pattern at offset 0x%llx (encrypted %u bytes).", 0x0A, 0
    fmt_key       db "Generated key: 0x%llx", 0x0A, 0

    ; PRNG constants (LCG) - educational only
    prng_seed     dq 0x123456789ABCDEF    ; initial seed
    prng_mul      dq 1103515245
    prng_inc      dq 12345
    prng_mod      dq 0x7FFFFFFF

    ; Pattern to search for (4 bytes)
    pattern       dd 0x4347414D    ; ASCII 'MAGC' little-endian (M A G C) -> 0x4D414743 -> we store reversed for direct dword compare
                    ; But store as 0x4347414D so that when compared as dword it matches little-endian bytes 'MAGC'

section .rodata
    ; create a fake memory region with "noise" and a few "secrets"
    ; include pattern occurrences followed by plaintext to be XORed
    memory_region:
        db "NOISE_NOISE_NOISE__"           ; offset 0
        db "MAGC"                          ; pattern at some offset
        db "SECRET_ONE_12345" , 0
        db "RANDOM_FILL_1234567890"        ; more noise
        db "MAGC"                          ; second occurrence
        db "SECOND_SECRET_DATA!!!" , 0
        db "PAD_PAD_PAD_PAD_PAD"
        db "MAGC"                          ; third occurrence
        db "THIRD_SECRET" , 0
    memory_region_end:

section .bss
    key_res  resq 1     ; 64-bit key

section .text
main:
    ; prologue - no frame pointer needed, but we'll keep stack alignment for calls
    ; print title
    lea rcx, [rel title_msg]
    sub rsp, 40             ; shadow space + align (32 bytes shadow + 8 to keep 16-byte alignment)
    call printf
    add rsp, 40

    ; print start message (use printf for consistent calling)
    lea rcx, [rel start_msg]
    sub rsp, 40
    call printf
    add rsp, 40

    ; -----------------------
    ; Generate pseudo-random 64-bit key (LCG)
    ; -----------------------
    mov rax, [rel prng_seed]    ; seed
    mov rbx, [rel prng_mul]
    imul rax, rbx               ; rax = seed * mul
    add rax, [rel prng_inc]     ; rax += inc
    mov rbx, [rel prng_mod]
    xor rdx, rdx
    div rbx                     ; divide rax by modulus -> quotient in rax, remainder in rdx
    ; use remainder as key material
    mov rax, rdx
    ; expand to full 64-bit somewhat (educational; still not cryptographically sound)
    shl rax, 32
    xor rax, rdx
    mov [rel key_res], rax

    ; print key
    lea rcx, [rel fmt_key]
    mov rdx, rax                ; second arg: key value
    sub rsp, 40
    call printf
    add rsp, 40

    ; -----------------------
    ; Scan memory_region for 4-byte pattern and XOR-encrypt following block
    ; -----------------------
    lea rsi, [rel memory_region]        ; rsi = start pointer
    lea rdi, [rel memory_region_end]    ; rdi = end pointer
    mov r8, rsi                         ; keep base pointer in r8 for offset calc

scan_loop:
    cmp rsi, rdi
    jae scan_done

    ; ensure we have at least 4 bytes to compare: (rdi - rsi) >= 4
    mov rax, rdi
    sub rax, rsi
    cmp rax, 4
    jb scan_done

    ; compare 4 bytes (dword) with pattern
    mov edx, [rsi]              ; read dword at [rsi]
    cmp edx, dword [rel pattern]
    jne next_byte

    ; match found at rsi
    ; compute offset = rsi - base
    lea rcx, [rel fmt_found]    ; format pointer (1st arg)
    mov rax, rsi
    sub rax, r8                 ; rax = offset
    mov rdx, rax                ; 2nd arg -> offset (unsigned long long)
    mov ecx, 16                 ; third arg -> number of bytes to encrypt (we'll pass as unsigned int)
    ; Windows x64 printf args: rcx=format, rdx=arg1, r8=arg2 -> but we want 3 args
    ; We must move third arg into r8 (for varargs it's in r8)
    mov r8d, ecx
    sub rsp, 40
    call printf
    add rsp, 40

    ; Now perform XOR encryption in-place on the next N bytes
    ; We'll XOR up to 16 bytes after the pattern or until we hit the region end or null terminator
    ; rsi currently points at pattern start; advance by 4 to start encrypting after pattern
    lea rbx, [rsi + 4]          ; pointer to data to encrypt
    xor rcx, rcx                ; counter
    mov rcx, 16                 ; max bytes
encrypt_loop:
    cmp rbx, rdi
    jae encrypt_done            ; if pointer beyond region end, stop
    mov al, [rbx]
    cmp al, 0
    je encrypt_done             ; stop at NUL
    ; XOR lowest byte of key with byte
    mov rax, [rel key_res]
    mov bl, al
    mov al, al                  ; ensure al has byte (already)
    mov dl, al
    ; XOR with lowest 8 bits of key
    mov al, byte [rel key_res]  ; al = low key byte
    xor dl, al
    mov [rbx], dl
    inc rbx
    dec rcx
    jnz encrypt_loop

encrypt_done:
    ; continue scanning after the pattern (skip pattern bytes to avoid re-detecting at same spot)
    add rsi, 4
    jmp scan_loop

next_byte:
    inc rsi
    jmp scan_loop

scan_done:
    ; print done message
    lea rcx, [rel done_msg]
    sub rsp, 40
    call printf
    add rsp, 40

    xor eax, eax
    ret
