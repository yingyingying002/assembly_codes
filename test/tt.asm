assume cs:code,ds:data,ss:stack
; 通过逻辑扇区号向硬盘写入

data segment
    wmsg db 'try to write disk by logic section number!',0dh,0ah,'$',0
    rmsg db 'test'
         db 1024 dup(0)
    origin_addr dw 0,0  ; 存放原本的13h中断例程地址
    show_str_addr dw 0,0  ; 存放show_str函数的地址
    error_code db 'int 13h disk error  ? ',0dh,0ah,'$',0
    dis  dw offset wmsg, offset rmsg, offset error_code
data ends

stack segment
    db 100h dup(0)
stack ends

code segment
start:
    mov ax,data
    mov ds,ax
    mov ax,stack
    mov ss,ax
    mov sp,100h
    mov ax,0
    mov es,ax
    mov ax,es:[13h*4]
    mov origin_addr[0],ax
    mov ax,es:[13h*4+2]
    mov origin_addr[2],ax

    ; 保存show_str函数的地址
    ;mov ax,seg show_str
    ;mov show_str_addr[2],ax
    ;mov ax,offset show_str
    ;mov show_str_addr[0],ax

    ;---------------------------------这里能正常读取硬盘
    mov ah, 02h        ; 功能号 02h：读扇区
    mov al, 1          ; 读取1个扇区
    mov ch, 0          ; 柱面号/磁道号 = 0
    mov cl, 1          ; 扇区号 = 1（从1开始）
    mov dh, 0          ; 磁头号 = 0
    mov dl, 00h        ; 驱动器号：00h = 软盘 A
    mov bx, ds          ; 缓冲区偏移地址（ES:BX）
    mov es, bx         ; 设置 ES=0（简单缓冲区）
    mov bx, dis[2]
    ;int 13h ;可以执行

    mov ah, 02h
    pushf
    call dword ptr origin_addr[0]   ;不能执行
    ;---------------------------------

    ; 安装中断程序13h,地址 0000:0200h
    mov ax,0
    mov es,ax
    mov di,0200h
    mov si,offset write_disk_by_logic_section
    mov cx,offset write_disk_by_logic_section_end - offset write_disk_by_logic_section
    cld
    rep movsb
    ; 设置中断向量表
    mov ax,es:[13h*4]
    mov origin_addr[0],ax
    mov ax,es:[13h*4+2]
    mov origin_addr[2],ax
    mov word ptr es:[13h*4],0200h
    mov word ptr es:[13h*4+2],0000h

    ;---------------
    ; 读取硬盘扇区0的数据
    mov ax,ds
    mov es,ax
    mov bx,dis[2]
    mov ax,0
    mov dx,0
    ;int 13h
    

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
;   ah - 错误类型
write_disk_by_logic_section:
    push bx
    push cx
    push dx
    ;----------------------------------------------
    mov ah, 02h        ; 功能号 02h：读扇区
    mov al, 1          ; 读取1个扇区
    mov ch, 0          ; 柱面号/磁道号 = 0
    mov cl, 1          ; 扇区号 = 1（从1开始）
    mov dh, 0          ; 磁头号 = 0
    mov dl, 00h        ; 驱动器号：00h = 软盘 A
    mov bx, ds          ; 缓冲区偏移地址（ES:BX）
    mov es, bx         ; 设置 ES=0（简单缓冲区）
    mov bx, dis[2]
    pushf
    call dword ptr [origin_addr]
    ;--------------------------------------------------

    pop dx
    pop cx
    pop bx
    iret
write_disk_by_logic_section_end:
    nop

code ends
end start