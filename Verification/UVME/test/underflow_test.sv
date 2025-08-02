class underflow_test extends base_test;
  `uvm_component_utils(underflow_test)

  function new(string name = "underflow_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    wseq.scenario = 14; // underflow_support_scenario
    rseq.scenario = 9; // underflow_scenario
    `uvm_info(get_type_name(), "Underflow test build_phase completed", UVM_LOW)
  endfunction

  task run_phase(uvm_phase phase);
    phase.raise_objection(this);
    `uvm_info(get_type_name(), "Starting underflow test", UVM_LOW)
    
    fork
      wseq.start(m_env.m_write_agent.m_sequencer);
      rseq.start(m_env.m_read_agent.m_sequencer);
    join
    
    `uvm_info(get_type_name(), "Underflow test completed", UVM_LOW)
    phase.drop_objection(this);
  endtask
endclass 