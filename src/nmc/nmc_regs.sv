// nmc_regs
`include "nmc_defs.svh"

module nmc_regs #(
    parameter   N_TOTAL         =   `N_FEATURE,
    parameter   N_PART          =   `N_PART_FEATURE,
    parameter type data_t       =   feature_t,
    localparam  N_PORT          =   N_TOTAL / N_PART,
    localparam type addr_t      =   logic[$clog2(N_PART)-1:0]
) (
    // external signals
    input   logic   clk,
    input   logic   rst,
    // wr port
    input   logic       we,
    input   data_t   wrdata,
    // rd port
    input   logic[N_PORT-1:0]   ce,
    input   addr_t[N_PORT-1:0]  rdaddr,
    output  float_t[N_PORT-1:0] rddata
);

// inner signals
data_t data_r, data_n;
float_t[N_PORT-1:0] rddata_r, rddata_n;

// update data_n
always_comb begin
    // default
    data_n = data_r;
    if (we) data_n = wrdata;
end
// update data_r
always_ff @ (posedge clk) begin
    if (rst) data_r <= '0;
    else     data_r <= data_n;
end

for (genvar i = 0; i < N_PORT; i++) begin : gen_rddata
    // update rddata_n
    always_comb begin
        // default
        rddata_n[i] = '0;
        if (ce[i]) rddata_n[i] = data_r[(i*N_PART)+rdaddr];
    end
    // update rddata_r
    always_ff @ (posedge clk) begin
        if (rst) rddata_r[i] <= '0;
        else     rddata_r[i] <= rddata_n[i];
    end
    // set output
    assign rddata[i] = rddata_r[i];
end

endmodule
