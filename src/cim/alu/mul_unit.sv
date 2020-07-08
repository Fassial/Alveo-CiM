// mul_unit
`include "alu_defs.svh"

module mul_unit #(
    parameter   DATA_WIDTH  =   32,
    parameter   ALU_KIND    =   0
) (
    // data_i
    input   logic[DATA_WIDTH-1:0]   a_i,
    input   logic[DATA_WIDTH-1:0]   b_i,
    // data_o
    output  logic[DATA_WIDTH-1:0]   c_o
);

logic [DATA_WIDTH*2-1:0] res;
// get mul of a_i & b_i
// temp use * instead of ip
assign res = a_i * b_i;

// set output
assign c_o = res[DATA_WIDTH-1:0];

endmodule
