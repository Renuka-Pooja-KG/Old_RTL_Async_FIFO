class read_conditions_test extends base_test;
  `uvm_component_utils(read_conditions_test)

  function new(string name = "read_conditions_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    wseq.scenario = 11; // read_conditions_support_scenario
    rseq.scenario = 6; // read_conditions_scenario
    `uvm_info(get_type_name(), "Read conditions test build_phase completed", UVM_LOW)
  endfunction

  task run_phase(uvm_phase phase);
    phase.raise_objection(this);
    `uvm_info(get_type_name(), "Starting read conditions test", UVM_LOW)
    
    fork
      wseq.start(m_env.m_write_agent.m_sequencer);
      rseq.start(m_env.m_read_agent.m_sequencer);
    join
    
    `uvm_info(get_type_name(), "Read conditions test completed", UVM_LOW)
    phase.drop_objection(this);
  endtask
endclass 