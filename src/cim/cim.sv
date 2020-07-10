// cim
`include "cim_defs.svh"

module cim_top #(
    parameter   N_GROUP     =   128,
    parameter   N_CELL      =   16,
    parameter   DATA_WIDTH  =   32,
    parameter   ALU_KIND    =   `ALU_KIND,
    localparam  GROUP_WIDTH =   $clog2(N_GROUP),
    localparam  CELL_WIDTH  =   $clog2(N_CELL),
    localparam type data_t  =   logic[DATA_WIDTH-1:0],
    localparam type count_t =   logic[CELL_WIDTH-1:0],
    localparam type addr_t  =   logic[GROUP_WIDTH+CELL_WIDTH-1:0],
    localparam type camml_t =   logic[N_GROUP*N_CELL-1:0]
) (
    // external signals
    input   logic   clk,
    input   logic   rst,
    // data_i
    input   data_t  a_i,
    input   logic   we_i,
    input   addr_t  addr_i,
    input   camml_t camml_i,        // cam match line
    input   logic   camml_vld,      // start cim, need N_CELL clock cycle
    // data_o
    output  data_t  data_o,
    output  logic   data_vld
);

// define funcs
`DEF_FUNC_GET_INDEX
`DEF_FUNC_GET_OFFSET

// define inner regs
// ready
logic ready;
// store addr
addr_t addr_r, addr_n;
// a_r
data_t a_r, a_n;
// count
count_t count, count_n;
// state
cim_state_t state, state_n;
// define interface for cim_buffer
logic cf_we_i;
count_t cf_count;
data_t[N_GROUP-1:0] cf_data_i, cf_data_o;
// define interface for ccg
data_t ccg_a_i;
logic[N_GROUP-1:0] ccg_update;
count_t ccg_count;
data_t[N_GROUP-1:0] ccg_data_o;

// update count_n
always_comb begin
    // default
    count_n = count + 1'b1;
    case (state)
        CIM_IDLE: begin
            if (we_i)       count_n = get_offset(addr_i);
            if (camml_vld)  count_n = '0;
        end
    endcase
end
// update addr_n
always_comb begin
    // default
    addr_n = addr_r;
    case (state)
        CIM_IDLE: if (we_i) addr_n = addr_i;
    endcase
end
// update a_n
always_comb begin
    // default
    a_n = a_r;
    case (state)
        CIM_IDLE: a_n = a_i;
    endcase
end
// update state_n
always_comb begin
    // default
    state_n = state;
    case (state)
        CIM_IDLE: begin
            if (we_i)      state_n = CIM_WRITE;
            if (camml_vld) state_n = CIM_CAL;
        end
        CIM_WRITE: state_n = CIM_IDLE;
        CIM_CAL: if (&count) state_n = CIM_IDLE;
    endcase
end
// update inner regs
always_ff @ (posedge clk) begin
    if (rst) begin
        state  <= CIM_IDLE;
        count  <= '0;
        addr_r <= '0;
        a_r    <= '0;
    end else begin
        state  <= state_n;
        count  <= count_n;
        addr_r <= addr_n;
        a_r    <= a_n;
    end
end
// set ready
assign ready = (state_n == CIM_IDLE);

// inst ccg
for (genvar i = 0; i < N_GROUP; i++) begin : gen_ccg
    cim_cell_group #(
        .N_CELL     ( N_CELL        ),
        .DATA_WIDTH ( DATA_WIDTH    ),
        .ALU_KIND   ( ALU_KIND      )
    ) ccg_inst (
        // external signals
        .clk,
        .rst,
        // data w & b
        .a_i        ( ccg_a_i       ),
        .update     ( ccg_update[i] ),
        .count_i    ( ccg_count     ),
        // data_o
        .data_o     ( ccg_data_o[i] )
    );
end
assign ccg_a_i = a_r;
// set ccg_update
always_comb begin
    // default
    ccg_update = '0;
    ccg_update[get_index(addr_r)] = (state == CIM_WRITE);
end
assign ccg_count = count;
// inst cim_buffer
for (genvar i = 0; i < N_GROUP; i++) begin : gen_cim_buffer
    dual_port_lutram #(
        .SIZE   ( N_CELL    ),
        .dtype  ( data_t    )
    ) cim_buffer (
        .clk,
        .rst,

        .ena    ( 1'b1                  ),
        .wea    ( cf_we_i               ),
        .addra  ( cf_count              ),
        .dina   ( cf_data_i[i]          ),
        .douta  (                       ),

        .enb    ( 1'b1                  ),
        .addrb  ( get_offset(addr_i)    ),
        .doutb  ( cf_data_o[i]          )
    );
end
assign cf_we_i   = (state == CIM_WRITE);
assign cf_count  = count;
assign cf_data_i = ccg_data_o;

// set output
assign data_o   = cf_data_o[get_index(addr_i)];
assign data_vld = ready;

endmodule

module cim_cell_group #(
    parameter   N_CELL      =   16,
    parameter   DATA_WIDTH  =   32,
    parameter   ALU_KIND    =   0,
    localparam  CELL_WIDTH  =   $clog2(N_CELL),
    localparam type data_t  =   logic[DATA_WIDTH-1:0],
    localparam type count_t =   logic[CELL_WIDTH-1:0]
) (
    // external signals
    input   logic   clk,
    input   logic   rst,
    // data w & b
    input   data_t  a_i,
    input   logic   update,
    input   count_t count_i,
    // data_o
    output  data_t  data_o
);

// define interface for alu
data_t alu_a, alu_b, alu_c;
// define interface for cim_cell
logic[N_CELL-1:0] ccg_update;
data_t ccg_data_i;
data_t[N_CELL-1:0] ccg_data_o;
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
assign alu_a = a_i;
assign alu_b = ccg_data_o[count_i];

// gen cim_cell group
for (genvar i = 0; i < N_CELL; i++) begin : gen_cim_cell_group
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
// set ccg_update
always_comb begin
    // default
    ccg_update = '0;
    ccg_update[count_i] = update;
end

// set output
assign data_o  = alu_c;

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
always_comb begin
    // default
    cell_data_n = data_i;
    // remove accumulate
end
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
