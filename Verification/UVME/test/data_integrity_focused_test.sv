class data_integrity_focused_test extends base_test;
  `uvm_component_utils(data_integrity_focused_test)

  function new(string name = "data_integrity_focused_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  // Override the scoreboard configuration for data integrity focused testing
  function void configure_scoreboard_for_test();
    // Enable both data integrity priority and level mismatch tolerance
    m_env.m_scoreboard.set_data_integrity_priority(1'b1);  // Prioritize data integrity
    m_env.m_scoreboard.set_level_mismatch_tolerance(1'b1); // Enable tolerance for level mismatches
    `uvm_info(get_type_name(), "Scoreboard configured for DATA INTEGRITY FOCUSED mode", UVM_MEDIUM)
  endfunction

  task run_phase(uvm_phase phase);
    phase.raise_objection(this);
    
    // Configure scoreboard for data integrity focused testing
    configure_scoreboard_for_test();
    
    // Set scenario for high-frequency simultaneous operations
    wseq.scenario = 4; // simultaneous scenario
    rseq.scenario = 4; // simultaneous scenario
    
    fork
      wseq.start(m_env.m_write_agent.m_sequencer);
      rseq.start(m_env.m_read_agent.m_sequencer);
    join
    
    // Get and report data integrity statistics
    report_data_integrity_stats();
    
    `uvm_info(get_type_name(), "Data integrity focused test completed", UVM_LOW)
    phase.drop_objection(this);
  endtask
endclass 