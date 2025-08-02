class read_agent extends uvm_agent;
  `uvm_component_utils(read_agent)

  read_driver    m_driver;
  read_monitor   m_monitor;
  read_sequencer m_sequencer;

  virtual rd_interface rd_vif;
  //uvm_analysis_port #(read_sequence_item) rd_agent_analysis_port;

  function new(string name = "read_agent", uvm_component parent = null);
    super.new(name, parent);
    //rd_agent_analysis_port = new("rd_agent_analysis_port", this);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    m_monitor = read_monitor::type_id::create("m_monitor", this);
    if (is_active == UVM_ACTIVE) begin
      m_driver    = read_driver::type_id::create("m_driver", this);
      m_sequencer = read_sequencer::type_id::create("m_sequencer", this);
    end

    // Get the virtual interface from config_db and assign to driver and monitor
 
    if (!uvm_config_db#(virtual rd_interface)::get(this, "", "rd_vif", rd_vif)) begin
      `uvm_fatal("NOVIF", "Could not get rd_vif from uvm_config_db")
    end
    if (is_active == UVM_ACTIVE) begin
      m_driver.rd_vif = rd_vif;
    end
    m_monitor.rd_vif = rd_vif;

    `uvm_info(get_type_name(), "read_agent build_phase completed", UVM_LOW)
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    //m_monitor.read_analysis_port.connect(rd_agent_analysis_port);
    if (is_active == UVM_ACTIVE) begin
      m_driver.seq_item_port.connect(m_sequencer.seq_item_export);
    end
    `uvm_info(get_type_name(), "read_agent connect_phase completed", UVM_LOW)
  endfunction
endclass