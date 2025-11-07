; 编写计算机启动程序，并存入软盘a的2、3、4扇区;
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

    ; 判断要显示那个界面
    cmp ah,1
    je case_1
    cmp ah,2
    je case_2
    cmp ah,3
    je case_3
    cmp ah,4
    je case_4

    ; 0.显示主界面
    default_case:
        call menu0_main_menu
        jmp display_end

    ; 1. 重新启动 -- todo：把1~4界面都先做成字符串显示，检查界面切换是否好用
    case_1:
        call menu1_reset_pc
        jmp display_end
    ; 2. 使用硬盘c的操作系统启动
    case_2:
        call menu2_start_system
        jmp display_end
    ; 3. 进入时钟程序
    case_3:
        call menu3_show_clock
        jmp display_end
    ; 4. 设置时间
    case_4:
        call menu4_set_clock
        jmp display_end

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
;   无
show_str:
    push ax
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
        pop si
        pop es
        pop ax
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

;param:
;   (ah) = 当前显示状态
;   (al) = al为功能列表，al=0~4, al=0表示无输入
menu0_main_menu:
    push ax
    push bx
    push cx
    push dx
    push si
    push di

    mov di,0                ;di-当前打印功能
    mov bh,0
    mov bl,color_list[0]    ;bx-当前打印字体颜色 
    mov cx,4
    mov dh,2
    mov dl,20

    default_case_loop:
        push cx
        mov cl,color_list[bx]
        mov si, option_list[di]
        call show_str
        add dh,2
        add di,2
        pop cx
        loop default_case_loop
    ; 根据输入，修改下次要显示的界面,即al=02h~05h(1~4的扫描码), 否则不修改
    check_memu_option_input:
        cmp al,05h
        ja check_memu_option_input_end
        cmp al,02h
        jb check_memu_option_input_end
        dec al
        mov [cur_display_flag], al
    check_memu_option_input_end:
        pop di
        pop si
        pop dx
        pop cx
        pop bx
        pop ax
    ret
menu1_reset_pc:
    reset_address dw 0,0ffffh
menu1_real_start:
    mov byte ptr [cur_display_flag], 1
    jmp far ptr [reset_address]
    ret

menu2_start_system:
    push ax
    push bx
    push cx
    push dx
    mov byte ptr [cur_display_flag], 2
    ;-- temp test
        mov bh,0
        mov bl,color_list[0]    ;bx-当前打印字体颜色 
        mov dh,12
        mov dl,12
        mov cl,color_list[bx]
        mov si, option_list[2]
        call show_str
    ; 1. 硬盘c的0道0面1扇区读入内存0:7c00h

    ; 2. 跳转到0:7c00h开始执行
    pop dx
    pop cx
    pop bx
    pop ax
    ret

menu3_show_clock:
    jmp short menu3_real_start
    t_positon db 9,8,7,6,2,0    ;年月日 时分秒对应的位置 
    t_char    db "// :: ",0     ;格式所需的分隔符
menu3_real_start:
    push ax
    push bx
    push cx
    push dx
    push si
    push di
    push es
    mov byte ptr [cur_display_flag], 3
    mov ax,0b800h
    mov es,ax

    ; 通过循环 读取时间信息
    mov cx,6
    mov si,offset t_positon     ;读取位置信息
    mov bx,offset t_char        ;读取分隔符信息
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

    pop es
    pop di
    pop si    
    pop dx
    pop cx
    pop bx
    pop ax
    ret
menu4_set_clock:
    menu4_msg1 db 'please input year: ',0
    menu4_msg2 db 'please input month: ',0
    menu4_msg3 db 'please input day: ',0
    menu4_msg4 db 'please input hour: ',0
    menu4_msg5 db 'please input minute: ',0
    menu4_msg6 db 'please input second: ',0
    menu4_change_success db 'change success',0
    menu4_change_fail db 'not change',0
    menu4_change_end db 'menu4 change end, type enter to exit',0
    menu4_msg_table dw offset menu4_msg1,offset menu4_msg2,offset menu4_msg3
                    dw offset menu4_msg4,offset menu4_msg5,offset menu4_msg6 
    menu4_buffer db 0fh,0fh     ;注意CMOS RAM中通过BCD码保存最多两位数字(两个0~9), 默认0fh表示无输入
                 db 0           ;
menu4_real_start:
    push ax
    push bx
    push cx
    push dx
    push si
    push di

    mov byte ptr [cur_display_flag], 4
    
    mov cx,6
    mov bh,0
    mov bl,color_list[0]    ;bx-当前打印字体颜色
    mov cl,color_list[bx]
    mov dh,0                ;dh-打印行
    mov dl,0                ;dl-打印列
    mov bx,0                ;bx-记录循环次数
    menu4_input_loop:
        ;1. 打印信息，提示当前修改内容
        mov si,menu4_msg_table[bx]
        call show_str
        inc dh
        ;2. 检查输入,若有则显示出来并存入buffer。若输入enter或已输入两个字符则输入结束
        mov si,offset menu4_buffer  ;si-指向输入缓冲区，准备打印
        mov di,0            ;di-记录当前写入buffer的位置
        menu4_check_input:
            call get_one_char
            cmp [input],0       ;无输入
            je menu4_check_loop_again
            cmp [input],1ch     ;enter键，强制完成检查
            je menu4_check_input_end
            cmp [input],02h     ;不在0~9的范围之内，注意`1~9`是02~0A,`0`是0B
            jb menu4_check_loop_again
            cmp [input],0bh
            jb menu4_check_loop_again
            ; 2.1. 扫描码转数字再写入缓存,便于显示
            mov al,[input]
            dec al
            cmp al,0ah
            jne menu4_scan_code_2_number_end
            mov al,0
            menu4_scan_code_2_number_end:
                mov menu4_buffer[di],al
                inc di
            ; 2.2. 显示已输入内容
            call show_str
            cmp di,2
            je menu4_check_input_end    ;已输入2位，且符合数字范围，完成检查
            menu4_check_loop_again:
                jmp menu4_check_input
        menu4_check_input_end:
            inc dh
        ;3. buffer中的数字转为BCD码写入端口
        ;3.1. 通过70h端口指定存放单元
        mov al,t_positon[bx]
        out 70h,al
        ;3.2. 转BCD码，并通过71h端口写入数值
        mov al,menu4_buffer[0]
        push cx
        mov cl,4
        shl al,cl
        pop cx
        or al,menu4_buffer[1]
        out 71h,al

        ;4. 打印是否修改成功的信息
        cmp di,0
        jne menu4_one_line_change_success
        mov si,offset menu4_change_fail
        jmp menu4_one_line_change_end
        menu4_one_line_change_success:
            mov si,offset menu4_change_success
        menu4_one_line_change_end:
            call show_str
            inc bx
            inc dh
        loop menu4_input_loop
    
    ;5. 打印修改完成提示，等待输入enter退出到主界面
    mov si,offset menu4_change_end
    call show_str
    menu4_wait_enter:
        call get_one_char
        cmp [input],1ch     ;enter键，强制完成检查
        je menu4_end
        jmp menu4_wait_enter

    menu4_end:
        mov byte ptr [cur_display_flag], 0
        pop di
        pop si
        pop dx
        pop cx
        pop bx
        pop ax
    ret
sector_boot_complete:
    db 1534-($ - offset start) dup(0) ; 填充剩余空间，确保程序总长达到1536字节
    dw 0aa55h           ; 引导扇区结束标志

code ends
end start