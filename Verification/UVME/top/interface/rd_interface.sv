interface rd_interface (
  //input logic hw_rst,
  input logic rclk
);

  // Asynchronous reset signals (not part of clocking blocks)
  //logic hw_rst;

  // Synchronous reset signal
  //logic sw_rst;

  // Read side signals
  logic [31:0] read_data;
  logic read_enable;
  logic [4:0] aempty_value;
  logic rdempty;
  logic rd_almost_empty;
  logic underflow;
  logic [5:0] fifo_read_count;
  logic [5:0] rd_level;

  // Read domain clocking block (for driver)
  clocking read_driver_cb @(negedge rclk);
    // default input #1step output #1step;
   
    //Synchronous reset signal
   // output sw_rst;

   // Read domain outputs (driven on rclk)
    output read_enable, aempty_value;

   // Read domain inputs (sampled on rclk)
    input read_data, rdempty, rd_almost_empty, underflow, fifo_read_count, rd_level;
  endclocking

  // Monitor clocking block (all signals as input)
  clocking read_monitor_cb @(posedge rclk);
    default input #0 output #1step;
    // Synchronous reset signal
    //input sw_rst;
    // Read domain inputs (sampled on rclk)
    //input read_enable, aempty_value, sw_rst;
    input read_enable, aempty_value;
    input read_data, rdempty, rd_almost_empty, underflow, fifo_read_count, rd_level;
  endclocking

  // Modport for driver
  modport read_driver_mp (
    clocking read_driver_cb,
    //output hw_rst // Asynchronous reset signal
    );

  // Modport for monitor
  modport read_monitor_mp (
    clocking read_monitor_cb,
    //input hw_rst // Asynchronous reset signal
    );

endinterface 