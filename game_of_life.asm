section .rodata
    guide: db "input map size: "
    guide_len: equ $ - guide

    min_max_guide: db "map size must be between 10 and 50.", 0xa
    min_max_guide_len: equ $ - min_max_guide

    input_grid_guide: db "input whole map:", 0xa, 0xa
    input_grid_guide_len: equ $ - input_grid_guide

    clear: db 0x1b, '[2J', 0x1b, '[H'
    clear_len: equ $ - clear


    SPACE: db 0xe2, 0x80, 0x82
    SQUARE: db 0xe2, 0x96, 0x88
    HORIZON_BAR: db 0xe2, 0x94, 0x81
    VERTICAL_BAR: db 0xe2, 0x94, 0x83
    VERTEX_LEFT_TOP: db 0xe2, 0x94, 0x8f
    VERTEX_RIGHT_TOP: db 0xe2, 0x94, 0x93
    VERTEX_LEFT_BOTTOM: db 0xe2, 0x94, 0x97
    VERTEX_RIGHT_BOTTOM: db 0xe2, 0x94, 0x9b

    CHARS: dq SPACE, SQUARE, \
    HORIZON_BAR, VERTICAL_BAR, \
    VERTEX_LEFT_TOP, VERTEX_RIGHT_TOP, \
    VERTEX_LEFT_BOTTOM, VERTEX_RIGHT_BOTTOM


section .bss
    grid_size: resd 1
    map_size: resd 1
    EPZ_size: resd 1
    input_N: resb 2
    input_map: resb 50

    current_grid: resb 8427 ; 53 * 53 * 3
    next_grid: resb 8427

section .text
    global _start


_start:
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
    mov dword [EPZ_size], eax
    add rax, 2  ; 테두리 포함
    mov dword [map_size], eax
    mov r12, rax    ; 이 스코프에서 씀
    
    ; 초기 테두리 세팅
    mov rdi, current_grid
    call grid_set

    mov rdi, next_grid
    call grid_set

    mov dword [grid_size], eax


    ;mov rdx, rax
    ;mov rax, 1
    ;mov rdi, 1
    ;mov rsi, current_grid
    ;syscall





    mov r12d, dword [EPZ_size]
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
    mov rax, r12
    add rax, 2
    imul rax, r8
    add rax, r10
    
    push rcx
    mov rdi, current_grid
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
    mov rsi, current_grid
    mov edx, dword [grid_size]
    syscall

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







; 행과 열을 주면 논리 인덱스를 반환하는 함수
; 변경하는 레지스터: rax
; input:
;   rdi = 행
;   rsi = 열
; return:
;   rax = 논리 인덱스
row_and_column_to_logic_index:
    push rbx
    mov rax, rdi
    xor rbx, rbx
    mov ebx, dword [map_size]
    imul rax, rbx
    add rax, rsi
    pop rbx
    ret
;










; 논리 인덱스를 주면 실제 인덱스를 반환하는 함수
; 변경하는 레지스터: rdi, rax, rdx
; input:
;   rdi = 논리 인덱스
; return:
;   rax = 실제 인덱스
logical_index_to_real_index:
    push rbx

    mov rax, rdi
    xor rbx, rbx
    mov ebx, dword [map_size]
    xor rdx, rdx
    
    div rbx
    ; rax = 행

    imul rdi, 3
    add rax, rdi
    ; rax = 행 + LI * 3 = RI

    pop rbx
    ret


;




; 그리드 주소, 논리 인덱스, 문자 인덱스를 주면 해당 문자를 써주는 함수
; 변경하는 레지스터: rdi, rsi, rcx
; input:
;   rdi = 그리드 주소
;   rsi = 논리 인덱스
;   rdx = CHARS에서의 문자 인덱스
insert_char_to_index:
    push rdx
    push rdi
    mov rdi, rsi
    call logical_index_to_real_index
    pop rdi
    ; 논리 인덱스 사용 끝

    pop rdx
    mov rsi, qword [CHARS+rdx*8]
    lea rdi, [rdi+rax]
    mov rcx, 3
    rep movsb 
    
    ret




;



; 그리드의 틀을 채우는 함수
; 변경하는 레지스터: rsi, rax, rcx, rdx, r8, r9, r10, r11
; input:
;   rdi = 그리드 주소
; return:
;   rax = 실제 그리드 크기
grid_set:
.setup:
    push rbx

    xor rbx, rbx
    mov ebx, dword [map_size]  ; 맵 크기
    mov r8, rbx         ; N - 1
    dec r8    
    xor r11, r11        ; 논리 인덱스(개행 제외)
.loop:
    mov rax, r11
    xor rdx, rdx        ; 열
    div rbx
    mov rcx, rax        ; 행


    ; 테두리 플래그 초기화
    xor r9, r9      ; 상하: 상=1, 하=2
    xor r10, r10    ; 좌우: 좌=1, 우=2

.is_top_or_bottom:
    cmp rcx, 0
    je .it_is_top
    cmp rcx, r8
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
    push rdi
    mov rsi, r11
    mov rdx, rax
    call insert_char_to_index
    pop rdi

    cmp r10, 2
    jne .next_cell

    push rdi
    mov rdi, r11
    call logical_index_to_real_index
    pop rdi

    add rax, 3
    mov byte [rdi+rax], 0xa

.next_cell:
    inc r11

    mov rax, rbx
    imul rax, rbx
    cmp r11, rax
    jl .loop


.ret:
    mov rax, r11
    xor rdx, rdx    ; 열
    div rbx
    mov rcx, rax    ; 행

    mov rax, r11
    imul rax, 3
    add rax, rcx

    pop rbx
    ret
;






; 그리드 주소와 논리 인덱스를 주면 실제 인덱스 값을 플래그로 반환하는 함수
; 변경하는 레지스터: rax, rdx, r8, r9
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
.setup:
    push rbx

    mov rax, rsi
    xor rbx, rbx
    mov ebx, dword [map_size]
    xor rdx, rdx
    div rbx
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
    pop rbx
    ret



;







; 그리드 주소와 논리 인덱스, 플래그를 주면 실제 인덱스를 해당 플래그의 값으로 변경하는 함수
; 변경하는 레지스터: 
; input:
;   rdi = 그리드 주소
;   rsi = 논리 인덱스
;   rdx = 플래그
flag_to_index_value:
    push rdi
    push rsi
    push rdx
    push rcx
    cmp rdx, 1
    jg .not_space_or_square

    call insert_char_to_index

.not_space_or_square:

.ret:
    pop rcx
    pop rdx
    pop rsi
    pop rdi
    ret

;





; 그리드 주소와 기준 행렬을 받아 주변 8칸을 검사하고 살아 있는 세포 수를 반환하는 함수
; 변경하는 레지스터: rax, rsi, rdx, r8, r9, r10, r11
; input:
;   rdi = 그리드 주소
;   rsi = 기준 행
;   rdx = 기준 열
; return:
;   rax = 살아 있는 세포 수
check_neighbor:
.setup:
    push rbx
    
    xor rbx, rbx
    mov ebx, dword [map_size]

    mov r8, rsi     ; 기준 행
    mov r9, rdx     ; 기준 열

    xor rdx, rdx    ; 살아 있는 세포 수 저장

    
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
    mov rax, r8
    add rax, r10
    imul rax, rbx
    add rax, r9
    add rax, r11

    push rdx
    push r8
    push r9
    mov rsi, rax
    call get_logic_index_value
    pop r9
    pop r8
    pop rdx

    cmp rax, 1
    jne .next_column
    inc rdx

.next_column:
    ; 열 오프셋 증가
    inc r11
    cmp r11, 2  ; 2가 아니면 루프
    jne .column_loop

    inc r10
    cmp r10, 2  ; 2가 아니면 루프
    jne .row_loop

.ret:
    mov rax, rdx

    pop rbx
    ret
;


; 현재 그리드와 다음 그리드의 주소를 주면 현재를 기반으로 다음 세대의 그리드를 그리는 함수
; 변경하는 레지스터: rax, rcx, rdx, r8, r9, r10, r11
; input:
;   rdi = 현재 그리드 주소
;   rsi = 다음 그리드 주소
; return:
;   rax = 다음 세대에 살아 있는 세포 수
to_next_grid:
.setup:
    push rbx
    mov rcx, 1                  ; 행
    xor rbx, rbx                ; 존재 가능 구역 크기
    mov ebx, dword [EPZ_size]
    xor r8, r8                  ; 현재 인덱스의 상태
    xor r9, r9                  ; 현재 인덱스 주변에 살아 있는 세포 수
    xor r10, r10                ; 다음 세대에 살아 있는 세포 수
    xor r11, r11                ; 현재 논리 인덱스
.EPZ_row_loop:
    mov rdx, 1  ; 열
.EPZ_column_loop:
    push rsi
    push rdi
    mov rdi, rcx    ; 행 전달
    mov rsi, rdx    ; 열 전달
    call row_and_column_to_logic_index
    mov r11, rax    ; 논리 인덱스

    pop rdi
    mov rsi, r11
    call get_logic_index_value
    mov r8, rax

    push rdx
    push r8
    push r9
    push r10
    push r11
    mov rsi, rcx
    call check_neighbor
    pop r11
    pop r10
    pop r9
    pop r8
    pop rdx
    pop rsi

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
    push rdi
    push rdx
    mov rdi, rsi
    mov rsi, r11
    xor rdx, rdx
    call flag_to_index_value
    pop rdx
    pop rdi


.dead:
    cmp r9, 3
    jne .next_cell

.live:
    push rdi
    push rdx
    mov rdi, rsi
    mov rsi, r11
    xor rdx, 1
    call flag_to_index_value
    pop rdx
    pop rdi

    inc r10

.next_cell:
    inc rdx
    cmp rdx, rbx
    jle .EPZ_column_loop

    inc rcx
    cmp rcx, rbx
    jle .EPZ_row_loop

    
    ; 다음 상태를 현재 상태로 복사
    mov ecx, dword [grid_size]
    rep movsb

.ret:
    mov rax, r10
    pop rbx
    ret


 
;











; 지연 함수
; 변경하는 레지스터: rax, rdi, rsi, rdx
; input:
;   rdi = 초 단위
;   rsi = 밀리초 단위 (0~999)
sleep:
    sub rsp, 0x10

    ; tv_sec = rdi (초)
    mov [rsp], rdi

    ; tv_nsec = rsi * 1,000,000 (밀리초 -> 나노초)
    mov rax, rsi
    imul rax, 1000000
    mov [rsp+8], rax

    ; rdi = &req (timespec 주소)
    mov rdi, rsp

    ; rsi = NULL (rem 포인터 무시)
    xor esi, esi

    mov eax, 35       ; syscall: nanosleep
    syscall

    add rsp, 16       ; 스택 원상복구
    ret
;




; 숫자 문자열을 정수로 바꿔주는 함수
; 변경하는 레지스터: rax
; input:
;   rdi = 변환할 문자열 주소
; reuturn:
;   rax = 변환된 정수
atoi:
.setup:
    push rdi
    push rbx
    push rcx

    xor rax, rax
    xor rcx, rcx
    mov rbx, 10

.to_int: 
    mov al, byte [rdi]
    push rax    ; 참조한 메모리 값 저장
    cmp al, 0x0
    je .ret

    mov rax, rcx
    mul rbx
    mov rcx, rax

    pop rax     ; 재사용
    cmp al, 0x30
    jb .not_integer
    cmp al, 0x39
    ja .not_integer

    sub al, 0x30
    add rcx, rax
    inc rdi
    jmp .to_int

.not_integer:

.ret:
    pop rax     ; push 한 번 남은 것 제거
    mov rax, rcx
    
    pop rcx
    pop rbx
    pop rdi
    ret


;






; input:
;   rdi = 정수
;   rsi = 변환된 문자열을 쓸 버퍼
; return: 
;   rax = 변환된 문자열의 길이
itoa:
.setup:
    push rbx    ; div

    mov rbx, 10
    xor rcx, rcx
    xor rdx, rdx

    mov rax, rdi
    mov rdi, rsi


.push_last_number:
    ; 10으로 나누기
    div rbx

    ; 마지막 자리 수 추출
    add rdx, 0x30
    push rdx
    xor rdx, rdx

    ; 길이 증가
    inc rcx

    ; 몫이 0이 아니면 루프
    test rax, rax
    jnz .push_last_number

    ; 루프에 사용하기 전, 문자열 길이 임시 저장
    mov rdx, rcx


.pop_number_string:
    ; 변환된 문자열의 맨 앞부터 가져오기
    pop rax

    ; 문자를 버퍼에 쓰기
    mov byte [rdi], al
    inc rdi
    
    ; 문자열 길이만큼 반복
    loop .pop_number_string

.ret:
    ; 길이 반환
    mov rax, rdx

    pop rbx
    ret

;