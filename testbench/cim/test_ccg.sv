// test ccg
`include "test_cim.svh"

module test_ccg #(
    // module parameter
    parameter   N_GROUP     =   12,
    parameter   DATA_WIDTH  =   32,
    parameter   ALU_KIND    =   0,
    localparam  COUNT_WIDTH =   $clog2(N_GROUP) + 1
) (

);

// gen clk & sync_rst
logic clk, rst, sync_rst;
sim_clock sim_clock_inst(.*);
always_ff @ (posedge clk) begin
    sync_rst <= rst;
end

// interface define
logic[DATA_WIDTH-1:0] w_i, b_i;
logic update;
logic[DATA_WIDTH-1:0][N_GROUP-1:0] data_o;
// inst module
cim_cell_group #(
    .N_GROUP    ( N_GROUP       ),
    .DATA_WIDTH ( DATA_WIDTH    ),
    .ALU_KIND   ( ALU_KIND      )
) cim_cell_group_inst (
    // external signals
    .clk,
    .rst,
    // data w & b
    .w_i,
    .b_i,
    .update,
    // data_o
    .data_o
);

// record
string summary;

task unittest_(
    input string name
);
    string fans_name, fans_path, freq_name, freq_path, out;
    integer fans, freq, ans_counter, req_counter, cycle;

    fans_name = {name, ".ans"};
    fans_path = get_path(fans_name);
    if (fans_path == "") begin
        $display("[Error] file[%0s] not found!", fans_name);
        $stop;
    end
    freq_name = {name, ".req"};
    freq_path = get_path(freq_name);
    if (freq_path == "") begin
        $display("[Error] file[%0s] not found!", freq_name);
        $stop;
    end

    // load mem into m_mem_device.ram.mem
    begin
        fans = $fopen({fans_path}, "r");
        freq = $fopen({freq_path}, "r");
    end

    // reset inst
    begin
        rst = 1'b1;
        #50 rst = 1'b0;
    end

    $display("======= unittest: %0s =======", name);

    // reset ans_counter & req_counter & cycle
    ans_counter = 0;
    req_counter = 0;
    cycle = 0;
    // reset control signals
    update = 1'b0;
    while (!$feof(fans)) begin
        // wait negedge clk to ensure line_data already update
        @ (negedge clk);
        cycle = cycle + 1;

        // reset control signals
        update = 1'b0;

        // check ans
        begin
            $sformat(out, {"%x"}, data_o);
            judge(fans, ans_counter, out);
            ans_counter = ans_counter + 1;
        end

        // issue req
        if (!$feof(freq)) begin
            $fscanf(freq, "%x %x %x %x\n", w_i, b_i, update);
            req_counter = req_counter + 1;
        end
    end

    $display("[OK] %0s\n", name);
    $sformat(summary, "%0s%0s: cycle = %d\n", summary, name, cycle);
endtask

task unittest(
    input string name
);
    unittest_(name);
endtask

initial begin
    wait(rst == 1'b0);
    summary = "";
    unittest("ccg_simple");
    $display("summary: %0s", summary);
    $stop;
end

endmodule
