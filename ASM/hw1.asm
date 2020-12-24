data segment
s db 100 dup(0)
t db 100 dup(0)
a db 0Dh, 0Ah, "$" ;回车换行用
data ends

code segment
assume cs:code, ds:data
main:
	mov ax, data
	mov ds, ax
	mov bx, 0
	mov SI, 0
	mov DI, 0
	mov ah, 1
	int 21h ;输入第一个字符
	cmp al, 0Dh ;判断第一个字符是否为回车
	je last ;last实现把回车转换为00h
	mov s[bx], al ;第一个字符不是回车就放入数组S
input:;循环输入字符
	add bx, 1
	mov ah, 1
	int 21h
	cmp al, 0Dh ;判断当前输入字符是否为回车
	je last
	mov s[bx], al ; 当前字符不是回车就放入数组S
	jne input
last:
	mov s[bx], 00h ;存入回车
	mov dx, 0
	mov ah, 9
	mov dx, offset a
	int 21h ; 全部输入完成后回车换行
transfer:;实现字符转换
	mov dl, s[SI]
	add SI, 1
	cmp dl, 00h ;判断当前字符是否为回车
	je preoutput ;preoutput实现存入00h以及DI=0，输出前准备
	cmp dl, 20h ;判断是否为空格
	je transfer
	cmp dl, "a"
	jae islower
notlower:
	mov t[DI], dl ;不是空格和小写字母的原样存入数组
	add DI, 1
	jmp transfer ;回到循环
islower:
	cmp dl, "z"
	ja notlower
	sub dl, 32 ;是小写字母则ASCII-32, 变成大写字母
	mov t[DI], dl ;是小写字母则存入数组t
	add DI, 1
	jmp transfer ;回到transfer函数，继续循环
preoutput:
	mov t[DI], 00h
	mov DI, 0
output:
	mov dl, t[DI]
	cmp dl, 00h
	je exit
	mov ah, 2
	int 21h
	add DI, 1
	jmp output
exit:
	mov dx, 0
	mov ah, 9
	mov dx, offset a
	int 21h ;输出回车
	mov ah, 4Ch		
	int 21h 	
code ends
end main