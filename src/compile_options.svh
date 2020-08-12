`ifndef COMPILE_OPTIONS_SVH
`define COMPILE_OPTIONS_SVH

/**
    Options to control optional components to be compiled
    These options are used to speed up compilation when debugging
**/

// enable all func unit
`define COMPILE_FULL_M
`ifdef COMPILE_FULL_M
    `define COMPILE_FULL    1
`else
    `define COMPILE_FULL    0
`endif

// define associate to COMPILE_FULL

// define not associate to COMPILE_FULL
`define N_PART_FEATURE      32
`define N_FEATURE           1024
// define for nmc
`define ALU_KIND            2
`define N_NMC               8
`define N_NMC_CELL          128
`define RESULT_WIDTH        32
`define NWR_FIFO_DEPTH      8
`define NQR_FIFO_DEPTH      16
`define NMC_CAL_THRES       32'h3f800000    // 32 float_t
// define for cam
`define KEY_WIDTH           48
`define KEY_DEPTH           16384
`define VALUE_WIDTH         32
`define VALUE_DEPTH         `KEY_DEPTH

// define non-value macro

`endif
