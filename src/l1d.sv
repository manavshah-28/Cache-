import cache_pkg::*;

module l1d(
    
    // clocking and reset (active low)
    input clk,
    input rst_n,

    /*============= CPU INTERFACE =============*/

    // CPU -> L1D
    input logic cpu_l1_valid,             // CPU wants to access memory
    input logic cpu_l1_store,             // 0 = load, 1 = store
    input logic [31:0] cpu_l1_addr,       //  
    input logic [31:0] cpu_l1_wdata,
    input logic [3:0] cpu_l1_wstrb,

    // L1D -> CPU
    output logic l1_cpu_valid,
    output logic [31:0] l1_cpu_rdata,
    output logic l1_cpu_stall

    /*============= L1->L2 INTERFACE =============*/
   
);

 /*============= L1-> Memory INTERFACE =============*/
logic l1_mem_valid;
logic l1_mem_store;   // 0 : load 1 : store
logic [31:0] l1_mem_addr;    // address 
logic [31:0] l1_mem_wdata;   // data to write

logic [31:0] mem_l1_rdata;
logic mem_l1_valid;    

// memory instantiation
memory main_mem(.*);

 /*============= L1 Cache Arrays =============*/
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

/* ==================== HIT LOGIC ==================== */

logic [L1_WAYS-1:0] way_hit;         // one bit hit flag per cache way
logic hit;                           // Global Hit Flag if any way hits than this will be hit. 
logic [$clog2(L1_WAYS)-1:0] hit_way; // binary index of the way that hit; Width = number of bits needed to encode WAYS // 2 bits for 4 way

// $@1 There is an assumption that only one way will hit
always_comb begin
    for(int w = 0; w < L1_WAYS; w ++)begin
        way_hit[w] = valid_array[index][w] && (tag_array[index][w] == tag); // valid and tag check to see if its a hit
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

/* ================= DATA EXTRACTION ================= */
logic [255:0] line_data;
logic [31:0]  word_data;

// $@1
assign line_data = data_array[index][hit_way]; // 32 bytes or 256 bits or 8 words
assign word_data = line_data[(offset*32)+: 32];

/* ================= TRUE LRU ================= */
/* 
LRU tracks the least recently used WAY in a particular SET.
4 ways, so need 2 bits per way to track LRU.
*/

logic [1:0] lru_pos [L1_SETS][L1_WAYS]; // 256 sets and 4 ways

/* LRU updation logic example
___________________
   ways->   0 1 2 3
___________________
set 0   :   0 1 2 3 | (0 : MRU  3 : LRU)
set 1   :   0 1 2 3
.
.
set 255 :   0 1 2 3 
___________________

lets say we had a hit on set 1, way 2
___________________
   ways->   0 1 2 3
___________________
set 0   :   0 1 2 3 | (0 : MRU  3 : LRU)
set 1   :   1 2 0 3
.
.
set 255 :   0 1 2 3 
___________________
*/

/* ================ LRU update logic ================= */
always_ff @(posedge clk or negedge rst_n) begin
    
    // initialize lru_pos array
    if(!rst_n)begin
        for(int s = 0; s < L1_SETS; s ++)begin
            for(int w = 0; w < L1_WAYS; w ++)begin
                lru_pos[s][w] = w; // (0 : MRU  3 : LRU)
            end
        end
    end
    else begin
    if(hit) begin
        int old_pos;
        old_pos = lru_pos[index][hit_way];

        for(int w = 0; w < L1_WAYS; w ++)begin
            if (lru_pos[index][w] < old_pos)
                lru_pos[index][w] <= lru_pos[index][w] + 1;
            else if (w == hit_way)
                lru_pos[index][w] <= 0;
            else
                lru_pos[index][w] <= lru_pos[index][w];
        end
    end
    end
end

/* ================ Victim Selection ================= */
logic [$clog2(L1_WAYS)-1:0] victim_way;

always_comb begin
    victim_way = '0;
    for (int w = 0; w < L1_WAYS; w++) begin
        if (lru_pos[index][w] == L1_WAYS-1) // whenever lru_pos array for a specific index is 3, that is the LRU way. (0 : MRU  3 : LRU)
            victim_way = w;
    end
end

logic victim_dirty;
logic victim_valid;

assign victim_dirty = dirty_array[index][victim_way];
assign victim_valid = valid_array[index][victim_way];

/* ================ MISS HANDLE FSM ================= */
typedef enum logic [2:0] {
    IDLE,                   // wait for CPU request
    LOOKUP,                 // check hit/miss
    WRITEBACK,              // evict ditry line
    REFILL,                 // fetch new line form main mem
    RESP                    // respond to CPU
}cache_state;

cache_state state, next_state;

/* ================ FSM update logic ================= */
always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        state <= IDLE;
    else
        state <= next_state;
end

always_comb begin
    next_state = state;

    case (state)
        // wait for the valid request from CPU
        IDLE: begin
            if (cpu_l1_valid)
                next_state = LOOKUP;
        end

        // check HIT/MISS
        LOOKUP: begin

            // HIT
            if (hit)
                next_state = RESP;

            // MISS
            else if (victim_valid && victim_dirty)
                next_state = WRITEBACK; // evict that dirty victim back to main memory
            else
                next_state = REFILL;    // miss and not valid dirty victim, bring in the new data from mem directly

        end

        WRITEBACK: begin // evict dirty line back to main mem
            //
            l1_mem_valid = 1;
            l1_mem_store = 1;
            l1_mem_addr  = cpu_l1_addr;     
            l1_mem_wdata = cpu_l1_wdata;

            next_state = REFILL;
        end

        REFILL: begin    // get the required data from main mem
            l1_mem_valid = 0;

            l1_mem_store = 0; // load mode on

            // Since memory is word aligned, from word 0 to word 65,535 
            // and each cache block is made up of 8 blocks, on a cache miss
            // I need to fill in 8 words sequentially from the memory.                     
            next_state = RESP;
        end

        RESP: begin
            next_state = IDLE;
        end
    endcase
end

endmodule