code segment
assume cs:code
main:
   mov ax, 0B800h
   mov ds, ax
   mov di, 0
   mov ax, 0020h; 清屏操作
   mov si, 2000; 共2000次
clear:
   mov word ptr ds:[di], ax
   add di, 2
   sub si, 1
   jnz clear
real_start:
   mov di, 0
   mov bp, 256; bp用来计数，256个ASCII字符
   mov si, 25; 每一列最多25个
   mov al, 0; 第一个ASCII字符
   mov ah, 0Ch; 黑底红字
again:
   mov byte ptr ds:[di], al
   mov byte ptr ds:[di+1], ah
   mov dx, ax; dx保存ax现存字符ASCII码，因为ax存放的东西之后会改变
   add di, 2
   mov bx, 2; bx用来计数循环左移的次数，共2次
rol_bit:
   mov cl, 4
   rol al, cl; al循环左移4次
   push ax
   and ax, 0Fh; 和0000 1111与
   cmp al, 10
   jb is_digit
is_alpha:
   sub al, 10
   add al, 'A'; 现在的al存放循环左移与操作后的16进制数
   jmp finish_4bits
is_digit:
   add al, '0'
finish_4bits:
   mov byte ptr ds:[di], al; 输出第一个16进制字符
   mov byte ptr ds:[di+1], 0Ah; 黑底绿字
   pop ax
   add di, 2
   sub bx, 1
   jnz rol_bit
finish_rol_bit:
   sub bp, 1; 计数减一
   jz finish_all
   mov ax, dx; 恢复ax存放的值
   add al, 1; ASCII码偏移一位，得到新的ASCII字符
   sub si, 1; 一列中还可以继续输出的字符减一，为0则去新的一列
   jz new_column
position:
   sub di, 6; di偏移了6个字节，现在要回去
   add di, 160; 去下一列
   jmp again
new_column:
   sub di, 6
   mov si, 24; si表示要退回的行数
reset:
   sub di, 160
   sub si, 1
   jnz reset;循环往前退
   add di, 14; 去新的一列的开始
   mov si, 25;恢复si的计数功能
   jmp again
finish_all:
   mov ah, 1
   int 21h; 
   mov ah, 4Ch
   int 21h
code ends
end main