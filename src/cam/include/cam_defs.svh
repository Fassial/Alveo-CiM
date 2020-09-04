`ifndef CAM_DEFS_SVH
`define CAM_DEFS_SVH

/*
    This header defines common data structrue & constants in cam module
*/

// common defs
`include "common_defs.svh"

// struct for cam
typedef struct packed {
    // we & addr_vld & data_vld signal
    logic we, addr_vld, data_vld;
    // access addr
    cam_addr_t addr;
    // data_i
    cam_key_t data;
} cam_req_t;
typedef struct packed {
    // addr_vld & data_vld signal
    logic addr_vld, data_vld;
    // prior-match addr
    cam_addr_t addr;
    // data_o
    cam_key_t data;
} cam_resp_t;

// struct for cam_top
typedef struct packed {
    // we signal
    logic we;
    // access addr
    cam_addr_t addr;
    // data_i
    cam_value_t data;
    // cam_req
    cam_req_t cam_req;
} cam_top_req_t;
typedef struct packed {
    // data_vld signal
    logic data_vld;
    // data_o
    cam_value_t data;
    // cam_resp
    cam_resp_t cam_resp;
} cam_top_resp_t;

// struct for tcam
typedef struct packed {
    // we & addr_vld & data_vld signal
    logic we, addr_vld, data_vld;
    // access addr
    cam_addr_t addr;
    // data_i & mask
    cam_key_t data, mask;
} tcam_req_t;
typedef struct packed {
    // addr_vld & data_vld signal
    logic addr_vld, data_vld;
    // prior-match addr
    cam_addr_t addr;
    // data_o
    cam_key_t data;
} tcam_resp_t;

// struct for tcam_top
typedef struct packed {
    // we signal
    logic we;
    // access addr
    cam_addr_t addr;
    // data_i
    cam_value_t data;
    // tcam_req
    tcam_req_t tcam_req;
} tcam_top_req_t;
typedef struct packed {
    // data_vld signal
    logic data_vld;
    // data_o
    cam_value_t data;
    // tcam_resp
    tcam_resp_t tcam_resp;
} tcam_top_resp_t;

`endif
