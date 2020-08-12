`ifndef NMC_DEFS_SVH
`define NMC_DEFS_SVH

/*
    This header defines common data structrue & constants in nmc module
*/

// common defs
`include "common_defs.svh"

// def funcs
`define DEF_FUNC_GET_INDEX function nmc_index_t get_index( input nmc_addr_t addr ); \
    return addr[$clog2(`N_NMC*`N_NMC_CELL)-1:$clog2(`N_NMC_CELL)]; \
endfunction
`define DEF_FUNC_GET_OFFSET function nmc_offset_t get_offset( input nmc_addr_t addr ); \
    return addr[$clog2(`N_NMC_CELL)-1:0]; \
endfunction

// def structs
typedef enum logic [2:0] {
    NMC_IDLE,
    NMC_QUERY,
    NMC_CAL,
    NMC_RES,
    NMC_WRITE
} nmc_state_t;

`endif
