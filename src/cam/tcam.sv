// tcam
`include "cam_defs.svh"

module tcam #(
    parameter       KEY_WIDTH   =   `KEY_WIDTH,
    parameter       KEY_DEPTH   =   `KEY_DEPTH
) (
    // external signals
    input   logic   clk,
    input   logic   rst,

    // input tcam_req
    input   tcam_req_t  tcam_req,

    // output tcam_resp
    output  tcam_resp_t tcam_resp
);

// def interface for tcam_cell
logic[KEY_DEPTH-1:0] data_match, data_we;
cam_key_t[KEY_DEPTH-1:0] data_o;
// def interface for prior_mux
logic[KEY_DEPTH-1:0] match_line;
cam_addr_t match_index;

// set data_we
always_comb begin
    // default
    data_we = '0;
    // set data_we[data_idx] as 1
    data_we[tcam_req.addr] = tcam_req.addr_vld & tcam_req.we;
end

// inst tcam_cell
for (genvar i = 0; i < KEY_DEPTH; ++i) begin : gen_tcam_cell
    tcam_cell #(
        .KEY_WIDTH  ( KEY_WIDTH     )
    ) tcam_cell_inst (
        // external signals
        .clk,
        .rst,

        // input data
        .data_we    ( data_we[i]        ),
        .data_vld   ( tcam_req.data_vld ),
        .data_i     ( tcam_req.data     ),
        .data_mask  ( tcam_req.mask     ),

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
assign tcam_resp.addr     = match_index;
assign tcam_resp.addr_vld = |data_match;
assign tcam_resp.data     = data_o[tcam_req.addr];
assign tcam_resp.data_vld = tcam_req.addr_vld & ~tcam_req.we;

endmodule

module tcam_cell #(
    parameter       KEY_WIDTH   =   `KEY_WIDTH
) (
    // external signals
    input   logic   clk,
    input   logic   rst,

    // input data
    input   logic       data_we,
    input   logic       data_vld,
    input   cam_key_t   data_i,
    input   cam_key_t   data_mask,

    // output match & data
    output  logic       data_match,
    output  cam_key_t   data_o
);

// cell_data
cam_key_t cell_data, cell_data_n;
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
assign data_match = (~|((cell_data ^ data_i) & data_mask)) && cell_data_vld;

endmodule
