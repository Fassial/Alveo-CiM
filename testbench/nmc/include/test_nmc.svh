`ifndef TEST_NMC_SVH
`define TEST_NMC_SVH

/*
    This header defines common constants in test_nmc module
*/

// testbench_defs
`include "testbench_defs.svh"

`ifdef PATH_PREFIX
`undef PATH_PREFIX
`endif
`define PATH_PREFIX "testbench/nmc/testcases/"
`DEF_FUNC_GET_PATH

`endif
