;
; Stage 2
; Copyright © 2018, Jacob Smith
; See LICENSE.MD for licensing info
;

; \/ #define simple \/

[BITS 16]
[ORG 0x1000]

jmp main

main:
    mov si, S2Hello
    call print

    jmp $
print:
    lodsb
    or al, al
    jz exit
    mov ah, 0x0E
    int 0x10
    jmp print

exit:
    ret

S2Hello db 0x0D, 0x0A, "Stage 2!", 0x0D, 0x0A, 0x00
times 1024-($-$$) db 0x0
