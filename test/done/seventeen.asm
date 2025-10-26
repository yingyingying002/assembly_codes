assume cs:code,ds:data,ss:stack
; 通过逻辑扇区号向硬盘写入

data segment
    disk_status db 0
    wmsg db 'try to write disk by logic section number!',0dh,0ah,'$',0
    rmsg db 'test'
         db 1024 dup(0)
    origin_addr dw 0,0  ; 存放原本的13h中断例程地址
    error_code db 'int 13h disk error  ? ',0
    dis  dw offset wmsg, offset rmsg, offset error_code
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

    ; 安装中断程序13h,地址 0000:0200h
    mov ax,0
    mov es,ax
    mov di,0200h
    push ds
    mov ax,cs
    mov ds,ax
    mov si,offset write_disk_by_logic_section
    mov cx,offset write_disk_by_logic_section_end - offset write_disk_by_logic_section
    cld
    rep movsb
    pop ds
    ; 设置中断向量表
    mov ax,es:[13h*4]
    mov origin_addr[0],ax
    mov ax,es:[13h*4+2]
    mov origin_addr[2],ax
    mov word ptr es:[13h*4],0200h
    mov word ptr es:[13h*4+2],0000h

    ; 读取硬盘扇区0的数据，并显示在屏幕
    mov ax,ds
    mov es,ax
    mov bx,dis[2]
    mov ax,0
    mov dx,0
    int 13h

    mov ah,[disk_status]
    cmp ah,0
    jne check_disk_error

    mov dh,12
    mov dl,12
    mov cl,01110001b
    mov si,bx
    call show_str

    ; 将wmsg写入硬盘扇区17
    mov bx,dis[0]
    mov ah,1
    mov dx,11h
    int 13h
    mov ah,[disk_status]
    cmp ah,0
    jne check_disk_error
    jmp normal_end

    check_disk_error:
        add ah,30h
        mov error_code[20],ah
        mov dh,5
        mov dl,1
        mov cl,01110001b
        mov si,dis[4]
        call show_str

    normal_end:
        mov ax,0
        mov es,ax
        ; 恢复原int 13h中断向量
        mov ax,origin_addr[2]
        mov es:[13h*4+2],ax
        mov ax,origin_addr[0]
        mov es:[13h*4],ax

    mov ax,4c00h
    int 21h

; 通过逻辑扇区号向硬盘写入,作为新的int 13h中断程序
; 计算公式 逻辑扇区号 = (面号*80+磁道号)*18+扇区号-1
; 参数:
;   ah - 功能号 0表示读，1表示写
;   dx - 读写的扇区逻辑号
;   es:bx - 读写的内存区首地址
; 返回值:

write_disk_by_logic_section:
    push ax
    push bx
    push cx
    push dx
    push ds
    ; 计算功能号
    cmp ah,0
    je set_ah_read_mode
    cmp ah,1
    jne all_end             ; ah其他功能号不处理，直接返回
    mov ah,3                ; ah=1匹配成功
    jmp ah_transform_end   
    set_ah_read_mode:       ; ah=0匹配成功
        mov ah,2

    ah_transform_end:
        push ax
        push bx
        ; 计算物理扇区号(16位除法，逻辑扇区号不超过2879)
        mov ax,dx
        mov bl,18
        div bl                  ; 余数为扇区号
        mov cl,ah
        inc cl                  ; 扇区号从1开始
        ; 计算磁道号+面号
        mov ah,0
        mov bl,80
        div bl                  ; 余数为磁道号，商为面号
        mov ch,ah               ; 磁道号
        mov dh,al               ; 面号(磁头号)
        ; 确定读写扇区数量+驱动器号
        pop bx
        pop ax
        mov al,1            ; 只写一个扇区
        mov dl,00h          ; 软驱A盘
        pushf
        call dword ptr [origin_addr] ;----------------------确定这里的入参是否正确
        mov [disk_status],ah    ;保存返回的状态码

    all_end:
        nop
    pop ds
    pop dx
    pop cx
    pop bx
    pop ax
    iret

write_disk_by_logic_section_end:
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