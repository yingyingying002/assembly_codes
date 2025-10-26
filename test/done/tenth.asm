assume cs:code,ds:data,ss:stack

data segment
    db 'congratutions! you win!',0
data ends

stack segment
    db  96 dup(0)
stack ends

code segment
start:
    mov ax,stack
    mov ss,ax
    mov sp,96
    mov ax,data
    mov ds,ax

    ; 显示字符串
    ;mov dh,1
    ;mov dl,2
    ;mov cl,11110001b
    ;mov si,0
    ;call show_str

    ; 除法计算 10^6 / 10
    ;mov ax,4240H
    ;mov dx,000FH
    ;mov cx,000ah
    ;call divdw
    ; 结果: (dx) = 0001H, (ax) = 86A0H, (cx) = 0000H

    ; 将结果转换为十进制字符串，然后打印出来
    mov ax,317ah    ;数字12666
    mov si,0
    call dtoc
    mov dh,8
    mov dl,3
    mov cl,11110001b
    call show_str

    mov ax,4C00h
    int 21h

;---------------------------------------
; 在指定的位置，用指定的颜色，显示一个用0结束的字符串
; param:
;   (dh): 行号(0-24)
;   (dl): 列号(0-79)
;   (cl): 颜色
;   (ds:si): 指向字符串首地址
; return:
;   无
show_str:
    push bx
    push es
    push ax
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
        jcxz show_str_end
        mov es:[di],cl
        mov es:[di+1],bl
        inc si
        add di,2
        jmp show_str_s1
    
    show_str_end:
        pop cx
        pop di
        pop si
        pop ax
        pop es
        pop bx
        ret
;---------------------------------------


;---------------------------------------
;进行不溢出的除法，被除数dword型,除数word型，结果为dword型
;实质是将一次除法转换为两次除法,REM为取余
; X/N = int(XH/N)*65536 + [REM(XH/N)*65535 + XL]/N
;param:
;  (ax): 被除数低16位
;  (dx): 被除数高16位
;  (cx): 除数
;return:
;  (ax): 商低16位
;  (dx): 商高16位
;  (cx): 余数
divdw:
    push bx

    ; 先计算XH/cx,得到最终结果高16位
    push ax
    mov ax,dx
    mov dx,0
    div cx
    mov bx,ax      ; bx=int(XH/cx)
    ; 计算REM(XH/cx)*65536 + XL，此时dx恰好=REM(XH/cx)。得到最终结果低16位和最终余数
    pop ax
    div cx
    ; 保存最终结果
    mov cx,dx
    mov dx,bx

    pop bx
    ret
;---------------------------------------


;---------------------------------------
;将一个word型数转换为十进制,字符串以0结尾
;param:
;  (ax): word型数
;  (ds:si): 存放转换结果的首地址
dtoc:
    push bx
    push cx
    push dx
    push si
    push di

    ; 考虑到8位除法使用al保存商，可能导致溢出，这里使用dx:ax的16位除法
    mov dx,0
    mov bx,10
    mov di,0    ;暂时用于存储结果的位数
    dtoc_s:
        div bx
        ; 除数10，余数必然只用到了dl
        add dl,30h
        push dx ;保存结果，通过栈保证逆序
        inc di
        ; 检查商是否为0(是否已经除完)
        mov cx,ax
        jcxz dtoc_end
        mov dx,0
        jmp dtoc_s

    dtoc_end:
        mov cx,di ;di=结果的位数
        dtoc_s1:
            pop dx
            mov [si],dl
            inc si
            loop dtoc_s1
        mov byte ptr [si],0 ;字符串结束标志
    ;恢复数据
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    ret
;---------------------------------------
code ends
end start