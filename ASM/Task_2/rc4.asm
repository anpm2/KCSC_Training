section .data
    msg_plain db "Nhap plaintext: ", 0
    msg_key db "Nhap key: ", 0
    msg_cipher db "ciphertext (hex): ", 0
    
    ; Buffer cho state array
    state times 256 db 0
    
section .bss
    plain resb 256
    key resb 256
    cipher resb 512
    
    temp resb 1
    plen resd 1
    klen resd 1

section .text
global _start
_start:
    ; Nhập plain text
    mov eax, msg_plain
    call print
    mov eax, plain
    call scan
    mov eax, plain
    call slen
    mov [plen], eax   ; plain text length
    
    ; Nhập key  
    mov eax, msg_key
    call print
    mov eax, key  
    call scan
    mov eax, key
    call slen
    mov [klen], eax     ; key length

    ; Khởi tạo state array
    xor ecx, ecx      ; ecx = 0 --> idx = 0
    .init:
        mov byte [state + ecx], cl  ; state[idx] = idx
        inc ecx
        cmp ecx, 256
        jl .init

    push cipher
    push dword [klen]
    push key
    push dword [plen]
    push plain
    call rc4
    ; cipher = rc4(plain, plen, key, klen)
    
    mov eax, msg_cipher
    call print
    
    ; Vòng lặp in từng ký tự hex
    mov ecx, [plen]     ; Load plaintext length
    mov esi, cipher     ; Load cipher buffer address
    
.print_hex:
    movzx eax, byte [esi]    ; Load byte from cipher
    
    ; Print first hex digit
    mov bl, al
    shr bl, 4           ; Get high 4 bits
    mov al, bl
    call hex_char
    mov [temp], al      ; Store hex char
    mov eax, temp
    push ecx
    call print          ; Print first hex digit
    pop ecx
    
    ; Print second hex digit
    movzx eax, byte [esi]    ; Reload byte
    and al, 0x0F        ; Get low 4 bits
    call hex_char
    mov [temp], al      ; Store hex char
    mov eax, temp
    push ecx
    call print          ; Print second hex digit
    pop ecx
    
    inc esi             ; Move to next byte
    dec ecx             ; Decrease counter
    jnz .print_hex      ; Continue if not zero

    call exit

rc4:
    push ebp
    mov ebp, esp
    push ebx
    push esi
    push edi

    ; ebp + 8  = plain
    ; ebp + 12 = plen
    ; ebp + 16 = key
    ; ebp + 20 = klen
    ; ebp + 24 = cipher
    
    xor edi, edi    ; j = 0
    
    ; KSA
    xor ecx, ecx    ; i = 0
.ksa_loop:
    ; j = (j + state[i] + key[i mod klen]) mod 256
    movzx eax, byte [state + ecx]  ; state[i]
    add edi, eax                   ; j += state[i]
    
    mov eax, ecx
    xor edx, edx
    div dword [ebp + 20]          ; i mod klen
    mov eax, [ebp + 16]           ; key address
    movzx eax, byte [eax + edx]   ; key[i mod klen]
    add edi, eax                  ; j += key[i mod klen]
    and edi, 0xFF                 ; j mod 256
    
    ; Swap state[i] and state[j]
    mov al, [state + ecx]
    mov bl, [state + edi]
    mov [state + edi], al
    mov [state + ecx], bl
    
    inc ecx
    cmp ecx, 256
    jl .ksa_loop
    
    ; PRGA
    xor ecx, ecx    ; i = 0
    xor edi, edi    ; j = 0
    xor esi, esi    ; output index
    
.prga_loop:
    ; Check if we've processed all bytes
    cmp esi, [ebp + 12]    ; Compare with plen
    jge .prga_done
    
    ; i = (i + 1) mod 256
    inc ecx
    and ecx, 0xFF
    
    ; j = (j + state[i]) mod 256
    movzx eax, byte [state + ecx]
    add edi, eax
    and edi, 0xFF
    
    ; Swap state[i] and state[j]
    mov al, [state + ecx]
    mov bl, [state + edi]
    mov [state + edi], al
    mov [state + ecx], bl
    
    ; t = (state[i] + state[j]) mod 256
    movzx eax, byte [state + ecx]
    movzx ebx, byte [state + edi]
    add eax, ebx
    and eax, 0xFF
    
    ; k = state[t]
    movzx eax, byte [state + eax]
    
    ; XOR with plaintext
    mov ebx, [ebp + 8]    ; plain
    movzx ebx, byte [ebx + esi]
    xor eax, ebx
    
    ; Store in cipher
    mov ebx, [ebp + 24]   ; cipher
    mov [ebx + esi], al
    
    inc esi                ; Move to next byte
    jmp .prga_loop
    
.prga_done:
    pop edi
    pop esi
    pop ebx
    pop ebp
    ret

; Chuyển thành ký tự hex
hex_char:
    cmp al, 10
    jge .letter
    add al, '0'
    ret
    .letter:
    add al, 'a' - 10
    ret

print:
    push edx
    push ecx
    push ebx
    push eax
    call slen
    mov edx, eax
    pop eax
    mov ecx, eax
    mov ebx, 1
    mov eax, 4
    int 0x80
    pop ebx
    pop ecx
    pop edx
    ret

scan:
    push edx
    push ecx
    push ebx
    push eax
    
    mov ebx, eax        ; Lưu địa chỉ buffer vào ebx
    
.read_loop:
    ; Đọc 1 ký tự
    push ebx            ; Lưu ebx vì sys_read có thể thay đổi nó
    mov edx, 1          ; Đọc 1 byte
    mov ecx, temp       ; Buffer tạm
    mov ebx, 0          ; stdin
    mov eax, 3          ; sys_read
    int 0x80
    pop ebx             ; Khôi phục ebx
    
    ; Kiểm tra có đọc được ký tự không
    cmp eax, 0          ; Nếu eax = 0, EOF
    jle .done
    
    ; Lấy ký tự vừa đọc
    mov al, [temp]
    
    ; Kiểm tra có phải newline không
    cmp al, 10
    je .done
    
    ; Nếu không phải newline, lưu vào buffer
    mov [ebx], al
    inc ebx             ; Tăng con trỏ buffer
    
    jmp .read_loop
    
.done:
    mov byte [ebx], 0   ; Thêm null vào cuối
    
    pop eax
    pop ebx
    pop ecx
    pop edx
    ret

slen:
    push ebx
    mov ebx, eax
    .next_char:
        cmp byte [eax], 0
        jz .end
        inc eax
        jmp .next_char
    .end:
        sub eax, ebx
        pop ebx
        ret

exit:
    mov eax, 1
    mov ebx, 0
    int 0x80
