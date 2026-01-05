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
logic [3:0] cpu_l1_wstrb;

// L1D -> CPU
logic l1_cpu_valid;
logic l1_cpu_stall;
logic [31:0] l1_cpu_rdata;
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

disp_info();
   
$finish;
end

task disp_info();
$display("________________|$ CACHE INFO $|_______________");
$display();
$display("Cache size  = %0d", L1_CACHE_SIZE);
$display("Cache ways  = %0d", L1_WAYS);
$display("Line size   = %0d", L1_LINE_SIZE);
$display("Data Bits   = %0d", L1_DATABITS);
$display("Cache lines = %0d", L1_CACHE_LINES);
$display("Sets        = %0d", L1_SETS);
$display("Offset      = %0d", L1_OFFSET);
$display("Index       = %0d", L1_INDEX);
$display("Tag         = %0d", L1_TAG);
$display("_______________________________________________");
endtask
endmodule