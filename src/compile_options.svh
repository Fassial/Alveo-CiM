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
// define for cim
`define ALU_KIND            0
// define for cam
`define KEY_WIDTH           32
`define KEY_DEPTH           16
`define VALUE_WIDTH         32
`define VALUE_DEPTH         `KEY_DEPTH

// define non-value macro

`endif
