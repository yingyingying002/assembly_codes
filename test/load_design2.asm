;将design2.bin写入软盘a作为系统启动进程
assume cs:code,ds:data,ss:stack

data segment
    buffer db 512 dup(0)    ;单个扇区大小
    file_name db 'c:\DESIGN2.BIN',0
    msg1 db 'file open failed, err code:?.','$'
    msg2 db 'file read failed, err return:?.','$'
    msg3 db 'reset fisk failed, err code:?','$'
    msg4 db 'write fisk failed, err code:?','$'
    msg5 db 'write success!','$'
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

    ;读取文件design2.bin，存入buffer
    ;http://bbc.nvg.org/doc/Master%20512%20Technical%20Guide/m512techb_int21.htm
    ;1. 打开文件
    mov ah,3dh
    mov al,0
    mov dx,offset file_name
    int 21h
    jc file_open_failed
    ;2. 读取文件
    mov bx,ax
    mov ah,3fh
    mov cx,512
    mov dx,offset buffer
    int 21h
    cmp ax,512
    jb file_read_failed
    ;3. 关闭文件
    mov ah,3eh
    int 21h

    ;buffer中的数据，存入软盘a -- debug模式下检查写入失败，返回FF6A
    ;1. 复位软盘，准备写入
    mov ah, 00h  ; 功能号00h：复位磁盘驱动器
    mov dl, 00h  ; 驱动器号：0代表软盘A
    int 13h
    jc reset_disk_failed
    ;2. 开始写入软盘
    mov ah,03h
    mov al,1
    mov ch,0
    mov cl,1
    mov dh,0
    mov dl,00h
    mov ax,ds
    mov es,ax
    mov bx,offset buffer
    int 13h
    jc write_disk_failed
    jmp write_disk_success

    file_open_failed:
        add al,30h
        mov msg1[27],al
        mov dx,offset msg1
        mov ah,09h
        int 21h
        jmp cur_end
    file_read_failed:
        add al,30h
        mov msg2[29],al
        mov dx,offset msg2
        mov ah,09h
        int 21h
        jmp cur_end
    reset_disk_failed:
        add ah,30h
        mov msg3[28],ah
        mov dx,offset msg3
        mov ah,09h
        int 21h
        jmp cur_end
    write_disk_failed:
        add ah,30h
        mov msg4[28],ah
        mov dx,offset msg4
        mov ah,09h
        int 21h
        jmp cur_end

    write_disk_success:
        mov dx,offset msg5
        mov ah,09h
        int 21h
    cur_end:
        nop
    mov ax,4c00h
    int 21h

code ends
end start