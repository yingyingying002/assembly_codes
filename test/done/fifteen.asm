assume cs:codesg,ds:datasg,ss:stack

datasg segment
    dw 0,0
    db "waiting for input!",0
datasg ends

stack segment
    db 256 dup(0)
stack ends

codesg segment
start:
    mov ax,datasg
    mov ds,ax
    mov ax,stack
    mov ss,ax
    mov sp,256
    ;安装新int 9中断到0000:0204h
    push ds
    mov ax,0
    mov es,ax
    mov di,204h
    mov ax,cs
    mov ds,ax
    mov si,offset mint_9
    mov cx,mint_9_end-mint_9
    cld
    rep movsb
    pop ds

    ;保存原int 9例程入口，并设置中断向量表为新int 9例程入口
    push es:[9*4]
    pop ds:[0]
    push es:[9*4+2]
    pop ds:[2]
    cli     ;设置IF=0，禁止响应中断
    mov word ptr es:[9*4],0204h
    mov word ptr es:[9*4+2],0
    sti     ;设置IF=1，允许响应中断

    ;等待输入
    mov dh,12
    mov dl,12
    mov cx,01110001b
    mov si,4
    call show_str
    call mdelay

    ;恢复原int 9中断向量
    cli
    mov ax,ds:[2]
    mov es:[9*4+2],ax
    mov ax,ds:[0]
    mov es:[9*4],ax
    sti

    mov ax,4c00h
    int 21h
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

;-----------int 9中断----------------
mint_9:
    push ax
    push es
    push cx
    push bx

    in al,60h
    cmp al,1Eh ;判断是否是按下"A"键
    jne mint_9_release_A
    ;按下A键
    mint_9_press_A:
        nop
        jmp mint_9_call_old

    ;松开A键
    mint_9_release_A:
        cmp al,9Eh ;判断是否是松开"A"键
        jne mint_9_call_old

        cli  ;设置IF为0，防止DOS系统其他中断修改显存
        mov ax,0b800h
        mov es,ax
        mov bx,0
        mov cx,2000
        mint_9_release_A_s: ;整页全部显示'A'
            mov byte ptr es:[bx],'A'
            add bx,2
            loop mint_9_release_A_s
        sti  ;
    ;没有相关逻辑
    mint_9_call_old:
        pushf
        call dword ptr ds:[0] ;调用原int 9例程

    pop bx
    pop cx
    pop es
    pop ax
    iret
mint_9_end:
    nop

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
codesg ends
end start