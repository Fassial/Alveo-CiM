`ifndef COUNT_BIT_SVH
`define COUNT_BIT_SVH

/*
    This header defines common data structrue & constants in count_bit module
*/

// nmc defs
`include "nmc_defs.svh"

// define struct for cb
typedef enum logic[1:0] {
    CB_IDLE,
    CB_COUNT,
    CB_FINISH
} cb_state_t;

`endif
