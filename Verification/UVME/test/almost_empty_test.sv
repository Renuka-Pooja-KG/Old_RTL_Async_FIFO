class almost_empty_test extends base_test;
  `uvm_component_utils(almost_empty_test)

  function new(string name = "almost_empty_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    wseq.scenario = 13; // almost_empty_support_scenario
    rseq.scenario = 8; // almost_empty_scenario
    `uvm_info(get_type_name(), "Almost empty test build_phase completed", UVM_LOW)
  endfunction

  task run_phase(uvm_phase phase);
    phase.raise_objection(this);
    `uvm_info(get_type_name(), "Starting almost empty test", UVM_LOW)
    
    fork
      wseq.start(m_env.m_write_agent.m_sequencer);
      rseq.start(m_env.m_read_agent.m_sequencer);
    join
    
    `uvm_info(get_type_name(), "Almost empty test completed", UVM_LOW)
    phase.drop_objection(this);
  endtask
endclass 