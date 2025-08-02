interface wr_interface (
  input logic wclk
);

  // Asynchronous reset signals (not part of clocking blocks)
  logic hw_rst;
  logic mem_rst;

  // Write side signals
  logic [31:0] wdata;
  logic write_enable;
  logic [4:0] afull_value;
  logic sw_rst;
  logic wfull;
  logic wr_almost_ful;
  logic overflow;
  logic [5:0] fifo_write_count;
  logic [5:0] wr_level;

  // Write domain clocking block (for driver)
  clocking write_driver_cb @(negedge wclk);
    //default input #1step output #1step;
    // Synchronous signals only
    output wdata, write_enable, afull_value, sw_rst;
    input wfull, wr_almost_ful, overflow, fifo_write_count, wr_level;
  endclocking

  // Monitor clocking block (all signals as input)
  clocking write_monitor_cb @(posedge wclk);
    default input #0 output #1step;
    input wdata, write_enable, afull_value, sw_rst;
    input wfull, wr_almost_ful, overflow, fifo_write_count, wr_level;
  endclocking

  // Modport for driver
  modport write_driver_mp (
    clocking write_driver_cb,
    output hw_rst, // Asynchronous reset signal
    output mem_rst   // Asynchronous reset signal
  );

  // Modport for monitor
  modport write_monitor_mp (
    clocking write_monitor_cb,
    input hw_rst, // Asynchronous reset signal
    input mem_rst   // Asynchronous reset signal
  );

endinterface