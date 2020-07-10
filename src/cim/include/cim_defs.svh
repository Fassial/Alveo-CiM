`ifndef CIM_DEFS_SVH
`define CIM_DEFS_SVH

/*
    This header defines common data structrue & constants in cim module
*/

// common defs
`include "common_defs.svh"

// def funcs
`define DEF_FUNC_GET_INDEX function index_t get_index( input addr_t addr ); \
    return addr[GROUP_WIDTH + CELL_WIDTH - 1 : CELL_WIDTH]; \
endfunction
`define DEF_FUNC_GET_OFFSET function offset_t get_offset( input addr_t addr ); \
    return addr[CELL_WIDTH - 1 : 0]; \
endfunction

// def structs
typedef enum logic [1:0] {
    CIM_IDLE,
    CIM_WRITE,
    CIM_CAL
} cim_state_t;

`endif
