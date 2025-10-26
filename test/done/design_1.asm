assume cs:code, ds:data, ss:stack

data segment
    db '1975','1976','1977','1978','1979','1980','1981','1982','1983'
    db '1984','1985','1986','1987','1988','1989','1990','1991','1992'
    db '1993','1994','1995'
    ; 21年，总长度 4*1B*21=84B 实际占用84B(54h)
    dd 16,22,382,1356,2390,8000,16000,24486,50065,97479,140417,197514
    dd 345980,590827,803530,1183000,1843000,2759000,3753000,4649000,5937000
    ; 每年总收入, 总长度 4B*21=84B 实际占用84B(54h)
    dw 3,7,9,13,28,38,130,220,476,778,1001,1442,2258,2793,4037,5635,8226
    dw 11542,14430,15257,17800
    ; 雇员人数, 总长度 2B*21=42B 实际占用42B(2Ah)
    dw 1024 dup(0)
    ; 占位
data ends

table segment
    db 21 dup ('year summ ne ?? ')
table ends

stack segment
    db  96 dup(0)
stack ends

code segment
start:
    mov ax,data
    mov ds,ax
    mov ax,table
    mov es,ax
    mov ax,stack
    mov ss,ax
    mov sp,96

    ; 预处理数据，格式化存储到table段
    call preprocess
    ; table中的数字转为10进制,覆盖data段中的内容
    call process
    ; 逐行打印
    mov cx,21
    mov dl,10
    mov dh,1
    mov si,0
    s:
        push cx
        mov cx,01110001b
        mov ax,0
        call show_str
        add si,ax
        inc dh
        pop cx
        loop s

    mov ax,4c00h
    int 21h

;--------------------------------------------------------------------
; 处理data中的数据，将其格式化存储到table段
; table每行长度为16B
; 年份4B + \t1B + 收入4B + \t1B + 雇员人数2B + \t1B + 人均收入2B + 空格1B = 16B
preprocess:
    push ax
    push bx
    push cx
    push dx
    push si
    push di

    mov si,0    ;data段偏移 -- 年份、收入
    mov bx,0    ;data段偏移 -- 雇员人数
    mov di,0    ;table段偏移 -- 行首
    mov cx,21   ;21年数据
    preprocess_s:
        ;年份 -- si+0为起点，data下一个数据在4B后
        mov ax,[si]
        mov es:[di],ax
        mov ax,[si+2]
        mov es:[di+2],ax
        ;总收入 -- si+84为起点，data下一个数据在4B后
        mov ax,[si+84]
        mov es:[di+5],ax
        mov ax,[si+86]
        mov es:[di+7],ax
        ;雇员人数 -- bx+168为起点, data下一个数据在2B后
        mov ax,[bx+168]
        mov es:[di+10],ax
        ;人均收入
        mov ax,es:[di+5]
        mov dx,es:[di+7]
        div word ptr es:[di+10]
        mov es:[di+13],ax
        ; \t与空格
        mov byte ptr es:[di+4],20h
        mov byte ptr es:[di+9],20h
        mov byte ptr es:[di+12],20h
        mov byte ptr es:[di+15],20h

        add si,4    ;下一个年份、总收入
        add bx,2    ;下一个雇员人数
        add di,16   ;table下一行
        loop preprocess_s
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret
;--------------------------------------------------------------------

;---------------------------------------
;模拟\t功能添加空格，实现列对齐
;param:
;   (bl): 当前列数
;   (ds:di): 写入空格的首地址
;return:
;   无。但是会根据添加的空格同步修改bx和di
fill_blank:
    push ax
    push cx
    push dx

    mov dx,bx
    mov ax,0
    mov al,dl
    mov dl,8
    div dl
    ;添加的空格数 = (8 - 余数)
    mov cx,0
    sub dl,ah
    mov cl,dl
    ;add cl,8
    fill_blank_s:
        mov byte ptr [di],20h
        inc di
        inc bx
        loop fill_blank_s

    pop dx
    pop cx  
    pop ax
    ret
;---------------------------------------

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

;--------------------------------------------------------------------
; 将table段中的数字转为10进制，覆盖data段中的内容
; 年份字符串 + \t + 收入字符串 + \t + 雇员人数字符串 + \t + 人均收入字符串 + \t 
process:
    push ax
    push bx
    push cx
    push dx
    push si
    push di

    mov si,0    ;table段偏移
    mov di,0    ;data段偏移
    mov cx,21   ;21年数据
    process_s:
        mov bx,0    ;记录数字列数，用于计算需要补充的空格数，以模拟\t效果
        ;年份字符串+\t -- 直接读
        push cx
        mov cx,5
        process_s_year:
            mov al,es:[si]
            mov [di],al
            inc si
            inc di
            inc bx
            loop process_s_year
        pop cx
        ;模拟\t效果
        call fill_blank

        ;收入字符串+\t -- 转10进制
        mov ax,es:[si]
        mov dx,es:[si+2]
        call dtoc32
        add di,ax
        add si,5
        ;模拟\t效果
        add bx,ax
        call fill_blank

        ; 雇员人数字符串+\t -- 转10进制
        mov ax,es:[si]
        call dtoc
        add di,ax
        add si,3
        ;模拟\t效果
        add bx,ax
        call fill_blank
        ; 人均收入字符串+空格 -- 转10进制
        mov ax,es:[si]
        call dtoc
        add di,ax
        add si,3
        ;模拟\t效果
        add bx,ax
        call fill_blank
        ; 增加一个0，作为本行结尾
        mov byte ptr [di],0
        inc di
        loop process_s
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret
;--------------------------------------------------------------------

;--------------------------------------------------------------------
; 转十进制数，32bit
; param:
;  (dx:ax): dword型数据
;  (ds:di): 存放转换结果的首地址
;return:
;  (ax): 转换结果长度
dtoc32:
    push bx
    push cx
    push dx
    push si
    push di

    ; 考虑到16位除法使用ax保存商，可能导致溢出，这里使用不溢出的16位除法
    mov si,0
    dtoc32_s:
        mov cx,10
        call divdw
        add cx,30h  ;转为ascii十进制数字
        push cx
        inc si      ;记录位数
        ;检查商是否为0
        mov cx,ax
        or cx,dx
        jcxz dtoc32_end
        jmp dtoc32_s
    dtoc32_end:
        mov cx,si
        dtoc32_s1:
            pop dx
            mov [di],dl
            inc di
            loop dtoc32_s1
        mov ax,si   ;返回值--转换结果长度
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    ret
;--------------------------------------------------------------------

;---------------------------------------
;将一个word型数转换为十进制,字符串以0结尾
;param:
;  (ax): word型数
;  (ds:di): 存放转换结果的首地址
;return:
;  (ax): 转换结果长度
dtoc:
    push bx
    push cx
    push dx
    push si
    push di

    ; 考虑到8位除法使用al保存商，可能导致溢出，这里使用dx:ax的16位除法
    mov dx,0
    mov bx,10
    mov si,0    ;暂时用于存储结果的位数
    dtoc_s:
        div bx
        ; 除数10，余数必然只用到了dl
        add dl,30h
        push dx ;保存结果，通过栈保证逆序
        inc si
        ; 检查商是否为0(是否已经除完)
        mov cx,ax
        jcxz dtoc_end
        mov dx,0
        jmp dtoc_s

    dtoc_end:
        mov cx,si ;si=结果的位数
        dtoc_s1:
            pop dx
            mov [di],dl
            inc di
            loop dtoc_s1
        mov ax,si
    ;恢复数据
    pop di
    pop si
    pop dx
    pop cx
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
code ends
end start