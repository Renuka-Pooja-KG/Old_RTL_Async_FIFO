class almost_full_test extends base_test;
  `uvm_component_utils(almost_full_test)

  function new(string name = "almost_full_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    wseq.scenario = 9; // almost_full_scenario
    rseq.scenario = 13; // almost_full_support_scenario
    `uvm_info(get_type_name(), "Almost full test build_phase completed", UVM_LOW)
  endfunction

  task run_phase(uvm_phase phase);
    phase.raise_objection(this);
    `uvm_info(get_type_name(), "Starting almost full test", UVM_LOW)
    
    fork
      wseq.start(m_env.m_write_agent.m_sequencer);
      rseq.start(m_env.m_read_agent.m_sequencer);
    join
    
    `uvm_info(get_type_name(), "Almost full test completed", UVM_LOW)
    phase.drop_objection(this);
  endtask
endclass 