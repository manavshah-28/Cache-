import cache_pkg::*;

module l1d_tb();

// clocking and reset (active low)
logic clk;
logic rst_n;

// CPU -> L1D$
logic cpu_l1_valid;             // CPU wants to access memory
logic pcu_l1_store;             // 0 = load, 1 = store
logic [ADDR_WIDTH-1:0] cpu_l1_addr;   // address of the Byte 
logic [ADDR_WIDTH-1:0] cpu_l1_wdata;
logic [3:0] cpu_l1_;

// L1D -> CPU

// DUT instantiation
l1d datacache(.*);

// 

initial begin
clk = 0;
forever #5 clk = ~clk;
end

initial begin
rst_n = 0;
#10;
rst_n = 1;

$display("Cache size = %0d", L1_CACHE_SIZE);
$display("Cache ways = %0d", L1_WAYS);
$display("Line Size = %0d", L1_LINE_SIZE);
$display("Number of Cache lines =  %0d", L1_CACHE_LINES);
$display("Sets = %0d", L1_SETS);

$display("offset bits = %0d", L1_OFFSET);
$display("index bits = %0d", L1_INDEX);
$display("tag bits = %0d", L1_TAG);

$finish;
end
endmodule