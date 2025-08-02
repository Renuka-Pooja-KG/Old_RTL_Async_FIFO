module async_fifo_top_tb;

  import uvm_pkg::*;
  import verification_pkg::*;

  `include "uvm_macros.svh"

  // Clock and reset signals
  logic wclk;
  logic rclk;
  // logic hw_rst;
  // logic mem_rst;

  // Clock generation
  initial wclk = 0;
  always #5 wclk = ~wclk; // 100MHz if WCLK_SPEED=10
  initial rclk = 0;
  always #7 rclk = ~rclk; // ~71.4MHz if RCLK_SPEED=14

   wr_interface wr_if (
    .wclk(wclk)
  );

  rd_interface rd_if (
    .rclk(rclk)
  );

  // DUT instantiation
  async_fifo_int_mem #(
    .DATA_WIDTH(32),
    .ADDRESS_WIDTH(5),
    //.DEPTH(32),
    .SOFT_RESET(3),
    .POWER_SAVE (1),
    .STICKY_ERROR(0),
    .RESET_MEM(1),
    .PIPE_WRITE(0),
    .DEBUG_ENABLE(1),
    .PIPE_READ(0),
    .SYNC_STAGE(2)
  ) dut (
    // Write side
    .wclk(wclk),
    .hw_rst(wr_if.hw_rst),
    .wdata(wr_if.wdata),
    .write_enable(wr_if.write_enable),
    .afull_value(wr_if.afull_value),
    .sw_rst(wr_if.sw_rst),
    .mem_rst(wr_if.mem_rst),
    .wfull(wr_if.wfull),
    .wr_almost_ful(wr_if.wr_almost_ful),
    .overflow(wr_if.overflow),
    .fifo_write_count(wr_if.fifo_write_count),
    .wr_level(wr_if.wr_level),
    // Read side
    .rclk(rclk),
    .read_enable(rd_if.read_enable),
    .aempty_value(rd_if.aempty_value),
    .read_data(rd_if.read_data),
    .rdempty(rd_if.rdempty),
    .rd_almost_empty(rd_if.rd_almost_empty),
    .underflow(rd_if.underflow),
    .fifo_read_count(rd_if.fifo_read_count),
    .rd_level(rd_if.rd_level)
  );

  // UVM config_db setup
  initial begin
    uvm_config_db#(virtual wr_interface)::set(null, "*", "wr_vif", wr_if);
    uvm_config_db#(virtual rd_interface)::set(null, "*", "rd_vif", rd_if);
  end

  // Waveform dumping
  initial begin
    $shm_open("wave.shm");
    $shm_probe("AS");
  end
  // Start UVM
  initial begin
    // Start UVM
    run_test("base_test");
  end

endmodule