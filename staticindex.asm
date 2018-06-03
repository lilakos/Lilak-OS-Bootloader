;
; SFS Filesystem because fuck FAT!
; But I don't have any utility to create images for me
; I don't care though
;

times 256-($-$$) db 0x00
db 0x02 ;Type
times 320-($-$$) db 0x00
db 0x12 ;Type
db 0x00 ;Continuation Entries
dq 0x00 ;Timestamp
dq 0x03 ;Start block
dq 0x16 ;End block
dq 9952 ;File Size
db '/boot/LilakOSKernelImage.LEF', 0x0
times 384-($-$$) db 0x00
db 0x12 ;Type
db 0x00 ;Continuation Entries
dq 0x00 ;Timestamp
dq 0x01 ;Start block
dq 0x03 ;End block
dq 1024 ;File Size
db '/boot/stage2.LEF', 0x0
times 448-($-$$) db 0x00
db 0x01 ;Type
db 0x00 ;Zero
db 0x00 ;Zero
db 0x00 ;Zero
dq 0x00 ;Timestamp
db ' ~ LilakOS v1.0 ~ ', 0x00
