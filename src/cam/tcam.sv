// tcam
`include "cam_defs.svh"

module tcam #(
    parameter       TCAM_WIDTH  =   32,
                    TCAM_DEPTH  =   16,
    localparam      TCAM_INDEX_WIDTH    =   $clog2(TCAM_DEPTH)
) (
    // external signals
    input   logic   clk,
    input   logic   rst,

    // input data
    input   logic                       data_we,
    input   logic[TCAM_INDEX_WIDTH-1:0] data_idx,
    input   logic[TCAM_WIDTH-1:0]       data_i,
    input   logic[TCAM_WIDTH-1:0]       data_mask,

    // output index & data
    output  logic                       index_rdy,
    output  logic[TCAM_INDEX_WIDTH-1:0] index_o,
    output  logic[TCAM_WIDTH-1:0]       data_o
);

// def interface for tcam_cell
logic[TCAM_DEPTH-1:0] data_match, cell_data_we;
logic[TCAM_WIDTH-1:0] cell_data_o[TCAM_DEPTH-1:0];
// def interface for prior_mux
logic[TCAM_DEPTH-1:0] match_line;
logic[TCAM_INDEX_WIDTH-1:0] match_index;

// set cell_data_we
always_comb begin
    // default
    cell_data_we = '0;
    // set cell_data_we[data_idx] as 1
    cell_data_we[data_idx] = data_we;
end

// inst tcam_cell
for (genvar i = 0; i < TCAM_DEPTH; ++i) begin : gen_tcam_cell
    tcam_cell #(
        .TCAM_WIDTH ( TCAM_WIDTH )
    ) tcam_cell_inst (
        // external signals
        .clk,
        .rst,

        // input data
        .data_we    ( cell_data_we[i]   ),
        .data_i,
        .data_mask,

        // output match
        .data_match ( data_match[i]     ),
        .data_o     ( cell_data_o[i]    )
    );
end

// inst prior_mux
prior_mux #(
    .MUX_WIDTH  ( TCAM_DEPTH    )
) prior_mux_inst (
    .*
);
assign match_line = data_match;

// set output
assign index_o   = match_index;
assign index_rdy = |data_match;
assign data_o    = cell_data_o[data_idx];

endmodule

module tcam_cell #(
    parameter       TCAM_WIDTH  =   32
) (
    // external signals
    input   logic   clk,
    input   logic   rst,

    // input data
    input   logic                   data_we,
    input   logic[TCAM_WIDTH-1:0]   data_i,
    input   logic[TCAM_WIDTH-1:0]   data_mask,

    // output match & cell_data
    output  logic                   data_match,
    output  logic[TCAM_WIDTH-1:0]   data_o
);

// cell_data
logic[TCAM_WIDTH-1:0] cell_data, cell_data_n;

// assign output
// compare data_i & cell_data
// if all 0, data_i & cell_data match
assign data_match = ~|((cell_data ^ data_i) & data_mask);
// set data_o
assign data_o     = cell_data;

// update cell_data_n
always_comb begin
    // default
    cell_data_n = cell_data;
    if (data_we) cell_data_n = data_i;
end

// update cell_data
always_ff @ (posedge clk) begin
    if (rst) cell_data <= '0;
    else     cell_data <= cell_data_n;
end

endmodule
