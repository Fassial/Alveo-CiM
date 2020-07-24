// test tcam
`include "test_cam.svh"

module test_cam #(
    // test target
    parameter       CAM_TEST_TARGET     =   `CAM_TEST_TARGET,
    // module parameter
    parameter       KEY_WIDTH   =   32,
    parameter       KEY_DEPTH   =   16
) (

);

// gen clk & sync_rst
logic clk, rst, sync_rst;
sim_clock sim_clock_inst(.*);
always_ff @ (posedge clk) begin
    sync_rst <= rst;
end

// define interface for cam
cam_req_t cam_req;
cam_resp_t cam_resp;
// define interface for tcam
tcam_req_t tcam_req;
tcam_resp_t tcam_resp;
// inst module
generate if (CAM_TEST_TARGET == `TEST_CAM) begin
    // inst cam module
    cam #(
        .KEY_WIDTH  ( KEY_WIDTH ),
        .KEY_DEPTH  ( KEY_DEPTH )
    ) cam_inst (
        .*
    );
end else if (CAM_TEST_TARGET == `TEST_TCAM) begin
    // inst tcam module
    tcam #(
        .KEY_WIDTH  ( KEY_WIDTH ),
        .KEY_DEPTH  ( KEY_DEPTH )
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
        if (CAM_TEST_TARGET == `TEST_CAM) begin
            // reset cam control signals
            cam_req.addr_vld = 1'b0;
            cam_req.data_vld = 1'b0;
        end else if (CAM_TEST_TARGET == `TEST_TCAM) begin
            // reset tcam control signals
            tcam_req.addr_vld = 1'b0;
            tcam_req.data_vld = 1'b0;
        end else begin
            // TODO
        end

        // check ans
        if (CAM_TEST_TARGET == `TEST_CAM) begin
            // check cam ans
            if (cam_resp.addr_vld) begin
                $sformat(out, {"%x-%x"}, cam_resp.addr, cam_resp.data);
                judge(fans, ans_counter, out);
                ans_counter = ans_counter + 1;
            end
        end else if (CAM_TEST_TARGET == `TEST_TCAM) begin
            // check tcam ans
            if (tcam_resp.addr_vld) begin
                $sformat(out, {"%x-%x"}, tcam_resp.addr, tcam_resp.data);
                judge(fans, ans_counter, out);
                ans_counter = ans_counter + 1;
            end
        end else begin
            // TODO
        end

        // issue req
        if (CAM_TEST_TARGET == `TEST_CAM) begin
            // issue cam req
            if (!$feof(freq)) begin
                $fscanf(freq, "%x %x %x %x %x\n", cam_req.we, cam_req.addr_vld, cam_req.data_vld, cam_req.addr, cam_req.data);
                req_counter = req_counter + 1;
            end
        end else if (CAM_TEST_TARGET == `TEST_TCAM) begin
            // issue tcam req
            if (!$feof(freq)) begin
                $fscanf(freq, "%x %x %x %x %x %x\n", tcam_req.we, tcam_req.addr_vld, tcam_req.data_vld, tcam_req.addr, tcam_req.data, tcam_req.mask);
                req_counter = req_counter + 1;
            end
        end else begin
            // TODO
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
