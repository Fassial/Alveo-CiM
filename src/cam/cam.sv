// cam
`include "cam_defs.svh"

module cam #(
    parameter       CAM_WIDTH   =   32,
    parameter       CAM_DEPTH   =   16,
    localparam      CAM_INDEX_WIDTH     =   $clog2(CAM_DEPTH),
    localparam type cam_t       = logic[CAM_WIDTH-1:0]
) (
    // external signals
    input   logic   clk,
    input   logic   rst,

    // input data
    input   logic                       data_we,
    input   logic[CAM_INDEX_WIDTH-1:0]  data_idx,
    input   cam_t                       data_i,
    input   logic                       data_vld,

    // output index & data
    output  logic                       index_rdy,
    output  logic[CAM_INDEX_WIDTH-1:0]  index_o
);

// def interface for cam_cell
logic[CAM_DEPTH-1:0] data_match, cell_data_we;
// def interface for prior_mux
logic[CAM_DEPTH-1:0] match_line;
logic[CAM_INDEX_WIDTH-1:0] match_index;

// set cell_data_we
always_comb begin
    // default
    cell_data_we = '0;
    // set cell_data_we[data_idx] as 1
    cell_data_we[data_idx] = data_we;
end

// inst cam_cell
for (genvar i = 0; i < CAM_DEPTH; ++i) begin : gen_cam_cell
    cam_cell #(
        .CAM_WIDTH  ( CAM_WIDTH )
    ) cam_cell_inst (
        // external signals
        .clk,
        .rst,

        // input data
        .data_we    ( cell_data_we[i]   ),
        .data_vld,
        .data_i,

        // output match
        .data_match ( data_match[i]     )
    );
end

// inst prior_mux
prior_mux #(
    .MUX_WIDTH  ( CAM_DEPTH )
) prior_mux_inst (
    // input match_line
    .match_line,

    // output index
    .match_index
);
assign match_line = data_match;

// set output
assign index_o   = match_index;
assign index_rdy = |data_match;

endmodule

module cam_cell #(
    parameter       CAM_WIDTH   =   32,
    localparam type cam_t       = logic[CAM_WIDTH-1:0]
) (
    // external signals
    input   logic   clk,
    input   logic   rst,

    // input data
    input   logic   data_we,
    input   logic   data_vld,
    input   cam_t   data_i,

    // output match
    output  logic   data_match
);

// cell_data
cam_t cell_data, cell_data_n;
// cell_data_vld
logic cell_data_vld, cell_data_vld_n;

// assign output
// compare data_i & cell_data
// if all 0, data_i & cell_data match
assign data_match = (~|(cell_data ^ data_i)) && cell_data_vld;

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

endmodule
