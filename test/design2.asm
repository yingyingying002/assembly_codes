; 编写计算机启动程序，并存入软盘a 0:7c00; -- 如何运行软盘中的代码？
; 涉及功能
;   1. 功能选项界面
;       1.1. 重新启动
;       1.2. 原系统启动，读取硬盘c 0:7c00
;       1.3. 进入时钟程序，时间自动刷新
;       1.4. 设置时间，更改当前的日期、时间
;   2. 功能按键
;       2.1. F1     改变显示颜色
;       2.2. Esc    返回功能选项界面

; 每次通过键盘缓冲区读取输入，比手动写一个m_int9应该短很多，不需要替换中断例程，也符合当前逻辑

assume cs:code,ds:data,ss:stack
; 程序将被加载到7C00H处，所有地址偏移都基于此计算
org 7c00h

data segment
    origin_addr dd 0,0,0    ; int16h
    input db 0              ; 键盘输入结果
    cur_display_flag db 0   ; 表示现在所处的显示界面 0:主选单 1:功能1 2:功能2
    color_list db  1, 00000111b, 00000010b, 00100100b, 01110001b        ; 显示界面的背景色列表，当前位置+黑底白字+黑底绿字+绿底红字+白底蓝字
    clock_input_buffer db 32 dup(0)     ;时钟输入缓冲区
    d1 db 'reset pc',0
    d2 db 'start system',0
    d3 db 'clock',0
    d4 db 'set clock',0
data ends

stack segment
    db 64 dup(0)
stack ends

code segment
start:
    mov ax,data
    mov ds,ax
    mov ax,stack
    mov ss,ax
    mov sp,64
    
    call preprocess
    mov cx,0
    always_loop:
        mov ax,0
        mov ah,[cur_display_flag]   ;获取当前显示状态
        call get_one_char           ;获取当前输入
        mov al,[input]
        ;如果是F1 -- todo
        cmp al,''
        je ready_to_process_F1
        ;如果是ESC,修改显示状态为选项界面 -- todo
        cmp al,''
        mov ah,0
        mov [cur_display_flag],0
        jmp ready_to_display
        ;其他输入在display函数自行处理
       
        ready_to_process_F1:    ;循环使用列表中的下一个颜色
            inc al
            cmp al,5
            je restart_color_list
            jmp ready_to_process_F1_end
            restart_color_list:
                mov al,1
            ready_to_process_F1_end:
                mov [int],al

        ready_to_display:
            call display ;
        inc cx   ; 保证死循环
        loop always_loop

    mov ax,4c00h
    int 21h

; 从键盘缓冲区读取一个字符，并存入input标签
get_one_char:

    ret

; 屏幕显示，若功能不同，则显示内容不同
; param:
;   (ah) = 当前显示状态
;   (al) = 若当前显示状态为0(主界面)，al为功能列表，al=0~4, al=0表示无输入
;          若当前显示状态为4(设置时间界面), al为输入的新时间界面
;          若当前显示状态为1~3(其他功能界面), al无效
display:
    ;若

    ;刷新显存全部内容的颜色，颜色按照color_list中的颜色和位置指定

    ret

code ends
end start