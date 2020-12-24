.386
data segment use16
buffer db 7, 0, 7 dup(0); 输入字符串缓冲器
S1 db 6 dup(' '); S1存放第一个数字
S2 db 6 dup(' '); S2存放第二个数字
D db 15 dup(' '), 0Dh, 0Ah, '$'; 十进制结果
H db 10 dup(' '), 0Dh, 0Ah, '$'; 十六进制结果
B db 40 dup(' '), 0Dh, 0Ah, '$'; 二进制结果
endline db 0Dh, 0Ah, '$'; 回车换行
data ends

code segment use16
assume cs:code, ds:data

; 实现一个数字串的输入
input_a_string:
    mov ah, 0Ah
    lea dx, buffer
    int 21h
    mov bx, 1
    mov dx, 0
    mov dl, buffer[bx]; 得到输入的实际字符数
    mov bx, dx
    mov buffer[bx+2], '$';最后一个0Dh改为‘$’, 便于后续处理
    ret

; 实现数字的存储，便于后续显示
store_the_string:
    mov di, 2
    mov si, 0
    mov dx, 0
    sub bp, 1;bp类似于全局变量，初始值为1，当存入第一个字符串时，跳转至函数store_in_S1，完成后bp值为2
    jz store_in_S1
store_in_S2:
    mov dl, buffer[di]
    cmp dl, '$'
    jz store_in_S2_done; 读到'$'时存储完成
    mov S2[si], dl
    add di, 1
    add si, 1
    jmp store_in_S2
store_in_S1:
    mov dl, buffer[di]
    cmp dl, '$'
    jz store_in_S1_done
    mov S1[si], dl
    add di, 1
    add si, 1
    jmp store_in_S1
store_in_S1_done:
    mov S1[si], '$'; 存入最后一个字符
    mov bp, 2
    jmp store_done
store_in_S2_done:
    mov S2[si], '$'
    jmp store_done
store_done:
    ret


; 字符串输入及字符转换成数字
input_a_number:
    call input_a_string; 输入字符
    call store_the_string; 存储字符
    mov bx, 2; 实际字符串是从buffer偏移2个地址的地方开始的，[buffer+2] 
    mov ax, 0
convert_again:
    mov cx, 0
    mov cl, buffer[bx]
    cmp cl, '$'
    je input_a_number_done
    mov si, 10
    mul si; 乘法结果存放在AX中
    sub cl, '0'
    add ax, cx
    inc bx
    jmp convert_again
input_a_number_done:
    ret

; 仅用于显示字符串运算
output:
    push eax; 保护eax的值
    mov ah, 09h; 输出第一个字符串S1
    lea dx, S1
    int 21h
    mov dl, '*'
    mov ah, 02h
    int 21h
    mov ah, 09h; 输出第二个字符串S1
    lea dx, S2
    int 21h
    mov dl, '='
    mov ah, 02h
    int 21h
    call endNow; 换行
    pop eax; 恢复eax
    ret


; 输出十进制结果，用div 10 取余实现
output_D:
    push eax; eax中存放乘法结果，push使其不被破环
    mov cx, 0; cx计算push次数
    mov dl, 0
    mov di, 0; di为数组下标
push_again_D:
    mov edx, 0
    mov ebx, 10
    div ebx; 每次除10
    add dl, '0'
    push dx
    inc cx
    cmp eax, 0
    jne push_again_D
pop_again_D:
    pop dx
    mov D[di], dl
    inc di
    dec cx
    jnz pop_again_D
output_D_done:
    mov ah, 9
    mov dx, offset D
    int 21h
    pop eax; 还原eax，以便后续使用
    ret

; 输出十六进制结果，位运算实现
output_H:
    mov ebx, eax;保存EAX的值到EBX中
    mov si, 8; 总共循环8次
    mov di, 0; 目标数组的下标
again_H:
    rol eax, 4; 循环左移4位
    push eax; 保护EAX
    and eax, 0Fh; 与运算
    cmp al, 10
    jb is_digit
is_alpha:
    sub al, 10
    add al, 'A'
    jmp finish_4bits
is_digit:
    add al, '0'
finish_4bits:
    mov H[di], al
    pop eax
    add di, 1
    sub si, 1
    jnz again_H
output_H_done:
    mov H[di], 'h'
    mov ah, 9
    mov dx, offset H
    int 21h
    mov eax, ebx
    ret


; 输出二进制结果，用位运算实现
output_B:
    mov si, 32; 总共循环左移32次
    mov di, 0; 目标数组的下标
    mov cx, 4; CX等于0时存入一个空格
again_B:
    rol eax, 1; 循环左移1位
    push eax; 保护EAX
    and eax, 01h; 与运算
    add al, '0'
    mov B[di], al
    pop eax
    add di, 1
    sub cx, 1
    jz reset; CX复位  
    sub si, 1
    jnz again_B
    jmp output_B_done; 完成
reset:
    sub si, 1;循环结束时不需要输出空格，直接输出‘B’
    jz output_B_done
    mov B[di], 20h; 否则输出空格
    add di, 1; 继续循环
    mov cx, 4; CX复位
    jmp again_B
output_B_done:
    mov B[di], 'B'
    mov ah, 9
    mov dx, offset B
    int 21h
    ret

;仅换行使用
endNow:
    mov ah, 09h
    mov dx, offset endline
    int 21h
    ret

main:
    mov ax, data
    mov ds, ax
    mov bp, 1
    call input_a_number;输入第一个数字
    and eax, 0FFFFh; 使EAX高16位为0
    push eax; 保存第一个数字
    call endNow; 调用换行函数
    call input_a_number;输入第二个数字
    mov ebx, eax; EBX存放第二个数字
    and ebx, 0FFFFh
    pop eax; 恢复第一个数字
    mul ebx; 两数相乘
    push eax
    call endNow
    pop eax
    call output; 输出显示
    call output_D; 输出十进制结果
    call output_H; 输出十六进制结果
    call output_B; 输出二进制结果
    mov ah, 4Ch
    int 21h

code ends
end main