section .data
    prompt1 db "Nhap so thu nhat: ", 0
    prompt2 db "Nhap so thu hai: ", 0
    result_msg db "Sum = ", 0

section .bss
    num1 resb 21
    num2 resb 21
    res resb 22

section .text
global _start

_start:
    mov eax, prompt1
    call print
    mov eax, num1
    call scan

    mov eax, prompt2
    call print
    mov eax, num2
    call scan

    push num1
    push num2
    push res
    call sum

    mov eax, result_msg
    call print

    mov eax, res
    call print

    call exit

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

    mov edx, 21
    mov ecx, eax
    mov ebx, 0
    mov eax, 3
    int 0x80
    
    ; Xử lý newline
    push eax            ; Lưu lại số ký tự đọc được
    dec eax             ; Trừ 1 để lấy vị trí cuối cùng (trước \n)
    add ecx, eax        ; Di chuyển đến vị trí cuối
    mov byte [ecx], 0   ; Thay \n bằng null terminator
    pop eax
    
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

; Ý tưởng để tính tổng là đảo ngược num1 và num2 sau đó tính tổng và lưu vào res (lưu ý nếu 1 trong 2 chuỗi ngắn hơn thì thêm 0 vào để tính toán)
sum:
    push ebp
    mov ebp, esp
    push eax
    push ebx
    push ecx
    push edx
    push esi
    push edi

    ; Đầu tiên đảo ngược cả 2 chuỗi
    mov eax, [ebp + 16]     ; num1
    call reverse
    mov eax, [ebp + 12]     ; num2 
    call reverse

    ; Tính độ dài 2 chuỗi
    mov eax, [ebp + 16]     ; num1
    call slen
    mov esi, eax            ; esi = len(num1)
    mov eax, [ebp + 12]     ; num2
    call slen  
    mov edi, eax            ; edi = len(num2)

    ; Tìm độ dài lớn nhất
    mov ecx, esi
    cmp ecx, edi
    jge .store_maxLen
    mov ecx, edi
    .store_maxLen:
        push ecx                ; Lưu độ dài max

    ; Thêm số 0 vào chuỗi ngắn hơn (nếu có)
    mov ebx, [ebp + 16]     ; num1
    add ebx, esi            ; ebx trỏ tới cuối num1
    .pad_num1:
        cmp esi, ecx
        jge .pad_num2       ; Nếu num1 dài = max_len thì qua num2
        mov byte [ebx], '0' ; Thêm '0' vào cuối
        inc ebx
        inc esi
        jmp .pad_num1

    .pad_num2:
        mov ebx, [ebp + 12] ; num2
        add ebx, edi        ; ebx trỏ tới cuối num2
        cmp edi, ecx
        jge .add_numbers    ; Nếu num2 dài = max_len thì tính tổng
        mov byte [ebx], '0'
        inc ebx
        inc edi
        jmp .pad_num2

    .add_numbers:
        xor ecx, ecx        ; index = 0
        xor edx, edx        ; carry = 0
        mov esi, [ebp + 16] ; num1
        mov edi, [ebp + 12] ; num2

    .add_loop:
        cmp ecx, [esp]      ; So sánh với độ dài max
        jge .addition_done

        ; Chuyển đổi ký tự tại vị trí ecx từ ASCII --> số
        mov al, [esi + ecx]
        sub al, '0'
        mov bl, [edi + ecx]
        sub bl, '0'

        ; Cộng các chữ số và carry
        add al, bl
        add al, dl
        mov dl, 0           ; Reset carry về 0

        ; Kiểm tra nếu tổng >= 10
        cmp al, 10
        jl .store_digit
        sub al, 10
        mov dl, 1           ; Set carry = 1

    .store_digit:
        ; Lưu chữ số vào kết quả
        add al, '0'         ; Chuyển lại thành ASCII
        mov ebx, [ebp + 8]  ; res
        mov [ebx + ecx], al
        inc ecx
        jmp .add_loop

    .addition_done:
        ; Xử lý carry cuối cùng nếu có
        cmp dl, 1
        jne .finish
        mov ebx, [ebp + 8]        ; res
        mov byte [ebx + ecx], '1' ; Nếu có carry thì thêm '1' vào cuối chuỗi kết quả
        inc ecx

    .finish:
        mov ebx, [ebp + 8]      ; res
        mov byte [ebx + ecx], 0 ; Thêm null vào cuối chuỗi để in ra
        pop ecx                 ; Lấy lại độ dài max
        
        ; Đảo ngược res
        mov eax, [ebp + 8]      ; res
        call reverse

    pop edi
    pop esi

    pop edx
    pop ecx
    pop ebx
    pop eax

    mov esp, ebp
    pop ebp
    ret


reverse:
    ; Lưu trữ các thanh ghi này vào stack để tránh bị thay đổi khi thực hiện hoán đổi chuỗi.
    push edx
    push ecx
    push ebx
    push eax
   
    push eax
    mov ebx, eax
    call slen
    
    add ebx, eax 
    sub ebx, 1 
    pop eax
    
    .loop_swap:
        mov cl, [eax]
        mov dl, [ebx]
        mov [eax], dl
        mov [ebx], cl

        inc eax
        dec ebx
        cmp eax, ebx
        jl .loop_swap
        
        pop eax
        pop ebx
        pop ecx
        pop edx
    ret

exit:
    mov eax, 1
    mov ebx, 0
    int 0x80
    ret
