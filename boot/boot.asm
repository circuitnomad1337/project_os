[BITS 16]     
[ORG 0x7C00]   ; classic place of the bootloader

_start:
    mov ax, 0x00
    mov bx, 0x00
    mov cx, 0x00
    mov dx, 0x00

    ; turning the A20 line 
    ; in order to switch to Protected Mode (32 bits)

    in al, 0x92    ; download the state of 0x92 I/O port
    or al, 2       ; manipulate it
    out 0x92, al   ; send it back, changing the behaviour of the I/O port

    mov si, message
    call print

    ; Next goal:
    ; load the GDT, and design it. 
    ; Try to do it in your own way of design, exactly like you want it.
    ; Also, gather information about GDTs in general.
    ; Bit by bit. (almost like brick by brick lol)

print:
    lodsb          ; Moves SI into AL, lodsb = LOaD String Byte
    or al, al      ; Checks if al is null-terminator (0x00)
    jz print_finished   ; "jump if zero"

    mov ah, 0x0E   ; BIOS's teletype function
    int 0x10
    jmp print

print_finished:
    ret    ; return


message db "Hello, world! Bootloader's here B).", 0   ; string var

times 510 - ($ - $$) db 0   ; fill 510 bits with 0's
dw 0xAA55                   ; bootloader's signature