%include "structs.inc"

global guide, guide_len
global min_max_guide, min_max_guide_len
global input_grid_guide, input_grid_guide_len
global clear, clear_len
global CHARS
global input_N, input_map
global current_grid, next_grid
global generation_print, generation_print_len
global survived_cell_count, survived_cell_count_len
global max_cell_count, max_cell_count_len
global grid_var
global write_buffer

section .rodata
    guide: db "input map size: "
    guide_len: equ $ - guide

    
    min_max_guide: db "map size must be between 10 and 50.", 0xa
    min_max_guide_len: equ $ - min_max_guide

    
    input_grid_guide: db "input whole map:", 0xa, 0xa
    input_grid_guide_len: equ $ - input_grid_guide

    
    clear: db 0x1b, '[2J', 0x1b, '[H'
    clear_len: equ $ - clear

    
    generation_print: db "Generation: "
    generation_print_len: equ $ - generation_print


    survived_cell_count: db "Cells: "
    survived_cell_count_len: equ $ - survived_cell_count

    max_cell_count: db "Max cells: "
    max_cell_count_len: equ $ - max_cell_count


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
    input_N: resb 2
    input_map: resb 50

    current_grid: resb 8427 ; 53 * 53 * 3
    next_grid: resb 8427

    grid_var: resb Grid_var_size

    write_buffer: resb 0x30

