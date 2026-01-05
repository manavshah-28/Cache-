# Cache$ Project Idea
design a parameterized cache module. Reuse support for 2 (3 if possible) levels before main memory.

# Design choices

| Design Aspect | L1 Cache Choice | L2 Cache Choice | Info |
|:--------------:|:---------------:|:---------------:|:------------------------------:|
| Cache Role | Closest to CPU | Between L1 and main memory | L1 serves CPU requests directly; L2 services L1 misses |  
| Primary Optimization Goal | Low latency | Low miss rate | L1 minimizes access time; L2 minimizes costly memory accesses | 
| Associativity | 4 way | 8 way | Number of cache lines per set | 
| Cache Size | 32 KB | 256 KB | Total cache capacity |  
| Line Size | 32 bytes (256 bits) | 32 bytes (256 bits) | Amount of data transferred per miss | 
| Write Policy | Write-back | Write-back | Writes update cache; memory updated on eviction | 
| Write Allocation | Write-allocate | Write-allocate | Store miss fetches line before writing | 
| Miss Handling | Blocking | Blocking | Only one miss handled at a time; requester stalls |  
| Hit Latency | 1 cycle | Multi-cycle | Cycles needed to serve a hit |  |
| Miss Penalty Visibility | Visible to CPU | Hidden from CPU | CPU stalls on L1 miss; L2 hides DRAM latency |  
| Replacement Policy | True LRU | True or pseudo-LRU | Selects victim line on cache miss | 
| Dirty Bit | Yes | Yes | Tracks modified cache lines |  
| Valid Bit | Yes | Yes | Indicates whether cache line holds valid data |  
| Inclusion Policy | N/A | Inclusive | All L1 lines must also exist in L2 | 
| Eviction Effect | Evict → write back to L2 | Evict → invalidate L1 |Evictions propagate down the hierarchy | 
| Interface Granularity | Word-level with byte mask | Line-level only | L1 handles words; L2 handles full cache lines | 
| Interface Type | CPU ↔ Cache | Cache ↔ Cache | Request/response handshake interface | 
| Non-blocking Support | No | No | Cannot handle multiple outstanding misses |  
| Prefetching | No | No | Speculative data fetch |
| Coherence | None | None | Multi-core consistency protocol | 
| Parameterization | Yes | Yes | Same cache core with different parameters Demonstrates scalable, reusable architecture |

## L1D$ Design
