`timescale 1ns/1ps

module memory_tb;

    // -------------------------
    // Clock / Reset
    // -------------------------
    logic clk;
    logic rst_n;

    initial clk = 0;
    always #5 clk = ~clk;   // 100 MHz

    // -------------------------
    // DUT signals
    // -------------------------
    logic        l1_mem_valid;
    logic        l1_mem_store;
    logic [31:0] l1_mem_addr;
    logic [31:0] l1_mem_wdata;

    logic [31:0] mem_l1_rdata;
    logic        mem_l1_valid;

    // -------------------------
    // DUT instantiation
    // -------------------------
    memory dut (.*);

    // -------------------------
    // Reset task
    // -------------------------
    task reset_dut();
        begin
            rst_n = 0;
            l1_mem_valid = 0;
            l1_mem_store = 0;
            l1_mem_addr  = 0;
            l1_mem_wdata = 0;
            repeat (3) @(posedge clk);
            rst_n = 1;
            @(posedge clk);
        end
    endtask

    // -------------------------
    // LOAD task
    // -------------------------
    task mem_load(input [31:0] addr, input [31:0] exp_data);
        begin
            @(posedge clk);
            l1_mem_valid = 1;
            l1_mem_store = 0;
            l1_mem_addr  = addr;

            @(posedge clk);
            l1_mem_valid = 0;

            // Wait for response
            wait (mem_l1_valid);

            if (mem_l1_rdata !== exp_data) begin
                $error("LOAD FAIL @ addr=0x%08h exp=0x%08h got=0x%08h",
                       addr, exp_data, mem_l1_rdata);
            end
            else begin
                $display("LOAD PASS @ addr=0x%08h data=0x%08h",
                         addr, mem_l1_rdata);
            end
        end
    endtask

    // -------------------------
    // STORE task
    // -------------------------
    task mem_store(input [31:0] addr, input [31:0] data);
        begin
            @(posedge clk);
            l1_mem_valid = 1;
            l1_mem_store = 1;
            l1_mem_addr  = addr;
            l1_mem_wdata = data;

            @(posedge clk);
            l1_mem_valid = 0;

            wait (mem_l1_valid);
            $display("STORE @ addr=0x%08h data=0x%08h", addr, data);
        end
    endtask

    // -------------------------
    // Test sequence
    // -------------------------
    initial begin
        reset_dut();

        $display("\n--- TEST 1: Initial memory pattern ---");
        // mem[i] = i
        mem_load(32'h0000_0000, 32'h0);      // word 0
        mem_load(32'h0000_0004, 32'h1);      // word 1
        mem_load(32'h0000_0040, 32'h10);     // word 16

        $display("\n--- TEST 2: Store then load-back ---");
        mem_store(32'h0000_0080, 32'hDEADBEEF);
        mem_load (32'h0000_0080, 32'hDEADBEEF);

        mem_store(32'h0001_0000, 32'hCAFEBABE);
        mem_load (32'h0001_0000, 32'hCAFEBABE);

        $display("\n--- TEST COMPLETE ---");
        #20;
        $finish;
    end

endmodule
