// tcam
`include "cam_defs.svh"

module tcam #(
    parameter       TCAM_WIDTH  =   32,
    parameter       TCAM_DEPTH  =   16,
    localparam      TCAM_INDEX_WIDTH    =   $clog2(TCAM_DEPTH),
    localparam type tcam_t      = logic[TCAM_WIDTH-1:0],
    localparam type camml_t     = logic[TCAM_DEPTH-1:0]
) (
    // external signals
    input   logic   clk,
    input   logic   rst,

    // input data
    input   logic                       data_we,
    input   logic[TCAM_INDEX_WIDTH-1:0] data_idx,
    input   tcam_t                      data_i,
    input   tcam_t                      data_mask,
    input   logic                       data_vld,

    // output index & data
    output  logic                       index_rdy,
    `ifdef PRIORMUX_ENABLED
    output  logic[TCAM_INDEX_WIDTH-1:0] index_o
    `else
    output  camml_t                     camml_o
    `endif
);

// def interface for tcam_cell
camml_t data_match, cell_data_we;
// def interface for prior_mux
camml_t match_line;
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
        .TCAM_WIDTH ( TCAM_WIDTH    )
    ) tcam_cell_inst (
        // external signals
        .clk,
        .rst,

        // input data
        .data_we    ( cell_data_we[i]   ),
        .data_vld,
        .data_i,
        .data_mask,

        // output match
        .data_match ( data_match[i]     )
    );
end

`ifdef PRIORMUX_ENABLED
// inst prior_mux
prior_mux #(
    .MUX_WIDTH  ( TCAM_DEPTH    )
) prior_mux_inst (
    // input match_line
    .match_line,

    // output index
    .match_index
);
assign match_line = data_match;
`endif

// set output
`ifdef PRIORMUX_ENABLED
assign index_o   = match_index;
`else
assign camml_o   = data_match;
`endif
assign index_rdy = |data_match;

endmodule

module tcam_cell #(
    parameter       TCAM_WIDTH  =   32,
    localparam type tcam_t      = logic[TCAM_WIDTH-1:0]
) (
    // external signals
    input   logic   clk,
    input   logic   rst,

    // input data
    input   logic   data_we,
    input   logic   data_vld,
    input   tcam_t  data_i,
    input   tcam_t  data_mask,

    // output match
    output  logic   data_match
);

// cell_data
tcam_t cell_data, cell_data_n;
// cell_data_mask
tcam_t cell_data_mask, cell_data_mask_n;
// cell_data_vld
logic cell_data_vld, cell_data_vld_n;

// assign output
// compare data_i & cell_data
// if all 0, data_i & cell_data match
assign data_match = (~|((cell_data ^ data_i) & cell_data_mask)) && cell_data_vld;

// update cell_data_n & cell_data_mask_n & cell_data_vld_n
assign cell_data_n      = data_i;
assign cell_data_mask_n = data_mask;
assign cell_data_vld_n  = data_vld;

// update cell_data
always_ff @ (posedge clk) begin
    if (rst) begin
        cell_data       <= '0;
        cell_data_mask  <= '0;
        cell_data_vld   <= 1'b0;
    end else if (data_we) begin
        cell_data       <= cell_data_n;
        cell_data_mask  <= cell_data_mask_n;
        cell_data_vld   <= cell_data_vld_n;
    end
end

endmodule
