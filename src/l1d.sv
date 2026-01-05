import cache_pkg::*;

module l1d(
    
    // clocking and reset (active low)
    input clk,
    input rst_n,

    // CPU -> L1D$
    input logic cpu_l1_valid,             // CPU wants to access memory
    input logic pcu_l1_store,             // 0 = load, 1 = store
    input logic [ADDR_WIDTH-1:0] cpu_l1_addr,   // address of the Byte 
    input logic [ADDR_WIDTH-1:0] cpu_l1_wdata,
    input logic [3:0] cpu_l1_

    // L1D -> CPU

);
    
endmodule