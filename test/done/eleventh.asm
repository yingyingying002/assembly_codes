assume cs:code, ds:datasg, ss:stack

datasg segment
    db "Beginner's All-purpose Symbolic Instruction Code",0
datasg ends

stack segment
    db  96 dup(0)
stack ends

code segment
start:
    mov ax,datasg
    mov ds,ax
    mov es,ax
    mov ax,stack
    mov ss,ax
    mov sp,96

    mov si,0
    mov di,0
    call letterc

    mov dh,3
    mov dl,5
    mov cx,01110001b
    call show_str

    mov ax,4c00h
    int 21h

;--------------------------------------------------------------------
; 将字符串的小写字母转大写，要求字符串以0结尾
;param:
; ds:si -- 字符串起始地址
letterc:
    push si
    push ax
    push cx
    mov cx,0
    letterc_s:
        mov al,[si]
        cmp al,'a'
        jb other_char
        cmp al,'z'
        ja other_char
        sub al,20h
        mov [si],al
        other_char:
            nop
        mov cl,al
        jcxz letterc_end
        inc si
        jmp letterc_s
    letterc_end:
    pop cx
    pop ax
    pop si
    ret
;--------------------------------------------------------------------

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
    push bx
    push es
    push si
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
        mov ax,si
        pop si
        sub ax,si   ;通过前后两次si的差值，计算打印的字符串长度
        pop es
        pop bx
        ret
;---------------------------------------
code ends
end start