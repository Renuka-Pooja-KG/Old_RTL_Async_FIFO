// define.sv - Macro definitions for async FIFO project

`ifndef ASYNC_FIFO_DEFINES_SV
`define ASYNC_FIFO_DEFINES_SV

// Data and address width
`ifndef DATA_WIDTH
  `define DATA_WIDTH 32
`endif

`ifndef ADDRESS_WIDTH
  `define ADDRESS_WIDTH 5
`endif

// Derived parameters
// `ifndef DEPTH
//   `define DEPTH (1 << `ADDRESS_WIDTH)
// `endif

// Feature and control parameters
`ifndef SOFT_RESET
  `define SOFT_RESET 0
`endif

`ifndef STICKY_ERROR
  `define STICKY_ERROR 0
`endif

`ifndef RESET_MEM
  `define RESET_MEM 0
`endif

`ifndef PIPE_WRITE
  `define PIPE_WRITE 0
`endif

`ifndef PIPE_READ
  `define PIPE_READ 0
`endif

`ifndef SYNC_STAGE
  `define SYNC_STAGE 0
`endif

// Clock speeds (in time units, e.g., ns)
`ifndef WCLK_SPEED
  `define WCLK_SPEED 10 // 100MHz (period = 10ns)
`endif

`ifndef RCLK_SPEED
  `define RCLK_SPEED 14 // ~71.4MHz (period = 14ns)
`endif

`endif // ASYNC_FIFO_DEFINES_SV 