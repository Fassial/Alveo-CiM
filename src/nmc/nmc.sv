// nmc
`include "nmc_defs.svh"

module nmc #(
    parameter   N_NMC_CELL      =   `N_NMC_CELL,
    parameter   ALU_KIND        =   `ALU_KIND,
    parameter   NWR_FIFO_DEPTH  =   `NWR_FIFO_DEPTH,
    parameter   NQR_FIFO_DEPTH  =   `NQR_FIFO_DEPTH,
    // threshold
    parameter   NMC_COUNT_THRES =   `NMC_COUNT_THRES
) (
    // external signals
    input   logic   clk,
    input   logic   rst,
    // nmc_wr_req
    input   nmc_wr_req_t    nmc_wr_req,
    input   logic           nwr_push,
    output  logic           nwr_full,
    // nmc_qr_req
    input   nmc_qr_req_t    nmc_qr_req,
    input   logic           nqr_push,
    output  logic           nqr_full,
    // nmc_qr_resp
    output  logic           ready,
    output  nmc_qr_resp_t   nmc_qr_resp
);

// define funcs
`DEF_FUNC_GET_INDEX
`DEF_FUNC_GET_OFFSET

// define addr_t
typedef logic[$clog2(NWR_FIFO_DEPTH)-1:0] nwr_addr_t;
typedef logic[$clog2(NQR_FIFO_DEPTH)-1:0] nqr_addr_t;
// define 
typedef logic[$clog2($bits(feature_t))-1:0] feature_count_t;

// state
nmc_state_t state, state_n;
// nmc_qr_req
nmc_wr_req_t nmc_wr_req_r, nmc_wr_req_n;
nmc_qr_req_t nmc_qr_req_r, nmc_qr_req_n;
// nmc_qr_resp
nmc_qr_resp_t nmc_qr_resp_n;

// define interface for nwr_fifo
logic nwr_empty, nwr_pop, nwr_poped, nwr_pushed;
nmc_wr_req_t nwr_fifo_i, nwr_fifo_o;
// define interface for nqr_fifo
logic nqr_empty, nqr_pop, nqr_poped, nqr_pushed;
nmc_qr_req_t nqr_fifo_i, nqr_fifo_o;
// define interface for nmc_mem
logic nmc_we;
nmc_offset_t nmc_rdaddr, nmc_wraddr;
nmc_entry_t nmc_rddata, nmc_wrdata;
// define interface for alu
feature_t alu_a_i, alu_b_i, alu_c_o;
// define interface for count_bit
logic cb_data_vld, cb_ready, cb_count_vld;
feature_t cb_data_i;
feature_count_t cb_count_o;

// set state_n
always_comb begin
    state_n = state;
    unique case (state)
        NMC_IDLE: begin
            if (~nqr_empty) state_n = NMC_QUERY;
            if (~nwr_empty) state_n = NMC_WRITE;
        end
        NMC_QUERY: begin
            if (nmc_rddata.id != nmc_qr_req_r.id && nmc_qr_req_r.id_vld)
                state_n = NMC_RES;
            else
                state_n = NMC_COUNT;
        end
        NMC_COUNT: begin
            if (cb_count_vld) state_n = NMC_QUERY;
            if (cb_count_vld && cb_count_o < NMC_COUNT_THRES) state_n = NMC_RES;
        end
        NMC_RES: state_n = NMC_IDLE;
        NMC_WRITE: state_n = NMC_IDLE;
    endcase
end
// set state
always_ff @ (posedge clk) begin
    if (rst) state <= NMC_IDLE;
    else     state <= state_n;
end
// set pop
assign nwr_pop = (state == NMC_IDLE) && ~nwr_empty;
assign nqr_pop = (state == NMC_IDLE) && nwr_empty && ~nqr_empty;
// set nmc_wr_req_r & nmc_qr_req_r
assign nmc_wr_req_n = nwr_fifo_o;
assign nmc_wr_req_r = nmc_wr_req_n;
always_comb begin
    // default
    nmc_qr_req_n = nmc_qr_req_r;
    unique case (state)
        NMC_IDLE: nmc_qr_req_n = nqr_fifo_o;
        NMC_QUERY: begin
            nmc_qr_req_n.addr = nmc_qr_req_r.addr + 1'b1;
            if (~nmc_qr_req_r.id_vld) begin
                nmc_qr_req_n.id = nmc_rddata.id;
                nmc_qr_req_n.id_vld = 1'b1;
            end
        end
    endcase
end
always_ff @ (posedge clk) begin
    if (rst) nmc_qr_req_r <= '0;
    else     nmc_qr_req_r <= nmc_qr_req_n;
end

// set output
// set nmc_qr_resp_n
always_comb begin
    nmc_qr_resp_n = '0;
    unique case (state)
        NMC_QUERY:
            if (nmc_rddata.id != nmc_qr_req_r.id && nmc_qr_req_r.id_vld) begin
                nmc_qr_resp_n.valid = 1'b1;
                nmc_qr_resp_n.found = 1'b0;
                nmc_qr_resp_n.result = '0;
            end
        NMC_COUNT:
            if (cb_count_vld && cb_count_o < NMC_COUNT_THRES) begin
                nmc_qr_resp_n.valid = 1'b1;
                nmc_qr_resp_n.found = 1'b1;
                nmc_qr_resp_n.result = nmc_rddata.result;
            end
    endcase
end
// set nmc_qr_resp
always_ff @ (posedge clk) begin
    if (rst) nmc_qr_resp <= '0;
    else     nmc_qr_resp <= nmc_qr_resp_n;
end
// set ready
assign ready = (state_n == NMC_IDLE);

// nwr_fifo
fifo #(
    .FIFO_DEPTH ( NWR_FIFO_DEPTH    ),
    .fifo_t     ( nmc_wr_req_t      )
) nwr_fifo (
    // external signals
    .clk,
    .rst,
    // control signals
    .pop        ( nwr_pop           ),
    .poped      ( nwr_poped         ),
    .push       ( nwr_push          ),
    .pushed     ( nwr_pushed        ),
    .empty      ( nwr_empty         ),
    .full       ( nwr_full          ),
    // fifo_t
    .fifo_i     ( nwr_fifo_i        ),
    .fifo_o     ( nwr_fifo_o        )
);
assign nwr_fifo_i = nmc_wr_req;
// nqr_fifo
fifo #(
    .FIFO_DEPTH ( NQR_FIFO_DEPTH    ),
    .fifo_t     ( nmc_qr_req_t      )
) nqr_fifo (
    // external signals
    .clk,
    .rst,
    // control signals
    .pop        ( nqr_pop           ),
    .poped      ( nqr_poped         ),
    .push       ( nqr_push          ),
    .pushed     ( nqr_pushed        ),
    .empty      ( nqr_empty         ),
    .full       ( nqr_full          ),
    // fifo_t
    .fifo_i     ( nqr_fifo_i        ),
    .fifo_o     ( nqr_fifo_o        )
);
assign nqr_fifo_i = nmc_qr_req;
// nmc entry ram
dual_port_ram #(
    .SIZE   ( N_NMC_CELL    ),
    .dtype  ( nmc_entry_t   )
) nmc_mem (
    .clk,
    .rst,

    .ena    ( 1'b1          ),
    .wea    ( nmc_we        ),
    .addra  ( nmc_wraddr    ),
    .dina   ( nmc_wrdata    ),
    .douta  (               ),

    .enb    ( 1'b1          ),
    .web    ( 1'b0          ),
    .addrb  ( nmc_rdaddr    ),
    .dinb   (               ),
    .doutb  ( nmc_rddata    )
);
assign nmc_we     = (state_n == NMC_WRITE);
assign nmc_wraddr = nmc_wr_req_r.addr;
assign nmc_wrdata = nmc_wr_req_r.entry;
assign nmc_rdaddr = get_offset(nmc_qr_req_n.addr);
// inst alu
alu #(
    .DATA_WIDTH ( $bits(feature_t)  ),
    .ALU_KIND   ( ALU_KIND          )
) alu_inst (
    // data_i
    .a_i        ( alu_a_i           ),
    .b_i        ( alu_b_i           ),
    // data_o
    .c_o        ( alu_c_o           )
);
assign alu_a_i = nmc_qr_req_r.feature;
assign alu_b_i = nmc_rddata.feature;
// inst count_bit
count_bit #(
    .cb_data_t  ( feature_t         ),
    .cb_count_t ( feature_count_t   )
) count_bit_inst (
    // external signals
    .clk,
    .rst,
    // input data
    .data_vld   ( cb_data_vld   ),
    .data_i     ( cb_data_i     ),
    // output
    .ready      ( cb_ready      ),
    .count_vld  ( cb_count_vld  ),
    .count_o    ( cb_count_o    )
);
assign cb_data_vld = (state == NMC_QUERY) && (state_n == NMC_COUNT);
assign cb_data_i = alu_c_o;

endmodule
