// fifo
`include "common_defs.svh"

module fifo #(
    parameter int FIFO_DEPTH    =   16,
    parameter type fifo_t       =   uint32_t
) (
    // external signals
    input   logic   clk,
    input   logic   rst,
    // control signals
    input   logic   pop,
    output  logic   poped,
    input   logic   push,
    output  logic   pushed,
    output  logic   empty,
    output  logic   full,
    // fifo_t
    input   fifo_t  fifo_i,
    output  fifo_t  fifo_o
);

// define addr_t
typedef logic[$clog2(FIFO_DEPTH)-1:0] addr_t;

// pointer
addr_t head, head_n, tail, tail_n;
// mem & valid
fifo_t[FIFO_DEPTH-1:0] mem, mem_n;
logic[FIFO_DEPTH-1:0] valid, valid_n;

// set pointer_n & valid_n & mem_n
always_comb begin
    head_n = head;
    tail_n = tail;
    mem_n = mem;
    valid_n = valid;

    pushed = 1'b0;
    poped  = 1'b0;
    // pop one line, allow push & pop at full
    if (pop && ~empty) begin
        valid_n[head] = 1'b0;

        if (head == FIFO_DEPTH-1) begin
            head_n = '0;
        end else begin
            head_n = head + 1;
        end

        poped = 1'b1;
    end

    // push one line
    if (push && ~full) begin
        mem_n[tail] = fifo_i;
        valid_n[tail] = 1'b1;

        if (tail == FIFO_DEPTH-1) begin
            tail_n = '0;
        end else begin
            tail_n = tail + 1;
        end

        pushed = 1'b1;
    end
end
// set pointer 
always_ff @ (posedge clk) begin
    if (rst) begin
        head <= '0;
        tail <= '0;
        valid <= '0;
    end else begin
        head <= head_n;
        tail <= tail_n;
        valid <= valid_n;
    end
end
// set mem
always_ff @ (posedge clk) begin
    if (rst) begin
        mem <= '0;
    end else if (pushed) begin
        mem <= mem_n;
    end
end

// set output
// Grow --->
// O O O X X X X O O
//       H       T
assign empty  = ~|valid;
assign full   = &valid;
assign fifo_o = mem[head];

endmodule
