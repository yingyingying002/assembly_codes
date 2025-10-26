assume cs:code,ds:data,ss:stack

data segment
    str1 db "*****clear screen!",0
    str2 db "*****set foreground color!",0
    str3 db "*****set background color!",0
    str4 db "*****scroll up one line!",0
    table dw sub1,sub2,sub3,sub4
data ends

stack segment
    db 256 dup(0)
stack ends

code segment
start:
    mov ax,data
    mov ds,ax
    mov ax,stack
    mov ss,ax
    mov sp,256
    
    funcStart:
        mov si,0
        mov ax,0
        mov bx,0
        mov cx,4
        mov dh,12
        mov dl,0
        funcStart_1s:
            ;显示即将执行的步骤
            push cx
            mov cx,01110001b
            call show_str
            add si,ax
            pop cx
            call mdelay
            ;执行步骤
            call word ptr [table+bx]
            add bx,2
            call mdelay
            loop funcStart_1s
    mov ax,4c00h
    int 21h

;清屏
sub1:
    push bx
    push cx
    push es

    mov bx,0b800h
    mov es,bx
    mov bx,0
    mov cx,2000
    sub1s:
        mov byte ptr es:[bx],' '
        add bx,2
        loop sub1s
    pop es
    pop cx
    pop bx
    ret
;设置前景色
sub2:
    push bx
    push cx
    push es

    mov bx,0b800h
    mov es,bx
    mov bx,1
    mov cx,2000
    sub2s:
        and byte ptr es:[bx],11111000b
        or byte ptr es:[bx],al
        add bx,2
        loop sub2s
    pop es
    pop cx
    pop bx
    ret
;设置背景色
sub3:
    push bx
    push cx
    push es

    mov bx,0b800h
    mov es,bx
    mov bx,1
    mov cx,2000
    sub3s:
        and byte ptr es:[bx],10001111b
        or byte ptr es:[bx],al
        add bx,2
        loop sub3s
    pop es
    pop cx
    pop bx
    ret
;屏幕上滚动一行
sub4:
    push cx
    push si
    push di
    push es
    push ds

    mov si,0b800h
    mov ds,si
    mov es,si
    mov si,160
    mov di,0
    cld
    mov cx,24
    sub4s:
        push cx
        mov cx,160
        rep movsb
        pop cx
        loop sub4s
    ;清除最后一行
    mov cx,80
    mov si,0
    sub4s1:
        mov byte ptr [160*24+si],' '
        mov byte ptr [160*24+si+1],07h
        add si,2
        loop sub4s1
    pop ds
    pop es
    pop di
    pop si
    pop cx
    ret
;-----------延时-----------------
mdelay:
    push ax
    push dx

    mov ax,0
    mov dx,0010h
    mdelay_s:
        sub ax,1
        sbb dx,0
        cmp ax,0
        jne mdelay_s
        cmp dx,0
        jne mdelay_s

    pop dx
    pop ax
    ret
;---------------------------------------
; 在指定的位置，用指定的颜色，显示一个用0结束的字符串
; param:
;   (dh): 行号(0-24)
;   (dl): 列号(0-79)
;   (cl): 颜色
;   (ds:si): 指向字符串首地址
; return:
;   (ax): 打印的字符串长度(含末尾0)
show_str:
    push es
    push si
    push bx
    push di
    push cx

    mov bl,cl
    mov di,0
    ; 显示缓冲区段地址
    mov ax,0B800h
    mov es,ax
    ; 起始行-偏移地址-添加到段地址中
    mov cx,0
    mov cl,dh
    mov ax,es
    show_str_s:
        add ax,000ah
        loop show_str_s
    mov es,ax
    ; 起始列-偏移地址-添加到di寄存器
    mov ax,0
    mov al,dl
    add al,al ;列偏移*2，因为每一列两个字符
    add di,ax

    ; 显示字符串
    show_str_s1:
        mov cx,0
        mov cl,[si]
        inc si
        jcxz show_str_end
        mov es:[di],cl
        mov es:[di+1],bl
        add di,2
        jmp show_str_s1
    
    show_str_end:
        pop cx
        pop di
        pop bx
        mov ax,si
        pop si
        sub ax,si   ;通过前后两次si的差值，计算打印的字符串长度
        pop es
        ret
;---------------------------------------
code ends
end start