`ifndef TEST_CAM_SVH
`define TEST_CAM_SVH

/*
    This header defines common constants in test_cam module
*/

// testbench_defs
`include "testbench_defs.svh"

`ifdef PATH_PREFIX
`undef PATH_PREFIX
`endif
`define PATH_PREFIX "testbench/cam/testcases/"
`DEF_FUNC_GET_PATH

// define test target
`define TEST_CAM        0
`define TEST_TCAM       1
`define CAM_TEST_TARGET `TEST_TCAM

`endif
