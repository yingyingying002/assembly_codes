;将design2.bin写入软盘a作为系统启动进程
assume cs:code,ds:data,ss:stack

data segment
    buffer db 1536 dup(0)    ;三个扇区大小
    cur_file dw 0       ;当前要处理的文件
    boot_file_name db 'c:\BOOT.BIN',0,'$'
    design2_file_name db 'c:\DESIGN2.BIN',0,'$'
    start_sector db 0
    sector_number db 0

    msg1 db 'file open failed, ','$'
    msg2 db 'file read failed, ','$'
    msg3 db 'check fisk failed, ','$'
    msg4 db 'write fisk failed, ','$'
    msg5 db 'write success!',0Dh,0Ah,'$'    ;0dh,0ah是换行
    msg6 db 'start process file ','$'
    err_code db 'err code:0000',0Dh,0Ah,'$'

    table dw offset buffer, offset boot_file_name, offset design2_file_name
    msg_table dw offset msg1, offset msg2, offset msg3
              dw offset msg4, offset msg5, offset msg6, offset err_code

data ends

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
    ;读取文件boot.bin，写入扇区1
    mov ax, table[2]
    mov [cur_file],ax
    mov byte ptr [start_sector],1
    mov byte ptr [sector_number],1
    call upload_2_floppy_disk

    ;读取文件design2.bin，写入扇区2~4
    mov ax, table[4]
    mov [cur_file], ax
    mov byte ptr [start_sector],2
    mov byte ptr [sector_number],3
    call upload_2_floppy_disk

    mov ax,4c00h
    int 21h

;读取cur_file内容到buffer，然后存入软盘0
;param:
;   无，所需信息都在数据段
;return:
;   无，但是会在屏幕打印相关信息
upload_2_floppy_disk:
    push ax
    push bx
    push cx
    push dx
    ; 打印当前信息
    mov dx,msg_table[10]
    mov ah,09h
    int 21h
    mov dx,[cur_file]
    mov ah,09h
    int 21h

    ;读取文件内容，存入buffer
    ;1. 打开文件, 打开成功则ax中保存文件句柄
    mov ah,3dh
    mov al,0
    mov dx,[cur_file]
    int 21h
    jc file_open_failed
    ;2. 读取文件
    mov bx,ax
    ;2.1 计算需要读取的长度
    mov ax,512
    mov cx,0
    mov cl,[sector_number]
    mul cx      ;不计入dx的值，默认长度不超过ax可表达的最大长度
    mov cx,ax
    ;2.2 开始读取
    mov ah,3fh
    mov dx,table[0]
    int 21h
    jc file_read_failed
    ;3. 关闭文件
    mov ah,3eh
    int 21h


    ;buffer中的数据，存入软盘a -- Dosbox debug时无法写入软盘
    ;1. 开始写入软盘
    mov ax,ds
    mov es,ax
    mov ah,03h
    mov al,[sector_number]
    mov ch,0
    mov cl,[start_sector]
    mov dh,0
    mov dl,0
    mov bx,table[0]
    int 13h
    jc write_disk_failed
    ;2. 检查软盘操作是否成功 -- 执行后al非0，但是实际没问题
    mov ah, 01h  ; 获取上次磁盘操作信息
    mov dl, 00h  ; 驱动器号：0代表软盘A
    int 13h
    cmp al,0
    jne check_disk_failed
    jmp write_disk_success

    file_open_failed:
        call error_code_to_ascii
        mov dx,msg_table[0]
        mov ah,09h
        int 21h
        jmp cur_end
    file_read_failed:
        call error_code_to_ascii
        mov dx,msg_table[2]
        mov ah,09h
        int 21h
        jmp cur_end
    check_disk_failed:
        call error_code_to_ascii
        mov dx,msg_table[4]
        mov ah,09h
        int 21h
        jmp cur_end
    write_disk_failed:
        call error_code_to_ascii
        mov dx,msg_table[6]
        mov ah,09h
        int 21h
        jmp cur_end

    write_disk_success:
        mov dx,msg_table[8]
        mov ah,09h
        int 21h
    cur_end:
        mov dx,msg_table[12]    ;打印错误码，若成功执行，则为0000
        mov ah,09h
        int 21h

    pop dx
    pop cx
    pop bx
    pop ax
    ret

;将错误码转为ascii形式
;param:
;   ax = error_code.(ffaa,0102,0A00等)
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
    mov di,3
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
        dec di
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