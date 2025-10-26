assume cs:code,ds:data,ss:stack

data segment
    msg db 'welcome to masm! inno.',0
data ends

stack segment
    db 512 dup(0)
stack ends

code segment
start:
    mov ax,data
    mov ds,ax
    mov ax,stack
    mov ss,ax
    mov sp,512
    mov ax,0
    mov es,ax

    push ds
    mov ax,cs
    mov ds,ax
    ; 安装中断程序7c,地址 0000:0200h
    mov si,offset int_showstr
    mov di,0200h
    mov cx,offset int_showstr_end - offset int_showstr
    cld
    rep movsb

    ; 安装中断程序7d,地址 0000:1000h
    mov si,offset int_mloop
    mov di,1000h
    mov cx,offset int_mloop_end - offset int_mloop
    cld
    rep movsb
    pop ds

    ; 注册中断向量表
    mov word ptr es:[7ch*4],0200h
    mov word ptr es:[7ch*4+2],0000h
    mov word ptr es:[7dh*4],1000h
    mov word ptr es:[7dh*4+2],0000h

    ; 实验13-1 显示字符串
    mov dh,10
    mov dl,10
    mov cl,2
    mov si,0
    ;call int_showstr
    int 7ch

    ; 实验13-2 模拟loop指令 在屏幕中间显示80个'!'
    mov ax,0b800h
    mov es,ax
    mov di,12*160
    mov bx,offset s - offset se
    mov cx,80
    s:
        mov byte ptr es:[di],'!'
        add di,2
        int 7dh
    se:
        nop

    mov ax,4c00h
    int 21h

;中断例程--7c  显示一个用0结束的字符串
;param:
;  dh   - 显示行号
;  dl   - 显示列号
;  cl   - 字符颜色
;  ds:si - 指向字符串
int_showstr:
    push ax
    push dx
    push si
    push di
    push es

    mov ax,0b800h
    mov es,ax
    mov ax,0
    mov al,dh
    mov dl,160
    mul dl
    add al,dl
    add al,dl
    mov di,ax

    int_showstr_s:
        mov al,[si]
        cmp al,0
        je int_showstr_s_end
        mov es:[di],al
        mov es:[di+1],cl
        inc si
        add di,2
        jmp int_showstr_s
    int_showstr_s_end:
        nop
    pop es
    pop di
    pop si
    pop ax
    pop dx
    iret
int_showstr_end:
    nop

;中断例程--7d  模拟loop指令
;param:
;  cx   - 循环次数
;  bx   - 跳转指令的位移
int_mloop:
    push bp
    mov bp,sp
    dec cx
    jcxz no_modify_reg_ip
    add ss:[bp+2],bx

    no_modify_reg_ip:
        nop
    pop bp
    iret
int_mloop_end:
    nop

code ends
end start