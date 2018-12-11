[bits 64]

extern malloc
extern free

section .text
	global start
	global step
    global cleanup

section .data
    align 16 ; Align data to 16 bytes.
    ; Memory for the heat flow simulation.
    board: DQ 0      ; memory for the board
    cache: DQ 0       ; memory for the heat change across the board
    width: DD 0      ; width of the board
    height: DD 0     ; height of the board
    heater: DQ 0     ; heater heat value
    cooler: DQ 0     ; cooler heat value
    proportion: DD 0 ; proportion for the heat flow
    ; Memory for XMM registers.
    vs: DD 0, 0, 0, 0

; start initializes global variables needed for computing
; heat flow across the board. It also allocates new memory
; for saving heat change per every cell.
; In case of error while allocating memory, exit(1) is called.
;
; Arguments:
;   rdi - width of the matrix
;   rsi - height of the matrix
;   rdx - initial value for the matrix fields
;   rcx - value for the heat engine
;   r8  - value for the cool engine
;   r9  - value for the proportion of heat flow
start:
    ; Set up global variables (from arguments).
	mov [width], edi
	mov [height], esi
    mov [board], rdx
    mov [heater], rcx
    mov [cooler], r8
    movups [vs], xmm0
    mov eax, [vs]
    mov [proportion], eax
    ; Allocate memory (size of two rows) for processing the board.
    mov rax, 0
    mov eax, [width] ; rax = [width]
    mov edi, [height]
    mul rdi
    mov rdi, 4
    mul rdi          ; rax *= 2 * 4 // number of cells (in two rows)
    mov rdi, rax
    call malloc      ; malloc([width] * [height] * 4)
    mov [cache], rax
    test rax, rax
    jz malloc_failed ; If no error, return.
    ret
    malloc_failed:   ; else
    mov rax, 0
    mov rbx, 1
    syscall ; exit(1)

; step simulates one step for heat flow.
; Cell changes it's heat based on the heat value coming from the near cells.
; The flow is parametrized by 'r9' register value when calling start.
step:
    call step_rows
    call flush_board
    ret

; Arguments:
;   rdi - row to compute the heat flow for.
step_rows:
    push rbp
    mov rbp, rsp

    sub rsp, 8
    mov DWORD[rsp], 0     ; x
    mov DWORD[rsp + 4], 0 ; y

    step_row_y:
    mov DWORD[rsp], 0     ; x = 0
    step_row_x:

    mov edi, [rsp]     ; edi = x
    mov esi, [rsp + 4] ; esi = y
    call step_row_4

    mov edi, [rsp]
    add edi, 4
    mov [rsp], edi
    cmp edi, [width]
    jl step_row_x

    mov esi, [rsp + 4]
    inc esi
    mov [rsp + 4], esi
    cmp esi, [height]
    jne step_row_y

    mov rsp, rbp
    pop rbp
    ret

; Arguments:
;   rdi - x, starting point to process 4 cells to the right direction
;   rsi - y, row number
; Used registers: rdi, rsi, rdx, rcx.
step_row_4:
    push rbp
    mov rbp, rsp
    sub rsp, 16
    mov [rsp], edi     ; x
    mov [rsp + 4], esi ; y

    ; Compute how many cells to process.
    ; Store result in [rsp + 8].
    mov eax, [width]
    sub eax, edi
    mov edi, 4
    cmp eax, edi
    jl step_row_4_c
    mov eax, 4

    step_row_4_c:
    mov [rsp + 8], eax

    ; Set left.
    mov ecx, 0
    step_row_add_left:
    mov edi, [rsp]     ; x
    mov esi, [rsp + 4] ; y
    add edi, ecx
    dec edi ; x -= 1
    call heat_value
    mov [vs + (ecx*4)], eax
    inc ecx
    cmp ecx, [rsp + 8]
    jl step_row_add_left
    movups xmm0, [vs] ; Set left.

    ; Add right.
    mov ecx, 0
    step_row_add_right:
    mov edi, [rsp]     ; x
    mov esi, [rsp + 4] ; y
    add edi, ecx
    inc edi ; x += 1
    call heat_value
    mov [vs + (ecx*4)], eax
    inc ecx
    cmp ecx, [rsp + 8]
    jl step_row_add_right

    movups xmm1, [vs] ; Add right.
    addps xmm0, xmm1

    ; Add up.
    mov ecx, 0
    step_row_add_up:
    mov edi, [rsp]     ; x
    mov esi, [rsp + 4] ; y
    add edi, ecx
    dec esi ; y -= 1
    call heat_value
    mov [vs + (ecx*4)], eax
    inc ecx
    cmp ecx, [rsp + 8]
    jl step_row_add_up

    movups xmm1, [vs] ; Add up.
    addps xmm0, xmm1

    ; Add down.
    mov ecx, 0
    step_row_add_down:
    mov edi, [rsp]     ; x
    mov esi, [rsp + 4] ; y
    add edi, ecx
    inc esi ; y += 1
    call heat_value
    mov [vs + (ecx*4)], eax
    inc ecx
    cmp ecx, [rsp + 8]
    jl step_row_add_down

    movups xmm1, [vs] ; Add down.
    addps xmm0, xmm1

    ; Sub 4*cell value.
    mov ecx, 0
    step_row_4cell_value:
    mov edi, [rsp]     ; x
    mov esi, [rsp + 4] ; y
    add edi, ecx
    call heat_value
    mov [vs + (ecx*4)], eax
    inc ecx
    cmp ecx, [rsp + 8]
    jl step_row_4cell_value

    movups xmm1, [vs] ; Sub 4* cell value.
    mov DWORD[vs],    0x40800000 ; = float(4)
    mov DWORD[vs+4],  0x40800000 ; = float(4)
    mov DWORD[vs+8],  0x40800000 ; = float(4)
    mov DWORD[vs+12], 0x40800000 ; = float(4)
    movups xmm2, [vs]
    mulps xmm1, xmm2
    subps xmm0, xmm1

    ; Mul proportion.
    mov ecx, 0
    step_row_proportion:
    mov edi, [proportion]
    mov [vs + (ecx*4)], edi
    inc ecx
    cmp ecx, [rsp + 8]
    jl step_row_proportion

    movups xmm1, [vs] ; Mul proportion.
    mulps xmm0, xmm1

    ; Add current cell's heat value to compute heat after the flow.
    mov ecx, 0
    step_row_final:
    mov edi, [rsp]     ; x
    mov esi, [rsp + 4] ; y
    add edi, ecx
    call heat_value
    mov [vs + (ecx*4)], eax
    inc ecx
    cmp ecx, [rsp + 8]
    jl step_row_final

    movups xmm1, [vs] ; Add current cell values.
    addps xmm0, xmm1

    ; Get cell's heat values after step simulation.
    movups [vs], xmm0
    ; Save them to 'cache'.
    mov ecx, 0
    step_row_save:
    mov edi, [rsp]     ; x
    mov esi, [rsp + 4] ; y
    add edi, ecx ; x += ecx

    mov eax, esi
    mov esi, [width]
    mul esi
    add eax, edi
    mov esi, 4
    mul esi

    mov edi, [vs + (ecx*4)]
    mov rsi, [cache]
    mov [rsi + rax], edi

    inc ecx
    cmp ecx, [rsp + 8]
    jl step_row_save

    mov rsp, rbp
    pop rbp
    ret

; flush_board copies cache heat flow to the main board.
flush_board:
    mov eax, [width]
    mov edi, [height]
    mul edi
    mov rcx, rax

    mov rdi, 0
    mov rax, 0
    flush_board_loop:

    mov rdx, [cache]
    mov esi, [rdx + rax]
    mov rdx, [board]
    mov [rdx + rax], esi

    add rax, 4
    inc rdi
    cmp rcx, rdi
    jne flush_board_loop

    ret

; heat_value returns heat value for given cell.
; It includes getting values for coolers and heaters.
;
; Arguments:
;   rdi - x coordinate on the board
;   rsi - y coordinate on the board
; Used registers: rdi, rsi, rdx.
heat_value:
    mov edx, 0
    ; Check if cell is a heater.
    mov eax, -1
    cmp esi, eax
    je heat_value_is_heater
    mov eax, 0
    mov eax, [height]
    cmp esi, eax
    jne heat_value_not_a_heater
    mov edx, 1
    heat_value_is_heater:
    mov eax, [width]
    mul edx
    add eax, edi
    mov edi, 4
    mul edi
    mov edx, eax
    mov rsi, [heater]
    mov eax, [rsi + rdx]
    ret
    heat_value_not_a_heater:
    ; Check if cell is a cooler.
    mov eax, -1
    cmp edi, eax
    je heat_value_is_cooler
    mov eax, 0
    mov eax, [width]
    cmp eax, edi
    jne heat_value_not_a_cooler
    mov edx, 1
    heat_value_is_cooler:
    mov eax, [height]
    mul edx
    add eax, esi
    mov edx, 4
    mul edx
    mov edx, eax
    mov rsi, [cooler]
    mov eax, [rsi + rdx]
    ret
    heat_value_not_a_cooler:
    ; It is a normal cell.
    mov eax, esi      ; rax = y
    mov esi, [width]
    mul esi           ; rax *= width
    add eax, edi      ; rax += x
    mov esi, 4
    mul esi
    mov rsi, [board]
    add rsi, rax
    mov eax, [rsi]
    ret

; cleanup frees allocated memory during start procedure.
; In case of error during freeing memory, exit(2) is called.
cleanup:
    mov rdi, [cache]
    call free
    test rax, rax
    jnz cleanup_failed ; if no error, return
    ret
    cleanup_failed:    ; else
    mov rax, 0
    mov rbx, 2
    syscall ; exit(2)
