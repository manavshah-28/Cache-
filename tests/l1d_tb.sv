import cache_pkg::*;

class cpu_transaction_randoms;

  rand bit                   cpu_l1_valid;
  rand bit                   cpu_l1_store;   // 0 = load, 1 = store
  rand logic [ADDR_WIDTH-1:0] cpu_l1_addr;
  rand logic [ADDR_WIDTH-1:0] cpu_l1_wdata;
  rand logic [3:0]            cpu_l1_wstrb;

  // Mostly valid transactions
  constraint c_valid {
    cpu_l1_valid dist {1 := 80, 0 := 20};
  }

  // Word-aligned address
  constraint c_addr_align {
    cpu_l1_addr[1:0] == 2'b00;
  }

  // Load / store behavior
  constraint c_load_store {
    if (cpu_l1_store == 0) {
      cpu_l1_wstrb == 4'b0000;
    }
    else {
      cpu_l1_wstrb inside {
        4'b0001, 4'b0010, 4'b0100, 4'b1000,
        4'b0011, 4'b1100,
        4'b1111
      };
    }
  }
  // Write data only valid on store
  constraint c_wdata {
    if (cpu_l1_store == 0)
      cpu_l1_wdata == '0;
  }

  function new();
  endfunction

endclass


module l1d_tb();

// clocking and reset (active low)
logic clk;
logic rst_n;

// CPU -> L1D$
logic cpu_l1_valid;             // CPU wants to access memory
logic cpu_l1_store;             // 0 = load, 1 = store
logic [ADDR_WIDTH-1:0] cpu_l1_addr;   // address of the Byte 
logic [ADDR_WIDTH-1:0] cpu_l1_wdata;
logic [3:0] cpu_l1_wstrb;

// L1D -> CPU
logic l1_cpu_valid;
logic l1_cpu_stall;
logic [31:0] l1_cpu_rdata;

/*============= L1-> Memory INTERFACE =============*/
  logic l1_mem_valid;
  logic l1_mem_store;   // 0 : load 1 : store
  logic [31:0] l1_mem_addr;    // address 
  logic [31:0] l1_mem_wdata;   // data to write

  logic [31:0] mem_l1_rdata;
  logic mem_l1_valid;
  
logic resp_valid;
// DUT instantiation
l1d datacache(.*);

// 
cpu_transaction_randoms tr;

initial begin
clk = 0;
forever #5 clk = ~clk;
end

initial begin
rst_n = 0;
#10;
rst_n = 1;

disp_info();

tr = new();

#20;

repeat (10) begin
@(posedge clk);
assert(tr.randomize())
else $fatal("Randomization failed");

cpu_l1_valid = tr.cpu_l1_valid;
cpu_l1_addr = tr.cpu_l1_addr;
cpu_l1_wstrb = tr.cpu_l1_wstrb;
cpu_l1_wdata = tr.cpu_l1_wdata;
cpu_l1_store = tr.cpu_l1_store;

$display("valid=%0b store=%0b addr=%h wstrb=%b wdata=%h",
    tr.cpu_l1_valid,
    tr.cpu_l1_store,
    tr.cpu_l1_addr,
    tr.cpu_l1_wstrb,
    tr.cpu_l1_wdata);

fork
  begin : wait_resp
  @(posedge resp_valid);
  $display("%0t Response Received", $time);
  end

  begin : timeout_blk
  repeat(20) @(posedge clk);
  $display("%0t Timeout : Response not received", $time);
  end
join_any
disable fork;
end
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
