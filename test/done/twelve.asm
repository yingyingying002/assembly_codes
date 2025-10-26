assume cs:codesg, ss:stack

stack segment
    db  256 dup(0)
stack ends

codesg segment
start:
    mov ax,cs
    mov ds,ax
    mov ax,stack
    mov ss,ax
    mov sp,256

    ;处理函数代码写入系统空间
    mov ax,0
    mov es,ax
    mov di,0200h    ;保存中断0处理函数地址 0000:0200h
    mov si,offset do0
    mov cx,offset do0end - offset do0
    add si,2        ;跳过开头的jmp指令
    sub cx,2
    cld
    rep movsb

    ;处理函数地址写入中断类型表
    mov word ptr es:[0*4],0200h
    mov word ptr es:[0*4+2],0000h
    ;错误处理测试
    mov ax,1000h
    mov bh,1
    div bh  ;除法溢出错误

    mov ax,4c00h
    int 21h

do0:
    jmp short do0start ;长度为2
    db "divide error!"
do0start:
    ;push ax

    mov ax,0b800h
    mov es,ax
    mov di,12*160+36*2  ;第13行第37列

    mov ax,cs
    mov ds,ax
    mov si,200h    ;注意代码已存入 0000:0200h
    mov cx,13
    do0_s:
        mov al,[si]
        mov es:[di],al
        ;mov es:[di+1],0fh
        inc si
        add di,2
        loop do0_s

    mov ax,4c00h
    int 21h
do0end:
    nop


codesg ends
end start