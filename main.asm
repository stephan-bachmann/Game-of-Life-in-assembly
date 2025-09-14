default rel
%include "structs.inc"




global _start
extern guide, guide_len
extern min_max_guide, min_max_guide_len
extern input_grid_guide, input_grid_guide_len
extern clear, clear_len
extern input_N, input_map
extern current_grid, next_grid
extern grid_var
extern insert_char_to_index
extern grid_set
extern atoi, sleep
extern to_next_grid

section .text
_start:
    mov qword [grid_var+Grid_var.current_grid], current_grid
    mov qword [grid_var+Grid_var.next_grid], next_grid

    xor r12, r12    ; 맵 크기

    mov rax, 1
    mov rdi, 1
    mov rsi, guide
    mov rdx, guide_len
    syscall

    ; 맵 크기 받기
    xor rax, rax
    xor rdi, rdi
    mov rsi, input_N
    mov rdx, 2
    syscall

    ; 입력을 정수로 변환
    mov rdi, input_N
    call atoi

    ; 범위 내인지 확인
    cmp rax, 10
    jl .not_in_min_max
    cmp rax, 50
    jg .not_in_min_max

    ; 존재 가능 구역 및 맵 크기 저장
    mov dword [grid_var+Grid_var.epz_size], eax
    add rax, 2  ; 테두리 포함
    mov dword [grid_var+Grid_var.map_size], eax
    mov r12, rax    ; 이 스코프에서 씀
    
    ; 초기 테두리 세팅
    mov rdi, qword [grid_var+Grid_var.current_grid]
    call grid_set

    mov rdi, qword [grid_var+Grid_var.next_grid]
    call grid_set

    mov dword [grid_var+Grid_var.grid_size], eax



    mov r12d, dword [grid_var+Grid_var.epz_size]
    xor rcx, rcx        ; 루프 카운터
    mov r8, 1           ; 행
    ; 사용자에게 입력 받기
.input_loop:
    push rcx
    xor rax, rax
    xor rdi, rdi
    mov rsi, input_map
    mov rdx, r12
    syscall
    pop rcx

    cmp rax, r12
    je .continue

.maybe_newline:
    ; 개행만 들어온 경우 무시
    cmp rax, 1
    jne .continue
    cmp byte [input_map], 0x0a
    jne .continue
    ; newline이니까 그냥 스킵
    jmp .input_loop

.continue:
    push rcx
    xor rcx, rcx
    xor r9, r9
    xor r10, r10
.insert_loop:
    mov r10, rcx
    inc r10
    mov r9b, byte [input_map+rcx]
    sub r9b, 0x30

    ; 논리 인덱스 계산
    mov eax, dword [grid_var+Grid_var.map_size]
    imul rax, r8
    add rax, r10
    
    push rcx
    mov rdi, qword [grid_var+Grid_var.current_grid]
    mov rsi, rax
    mov rdx, r9
    call insert_char_to_index
    pop rcx

    inc rcx
    cmp rcx, r12
    jne .insert_loop
    pop rcx




    inc rcx
    inc r8
    cmp rcx, r12
    jne .input_loop


    ; 사용자에게 입력 받기



    mov rax, 1
    mov rdi, 1
    mov rsi, clear
    mov rdx, clear_len
    syscall

    mov rax, 1
    mov rdi, 1
    mov rsi, qword [grid_var+Grid_var.current_grid]
    mov edx, dword [grid_var+Grid_var.grid_size]
    syscall


    mov rdi, 1
    xor rsi, rsi
    call sleep

    
    ; 최초 1회 다음 그리드에 현재 그리드 복사
    mov rdi, qword [grid_var+Grid_var.next_grid]
    mov rsi, qword [grid_var+Grid_var.current_grid]
    mov ecx, dword [grid_var+Grid_var.grid_size]
    rep movsb



.infinity_loop:
    xor rdi, rdi
    mov rsi, 500
    call sleep

    mov rax, 1
    mov rdi, 1
    mov rsi, clear
    mov rdx, clear_len
    syscall

    mov rdi, qword [grid_var+Grid_var.current_grid]
    mov rsi, qword [grid_var+Grid_var.next_grid]
    call to_next_grid

    mov rax, 1
    mov rdi, 1
    mov rsi, qword [grid_var+Grid_var.current_grid]
    mov edx, dword [grid_var+Grid_var.grid_size]
    syscall

    jmp .infinity_loop


    jmp _exit







.not_in_min_max:
    mov rax, 1
    mov rdi, 1
    mov rsi, min_max_guide
    mov rdx, min_max_guide_len
    syscall

_exit:
    mov rax, 60
    xor rdi, rdi
    syscall
