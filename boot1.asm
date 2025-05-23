[org 0x7C00]
bits 16

mov	ax , 0x0000
mov	ds , ax
mov	es , ax
mov	ss , ax
mov	sp , 0x7C00

mov	ah , 0x02
mov	al , 0x01
mov	ch , 0
mov	cl , 2
mov	dh , 0
mov	dl , 0
mov	bx , 0x8000
int 	0x13	; Read sector

jmp	0x0000:0x8000

times 	510-($-$$) db 0	 ; Padding
dw	0xAA55	; Bootloader signature
