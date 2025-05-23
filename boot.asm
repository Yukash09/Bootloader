bits 16
; In real mode , 64k segment of a logical address --> divide by 16. 
mov	ax , 0x7C0	; Our code resides at 0x7C00 (convention) , put data segment at 0x7C0 . Can't directly do mov ds , 0x7C0 , so use ax
mov	ds , ax	
mov	ax , 0x7E0 	; Stack starts after 512 bytes of boot loader --> 0x7C00 + 512 = 0x7E00 --> 0x7E0
mov	ss , ax
; On x86 architecture --> sp decrements --> set sp at some point after ss.

mov	sp , 0x2000

call	clear
push	0x0000

call	setcursor
add	sp , 2

push	msg
call	printmsg
add	sp , 2

call	readinput
add	sp , 2

cli  	; Clear interrupt flag --> disables hardware interrupts 
hlt	; Halts the CPU until the next interrupt is received

clear:
	; By storing certain registers with certain parameters and then sending a particular opcode to the BIOS as an interrupt.
	push	bp
	mov	bp , sp
	pusha 		; Push all general purpose registers  (ax , cx , dx , bx , sp , bp , si , di)

	mov	ah , 0x07  ; tells BIOS to scroll down window , ah --> higher bytes of ax
	mov	al , 0x00  ; clear entire window
	mov     bh , 0x07  ; white on black
	mov     cx , 0x00  ; Specifies top left of screen as (0 , 0)
	mov 	dh , 0x18  ; 0x18 = 24 --> rows of chars
	mov	dl , 0x4f  ; 0x4f = 79 --> cols of chars
	int     0x10  ; Calls video interrupt

; Spec: 
; Video - Scroll down window:
;	ah - 0x07 ; 
;	al - No. of lines by which to scroll down , 0x00 - to clear entire window 
;	bh - Write blank lines at top of window
;	ch , cl - row , column of window's upper left corner
;	dh , dl - row , column of window's lower left corner
	popa
	mov	sp , bp
	pop	bp
	ret

setcursor:
; Given two arguments row,col , this will set the cursor to that position
; Arguments located at bp + 4 , we need to put it in dh , dl (according to spec)
	push	bp
	mov	bp , sp
	pusha

	mov	ah , 0x02
	mov	bh , 0x00  ; Default page number
	mov	dx , [bp + 4]	
	int	0x10

	popa
	mov	sp , bp
	pop	bp
	ret

printmsg:
	
	push	bp
	mov	bp , sp
	pusha

	mov	si , [bp + 4]	; Pointer to the string --> si (given as argument located at bp+4)
	mov	ah , 0x0e
	mov	bh , 0x00	; bh - page number ; bl - foreground color (Doesn't matter)
	mov	bl , 0x00

	printchar:			; Subroutine that prints char till null is encountered
		mov	al , [si]
		add	si , 1
		or	al , 0
		je	exit

		int	0x10
		jmp	printchar

	exit:
		popa
		mov	sp , bp
		pop	bp
		ret

readinput:
	
	push	bp
	mov	bp , sp
	pusha

	mov	si , buffer
	mov	cx , 0x00

	readchar:
		mov	ah , 0x00
		int	0x16

		cmp	al , 0x0d  ; Check if it's enter
		je	exit1

		cmp	al , 0x08  ; Check if it's backspace
		je	backspace

		cmp	al , 0x04  ; Ctrl+D
		je	reboot

		mov	[si] , al  ; store the character in the location of si
		inc	si
		inc	cx
	
	outchar:
		mov	ah , 0x0e
		mov	bh , 0x00
		mov	bl , 0x00
		int	0x10
		jmp	readchar

	backspace:
		cmp	cx , 0
		je	readchar

		dec	si
		dec 	cx

		mov	ah , 0x0e
		mov	al , 0x08
		int	0x10
		mov	al , ''
		int 	0x10
		mov	al , 0x08
		int 	0x10
		jmp	readchar

	reboot:
		mov	ax , 0x0000
		int	0x19

	exit1:
		mov byte  [si] , 0
		popa
		mov	sp , bp
		pop	bp
		ret			

msg:	db	"If you replace the stack with a queue in a Push-down automata, it becomes as powerful as a Turing Machine. Type Something, or do Ctrl+D for reboot" , 13 , 10 , 0
buffer:	times	128 db 0

times	510-($-$$) db 0 
; times --> repeat an instruction specified number of times (510 - current size , here)
; $ - $$ --> current size of the program in bytes 
; db  0 --> padding with 0 
dw	0xAA55		; Tells that this is bootable (boot signature)
