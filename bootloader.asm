; ___       ___  ___       ________  ___  __    ________  ________           ________  ________  ________  _________  ___       ________  ________  ________  _______   ________     
;|\  \     |\  \|\  \     |\   __  \|\  \|\  \ |\   __  \|\   ____\         |\   __  \|\   __  \|\   __  \|\___   ___\\  \     |\   __  \|\   __  \|\   ___ \|\  ___ \ |\   __  \    
;\ \  \    \ \  \ \  \    \ \  \|\  \ \  \/  /|\ \  \|\  \ \  \___|_        \ \  \|\ /\ \  \|\  \ \  \|\  \|___ \  \_\ \  \    \ \  \|\  \ \  \|\  \ \  \_|\ \ \   __/|\ \  \|\  \   
; \ \  \    \ \  \ \  \    \ \   __  \ \   ___  \ \  \\\  \ \_____  \        \ \   __  \ \  \\\  \ \  \\\  \   \ \  \ \ \  \    \ \  \\\  \ \   __  \ \  \ \\ \ \  \_|/_\ \   _  _\  
;  \ \  \____\ \  \ \  \____\ \  \ \  \ \  \\ \  \ \  \\\  \|____|\  \        \ \  \|\  \ \  \\\  \ \  \\\  \   \ \  \ \ \  \____\ \  \\\  \ \  \ \  \ \  \_\\ \ \  \_|\ \ \  \\  \| 
;   \ \_______\ \__\ \_______\ \__\ \__\ \__\\ \__\ \_______\____\_\  \        \ \_______\ \_______\ \_______\   \ \__\ \ \_______\ \_______\ \__\ \__\ \_______\ \_______\ \__\\ _\ 
;    \|_______|\|__|\|_______|\|__|\|__|\|__| \|__|\|_______|\_________\        \|_______|\|_______|\|_______|    \|__|  \|_______|\|_______|\|__|\|__|\|_______|\|_______|\|__|\|__|
;                                                           \|_________|                                                                                                             
; 
; Copyright © 2018, Jacob Smith
; See LICENSE.MD for licensing info
;

[BITS 16]
[ORG 0x7C00]

jmp main

main:
    cli
    mov ax, 0x7C00
    mov gs, ax
    mov fs, ax

    xor ax, ax
    mov es, ax
    mov ss, ax
    mov sp, 0x9C00
    
    sti
    
    mov [HDDDriveNumber], dl

    mov si, WelcomeMessage
    call print

    call readindex

    jmp $

readindex:
    mov ax, 0x00
    mov ds, ax
    mov ah, 0x42
    mov dl, 0x80
    mov si, IndexDAP
    
    int 0x13
    
    mov ax, 0x500
    mov si, ax
    findstartloop:
        lodsb
        cmp al, 0x02
        je foundstart
        jmp findstartloop
    cli
    hlt
    jmp $

foundstart:
    mov ax, si
    add ax, 0x3F
    mov si, ax
    isfile?:
        lodsb
        cmp al, 0x12
        je .foundfile
        jmp foundstart
        .foundfile:
            mov ax, si
            add ax, 0x21
            mov si, ax
            mov di, Filename
            mov cx, 17
            rep cmpsb
            je .success
            jmp .faileure
            cli
            hlt
            jmp $
        .faileure:
            mov ax, si
            add ax, cx
            add ax, 0xE
            mov si, ax
            jmp .foundfile
            jmp $
        .success:
            push si
            mov si, successmsg
            call print
            pop si
            jmp .cpstuff
            .cpstuff:
                mov ax, si
                sub ax, 0x29
                mov si, ax
                mov bx, Location
                mov di, bx
                mov cx, 0x07
                rep movsb
                inc si
                mov bx, tempLocal
                mov di, bx
                mov cx, 0x07
                rep movsb
                
                mov si, Location
                lodsw

                mov bx, ax

                mov si, tempLocal
                lodsw

                sub ax, bx

                mov [size], ax

                jmp .readfile
            .readfile:
                mov ax, 0x00
                mov ds, ax
                mov ah, 0x42
                mov dl, 0x80
                mov si, FileDAP
                
                int 0x13

                jmp .executefile

            .executefile:
                jmp 0x1000
                cli
                hlt
                jmp $

print:
    lodsb
    or al, al
    jz exit
    mov ah, 0xE
    int 0x10
    jmp print

waitfkb:
    xor ax, ax
    int 0x16
    ret


exit:
    ret

IndexDAP:
    db 0x10
    db 0
    dw 1
    dd 0x500
    dq 0x1FFFFF

FileDAP:
    db 0x10
    db 0x00
    size: dw 0x00
    dd 0x1000
    Location: dq 0x0


HDDDriveNumber db 0x80
WelcomeMessage db "LilakOS Hard Drive Image for Bochs(x86)", 0x0A, 0x0D, 0x0
Filename db "/boot/stage2.LEF", 0x00
Filesize db 17
successmsg db "Success!", 0x0
failmsg db 0x0A, 0x0D, 0x0A, 0x0D, "Catastrophic Faileure!!!",0x0A, 0x0D, 0x0A, 0x0D, 0x00
tempLocal: dq 0x0000
times 510-($-$$) db 0x00
db 0x55
db 0xAA

;This is the first time in a while I have
;felt genuinly happy about finishing a
;project, because this was actually hard!
