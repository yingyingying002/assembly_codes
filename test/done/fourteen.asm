assume cs:codesg,ss:stack

data segment
    db 9,8,7,4,2,0      ;年月日 时分秒对应的位置 
    db "// :: ",0       ;格式所需的分隔符
data ends

stack segment
    db 128 dup(0)
stack ends

codesg segment
start:
    mov ax,data
    mov ds,ax
    mov ax,stack
    mov ss,ax
    mov sp,128
    mov ax,0b800h
    mov es,ax


    mov cx,6
    mov si,0    ;读取位置信息
    mov bx,6    ;读取分隔符信息
    mov di,0
    s:
        push cx
        ;读取ROM中的时间信息
        mov al,ds:[si]
        out 70h,al
        in al,71h
        ;BCD码转换为ASCII码
        mov cl,4
        mov ah,al
        shr ah,cl
        and al,0fh
        add ah,30h
        add al,30h
        ;显示两个ASCII码
        mov es:[di+160*12],ah
        mov byte ptr es:[di+160*12+1],2
        mov es:[di+160*12+2],al
        mov byte ptr es:[di+160*12+3],2
        ;显示分隔符
        mov al,ds:[bx+si]
        mov es:[di+160*12+4],al
        mov byte ptr es:[di+160*12+5],2
        ;更新信息
        add di,6
        inc si
        pop cx
        loop s

    mov ax,4c00h
    int 21h
codesg ends
end start