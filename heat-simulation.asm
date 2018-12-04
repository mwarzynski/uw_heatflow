extern malloc

section .text
	global start
	global step

section .data
    board:  DQ 0
    boardd: DQ 0
	width:  DD 0
	height: DD 0
    heater: DQ 0
    cooler: DQ 0
    proportion: DD 0

; Arguments:
;   rdi - width of the matrix
;   rsi - height of the matrix
;   rdx - initial value for the matrix fields
;   rcx - value for the heat engine
;   r8  - value for the cool engine
;   r9  - value for the proportion of heat movement
start:
    ; Set up variables.
	mov [width], edi
	mov [height], esi
    mov [board], rdx
    mov [heater], rcx
    mov [cooler], r8
    mov [proportion], r9d
    ; Allocate memory for processing the board.
    ; Additional memory will be useful for keeping heat changes.
    mov eax, [width]
    mul DWORD[height] ; rax = [width] * [height]
    mov rsi, 0x4
    mul rsi           ; rax *= 4;
    mov rdx, rax
    call malloc       ; malloc([width] * [height] * 4)
    test rax, rax
    jz start_fail     ; If no error, return.
    ret
start_fail:
    mov rax, 0 ; exit syscall
    mov rbx, 1 ; exit code
    syscall

step:
	; Use SSE (for SSE3?).
	ret
