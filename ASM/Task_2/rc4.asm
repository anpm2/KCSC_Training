section .data
    msg_plain db "Nhap plain text: ", 0
    msg_key db "Nhap key: ", 0
    msg_cipher db "Cipher text (hex): ", 0
    
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

    call ksa            ; Key scheduling algorithm (KSA)
    call prga           ; Pseudo-random generation algorithm (PRGA) để mã hóa
    
    ; In kết quả
    mov eax, msg_cipher
    call print
    mov eax, cipher
    call print
    call exit

ksa:
    push eax
    push ebx
    push ecx
    push edx
    
    ; Khởi tạo state array
    xor ecx, ecx      ; ecx = 0 --> idx = 0
    .init:
        mov byte [state + ecx], cl  ; state[idx] = idx
        inc ecx
        cmp ecx, 256
        jl .init

    xor ecx, ecx      ; i = 0
    xor ebx, ebx      ; j = 0
    .loop:
        ; j = (j + S[i] + key[i mod klen]) mod 256
        movzx eax, byte [state + ecx]   ; Zero extend để tránh lỗi
        add bl, al                      ; j += S[i]
        
        ; Tính i mod klen để lấy ký tự key
        push ecx                        ; Lưu lại ecx
        mov eax, ecx
        xor edx, edx
        div dword [klen]                ; edx = i mod klen
        movzx eax, byte [key + edx]     ; Lấy key[i mod klen]
        add bl, al                      ; j += key[i mod klen]
        pop ecx
        
        ; Swap state[i] và state[j]
        movzx eax, byte [state + ecx]   ; eax = state[i]
        movzx edx, byte [state + ebx]   ; edx = state[j]
        mov byte [state + ecx], dl      ; state[i] = state[j]
        mov byte [state + ebx], al      ; state[j] = state[i]
        
        inc ecx                         ; i++
        cmp ecx, 256
        jl .loop
    
    pop edx
    pop ecx  
    pop ebx
    pop eax
    ret

prga:
    push eax
    push ebx
    push ecx
    push edx
    push esi
    push edi
    
    xor ecx, ecx      ; i = 0
    xor ebx, ebx      ; j = 0
    xor esi, esi      ; index cho plain text
    xor edi, edi      ; index cho cipher text (hex output)
    .loop:
        ; Kiểm tra kết thúc plain text
        cmp esi, dword [plen]
        jge .done
        
        ; i = (i + 1) mod 256
        inc cl
        and cl, 0xFF      ; Đảm bảo trong phạm vi 256
        
        ; j = (j + state[i]) mod 256
        movzx eax, byte [state + ecx]
        add bl, al
        and bl, 0xFF
        
        ; Swap state[i] và state[j]
        movzx eax, byte [state + ecx]
        movzx edx, byte [state + ebx]  
        mov byte [state + ecx], dl
        mov byte [state + ebx], al
        
        ; t = state[(S[i] + state[j]) mod 256]
        add al, dl
        and al, 0xFF      ; Đảm bảo trong phạm vi 256
        movzx eax, byte [state + eax]   ; al = keystream byte
        
        ; XOR với plain text
        xor al, byte [plain + esi]
        
        ; Chuyển sang hex và lưu vào cipher
        mov ah, al
        shr al, 4                ; 4 bit cao
        call hex_char
        mov byte [cipher + edi], al
        inc edi
        
        mov al, ah
        and al, 0x0F            ; 4 bit thấp
        call hex_char  
        mov byte [cipher + edi], al
        inc edi
        
        inc esi
        jmp .loop
        
    .done:
        mov byte [cipher + edi], 10   ; Newline
        inc edi
        mov byte [cipher + edi], 0    ; thêm null 
        
    pop edi
    pop esi
    pop edx  
    pop ecx
    pop ebx
    pop eax
    ret

; Chuyển thành hex
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
    cmp al, 10          ; '\n'
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
