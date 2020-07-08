// alu
`include "alu_defs.svh"

module alu #(
    parameter   DATA_WIDTH  =   32,
    parameter   ALU_KIND    =   0
) (
    // data_i
    input   logic[DATA_WIDTH-1:0]   a_i,
    input   logic[DATA_WIDTH-1:0]   b_i,
    // data_o
    output  logic[DATA_WIDTH-1:0]   c_o
);

// define interface for alu_sub(xnor_unit & mul_unit)
logic[DATA_WIDTH-1:0] alu_a, alu_b, alu_c;
// inst alu_sub
generate if (ALU_KIND == 0) begin
    xnor_unit #(
        .DATA_WIDTH ( DATA_WIDTH    ),
        .ALU_KIND   ( ALU_KIND      )
    ) xnor_unit_inst (
        // data_i
        .a_i    ( alu_a ),
        .b_i    ( alu_b ),
        // data_o
        .c_o    ( alu_c )
    );
end else if (ALU_KIND == 1) begin
    mul_unit #(
        .DATA_WIDTH ( DATA_WIDTH    ),
        .ALU_KIND   ( ALU_KIND      )
    ) mul_unit_inst (
        // data_i
        .a_i    ( alu_a ),
        .b_i    ( alu_b ),
        // data_o
        .c_o    ( alu_c )
    );
end else begin
    // set '0
    assign alu_c = '0;
end endgenerate
// set interface
assign alu_a = a_i;
assign alu_b = b_i;
assign c_o = alu_c;

endmodule
