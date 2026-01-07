module memory(
    input clk,
    input rst_n,
    input logic l1_mem_valid,
    input logic l1_mem_store,   // 0 : load 1 : store
    input logic [31:0] l1_mem_addr,    // address 
    input logic [31:0] l1_mem_wdata,   // data to write

    output logic [31:0] mem_l1_rdata,
    output logic mem_l1_valid
);

// -------------------------
    // Parameters
    // -------------------------
    parameter MEM_BYTES = 256 * 1024;   // 256 KB
    parameter WORDS     = MEM_BYTES / 4;

    // -------------------------
    // Memory array
    // -------------------------
    logic [31:0] mem [0:WORDS-1];

    integer i;
    initial begin
        for (i = 0; i < WORDS; i++) begin
            mem[i] = i;
        end
    end

    // Word address (ignore byte offset)
    logic [$clog2(WORDS)-1:0] word_addr;
    assign word_addr = l1_mem_addr[31:2];

    always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        mem_l1_valid <= 1'b0;
        mem_l1_rdata <= '0;
    end
    else begin
        mem_l1_valid <= 1'b0;

        if (l1_mem_valid) begin

            if (l1_mem_store) begin
                // STORE
                mem[word_addr] <= l1_mem_wdata;
            end
            else begin
                // LOAD
                mem_l1_rdata <= mem[word_addr];
            end
            mem_l1_valid <= 1'b1;
        end
    end
end

endmodule

