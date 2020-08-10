// test nmc
`include "test_nmc.svh"

module test_nmc #(
    // module parameter
    parameter   N_NMC_CELL      =   `N_NMC_CELL,
    parameter   ALU_KIND        =   `ALU_KIND,
    parameter   NWR_FIFO_DEPTH  =   `NWR_FIFO_DEPTH,
    parameter   NQR_FIFO_DEPTH  =   `NQR_FIFO_DEPTH,
    // threshold
    parameter   NMC_COUNT_THRES =   `NMC_COUNT_THRES
) (

);

// gen clk & sync_rst
logic clk, rst, sync_rst;
sim_clock sim_clock_inst(.*);
always_ff @ (posedge clk) begin
    sync_rst <= rst;
end

// interface define
nmc_wr_req_t nmc_wr_req;
logic nwr_push, nwr_full;
nmc_qr_req_t nmc_qr_req;
logic nqr_push, nqr_full;
logic ready;
nmc_qr_resp_t nmc_qr_resp;
// inst module
nmc #(
    .N_NMC_CELL     ( N_NMC_CELL        ),
    .ALU_KIND       ( ALU_KIND          ),
    .NWR_FIFO_DEPTH ( NWR_FIFO_DEPTH    ),
    .NQR_FIFO_DEPTH ( NQR_FIFO_DEPTH    ),
    .NMC_COUNT_THRES( NMC_COUNT_THRES   )
) nmc_inst (
    // external signals
    .clk,
    .rst,
    // nmc_wr_req
    .nmc_wr_req,
    .nwr_push,
    .nwr_full,
    // nmc_qr_req
    .nmc_qr_req,
    .nqr_push,
    .nqr_full,
    // nmc_qr_resp
    .ready,
    .nmc_qr_resp
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
    nwr_push = 1'b0;
    nqr_push = 1'b0;
    while (!$feof(fans)) begin
        // wait negedge clk to ensure line_data already update
        @ (negedge clk);
        cycle = cycle + 1;

        // reset control signals
        nwr_push = 1'b0;
        nqr_push = 1'b0;

        // check ans
        if (nmc_qr_resp.valid) begin
            $sformat(out, {"%x-%x"}, nmc_qr_resp.found, nmc_qr_resp.result);
            judge(fans, ans_counter, out);
            ans_counter = ans_counter + 1;
        end

        // issue req
        if (!$feof(freq)) begin
            nmc_qr_req.id = '0;
            nmc_qr_req.id_vld = 1'b0;
            $fscanf(freq, "%x %x %x %x %x %x\n", nwr_push, nmc_wr_req.addr, nmc_wr_req.entry, nqr_push, nmc_qr_req.addr, nmc_qr_req.feature);
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
    unittest("nmc_simple");
    $display("summary: %0s", summary);
    $stop;
end

endmodule
