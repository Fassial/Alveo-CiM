// count_bit
`include "count_bit.svh"

module count_bit #(
    parameter type cb_data_t  = feature_t,
    parameter type cb_count_t = feature_count_t
) (
    // external signals
    input   logic   clk,
    input   logic   rst,
    // input data
    input   logic       data_vld,
    input   cb_data_t   data_i,
    // output
    output  logic       ready,
    output  logic       count_vld,
    output  cb_count_t  count_o
);

// inner signals
cb_state_t state, state_n;
cb_data_t data, data_n, data_lowest;
cb_count_t count, count_n;

// set state_n
always_comb begin
    state_n = state;
    unique case (state)
        CB_IDLE: if (data_vld) state_n = CB_COUNT;
        CB_COUNT: if (~|data_lowest) state_n = CB_FINISH;
        CB_FINISH: state_n = CB_IDLE;
    endcase
end
// set state
always_ff @ (posedge clk) begin
    if (rst) state <= CB_IDLE;
    else     state <= state_n;
end

// set data_n
always_comb begin
    data_n = data;
    unique case (state)
        CB_IDLE: data_n = data_i;
        CB_COUNT: data_n = data ^ data_lowest;
    endcase
end
// set data
always_ff @ (posedge clk) begin
    if (rst) data <= '0;
    else     data <= data_n;
end
// set data_lowest
assign data_lowest = data & (~data + 1'b1);

// set count_n
always_comb begin
    count_n = count;
    unique case (state)
        CB_IDLE: if (data_vld) count_n = '0;
        CB_COUNT: if (|data_lowest) count_n = count + 1'b1;
    endcase
end
// set count
always_ff @ (posedge clk) begin
    if (rst) count <= '0;
    else     count <= count_n;
end

// set output
assign ready     = (state_n == CB_IDLE);
assign count_o   = count;
assign count_vld = (state == CB_FINISH);

endmodule
