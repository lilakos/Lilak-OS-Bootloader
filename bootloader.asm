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
    xor ax, ax
    mov ds, ax
    mov ss, ax

    mov sp, 0x9C00

    cld
    sti

    mov si, msg
    call print

    mov si, IndexDAP
    mov ah, 0x42
    mov dl, 0x80

    int 0x13

    mov si, 0x500

    loop1:
        lodsb
        cmp al, 0x02
        je loop2
        jmp loop1
    loop2:
        lodsb
        cmp al, 0x12
        je foundfile
        jmp loop2
    foundfile:
        lodsb
        mov [content], al

        cmp al, 0x1
        jne loop2

        add si, 0x20

        mov di, FileName

        mov cx, [FileNameSize]

        rep cmpsb
        je success
        jmp foundfileerr
    success:
        push si
        mov si, smsg
        call print
        xor si, si
        pop si
        sub si, 0x3D
        lodsw
        mov [FileLocation], ax
        
        add si, 0x06
        lodsw

        mov [FileLimit], ax

        mov bx, [FileLocation]

        sub bx, ax

        mov [FileSize], ax

        mov si, FileDAP
        xor ax, ax
        mov ah, 0x42
        mov dl, 0x80

        int 0x13

        jmp 0x1000

        jmp $
    foundfileerr:
        add si, cx
        push si
        mov si, fmsg
        call print
        xor si, si
        pop si
        jmp loop2
        jmp $
    jmp $

print:
    lodsb
    or al, al
    jz .done
    mov ah, 0xE
    int 0x10
    jmp print
.done:
    ret

IndexDAP:
    db 0x10
    db 0x00
    dw 0x01
    dw 0x0500
    dw 0x0000
    dq 0x003FFFFF

FileDAP:
    db 0x10
    db 0x00
    FileSize dw 0x03
    dw 0x1000
    dw 0x0000
    FileLocation dq 0x00

content db 0x00
smsg db 'Success', 0x0A, 0x0D, 0x00
fmsg db 'Faileure', 0x0A, 0x0D, 0x00
msg db 'Hello, World!', 0x0A, 0x0D, 0x00
FileName db "/LilakOS/Bootstuff/stage2/stage2.LBF", 0x00
FileNameSize dw 0x25
FileLimit dw 0x00
times 510-($-$$) db 0x00
db 0x55
db 0xAA
