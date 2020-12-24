.386
data segment use16
t            db "0123456789ABCDEF"
bytesOnRow   db 1 dup(0);当前行字节数
rows         db 1 dup(0);当前页行数
rowsCur      db 1 dup(0);当前行号
xx           db 1 dup(0);8位数
line0        db "00000000:            |           |           |                             ";pattern
line         db "00000000:            |           |           |                             ";当前行的输出
preFile      db "Please input filename:", 0Dh, 0Ah, '$'
fileFailed   db "Cannot open file!", 0Dh, 0Ah, '$'
fileSuccess  db "Success!", 0Dh, 0Ah, '$'
fileName     db 100, 0, 100 dup(0)
buffer       db 256 dup(' ');当前页的内容
bufferCur    dw 1 dup(0);当前页内容对应行的偏移地址
fileSize     dw 2 dup(0)
offSetSet    dw 2 dup(0);页的偏移地址
offSetNew    dw 2 dup(0);行的偏移地址
n            dw 2 dup(0)
handle       dw 1 dup(0);文件句柄
bytesInBuf   dw 1 dup(0);buffer中的有效内容字节数
endLine      db 0Dh, 0Ah, '$';回车换行
data ends


code segment use16
assume cs:code, ds:data

;把8位数转化成16进制格式，在一行的进制转换中，bp类似全局变量
charToHex:
    mov dx, 0
    mov dl, xx
    push dx
    and dx, 0000Fh;取出低四位
    mov bx, dx
    mov dl, ds:[t+bx]
    mov ds:[line+bp+1], dl;低四位
    pop dx
    ror dx, 4;循环右移4位得到高四位
    and dx, 0000Fh;取出高四位
    mov bx, dx
    mov dl, ds:[t+bx]
    mov ds:[line+bp], dl;高四位
    ret

;把32位数转化成16进制格式
longToHex:
    mov bp, 0
    mov ax, ds:[offSetNew+2];存放高16位
    mov si, 2
again1:;高16位转16进制格式
    ror ax, 8
    mov xx, al
    call charToHex
    add bp, 2
    sub si, 1
    jnz again1
    mov ax, ds:[offSetNew+0];存放低16位
    mov si, 2
again2:;低16位转16进制格式
    ror ax, 8
    mov xx, al
    call charToHex
    add bp, 2
    sub si, 1
    jnz again2
    ret

;显示当前一行
showThisRow:
    mov si, 76
    mov di, 0
resetLine:;把line里面的值清空，变成模板样子
    mov al, ds:[line0+di]
    mov ds:[line+di], al
    add di, 1
    cmp di, si
    jnz resetLine
    call longToHex;地址转成16进制
    mov dx, 0
    mov dl, ds:[bytesOnRow]
    mov cx, dx;cx存放这一行的字节数
    mov ax, word ptr ds:[bufferCur];获得当前内容在buffer中的偏移地址
    mov di, ax;存放在di中
    mov si, 0
fill1:;存放内容的16进制表示
    mov dl, ds:[buffer+di]
    mov xx, dl
    mov ax, si
    mov bh, 3
    mul bh
    mov bp, ax;即char2hex(buf[i], s+10+i*3);
    add bp, 10;bp为偏移地址
    call charToHex
    add di, 1
    add si, 1
    cmp si, cx
    jnz fill1
    mov ax, word ptr ds:[bufferCur];获得当前内容在buffer中的偏移地址
    mov di, ax
    mov si, 0
fill2:;存放内容,把buffer中各个字节填入s右侧小数点处
    mov dl, ds:[buffer+di]
    mov ds:[line+59+si], dl
    add di, 1
    add si, 1
    cmp si, cx
    jnz fill2
    mov bx, 0
    mov dx, 0
    mov dl, ds:[rowsCur]
    cmp dx, 0
    je next3
addr:;计算row行偏移地址
    add bx, 160
    sub dx, 1
    jnz addr
next3:
    mov di, 0
    mov bp, 0
    mov si, 75
view:;显示
    mov al, ds:[line+bp]
    cmp di, 59
    jb next2
normal:;其它字符的前景色设为白色
    mov ah, 07h
    mov byte ptr es:[bx+di], al
    mov byte ptr es:[bx+di+1], ah
    sub si, 1
    jz done1
    add di, 2
    add bp, 1
    jmp view
next2:
    cmp al, '|'
    jz highlight
    jmp normal
highlight:;把竖线的前景色设为高亮度白色
    mov ah, 0Fh
    mov byte ptr es:[bx+di], al
    mov byte ptr es:[bx+di+1], ah
    sub si, 1
    jz done1
    add di, 2
    add bp, 1
    jmp view
done1:
    ret


;显示当前页
showThisPage:
    call clearThisPage
    mov ax, ds:[bytesInBuf]
    add ax, 15
    shr ax, 4;计算当前页的行数，rows = (bytes_in_buf + 15) / 16
    mov byte ptr ds:[rows], al;存放行数
    mov byte ptr ds:[rowsCur], 0;当前行数清零
loop1:;bytes_on_row = (i == rows-1) ? (bytes_in_buf - i*16) : 16;
    mov ax, 0
    mov al, byte ptr ds:[rowsCur];取出当前行数值，放入bx中
    mov bx, ax
    mov ax, 0
    mov al, byte ptr ds:[rows];取出当前页的行数
    sub ax, 1;相当于rows-1
    mov si, bx
    shl si, 4;相当于i*16
    mov word ptr ds:[bufferCur], si;计算出buffer偏移量
    cmp bx, ax;判断i==rows-1
    jne set16
    mov ax, ds:[bytesInBuf]
    sub ax, si
    mov byte ptr ds:[bytesOnRow], al;同C代码bytes_in_buf - i*16
next1:;show_this_row(i, offset+i*16, &buf[i*16], bytes_on_row)
    mov ax, ds:[offSetSet]
    add ax, si
    mov ds:[offSetNew], ax
    mov ax, ds:[offSetSet+2]
    adc ax, 0
    mov ds:[offSetNew+2], ax
    call showThisRow;显示这一行
    mov ax, 0
    mov al, byte ptr ds:[rows]
    mov bx, ax
    mov ax, 0
    mov al, byte ptr ds:[rowsCur]
    add ax, 1
    mov byte ptr ds:[rowsCur], al;当前行数加1
    cmp ax, bx
    je done2
    jmp loop1
set16:;设置当前行的字节数为16
    mov byte ptr ds:[bytesOnRow], 16
    jmp next1
done2:
    ret


;清除屏幕0~25行
clearThisPage:
    mov ax, 0B800h
    mov es, ax
    mov di, 0
    mov ax, 0020h
    mov si, 2000; 清屏共80*25次
clear:
    mov word ptr es:[di], ax
    add di, 2
    sub si, 1
    jnz clear
    ret


;主函数
main:
    mov ax, data
    mov ds, ax
    inputFileName:
    mov dx, offset ds:[preFile];输出"Please input filename:"
    mov ah, 09h
    int 21h
    mov dx, offset ds:[fileName];读入文件名,放在缓冲器中
    mov ah, 0Ah
    int 21h
    mov bx, 1
    mov dx, 0
    mov dl, ds:[fileName+bx];得到实际读入的文件名字节数
    mov bx, dx
    mov ds:[fileName+bx+2], 00h;将文件名最后一个字节改0Dh->00h
    mov dx, offset ds:[endLine];换行
    mov ah, 09h
    int 21h
openFile:
    mov ah, 3Dh;打开文件，返回句柄
    mov al, 0
    mov dx, offset ds:[fileName+2]
    int 21h
    mov ds:[handle], ax
    jc fileOpenFailed
    mov dx, offset ds:[fileSuccess]
    mov ah, 09h
    int 21h
getFileSize:
    mov ah, 42h
    mov al, 2;对应lseek()的第3个参数,表示以EOF为参照点进行移动
    mov bx, ds:[handle]
    mov cx, 0
    mov dx, 0
    int 21h
    mov word ptr ds:[fileSize+2], dx
    mov word ptr ds:[fileSize], ax
loop2:
    mov ax, ds:[fileSize]
    sub ax, ds:[offSetSet]
    mov ds:[n], ax
    mov ax, ds:[fileSize+2]
    sbb ax, ds:[offSetSet+2]
    mov ds:[n+2], ax;n=fileSize-offSet
    cmp ds:[n], 0100h;比较n是否大于256
    jae setBuf
    mov ax, ds:[n]
    mov word ptr ds:[bytesInBuf], ax
next:
    mov ah, 42h;移动文件指针
    mov al, 0
    mov bx, ds:[handle]
    mov cx, word ptr ds:[offSetSet+2]
    mov dx, word ptr ds:[offSetSet]
    int 21h
    mov ah, 3Fh;读取文件中byteInBuf个字节到buffer中
    mov bx, ds:[handle]
    mov cx, ds:[bytesInBuf]
    mov dx, offset ds:[buffer]
    int 21h
    call showThisPage
keyInput:;键盘输入
    mov ah, 0
    int 16h
    mov di, ax
    cmp di, 4900h
    je isPageUp
    cmp di, 5100h
    je isPageDown
    cmp di, 4700h
    je isHome
    cmp di, 4F00h
    je isEnd
    cmp di, 011Bh
    je isEsc
isPageUp:
    mov eax, 0
    mov ax, ds:[offSetSet+2]
    shl eax, 16
    mov ax, ds:[offSetSet]
    cmp eax, 256
    jb set0;offset小于256则设置为0，否则offset = offset - 256;
    sub eax, 256
    mov ds:[offSetSet], ax
    shr eax, 16
    mov ds:[offSetSet+2], ax 
    jmp loop2
set0:
    mov ds:[offSetSet], 0
    mov ds:[offSetSet+2], 0
    jmp loop2
isPageDown:
    mov eax, 0
    mov ax, ds:[offSetSet+2]
    shl eax, 16
    mov ax, ds:[offSetSet]
    add eax, 256
    mov edx, 0
    mov dx, ds:[fileSize+2]
    shl edx, 16
    mov dx, ds:[fileSize]
    cmp eax, edx;比较offset + 256与file_size
    jae returnLoop
    mov ds:[offSetSet], ax
    shr eax, 16
    mov ds:[offSetSet+2], ax
returnLoop:
    jmp loop2
isHome:
    mov ds:[offSetSet], 0
    mov ds:[offSetSet+2], 0
    jmp loop2
isEnd:
    mov edx, 0
    mov eax, 0
    mov dx, ds:[fileSize+2]
    mov ax, ds:[fileSize]
    mov bx, 0100h
    div bx;dx= file_size % 256
    mov eax, 0
    mov ax, ds:[fileSize+2]
    shl eax, 16
    mov ax, ds:[fileSize]
    mov ebx, eax;ebx存放fileSize
    sub eax, edx;eax存放offset
    cmp eax, ebx
    jne returnLoop2
    sub ebx, 256
    mov ds:[offSetSet], bx;offset = file_size - file_size % 256;
    shr ebx, 16
    mov ds:[offSetSet+2], bx
    jmp loop2
returnLoop2:;offset = file_size - 256;
    mov ds:[offSetSet], ax
    shr eax, 16
    mov ds:[offSetSet+2], ax
    jmp loop2
isEsc:;关闭文件
    mov ah, 3Eh
    mov bx, ds:[handle]
    int 21h
    jmp finishAll

setBuf:
    mov ds:[bytesInBuf], 0100h
    jmp next
fileOpenFailed:;文件打开失败，输出相应内容
    mov dx, data
    mov ds, dx
    mov dx, offset ds:[fileFailed] 
    mov ah, 09h
    int 21h
finishAll:
    mov ah, 1
    int 21h
    mov ah, 4Ch
    int 21h
code ends
end main