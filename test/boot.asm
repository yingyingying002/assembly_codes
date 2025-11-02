; 引导扇区代码
; 功能：将2~3扇区的系统引导代码放入内存0x7E00处，并执行
assume cs:code
org 7C00h  ; 告知编译器程序将被加载到 0x7C00 处[4](@ref)

code segment
start:
    jmp real_start
    next_address dw 0000,7E00h
    dirve_num db 0
real_start:
    ; 初始化段寄存器
    mov ax, cs
    mov ds, ax
    mov es, ax

    ; 引导阶段，BIOS通常会将启动设备的驱动器号放入 DL寄存器
    mov [dirve_num],dl

    ; 设置读取主程序的功能参数
    mov ax, 07E0h   ; 设置目标内存地址 ES:BX 为 0x7E0:0x0000 (即物理地址 0x7E00)
    mov es, ax
    mov bx, 0

    mov ah, 02h    ; 功能号：读扇区
    mov al, 2       ; 要读取的扇区数（根据主程序大小调整）
    mov ch, 0        ; 柱面/磁道号：0
    mov cl, 2        ; 起始扇区号：2（主程序从第2扇区开始）
    mov dh, 0        ; 磁头号：0
    mov dl, [dirve_num]        ; 驱动器号：0 (软驱A)
    int 13h         ; 调用BIOS磁盘中断

    jc disk_error   ; 如果出错（进位标志CF=1）则跳转到错误处理

    ; 成功读取后，跳转到主程序(0x7E00)执行
    call dword ptr [next_address]

disk_error:
    jmp short disk_error_start
    error_msg db "read disk error!",'0'
    
    disk_error_start:
    mov si, offset error_msg
    call show_str

    ; 填充引导扇区剩余空间，并设置有效结束标志
    db 510-($ - offset start) dup(0) ; 填充剩余空间，确保程序总长达到510字节
    dw 0aa55h           ; 引导扇区结束标志

;---------------------------------------
; 显示一个用0结束的字符串
; param:
;   (ds:si): 指向字符串首地址
; return:
;   无
show_str:
    push es
    push si
    push di
    push cx

    ; 显示缓冲区段地址
    mov ax,0B800h
    mov es,ax
    mov di,0
    ; 显示字符串
    show_str_s1:
        mov cx,0
        mov cl,[si]
        inc si
        jcxz show_str_end
        mov es:[di],cl
        add di,2
        jmp show_str_s1

    pop cx
    pop di
    pop si
    pop es
    ret

code ends
end start