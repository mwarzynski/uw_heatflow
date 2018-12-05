[bits 64]

extern malloc

section .text
	global start
	global step

section .data
    align 16 ; Align data to 16 bytes.
    ; Memory for the heat flow simulation.
    board:  DQ 0       ; memory for the board
    board_change: DQ 0 ; memory for the heat change across the board
    width:  DD 0       ; width of the board
    height: DD 0       ; height of the board
    heater: DQ 0       ; heater heat value
    cooler: DQ 0       ; cooler heat value
    proportion: DD 0   ; proportion for the heat flow
    ; Memory for XMM registers.
    v1: DD 0, 0, 0, 0
    v2: DD 0, 0, 0, 0

; start initializes global variables needed for computing
; heat flow across the board. It also allocates new memory
; for saving heat change per every cell.
;
; Arguments:
;   rdi - width of the matrix
;   rsi - height of the matrix
;   rdx - initial value for the matrix fields
;   rcx - value for the heat engine
;   r8  - value for the cool engine
;   r9  - value for the proportion of heat flow
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
    mov rsi, 4
    mul rsi           ; rax *= 4;
    mov rdx, rax
    call malloc       ; malloc([width] * [height] * 4)
    test rax, rax
    jz start_fail     ; If no error, return.
    ret
    start_fail:
    mov rax, 0
    mov rbx, 1
    syscall ; exit(1)

step:
    ; Compute changes for every cell.
    mov rdi, cell_compute_change
    call loop_cells
    ; Apply computed changes for every cell.
    mov rdi, cell_apply_change
    call loop_cells
    ret

; Arguments:
;   rdi - procedure to call for each cell
loop_cells:
    push rbp
    mov rbp, rsp
    sub rsp, 8 ; address to call
    sub rsp, 8 ; x, y

    mov DWORD[rsp + 4], 0 ; x = 0
    mov DWORD[rsp], 0     ; y = 0
    mov [rsp + 8], rdi

    loop_cells_call:
    ; edi = x, esi = y
    mov rdi, 0
    mov rsi, 0
    mov edi, DWORD[rsp + 4]
    mov esi, DWORD[rsp]
    ; Do one cell operation.
    mov rax, [rsp + 8]
    call rax

    ; Increment x.
    mov eax, DWORD[rsp + 4]
    inc eax
    mov DWORD[rsp + 4], eax

    mov esi, [width]
    cmp eax, esi        ; if (x != [width])
    jne loop_cells_call ;     goto loop_cells_call

    mov DWORD[rsp + 4], 0 ; x = 0
    ; Increment y.
    mov esi, [rsp]
    inc esi
    mov DWORD[rsp], esi

    mov eax, [height]
    cmp eax, esi        ; if (y != [height])
    jne loop_cells_call ;     goto step_loop

    mov rsp, rbp
    pop rbp
    ret

; Arguments:
;   rdi - x coordinate for cell at the board
;   rsi - y coordinate for cell at the board
cell_compute_change:
    ; Load to rdx cell heat value.
    mov rdx, 0x1337
    ; Load heat to the v1 values.
    call cell_set_right_heat_change
    call cell_set_left_heat_change
    call cell_set_up_heat_change
    call cell_set_down_heat_change

    ; Load proportions to v2 values.
    mov eax, [proportion]
    mov [v2], eax
    mov [v2 + 4], eax
    mov [v2 + 8], eax
    mov [v2 + 12], eax

    movups xmm0, [v1]
    movups xmm1, [v2]
    mulps  xmm0, xmm1
    movups [v1], xmm0
    movups [v2], xmm1

    ; Save the heat change in the board_change.
    ; TODO: implement me

	ret

cell_set_right_heat_change:
    mov DWORD[v1], 1
    ret

cell_set_left_heat_change:
    mov DWORD[v1], 1
    ret

cell_set_up_heat_change:
    mov DWORD[v1+8], 1
    ret

cell_set_down_heat_change:
    mov DWORD[v1+12], 1
    ret

; Arguments:
;   rdi - x coordinate for cell at the board
;   rsi - y coordinate for cell at the board
cell_apply_change:
    ret

