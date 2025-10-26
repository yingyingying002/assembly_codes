assume cs:code

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
data ends

table segment
    db 21 dup ('year summ ne ?? ')
table ends

code segment
start:
    ; 代码开始
    mov ax,data
    mov ds,ax

    mov di,0
    mov dx,0
    mov si,0
    mov bx,00E0h
    mov cx,21
s:
    ; 年份
    mov ax,[di]
    mov [bx],ax
    mov ax,[di+2]
    mov [bx+2],ax
    ; 总收入
    mov ax,[di+84]
    mov [bx+5],ax
    mov ax,[di+86]
    mov [bx+7],ax
    ; 雇员人数
    mov ax,[si+168]
    mov [bx+10],ax
    ; 人均收入
    mov ax,[bx+5]
    mov dx,[bx+7]
    div word ptr [bx+10]
    mov [bx+13],ax
    ; 空格
    mov al,20h
    mov byte ptr [bx+4],20h
    mov byte ptr [bx+9],20h
    mov byte ptr [bx+12],20h
    mov byte ptr [bx+15],20h

    add bx,10h
    add di,4h
    add si,2h
    loop s

    ; 代码结束
    mov ax,4c00h
    int 21h
code ends
end start