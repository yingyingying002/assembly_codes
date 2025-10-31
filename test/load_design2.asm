;将design2.bin写入软盘a作为系统启动进程
assume cs:code,ds:data,ss:stack

data segment
    buffer db 512 dup(0)    ;单个扇区大小
    file_name db 'c:\DESIGN2.BIN',0
    msg1 db 'file open failed, ','$'
    msg2 db 'file read failed, ','$'
    msg3 db 'check fisk failed, ','$'
    msg4 db 'write fisk failed, ','$'
    msg5 db 'write success!','$'
    err_code db 'err code:0000','$'
    table dw offset buffer, offset file_name, offset msg1, offset msg2
          dw offset msg3, offset msg4, offset msg5, offset err_code
data ends

;-- 研究多扇区启动的方案，并写入软盘

stack segment
    db 1024 dup(0)
stack ends

code segment
start:
    mov ax,data
    mov ds,ax
    mov ax,stack
    mov ss,ax
    mov sp,1024

    ;读取文件design2.bin，存入buffer
    ;http://bbc.nvg.org/doc/Master%20512%20Technical%20Guide/m512techb_int21.htm
    ;1. 打开文件
    mov ah,3dh
    mov al,0
    mov dx,table[2]
    int 21h
    jc file_open_failed
    ;2. 读取文件
    mov bx,ax
    mov ah,3fh
    mov cx,512
    mov dx,table[0]
    int 21h
    jc file_read_failed
    cmp ax,512
    jb file_read_failed
    ;3. 关闭文件
    mov ah,3eh
    int 21h


    ;buffer中的数据，存入软盘a -- debug模式下检查写入失败，返回FF6A
    ;1. 开始写入软盘
    mov ax,ds
    mov es,ax
    mov ah,03h
    mov al,1
    mov ch,0
    mov cl,1
    mov dh,0
    mov dl,0
    mov bx,table[0]
    int 13h
    jc write_disk_failed
    ;2. 读取软盘操作是否成功
    mov ah, 01h  ; 获取上次磁盘操作信息
    mov dl, 00h  ; 驱动器号：0代表软盘A
    int 13h
    cmp al,0
    jne check_disk_failed
    jmp write_disk_success

    file_open_failed:
        call error_code_to_ascii
        mov dx,table[4]
        mov ah,09h
        int 21h
        jmp cur_end
    file_read_failed:
        call error_code_to_ascii
        mov dx,table[6]
        mov ah,09h
        int 21h
        jmp cur_end
    check_disk_failed:
        call error_code_to_ascii
        mov dx,table[8]
        mov ah,09h
        int 21h
        jmp cur_end
    write_disk_failed:
        call error_code_to_ascii
        mov dx,table[10]
        mov ah,09h
        int 21h
        jmp cur_end

    write_disk_success:
        mov dx,table[12]
        mov ah,09h
        int 21h
    cur_end:
        mov dx,table[14]    ;打印错误码，若成功执行，则为0000
        mov ah,09h
        int 21h
    mov ax,4c00h
    int 21h

;将错误码转为ascii形式
;param:
;   ax = error_code.(ff,01,0A等)
;return:
;   无，修改ds:error_code字段为ax的ascii码形式
error_code_to_ascii:
    push ax
    push bx
    push cx
    push dx
    push di

    mov dx,0
    mov bx,16
    mov cx,4
    mov di,0
    code_to_ascii_loop:
        div bx
        cmp dx,10
        jnb process_character
        add dx,30h  ;按数字处理
        jmp process_end
        process_character:  ;按字母a~f处理
            add dx,57h
        process_end:    ;处理之后的数据为单个ascii码，ah肯定为0
            mov err_code[di+9],dl
        inc di
        mov dx,0
        loop code_to_ascii_loop

    pop di
    pop dx
    pop cx
    pop bx
    pop ax
    ret
code ends
end start