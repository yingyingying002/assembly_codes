; 编写计算机启动程序，并存入软盘a的2、3扇区;
; 涉及功能
;   1. 功能选项界面
;       1.1. 重新启动
;       1.2. 原系统启动，从硬盘c启动
;       1.3. 进入时钟程序，时间自动刷新
;       1.4. 设置时间，更改当前的日期、时间
;   2. 功能按键
;       2.1. F1     改变显示颜色
;       2.2. Esc    返回功能选项界面

assume cs:code,ds:code
; 程序将被加载到7E00H处，所有地址偏移都基于此计算
; org 7E00h ;手动修改段地址达到org 7E00h的效果

code segment
start:
    jmp real_start
    ; 数据段放到代码段里，方便计算总长度
    input db 0              ; 键盘输入结果(扫描码)
    cur_display_flag db 0   ; 表示现在所处的显示界面 0:主选单 1:功能1 2:功能2
    color_list db 1, 00000111b, 00000010b, 00100100b, 01110001b        ; 显示界面的背景色列表，当前位置+黑底白字+黑底绿字+绿底红字+白底蓝字
    d1 db '1.reset pc','\n',0
    d2 db '2.start system','\n',0
    d3 db '3.clock','\n',0
    d4 db '4.set clock','\n',0
    option_list dw offset d1, offset d2, offset d3, offset d4
    ;栈段
    stack db 128 dup(0)
real_start:
    mov ax,cs
    add ax,07e0h
    mov ds,ax
    mov ss,ax
    mov sp,offset stack+128
    always_loop:
        mov ax,0    ; ah-当前显示状态,al-当前输入
        mov ah,[cur_display_flag]   ;获取当前显示状态
        call get_one_char           ;获取当前输入
        mov al,[input]
        ;1.如果是F1(扫描码)
        cmp al,3bh
        je ready_to_process_F1
        ;2.如果是ESC,修改显示状态为选项界面
        cmp al,01h
        je ready_to_process_ESC
        ;3.属于其他按键，或者没有按键输入，display函数自行处理
        jmp ready_to_display
       
        ready_to_process_F1:    ;循环使用列表中的下一个颜色
            push ax
            mov al, color_list[0]
            inc al
            cmp al,5
            je restart_color_list
            jmp ready_to_process_F1_end
            restart_color_list:
                mov al,1
            ready_to_process_F1_end:
                mov color_list[0],al
            pop ax
            jmp ready_to_display
        ready_to_process_ESC:
                mov ah,0
                mov [cur_display_flag],0

        ready_to_display:
            call display ;
        call mdelay
        jmp always_loop ; 保证死循环--todo

    ;mov ax,4c00h
    ;int 21h
    call sector_boot_complete


; 从键盘缓冲区读取一个字符，并将扫描码存入input标签
get_one_char:
    push ax
    ;ah=1检查键盘缓冲区
    mov ah,01h
    int 16h
    jz no_input

    ;缓冲区有数据，ah=0读取缓冲区
    mov ah,0h
    int 16h
    mov [input],ah
    jmp get_one_char_end

    no_input:
        mov [input],0
    get_one_char_end:
        pop ax
    ret

; 屏幕显示，若功能不同，则显示内容不同
; param:
;   (ah) = 当前显示状态
;   (al) = 若当前显示状态为0(主界面)，al为功能列表，al=0~4, al=0表示无输入
;          若当前显示状态为4(设置时间界面), al为输入的新时间界面
;          若当前显示状态为1~3(其他功能界面), al无效
display:
    push ax
    push bx
    push cx
    push dx
    push si
    push di
    push es
    ; 界面清空，全都设置为空格
    cli  ;设置IF为0，防止DOS系统其他中断修改显存
    mov bx,0b800h
    mov es,bx
    mov bx,0
    mov cx,2000 ; 25行 * 80列
    display_clear: ;整页全部显示' '
        mov byte ptr es:[bx],' '
        add bx,2
        loop display_clear
    sti

    ; 0.显示主界面
    case_0:
        mov di,0                ;di-当前打印功能
        mov bh,0
        mov bl,color_list[0]    ;bx-当前打印字体颜色 
        mov cx,4
        mov dh,2
        mov dl,20

        case_0_loop:
            push cx
            mov cl,color_list[bx]
            mov si, option_list[di]
            call show_str
            add dh,2
            add di,2
            pop cx
            loop case_0_loop
        jmp display_end
    ;刷新显存全部内容的颜色，颜色按照color_list中的颜色和位置指定

    display_end:
    pop es
    pop di
    pop si
    pop dx
    pop cx
    pop bx
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

;-----------延时------------------------
mdelay:
    push ax
    push dx

    mov ax,0
    mov dx,0001h    ;微调了一下，循环2^16次，大概0.1s。不然单次Delay时间太长
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
sector_boot_complete:
    db 1022-($ - offset start) dup(0) ; 填充剩余空间，确保程序总长达到510字节
    dw 0aa55h           ; 引导扇区结束标志

code ends
end start