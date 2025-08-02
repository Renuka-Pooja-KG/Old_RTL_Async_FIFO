class read_monitor extends uvm_monitor;
  `uvm_component_utils(read_monitor)

  uvm_analysis_port #(read_sequence_item) read_analysis_port;
  virtual rd_interface rd_vif;
  read_sequence_item tr;

  function new(string name = "read_monitor", uvm_component parent = null);
    super.new(name, parent);
    read_analysis_port = new("read_analysis_port", this);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual rd_interface)::get(this, "", "rd_vif", rd_vif)) begin
      `uvm_fatal("NOVIF", "Could not get rd_vif from uvm_config_db")
    end

    tr = read_sequence_item::type_id::create("tr", this);

    `uvm_info(get_type_name(), "read_monitor build_phase completed, interface acquired", UVM_MEDIUM)
  endfunction

  task run_phase(uvm_phase phase);
  super.run_phase(phase);
    `uvm_info(get_type_name(), "read_monitor run_phase started", UVM_LOW)

    forever begin
      @(rd_vif.read_monitor_cb);

      // Only capture when read_enable is active
      if (rd_vif.read_monitor_cb.read_enable) begin
        // Capture signals from the interface
        // // Asynchronous reset signals
        // tr.hw_rst       = rd_vif.hw_rst;
        // // Synchronous signals
        // tr.sw_rst         = rd_vif.read_monitor_cb.sw_rst;

        tr.read_enable      = rd_vif.read_monitor_cb.read_enable;
        tr.aempty_value    = rd_vif.read_monitor_cb.aempty_value;
    
        tr.rdempty         = rd_vif.read_monitor_cb.rdempty;
        tr.rd_almost_empty = rd_vif.read_monitor_cb.rd_almost_empty;
        tr.fifo_read_count = rd_vif.read_monitor_cb.fifo_read_count;
        tr.underflow       = rd_vif.read_monitor_cb.underflow;
        tr.rd_level        = rd_vif.read_monitor_cb.rd_level;
        tr.read_data       = rd_vif.read_monitor_cb.read_data;

        // // Print all rd_vif signals for debug
        // $monitor("Time=%0t rd_vif: read_enable=%b aempty_value=%d rdempty=%b rd_almost_empty=%b fifo_read_count=%d underflow=%b rd_level=%d read_data=%h",
        //   $time, rd_vif.read_monitor_cb.read_enable, rd_vif.read_monitor_cb.aempty_value,
        //   rd_vif.read_monitor_cb.rdempty, rd_vif.read_monitor_cb.rd_almost_empty, rd_vif.read_monitor_cb.fifo_read_count,
        //   rd_vif.read_monitor_cb.underflow, rd_vif.read_monitor_cb.rd_level, rd_vif.read_monitor_cb.read_data);

        `uvm_info(get_type_name(), $sformatf("Captured read transaction in read_monitor: %s", tr.sprint), UVM_LOW)

        read_analysis_port.write(tr);
      end
    end
  endtask
endclass