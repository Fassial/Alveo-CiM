// tcam
`include "cam_defs.svh"

module tcam_top #(
    parameter       KEY_WIDTH   =   `KEY_WIDTH,
    parameter       KEY_DEPTH   =   `KEY_DEPTH,
    parameter       VALUE_WIDTH =   `VALUE_WIDTH,
    parameter       VALUE_DEPTH =   `VALUE_DEPTH
) (
    // external signals
    input   logic   clk,
    input   logic   rst,

    // input tcam_top_req
    input   tcam_top_req_t  tcam_top_req,

    // output tcam_top_resp
    output  tcam_top_resp_t tcam_top_resp
);

// define interface for tcam
tcam_req_t tcam_req;
tcam_resp_t tcam_resp;
// define interface for value_sram
logic vs_we;
cam_addr_t vs_addr;
cam_value_t vs_data_i, vs_data_o;

// inst tcam
tcam #(
    .KEY_WIDTH  ( KEY_WIDTH ),
    .KEY_DEPTH  ( KEY_DEPTH )
) tcam_inst (
    // external signals
    .clk,
    .rst,

    // input tcam_req
    .tcam_req,

    // output tcam_resp
    .tcam_resp
);
assign tcam_req = tcam_top_req.tcam_req;
// inst value_sram
single_port_ram #(
    .SIZE   ( VALUE_DEPTH   ),
    .dtype  ( cam_value_t       )
) value_sram (
    // external signals
    .clk,
    .rst,
    // input query
    .we     ( vs_we     ),
    .addr   ( vs_addr   ),
    .din    ( vs_data_i ),
    // output data
    .dout   ( vs_data_o )
);
assign vs_we     = tcam_top_req.we;
assign vs_addr   = tcam_top_req.we ? tcam_top_req.addr : tcam_resp.addr;
assign vs_data_i = tcam_top_req.data;

// inner signals
tcam_top_resp_t pipe1_tcam_top_resp, pipe1_tcam_top_resp_n;

// update pipe1_tcam_top_resp_n
always_comb begin
    // defualt
    pipe1_tcam_top_resp_n = '0;
    // set data_vld
    pipe1_tcam_top_resp_n.data_vld = tcam_resp.addr_vld;
    // set tcam_resp
    pipe1_tcam_top_resp_n.tcam_resp = tcam_resp;
end
// update pipe1_tcam_top_resp
always_ff @ (posedge clk) begin
    if (rst)    pipe1_tcam_top_resp <= '0;
    else        pipe1_tcam_top_resp <= pipe1_tcam_top_resp_n;
end

// set output
assign tcam_top_resp.data      = vs_data_o;
assign tcam_top_resp.data_vld  = pipe1_tcam_top_resp.data_vld;
assign tcam_top_resp.tcam_resp = pipe1_tcam_top_resp.tcam_resp;

endmodule
