// cim
`include "cim_defs.svh"

module cim #(
    parameter   N_GROUP     =   12,
    parameter   DATA_WIDTH  =   32,
    parameter   ALU_KIND    =   0
) (
    // external signals
    input   logic   clk,
    input   logic   rst
    // data_i
    // TODO
    // data_o
    // TODO
);

// inst ccg
// TODO

endmodule

module cim_cell_group #(
    parameter   N_GROUP     =   1,
    parameter   DATA_WIDTH  =   32,
    parameter   ALU_KIND    =   `ALU_KIND,      // 0,
    localparam  COUNT_WIDTH =   $clog2(N_GROUP) + 1,
    localparam  type data_t = logic[DATA_WIDTH-1:0]
) (
    // external signals
    input   logic   clk,
    input   logic   rst,
    // data w & b
    input   data_t  w_i,
    input   data_t  b_i,
    input   logic   update,
    // data_o
    output  data_t[N_GROUP-1:0] data_o
);

// define count
logic[COUNT_WIDTH-1:0] count, count_n;
// update count_n
always_comb begin
    count_n = count + 1'b1;
    if (count_n == N_GROUP) count_n = '0;
end
// update count
always_ff @ (posedge clk) begin
    if (rst)
        count <= '0;
    else if (update)
        count <= count_n;
end

// define interface for alu
data_t alu_a, alu_b, alu_c;
// define interface for cim_cell
logic[N_GROUP-1:0] ccg_update;
data_t ccg_data_i;
data_t[N_GROUP-1:0] ccg_data_o;
// inst alu
alu #(
    .DATA_WIDTH ( DATA_WIDTH    ),
    .ALU_KIND   ( ALU_KIND      )
) alu_inst (
    // data_i
    .a_i    ( alu_a ),
    .b_i    ( alu_b ),
    // data_o
    .c_o    ( alu_c )
);
assign alu_a = w_i;
assign alu_b = b_i;

// gen cim_cell group
for (genvar i = 0; i < N_GROUP; i++) begin : gen_cim_cell_group
    cim_cell #(
        .DATA_WIDTH ( DATA_WIDTH    )
    ) cim_cell_inst (
        // external signals
        .clk,
        .rst,
        // data_i
        .data_i ( ccg_data_i    ),
        .update ( ccg_update[i] ),
        // data_o
        .data_o ( ccg_data_o[i] )
    );
end
assign ccg_data_i = alu_c;
always_comb begin
    // default
    ccg_update = '0;
    ccg_update[count] = update;
end

// set output
assign data_o = ccg_data_o;

endmodule

module cim_cell #(
    parameter   DATA_WIDTH  =   32,
    localparam  type data_t = logic[DATA_WIDTH-1:0]
) (
    // external signals
    input   logic   clk,
    input   logic   rst,
    // data_i
    input   data_t  data_i,
    input   logic   update,
    // data_o
    output  data_t  data_o
);

// cell_data
data_t cell_data, cell_data_n;

// update cell_data_n
assign cell_data_n = cell_data + data_i;
// update cell_data
always_ff @ (posedge clk) begin
    if (rst)
        cell_data <= '0;
    else if (update)
        cell_data <= cell_data_n;
end

// assign output
assign data_o = cell_data;

endmodule
