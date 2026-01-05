import cache_pkg::*;

module l1d(
    
    // clocking and reset (active low)
    input clk,
    input rst_n,

    /*============= CPU INTERFACE =============*/

    // CPU -> L1D
    input logic cpu_l1_valid,             // CPU wants to access memory
    input logic pcu_l1_store,             // 0 = load, 1 = store
    input logic [31:0] cpu_l1_addr,       //  
    input logic [31:0] cpu_l1_wdata,
    input logic [3:0] cpu_l1_wstrb,

    // L1D -> CPU
    output logic l1_cpu_valid,
    output logic [31:0] l1_cpu_rdata,
    output logic l1_cpu_stall

    /*============= L1->L2 INTERFACE =============*/

);
    
// L1 CACHE ARRAYS
logic [L1_TAG-1:0] tag_array[L1_SETS][L1_WAYS]; 
logic [L1_DATABITS-1:0] data_array[L1_SETS][L1_WAYS];
logic dirty_array[L1_SETS][L1_WAYS];
logic valid_array[L1_SETS][L1_WAYS];


/* ================= ADDRESS DECODE ================= */
logic [L1_OFFSET-1:0] offset;
logic [L1_INDEX-1:0]  index;
logic [L1_TAG-1:0]    tag;

assign offset = cpu_l1_addr[L1_OFFSET-1:0];
assign index  = cpu_l1_addr[L1_OFFSET +: L1_INDEX];
assign tag    = cpu_l1_addr[L1_OFFSET+ L1_INDEX +: L1_TAG];

// HIT Logic

logic [L1_WAYS-1:0] way_hit; // one bit hit flag per cache way
logic hit; // Global Hit Flag if any way hits than this will be hit. 
logic [$clog2(L1_WAYS)-1:0] hit_way; // Binary index of the way that hit; Width = number of bits needed to encode WAYS // 2 bits for 4 way

always_comb begin
    // for loop to go through all ways
    for(int w = 0; w < L1_WAYS; w ++)begin
        way_hit[w] = valid_array[L1_INDEX][w] && (tag_array[L1_INDEX][w]== tag);
    end
end

// global tag hit
assign hit = |way_hit; // reduction or operator 

// convert way hit into one hot binay index codex
always_comb begin
  hit_way = '0;
  for (int w = 0; w < L1_WAYS; w++)
    if (way_hit[w]) hit_way = w;
end

endmodule