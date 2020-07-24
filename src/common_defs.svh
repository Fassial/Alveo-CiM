`ifndef COMMON_DEFS_SVH
`define COMMON_DEFS_SVH

/*
    This header defines common data structrue & constants in the whole soc
*/

// project configuration
`default_nettype wire
`timescale 1ns / 1ps

// compile_options
`include "compile_options.svh"

// def struct
// def struct for cam
typedef logic[$clog2(`KEY_DEPTH)-1:0]   addr_t;
typedef logic[`KEY_WIDTH-1:0]           cam_t;
typedef logic[`VALUE_WIDTH-1:0]         value_t;

`endif
