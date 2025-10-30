#《汇编语言》第三版(王爽著)的各个实验代码

课程设计2：
1. 编写系统启动代码，并以下列代码结尾
```
    times 510-($-$$) db 0 ; 填充剩余空间，确保程序总长达到510字节
    dw 0xAA55           ; 引导扇区结束标志(占2个字节)
```
2. 将系统启动代码通过masm编译为.bin文件
```
masm test.asm
link test.obj
exe2bin test.exe test.bin
```
3. 编写代码，将.bin文件写入软盘0面0磁道1扇区
4. 配置dosbox从软盘启动
```
boot -l A
```