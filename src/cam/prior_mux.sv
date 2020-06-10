// prior_mux
`include "cam_defs.svh"

module prior_mux #(
    parameter       MUX_WIDTH   =   16,
    localparam      MUX_INDEX   =   $clog2(MUX_WIDTH)
) (
    // input match_line
    input   logic[MUX_WIDTH-1:0]    match_line,

    // output index
    output  logic[MUX_INDEX-1:0]    match_index
);

// TODO
// inst prior_mux16
prior_mux16 #(

) prior_mux16_inst (
    .*
);

endmodule

module prior_mux16 #(
    // localparam, cannot change
    localparam      MUX_WIDTH   =   16,
    localparam      MUX_INDEX   =   $clog2(MUX_WIDTH)
) (
    // input match_line
    input   logic[MUX_WIDTH-1:0]    match_line,

    // output index
    output  logic[MUX_INDEX-1:0]    match_index
);

always_comb begin
    casez (match_line)
        16'b????_????_????_???1: match_index = 4'd00;
        16'b????_????_????_??10: match_index = 4'd01;
        16'b????_????_????_?100: match_index = 4'd02;
        16'b????_????_????_1000: match_index = 4'd03;
        16'b????_????_???1_0000: match_index = 4'd04;
        16'b????_????_??10_0000: match_index = 4'd05;
        16'b????_????_?100_0000: match_index = 4'd06;
        16'b????_????_1000_0000: match_index = 4'd07;
        16'b????_???1_0000_0000: match_index = 4'd08;
        16'b????_??10_0000_0000: match_index = 4'd09;
        16'b????_?100_0000_0000: match_index = 4'd10;
        16'b????_1000_0000_0000: match_index = 4'd11;
        16'b???1_0000_0000_0000: match_index = 4'd12;
        16'b??10_0000_0000_0000: match_index = 4'd13;
        16'b?100_0000_0000_0000: match_index = 4'd14;
        16'b1000_0000_0000_0000: match_index = 4'd15;
    endcase
end

endmodule
