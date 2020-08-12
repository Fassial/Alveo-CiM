// nmc
`include "nmc_defs.svh"

module nmc #(
    parameter   N_FEATURE       =   `N_FEATURE,
    parameter   N_PART_FEATURE  =   `N_PART_FEATURE,
    parameter   N_NMC_CELL      =   `N_NMC_CELL,
    parameter   ALU_KIND        =   `ALU_KIND,
    parameter   NWR_FIFO_DEPTH  =   `NWR_FIFO_DEPTH,
    parameter   NQR_FIFO_DEPTH  =   `NQR_FIFO_DEPTH,
    // threshold
    parameter   NMC_CAL_THRES   =   `NMC_CAL_THRES,
    // localparam
    localparam  N_PARALLEL      =   N_FEATURE/N_PART_FEATURE
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
typedef logic[$clog2(N_PART_FEATURE)-1:0] part_addr_t;
typedef logic[$clog2(N_PARALLEL)-1:0]     para_addr_t;
// define 
typedef logic[$clog2($bits(feature_t)):0] feature_count_t;

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
// define interface for qr_req_feature
logic qrf_we;
feature_t qrf_wrdata;
logic[N_PARALLEL-1:0] qrf_ce;
part_addr_t[N_PARALLEL-1:0] qrf_rdaddr;
float_t[N_PARALLEL-1:0] qrf_rddata;
// define interface for rd_feature
logic rdf_we;
feature_t rdf_wrdata;
logic[N_PARALLEL-1:0] rdf_ce;
part_addr_t[N_PARALLEL-1:0] rdf_rdaddr;
float_t[N_PARALLEL-1:0] rdf_rddata;
// define interface for faddn_regs
logic fr_we;
float_t[N_PARALLEL-1:0] fr_wrdata;
logic[0:0] fr_ce;
para_addr_t[0:0] fr_rdaddr;
float_t[0:0] fr_rddata;
// define interface for l2_dist_inst
logic[N_PARALLEL-1:0] ld_start;
logic[N_PARALLEL-1:0] ld_done;
logic[N_PARALLEL-1:0] ld_idle;
logic[N_PARALLEL-1:0] ld_ready;
part_addr_t[N_PARALLEL-1:0] ld_ardaddr;
logic[N_PARALLEL-1:0] ld_ace;
float_t[N_PARALLEL-1:0] ld_arddata;
part_addr_t[N_PARALLEL-1:0] ld_brdaddr;
logic[N_PARALLEL-1:0] ld_bce;
float_t[N_PARALLEL-1:0] ld_brddata;
float_t[N_PARALLEL-1:0] ld_res;
// define interface for faddn
logic fn_start, fn_done, fn_idle, fn_ready, fn_ace;
para_addr_t fn_ardaddr;
float_t fn_arddata;
float_t fn_res;

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
                state_n = NMC_CAL;
        end
        NMC_CAL: begin
            if (fn_done) state_n = NMC_QUERY;
            if (fn_done && fn_res <= NMC_CAL_THRES) state_n = NMC_RES;
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
    case (state)
        NMC_IDLE: nmc_qr_req_n = nqr_fifo_o;
        NMC_QUERY:
            if (~nmc_qr_req_r.id_vld) begin
                nmc_qr_req_n.id = nmc_rddata.id;
                nmc_qr_req_n.id_vld = 1'b1;
            end
        NMC_CAL: if (fn_done) nmc_qr_req_n.addr = nmc_qr_req_r.addr + 1'b1;
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
    case (state)
        NMC_QUERY:
            if (nmc_rddata.id != nmc_qr_req_r.id && nmc_qr_req_r.id_vld) begin
                nmc_qr_resp_n.valid = 1'b1;
                nmc_qr_resp_n.found = 1'b0;
                nmc_qr_resp_n.result = '0;
            end
        NMC_CAL:
            if (fn_done && fn_res <= NMC_CAL_THRES) begin
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
// inst num_regs for nmc_qr_req_r.feature
nmc_regs #(
    .N_TOTAL    ( N_FEATURE         ),
    .N_PART     ( N_PART_FEATURE    ),
    .data_t     ( feature_t         )
) qr_req_feature (
    // external signals
    .clk,
    .rst,
    // wr port
    .we         ( qrf_we            ),
    .wrdata     ( qrf_wrdata        ),
    // rd port
    .ce         ( qrf_ce            ),
    .rdaddr     ( qrf_rdaddr        ),
    .rddata     ( qrf_rddata        )
);
assign qrf_we = (state == NMC_QUERY) && (state_n == NMC_CAL);
assign qrf_wrdata = nmc_qr_req_r.feature;
for (genvar i = 0; i < N_PARALLEL; i++) begin : assign_qrf_rd
    assign qrf_ce[i] = ld_ace[i];
    assign qrf_rdaddr[i] = ld_ardaddr[i];
end
// inst num_regs for nmc_rddata.feature
nmc_regs #(
    .N_TOTAL    ( N_FEATURE         ),
    .N_PART     ( N_PART_FEATURE    ),
    .data_t     ( feature_t         )
) rd_feature (
    // external signals
    .clk,
    .rst,
    // wr port
    .we         ( rdf_we            ),
    .wrdata     ( rdf_wrdata        ),
    // rd port
    .ce         ( rdf_ce            ),
    .rdaddr     ( rdf_rdaddr        ),
    .rddata     ( rdf_rddata        )
);
assign rdf_we = (state == NMC_QUERY) && (state_n == NMC_CAL);
assign rdf_wrdata = nmc_rddata.feature;
for (genvar i = 0; i < N_PARALLEL; i++) begin : assign_rdf_rd
    assign rdf_ce[i] = ld_bce[i];
    assign rdf_rdaddr[i] = ld_brdaddr[i];
end
// l2_dist
for (genvar i = 0; i < N_PARALLEL; i++) begin : gen_l2_dist
    l2_dist l2_dist_inst (
        .ap_clk     ( clk           ),
        .ap_rst     ( rst           ),
        .ap_start   ( ld_start[i]   ),
        .ap_done    ( ld_done[i]    ),
        .ap_idle    ( ld_idle[i]    ),
        .ap_ready   ( ld_ready[i]   ),
        .A_address0 ( ld_ardaddr[i] ),
        .A_ce0      ( ld_ace[i]     ),
        .A_q0       ( ld_arddata[i] ),
        .B_address0 ( ld_brdaddr[i] ),
        .B_ce0      ( ld_bce[i]     ),
        .B_q0       ( ld_brddata[i] ),
        .ap_return  ( ld_res[i]     )
    );
    assign ld_start[i] = (state == NMC_QUERY) && (state_n == NMC_CAL);
    assign ld_arddata[i] = qrf_rddata[i];
    assign ld_brddata[i] = rdf_rddata[i];
end
// inst num_regs for faddn
nmc_regs #(
    .N_TOTAL    ( N_PARALLEL    ),
    .N_PART     ( N_PARALLEL    ),
    .data_t     ( float_t[N_PARALLEL-1:0]   )
) faddn_regs (
    // external signals
    .clk,
    .rst,
    // wr port
    .we         ( fr_we         ),
    .wrdata     ( fr_wrdata     ),
    // rd port
    .ce         ( fr_ce         ),
    .rdaddr     ( fr_rdaddr     ),
    .rddata     ( fr_rddata     )
);
assign fr_we = &ld_done;
assign fr_wrdata = ld_res;
assign fr_ce = fn_ace;
assign fr_rdaddr = fn_ardaddr;
// faddn
faddn faddn_inst (
    .ap_clk     ( clk           ),
    .ap_rst     ( rst           ),
    .ap_start   ( fn_start      ),
    .ap_done    ( fn_done       ),
    .ap_idle    ( fn_idle       ),
    .ap_ready   ( fn_ready      ),
    .A_address0 ( fn_ardaddr    ),
    .A_ce0      ( fn_ace        ),
    .A_q0       ( fn_arddata    ),
    .ap_return  ( fn_res        )
);
assign fn_start = &ld_done;
assign fn_arddata = fr_rddata;

endmodule
