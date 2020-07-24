// cam
`include "cam_defs.svh"

module cam #(
    parameter       KEY_WIDTH   =   32,
    parameter       KEY_DEPTH   =   16
) (
    // external signals
    input   logic   clk,
    input   logic   rst,

    // input cam_req
    input   cam_req_t   cam_req,

    // output cam_resp
    output  cam_resp_t  cam_resp
);

// def interface for cam_cell
logic[KEY_DEPTH-1:0] data_match, data_we;
cam_t[KEY_DEPTH-1:0] data_o;
// def interface for prior_mux
logic[KEY_DEPTH-1:0] match_line;
addr_t match_index;

// set data_we
always_comb begin
    // default
    data_we = '0;
    // set data_we[data_idx] as 1
    data_we[cam_req.addr] = cam_req.addr_vld & cam_req.we;
end

// inst cam_cell
for (genvar i = 0; i < KEY_DEPTH; ++i) begin : gen_cam_cell
    cam_cell #(
        .KEY_WIDTH  ( KEY_WIDTH     )
    ) cam_cell_inst (
        // external signals
        .clk,
        .rst,

        // input data
        .data_we    ( data_we[i]        ),
        .data_vld   ( cam_req.data_vld  ),
        .data_i     ( cam_req.data      ),

        // output match
        .data_match ( data_match[i]     ),
        .data_o     ( data_o[i]         )
    );
end

// inst prior_mux
prior_mux #(
    .MUX_WIDTH  ( KEY_DEPTH )
) prior_mux_inst (
    // input match_line
    .match_line,

    // output index
    .match_index
);
assign match_line = data_match;

// set output
assign cam_resp.addr     = match_index;
assign cam_resp.addr_vld = |data_match;
assign cam_resp.data     = data_o[cam_req.addr];
assign cam_resp.data_vld = cam_req.addr_vld & ~cam_req.we;

endmodule

module cam_cell #(
    parameter       KEY_WIDTH   =   32
) (
    // external signals
    input   logic   clk,
    input   logic   rst,

    // input data
    input   logic   data_we,
    input   logic   data_vld,
    input   cam_t   data_i,

    // output match
    output  logic   data_match,
    output  cam_t   data_o
);

// cell_data
cam_t cell_data, cell_data_n;
// cell_data_vld
logic cell_data_vld, cell_data_vld_n;

// update cell_data_n & cell_data_vld_n
assign cell_data_n      = data_i;
assign cell_data_vld_n  = data_vld;

// update cell_data
always_ff @ (posedge clk) begin
    if (rst) begin
        cell_data       <= '0;
        cell_data_vld   <= 1'b0;
    end else if (data_we) begin
        cell_data       <= cell_data_n;
        cell_data_vld   <= cell_data_vld_n;
    end
end

// assign output
assign data_o = cell_data;
// compare data_i & cell_data
// if all 0, data_i & cell_data match
assign data_match = (~|(cell_data ^ data_i)) && cell_data_vld;

endmodule
