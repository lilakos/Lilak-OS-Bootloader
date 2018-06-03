;
; Stage 2
; Copyright © 2018, Jacob Smith
; See LICENSE.MD for licensing info
;

[BITS 16]
[ORG 0x1000]

jmp main

main:
    cli
    mov ds, ax
    mov es, ax
    mov bx, 0x8000

    mov ss, bx
    mov sp, ax

    mov si, S2Hello
    call print
    
    call gexec

    mov si, GotExecMsg
    call print

    cli
    call EnableA20
    cli
    pusha
	lgdt[gdtr]
    sti
    mov si, A20SuccessMsg
    call print
    xor ax, ax
    int 0x16
    mov si, GDTMsg
    call print
    xor ax, ax
    int 0x16
    cli
    
    mov eax, cr0
    or al, 1
    mov cr0, eax

    jmp 0x08:Stage3

    cli
    hlt

    jmp $

;Subroutines:

;Mini FS "Driver"
gexec:
    mov si, 0x500
    jmp findstartloop
    findstartloop:
        lodsb
        cmp al, 0x02
        je foundstart
        jmp findstartloop
    cli
    hlt
    jmp $

foundstart:
    add si, 0x3F
    isfile?:
        lodsb
        cmp al, 0x12
        je .foundfile
        jmp foundstart
        .foundfile:
            add si, 0x21 
            mov di, Filename
            mov cx, 29 ;0x21 + 29 = 62
            rep cmpsb
            je .success
            jmp .faileure
            cli
            hlt
            jmp $
        .faileure:
            add si, cx
            add si, 0x2 ;62 + 0x02 = 64 
            jmp .foundfile
            jmp $
        .success:
            jmp .cpstuff
            .cpstuff:
                sub si, 0x35 ;62 - 0x35 = 0x09
                mov bx, Location
                mov di, bx
                mov cx, 0x07 ;8 bytes
                rep movsb
                inc si
                mov bx, tempLocal
                mov di, bx
                mov cx, 0x07 ;8 bytes
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

                ret

;Print

print:
    lodsb
    or al, al
    jz exit
    mov ah, 0x0E
    int 0x10
    jmp print

exit:
    ret

;A20 Code


EnableA20:
	pushad
	pushfd
	mov ax, 0x2402
	int 0x15
	jc A20NoBios
	test al, 1
	je A20Enabled
	mov ax, 0x2401
	int 0x15
	jc A20NoBios
	or ah, ah
	jnz A20NoBios

A20Enabled:
	popfd
	popad
	ret
	
A20NoBios:
	mov ax, 0x2403
	int 0x15
	jc A20KB
	test bx, 1
	je A20KB
	test bx, 2
	je FastA20
	call CheckA20
	jc A20Enabled
A20Fail:
	mov si, A20FaileureMsg
	call print
	cli
	hlt
FastA20:
	in al, 0x92
	test al, 2
	jnz A20Fail
	or al, 2
	and al, 0xFE
	out 0x92, al
	call CheckA20
	jc A20Enabled
	cli
	hlt
A20KB:
	cli
	mov cx, 50
	UseKB:
	call A20Owait
	mov al, 0xAD
	out 0x64, al
	mov al, 0xD0
	out 0x64, al
	call A20Iwait
	mov al, 0xD1
	out 0x64, al
	call A20Owait
	pop ax
	or al, 10b
	out 0x60, al
	call A20Owait
	mov al, 0xAE
	out 0x64, al
	call A20Owait
	call CheckA20
	jc A20Enabled
	loop UseKB
	jmp A20Fail
A20Owait:
	in al, 0x64
	test al, 10b
	jnz A20Owait
	ret
A20Iwait:
	in al, 0x64
	test al, 1b
	jz A20Iwait
	ret
	
CheckA20:
	pushad
	push ds
	push es
	xor ax, ax
	mov ds, ax
	not ax
	mov es, ax
	mov ax, word[ds:0x7DFE]
	mov bx, word[es:0x7E0E]
	pop es
	pop ds
	cmp ax, bx
	jne A20isenabled
	clc
CheckA20Ret:
	popad
	ret
A20isenabled:
	stc
	jmp CheckA20Ret

;File DAP for INT 13h AH=0x42

FileDAP:
    db 0x10
    db 0x00
    size: dw 0x00
    dd 0x2000
    Location: dq 0x0

;
;Pretty Standard GDT setup for right now, i'd say
;


gdt_data: 
	dd 0                
	dd 0 

; gdt code:	            
	dw 0FFFFh
	dw 0
	db 0
	db 10011010b
	db 11001111b
	db 0

; gdt data:
	dw 0FFFFh
	dw 0
	db 0
	db 10010010b
	db 11001111b
	db 0
	
end_of_gdt:
gdtr: 
	dw end_of_gdt - gdt_data - 1
	dd gdt_data


[BITS 32]

Stage3:
    mov ax, 0x10
    mov ds, ax
    mov ss, ax
    mov es, ax
    mov esp, 0x90000

    mov edi, 0xB800
    mov [edi], byte 'P';Protection
    mov [edi+1], byte 0x7

    mov [edi+2], byte 'E';Enabled
    mov [edi+3], byte 0x7
    
    mov esi, 0x2000
    mov edi, 0xFF000 ;My kernel has an offset of 0x1000, so this lets me load 
    ;it at an offset.
    mov ecx, tempSize
    rep movsd
    jmp 0x8:0x100000

    jmp $



GotExecMsg db "Lilak OS Kernel Image loaded at memory location 0x2000", 0x0D, 0x0A, 0x00
A20TestMsg db "Testing A20 . . . ", 0x0D, 0x0A, 0x00
A20FaileureMsg db "A20 Line Enabled", 0x0D, 0x0A, 0x00
A20SuccessMsg db "A20 Line Failed", 0x0D, 0x0A, 0x00
GDTMsg db "GDT Set", 0x0D, 0x0A, 0x00
Filename db "/boot/LilakOSKernelImage.LEF", 0x00
S2Hello db 0x0D, 0x0A, "Stage 2!", 0x0D, 0x0A, 0x00
tempLocal dq 0x0000
tempSize dq 0x0000
db "END", 0x00
times 1024-($-$$) db 0x0
