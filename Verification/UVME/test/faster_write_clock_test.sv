class faster_write_clock_test extends base_test;
  `uvm_component_utils(faster_write_clock_test)

  function new(string name = "faster_write_clock_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    wseq.scenario = 4; // simultaneous_scenario (to test with faster write clock)
    rseq.scenario = 4; // simultaneous_scenario
    `uvm_info(get_type_name(), "Faster write clock test build_phase completed", UVM_LOW)
  endfunction

  task run_phase(uvm_phase phase);
    phase.raise_objection(this);
    `uvm_info(get_type_name(), "Starting faster write clock test", UVM_LOW)
    
    fork
      wseq.start(m_env.m_write_agent.m_sequencer);
      rseq.start(m_env.m_read_agent.m_sequencer);
    join
    
    `uvm_info(get_type_name(), "Faster write clock test completed", UVM_LOW)
    phase.drop_objection(this);
  endtask
endclass 