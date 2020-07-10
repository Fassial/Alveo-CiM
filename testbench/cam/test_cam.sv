// test tcam
`include "test_cam.svh"

module test_cam #(
    // test target
    parameter       CAM_TEST_TARGET     =   `CAM_TEST_TARGET,
    // module parameter
    parameter       CAM_WIDTH   =   32,
    parameter       CAM_DEPTH   =   16,
    localparam      CAM_INDEX_WIDTH     =   $clog2(CAM_DEPTH)
) (

);

// gen clk & sync_rst
logic clk, rst, sync_rst;
sim_clock sim_clock_inst(.*);
always_ff @ (posedge clk) begin
    sync_rst <= rst;
end

// interface define
logic data_we, data_vld;
logic[CAM_INDEX_WIDTH-1:0] data_idx;
logic[CAM_WIDTH-1:0] data_i, data_mask;
logic index_rdy;
logic[CAM_INDEX_WIDTH-1:0] index_o;
// inst module
generate if (CAM_TEST_TARGET == `TEST_CAM) begin
    cam #(
        .CAM_WIDTH  ( CAM_WIDTH ),
        .CAM_DEPTH  ( CAM_DEPTH )
    ) cam_inst (
        .*
    );
end else if (CAM_TEST_TARGET == `TEST_TCAM) begin
    tcam #(
        .TCAM_WIDTH ( CAM_WIDTH ),
        .TCAM_DEPTH ( CAM_DEPTH )
    ) tcam_inst (
        .*
    );
end else begin
    // TODO
end endgenerate

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
    while (!$feof(fans)) begin
        // wait negedge clk to ensure line_data already update
        @ (negedge clk);
        cycle = cycle + 1;

        // reset control signals
        data_we = 1'b0;

        // check ans
        if (index_rdy) begin
            $sformat(out, {"%x"}, index_o);
            judge(fans, ans_counter, out);
            ans_counter = ans_counter + 1;
        end

        // issue req
        if (!$feof(freq)) begin
            $fscanf(freq, "%x %x %x %x %x\n", data_we, data_vld, data_idx, data_i, data_mask);
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
    if (CAM_TEST_TARGET == `TEST_CAM) begin
        // test cam
        unittest("cam_simple");
    end else if (CAM_TEST_TARGET == `TEST_TCAM) begin
        // test tcam
        unittest("tcam_simple");
    end else begin
        // TODO
    end
    $display("summary: %0s", summary);
    $stop;
end

endmodule
