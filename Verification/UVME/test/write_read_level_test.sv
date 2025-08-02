class write_read_level_test extends base_test;
  `uvm_component_utils(write_read_level_test)

  function new(string name = "write_read_level_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    wseq.scenario = 4; // simultaneous_scenario (to test levels during concurrent operations)
    rseq.scenario = 4; // simultaneous_scenario
    `uvm_info(get_type_name(), "Write read level test build_phase completed", UVM_LOW)
  endfunction

  task run_phase(uvm_phase phase);
    phase.raise_objection(this);
    `uvm_info(get_type_name(), "Starting write read level test", UVM_LOW)
    
    fork
      wseq.start(m_env.m_write_agent.m_sequencer);
      rseq.start(m_env.m_read_agent.m_sequencer);
    join
    
    `uvm_info(get_type_name(), "Write read level test completed", UVM_LOW)
    phase.drop_objection(this);
  endtask
endclass 