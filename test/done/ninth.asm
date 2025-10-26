assume cs:code,ds:data,ss:stack

data segment
    ;welcome to masm 绿色
    db  77h,00000010b,65h,00000010b,6ch,00000010b,63h,00000010b
    db  6fh,00000010b,6dh,00000010b,65h,00000010b,20h,00000010b
    db  74h,00000010b,6fh,00000010b,20h,00000010b,6dh,00000010b
    db  61h,00000010b,73h,00000010b,6dh,00000010b,20h,00000010b
    ;welcome to masm 绿底红色
    db  77h,00100100b,65h,00100100b,6ch,00100100b,63h,00100100b
    db  6fh,00100100b,6dh,00100100b,65h,00100100b,20h,00100100b
    db  74h,00100100b,6fh,00100100b,20h,00100100b,6dh,00100100b
    db  61h,00100100b,73h,00100100b,6dh,00100100b,20h,00100100b
    ;welcome to masm 白底蓝色+闪烁
    db  77h,11110001b,65h,11110001b,6ch,11110001b,63h,11110001b
    db  6fh,11110001b,6dh,11110001b,65h,11110001b,20h,11110001b
    db  74h,11110001b,6fh,11110001b,20h,11110001b,6dh,11110001b
    db  61h,11110001b,73h,11110001b,6dh,11110001b,20h,11110001b
data ends

stack segment
    db  16 dup(0)
stack ends

code segment
start:
    ; 设置显示模式为文本模式 80*25
    mov ax, 0003H
    int 10H

    mov ax,data
    mov ds,ax

    mov ax,stack
    mov ss,ax
    mov sp,16

    mov ax,0B800h
    mov es,ax

    mov si,0
    mov di,0
    mov cx,3

s:
    push cx
    mov cx,16
    mov di,0
    s1:
        mov ax,[si]
        mov es:[di],ax
        add si,2
        add di,2
        loop s1
    ; 指向显示缓冲区的下一行
    mov ax,es
    add ax,000ah
    mov es,ax
    ; 继续循环
    pop cx
    loop s

    mov ax,4c00h
    int 21h
code ends
end start