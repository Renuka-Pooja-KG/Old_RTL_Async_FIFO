class write_agent extends uvm_agent;
  `uvm_component_utils(write_agent)

  write_driver    m_driver;
  write_monitor   m_monitor;
  write_sequencer m_sequencer;

  virtual wr_interface wr_vif;

  //uvm_analysis_port #(write_sequence_item) wr_agent_analysis_port;

  function new(string name = "write_agent", uvm_component parent = null);
    super.new(name, parent);
    //wr_agent_analysis_port = new("wr_agent_analysis_port", this);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    m_monitor = write_monitor::type_id::create("m_monitor", this);
    if (is_active == UVM_ACTIVE) begin
      m_driver    = write_driver::type_id::create("m_driver", this);
      m_sequencer = write_sequencer::type_id::create("m_sequencer", this);
    end

    // Get the virtual interface from config_db and assign to driver and monitor
    if (!uvm_config_db#(virtual wr_interface)::get(this, "", "wr_vif", wr_vif)) begin
      `uvm_fatal("NOVIF", "Could not get wr_vif from uvm_config_db")
    end
    if (is_active == UVM_ACTIVE) begin
      m_driver.wr_vif = wr_vif;
    end
    m_monitor.wr_vif = wr_vif;

    `uvm_info(get_type_name(), "write_agent build_phase completed", UVM_LOW)
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    // Connect monitor analysis port to agent analysis port
    //m_monitor.write_analysis_port.connect(wr_agent_analysis_port);

    // Connect driver to sequencer
    if (is_active == UVM_ACTIVE) begin
      m_driver.seq_item_port.connect(m_sequencer.seq_item_export);
    end
    `uvm_info(get_type_name(), "write_agent connect_phase completed", UVM_LOW)
  endfunction
endclass