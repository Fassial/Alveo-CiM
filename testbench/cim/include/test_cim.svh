`ifndef TEST_CIM_SVH
`define TEST_CIM_SVH

/*
    This header defines common constants in test_cim module
*/

// testbench_defs
`include "testbench_defs.svh"

`ifdef PATH_PREFIX
`undef PATH_PREFIX
`endif
`define PATH_PREFIX "testbench/cim/testcases/"
`DEF_FUNC_GET_PATH

`endif
