default rel
%include "structs.inc"



global grid_set
global insert_char_to_index
global to_next_grid
extern CHARS
extern grid_var


; 행과 열을 주면 논리 인덱스를 반환하는 함수
; input:
;   rdi = 행
;   rsi = 열
; return:
;   rax = 논리 인덱스
row_and_column_to_logic_index:
    mov rax, rdi
    imul eax, dword [grid_var+Grid_var.map_size]
    add rax, rsi
    ret
;










; 논리 인덱스를 주면 실제 인덱스를 반환하는 함수
; input:
;   rdi = 논리 인덱스
; return:
;   rax = 실제 인덱스
logical_index_to_real_index:
    mov rax, rdi
    xor rcx, rcx
    mov ecx, dword [grid_var+Grid_var.map_size]
    xor rdx, rdx
    
    div rcx
    ; rax = 행

    imul rcx, rdi, 3
    add rax, rcx
    ; rax = 행 + LI * 3 = RI

    ret


;




; 그리드 주소, 논리 인덱스, 문자 인덱스를 주면 해당 문자를 써주는 함수
; input:
;   rdi = 그리드 주소
;   rsi = 논리 인덱스
;   rdx = CHARS에서의 문자 인덱스
insert_char_to_index:
    push rbp
    mov rbp, rsp
    push r12
    push r13

    mov r12, rdx
    mov r13, rdi
    
    mov rdi, rsi
    call logical_index_to_real_index
    mov rdi, r13
    ; 논리 인덱스 사용 끝

    mov rdx, r12
    mov rsi, qword [CHARS+rdx*8]
    lea rdi, [rdi+rax]
    mov rcx, 3
    rep movsb 
    
    pop r13
    pop r12
    pop rbp
    ret




;



; 그리드의 틀을 채우는 함수
; input:
;   rdi = 그리드 주소
; return:
;   rax = 실제 그리드 크기
grid_set:
    push rbp
    mov rbp, rsp
    push r12
    push r13
    push r14
    push r15

    mov r12d, dword [grid_var+Grid_var.map_size]    ; 맵 크기
    mov r8, r12                     ; N - 1
    dec r8    
    xor r13, r13                    ; 논리 인덱스(개행 제외)
.loop:
    mov rax, r13
    xor rdx, rdx                    ; 열
    div r12
    mov r15, rax                    ; 행


    ; 테두리 플래그 초기화
    xor r9, r9      ; 상하: 상=1, 하=2
    xor r10, r10    ; 좌우: 좌=1, 우=2

.is_top_or_bottom:
    cmp r15, 0
    je .it_is_top
    cmp r15, r8
    je .it_is_bottom
    jmp .is_left_or_right
.it_is_top:
    mov r9, 1
    jmp .is_left_or_right
.it_is_bottom:
    mov r9, 2


.is_left_or_right:
    cmp rdx, 0
    je .it_is_left
    cmp rdx, r8
    je .it_is_right
    jmp .set_character
.it_is_left:
    mov r10, 1
    jmp .set_character
.it_is_right:
    mov r10, 2



.set_character:
    ; 테두리인지 계산
    mov rax, r9
    or rax, r10
    test rax, rax
    jz .put_space
    

    cmp r9, 0
    je .put_vertical
    cmp r10, 0
    je .put_horizon

    cmp r9, 1
    je .vertex_top
    jmp .vertex_bottom

    

.put_space:
    mov rax, 0
    jmp .fill_cell
.put_horizon:
    mov rax, 2
    jmp .fill_cell
.put_vertical:
    mov rax, 3
    jmp .fill_cell


.vertex_top:
    cmp r10, 1
    jne .put_vertex_right_top
.put_vertex_left_top:
    mov rax, 4
    jmp .fill_cell
.put_vertex_right_top:
    mov rax, 5
    jmp .fill_cell

.vertex_bottom:
    cmp r10, 1
    jne .put_vertex_right_bottom
.put_vertex_left_bottom:
    mov rax, 6
    jmp .fill_cell
.put_vertex_right_bottom:
    mov rax, 7
    jmp .fill_cell


.fill_cell:
    mov r14, rdi
    mov rsi, r13
    mov rdx, rax
    call insert_char_to_index
    mov rdi, r14

    cmp r10, 2
    jne .next_cell

    mov rdi, r13
    call logical_index_to_real_index
    mov rdi, r14

    add rax, 3
    mov byte [rdi+rax], 0xa

.next_cell:
    inc r13

    mov rax, r12
    imul rax, r12
    cmp r13, rax
    jl .loop


.ret:
    mov rax, r13
    imul rax, 3
    add rax, r15
    inc rax         ; 마지막 줄바꿈 포함

    pop r15
    pop r14
    pop r13
    pop r12
    pop rbp

    ret
;






; 그리드 주소와 논리 인덱스를 주면 실제 인덱스 값을 플래그로 반환하는 함수
; input:
;   rdi = 그리드 주소
;   rsi = 논리 인덱스
; return:
;   rax = 해당 인덱스 값의 플래그
;   플래그 목록
;   0 = 죽은 세포`
;   1 = 산 세포
;   2 = 테두리
get_logic_index_value:
    push r12

    
    mov rax, rsi
    xor r12, r12
    mov r12d, dword [grid_var+Grid_var.map_size]
    xor rdx, rdx
    div r12
    mov r8, rax ; 행
    xor r9, r9

.retrive_index:
    ; 실제 인덱스 계산
    mov rax, rsi
    imul rax, 3 ; 논리 인덱스 1칸 = 3바이트
    add rax, r8 ; 개행 고려

    ; 마지막 바이트만 확인
    add rax, 2

    mov r9b, byte [rdi+rax]

    ; 플래그 초기화
    xor rax, rax

    ; 죽은 세포인지 확인
    cmp r9b, 0x82
    je .ret ; 죽은 세포면 플래그 반환: 0
    inc rax


    ; 산 세포인지 확인
    cmp r9b, 0x88
    je .ret ; 산 세포면 플래그 반환: 1
    inc rax
    
    ;   테두리 플래그 반환: 2

.ret:

    pop r12
    ret



;





; 그리드 주소와 기준 행렬을 받아 주변 8칸을 검사하고 살아 있는 세포 수를 반환하는 함수
; input:
;   rdi = 그리드 주소
;   rsi = 기준 행
;   rdx = 기준 열
; return:
;   rax = 살아 있는 세포 수
check_neighbor:
    push rbp
    mov rbp, rsp
    push r12
    push r13
    push r14
    push r15
    
    xor r12, r12
    mov r12d, dword [grid_var+Grid_var.map_size]

    mov r13, rsi     ; 기준 행
    mov r14, rdx     ; 기준 열

    xor r15, r15    ; 살아 있는 세포 수 저장

    
    mov r10, -1     ; 행 오프셋
.row_loop:
    mov r11, -1     ; 열 오프셋



.column_loop:
    cmp r10, 0
    jne .not_self
    cmp r11, 0
    jne .not_self

    ; 오프셋이 둘 다 0이면 자기 자신 -> 스킵
    jmp .next_column

.not_self:
    ; 상대 논리 인덱스 계산
    push rdi
    mov rdi, r13
    add rdi, r10
    mov rsi, r14
    add rsi, r11
    call row_and_column_to_logic_index
    pop rdi

    mov rsi, rax
    push rdx
    call get_logic_index_value
    pop rdx

    cmp rax, 1
    jne .next_column
    inc r15

.next_column:
    ; 열 오프셋 증가
    inc r11
    cmp r11, 2  ; 2가 아니면 루프
    jne .column_loop

    inc r10
    cmp r10, 2  ; 2가 아니면 루프
    jne .row_loop

.ret:
    mov rax, r15

    pop r15
    pop r14
    pop r13
    pop r12
    pop rbp
    ret

;


; 현재 그리드와 다음 그리드의 주소를 주면 현재를 기반으로 다음 세대의 그리드를 그리는 함수
; input:
;   rdi = 현재 그리드 주소
;   rsi = 다음 그리드 주소
; return:
;   rax = 다음 세대에 살아 있는 세포 수
to_next_grid:
    push rbp
    mov rbp, rsp
    push r12
    push r13
    push r14
    push r15



    mov rcx, 1                  ; 행
    xor r12, r12                ; 존재 가능 구역 크기
    mov r12d, dword [grid_var+Grid_var.epz_size]
    xor r8, r8                  ; 현재 인덱스의 상태
    xor r9, r9                  ; 현재 인덱스 주변에 살아 있는 세포 수
    xor r10, r10                ; 다음 세대에 살아 있는 세포 수
    xor r11, r11                ; 현재 논리 인덱스
    mov r13, rdi
    mov r14, rsi
.EPZ_row_loop:
    mov rdx, 1  ; 열
.EPZ_column_loop:
    mov rdi, rcx    ; 행 전달
    mov rsi, rdx    ; 열 전달
    call row_and_column_to_logic_index
    mov r11, rax    ; 논리 인덱스

    push rdx
    mov rdi, r13
    mov rsi, r11
    call get_logic_index_value
    mov r8, rax
    pop rdx

    mov r15, rdx
    
    push r8
    push r10
    push r11
    mov rsi, rcx
    call check_neighbor
    pop r11
    pop r10
    pop r8
    mov rsi, r14

    mov r9, rax


    cmp r8, 0
    je .dead

.alive:
    cmp r9, 2
    jl .die
    cmp r9, 3
    jg .die
    
    inc r10
    jmp .next_cell

.die:
    push rcx
    mov rdi, rsi
    mov rsi, r11
    xor rdx, rdx
    call insert_char_to_index
    mov rdi, r13
    mov rdx, r15
    pop rcx


.dead:
    cmp r9, 3
    jne .next_cell

.live:
    push rcx
    mov rdi, rsi
    mov rsi, r11
    mov rdx, 1
    call insert_char_to_index
    mov rdi, r13
    mov rdx, r15
    pop rcx

    inc r10

.next_cell:
    inc rdx
    cmp rdx, r12
    jle .EPZ_column_loop

    inc rcx
    cmp rcx, r12
    jle .EPZ_row_loop

    
    ; 다음 상태를 현재 상태로 복사
    mov rdi, qword [grid_var+Grid_var.current_grid]
    mov rsi, qword [grid_var+Grid_var.next_grid]
    mov ecx, dword [grid_var+Grid_var.grid_size]
    rep movsb

.ret:
    mov rax, r10

    pop r15
    pop r14
    pop r13
    pop r12
    pop rbp
    ret


 
;
