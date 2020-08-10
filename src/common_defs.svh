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

// common struct
typedef logic[31:0] uint32_t;

// def struct
typedef logic[`FEATURE_WIDTH-1:0]       feature_t;
// def struct for cam
typedef logic[$clog2(`KEY_DEPTH)-1:0]   cam_addr_t;
typedef logic[`KEY_WIDTH-1:0]           cam_key_t;
typedef logic[`VALUE_WIDTH-1:0]         cam_value_t;
// def struct for nmc
typedef logic[$clog2(`N_NMC)-1:0]               nmc_index_t;
typedef logic[$clog2(`N_NMC_CELL)-1:0]          nmc_offset_t;
typedef logic[$clog2(`N_NMC_CELL*`N_NMC)-1:0]   nmc_addr_t;
typedef feature_t                               nmc_feature_t;
typedef logic[`RESULT_WIDTH-1:0]                nmc_result_t;
typedef struct packed {
    nmc_offset_t id;
    nmc_feature_t feature;
    nmc_result_t result;
} nmc_entry_t;
typedef struct packed {
    nmc_addr_t addr;
    nmc_entry_t entry;
} nmc_wr_req_t;
typedef struct packed {
    logic id_vld;   // set 0
    nmc_offset_t id;
    nmc_addr_t addr;
    feature_t feature;
} nmc_qr_req_t;
typedef struct packed {
    logic valid, found;
    nmc_result_t result;
} nmc_qr_resp_t;

`endif
