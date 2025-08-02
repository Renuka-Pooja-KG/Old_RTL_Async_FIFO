class write_driver extends uvm_driver #(write_sequence_item);
  `uvm_component_utils(write_driver)

  virtual wr_interface wr_vif;
  write_sequence_item tr;

  function new(string name = "write_driver", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual wr_interface)::get(this, "", "wr_vif", wr_vif)) begin
      `uvm_fatal("NOVIF", "Could not get wr_vif from uvm_config_db")
    end
    tr = write_sequence_item::type_id::create("tr");
    `uvm_info(get_type_name(), "write_driver build_phase completed, interface acquired", UVM_LOW)
  endfunction

  task run_phase(uvm_phase phase);
    super.run_phase(phase);
    //write_sequence_item tr;
    `uvm_info(get_type_name(), "write_driver run_phase started", UVM_LOW)

    forever begin
      seq_item_port.get_next_item(tr);
      // Drive stimulus to the interface
      wr_vif.write_driver_cb.write_enable <= tr.write_enable;
      wr_vif.write_driver_cb.wdata       <= tr.wdata;
      wr_vif.write_driver_cb.afull_value <= tr.afull_value;
      wr_vif.write_driver_cb.sw_rst      <= tr.sw_rst;  

      // Drive asynchronous reset signals
      wr_vif.hw_rst    <= tr.hw_rst;
      wr_vif.mem_rst     <= tr.mem_rst;
      @(wr_vif.write_driver_cb);
      `uvm_info(get_type_name(), $sformatf("write_driver: tr = %s", tr.sprint), UVM_LOW)
      seq_item_port.item_done();
    end
  endtask
endclass 