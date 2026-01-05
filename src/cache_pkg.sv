package cache_pkg;

parameter ADDR_WIDTH = 32;
parameter DATA_WIDTH = 32;

parameter L1_WAYS = 4;           // 4 way set associative cache
parameter L1_CACHE_SIZE = 32768; // 32 KB = 3 x 1024 B = 32768 bytes
parameter L1_LINE_SIZE = 32;     // line size = 32 bytes
parameter L1_CACHE_LINES = L1_CACHE_SIZE/L1_LINE_SIZE; // 1024 lines in L1 cache
parameter L1_SETS =  L1_CACHE_LINES/L1_WAYS;      // 256 Sets per way

parameter L1_OFFSET = $clog2(L1_LINE_SIZE);
parameter L1_INDEX  = $clog2(L1_SETS);
parameter L1_TAG    = ADDR_WIDTH - L1_OFFSET - L1_INDEX;

endpackage