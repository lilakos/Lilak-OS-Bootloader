;
; Stage 2
; Copyright © 2018, Jacob Smith
; See LICENSE.MD for licensing info
;

[BITS 16]
[ORG 0x1000]

jmp main
main:
    mov si, HelloMSG
    call print

    call MemoryDetection

    call readfile

    cli
    call EnableA20
    cli
    pusha
    lgdt[gdtr]

    mov eax, cr0
    or al, 1
    mov cr0, eax

    jmp 0x08:Stage3

    jmp $

MemoryDetection:
    xor cx, cx
    xor dx, dx
    mov ax, 0xE801
    int 0x15
    jc .err
    cmp ah, 0x86
    je short .err
    cmp ah, 0x80
    je short .err
    jcxz .useax

    mov ax, cx
    mov bx, dx

.useax:
    mov [tempcx], ax
    mov [tempdx], bx
    xor ax, ax
    xor bx, bx
    xor cx, cx
    xor dx, dx
    xor si, si
    xor di, di
    ret

.err:
    int 0x16

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
	jmp $
FastA20:
	in al, 0x92
	test al, 2
	jnz A20Fail
	or al, 2
	and al, 0xFE
	out 0x92, al
	call CheckA20
	jc A20Enabled
	jmp $
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

readfile:
    mov dx, 0x80
    mov si, 0x800
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
        cmp al, 0x1
        jne loop2ex
        add si, 0x20
        mov di, Filename
        mov cx, 0x21
        rep cmpsb
        
        je success
        jmp loop2
    success:
        std
        loop3:
            lodsb
            cmp al, 0x12
            je success2
            jmp success
        success2:
            cld
            add si, 0xB
            mov di, Location
            mov cx, 0x8

            rep movsb
            lodsw
            mov bx, [Location]

            sub ax, bx

            mov [Size], ax

            mov si, FileDAP
            xor ax, ax
            mov ds, ax
            mov ah, 0x42
            int 0x13

            ret
        loop2ex:
            add si, 0x20
            jmp loop2

print:
    lodsb
    or al, al
    jz .exit
    mov ah, 0x0E
    int 0x10
    jmp print

.exit:
    ret

FileDAP:
    db 0x10
    db 0x00
    Size dw 0x00
    dw 0x2000
    dw 0x0000
    Location dq 0x00

GDT: 
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
	dw end_of_gdt - GDT - 1
	dd GDT

[BITS 32]
Stage3:
    mov ax, 0x10
    mov ds, ax
    mov ss, ax
    mov es, ax
    mov esp, 0x90000

    mov eax, 0x464c457f
    mov ebx, dword [0x2000]

    cmp eax, ebx
    jne ERROR


    xor esi, esi
    xor edi, edi
    xor ecx, ecx

    mov esi, 0x2000
    mov edi, 0xFF000
    mov ecx, 40000
    
    rep movsb

    xor ecx, ecx
    xor edx, edx

    mov eax, [tempcx]
    mov ebx, 0x400

    mul ebx

    push eax

    mov eax, [tempdx]
    mov ebx, 0x10000

    mul ebx

    pop ebx

    add eax, ebx

    add eax, 0x100000

    mov [HighMem], eax


    mov esi, 0x2018
    lodsb

    push multibootInfo

    jmp 0x8:0x100000

ERROR:
    xor edi, edi
    mov edi, 0xB8000
    xor ecx, ecx
    mov ecx, 4000 
    xor ax, ax
    clear:
        mov [edi], word ax
        inc edi
        dec ecx
        cmp ecx, 0
        jz finished
        jmp clear
    finished:
    xor edi, edi
    mov edi, 0xB8000
    mov [edi], word 0x8C45
    mov [edi+2], word 0x8C52
    mov [edi+4], word 0x8C52
    mov [edi+6], word 0x8C4F
    mov [edi+8], word 0x8C52
    jmp $

tempcx dw 0x00
tempdx dw 0x00

multibootInfo:
    Flags dd 00000000000000000000000000000001b
    LowMem dd 0x00
    HighMem dd 0x00
    BootDevice dd 0x80
    CmdLine dd 0x00
    ModsCount dd 0x00
    ModsAddr dd 0x00
    Syms dd 0x00
    Syms2 dd 0x00
    Syms3 dd 0x00
    MMapLength dd 0x00
    MMapAddr dd 0x00
    DrivesLength dd 0x400000
    DrivesAddr dd 0x00
    ConfigTable dd 0x00
    BootloaderName dd BootName
    APMTable dd 0x00
    VBRControlInfo dd 0x00
    VBEModeInfo dd 0x00
    VBEMode dd 0x00
    VBEInterfaceSeg dd 0x00
    VBEInterfaceOff dd 0x00
    VBEInterfaceLen dd 0x00
    FrameBufferAddr dd 0x00
    FrameBufferPitch dd 0x00
    FrameBufferWidth dd 0x00
    FrameBufferHeight dd 0x00
    FrameBufferBPP dd 0x00
    FrameBufferType dd 0x00
    ColorInfo dd 0x00
    ColorInfo2 db 0x00


BootName db 'LilakOS Bootloader', 0x0A, 0x0D, 0x00
Filename db "/LilakOS/core/LOS32BitKernel.LEF", 0x00
HelloMSG db 'Hello, stage 2!', 0x0A, 0x0D, 0x00
